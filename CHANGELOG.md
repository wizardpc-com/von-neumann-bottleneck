# 更新说明 · Changelog

[简体中文](#简体中文) · [English](#english) · [README](README.md)

## 简体中文

### 2026-09-14 · 导线预览（源码更新）

- 反向拖线保持接好后的曲线方向，接近有效端口时对齐，拒绝连接显示叉号。
- 线头随鼠标移动轻微提亮，停下后收敛；保留单线／总线区别和减少动效设置。
- 仅改变编辑反馈，导线仍无仿真延迟；现有候选包未覆盖更新。

### 2026-09-14 · 原生试玩修正

候选：`free-alpha-3b0afc5a4234`，内容提交 `3b0afc5a4234`，未公开发行。

- 返回任务树保留视野；被遮住或收起的工具可一次唤起。
- 第一章支线编号使用真实任务数；语法错误不再重复提示“程序为空”。
- 原生检查确认草稿／语言／重启恢复，实际完成“一取再用”，重跑双缓冲与布局综合关。
- [完整证据与导出包鼠标验收边界](docs/verification/20260914-native-followup/README.md)。

### 2026-09-13 · 最后一轮发布前收敛

本地候选：`free-alpha-6c5c59df6c26`，内容提交 `6c5c59df6c26`；尚未公开发行。

- 第一、二章保存未应用草稿、已应用程序、部件与配置；重要观察记录按当前模型重新计算。恢复作品不授予通关。
- 保存失败会提示，并提供独立恢复文件；继续游戏跳过锁定任务。
- 关内复用完整设置，切换语言后回到原任务，记住窗口位置；第二章结束后回任务树。
- 修复旧档已完成综合关误锁编辑器，任务说明底部操作保持可见。
- 统计报告正确读取访问汇总，分离版本和玩家分组；暂时断网可持续补发，队列优先保留意见等重要记录。
- 预留 Logo／图标替换接口，增加隔离 CI、40 任务维护表和操作手册。

[本轮证据与候选状态](docs/verification/20260913-final-convergence/README.md)。未修改 40 任务、仿真和解锁规则，未配置公网服务。

### 2026-09-13 · 双语界面与空间层次打磨

候选构建：`free-alpha-47a59d385103`。内容提交：`47a59d385103`。
这是本地冻结候选，尚未公开发行；后续文档提交不改写这个构建编号。

- **中英文文字与排版：** 凝练章节标题，精简说明；英文按自身语感改写。长说明随窗口换行，缩放后的任务树保留可读字号，内存图分开表示字段、记录和数值。
- **界面层次：** 首页突出任务树；保留五章图形与主题色，增加克制的背景层次，弱化后台浮窗边框，突出当前操作窗口。
- **任务与操作：** 修复章节地图节点重叠和任务树拖动问题；从 Hint 返回时保留工具窗位置、收起状态与相机视角。长 Mission 中的翻页与开始按钮提前显示。
- **运行结果：** 分析器增加计算／等待比例；时间线统一字体、批次标签和周期刻度。第二章将程序编辑、应用和状态提示放在参考资料之前。
- **验证：** 隔离检查通过；当前 Mac 导出包实际完成任务树导航、教程拖放／接线／删除／撤销、通关、退出恢复与英文设置复查。

Windows 实机、另一台 Mac 安装／公证、外部新手及长时间 DPI／焦点验收仍待完成。完整记录见[候选验收](docs/verification/20260913-spatial-candidate/README.md)与[发布前待验收项](RELEASE_BLOCKERS.md)。

### 本次版本包含的既有内容

- 序章与四个后续章节，共 40 个任务；统一任务树、探索支线和附加挑战。
- 自由构建、线中分支、删除、撤销、命名方案、浮动工作台与独立三级 Hint。
- 缓存与局部性、异步搬运与预取、数据布局与实际复制成本。
- 语言、音量、减少动效、诊断导出；本地个人任务板和逐关评分意见。
- 存档来源重验、备份和最低写入版本保护；远程反馈前置已完成本地联调，公开端点仍为空，上传默认关闭。

此前的八关替代运行入口已经移除。旧开发记录保留为历史依据，不代表当前关卡数量或发布状态。

### 文档更新

README 改为中文首页与独立英文页，更新五区域介绍、运行方法、平台状态和反馈说明；用当前源码的中英文首页／任务树配图替换旧版配图。新增本页供玩家查看版本变化，开发证据继续由 [CURRENT_STATE](docs/CURRENT_STATE.md) 汇总。

## English

### 2026-09-14 · Wire previews (source update)

- Reverse drags match the final cable curve; valid sockets snap and rejected endpoints show a cross.
- Gentle pointer-driven feedback settles at rest and respects reduced motion and scalar/bus notation.
- Presentation only: wires still have zero simulation latency. Existing candidate packages are unchanged.

### 2026-09-14 · Native playtest fixes

Candidate: `free-alpha-3b0afc5a4234`, content `3b0afc5a4234`; not publicly released.

- Preserve the view when returning to the tree; recall covered or minimized tools with one click.
- Use the actual Chapter 1 task count; omit the redundant empty-program message after syntax errors.
- Native checks cover draft/language/restart recovery, a player-built read-once solution, double buffering and the layout capstone.
- [Evidence and remaining exported-input acceptance](docs/verification/20260914-native-followup/README.md).

### 2026-09-13 · Final pre-public convergence

Local candidate: `free-alpha-6c5c59df6c26`, content commit `6c5c59df6c26`; not publicly released.

- Preserve draft text, applied programs and configuration separately in Chapters 1/2. Recompute saved observations against the current model; restoration does not complete tasks.
- Surface save failures with an independent recovery export. Continue skips locked tasks.
- Reuse full settings during play, restore the task after language changes and remember window geometry. Chapter 2 completion returns to the tree.
- Fix a completed capstone's locked editor after legacy restart; keep Mission actions outside long scrolling explanations.
- Read visit summaries correctly, separate version/cohort groups and recover queues after prolonged transient outages.
- Add optional branding slots, isolated CI, a 40-task maintenance inventory and owner workflows.

[Evidence and candidate status](docs/verification/20260913-final-convergence/README.md). The 40 tasks, simulation and unlock rules remain; no public service is configured.

### 2026-09-13 · Bilingual presentation and spatial UI polish

Candidate: `free-alpha-47a59d385103`. Content commit: `47a59d385103`.
This is a locally frozen candidate, not a public release. Later documentation commits do not change its identity.

- **Writing and typography:** more concise titles and explanations, with natural English phrasing. Long text wraps with its window; task-tree labels retain a readable size when zoomed; memory diagrams distinguish fields, records and values.
- **Visual hierarchy:** a prominent task-tree entry, five preserved chapter emblems and accents, restrained background depth and quieter inactive instruments.
- **Tasks and interaction:** fixed overlapping chapter-map nodes and native tree dragging. Returning from Hint preserves instrument placement, collapsed state and camera view. Mission page actions appear before long explanations.
- **Results and tools:** compute/wait proportions in the profiler, consistent timeline type, batch labels and cycle ticks. Chapter 2 puts program editing, Apply and draft status ahead of optional reference material.
- **Verification:** isolated checks passed. The actual Mac candidate was exercised through tree navigation, tutorial placement/wiring/deletion/undo, completion, quit/restart and English settings.

Windows hardware, another Mac installation/notarization, external beginners and extended DPI/focus sessions remain pending. See the [candidate record](docs/verification/20260913-spatial-candidate/README.md) and [release gates](RELEASE_BLOCKERS.md).

### Existing content included in this version

- The prologue and four chapters: 40 tasks, a shared prerequisite tree, optional branches and bonus challenges.
- Free construction, mid-wire branching, deletion, undo, named designs, floating instruments and separate three-stage hints.
- Cache locality, asynchronous transfers and prefetching, data layout and actual copy costs.
- Language, audio, reduced motion, diagnostics, an offline completion board and per-task ratings/comments.
- Provenance revalidation, backups and minimum-writer protection. Remote-feedback groundwork has local integration coverage; the public endpoint is empty and uploads remain off by default.

The former eight-task replacement runtime has been removed. Older development records describe history, not the current content count or release status.

### Documentation update

The repository now has a Chinese homepage and a separate English README, refreshed five-region descriptions, startup/platform/feedback instructions and current-source bilingual hub/tree images. This changelog provides a player-facing overview; [CURRENT_STATE](docs/CURRENT_STATE.md) remains the technical evidence index.

## 2026-09-14 · Competition entry / 参赛入口

- 首页可直接切换中英文；修复首次打开元件台时第一张卡片被截断。
- Added a bilingual home-screen language menu and kept the first component card fully visible.
- Added bilingual first-session guidance and a player-friendly feedback form. Five regions / 40 tasks remain unchanged; this is not a public release.

候选 / Candidate: `free-alpha-60de5e54c95d` (not publicly released).

- 设置和手册可拖动标题移动，边界内保持关闭按钮可见；Mac 支持 ⌘, 设置、⌃⌘F 全屏。原有工具窗拖动／缩放和 Windows 快捷键保留。
- Settings and Handbook support bounded title dragging; Mac adds ⌘, for Settings and ⌃⌘F for fullscreen. Existing floating tools and Windows shortcuts remain.
- 两份 README 新增第四章综合关真实截图；中英文试玩说明和参赛素材包已备妥，尚未提交比赛。
- Both READMEs feature a real Chapter 4 capstone run. Bilingual quickstarts and local contest materials are prepared; no contest submission has been made.

## 2026-09-14 · 任务桌面与玩法配图 / Task desktop and gameplay images

- 序章顶部合并重复标题、减少空白；任务说明留出上下拖动空间，翻页和开始按钮继续可见。
- 拖动／缩放按画布坐标跟随鼠标，松开、取消或失焦后停止；不改变电路和存档规则。
- 中英文 README 新增四位 CPU 与双缓冲实际方案截图和简短介绍。
- Compact construction header, more room to move Mission, and scaled floating-window gestures that stop on release or focus loss.
- Both READMEs show saved CPU wiring and a measured double-buffer run.

Source follow-up only; the previous frozen candidate remains unchanged.
[Evidence / 验证记录](docs/verification/20260914-compact-desktop/README.md).
