# 胶带环抓取场景设计 (Tape-Ring Lift Scene)

> 日期：2026-06-26
> 基础：leisaac:v1.0 镜像，Table with Cube 场景，SO101 Leader 遥操作

## 1. 目标

在 LeIsaac 中构建一个新场景，用**棕色胶带环**替代 Table with Cube 场景里的正方体，作为 SO101 遥操作的抓取对象。任务目标与 LiftCube 一致：把胶带环抬起至机器人基座上方 ≥0.20m。

胶带环规格：
- 外直径 70mm（外半径 35mm）
- 内直径 60mm（内半径 30mm，壁厚 5mm）
- 高度 15mm
- 颜色：棕色（base color `(0.45, 0.27, 0.13)`）

## 2. 关键约束（来自代码探查）

- `leisaac/tasks/lift_cube/lift_cube_env_cfg.py` 通过 `parse_usd_and_create_subassets(TABLE_WITH_CUBE_USD_PATH, self)` 自动注册场景 USD 中的 RigidBody prim 为场景资产，**资产名 = prim 名**。
- 任务代码（observations `object_grasped`、terminations `cube_height_above_base`）用 `SceneEntityCfg("cube")` 引用抓取物体。**因此新场景里抓取物体的 prim 名必须保持 `cube`**（已与用户确认）。
- 成功条件 `cube_height_above_base` 只看物体 Z 高度，与物体形状无关 → 对胶带环同样适用。
- `scene.usd` / `cube.usd` 是二进制 USDC，无法文本编辑，必须用 Isaac Sim USD Python API 程序化构建。

## 3. 方案

**方案 A（选定）：复制 USD + Python 脚本替换几何**

复制 `assets/scenes/table_with_cube/` → `assets/scenes/table_with_tape_ring/`，用一个 Isaac Sim headless 脚本打开 `scene.usd`，把 `cube` prim 内的 `Cube` 几何替换为胶带环 mesh，换棕色材质，保留 RigidBodyAPI/CollisionAPI/MassAPI。prim 名保持 `cube`，任务 mdp 逻辑零改动。

不选方案 B（就地改原场景，不可回退）和方案 C（全程序化重建桌面，工作量过大）。

## 4. 源码落地方式

容器源码改为**挂载主机源码树**（免重建镜像，改动即时生效）：
- `-v /home/ly/code/leisaac/leisaac/source:/workspace/leisaac/source:rw`
- `-v /home/ly/code/leisaac/leisaac/scripts:/workspace/leisaac/scripts:rw`
- leisaac 以 editable install 指向 `/workspace/leisaac/source/leisaac/leisaac`，主机 .py 改动即时生效。
- assets/datasets/.cache 维持现有挂载（`assets_download/assets` → `/workspace/leisaac/assets`）。

## 5. 改动清单

### 5.1 新增场景资源
`assets/scenes/table_with_tape_ring/`：
- `scene.usd`：从 table_with_cube 复制，`cube` prim 几何替换为胶带环。
- `textures/`、`cube/` 等子资源从 table_with_cube 复制（桌面纹理等保留）。

### 5.2 新增场景构建脚本
`scripts/tutorials/build_tape_ring_scene.py`：
- 用 `SimulationApp({"headless": True})` 启动。
- 打开复制后的 `scene.usd`。
- 定位顶层 `cube` Xform prim（含原 `Cube` Mesh 子 prim）。
- 删除原 `Cube` Mesh，新建环形体 Mesh（外⌀70/内⌀60/高15mm，参数化生成顶点/面：内外圆柱面 + 上下环形端面，每圆 48 段）。
- 应用棕色 `UsdShade.Material`，绑定到 mesh。
- 保留 `cube` Xform 上的 `PhysicsRigidBodyAPI`、`PhysicsCollisionAPI`、`PhysicsMassAPI`。
- 碰撞近似用三角 mesh（`meshSimplification`），不用 convex hull（convex 会填掉内孔，影响夹取）。
- 保存覆盖 `scene.usd`。
- 命令行参数：`--src`（源 scene.usd）、`--dst`（目标 scene.usd）、`--outer`/`--inner`/`--height`/`--color`。

