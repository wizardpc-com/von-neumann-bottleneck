# 实验室旅程 · 交接（2026-10-19）

分支：`claude/lab-journey-20261019`（基于 `codex/journey-final-candidate-20261018`，已包含 PR #11–#15 全部内容；更早的 `mac-second-act` / `main-works-integration` 分支内容已经以 PR #2/#10 合入 main，且候选分支中的版本更新，不需要再合）。

这份文档写给团队：先看「玩家看到了什么变化」，再看「各位从哪里接手」。截图都在 [verification/20261019-lab-journey](../verification/20261019-lab-journey/)，全部来自真实运行（1280×720），不是概念图。

## 1. 这一轮改了什么（玩家视角）

| 位置 | 之前 | 现在 |
|---|---|---|
| 打开游戏 | 深色菜单页 + 抽象等距插画（`before-home.png`） | 一间明亮、尺度适中的实验室：窗外是安静的城市，中间是一张实验台和一台深色终端；左墙档案架，右墙旅程板，桌上一盏台灯和一盆植物。鼠标移动时画面有轻微视差（"转头"）（`lab-idle.png`） |
| 唤醒终端 | — | 点击屏幕或按 Enter，终端亮起，壹打招呼并给出一个具体目标："我们从一盏灯开始。"（`lab-awake.png`）|
| 进入 | 弹出大段壹的导入文字 | 镜头推进到终端屏幕里，直接进入工作台（`lab-zoom.png`）|
| 第一次操作 | 六页任务说明盖住画布、三个浮窗、两排工具栏（约 30 个控件，`before-tutorial.png`） | 只有电路、一张"步骤卡"和测试台。步骤卡一次只说一件具体的事，五个进度格，每完成一步给一句简短肯定（`tut-focus.png` / `tut-s3.png`）。完整说明仍可点开。通关后所有工具恢复 |
| 首次完成 | "关卡完成"文字框 | 原地出现温和的光环徽记、壹的一句话、下一步提示；主按钮是"回到实验室 · 看看那盏灯"（`tut-done.png`）|
| 回到实验室 | — | 镜头从屏幕里拉出来，桌上台灯第一次亮起；旅程板「构造」点亮一格；档案架多出一页；壹回应："灯亮过，也灭过。两次都是对的。那条线是你接上的，不是我替你算出来的。"（`back-lab.png`）主按钮直接指向下一项任务（`lab-return2.png`）|
| 窗外城市（新内容） | — | 每个章节有进度，窗外一座塔楼亮起窗灯；章节全部完成时变为暖色（`lab-progress.png`）|
| 档案架（新内容） | — | 13 页"壹的记录"，每页在完成一项真实任务后开启，把刚学的概念接到世界历史上（第一束光、数到二、留住一个值、等待的来处……你留下的）。未开启的页面会告诉你完成哪一项可以打开（`r4-archive.png`）|
| 旅程地图 | 只有"压缩/内容预测/创造 · 候选"三个按钮，后面章节难找（`r3-tree.png`）| 11 个章节标签一字排开，带真实进度；标题改为"旅程"，左上角"← 实验室"（`r3-tree-after.png`）|
| 中期：第 2 章结果 | "实际值 88 · 目标值 88 · 用时 210 · 本次 210 · 上限 145 · 超出 65" | 一条周期条：青色是计算（34），黄色斜纹是"等数据"（176），红线是上限；文字改成"210 周期，比上限 145 多 65。看看黄色部分：CPU 在等数据。"（`r3-loc-result.png`）|
| 后期：C/P/G 工作台 | 顶部是规格说明式标题和多行审计文字（`r3-creation.png`）| 顶部是"压缩 C1 C2 C3 → 内容预测 P1 P2 P3 → 创造 G1 G2 G3"步进条，可直接跳转、带 ✓；机器规格移到悬停提示；说明文字改为人话（`r3-creation-after.png`）|
| 全局配色 | 霓虹青 `50d5ff`、紫色标题 `bc8cff` 等高饱和色散落在 40+ 个文件 | 统一映射到终端色板（柔和青、灰蓝紫、低饱和信号绿/红），与实验室同一套色彩逻辑 |
| 玩家可见文字 | "可选虚构回顾""不表示电流、能耗或文明测量""不冒称执行此算法""候选"等 | 删去或改写为面向玩家的话；技术边界留在代码注释与文档中 |

源码直接 F5 现在默认是**完整 60 项旅程**（`project.godot` 中 `game/full_journey=true`，表示/服务存档写在普通存档目录）。需要旧的 40 项核心旅程时加用户参数 `--core-journey`；旧首页加 `--classic-hub`；旧教程加 `--classic-tutorial`。

## 2. 各位从哪里接手

**美术（严睿清、陈梓弘）**
- 实验室是代码绘制的占位层，构图已经固定。最快的替换方式：放入 1600×900 的 PNG 到 `assets/lab/lab-back.png`（墙/窗/地面）、`lab-mid.png`（侧墙，透明处保留代码绘制的档案架和旅程板）、`lab-desk.png`（桌、灯、植物、终端外壳）。文件存在就自动使用，不需要改代码。见 `src/lab/lab_home.gd` 顶部的 `LAB_ART`。
- 终端屏幕的可交互区域是设计坐标 `Rect2(536, 300, 528, 318)`（显示器外框 `518, 282, 564, 354`）。背景图里请把这块留成屏幕，菜单由游戏绘制。
- 台灯灯头在 `(440, 520)`，光落在桌面 `(436, 712)` 附近；档案架在左墙，旅程板在右墙。改构图时同步改 `lab_home.gd` 中对应坐标。
- 色板只有一个文件：`src/lab/lab_palette.gd`（实验室浅色 + 终端深色）。定稿颜色先改这里。

