# LeIsaac 胶带环场景构建与夹爪修复总结

> 日期：2026-06-27
> 基础：leisaac:v1.0 镜像，Table with Cube 场景，SO101 Leader 遥操作

---

## 一、目标

在 LeIsaac 中构建一个新场景，用**棕色胶带环**替代 Table with Cube 场景里的红色正方体，作为 SO101 遥操作的抓取对象。任务目标沿用 LiftCube：把胶带环抬起至机器人基座上方 ≥0.20m。

最终尺寸（经多轮调整）：
- 外径 60mm（R=0.030m）
- 内径 50mm（R=0.025m）
- 壁厚 5mm
- 高度 20mm（H=0.020m）
- 颜色：棕色（base color `(0.45, 0.27, 0.13)`）

---

## 二、底层遥操作映射原理

从 SO101 Leader（真机）到 Isaac Sim（仿真）的完整数据流：

```
SO101 Leader (真机)                    Isaac Sim (仿真)
┌─────────────────┐                    ┌─────────────────────┐
│ STS3215 电机    │  串口读取           │                     │
│ 6 个关节编码器  │ ──────────────►    │  SO101Leader 设备   │
│ (raw 0~4095)    │  /dev/ttyACM0      │                     │
└─────────────────┘                    │  ① 校准归一化        │
                                       │     raw → norm(0~100)│
                                       │  ② 映射到关节角度    │
                                       │     norm → degree    │
                                       │  ③ 转弧度            │
                                       │     degree → rad     │
                                       │         │            │
                                       │         ▼            │
                                       │  JointPositionAction │
                                       │  ④ offset + scale    │
                                       │     → 目标关节角      │
                                       │  ⑤ PD actuator       │
                                       │     → 关节力矩        │
                                       │  ⑥ PhysX 仿真步进    │
                                       │     → 从端夹爪运动    │
                                       └─────────────────────┘
```

### ① 校准归一化：raw → norm

Leader 每个关节是 STS3215 舵机，编码器原始读数 `raw`（0~4095）无物理意义，需校准成标准化角度。

校准过程（`so101_leader.py` 的 `calibrate`）：
1. **homing**：把 leader 摆到行程中间，记录 `homing_offset`（定电机零点）
2. **record range**：把每个关节转到全程两端，记录 `range_min` / `range_max`（编码器极值）

归一化（`motors_bus._normalize`），gripper 用 `RANGE_0_100` 模式：
```python
bounded_val = min(range_max, max(range_min, raw))
norm = (bounded_val - range_min) / (range_max - range_min) * 100
```
- raw = range_min（闭合极值）→ norm = 0
- raw = range_max（张开极值）→ norm = 100

### ② 映射到从端关节角度：norm → degree

`action_process.convert_action_from_so101_leader`：
```python
motor_limits = SO101_FOLLOWER_MOTOR_LIMITS["gripper"]      # (0, 100)   leader 端范围
joint_limits = SO101_FOLLOWER_USD_JOINT_LIMLITS["gripper"] # (-10, 100) 仿真从端范围
motor_degree = norm - motor_limits[0]
processed_degree = motor_degree / (motor_limits[1]-motor_limits[0]) * (joint_limits[1]-joint_limits[0]) + joint_limits[0]
                  = norm / 100 * 110 + (-10)
```
**线性映射**，把 leader 的 0~100 拉伸/平移到仿真从端的 -10°~100°。两个范围独立定义，映射只保证端点对接。

### ③④⑤⑥ 转弧度 → JointPositionAction(offset+scale) → PD actuator → PhysX

- `processed_radius = processed_degree * pi / 180`
- `JointPositionAction`：`processed = raw_action * scale(1.0) + offset(default_joint_pos=0)`
- PD actuator（stiffness=17.8, damping=0.6）：`torque = K*(target-current) - D*vel`，effort_limit=10 N·m
- PhysX 步进，关节按力学运动

**遥操作本质**：把人操作 leader 的"行程百分比"，线性复刻到仿真从端的"关节角度行程"。actual 精确跟随 target（实测误差 0.01°）。

---

## 三、场景构建（方案 A：复制 USD + Python 脚本替换几何）

### 关键约束（代码探查得出）

- `parse_usd_and_create_subassets` 按 **prim 名**自动注册场景中的 RigidBody 为场景资产；任务代码用 `SceneEntityCfg("cube")` 引用抓取物体。**新场景抓取物体 prim 名必须保持 `cube`**。
- 成功条件 `cube_height_above_base` 只看物体 Z 高度，与形状无关。
- `scene.usd` / `cube.usd` 是二进制 USDC，必须用 Isaac Sim USD Python API 程序化构建。

### 改动清单

**1. 场景构建脚本** `scripts/tutorials/build_tape_ring_scene.py`（新建）