### 5.3 新增场景配置
`source/leisaac/leisaac/assets/scenes/simple.py` 追加：
```python
TABLE_WITH_TAPE_RING_USD_PATH = str(SCENES_ROOT / "table_with_tape_ring" / "scene.usd")
TABLE_WITH_TAPE_RING_CFG = AssetBaseCfg(
    spawn=sim_utils.UsdFileCfg(usd_path=TABLE_WITH_TAPE_RING_USD_PATH),
)
```

### 5.4 新增任务变体
`source/leisaac/leisaac/tasks/lift_cube/lift_cube_tape_ring_env_cfg.py`：
```python
from configclass import configclass  # 实际用 isaaclab.utils.configclass
from leisaac.assets.scenes.simple import TABLE_WITH_TAPE_RING_CFG
from .lift_cube_env_cfg import LiftCubeEnvCfg, LiftCubeSceneCfg

class LiftTapeRingSceneCfg(LiftCubeSceneCfg):
    scene: AssetBaseCfg = TABLE_WITH_TAPE_RING_CFG.replace(prim_path="{ENV_REGEX_NS}/Scene")

@configclass
class LiftTapeRingEnvCfg(LiftCubeEnvCfg):
    scene: LiftTapeRingSceneCfg = LiftTapeRingSceneCfg(env_spacing=8.0)
    task_description: str = "Lift the brown tape ring up."
```
（viewer/robot 位姿、终止条件、domain randomization 全继承自 LiftCubeEnvCfg。）

### 5.5 注册新环境
`source/leisaac/leisaac/tasks/lift_cube/__init__.py` 追加：
```python
gym.register(
    id="LeIsaac-SO101-LiftTapeRing-v0",
    entry_point="isaaclab.envs:ManagerBasedRLEnv",
    disable_env_checker=True,
    kwargs={
        "env_cfg_entry_point": f"{__name__}.lift_cube_tape_ring_env_cfg:LiftTapeRingEnvCfg",
    },
)
```

## 6. 验证

1. **USD 完整性**：headless 打开新 `scene.usd`，Traverse 确认存在 `cube` prim 且带 RigidBodyAPI/CollisionAPI/MassAPI，几何为环形体 mesh。
2. **任务注册**：`python scripts/environments/list_envs.py` 确认 `LeIsaac-SO101-LiftTapeRing-v0` 出现。
3. **冒烟测试**：keyboard 设备 headless 启动新任务，确认场景加载、机器人 spawn、无 USD/路径报错。
4. **真臂遥操作**：SO101 Leader 实际抬起胶带环验证。

GPU 与 `isaac-lab` 容器的 RL 训练并发：验证用 Isaac Sim 进程单独串行起，若显存不足会报错，届时可暂停训练。

## 7. 运行命令

```bash
docker exec -it leisaac-teleop /isaac-sim/python.sh \
  /workspace/leisaac/scripts/environments/teleoperation/teleop_se3_agent.py \
  --task=LeIsaac-SO101-LiftTapeRing-v0 \
  --teleop_device=so101leader --port=/dev/ttyACM0 \
  --num_envs=1 --device=cuda --enable_cameras
```

## 8. 工作流编排

用 Workflow 编排**不占 GPU 的设计与代码生成**（GPU 任务由主循环串行执行，避免与 RL 训练并发崩溃）：

- **Phase 1 设计（并行 3 agent，屏障）**：独立产出 (a) 环形体 mesh 生成算法草案、(b) USD 编辑脚本结构草案、(c) 任务配置改动点清单。屏障后综合。
- **Phase 2 实现（串行 pipeline）**：agent A 写 `build_tape_ring_scene.py`；agent B 写 `simple.py`/`lift_cube_tape_ring_env_cfg.py`/`__init__.py` 改动。写到主机源码树。
- 工作流只产代码文件，不执行 Isaac Sim。
- **GPU 验证由主循环串行做**，结果回填最终总结。

## 9. 风险

- 胶带环扁平（15mm 高）、内孔 60mm，SO101 夹爪需夹外壁或卡内孔抬起。遥操作可行（人控），但自动策略成功率可能低于 cube。
- mesh 碰撞对薄环性能开销略大于 convex；用 `meshSimplification` 折中。
- USD 编辑脚本首次跑需启 SimulationApp（约 1-3 分钟 + GPU），与训练争显存。
