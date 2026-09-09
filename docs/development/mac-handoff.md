# Mac 开发接手说明

当前 Mac 后续进展见 [原生试玩与界面优化](../status/mac-native-polish.md)。已实际完成 Tutorial、Half Adder、CPU 与桥接实验；新的界面修正见该记录；重启存档问题已按批准方案修复，见[恢复验证](../verification/2026-09-08-save-recovery/README.md)。下面的 Windows 候选包信息保留为历史交付基线。

## 当前基线与工作分工

仓库：<https://github.com/wizardpc-com/von-neumann-bottleneck>，默认分支 `main`。

Mac 是主要开发与原生交互试玩环境；Windows 用于兼容性、真实鼠标与导出 EXE 验证。继续优化当前游戏，不重启八关重做。默认入口是原章节选择 → Hardware Foundations → 教程 → 算术/存储两分支 → CPU → LOAD/STORE → Chapter 1 → Chapter 2。八关运行版已于 2026-09-09 按用户要求移除；历史记录留在 Git，不读取或转换其玩家进度。

当前游戏构建标识：`polish-20260907T010358-76ef116`。标识中的旧 SHA 是制作该候选包时的本地基线，不是本次迁移提交 SHA。以 `git rev-parse HEAD` 和 GitHub 提交记录确定源码版本，不改写既有候选包。

完整游戏与接手资料已在提交 `1fef90db8debf45d69dd3973026a09763ce6fbbe` 上传；其 401 个文件的 Git 对象哈希已逐一与 GitHub 核对。后续提交只补充迁移回执。Windows 预发布 ZIP 和构建清单的 GitHub SHA-256 均与本地相同，见 [发布回执](../verification/2026-09-07-windows-handoff/publication.json) 和 [完成记录](../exec-plans/completed/mac-development-handoff.md)。

已完成：原编辑能力恢复、独立三级 Hint、可移动 Mission、清晰任务页签、紧凑电平符号、对齐元件预览、统一仪表风格及字体、随进度开放的 89 条手册知识（29 条带图）。详见 [当前状态](../status/visual-learning-polish.md)。本版尚未通过完整原生桌面试玩和新手验收。

## 先读这些文件

1. 根目录 `AGENTS.md`、`PLANS.md`、`README.md`、`ARCHITECTURE.md`。
2. [视觉与学习计划](../exec-plans/active/visual-learning-polish.md)、[当前状态](../status/visual-learning-polish.md)、[此前构建优化](../status/construction-experience.md)。
3. [原版恢复要求](../design/IN_PLACE_RECOVERY_AND_OPTIMIZATION.md)、[ADR 0015](../decisions/0015-versioned-workbench-snapshots-and-read-only-hints.md)、[测试说明](testing.md)。

旧蓝图中“八关替代主线、深层构建变工坊、固定桌面取代原工具窗”的决定已被撤回。保留历史文档，不据此恢复已撤回方向。

用户最近指出的原始问题截图已保存：[重复且过大的输入控件](../images/feedback-input-controls.png)、[元件图形与说明未对齐](../images/feedback-component-preview.png)。当前候选包已对此修改，但尚未获得用户试玩确认。下一轮仍以科技感美术为重点，并提高叙述的可读性、逻辑性、引导性、手册图解和渐进解锁，面向愿意了解 CS 的新手；参考图灵完备的表达与操作习惯，保留本游戏既有功能及大致进度关系。

## Mac 环境与首次启动

使用 **Godot 4.7.1 stable 标准版**，不需要 .NET、Python 包或第三方 Godot 插件。Python 3 只用于验证辅助脚本。安装匹配版本的导出模板后才能导出平台包；不在迁移时顺手升级引擎。

```sh
git clone https://github.com/wizardpc-com/von-neumann-bottleneck.git
cd von-neumann-bottleneck
git status --short --branch
git log -3 --oneline

GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT" --version
python3 scripts/verify-project.py --godot "$GODOT" --gui --locale zh_CN
```

若已有 checkout，先检查本地改动，再 `git pull --ff-only`；不要覆盖未提交工作。Godot 安装名不同则调整 `GODOT` 路径。脚本会复制 Git 跟踪及非忽略的当前文件到 `.godot/verification/<run>/project`，重新导入资源，为每个检查分配独立玩家目录，并执行 21 套常规测试；`--gui` 加跑普通 Game 的完整 GUI 输入路线。`--interaction-only` 可缩短为教程交互，`--locale en` 检查英文。

脚本只修改副本的玩家目录设置；首次导入时暂时省略全局字体配置以先生成字体缓存，此后所有检查恢复实际字体配置。原工作区和实际玩家存档不变；日志、失败结果和截图均保留，不自动删除。脚本在 Windows 上验证过，Mac 执行结果必须在本机重新记录。

