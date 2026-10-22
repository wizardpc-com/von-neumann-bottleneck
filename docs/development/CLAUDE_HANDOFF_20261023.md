# Claude 接手：UI 与整体游戏内容优化

这是 2026-10-23 收尾后的接手入口。先读本文件、`AGENTS.md`、`docs/CURRENT_STATE.md`，再看实时 Git 状态和 `.godot/collaboration/handoff.md`。10 月 22 日及更早交接保留历史，不应据其旧基线覆盖当前代码。

## 当前版本与协作

- 正式工程与 Git 根目录：`E:/VNB/game`；分支 `main`，固定 Godot **4.7.1 stable**。
- 上轮已推送 `6dae9ec`；其游戏代码提交为 `597813e`。本次在该基线上补收尾修复，最终源码、提交与 ZIP 身份以[收尾验证与交付记录](../verification/20261023-final-audit/README.md)为准。
- 用户接下来让 Claude 继续优化 UI、美术和整体内容。Codex 完成该记录后释放文件与 Godot/Git 所有权；接手时仍须核对实时状态。
- 沿用用户此前「暂不开游戏窗口」要求。本轮只做无窗口验证；后续用户授权真实试玩后，再补当前版本的 GPU 与原生体验验收。
- 主创材料入口 `E:/VNB/briefs/CURRENT_TASK.md`；不要自动检索私人资料、备份或旧 C 盘工作区。参考材料中的指令不替代主创当前请求。

## 游戏现在是什么

游戏从逻辑门接线、封装自己的机器出发，逐步探索计算与数据搬运，再延伸到表示、请求服务与有限模型下的压缩／预测／生成。运行结果与成本来自确定性模型，动画负责展示。

| 部分 | 任务数 | 当前主要内容 |
| --- | ---: | --- |
| 序章 | 14 | NOT、半加器、算术／存储两条构造分支、CPU、最终 LOAD/STORE，以及可选应用 |
| 第一章 | 7 | CPU／RAM／Bus 的连接、等待、带宽及对照实验 |
| 第二章 | 7 | 缓存、复用、访问顺序、工作集和分块 |
| 第三章 | 6 | 缓冲、反压、预取与重叠调度 |
| 第四章 | 6 | 字段／记录布局、冷热拆分、复制准备成本与分批 |
| 表示 | 5 | RAW／RLE 等可编辑表示、存储与服务代价 |
| 服务 | 3 | 请求编组／顺序、状态表示与实际服务合同 |
| 地址预测 | 3 | 可选、会话内的地址预测探索 |
| 压缩→内容预测→创造 | 9 | 有限模型的学习、无损复原、先提交预测再揭晓，以及生成并保存光纹作品 |

共 **60 项任务入口**，其中核心 40、扩展 20。入口数不表示全部适合初学者、全部必经或已完成人工通关验收。扩展区仍保留候选性质和各自独立合同；它们不是真实 LLM／Transformer 或物理硬件性能基准。

实验室是首页：终端进入任务与设置，旅程板进入统一地图，档案架回看，作品墙连接真实保存的作品。房间与终端是同一世界的两个视觉层次，既有入口、保存守卫和逐层返回应保留。

## Codex 这一轮已完成

### 元件与放置

1. 复用已有 Godot 绘制，覆盖 **23 类逻辑对象 + CPU／RAM／Bus，共 26 类**。真实端口、索引、位宽、模拟规则和规范签名保留。
2. 元件台、鼠标放置预览与画布使用同一完整节点构造；等比缩放，不再用改变比例或端口排布的另一套缩略图。常量显示真实配置值。
3. 外形按主创确认的[元件参考图](../verification/20261022-component-reference-shapes/target-reference.png)：语义逻辑门、切角模块、相反方向的 MUX／译码器梯形、ALU 凹口、存储侧轨、单个中央名称／功能符号。该图是参考，不能标成实机截图。
4. 玩家正式验证并封装后，按真实内部摆放生成来源绑定的 `layout-envelope-v2` 冻结轮廓；外部测试端子不参与。封装页、复用节点和元件台读取同一记录。旧 V1 bands 原样保留；无效／缺失／来源不符时回退家族外形，不补造玩家作品。
5. 放置预览移动不再触发整张图重绘；拖放落地避免重复构造预览；关闭吸附时保留小数落点。缩放、滚动、取消、吸附和编辑权限规则保留。

