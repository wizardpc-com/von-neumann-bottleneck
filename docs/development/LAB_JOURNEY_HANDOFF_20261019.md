# 实验室旅程 · 交接与待办（2026-10-19）

工程收尾后的当前入口为 [团队试玩与开发交接](team-handoff.md) 与
[工程验证记录](../verification/20261019-team-closeout/README.md)。
本文保留实验室功能地图及团队创作建议；旧包、机器空间与当时未导出状态均为历史快照。

**当前入口文档。** 接手（人或 AI）先读本文，再按需读 [AGENTS.md](../../AGENTS.md)、[美术风格约束](../briefs/20261019-lab/美术风格约束_v0.1.md)、[接续开发目标](../briefs/20261019-lab/接续开发目标_20261018.md)、[Claude 接续开发计划](../briefs/20261019-lab/Claude接续开发计划_v1.0.md)。旧的 [CLAUDE_HANDOFF_20261018](CLAUDE_HANDOFF_20261018.md) 只作历史参考，其中"F5 只有 40 项""候选创作路线"已过时。

截图都在 [verification/20261019-lab-journey](../verification/20261019-lab-journey/)，全部来自真实运行（1280×720），不是概念图。

---

## 0. 迁移到新目录（例如 E 盘）

`main` 已包含全部必须内容：60 项旅程、实验室首页、本轮所有改动、PR #11–#15、离线反馈系统和测试。直接重新克隆即可：

```powershell
git clone https://github.com/wizardpc-com/von-neumann-bottleneck.git E:\von-neumann-bottleneck
cd E:\von-neumann-bottleneck
# Godot 4.7.1 stable（与仓库约束一致）
Godot_v4.7.1-stable_win64_console.exe --editor --path . --import --quit
Godot_v4.7.1-stable_win64.exe --path .
```

首次导入会生成 `.godot/` 缓存和少量 `.uid`/`.import` 文件，属于正常现象。

**以下内容不在 Git 里，迁移时请按需手动复制：**

| 内容 | 旧位置 | 说明 |
|---|---|---|
| Godot 4.7.1 可执行文件 | `冯诺依曼瓶颈/godot-4.7.1/` | 脚本里的 `--godot ../godot-4.7.1/...` 假设引擎在仓库同级目录 |
| 10/18 同学试玩包 ZIP | `night-experience-20261018/build/` | 已发给同学的旧版本；新版本需重新导出（见 §4 T9） |
| GPT 留下的 QA 证据 | `night-experience-20261018/.godot/`（约 15 GB） | 历史验收日志/截图，开发不需要，可不迁移 |
| 团队讨论记录、成员情况 | 工作区根目录《游戏项目现状与团队讨论交接》 | 含成员评价，**仓库是公开的，未放入 Git**，请自行保管 |
| 分工 v2.0、故事稿、参赛清单 | `Downloads/` 下的 docx/md | 同上，本地保管；需要时把定稿内容整理进 `docs/briefs/` |

本机 C 盘已满（验证时一度只剩 0 字节），这是迁移的另一个好理由。

---

## 1. 玩家现在看到什么（相对 10/18 候选版）

