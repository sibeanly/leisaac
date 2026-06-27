# LeIsaac Docker 镜像构建指南

> 基于 `my-isaac-lab:v1.0` 构建 LeIsaac (LeRobot + IsaacLab) 镜像
> 构建日期：2026-06-26

---

## 镜像信息

| 属性 | 值 |
|------|------|
| 镜像名 | `leisaac:v1.0` |
| 大小 | 28.5 GB |
| 基础镜像 | `my-isaac-lab:v1.0` |
| 架构 | amd64 |
| LeIsaac 版本 | 0.4.0 |

## 基础镜像 `my-isaac-lab:v1.0` 规格

| 组件 | 版本 |
|------|------|
| IsaacLab | v2.3.0 |
| IsaacSim | 5.1.0-rc.19 |
| Python | 3.11.13 (IsaacSim 内置) |
| PyTorch | 2.7.0+cu128 |
| CUDA | 12.8 |
| OS | Ubuntu 24.04 |

## 版本兼容性对应表

| 依赖项 | IsaacSim 4.5 | IsaacSim 5.0 | IsaacSim 5.1 |
|--------|:-----------:|:-----------:|:-----------:|
| Python | 3.10 | 3.11 | 3.11 |
| IsaacLab | v2.1.1 | v2.2.1 | **v2.3.0 ✅** |
| CUDA | 11.8 | 12.8 | **12.8 ✅** |
| PyTorch | 2.5.1 | 2.7.0 | **2.7.0 ✅** |

`leisaac:v1.0` 对齐 **IsaacSim 5.1** 列，与 LeIsaac 文档完全兼容。

## 构建过程

### Dockerfile

位于 `/home/ly/code/leisaac/Dockerfile`。

主要步骤：
1. 配置 pip 清华源 (`pypi.tuna.tsinghua.edu.cn`)
2. 升级 pip 到最新版（解决旧 pip 构建元数据问题）
3. 安装 `leisaac` 核心包
4. 安装 `leisaac[lerobot]` — LeRobot 数据支持
5. 安装 `leisaac[gr00t]` — GR00T N1.5/N1.6 策略推理
6. 安装 `leisaac[remote]` — ZMQ 远程遥操作
7. 安装 `leisaac[lerobot-async]` — gRPC 异步 LeRobot
8. 降级并固定 `numpy==1.26.0`（lerobot 升级到 2.x 会破坏 IsaacLab）
9. 修复 torch vendored packaging 符号链接

### 构建命令

```bash
cd /home/ly/code/leisaac

# 如果代理可用（7897 端口）：
docker build --network=host \
  --build-arg http_proxy=http://127.0.0.1:7897 \
  --build-arg https_proxy=http://127.0.0.1:7897 \
  -t leisaac:v1.0 \
  -f Dockerfile .

# 如果直连（使用清华源）：
docker build -t leisaac:v1.0 -f Dockerfile .
```

### 已知问题及处理

| 问题 | 原因 | 处理方式 |
|------|------|---------|
| Docker daemon 注入代理 | daemon 配置了 `127.0.0.1:7890` 代理，容器内 127.0.0.1 指自身 | 每个 RUN 步骤开头 `unset http_proxy https_proxy ...` |
| lerobot 升级 numpy 到 2.x | lerobot 依赖 `numpy>=1.17`，resolver 选择最新版 | 安装后固定回 `numpy==1.26.0` |
| torch 的 `_structures.py` 符号链接断裂 | pip 升级 packaging 时删除了符号链接目标文件 | 用新 packaging 文件替换符号链接 |
| pip 版本过旧无法构建 lerobot 元数据 | IsaacSim 内置 pip 24.3.1 | 先 `pip install --upgrade pip` |

## 验证结果

```python
# 所有导入验证通过
import leisaac        # 0.4.0           ✅
import isaaclab       # 0.47.1          ✅
import torch          # 2.7.0+cu128     ✅
import numpy          # 1.26.0          ✅
import lerobot        # 0.4.2           ✅
import zmq            # 27.1.0          ✅ (gr00t + remote)
import pydantic       # 2.10.6          ✅ (gr00t)
import msgpack        # OK              ✅ (gr00t)
import grpc           # 1.74.0          ✅ (lerobot-async)
import protobuf       # 6.32.0          ✅ (lerobot-async)
import serial         # OK              ✅ (核心依赖)
import pygame         # 2.6.1           ✅ (核心依赖)
```

## 使用方式

### 交互式启动

```bash
docker run -it --rm \
  --gpus all \
  --network=host \
  leisaac:v1.0
```

> **注意**：基础镜像 Entrypoint 为 `["bash"]`，不要传入 `/bin/bash` 作为 command。

### 运行 LeIsaac 脚本

使用 IsaacSim 内置 Python（不是系统 python3）：

```bash
# 列出可用环境
docker run --rm --gpus all \
  --entrypoint=/isaac-sim/python.sh \
  leisaac:v1.0 \
  /workspace/leisaac/scripts/environments/list_envs.py

# 遥操作（键盘模式，no-window）
docker run --rm --gpus all \
  --network=host \
  --entrypoint=/isaac-sim/python.sh \
  leisaac:v1.0 \
  /workspace/leisaac/scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --teleop_device=keyboard \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras \
    --kit_args="--no-window"
```

### 工作目录结构

```
/workspace/
├── isaaclab/              # IsaacLab v2.3.0
│   └── source/
│       ├── isaaclab/
│       ├── isaaclab_tasks/
│       ├── isaaclab_rl/
│       ├── isaaclab_assets/
│       └── isaaclab_mimic/
└── leisaac/              # LeIsaac 0.4.0
    ├── source/leisaac/    # Python 包 (editable install)
    ├── scripts/
    │   └── environments/teleoperation/
    │       ├── teleop_se3_agent.py
    │       ├── replay.py
    │       └── so101_joint_state_server.py
    └── assets/
```

## 重新构建

如需调整依赖，编辑 Dockerfile 后：

```bash
cd /home/ly/code/leisaac
docker build -t leisaac:v2.0 -f Dockerfile .
```

> 提示：使用 `--no-cache` 强制完全重建，跳过缓存层。