工作流程：复制源场景 → 打开 stage → 递归查找名为 `cube` 的 prim（位于 `/world/cube`）→ 生成环形体 mesh（内外圆柱壁 + 上下环形端面，4N 顶点）→ 绑定棕色 `UsdPreviewSurface` 材质 → 应用 RigidBodyAPI/CollisionAPI/MassAPI → 清除旧 cube payload 并显式声明 `cube` 为 Xform → 保存。

运行：
```bash
/isaac-sim/python.sh scripts/tutorials/build_tape_ring_scene.py \
    --src /workspace/leisaac/assets/scenes/table_with_cube/scene.usd \
    --dst /workspace/leisaac/assets/scenes/table_with_tape_ring/scene.usd \
    --outer 0.030 --inner 0.025 --height 0.020 \
    --color "0.45,0.27,0.13" --segments 48
```

**2. 场景配置** `leisaac/assets/scenes/simple.py`（追加）
```python
TABLE_WITH_TAPE_RING_USD_PATH = str(SCENES_ROOT / "table_with_tape_ring" / "scene.usd")
TABLE_WITH_TAPE_RING_CFG = AssetBaseCfg(spawn=sim_utils.UsdFileCfg(usd_path=TABLE_WITH_TAPE_RING_USD_PATH))
```

**3. 任务变体** `leisaac/tasks/lift_cube/lift_cube_tape_ring_env_cfg.py`（新建）

继承 `LiftCubeEnvCfg`，仅替换 `scene` 为 `TABLE_WITH_TAPE_RING_CFG`，**重写 `__post_init__`** 调用 `parse_usd_and_create_subassets(TABLE_WITH_TAPE_RING_USD_PATH, self)`（父类硬编码了 cube 路径）。domain randomization 仍按 `"cube"` 名随机化（prim 名未变）。

**4. 注册环境** `leisaac/tasks/lift_cube/__init__.py`（追加）
```python
gym.register(id="LeIsaac-SO101-LiftTapeRing-v0", entry_point="isaaclab.envs:ManagerBasedRLEnv",
    disable_env_checker=True,
    kwargs={"env_cfg_entry_point": f"{__name__}.lift_cube_tape_ring_env_cfg:LiftTapeRingEnvCfg"})
```

### 遥操作命令

```bash
docker exec -it leisaac-teleop /isaac-sim/python.sh \
  /workspace/leisaac/scripts/environments/teleoperation/teleop_se3_agent.py \
  --task=LeIsaac-SO101-LiftTapeRing-v0 \
  --teleop_device=so101leader --port=/dev/ttyACM0 \
  --num_envs=1 --device=cuda --enable_cameras
```

### 构建过程踩的坑（pxr API）

| 坑 | 解决 |
|---|---|
| `Set()` 不接受 numpy 标量 | 转 Python `float` |
| `ComputeExtent()` API 不存在 | 手动算 bbox |
| `ConnectToSource` 参数类型错误 | 传 `shader.ConnectableAPI()` 而非 `shader` |
| 旧 cube 是 payload 引用，`RemovePrim` 删不掉 | `payloadList.ClearEditsAndMakeExplicit()` |
| 清 payload 后 `cube` 丢 Xform 类型 | 显式 `typeName="Xform"`，否则 RigidBodyAPI 报错 |
| 动态体禁用 triangle-mesh 碰撞 | 用 `convexHull`（SDF 需场景级启用未生效） |
| `app.close()` 吞掉 Python traceback | 调试时 `try/except` 手动打印 |

---

## 四、夹爪合不拢问题（核心）

### 现象

遥操作时 arm 正常跟随 leader，但闭合 leader 夹爪后，仿真从端夹爪两指之间仍有 2-4cm 缝隙，夹不住薄物体（胶带环）。原版 LiftCube 因正方体厚（~4cm）未暴露此问题。重新标定 4 次无效。

### 排查过程

在 teleop 主循环加诊断打印，实测 leader 完全捏合时：
```
target = -0.1491 rad (-8.54°)
actual = -0.1492 rad (-8.55°)    # 误差仅 0.01°
```
**target 与 actual 完全一致**，逐一排除：

| 怀疑点 | 排除依据 |
|---|---|
| 标定问题 | 重新标定 4 次无效；leader 读数正常（闭合≈1.4，张开≈96.6） |
| 映射方向反 | arm 用同一套映射且跟随正常；actual 精确等于 target |
| actuator 没驱动 | actual 精确跟随 target |
| stiffness/力矩不足 | actual 精确到位，effort_limit=10 N·m 满值 |
| 力矩动态限制 | 无 ring 时也合不上 |

### 根因

SO101 仿真夹爪是单关节结构（`gripper` 关节驱动 `jaw` 活动指对基座开合）。原 USD 把关节下限设为 **-10°**，但 -10° 是"关节机械限位"——此时 jaw 指尖距基座被夹面还有 2-4cm。**限位设在 jaw 贴拢之前**，关节转到 -10° 被卡住，但夹爪没关严。