| 位置 | 之前 | 现在 |
|---|---|---|
| 打开游戏 | 深色菜单 + 抽象等距插画（`before-home.png`） | 明亮、尺度适中的实验室：窗外安静的城市，中间实验台与深色终端；左墙档案架，右墙旅程板，后墙作品墙，桌上台灯与植物；鼠标移动有轻微视差（`lab-idle.png` / `lab-works.png`） |
| 唤醒终端 | — | 点击屏幕或 Enter；壹打招呼并给出一个具体目标（`lab-awake.png`） |
| 进入 | 大段壹的导入文字 | 镜头推进到终端屏幕里，进入工作台（`lab-zoom.png`）；返回时从屏幕里拉回实验室 |
| 第一关 | 六页说明盖住画布、三个浮窗、两排工具（约 30 个控件，`before-tutorial.png`） | 只有电路、步骤卡与测试台；步骤卡跟随真实操作，一次一件事，每步一句肯定（`tut-focus.png` / `tut-s3.png`）；通关后工具恢复 |
| 首次完成 | "关卡完成"文字框 | 光环徽记、壹的一句话、"回到实验室 · 看看那盏灯"（`tut-done.png`） |
| 回到实验室 | — | 台灯第一次亮起；旅程板点亮；档案架多一页；窗外塔楼亮一扇窗；壹："灯亮过，也灭过。两次都是对的……"；主按钮直接指向下一项（`back-lab.png` / `lab-return2.png`） |
| 档案架（新） | — | 13 页"壹的记录"，每页由一项真实完成开启，未开启的页写明完成哪一关（`r4-archive.png`） |
| 窗外城市（新） | — | 每个章节有进度时一座塔楼亮窗，章节完成变暖色（`lab-progress.png`） |
| 作品墙（新） | — | 后墙显示最近一件在创造章节保存的作品（光纹 + 名字 + 件数），点击进入 G3；没有作品时显示"空着，等你留下第一件"（`lab-works.png`） |
| 旅程地图 | 只有"压缩/内容预测/创造 · 候选"三个按钮（`r3-tree.png`） | 11 个章节标签带真实进度，"候选"字样去掉；"← 实验室"（`r3-tree-after.png`） |
| 第 1、2 章工作台 | 六/七个浮窗随机叠放，任务窗盖住机器（`r3-system.png` / `r3-loc-result.png`） | 停靠布局：任务在左栏，工具在右栏（第二个工具会把右栏上下分开），机器自动缩放到中间空白处；面板只在第一次打开时停靠，之后保留你拖动/缩放的位置（`r5-system-docked.png` / `r5-locality-docked.png`） |
| 半加器、全加器、SR 锁存器、寄存器 | 五页说明盖住画布（`r5-half-adder-before.png`） | 同一张步骤卡：搭电路 → 试一试 → 正式测试，三步分别读取真实接线、真实调试运行和真实正式结果；完整说明仍可一键打开（`r5-half-adder-guided.png`） |
| 第 2 章结果 | 一串数字 | 周期条：计算 / 等数据 / 上限，文字"看看黄色部分：CPU 在等数据"（`r3-loc-result.png`） |
| C/P/G 工作台 | 规格说明式标题和审计文字（`r3-creation.png`） | "压缩 C1–C3 → 内容预测 P1–P3 → 创造 G1–G3"步进条；九关说明改为人话（`r3-creation-after.png`） |
| 配色与控件 | 霓虹青、紫色等高饱和色散落 40+ 文件；控件小圆角 | 统一映射到终端色板（`src/lab/lab_palette.gd` 是唯一定稿入口）；全局控件主题改用终端色、圆角加大；所有深色工作台背景加上与实验室显示器一致的屏幕光和内框，读起来像"在终端里" |
| 实验室细节 | — | 墙面光晕、窗口斜光、屏幕在桌面上的反光、笔记本与杯子、右墙仪器柜（指示灯随总进度点亮）（`lab-art.png`） |
| 玩家可见文字 | "可选虚构回顾""不表示电流、能耗或文明测量""不冒称""回执""合同"等 | 删去或改写；60 关的"怎样算完成 / 完成的意义"中文全部改成人话（规则不变）；"CPU WAIT"→"CPU 等待"；"返回章节选择"→"回到实验室" |

**启动开关（用户参数，`--` 之后）：** `--core-journey` 只看核心 40 项；`--classic-hub` 旧首页；`--classic-tutorial` 旧教程。默认值在 `project.godot` 的 `game/full_journey=true` 与 `src/lab/lab_features.gd`。

**没有改动的部分：** 所有模拟、计分、完成门槛、存档格式和玩家作品合同。实验室只读取真实进度；它自己的记录 `user://lab_state.cfg` 只记"哪些完成已经回应过、哪些档案读过"，删除它只会重播回应，不影响进度。

---

## 2. 代码地图（新增 / 主要改动）

| 文件 | 作用 |
|---|---|
| `src/lab/lab_home.gd` | 实验室场景：分层绘制、视差、镜头推拉、旅程板、档案架、城市灯、作品墙、环境回应 |
| `src/lab/lab_terminal.gd` | 终端屏幕即主菜单：待机、壹的话、主按钮、旅程/档案/手册/设置/退出 |
| `src/lab/lab_archive.gd` / `archive_fragments.gd` | 档案阅读器 / 13 页候选文本 |
| `src/lab/lab_state.gd` | 读真实进度、章节站点、已回应记录 |
| `src/lab/lab_palette.gd` | 实验室浅色 + 终端深色唯一色板 |
| `src/lab/lab_features.gd` | 新旧表面开关 |
| `src/hardware_foundations/tutorial_coach.gd` | 第一关步骤卡 |
| `src/ui/cycle_budget_bar.gd` | 第 2 章计算/等待/上限条 |
| `src/ui/instrument_dock.gd` | 第 1、2 章停靠布局与机器取景 |
| `src/dev/dev_capture.gd` | 开发截图/固定路线（只在带 `--dev-*` 参数时生效） |
| `src/ui/prototype_hub.gd` | 首页挂载实验室；旧表面保留为回退 |
| `src/ui/level_completion_overlay.gd` | 完成卡重设计（所有章节共用） |
| `src/campaign/task_tree.gd` | 章节标签、文案 |
| `experiments/creation/workbench.gd` | C/P/G 步进条与精简 |
| `tests/test_lab_journey.gd` | 本轮新增的行为检查（37 项） |

