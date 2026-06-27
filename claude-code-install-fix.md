# Claude Code 原生二进制安装故障排查与修复

> 时间:2026-06-26 · 环境:Linux x86_64 (ly-System-Product-Name) · npm 11.11.0 / node v24.14.1

## 故障现象

在终端运行 `claude --resume` / `claude` 时报错:

```
Error: claude native binary not installed.

Either postinstall did not run (--ignore-scripts, some pnpm configs)
or the platform-native optional dependency was not downloaded
(--omit=optional).

Run the postinstall manually (adjust path for local vs global install):
  node node_modules/@anthropic-ai/claude-code/install.cjs
```

## 根因分析

整个故障由 **三个环节** 串联导致,缺一不可:

### 1. 原生包未下载(postinstall 找不到依赖)

主包 `@anthropic-ai/claude-code@2.1.193` 本身不含二进制,真正的可执行文件放在按平台分发的 optionalDependencies 里,对应本机的是:

```
@anthropic-ai/claude-code-linux-x64@2.1.193
```

该原生包在最初安装时没有下载下来,`node_modules/@anthropic-ai/` 目录为空。
主包 postinstall(`install.cjs`)通过 `require.resolve(...)` 找不到原生包,于是**保留 500 字节的占位 stub**(`bin/claude.exe`),导致后续 `claude` 命令一启动就报错。

### 2. 下载失败的真因 —— 代理 TLS 记录损坏

手动安装原生包时观察到的关键日志:

```
npm http fetch GET 200 .../claude-code-linux-x64  503ms (cache miss)   ← 元数据,小请求,通过
npm http fetch GET .../claude-code-linux-x64-2.1.193.tgz
   attempt 1 failed with ERR_SSL_TLS_ALERT_BAD_RECORD_MAC              ← 大文件,第一次失败
npm http fetch GET 200 .../claude-code-linux-x64-2.1.193.tgz
   157875ms attempt #2 (cache miss)                                    ← 靠重试才成功,耗时 ~158s
```

- `ERR_SSL_TLS_ALERT_BAD_RECORD_MAC`:TLS 解密后数据完整性校验(MAC)失败。
- 本地代理端口 `7897`(Clash / Mihomo 类)在转发 HTTPS 长数据流时破坏了 TLS 记录:
  - **小请求**(元数据,503ms)能正常通过;
  - **大文件**(240 MB tgz)第一次必然失败,依赖 npm 自动重试才在第二次下载成功。
- 这是 HTTP 代理转发 HTTPS 隧道时的典型故障,常见诱因:MTU 不匹配、TCP 分片被篡改、或代理开启了 SNI 嗅探 / TLS 解密。

> 注意:`npm config` 默认**不读** `http_proxy` / `https_proxy` 环境变量,需通过 `npm config set https-proxy ...` 显式配置。

### 3. 下载成功后仍报错 —— postinstall 时序问题

原生包最终下载成功并落到**全局扁平目录**:
```
/home/ly/.npm-global/lib/node_modules/@anthropic-ai/claude-code-linux-x64/claude  (240,556,856 bytes)
```

但主包的 postinstall **只在最初安装时跑过一次**(那时还没有原生包),npm 不会因为 optionalDependency 后到而自动重跑 postinstall。
因此 `bin/claude.exe` 始终是 500 字节 stub,`claude` 命令继续报同样的错。

## 修复过程

### 关键路径

| 路径 | 说明 |
|------|------|
| `claude` 命令(symlink) | `/home/ly/.npm-global/bin/claude` → `../lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` |
| 主包目录 | `/home/ly/.npm-global/lib/node_modules/@anthropic-ai/claude-code/` |
| 占位 stub(故障态) | `…/claude-code/bin/claude.exe` (500 bytes) |
| 原生二进制(已下载) | `…/claude-code-linux-x64/claude` (240,556,856 bytes) |
| postinstall 脚本 | `…/claude-code/install.cjs` |

### 修复步骤

1. **手动安装原生包**(清缓存后重试,绕开损坏的本地缓存):
   ```bash
   npm cache clean --force
   npm install -g @anthropic-ai/claude-code-linux-x64@2.1.193 -d
   ```
   → attempt #2 下载成功。

2. **重跑主包 postinstall**,把二进制硬链接到 `bin/claude.exe`:
   ```bash
   cd /home/ly/.npm-global/lib/node_modules/@anthropic-ai/claude-code
   node install.cjs
   ```
   - `install.cjs` 内部逻辑:`require.resolve('@anthropic-ai/claude-code-linux-x64/package.json')` 定位原生包 → `linkSync` 硬链接其 `claude` 到 `bin/claude.exe`(同文件系统优先硬链接,失败回退 `copyFileSync`)。
   - 退出码 0,`bin/claude.exe` 由 500 B → 240,556,856 B(链接数 2,硬链接)。

3. **验证**:
   ```bash
   claude --version
   # → 2.1.193 (Claude Code)
   ```

✅ 修复完成,`claude --resume` 可正常使用。

## 复发预防建议

### A. 更新 Claude Code 时绕开代理 TLS 问题(推荐)

使用国内镜像直连,根本不依赖代理:

```bash
npm install -g @anthropic-ai/claude-code --registry=https://registry.npmmirror.com
```

### B. 若坚持用代理 + npmjs 官方源

- 关闭代理对 `registry.npmjs.org` 的 SNI 嗅探 / TLS 解密(Clash 中改为 rule 模式直连,或关闭 `sniffer`)。
- 显式给 npm 配代理(它不读系统环境变量):
  ```bash
  npm config set proxy http://127.0.0.1:7897
  npm config set https-proxy http://127.0.0.1:7897
  ```

### C. 兜底:手动下载 tgz 安装(curl 对代理兼容性更好)

```bash
curl -x http://127.0.0.1:7897 -L -o /tmp/cc.tgz \
  https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-2.1.193.tgz
ls -la /tmp/cc.tgz   # 校验大小不为 0
npm install -g /tmp/cc.tgz -d
```

### D. 再次遇到 `native binary not installed` 时的一键修复

无需重装,直接重跑 postinstall:

```bash
node /home/ly/.npm-global/lib/node_modules/@anthropic-ai/claude-code/install.cjs
```

> 适用前提:对应的原生包(`claude-code-linux-x64`)已存在于全局 `node_modules`。若不存在,先按 A/B/C 任一方式安装原生包,再跑此命令。

## 附录:install.cjs 工作机制要点

- **平台探测**:`getPlatformKey()` 基于 `process.platform` + `arch()`,Linux 上通过 `process.report.header.glibcVersionRuntime` 是否存在区分 glibc / musl。
- **二进制放置**:`placeBinary(src, dest)` 优先 `linkSync`(硬链接,零额外磁盘占用),`EEXIST` 时先备份 stub 再重链,`EXDEV/EPERM` 回退 `copyFileSync`。
- **目标路径固定**:始终写入 `bin/claude.exe`(`.exe` 后缀 + 无 shebang stub,使 npm 在 Windows 生成直接 exec 的 cmd-shim;Unix 忽略后缀)。
- **降级方案**:postinstall 失败时可手动 `node cli-wrapper.cjs` 作为保留 Node 进程的 fallback。