```
门框(基座)            门框
  ┃                    ┃
  ┃   门(jaw)          ┃
  ┃    ╲               ┃  门(jaw)
  ┃     ╲  ← 门缝2-4cm  ┃   ╱
  ┃      ╲              ┃  ╱
  ┃   门轴●             ┃ ●门轴
  -10°(限位卡住,有缝)    -12°(门贴框,闭合)
```

**-10° 是"门轴能转的极限"，不是"门贴上门框的位置"。** 建模者把限位设在 -10°，但 -10° 时门还没贴框。

### 为什么调标定/力矩都没用

```
leader 捏合 → norm=0 → target = 0/100×110 + (-10) = -10° → actual=-10°（PD 精确到位）
                    ↑ 映射下限锁死在 -10°               ↑ -10° 处几何有缝
```
- **标定**：只影响 leader→norm，无法突破 target 的 -10° 下限（映射公式下限锁死）
- **力矩/stiffness**：actual 已精确到 target，不是推不动
- **方向**：actual=target，方向正确

三者在数据上都没问题，瓶颈是**映射下限 -10° 对应的几何位置没贴拢**。

### 解决：放宽夹爪关节下限到 -12°

需同时改两处（必须一致）：

1. **USD** `assets/robots/so101_follower.usd`：`/so101_new_calib/joints/gripper` 的 `physics:lowerLimit`：`-10` → `-12`
2. **代码** `leisaac/assets/robots/lerobot.py`：`SO101_FOLLOWER_USD_JOINT_LIMLITS["gripper"]`：`(-10, 100.0)` → `(-12, 100.0)`

```python
# 改 USD（用 Isaac Sim python）
from pxr import Usd
stage = Usd.Stage.Open("assets/robots/so101_follower.usd")
stage.GetPrimAtPath("/so101_new_calib/joints/gripper").GetAttribute("physics:lowerLimit").Set(-12.0)
stage.Save()
```

### -12° 的确定方法（实测二分）

jaw 绕关节轴转，间距随角度单调减小。手工几何推导易因 jaw orient 旋转/关节轴方向出错（曾算出 -70°，错），USD mesh 距离扫描遇 API 阻碍。**实测二分最可靠**：

| 角度 | 现象 |
|---|---|
| -10° | 有缝 2-4cm |
| **-12°** | 恰好贴拢（轻微余量，不穿模） |
| -15° | 轻微穿模 |
| -25° | 严重穿模 |
| -57.76° | 严重穿模（actual 实测） |

3 次遥操作（-25/-15/-12）收敛，每次数据都是真实几何的直接反馈。

### 影响范围

改动 `so101_follower.usd` 和 `lerobot.py` 影响所有 SO101 从端任务。原 LiftCube（厚物体）不受影响；薄物体（胶带环）现在可夹住。原 USD 备份为 `so101_follower.usd.bak`，可随时还原。

---

## 五、最终改动文件清单

| 文件 | 改动 | 说明 |
|---|---|---|
| `assets/robots/so101_follower.usd` | `gripper` joint `lower` -10°→-12° | 夹爪闭合修复，备份 `.bak` |
| `source/leisaac/leisaac/assets/robots/lerobot.py` | `SO101_FOLLOWER_USD_JOINT_LIMLITS["gripper"]` (-10,100)→(-12,100) | 与 USD 一致 |
| `scripts/tutorials/build_tape_ring_scene.py` | 新建 | 场景构建脚本 |
| `source/leisaac/leisaac/assets/scenes/simple.py` | 追加 TAPE_RING 配置 | 场景注册 |
| `source/leisaac/leisaac/tasks/lift_cube/lift_cube_tape_ring_env_cfg.py` | 新建 | 任务变体 |
| `source/leisaac/leisaac/tasks/lift_cube/__init__.py` | 追加 gym.register | 注册 LeIsaac-SO101-LiftTapeRing-v0 |
| `assets/scenes/table_with_tape_ring/scene.usd` | 新建 | 胶带环场景 |
| `leisaac-docs-zh.md` | 更新 | §3.1.6 示例 + 故障排除条目 |

源码改动均挂载主机源码树进容器（`source` + `scripts`），免重建镜像，改动即时生效。

---

## 六、运行

```bash
docker exec -it leisaac-teleop /isaac-sim/python.sh \
  /workspace/leisaac/scripts/environments/teleoperation/teleop_se3_agent.py \
  --task=LeIsaac-SO101-LiftTapeRing-v0 \
  --teleop_device=so101leader --port=/dev/ttyACM0 \
  --num_envs=1 --device=cuda --enable_cameras
```

操作：Isaac Sim 窗口聚焦后按 `B` 开始遥操作；`R` 重置标记失败，`N` 重置标记成功。成功条件：胶带环抬起至基座上方 ≥0.20m。