---

## 3. 团队接手点

**美术（严睿清、陈梓弘）**
- 实验室目前是**代码绘制的占位层**，构图已固定。替换方式：放入 1600×900 PNG 到 `assets/lab/lab-back.png`（墙、窗、地面、作品墙底）、`lab-mid.png`（侧墙，透明处保留游戏绘制的档案架和旅程板）、`lab-desk.png`（桌、灯、植物、终端外壳）。文件存在即自动使用，无需改代码（`lab_home.gd` 顶部 `LAB_ART`）。
- 关键坐标（设计分辨率 1600×900）：终端屏幕 `Rect2(536,300,528,318)`，显示器外框 `518,282,564,354`；台灯灯头 `(440,520)`；作品墙 `Rect2(1128,150,196,168)`；档案架左墙、旅程板右墙。背景图请把屏幕区域留空。
- 色板：`src/lab/lab_palette.gd`。图标、元件外形尚未统一重绘（§4 T5）。

**教学文字（刘若琪）**
- 第一关步骤卡：`tutorial_coach.gd` 的 `STEPS`。
- 各关"现在做什么 / 怎样算完成 / 完成后的意义"：`src/ui/mission_narrative_catalog.gd` 的 `TASK_CONTEXTS`。C/P/G 九关已改写，**其余 51 关仍是旧文案**（§4 T3）。
- 第 2 章结果文字：`localization/game.zh_CN.po` 的 `chapter2.result.*`。

**故事与演出（罗雅琪）**
- 档案 13 页：`archive_fragments.gd`（只改 `title/body`；`id` 不改；`requires` 是开启它的任务键）。文本依据《壹_未完成的说明书》《背景小说创作交接》写成，**是候选稿**，人名沿用林见秋、阿禾。
- 壹在终端上的话：`lab_terminal.gd` 的 `_compose()`；实验室字幕：`lab_home.gd` 的 `_arrive()`；片头 CG 可接在 `_arrive()` 首次进入分支。

**交互与关卡（常逸飞）**
- 重点试：新档从实验室到点亮台灯；第 2 章「分而复用」的周期条；旅程地图能否找到后三章；作品墙是否让人想去创造。

**展示（苏子航）**
- 固定路线截图（窗口固定 1280×720）：
  ```
  Godot --path . -- --dev-key=Enter@2 --dev-key=Enter@4.2 --dev-shot=C:/tmp/a.png@8 --dev-quit=9
  ```
  还支持 `--dev-click=x,y@秒`、`--dev-drag=x1,y1,x2,y2@秒`、`--dev-rdrag=…`、`--dev-enter=<任务键|tree>@秒`、`--test-mode`。第一关完整路线见 §5。

---

## 4. 待完成任务（按优先级）

下面是这一轮**没有完成**、需要接着做的事。每项写了范围、位置和怎样算完成。