在原 checkout 中打开编辑器或游戏：

```sh
"$GODOT" --headless --path . --editor --import --quit
"$GODOT" --headless --path . --editor --import --quit
"$GODOT" --path . --editor
# 直接普通 Game：
"$GODOT" --path .
```

完全没有 `.godot` 缓存时，Godot 可能在首轮导入之前尝试加载全局字体，并报告尚未生成的 `.fontdata`；首轮导入完成后第二轮必须不再报告资源/脚本错误。不要把它解释为缺少字体源码，也不要提交 `.godot` 来掩盖导入问题。字体源文件、`.import` 设置、资源引用和许可证均在 Git 中。

macOS 可执行文件入口及 `user://` 路径依据 [Godot CLI 文档](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) 和 [数据路径文档](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html)。

迁移检查还修正了两项旧测试的环境依赖：`test_demo_performance.gd` 和 `test_demo_save.gd` 现在自行创建临时输出目录并检查文件打开结果。行为与性能断言保持完整；这些修正不改变游戏逻辑。

## 数据与资源边界

普通 Mac 游戏存档默认位于 `~/Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck/`。验证脚本使用独立的 `~/Library/Application Support/VonNeumannBottleneckChecks/<run>/<case>/`，并用实际运行探针确认隔离生效。Windows 验证脚本另将 APPDATA/LOCALAPPDATA 指向仓库内的测试目录。不要只在 Mac 设置 APPDATA 并假定它能隔离存档。

GitHub 包含源码、场景、关卡/双语内容、测试、`.uid`、字体及许可证、项目/导出配置、现状/决策/截图和精选验证记录。Windows 候选包放在 [GitHub prerelease](https://github.com/wizardpc-com/von-neumann-bottleneck/releases/tag/playtest-polish-20260907T010358)，不塞进 Git 历史。

Windows 的实际存档、命名方案、遥测、备份、完整临时日志和 `.godot` 缓存留在原机器；不上传公共 GitHub。21 个玩家文件在视觉优化交付时均通过原始备份哈希核对。若用户以后需要迁移个人进度，单独私下复制整个相关数据目录，保护新旧版本文件；不要将新版完成标记转成旧版通关。

## 开始开发时的具体任务

1. 确认 Mac 上实际可用的原生 computer-use 工具与系统权限，运行普通 Game。工具不可用或桌面锁定时明确记录，不冒充已操作。
2. 从教程开始真实输入：选中拖动 → 放置/接线 → 线段中间分支 → 精确删线 → 撤销 → 框选/复制粘贴 → 文本框返回焦点 → 缩放/平移 → 窗口/全屏。确认位宽、端口与落点一致。
3. 测试任务随时可找、规格直接可查；H1/H2/H3 逐层主动请求和确认；退出后名称、拓扑、位置、线色不变，继续编辑及完整测试。Hint 返回仍按 ADR 0015 清空撤销历史和剪贴板，不虚称保留。
4. 重点试玩 Tutorial、Half Adder、CPU，检查符号与控件、手册逐步开放、任务可读性、模块关系和下一关动机。补测 Retina/缩放与快捷键/触控板差异。当前 GUI 代码使用 Ctrl 修饰键；Mac 的 Command 支持尚未验收，不预先宣称兼容。
5. 根据实际观察继续局部优化美术、操作、叙述和引导，保留已有功能与大致关卡推进。不用自动加载答案或 Test 模式贯通代替普通 Game 验收，不降低测试要求，不再另写编辑器或仿真。

已批准方向和可逆细节自行推进；重大玩法、架构、持久化、依赖或范围改变再询问。每次记录实际修改、自动测试、画面观察、原生操作和真人新手试玩的不同证据。通过部分检查不等于可以正式发布。

## Windows 后续验证

Windows 只拉取已经提交的明确版本并验证。拉取前检查本地改动；用 `git pull --ff-only`，保留历史包与存档。验证版本必须与 Mac 提交 SHA 对应。

用匹配导出模板，在全新的输出目录导出 `Windows Playtest` preset；附上 `distribution/PLAYTEST-README.txt` 和 `assets/fonts/OFL-NotoSansSC.txt`，记录构建标识、源提交和 EXE/ZIP 哈希。Mac 上也可调用 Godot CLI 导出这个现有 preset，Windows 再实际运行 EXE。

不要用旧 `scripts/build-playtest.ps1` 重复覆盖基线包：该历史辅助脚本会替换固定输出目录，也尚未复制新字体许可证。当前候选包由独立目录导出并已附许可。以后修改打包脚本应保持输出可追踪、旧包不丢失。

本次迁移没有 macOS 导出包、签名、公证或已完成的 Mac 原生验收；这些不是已有成果。
