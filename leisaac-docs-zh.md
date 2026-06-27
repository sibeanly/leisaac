# LeIsaac 文档（完整中文汇总）

> 原文站点：https://lightwheelai.github.io/leisaac/
>
> LeIsaac 在 IsaacLab 中提供了基于 SO101 Leader（LeRobot）的遥操作功能，涵盖数据采集、数据转换以及后续的策略训练。
>
> 本汇总文档整理了该网站所有层级的文档内容，翻译为中文，并保留了所有代码块、命令、参数说明和链接。

---

## 目录

- [LeIsaac 文档（完整中文汇总）](#leisaac-文档完整中文汇总)
  - [目录](#目录)
  - [一、简介（Introduction）](#一简介introduction)
  - [二、入门指南（Getting Started）](#二入门指南getting-started)
    - [2.1 安装（Installation）](#21-安装installation)
    - [2.2 遥操作（Teleoperation）](#22-遥操作teleoperation)
    - [2.3 数据集回放（Dataset Replay）](#23-数据集回放dataset-replay)
    - [2.4 策略训练与推理（Policy Training \& Inference）](#24-策略训练与推理policy-training--inference)
  - [三、教程（Tutorials）](#三教程tutorials)
    - [3.1 添加自定义任务（Add Custom Task）](#31-添加自定义任务add-custom-task)
    - [3.2 LeIsaac × Marble](#32-leisaac--marble)
    - [3.3 LeIsaac × Cosmos](#33-leisaac--cosmos)
  - [四、额外功能（Extra Features）](#四额外功能extra-features)
    - [4.1 DigitalTwin 环境](#41-digitaltwin-环境)
    - [4.2 MimicGen 环境](#42-mimicgen-环境)
    - [4.3 EnvHub 支持](#43-envhub-支持)
    - [4.4 LeRobot 记录器（LeRobot Recorder）](#44-lerobot-记录器lerobot-recorder)
    - [4.5 状态机数据生成（State Machine）](#45-状态机数据生成state-machine)
  - [五、故障排除（Trouble Shooting）](#五故障排除trouble-shooting)
  - [六、云仿真（Cloud Simulation）](#六云仿真cloud-simulation)
    - [6.1 NVIDIA Brev](#61-nvidia-brev)
  - [七、资源（Resources）](#七资源resources)
    - [7.1 可用机器人（Available Robots）](#71-可用机器人available-robots)
    - [7.2 可用环境（Available Environments）](#72-可用环境available-environments)
    - [7.3 可用设备（Available Devices）](#73-可用设备available-devices)
    - [7.4 可用策略推理（Available Policy Inference）](#74-可用策略推理available-policy-inference)

---

## 一、简介（Introduction）

LeIsaac 在 [IsaacLab](https://isaac-sim.github.io/IsaacLab/main/index.html) 中提供了基于 SO101 Leader（[LeRobot](https://github.com/huggingface/lerobot)）的遥操作功能，涵盖数据采集、数据转换以及后续的策略训练。

- 🤖 我们在 IsaacLab 中使用 SO101 Follower 机器人（及其他相关机器人），并提供实用的遥操作方法。
- 🦾 基于状态机的脚本化策略支持无需人工遥操作的全自动数据采集。
- 🔄 提供可直接使用的脚本，将 HDF5 数据转换为 LeRobot 数据集格式。
- 🧠 利用仿真数据微调 [GR00T N1.5](https://github.com/NVIDIA/Isaac-GR00T)，并将策略部署到真实硬件上，未来还将支持更多策略。

**相关链接：**

- [IsaacLab](https://isaac-sim.github.io/IsaacLab/main/index.html)
- [LeRobot](https://github.com/huggingface/lerobot)
- [GR00T N1.5](https://github.com/NVIDIA/Isaac-GR00T)
- [Lightwheel AI](https://lightwheel.ai/)
- [GitHub 仓库](https://github.com/LightwheelAI/leisaac)

---

## 二、入门指南（Getting Started）

LeIsaac 入门指南包含以下四个步骤：

1. **安装** — 环境搭建
2. **遥操作** — 遥操作脚本
3. **数据集回放** — 在仿真中回放采集的数据集
4. **策略训练与推理** — 数据规范、策略训练与推理

---

### 2.1 安装（Installation）

#### 2.1.1 作为包安装

可以将 LeIsaac 作为依赖项安装。以下脚本会配置 IsaacLab、IsaacSim 以及所有必要组件。

```bash
conda create -n leisaac python=3.11
conda activate leisaac

# 安装 cuda-toolkit
conda install -c "nvidia/label/cuda-12.8.1" cuda-toolkit

# 安装 PyTorch（CUDA 12.8 wheels）
pip install -U torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu128

# 安装 LeIsaac 及 IsaacLab/IsaacSim 扩展
pip install 'leisaac[isaaclab] @ git+https://github.com/LightwheelAI/leisaac.git#subdirectory=source/leisaac' --extra-index-url https://pypi.nvidia.com
```

> **提示：** 作为包安装可能存在边界情况。如果遇到问题，请在 GitHub 上提交 issue，并考虑切换到从源码安装方式。

#### 2.1.2 从源码安装

也可以直接从源码安装以进行本地开发。首先克隆仓库及相关子模块：

```bash
git clone https://github.com/LightwheelAI/leisaac.git --recursive
```

然后参照 [IsaacLab 官方安装指南](https://isaac-sim.github.io/IsaacLab/main/source/setup/installation/index.html) 安装 IsaacLab：

```bash
# 创建并激活环境
conda create -n leisaac python=3.11
conda activate leisaac

# 安装 cuda-toolkit
conda install -c "nvidia/label/cuda-12.8.1" cuda-toolkit

# 安装 PyTorch
pip install -U torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu128

# 安装 IsaacSim
pip install --upgrade pip
pip install "isaacsim[all,extscache]==5.1.0" --extra-index-url https://pypi.nvidia.com

# 安装 IsaacLab
sudo apt install cmake build-essential
cd leisaac/dependencies/IsaacLab
./isaaclab.sh --install
```

最后，安装 leisaac 作为依赖：

```bash
cd ../..
pip install -e source/leisaac
```

**版本兼容性：**

| 依赖项 | IsaacSim 4.5 | IsaacSim 5.0 | IsaacSim 5.1 |
|--------|-------------|-------------|-------------|
| Python | 3.10 | 3.11 | 3.11 |
| IsaacLab | v2.1.1 | v2.2.1 | v2.3.0 |
| CUDA | 11.8 | 12.8 | 12.8 |
| PyTorch | 2.5.1 | 2.7.0 | 2.7.0 |

> 注意：如果你使用的是 50 系列 GPU，建议使用 IsaacSim 5.0+ 和 IsaacLab v2.2.1+。

#### 2.1.3 [可选] 安装 LeRobot

```bash
# 安装 lerobot 支持
pip install -e "source/leisaac[lerobot]"

# 修复 numpy 版本
pip install numpy==1.26.0
```

#### 2.1.4 资源准备

从 [Releases 页面](https://github.com/LightwheelAI/leisaac/releases/tag/v0.1.0) 下载示例场景，解压到 `assets` 目录。目录结构如下：

```
<assets>
├── robots/
│   └── so101_follower.usd
└── scenes/
    └── kitchen_with_orange/
        ├── scene.usd
        ├── assets
        └── objects/
            ├── Orange001
            ├── Orange002
            ├── Orange003
            └── Plate
```

**可用场景资源：**

| 场景名称 | 描述 | 下载链接 |
|---------|------|---------|
| Kitchen with Orange | 带有橙子的示例厨房场景 | [下载](https://github.com/LightwheelAI/leisaac/releases/tag/v0.1.0) |
| Lightwheel Toyroom | 带多种玩具的现代房间 | [下载](https://github.com/LightwheelAI/leisaac/releases/tag/v0.1.1) |
| Table with Cube | 带一个立方体的简单桌子 | [下载](https://github.com/LightwheelAI/leisaac/releases/tag/v0.1.2) |
| Lightwheel Bedroom | 带布料的逼真卧室场景 | [下载](https://github.com/LightwheelAI/leisaac/releases/tag/v0.2.0) |
| Lightwheel Loft | 大型二层 loft | [下载](https://github.com/LightwheelAI/leisaac/releases/tag/v0.3.0) |

也可从 [HuggingFace](https://huggingface.co/LightwheelAI/leisaac_env/tree/main) 下载场景。

#### 2.1.5 设备设置

使用 SO101 Leader 作为遥操作设备。请参照 [官方文档](https://huggingface.co/docs/lerobot/so101) 进行连接和配置。注意，不需要使用 LeRobot 仓库进行校准，LeIsaac 代码库提供了校准过程的引导步骤。

---

### 2.2 遥操作（Teleoperation）

#### 2.2.1 遥操作脚本

运行遥操作任务：

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --teleop_device=so101leader \
    --port=/dev/ttyACM0 \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras \
    --record \
    --dataset_file=./datasets/dataset.hdf5
```

**`teleop_se3_agent.py` 参数说明：**

| 参数 | 说明 |
|------|------|
| `--task` | 任务环境名称，例如 `LeIsaac-SO101-PickOrange-v0` |
| `--seed` | 环境随机种子，例如 `42` |
| `--teleop_device` | 遥操作设备类型：`so101leader`、`bi-so101leader`、`keyboard`、`gamepad`、`lekiwi-leader`、`lekiwi-keyboard`、`lekiwi-gamepad` |
| `--port` | 遥操作设备端口，例如 `/dev/ttyACM0` |
| `--remote_endpoint` | 远程 SO101Leader 的 ZMQ 端点（如 `tcp://192.168.1.10:5556`） |
| `--left_arm_port` | 左臂端口（仅 `bi-so101leader`） |
| `--right_arm_port` | 右臂端口（仅 `bi-so101leader`） |
| `--num_envs` | 并行仿真环境数量，通常为 `1` |
| `--device` | 计算设备，`cpu` 或 `cuda` |
| `--enable_cameras` | 启用摄像头传感器以采集视觉数据 |
| `--record` | 启用数据录制，保存为 HDF5 文件 |
| `--dataset_file` | 录制数据集保存路径 |
| `--resume` | 从已有数据集文件继续录制 |
| `--recalibrate` | 重新校准 SO101 Leader |
| `--quality` | 启用高质量渲染模式 |
| `--use_lerobot_recorder` | 使用 LeRobot 记录器 |
| `--lerobot_dataset_repo_id` | LeRobot 数据集仓库 ID |
| `--lerobot_dataset_fps` | LeRobot 数据集帧率 |

#### 2.2.2 远程遥操作

当主端臂连接在不同机器上时（例如 Isaac Sim 在云端 GPU 实例上，主端臂在笔记本上），可以通过 ZMQ 使用远程遥操作。

**工作原理：**

```
笔记本（主端臂）                         云端 GPU（Isaac Sim）
┌──────────────────────────┐  ZMQ PUB/SUB  ┌──────────────────────┐
│ so101_joint_state_server │──────────────►│ SO101LeaderRemote    │
│ 读取电机数据             │   tcp:5556    │ teleop_se3_agent.py  │
│ 50 Hz 频率               │               │ --remote_endpoint    │
└──────────────────────────┘               └──────────────────────┘
```

**前提条件：**

- 两台机器之间的网络连通性（直接连接或通过 SSH 隧道）
- 在 Isaac Sim 机器上安装 pyzmq：`pip install "source/leisaac[remote]"` 或 `pip install pyzmq`

**本地机器设置（主端臂所在机器）：**

```bash
pip install "source/leisaac[remote]"
```

> 注意：远程机器（Isaac Sim 机器）需要安装完整的仿真栈（PyTorch、Isaac Sim、IsaacLab），本地机器可跳过这些重量级依赖。

**使用方法：**

终端 1 — 本地机器（主端臂）：

```bash
python scripts/environments/teleoperation/so101_joint_state_server.py \
    --port /dev/ttyACM0 --id leader_arm --rate 50
```

终端 2 — 远程机器（Isaac Sim）：

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --teleop_device=so101leader \
    --remote_endpoint=tcp://<local-machine-ip>:5556 \
    --num_envs=1 --device=cuda --enable_cameras
```

**SSH 反向端口转发：**

如果云实例无法直接访问笔记本（例如在 NAT 或防火墙后）：

```bash
# 在笔记本上 — 将本地端口 5556 转发到远程机器的 localhost:5556
ssh -R 5556:localhost:5556 ubuntu@<cloud-instance-ip>
```

然后在远程机器上连接 `localhost`：

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --teleop_device=so101leader \
    --remote_endpoint=tcp://localhost:5556 \
    --num_envs=1 --device=cuda --enable_cameras
```

**参数说明：**

- `--remote_endpoint`：要订阅的 ZMQ 端点。设置后使用 `SO101LeaderRemote` 替代本地 `SO101Leader`
- `--id`（发布端）：校准 ID（默认 `leader_arm`），校准文件存储在 `scripts/environments/teleoperation/.cache/{id}.json`
- `--rate`（发布端）：电机读取频率 Hz（默认 50），30-50 Hz 对 LeIsaac 遥操作已足够
- `--recalibrate`（发布端）：强制重新校准

#### 2.2.3 操作说明

如果校准文件不存在，系统会提示校准 SO101 Leader。参考 [文档](https://huggingface.co/docs/lerobot/so101#calibration-video) 了解校准步骤。

进入 IsaacLab 窗口后，按键盘上的 `b` 键开始遥操作。如需重置环境：

- 按 `r` 键：重置环境并将任务标记为失败
- 按 `n` 键：重置环境并将任务标记为成功

> **重要：键盘焦点必须在 Isaac Sim 窗口上。** `B`/`R`/`N` 等控制键由 Isaac Sim 应用窗口通过 carb 输入订阅捕获（`omni.appwindow.get_default_app_window().get_keyboard()`），**不是终端 stdin**。底层逻辑（`leisaac/devices/device_base.py`）为：按 `B` 才会把 `_started` 置为 `True`，`advance()` 在 `_started` 为 `False` 时返回 `None`，主循环此时只调用 `env.render()` 而不执行 `env.step()`，因此从端机械臂不会运动。
>
> 常见误区：在 `docker exec -it ...` 的终端里按键，按键只会被终端吃掉（终端会原样回显 `b`/`B`），Isaac Sim 窗口并未收到，所以按 `B` 后遥操作"没反应"。
>
> **正确做法**：用鼠标点击 Isaac Sim 窗口使其获得键盘焦点，再按 `B` 开始遥操作；`R`/`N` 同理，必须对着 Isaac Sim 窗口按。判断是否成功：按 `B` 后移动手中的 SO101 Leader，仿真中的 SO101 Follower 应随之运动。

如果遇到权限错误（如 `ConnectionError`），可临时授权：

```bash
sudo chmod 666 /dev/ttyACM0
```

或将当前用户添加到 dialout 组（需要重启设备）：

```bash
sudo usermod -aG dialout $USER
```

---

### 2.3 数据集回放（Dataset Replay）

完成遥操作后，使用以下脚本在仿真环境中回放已采集的数据集：

```bash
python scripts/environments/teleoperation/replay.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras \
    --replay_mode=action \
    --dataset_file=./datasets/dataset.hdf5 \
    --select_episodes 1 2
```

**`replay.py` 参数说明：**

| 参数 | 说明 |
|------|------|
| `--task` | 任务环境名称 |
| `--num_envs` | 并行仿真环境数量，回放时通常设为 `1` |
| `--device` | 计算设备，`cpu` 或 `cuda` |
| `--enable_cameras` | 启用摄像头传感器以便可视化 |
| `--replay_mode` | 回放模式：`action`（动作）或 `state`（状态） |
| `--task_type` | 如果数据集是用键盘录制的，应设为 `keyboard`，否则保持默认 None |
| `--dataset_file` | 录制数据集的路径 |
| `--select_episodes` | 要回放的情节索引列表，留空则回放所有情节 |

> **提示：**
>
> - 如果使用 Leader 以外的设备（键盘/手柄）录制数据集，请将 `task_type` 设置为相应设备
> - 对于 Lekiwi 相关任务，默认 `task_type` 为 `lekiwi-leader`，使用其他设备时需要相应设置

---

### 2.4 策略训练与推理（Policy Training & Inference）

#### 2.4.1 数据规范

采集的遥操作数据以 HDF5 格式存储。使用以下脚本转换为 LeRobot 数据集格式：

首先安装 LeRobot 依赖：

```bash
pip install lerobot==0.3.3
pip install numpy==1.26.0
```

执行数据转换：

```bash
python scripts/convert/isaaclab2lerobot.py \
    --task_name=LeIsaac-SO101-PickOrange-v0 \
    --repo_id=EverNorif/so101_test_orange_pick \
    --hdf5_root=./datasets \
    --hdf5_files=dataset.hdf5
```

**`isaaclab2lerobot.py` 参数说明：**

| 参数 | 说明 |
|------|------|
| `--task_name` | 任务名称 |
| `--task_type` | 任务类型，键盘/手柄录制需设为 `keyboard`/`gamepad` |
| `--repo_id` | LeRobot 数据集 repo-id |
| `--fps` | 数据集帧率 |
| `--hdf5_root` | HDF5 根目录 |
| `--hdf5_files` | HDF5 文件名（逗号分隔） |
| `--task_description` | 任务描述 |
| `--push_to_hub` | 是否推送至 Hugging Face Hub |

> 还提供了 `isaaclab2lerobotv3.py` 脚本用于转换为 LeRobot Dataset v3 格式。

#### 2.4.2 策略训练

以 [GR00T N1.5](https://github.com/NVIDIA/Isaac-GR00T) 为例，参考 [nvidia/gr00t-n1.5-so101-tuning](https://huggingface.co/blog/nvidia/gr00t-n1-5-so101-tuning) 使用 LeRobot 数据进行微调。

#### 2.4.3 策略推理

安装额外依赖：

```bash
pip install -e "source/leisaac[gr00t]"
```

启动 GR00T N1.5 推理服务器（参考 [GR00T 评估文档](https://github.com/NVIDIA/Isaac-GR00T/tree/4af2b622892f7dcb5aae5a3fb70bcb02dc217b96?tab=readme-ov-file#4-evaluation)），然后使用推理脚本：

```bash
python scripts/evaluation/policy_inference.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --eval_rounds=10 \
    --policy_type=gr00tn1.5 \
    --policy_host=localhost \
    --policy_port=5555 \
    --policy_timeout_ms=5000 \
    --policy_action_horizon=16 \
    --policy_language_instruction="Pick up the orange and place it on the plate" \
    --device=cuda \
    --enable_cameras
```

**`policy_inference.py` 参数说明：**

| 参数 | 说明 |
|------|------|
| `--task` | 推理任务环境名称 |
| `--seed` | 环境随机种子 |
| `--episode_length_s` | 每回合时长（秒，默认 `60`） |
| `--eval_rounds` | 评估回合数，0 表示不添加超时终止 |
| `--policy_type` | 策略类型：`gr00tn1.5`、`gr00tn1.6`、`lerobot-<model_type>` |
| `--policy_host` | 策略服务器主机地址 |
| `--policy_port` | 策略服务器端口 |
| `--policy_timeout_ms` | 策略服务器超时时间（毫秒） |
| `--policy_action_horizon` | 每次推理预测的动作数量 |
| `--policy_language_instruction` | 语言指令 |
| `--policy_checkpoint_path` | 策略检查点路径 |
| `--device` | 计算设备 |

#### 2.4.4 示例

项目提供了仿真采集的数据及对应的微调 GR00T N1.5 策略：

- **数据集：** [https://huggingface.co/datasets/LightwheelAI/leisaac-pick-orange](https://huggingface.co/datasets/LightwheelAI/leisaac-pick-orange)
- **策略：** [https://huggingface.co/LightwheelAI/leisaac-pick-orange-v0](https://huggingface.co/LightwheelAI/leisaac-pick-orange-v0)

---

## 三、教程（Tutorials）

### 3.1 添加自定义任务（Add Custom Task）

本教程引导你在 LeIsaac 中添加自定义任务和环境。

#### 3.1.1 准备 USD 场景

假设已拥有环境的 USD 文件。可从 [此处](https://drive.google.com/file/d/1hRmwRzN_9SXLD0_CJjkT4LsQ7zNpeesc/view?usp=sharing) 下载示例场景（包含一张桌子、一个红色立方体和一个盒子）。将文件放置在项目根目录的 `assets/scenes` 下。

#### 3.1.2 添加资产配置

在 `source/leisaac/leisaac` 中创建 `assets/scenes/custom_scene.py`：

```python
from pathlib import Path
import isaaclab.sim as sim_utils
from isaaclab.assets import AssetBaseCfg
from leisaac.utils.constant import ASSETS_ROOT

"""Configuration for the Custom Scene"""

SCENES_ROOT = Path(ASSETS_ROOT) / "scenes"
CUSTOM_SCENE_USD_PATH = str(SCENES_ROOT / "custom_scene" / "scene.usd")

CUSTOM_SCENE_CFG = AssetBaseCfg(
    spawn=sim_utils.UsdFileCfg(
        usd_path=CUSTOM_SCENE_USD_PATH,
    )
)
```

#### 3.1.3 实现任务代码

创建 `tasks/custom_task/custom_task_env_cfg.py`：

```python
import torch
from isaaclab.assets import AssetBaseCfg, RigidObject
from isaaclab.managers import SceneEntityCfg
from isaaclab.managers import TerminationTermCfg as DoneTerm
from isaaclab.utils import configclass

from leisaac.assets.scenes.custom_scene import CUSTOM_SCENE_CFG, CUSTOM_SCENE_USD_PATH
from leisaac.utils.general_assets import parse_usd_and_create_subassets
from leisaac.utils.domain_randomization import domain_randomization, randomize_object_uniform

from ..template import (
    SingleArmObservationsCfg,
    SingleArmTaskEnvCfg,
    SingleArmTaskSceneCfg,
    SingleArmTerminationsCfg,
)


@configclass
class CustomTaskSceneCfg(SingleArmTaskSceneCfg):
    """Scene configuration for the custom task."""
    scene: AssetBaseCfg = CUSTOM_SCENE_CFG.replace(prim_path="{ENV_REGEX_NS}/Scene")


def cube_in_box(env, cube_cfg: SceneEntityCfg, box_cfg: SceneEntityCfg,
                x_range, y_range, height_threshold):
    """Termination condition for the object in the box."""
    done = torch.ones(env.num_envs, dtype=torch.bool, device=env.device)
    box: RigidObject = env.scene[box_cfg.name]
    box_x = box.data.root_pos_w[:, 0] - env.scene.env_origins[:, 0]
    box_y = box.data.root_pos_w[:, 1] - env.scene.env_origins[:, 1]
    cube: RigidObject = env.scene[cube_cfg.name]
    cube_x = cube.data.root_pos_w[:, 0] - env.scene.env_origins[:, 0]
    cube_y = cube.data.root_pos_w[:, 1] - env.scene.env_origins[:, 1]
    cube_z = cube.data.root_pos_w[:, 2] - env.scene.env_origins[:, 2]
    done = torch.logical_and(done, cube_x < box_x + x_range[1])
    done = torch.logical_and(done, cube_x > box_x + x_range[0])
    done = torch.logical_and(done, cube_y < box_y + y_range[1])
    done = torch.logical_and(done, cube_y > box_y + y_range[0])
    done = torch.logical_and(done, cube_z < height_threshold)
    return done


@configclass
class TerminationsCfg(SingleArmTerminationsCfg):
    """Termination configuration for the custom task."""
    success = DoneTerm(
        func=cube_in_box,
        params={
            "cube_cfg": SceneEntityCfg("cube"),
            "box_cfg": SceneEntityCfg("box"),
            "x_range": (-0.05, 0.05),
            "y_range": (-0.05, 0.05),
            "height_threshold": 0.10,
        },
    )


@configclass
class CustomTaskEnvCfg(SingleArmTaskEnvCfg):
    """Configuration for the custom task environment."""
    scene: CustomTaskSceneCfg = CustomTaskSceneCfg(env_spacing=8.0)
    observations: SingleArmObservationsCfg = SingleArmObservationsCfg()
    terminations: TerminationsCfg = TerminationsCfg()
    task_description: str = "pick up the red cube and place it into the box."

    def __post_init__(self):
        super().__post_init__()
        self.viewer.eye = (-0.2, -1.0, 0.5)
        self.viewer.lookat = (0.6, 0.0, -0.2)
        self.scene.robot.init_state.pos = (0.35, -0.64, 0.01)
        parse_usd_and_create_subassets(CUSTOM_SCENE_USD_PATH, self)
        domain_randomization(
            self,
            random_options=[
                randomize_object_uniform(
                    "cube",
                    pose_range={
                        "x": (-0.05, 0.05),
                        "y": (-0.05, 0.05),
                        "z": (0.0, 0.0),
                    },
                ),
                randomize_object_uniform(
                    "box",
                    pose_range={
                        "x": (-0.05, 0.05),
                        "y": (-0.05, 0.05),
                        "z": (0.0, 0.0),
                    },
                ),
            ],
        )
```

#### 3.1.4 注册环境

创建 `tasks/custom_task/__init__.py`：

```python
import gymnasium as gym

gym.register(
    id="LeIsaac-SO101-CustomTask-v0",
    entry_point="isaaclab.envs:ManagerBasedRLEnv",
    disable_env_checker=True,
    kwargs={
        "env_cfg_entry_point": f"{__name__}.custom_task_env_cfg:CustomTaskEnvCfg",
    },
)
```

#### 3.1.5 运行任务

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-CustomTask-v0 \
    --teleop_device=so101leader \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras
```

#### 3.1.6 示例：用胶带环替代正方体（Table with Tape Ring）

本示例演示如何在不改动任务 mdp 逻辑的前提下，用一个自定义物体替换现有场景中的抓取对象。这里把 `Table with Cube` 场景里的红色正方体替换为**棕色胶带环**（外径 6cm、内径 5cm、壁厚 5mm、高 2cm），并复用 LiftCube 的"抬起即成功"任务。

**关键思路：**

- `parse_usd_and_create_subassets` 按 **prim 名**自动注册场景中的 RigidBody 为场景资产；任务代码用 `SceneEntityCfg("cube")` 引用抓取物体。因此**新场景里抓取物体的 prim 名必须保持 `cube`**，只替换其几何与材质，即可零改动复用 LiftCube 的 observations/terminations。
- 原场景的 `cube` prim 通过 **payload** 引用 `cube/cube.usd`，`RemovePrim` 无法删除被引用的内容，需用 `payloadList.ClearEditsAndMakeExplicit()` 清除 payload；清除后 `cube` 丢失 Xform 类型，需显式 `typeName="Xform"`，否则 RigidBodyAPI 报 "applied to a non-xformable primitive"。
- 胶带环是**动态刚体**（被抬起时移动），PhysX 禁止 triangle-mesh / meshSimplification / approx=none 碰撞作用于动态体（会崩溃或回退到 convexHull）。SDF 碰撞能保住内孔但需场景级启用；最稳妥的做法是 `convexHull`（视觉仍是带孔的环，碰撞为凸盘，夹爪可夹持抬起）。

**1. 构建场景 USD：** 使用 `scripts/tutorials/build_tape_ring_scene.py`（基于 Isaac Sim 的 `pxr` USD API，headless 运行）：

```bash
# 在 leisaac 容器内
/isaac-sim/python.sh scripts/tutorials/build_tape_ring_scene.py \
    --src /workspace/leisaac/assets/scenes/table_with_cube/scene.usd \
    --dst /workspace/leisaac/assets/scenes/table_with_tape_ring/scene.usd \
    --outer 0.030 --inner 0.025 --height 0.020 \
    --color "0.45,0.27,0.13" --segments 48
```

脚本工作流程：复制源场景 → 打开 stage → 递归查找名为 `cube` 的 prim → 生成环形体 mesh（内外圆柱壁 + 上下环形端面，4N 顶点）→ 绑定棕色 `UsdPreviewSurface` 材质 → 应用 RigidBodyAPI/CollisionAPI/MassAPI（convexHull 碰撞）→ 清除旧 cube payload 并显式声明 `cube` 为 Xform → 保存。

> 注意 pxr 的几个坑：`Set()` 不接受 numpy 标量（需转 Python `float`）；`UsdShade` 的 `ConnectToSource` 需传 `shader.ConnectableAPI()` 而非 `shader`；`app.close()` 会吞掉 Python traceback，调试时需在 `finally` 前手动 `try/except` 打印。

**2. 注册场景与任务：**

- 在 `leisaac/assets/scenes/simple.py` 追加 `TABLE_WITH_TAPE_RING_USD_PATH` / `TABLE_WITH_TAPE_RING_CFG`。
- 新建 `leisaac/tasks/lift_cube/lift_cube_tape_ring_env_cfg.py`，继承 `LiftCubeEnvCfg`，仅替换 `scene` 为 `TABLE_WITH_TAPE_RING_CFG`，并**重写 `__post_init__`** 调用 `parse_usd_and_create_subassets(TABLE_WITH_TAPE_RING_USD_PATH, self)`（父类硬编码了 cube 路径）。domain randomization 仍按 `"cube"` 名随机化（prim 名未变）。
- 在 `leisaac/tasks/lift_cube/__init__.py` 注册 `LeIsaac-SO101-LiftTapeRing-v0`。

**3. 遥操作：**

```bash
docker exec -it leisaac-teleop /isaac-sim/python.sh \
  /workspace/leisaac/scripts/environments/teleoperation/teleop_se3_agent.py \
  --task=LeIsaac-SO101-LiftTapeRing-v0 \
  --teleop_device=so101leader --port=/dev/ttyACM0 \
  --num_envs=1 --device=cuda --enable_cameras
```

成功条件沿用 LiftCube：胶带环被抬起至机器人基座上方 ≥0.20m。按 `B` 开始（务必在 Isaac Sim 窗口聚焦时按键，见 §2.2.3 / §五）。

---

### 3.2 LeIsaac × Marble

本教程介绍如何将 **Marble-Generate** 场景集成到 LeIsaac 中，在大规模泛化环境中构建和评估多样化的具身任务。

#### 3.2.1 第一步：准备 USD 场景

**1.1 在 Marble 中创建世界**

导航至 [Marble 平台](https://marble.worldlabs.ai/)，按照 [Marble 文档](https://docs.worldlabs.ai/) 创建自定义世界模型并下载 Splats 文件（`.ply`）和高质量网格（`.glb`）。

**1.2 将 PLY 转换为 USDZ**

安装 [3DGrut](https://github.com/nv-tlabs/3dgrut) 并运行：

```bash
python -m threedgrut.export.scripts.ply_to_usd path/to/your/splats.ply \
    --output_file path/to/output.usdz
```

**1.3 在 Isaac Sim 中集成高斯渲染与网格碰撞**

1. 双击 `.usdz` 文件解压，找到 `default.usda` 拖入 Isaac Sim 视口
2. 创建 Xform，添加 `texture_mesh.glb` 引用作为碰撞网格
3. 对齐高斯场景与网格几何体
4. 为网格配置刚体 + 碰撞体（Rigid Body with Colliders Preset，启用 Kinematic）
5. 碰撞体 Approximation 设为 `meshSimplification`
6. 可选隐藏网格几何体，仅保持高斯泼溅可见
7. 保存为单个 USD 文件（如 `scene.usd`）

#### 3.2.2 第二步：任务场景组合

**记录机器人位姿变换：**

在 Isaac Sim 中加载背景 USD，创建 Xform 并添加 SO101 Follower USD 作为引用，将机器人拖动到目标位姿，记录位姿变换（平移 x,y,z 和四元数朝向 w,x,y,z）。

**运行场景组合脚本：**

```bash
python scripts/tutorials/marble_compose.py \
  --task your_task \
  --background path/to/background_scene.usd \
  --output path/to/output.usd \
  --assets-base /path/to/assets \
  --target-pos X Y Z \
  --target-quat W X Y Z
```

**`marble_compose.py` 参数说明：**

| 参数 | 说明 |
|------|------|
| `--task` | 任务类型（`toys`、`orange`、`cloth`、`cube`） |
| `--background` | 背景场景 USD 路径 |
| `--output` | 输出 USD 路径 |
| `--assets-base` | 任务相关资产 USD 基目录 |
| `--target-pos` | 机器人位置 (x, y, z) |
| `--target-quat` | 机器人朝向四元数 (w, x, y, z) |
| `--include-table` | 包含特定任务的桌面资产 |
| `--dual-arm` | 启用双臂配置 |

**桌面替换（适用于 cloth 和 toys 任务）：**

```bash
python scripts/tutorials/marble_compose.py \
  --task your_task \
  --background path/to/scene.usd \
  --output path/to/output.usd \
  --assets-base /path/to/assets \
  --target-pos X Y Z \
  --target-quat W X Y Z \
  --include-table
```

**双臂配置：**

```bash
python scripts/tutorials/marble_compose.py \
  --task your_task \
  --background path/to/scene.usd \
  --output path/to/output.usd \
  --assets-base /path/to/assets \
  --target-pos X Y Z \
  --target-quat W X Y Z \
  --include-table \
  --dual-arm
```

#### 3.2.3 第三步：验证场景

更新场景配置文件中的 USD 路径后，使用遥操作脚本验证：

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-CleanToyTable-v0 \
    --teleop_device=so101leader \
    --port=/dev/ttyACM0 \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras \
    --record \
    --dataset_file=./datasets/dataset.hdf5
```

---

### 3.3 LeIsaac × Cosmos

本教程扩展 LeIsaac，集成 **Cosmos-Predict2.5** 和 **GR00T-Dreams IDM**，构建可扩展的视频到动作数据生成流水线。

**概述：**

1. 使用 LeIsaac 采集 HDF5 数据集并转换为 LeRobot 数据集
2. 后训练 Cosmos-Predict2.5，运行推理生成合成视频
3. 微调 IDM，从合成视频推断机器人动作
4. 将数据转换为可回放的 LeIsaac HDF5 数据集并评估

#### 3.3.1 第一步：数据采集

**1.1 采集 HDF5 数据集：** 使用 LeIsaac 遥操作采集演示数据，参考 [遥操作文档](#22-遥操作teleoperation)。

**1.2 转换为 LeRobot 格式：** 参考 [数据规范](#241-数据规范)，将 HDF5 转换为 LeRobot 数据集。

> **重要：** 确保所有输出视频使用 H.264（h264）编码，而非 AV1。修改 `isaaclab2lerobot.py` 中的 `"video.codec": "av1"` 为 `"video.codec": "h264"`。

#### 3.3.2 第二步：使用 Cosmos-Predict2.5 生成视频

**2.1 安装 Cosmos-Predict2.5：** 参考 [官方安装指南](https://github.com/nvidia-cosmos/cosmos-predict2.5/blob/main/docs/setup.md)。

**2.2 准备后训练数据集：**

数据集文件夹格式：

```
cosmos-predict2.5/datasets/benchmark_train/<task_name>/
├── metas/
│   ├── *.txt
├── videos/
│   ├── *.mp4
```

1. 从 LeRobot 数据集复制 MP4 视频
2. 重命名为序号：`1.mp4`、`2.mp4`...
3. 创建对应提示文件，使用任务描述文本

**2.3 后训练 Cosmos-Predict2.5：** 参考 [官方后训练指南](https://github.com/nvidia-cosmos/cosmos-predict2.5/blob/main/docs/post-training_video2world_gr00t.md)。

**2.4 运行推理生成视频：** 使用提供的 `generate_batch_config.py` 脚本生成批量推理配置。

#### 3.3.3 第三步：使用 IDM 推断动作

**3.1 安装 IDM 环境：** IDM 需要 Cosmos-Predict2 环境，参考 [官方文档](https://github.com/nvidia-cosmos/cosmos-predict2/blob/main/documentations/post-training_video2world_gr00t.md)。

**3.2 微调 IDM：** 参考 [GR00T-Dreams 文档](https://github.com/NVIDIA/GR00T-Dreams?tab=readme-ov-file#optional-33-training-custom-idm-model)，添加 SO101 模态配置并运行训练。

**3.3 提取动作：** 使用 IDM 推理脚本从 Cosmos 生成的视频中提取动作轨迹，输出 LeRobot 格式。

#### 3.3.4 第四步：在 LeIsaac 中回放和评估

**4.1 转换 IDM 输出为 HDF5：**

```bash
python scripts/convert/lerobot2isaaclab.py \
    --lerobot_dir <path_to_idm_output_lerobot> \
    --output_hdf5 <path_to_idm_output_hdf5> \
    --column_keys action observation.state
```

**4.2 合并源数据集：**

```bash
python scripts/tutorials/cosmos_merge.py \
    --lerobot_hdf5 <path_to_idm_output_hdf5> \
    --source_hdf5 <path_to_source_leisaac_hdf5> \
    --output_hdf5 <path_to_output_hdf5>
```

**4.3 回放生成的数据集：** 参考 [数据集回放](#23-数据集回放dataset-replay) 的详细说明。

---

## 四、额外功能（Extra Features）

### 4.1 DigitalTwin 环境

**DigitalTwin 环境：让 Sim2Real 变得简单**

借鉴自 [SIMPLER](https://simpler-env.github.io/) 和 [ManiSkill](https://github.com/haosulab/ManiSkill)，实现 DigitalTwin 环境。该功能允许在仿真环境中用真实背景图像替换背景，同时保留机械臂和交互对象等前景元素，缩小仿真与现实的差距，实现更好的 sim2real 迁移。

只需创建一个继承自 `ManagerBasedRLDigitalTwinEnvCfg` 的任务配置类并通过相应环境启动。可指定 `overlay_mode`、背景图像路径以及要保留的前景环境组件。

参考示例：[LiftCubeDigitalTwinEnvCfg](https://github.com/LightwheelAI/leisaac/blob/main/source/leisaac/leisaac/tasks/lift_cube/lift_cube_env_cfg.py)

---

### 4.2 MimicGen 环境

**MimicGen 环境：从示范数据中生成新数据**

集成 IsaacLab MimicGen，能够根据专家示范自动生成额外的示范数据。

**使用流程：**

1. **记录示范数据：** 参考遥操作脚本录制若干示范数据

2. **转换动作为 IK 格式：**
   ```bash
   python scripts/mimic/eef_action_process.py \
       --input_file ./datasets/mimic-lift-cube-example.hdf5 \
       --output_file ./datasets/processed_mimic-lift-cube-example.hdf5 \
       --to_ik --headless
   ```

3. **子任务标注：**
   ```bash
   python scripts/mimic/annotate_demos.py \
       --device cuda \
       --task LeIsaac-SO101-LiftCube-Mimic-v0 \
       --input_file ./datasets/processed_mimic-lift-cube-example.hdf5 \
       --output_file ./datasets/annotated_mimic-lift-cube-example.hdf5 \
       --enable_cameras
   ```

4. **数据生成：**
   ```bash
   python scripts/mimic/generate_dataset.py \
       --device cuda \
       --num_envs 1 \
       --generation_num_trials 10 \
       --input_file ./datasets/annotated_mimic-lift-cube-example.hdf5 \
       --output_file ./datasets/generated_mimic-lift-cube-example.hdf5 \
       --enable_cameras
   ```

5. **转换回关节动作：**
   ```bash
   python scripts/mimic/eef_action_process.py \
       --input_file ./datasets/generated_mimic-lift-cube-example.hdf5 \
       --output_file ./datasets/final_generated_mimic-lift-cube-example.hdf5 \
       --to_joint --headless
   ```

6. **查看回放效果**

> 根据采集数据使用的设备，需通过 `--task_type` 指定相应的任务类型。

**示例数据：**

- [原始采集数据](https://huggingface.co/spaces/lerobot/visualize_dataset?path=%2FLightwheelAI%2Fleisaac-pick-orange%2Fepisode_0)
- [MimicGen 生成数据](https://huggingface.co/spaces/lerobot/visualize_dataset?path=%2FLightwheelAI%2Fleisaac-pick-orange-mimic-v0%2Fepisode_0)

---

### 4.3 EnvHub 支持

**EnvHub：通过 HuggingFace 分享 LeIsaac 环境**

EnvpHub 是 Hugging Face 的可复现环境中心，"spin up a packaged simulation with one line, experiment immediately, and publish your own tasks for the community."

**环境设置：**

```bash
conda create -n leisaac_envhub python=3.11
conda activate leisaac_envhub
conda install -c "nvidia/label/cuda-12.8.1" cuda-toolkit
pip install -U torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu128
pip install 'leisaac[isaaclab] @ git+https://github.com/LightwheelAI/leisaac.git#subdirectory=source/leisaac' --extra-index-url https://pypi.nvidia.com
pip install lerobot==0.4.1
pip install numpy==1.26.0
```

**随机动作示例：**

```python
import torch
from lerobot.envs.factory import make_env

# 从 hub 加载
envs_dict = make_env("LightwheelAI/leisaac_env:envs/so101_pick_orange.py", n_envs=1, trust_remote_code=True)

# 访问环境
suite_name = next(iter(envs_dict))
sync_vector_env = envs_dict[suite_name][0]

# 从 sync vector env 中获取 isaac 环境
env = sync_vector_env.envs[0].unwrapped

# 像使用任何 gym 环境一样使用它
obs, info = env.reset()
while True:
    action = torch.tensor(env.action_space.sample())
    obs, reward, terminated, truncated, info = env.step(action)
    if terminated or truncated:
        obs, info = env.reset()
env.close()
```

**遥操作示例：** 参考完整代码 `envhub_teleop_example.py` 脚本。

**EnvHub 当前支持的环境：**

- `so101_pick_orange`
- `so101_lift_cube`
- `so101_clean_toytable`
- `bi_so101_fold_cloth`

通过指定不同脚本切换任务：

```python
envs_dict_pick_orange = make_env("LightwheelAI/leisaac_env:envs/so101_pick_orange.py", n_envs=1, trust_remote_code=True)
envs_dict_lift_cube = make_env("LightwheelAI/leisaac_env:envs/so101_lift_cube.py", n_envs=1, trust_remote_code=True)
envs_dict_clean_toytable = make_env("LightwheelAI/leisaac_env:envs/so101_clean_toytable.py", n_envs=1, trust_remote_code=True)
envs_dict_fold_cloth = make_env("LightwheelAI/leisaac_env:envs/bi_so101_fold_cloth.py", n_envs=1, trust_remote_code=True)
```

> 使用 `bi_so101_fold_cloth` 时，获取环境后需要立即调用 `env.initialize()`。

---

### 4.4 LeRobot 记录器（LeRobot Recorder）

**LeRobot 数据集记录器：在遥操作过程中直接录制 LeRobot 格式的数据集**

LeRobot Recorder 替换默认的记录管理器，使用 `LeRobotRecorderManager`。每个环境步骤完成后：

1. **数据收集**：收集观测数据（关节位置、相机图像等）和动作数据
2. **格式转换**：通过 `build_lerobot_frame` 转换为 LeRobot 帧格式
3. **缓冲区管理**：将帧数据添加到缓冲区
4. **回合处理**：成功则调用 `flush()` 保存，失败则调用 `clear()` 清空

LeIsaac 自动跳过每回合前 5 帧，避免初始状态不稳定影响数据质量。

**使用方式：**

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --teleop_device=so101leader \
    --port=/dev/ttyACM0 \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras \
    --record \
    --use_lerobot_recorder \
    --lerobot_dataset_repo_id=EverNorif/test_lerobot_recorder \
    --lerobot_dataset_fps=30
```

**参数说明：**

| 参数 | 说明 |
|------|------|
| `--use_lerobot_recorder` | 启用 LeRobot 格式记录器 |
| `--lerobot_dataset_repo_id` | HuggingFace 数据集仓库 ID（格式：`用户名/仓库名`） |
| `--lerobot_dataset_fps` | 数据集帧率，通常设为 30 FPS |

> 集成 LeRobot Recorder 可能导致遥操作出现轻微延迟。

---

### 4.5 状态机数据生成（State Machine）

状态机模块提供无需人工遥操作的自动化数据采集功能，适用于操作任务。它运行预设策略并将示范记录为 HDF5 数据集。

**录制：**

```bash
python scripts/datagen/state_machine/generate.py \
    --task LeIsaac-SO101-PickOrange-v0 \
    --num_envs 1 \
    --device cuda \
    --enable_cameras \
    --record \
    --dataset_file ./datasets/pick_orange.hdf5 \
    --num_demos 50
```

**`generate.py` 参数说明：**

| 参数 | 说明 |
|------|------|
| `--task` | 任务环境名称 |
| `--num_envs` | 并行环境数量 |
| `--device` | 计算设备 |
| `--enable_cameras` | 启用相机传感器 |
| `--seed` | 环境随机种子 |
| `--record` | 启用录制 |
| `--dataset_file` | 数据集保存路径 |
| `--resume` | 从已有文件继续录制 |
| `--num_demos` | 需要录制的成功示范次数，0 表示无限 |
| `--step_hz` | 环境步进频率（Hz，默认 60） |
| `--quality` | 高质量渲染模式 |
| `--use_lerobot_recorder` | 直接以 LeRobot 格式录制 |
| `--lerobot_dataset_repo_id` | HuggingFace 仓库 ID |
| `--lerobot_dataset_fps` | LeRobot 数据集帧率 |

> 抓取成功率取决于物体的生成位置。调整配置文件中的生成位置可显著提升成功率。

**回放：**

```bash
python scripts/datagen/state_machine/replay.py \
    --task LeIsaac-SO101-PickOrange-v0 \
    --dataset_file ./datasets/pick_orange.hdf5 \
    --task_type so101_state_machine \
    --select_episodes 0 \
    --device cuda \
    --enable_cameras \
    --replay_mode action
```

**添加新任务：**

1. 在 `source/leisaac/leisaac/datagen/state_machine/` 下实现 `StateMachineBase` 子类
2. 在 `scripts/datagen/state_machine/generate.py` 的 `TASK_REGISTRY` 中注册

```python
TASK_REGISTRY = {
    "LeIsaac-SO101-PickOrange-v0": (PickOrangeStateMachine, "so101_state_machine"),
    "LeIsaac-MY-NewTask-v0":       (MyNewStateMachine,      "so101_state_machine"),
}
```

---

## 五、故障排除（Trouble Shooting）

### SO101 仿真夹爪合不拢（薄物体夹不住）

**现象**：遥操作时 arm 正常跟随 leader，但闭合 leader 夹爪后，仿真从端夹爪两指之间仍有 2-4cm 缝隙，夹不住薄物体（如胶带环）。原版 LiftCube 因正方体厚（~4cm）未暴露此问题。

**根因**：SO101 仿真夹爪是单关节结构（`gripper` 关节驱动 `jaw` 活动指对基座开合）。原 USD 把关节下限设为 **-10°**，但 -10° 是"关节机械限位"，此时 jaw 指尖距基座被夹面还有 2-4cm——**限位设在 jaw 贴拢之前**，关节转到 -10° 被卡住，但夹爪没关严。

映射链路（解释为何调标定/力矩都无用）：
```
leader 捏合 → norm=0 → target = 0/100×110 + (-10) = -10° → actual=-10°（PD 精确到位）
                    ↑ 映射下限锁死在 -10°               ↑ -10° 处几何有缝
```
- 标定只影响 leader→norm，无法突破 target 的 -10° 下限
- actual 已精确跟随 target（实测误差 0.01°），非力矩/stiffness 不足
- 方向正确（actual = target）

瓶颈在**映射下限 -10° 对应的几何位置没贴拢**，非映射/驱动问题。

**解决**：放宽夹爪关节下限到 **-12°**（jaw 指尖恰好贴拢基座的角度，实测二分确定）。需同时改两处（必须一致）：

1. USD `assets/robots/so101_follower.usd`：`/so101_new_calib/joints/gripper` 的 `physics:lowerLimit`：`-10` → `-12`
2. 代码 `leisaac/assets/robots/lerobot.py`：`SO101_FOLLOWER_USD_JOINT_LIMLITS["gripper"]`：`(-10, 100.0)` → `(-12, 100.0)`

```python
# 改 USD（用 Isaac Sim python）
from pxr import Usd
stage = Usd.Stage.Open("assets/robots/so101_follower.usd")
stage.GetPrimAtPath("/so101_new_calib/joints/gripper").GetAttribute("physics:lowerLimit").Set(-12.0)
stage.Save()
```

**-12° 的确定方法（实测二分）**：jaw 绕关节轴转，间距随角度单调减小。实测：-10° 有缝，-15° 轻微穿模，-25° 严重穿模，故贴拢点在 -10°~-15° 之间，取 -12°（轻微余量防穿模）。手工几何推导易因 jaw orient 旋转/关节轴方向出错，实测二分最可靠。

**影响范围**：改动 `so101_follower.usd` 和 `lerobot.py` 影响所有 SO101 从端任务。原 LiftCube（厚物体）不受影响；薄物体（胶带环等）现在可夹住。原 USD 备份为 `so101_follower.usd.bak`，可随时还原。

### 按 `B` 键后遥操作无反应（从端机械臂不动）

**现象**：Isaac Sim 窗口已正常显示、SO101 Leader 已完成校准，但按下 `B` 键后从端机械臂（SO101 Follower）不跟随 Leader 运动。

**根因**：控制键（`B`/`R`/`N`）通过 Isaac Sim 应用窗口的 carb 键盘输入捕获，而非终端 stdin（见 `leisaac/devices/device_base.py` 的 `_on_keyboard_event` 与 `advance`）。只有 Isaac Sim 窗口收到 `B` 键时才会把 `_started` 置为 `True`，否则 `advance()` 返回 `None`，主循环只 `env.render()` 不 `env.step()`。

**排查与解决**：

1. **键盘焦点是否在 Isaac Sim 窗口**：用鼠标点击 Isaac Sim 窗口使其获得焦点后再按键。若在 `docker exec -it` 的终端里按键，终端会回显 `b`/`B` 但 Isaac Sim 收不到——这就是"没反应"的典型表现。
2. **校准是否合理**：若 Leader 校准的关节范围异常，Follower 可能无法同步。加 `--recalibrate` 重新校准（参考操作说明中的 [TIPS]）。
3. **Leader 电机读数是否正常**：确认 SO101 Leader 已连接（日志出现 `SO101-Leader connected.`），且移动 Leader 时 `get_device_state()` 能读到变化的关节位置。

### VSCode 调试器无法正常工作

> 相关问题：[IsaacLab/issues/3305](https://github.com/isaac-sim/IsaacLab/issues/3305)

当使用 VSCode Python Debugger 启动程序时，可能遇到以下错误：

```
OSError: libstdc++.so.6: version `GLIBCXX_3.4.30' not found
```

请在 conda 环境中安装相应的依赖：

```bash
conda install -c conda-forge gcc=12 -y
```

---

## 六、云仿真（Cloud Simulation）

### 6.1 NVIDIA Brev

**使用 NVIDIA Brev 在云端即时运行 LeIsaac**

最快的方式开始使用 LeIsaac——无需高性能 GPU，只需一个网页浏览器。

打开浏览器访问此 [链接](https://brev.nvidia.com/launchable/deploy/now?launchableID=env-35P96N3pyzVDW3Xlohy7X2TuLCX)。部署完成后，点击指向 80 端口（HTTP）的链接打开 Visual Studio Code Server，默认密码为 `password`。

**快速安装：**

```bash
cd leisaac
pip install -e source/leisaac
```

**启动仿真：**

```bash
python scripts/environments/teleoperation/teleop_se3_agent.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --teleop_device=keyboard \
    --num_envs=1 \
    --device=cuda \
    --enable_cameras \
    --kit_args="--no-window --enable omni.kit.livestream.webrtc"
```

打开新浏览器标签页，使用与 VS Code Server 相同的地址，将 URL 末尾改为 `/viewer` 即可查看 UI。

---

## 七、资源（Resources）

### 7.1 可用机器人（Available Robots）

| 机器人 | USD 资源 | 描述 |
|--------|----------|------|
| **单臂 SO101 从端** | [查看详情](https://huggingface.co/docs/lerobot/so101) | 基于 SO101 从端平台打造的单臂机器人系统 |
| **双臂 SO101 从端** | [查看详情](https://huggingface.co/docs/lerobot/so101) | 基于 SO101 从端平台打造的双臂机器人系统 |
| **LeKiwi** | [查看详情](https://huggingface.co/docs/lerobot/lekiwi) | 搭载单臂的移动机器人 |
| **...** | **...** | 更多机器人即将推出 |

### 7.2 可用环境（Available Environments）

可通过以下命令获取最新环境列表：

```bash
python scripts/environments/list_envs.py
```

| 任务 | 描述 | 相关机器人 |
|------|------|-----------|
| LeIsaac-SO101-PickOrange-v0 / Direct-v0 | 拾取三个橘子放入盘中，然后复位 | 单臂 SO101 |
| LeIsaac-SO101-LiftCube-v0 / Direct-v0 | 将红色方块抬起 | 单臂 SO101 |
| LeIsaac-SO101-LiftTapeRing-v0 | 抬起棕色胶带环（替代正方体，复用 LiftCube 逻辑，见 §3.1.6） | 单臂 SO101 |
| LeIsaac-SO101-CleanToyTable-v0 / BiArm-v0 / BiArm-Direct-v0 | 将两个 e 形物件捡入盒子中，然后复位 | 单臂/双臂 SO101 |
| LeIsaac-SO101-FoldCloth-BiArm-v0 / Direct-v0 | 折叠布料并复位（仅 DirectEnv 支持 check_success） | 双臂 SO101 |
| LeIsaac-LeKiwi-CleanupTrash-v0 | 从地面捡起纸巾垃圾并扔进垃圾桶 | LeKiwi |

### 7.3 可用设备（Available Devices）

#### 单臂 SO101 Follower

**SO101-Leader（推荐）：** `--teleop_device=so101leader`

**键盘：** `--teleop_device=keyboard`

键盘映射：

| 输入按键 | 描述 |
|---------|------|
| `W` / `S` | 前/后 |
| `A` / `D` | 左/右 |
| `Q` / `E` | 上/下 |
| `J` / `L` | 偏航左/右旋转 |
| `K` / `I` | 俯仰上/下旋转 |
| `U` / `O` | 夹爪开/闭 |

**游戏手柄：** `--teleop_device=gamepad`（支持 Xbox Series 控制器）

| 控制按键 | 描述 |
|---------|------|
| 左摇杆前推/后拉 | 前/后 |
| 左摇杆左推/右推 | 左/右 |
| 右摇杆前推/后拉 | 上/下 |
| 右摇杆左推/右推 | 偏航左/右旋转 |
| LB / LT | 俯仰上/下旋转 |
| RT / RB | 夹爪开/闭 |

#### 双臂 SO101 Follower

**Bi-SO101-Leader：** `--teleop_device=bi-so101leader`，配置 `left_arm_port` 和 `right_arm_port`。

#### LeKiwi

| 设备 | 命令 | 说明 |
|------|------|------|
| lekiwi-leader | `--teleop_device=lekiwi-leader` | SO101 Follower 由 SO101-Leader 控制，移动底座通过键盘驱动 |
| lekiwi-keyboard | `--teleop_device=lekiwi-keyboard` | 臂部和底座均通过键盘控制 |
| lekiwi-gamepad | `--teleop_device=lekiwi-gamepad` | 臂部和底座均通过游戏手柄控制 |

LeKiwi 底座键盘映射：

| 输入按键 | 描述 |
|---------|------|
| ⬆️ / ⬇️ | 前进/后退 |
| ⬅️ / ➡️ | 左移/右移 |
| `Z` / `X` | 左旋转/右旋转 |
| `1` / `2` / `3` | 速度等级：慢/中/快 |

### 7.4 可用策略推理（Available Policy Inference）

#### Finetuned GR00T N1.5

```bash
pip install -e "source/leisaac[gr00t]"

python scripts/evaluation/policy_inference.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --eval_rounds=10 \
    --policy_type=gr00tn1.5 \
    --policy_host=localhost \
    --policy_port=5555 \
    --policy_timeout_ms=5000 \
    --policy_action_horizon=16 \
    --policy_language_instruction="Pick up the orange and place it on the plate" \
    --device=cuda \
    --enable_cameras
```

> 目标提交：`4af2b622892f7dcb5aae5a3fb70bcb02dc217b96`

#### Finetuned GR00T N1.6

```bash
pip install -e "source/leisaac[gr00t]"

python scripts/evaluation/policy_inference.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --policy_type=gr00tn1.6 \
    --policy_host=localhost \
    --policy_port=5555 \
    --policy_timeout_ms=5000 \
    --policy_action_horizon=16 \
    --policy_language_instruction="Pick up the orange and place it on the plate" \
    --device=cuda \
    --enable_cameras
```

> 目标提交：`e8e625f4f21898c506a1d8f7d20a289c97a52acf`

#### LeRobot 官方策略

```bash
pip install -e "source/leisaac[lerobot-async]"

python scripts/evaluation/policy_inference.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --policy_type=lerobot-smolvla \
    --policy_host=localhost \
    --policy_port=8080 \
    --policy_timeout_ms=5000 \
    --policy_language_instruction='Pick the orange to the plate' \
    --policy_checkpoint_path=outputs/smolvla/leisaac-pick-orange/checkpoints/last/pretrained_model \
    --policy_action_horizon=50 \
    --device=cuda \
    --enable_cameras
```

> 目标提交：`v0.3.3`

#### Finetuned OpenPI

```bash
pip install -e "source/leisaac[openpi]"

python scripts/evaluation/policy_inference.py \
    --task=LeIsaac-SO101-PickOrange-v0 \
    --policy_type=openpi \
    --policy_host=localhost \
    --policy_port=8000 \
    --policy_timeout_ms=5000 \
    --policy_language_instruction='Pick the orange to the plate' \
    --device=cuda \
    --enable_cameras
```

> 目标提交：`5bff19b0c0c447c7a7eaaaccf03f36d50998ec9d`

---

## 附录：外部链接汇总

| 资源 | 链接 |
|------|------|
| LeIsaac GitHub 仓库 | https://github.com/LightwheelAI/leisaac |
| Lightwheel AI 官网 | https://lightwheel.ai/ |
| Lightwheel AI LinkedIn | https://www.linkedin.com/company/lightwheel-ai/ |
| IsaacLab 文档 | https://isaac-sim.github.io/IsaacLab/main/index.html |
| LeRobot | https://github.com/huggingface/lerobot |
| GR00T N1.5 | https://github.com/NVIDIA/Isaac-GR00T |
| SO101 文档 | https://huggingface.co/docs/lerobot/so101 |
| LeKiwi 文档 | https://huggingface.co/docs/lerobot/lekiwi |
| Marble 平台 | https://marble.worldlabs.ai/ |
| 3DGrut | https://github.com/nv-tlabs/3dgrut |
| Cosmos-Predict2.5 | https://github.com/nvidia-cosmos/cosmos-predict2.5 |
| GR00T-Dreams | https://github.com/NVIDIA/GR00T-Dreams |
| Brev 启动链接 | https://brev.nvidia.com/launchable/deploy/now?launchableID=env-35P96N3pyzVDW3Xlohy7X2TuLCX |
| HuggingFace 场景资源 | https://huggingface.co/LightwheelAI/leisaac_env/tree/main |

---

> 本文档生成于 2026 年 6 月 25 日，基于 https://lightwheelai.github.io/leisaac/ 站点的所有公开页面内容汇总翻译。
>
> 原始版权 © 2026 Lightwheel AI, Inc. 使用 Docusaurus 构建。