| # | 任务 | 位置 | 完成标准 |
|---|---|---|---|
| T1 | **导出新的 Windows 试玩包**并发给同学 | `scripts/build-free-candidate.py`（源码已默认完整旅程；若沿用 `--second-act-profile` 隔离档，同学的旧档不受影响，打包前先在临时目录试一次） | 新包从实验室开始，60 项可见；新档走通第一关；F8 反馈与导出正常 |
| T2 | **正式实验室美术**替换三层占位，并补终端开机/按键/完成音效 | `assets/lab/*.png`；音效接 `WindowMode` 的 Effects 总线 | 同一构图下画面质感明显提升；读字、点按不受影响 |
| T3 | **关卡文案继续打磨**：60 关"怎样算完成 / 完成的意义"中文已改写；还剩各关多页任务说明（`.po` 中 `hardware.briefing.*`、`system.mission.*`、`chapter2.*` 等）与对应英文 | `game.zh_CN.po`、`game.en.po`、`mission_narrative_catalog.gd` | 由刘若琪按同一口吻逐章审校；不出现审计式免责声明 |
| T4 | **引导扩展**：半加器、全加器、锁存器、寄存器已有步骤卡；可继续为 ALU、RAM、CPU 写更具体的分步（目前是通用三步） | `hardware_foundations.gd` 的 `GUIDED_LEVELS` / `tutorial_coach.gd` 的 `BUILD_STEPS` | 每关步骤贴合该关电路 |
| T5 | **停靠布局继续打磨**：已改为左栏任务 + 右栏工具 + 中间机器；第 3、4 章（重叠、布局）和第二幕仍是原布局，可接入同一个 `instrument_dock.gd` | `overlap_chapter.gd`、`layout_chapter.gd`、`experiments/*` | 1280×720 首屏不互相遮挡 |
| T6 | **元件与图标统一**：门电路、CPU/Bus/RAM/Cache 的外形、端口与状态符号做成一套 SVG | `circuit_component_symbol.gd`、`system_device_surface.gd`；需要陈梓弘出图 | 同一套线宽、圆角和色板 |
| T7 | **章节完成演出深化**：已为构造、第 1–4 章收尾和 G3 加了专属字幕与壹的回应（`CHAPTER_RESPONSES`）；还缺与之对应的**画面变化**（例如窗外整片亮起、档案架抽屉打开动画）和音效 | `lab_home.gd` 的 `CHAPTER_RESPONSES` / `_arrive()` | 每章收尾都有一个看得见的空间变化 |
| T8 | **英文文案**：C/P/G 九关与档案页、终端、章节回应已双语改写；其余 51 关随 T3 一起改 | `mission_narrative_catalog.gd` | 英文界面无旧审计语气 |
| T9 | **在新机器重跑完整回归**（本机已 177/177 通过，迁移后再确认一次） | `python scripts/verify-project.py --godot <Godot>` | 全部 PASS |
| T10 | **旧表面清理**：确认实验室版本被接受后，删除旧首页插画、只读 3D 观察站、ThemeReflection 等不再使用的入口 | `prototype_hub.gd`、`journey_observatory.gd`、`theme_reflection.gd` 及对应测试 | 删除前与主创确认；测试同步更新 |
| T11 | 赛后：真 3D 实验室（受限视角）评估 | — | 先做比较原型，不影响 2D 工作台 |

**需要主创决定：**
1. 实验室走 **2.5D 分层插画**（目前方案，建议参赛前采用）还是**轻量 3D**？
2. 档案架"每个概念对应一段历史"的写法是否采用？人名是否沿用林见秋、阿禾？
3. 壹按"有温度、克制的引导者"来写，这与 `docs/design/thought-within-world.md`"最多三处痕迹"的旧约束不同，以哪个为准？

---

## 5. 验证

**真实运行（Windows，1280×720）：** 新档 → 唤醒终端 → 进入 → 五步（真实拖线、点击、右键拆线、重新接线）→ 完成卡 → 回到实验室：台灯亮起，旅程板、档案架、塔楼更新。退出重开后显示"欢迎回来 / 继续 · 半加器"。第一关路线：

```
--dev-key=Enter@2 --dev-key=Enter@4.2 --dev-drag=517,431,643,421@8 --dev-drag=778,421,1048,431@9 --dev-click=123,462@10.5 --dev-click=177,513@11.6 --dev-rdrag=910,380,910,480@14 --dev-drag=778,421,1048,431@15.5 --dev-click=708,561@18
```

**自动测试（`scripts/verify-project.py`，Godot 4.7.1，Windows 隔离副本）：** 结果见下方"完整回归"一段。旧首页、旧教程、40 项旅程的测试改为显式打开 `lab_features.gd` 的 `classic` / `core_journey` 回退开关后继续验证原表面；第 2 章、C/P/G 与本地化的文案断言按新文字更新。

**完整回归（2026-10-19，合并 main 前）：** `python scripts/verify-project.py --godot <Godot 4.7.1>` 一次跑完 176 个常规套件 + import + user_directory：156 通过，20 失败。失败分三类：(a) 依赖旧首页/旧教程/焦点返回首页的套件，改为显式打开 `LabFeatures.classic`；(b) 依赖"60 项须候选配置才开放"的套件，改为显式打开 `LabFeatures.core_journey`；(c) 断言旧文案（"候选""文明测量""CPU WAIT""首页"）的，按新文字更新。修复后这 20 个套件与 `test_lab_journey`、`test_full_journey_narrative`、`test_task_tree*`、`test_creation_route_access` 重跑全部通过。工作区里一直缺失的 `tests/test_service_commission_ui.gd`（Git 中存在，此前被本地删除，非本轮改动）已从 Git 恢复并单独通过。**合计 177/177 通过。** 此后加入的章节结尾回应与 C/P/G 英文改写由 `test_lab_journey`、`test_full_journey_narrative` 覆盖。
- 注意：这台机器 C 盘只剩约 1 GB，每次验证副本约 250 MB，跑完需删除 `.godot/verification/<时间戳>`。

**未做：** 陌生玩家试玩、Mac、导出新 Windows 包（T1）、带真实已保存作品的作品墙截图（需要先在 G3 保存一件）。