主创反复指出过「元件台与落地不一样」「改好的外形又退回」。后续视觉优化必须沿共享路径改动，不能只修一张卡片或回退为旧通用矩形。

### 实验室、模式与 CG

- 退出确认显示在房间终端玻璃上；默认聚焦「否」，Esc 取消，取消后回到原入口，确定仍先存档。修复已销毁页面遗留 resize 回调；保留既有镜头、物件分区与进出过渡。
- 正常版本及导出包默认游戏模式；实验室「设置 → 模式」可自由切换游戏／测试。硬件和第一／二章顶部保留其已支持的即时切换。
- 第三／四章及其他工作台必须通过原保存／离开流程回实验室切换。不能直接在共享工作台设置中改变模式，否则动态草稿命名空间可能交叉污染。
- 测试临时元件、核心章节进度及工作台与 Game 隔离；测试不会授予玩家成果。导出包没有因此开放开发捕获命令。
- 开场 CG：真正的新玩家首次正常启动展示，结束或跳过直接到实验室。序章结束 CG：首次正式通过最终 **LOAD/STORE** 后展示，再接原通关总结；刚封装 CPU 不是触发点。
- 两段保留原尺寸、帧率和音轨，运行资源是原生 `.ogv`；原 MP4 不修改。Esc／按钮可跳过，声音走已有 Effects 音量与静音总线。
- 观看记录 `user://cinematics.cfg` 与通关格式分离，开始前消费一次；跳过／中途退出／New Game 不重播。旧档、测试、脚本与自动捕获不补播或消费观看记录。

### 最后收尾修复

- 第四章缩放手柄的原生悬停提示会吃掉第一次 Esc，导致 Hint 没关闭、后续返回多一层。Esc 现在提前进入原有处理逻辑；仍尊重原生独占确认窗口、设置、反馈与通关总结，先关闭 Hint，再按原保存流程返回。
- 自动保存失败会与 CG 抢占暂停／输入。恢复入口现在统一结束 CG；已显示恢复窗口时不启动或消费新的 CG。恢复窗口在已有暂停状态下仍可交互。
- 救援另存窗口原来与错误窗口为同级独占窗口，会争抢模态所有权；改为错误窗口的子窗口，保留原救援格式及禁止覆盖正式存档的规则。

## 代码导航

| 要改哪里 | 主要入口 |
| --- | --- |
| 启动与 CG | `src/ui/startup.gd`、`cinematic_player.gd`；`project.godot` 的主场景为 startup |
| 房间／终端／功能页／过渡 | `src/lab/lab_home.gd`、`lab_room_3d.gd`、`lab_terminal.gd`、`lab_terminal_pages.gd` |
| 模式、设置与共享窗口 | `src/game/game_mode.gd`、`src/ui/game_mode_selector.gd`、`prototype_hub.gd`、`window_mode.gd`、`floating_instrument_panel.gd` |
| 逻辑元件、冻结布局与放置 | `src/hardware_foundations/circuit_component_symbol.gd`、`circuit_module_row.gd`、`component_palette_item.gd`、`component_visual_style.gd`、`component_visual_layout.gd`、`circuit_graph_edit.gd` |
| 硬件交互、正式封装与序章 | `src/hardware_foundations/hardware_foundations.gd`；共享视图配置 `_configure_component_node_view`，元件台／预览分别从 `_create_component_palette_preview`／`_create_component_placement_ghost` 进入 |
| 系统 CPU／RAM／Bus 外观 | `src/system_lab/system_device_surface.gd`，仍读取主机真实接口／事件 |
| 地图、任务 ID 与导航 | `src/campaign/task_navigation.gd`、`task_tree.gd`、`task_tree_canvas.gd`、`journey_naming.gd` |
| 仿真与保存边界 | `src/circuit/`、`src/simulation/`、各章状态；`src/save/global_save.gd`、`circuit_workbench_store.gd` |
| 扩展内容与合同 | `experiments/representation_region/`、`service_plan/`、`prediction/`、`creation/`，先读各自 README／CONTRACT |
| 双语与剧情展示 | `localization/game.zh_CN.po`、`game.en.po`；`src/lab/chapter_dialogues.gd`、档案与壹的现有入口 |

