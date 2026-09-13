# 更新说明 · Changelog

[简体中文](#简体中文) · [English](#english) · [README](README.md)

## 简体中文

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