**教学文字（刘若琪）**
- 第一关步骤卡的五句话：`src/hardware_foundations/tutorial_coach.gd` 的 `STEPS`。
- 第一关完成卡、各关壹的完成回应：`src/ui/mission_narrative_catalog.gd`（`TASK_CONTEXTS` 每关三行：现在做什么 / 怎样算完成 / 完成后的意义）。C/P/G 九关的中文已改写，其余 51 关仍是旧文案，按同样风格逐章改即可。
- 第 2 章结果文字：`localization/game.zh_CN.po` 中 `chapter2.result.*`。

**故事与演出（罗雅琪）**
- 档案架 13 页：`src/lab/archive_fragments.gd`，每页 `title/body` 可直接改写；`id` 不要改（玩家的已读状态靠它），`requires` 是开启它的任务。文本是根据《壹_未完成的说明书》《背景小说创作交接》写的**候选稿**，人名（林见秋、阿禾）沿用旧稿，可替换。
- 壹在终端上说的话：`src/lab/lab_terminal.gd` 的 `_compose()`（初见 / 首次点灯 / 一般完成三选一 / 欢迎回来）。
- 实验室底部字幕（"桌上的灯亮了。"等）：`src/lab/lab_home.gd` 的 `_arrive()`。
- 可以插入片头 CG 的位置：实验室第一次出现前（`lab_home.gd` 的 `_arrive()`，`returning == false` 分支）。

**交互与关卡（常逸飞）**
- 重点试：新档从实验室到点亮台灯的完整一段；第 2 章「分而复用」的结果条是否让人看懂"在等数据"；旅程地图能否找到后三章。
- 第一关的"专注模式"判定在 `hardware_foundations.gd` 的 `_tutorial_focus()`。

**展示（苏子航）**
- 可截图画面见第 1 节表格。录制固定路线可以用开发参数（只在加了参数时生效）：
  ```
  Godot --path . -- --dev-key=Enter@2 --dev-key=Enter@4.2 --dev-shot=C:/tmp/a.png@8 --dev-quit=9
  ```
  支持 `--dev-click=x,y@秒`、`--dev-drag=x1,y1,x2,y2@秒`、`--dev-rdrag=…`、`--dev-enter=任务键或tree@秒`，窗口固定为 1280×720。第一关完整通关路线见本文第 4 节。

## 3. 需要主创决定的少数问题

1. **实验室走 2.5D 分层插画还是轻量 3D？** 目前是代码绘制的 2.5D + 视差，构图和交互已可用。建议参赛前用陈梓弘的分层 PNG 替换，赛后再评估 3D。
2. **档案架文本是否采用这条"见微知著"的写法**（每个概念对应一段历史）？人名是否沿用林见秋、阿禾？
3. **壹的定位**：这一轮按"有温度、克制的引导者"写，已与 `thought-within-world.md` 中"最多三处痕迹"的旧约束不同，需要确认。

## 4. 验证

- 真实运行：新档 → 唤醒终端 → 进入 → 五步（真实拖线、点击、右键拆线、重新接线）→ 完成卡 → 回到实验室 → 台灯亮起、旅程板与档案架更新。存档在退出重开后保留（第二次启动显示"欢迎回来 / 继续 · 半加器"）。
- 第一关路线（1280×720 窗口坐标）：`--dev-key=Enter@2 --dev-key=Enter@4.2 --dev-drag=517,431,643,421@8 --dev-drag=778,421,1048,431@9 --dev-click=123,462@10.5 --dev-click=177,513@11.6 --dev-rdrag=910,380,910,480@14 --dev-drag=778,421,1048,431@15.5 --dev-click=708,561@18`
- 隔离验证器（`scripts/verify-project.py`，Godot 4.7.1，Windows）逐批通过：新增 `test_lab_journey`（37 项：60 项默认旅程、档案页都对应真实任务、实验室/终端/档案架、首课专注模式跟随真实交互标志）；以及 `test_hub_first_screen`、`test_night_narrative`、`test_hardware_foundations_ui`、`test_task_tree`、`test_task_tree_layout`、`test_creation_route_access`、`test_candidate_journey`、`test_full_journey_narrative`、`test_journey_journal`、`test_completion_presentation`、`test_locality_chapter_ui`、`test_creation_workbench`、`test_cpg_connection_fragment`、`test_creation_future_workbench`、`test_instrument_theme`、`test_system_evidence_guidance`、`test_rule_practice_input`、`test_representation_region`、`test_prediction_workbench_presentation`。
- 旧首页/旧教程/40 项旅程的测试改为显式打开回退开关（`src/lab/lab_features.gd` 的 `classic` / `core_journey`）后继续验证原表面；第 2 章与 C/P/G 的文案断言按新文字更新。
- 未做：完整 364 项回归（本机 C 盘只剩不到 1 GB，验证副本每次约 250 MB，只能分批跑）、陌生玩家试玩、Mac、导出 Windows 包。
- 档案架截图：`r4-archive.png`；第一项完成后窗外中央塔楼亮起一格窗：`lab-progress.png`。

## 5. 下一轮建议顺序

1. 用正式美术替换实验室三层；补终端开机/按键/完成音效（`WindowMode` 已有音效总线）。
2. 按第一关的做法，把序章后几关（半加器、锁存器）也改成"步骤卡 + 少量工具"，并逐章重写 `TASK_CONTEXTS`。
3. 第 1 章系统桌面的浮窗太多：任务/零件/程序/测试/分析器/历史六个窗口，建议合并成左右两栏。
4. 创造结尾：G3 保存的作品回到实验室陈列（档案架旁增加一个作品位）。
5. 每完成一个章节，实验室多一个可见变化（例如窗外城市亮起一处灯）。