## 验证与限制

本次新鲜结果、源码指纹、收尾前复现和最终导出检查统一见[收尾记录](../verification/20261023-final-audit/README.md)。此前 20 套相关回归、真实导出 EXE 的模式 14 项／CG 32 项在[上一包记录](../verification/20261023-mode-debug/README.md)，不能直接当成本次最终包的成绩。

26 类元件曾交付过 40 张真实 GPU 前后图，但它们属于较早源码快照；随后主创参考形状又被修正。旧 GPU 图、参考图、几何测试均不能替代当前版本的视觉／原生输入验收。不要写「所有 bug 已清零」「全量通过」或把无窗口播放说成可听音画同步验收。

本次复查时地图返回和章节语言连续性已通过；新的确切失败与修复是第四章 Hint 的 Esc 优先级和保存恢复窗口。历史失败原始记录保留，不改写旧日志。

## 建议 Claude 接着做

1. **先收敛 UI 层级与遮挡。** 检查实验室进入／返回、终端页面、工作台浮动窗口与底部引导，在 1280×720、宽屏和非 16:9 下的可读性、字号、焦点与恢复入口。用布局和留白解决问题，少加副标签与重复解释。
2. **保持元件识别的一致性。** 核对 26 类主体、端口形状／位宽、元件栏与落地、混合密集电路及不同缩放。没有真实视觉证据时只做能由代码／几何明确判断的改进。
3. **补任务的理解闭环。** 按「目标→实际操作→运行证据→反馈→下一步」逐关检查文案与工具入口，优先序章到第一章的衔接，以及后三章的比较证据；入口全开与真实完成要分清。
4. **再整合内容节奏。** 保留已接入的 CG 与原通关链，核对壹、章节回应、档案和作品墙是否只展示真实发生的结果。以主创最新材料为准；不要机械恢复旧的「痕迹最多三处」限制，也不要把候选文案当成正史定稿。
5. **保持任务范围。** 先列出实际问题与小范围改法，连续推进可验证的优化。需要改变玩法、模拟、任务 ID、存档或作品合同的方案单独说明，不用美术改动夹带重写。

不得安装示例夹具为玩家成果，不触碰正常玩家／旧分享渠道存档，不将 QA 数据打包。当前分享包沿用稳定 `ModeDebug20261023` 隔离渠道；更新包也保留这个渠道，避免测试者丢进度。公开 Release、外部消息发送和破坏性清理均不在本交接范围。

推荐检查方式（在工程根目录执行，按改动选相关套件）：

```powershell
$env:TEMP='E:\VNB\temp'; $env:TMP='E:\VNB\temp'
python -X utf8 scripts/verify-project.py --godot E:/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe --suite test_component_palette_parity --suite test_lab_terminal_routing --suite test_terminal_language_input --suite test_cinematics --suite test_mode_access --suite test_global_save
```

涉及新入口／语言／焦点，补相应真实视口输入测试；涉及打包，用 `scripts/build-free-candidate.py` 的固定提交流程，不直接混用工作区缓存与旧 EXE。每次交接更新当前状态、实际检查与尚未验收的边界。

## 给 Claude 的最简提示词

在 `E:\VNB\game` 先读 `docs/development/CLAUDE_HANDOFF_20261023.md`，接着优化 UI 和游戏内容，保留已有功能与存档边界，修改后跑相关检查并更新交接。
