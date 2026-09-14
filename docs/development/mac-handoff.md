# Mac 开发接手说明

更新：2026-09-14。当前源码、冻结包和验收范围以 [CURRENT_STATE](../CURRENT_STATE.md) 为准；发布门槛见 [RELEASE_BLOCKERS](../../RELEASE_BLOCKERS.md)。

## 当前入口与边界

仓库：[wizardpc-com/von-neumann-bottleneck](https://github.com/wizardpc-com/von-neumann-bottleneck)，默认分支 `main`。
Mac 是主要开发与原生试玩环境；Windows 负责实际 EXE、输入与 DPI 验证。
使用 **Godot 4.7.1 stable 标准版**，Python 3 用于隔离验证和打包辅助脚本。
导出需要同版本模板；不在接手时顺手升级引擎。

普通 Game 从首页的任务树进入，五个区域共 40 个任务。章节卡片是另一种导航；
“继续游戏”回到任务树并定位最近可用任务，不改变解锁。八关替代运行版已移除。
保留自由选件、接线、线中分支、删除、撤销、命名工作台和独立三级 Hint。

先读根目录 `AGENTS.md`、`PLANS.md`、`README.md`、`ARCHITECTURE.md`，再读
[文档索引](../README.md)、[测试说明](testing.md)、[维护指南](final-maintenance.md)和
[最新导线／任务／手册验证](../verification/20260914-wire-iteration/README.md)。
旧计划中已标注 HISTORICAL / SUPERSEDED 的内容不是新的实施队列。

## 启动与隔离验证

已有 checkout 先检查 `git status --short --branch` 和提交记录；拉取采用
`git pull --ff-only`，保留本地修改。首次使用可从上面的仓库地址克隆。
按本机安装位置设置引擎路径：

```sh
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT" --version
python3 scripts/verify-project.py --godot "$GODOT" --gui --locale zh_CN
python3 scripts/verify-project.py --godot "$GODOT" --gui --locale en
```

依次运行，不并行启动 Godot 验证或原生试玩。隔离脚本复制当前源码到
`.godot/verification/<run>/project`，每项检查分配独立玩家目录并验证实际路径。
`--gui --interaction-only` 仅回放 Tutorial；`--suite <测试文件名，不含 .gd>` 可重复指定定向测试。
失败日志与截图保留；测试通过不等于新手理解或导出包验收。

日常编辑可在 Godot 中导入 `project.godot`，完成资源导入后运行项目；直接启动：

```sh
"$GODOT" --path . --editor
# 普通 Game：
"$GODOT" --path .
```

普通启动会使用真实玩家目录。原生 QA 应使用验证生成的副本及其独立目录；
深层关卡只复制已经获得的 QA 存档并经过原有来源重验，不能插入完成标记代替游玩。
若空缓存首次导入报告缺少尚未生成的字体缓存，检查隔离脚本的导入处理，
不要提交 `.godot` 或删除字体引用来掩盖问题。

## 存档与工作区保护

Mac 正常用户目录为 `~/Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck/`；
检查目录位于 `~/Library/Application Support/VonNeumannBottleneckChecks/<run>/<case>/`。
Mac 仅修改 `APPDATA` 不能隔离用户数据；必须检查引擎实际报告的目录。

当前主存档使用 schema 2，文件名仍为 `savegame_v1.json`。保留备份、最低写入版本检查和来源重验。
第一、二章草稿与已应用程序分开恢复；恢复作品不授予成绩。不要将旧备份手动覆盖新版主存档。
玩家数据、遥测、临时日志和缓存不提交；个人进度迁移应私下复制整套数据目录。

## 原生操作与平台检查

1. 从普通 Game 进入 Tutorial，实际测试元件台拖放、正反向接线、分支、删除、撤销、框选复制和文本焦点。
2. 任务规格直接可看；H2/H3 各自确认。检查 Hint 返回后的工作台和相机恢复、退出后的方案恢复。
3. 检查窗口移动／缩放、减少动效、暂停回放时平移缩放、松开和失焦取消。导线只有连接意义，动画不能改变仿真时间。
4. Mac 检查 `⌘Z`、`⇧⌘Z`、`⌘,`、`⌃⌘F`；Windows 检查 `Ctrl+Z`、`Ctrl+Y`、`Alt+Enter`；两者均保留 F11。按界面提示复核，不能只靠源码推断兼容。
5. 区分源码输入回放、直接渲染、原生鼠标和导出包证据。CUA 返回 `noWindowsAvailable` 时记录工具限制，不声称已完成鼠标操作。

最新未闭合项包括持续拖动／焦点与混合 DPI、Windows 实机、另一台 Mac 安装和外部新手。
没有这些新证据时，不用旧候选或单元测试代替验收。

## 分发与历史回执

采用[统一冻结流程](../distribution/free-alpha.md)，从一个明确提交生成 Mac／Windows 包，
再检查身份、哈希、随包说明和真实操作。源码领先现有候选时必须新建构建编号，不能覆盖旧包。
公网服务、签名／公证资料和正式发布由用户另行决定。

2026-09-07 的迁移、旧 Windows prerelease 和当时版本仅保留为历史：
[迁移完成记录](../exec-plans/completed/mac-development-handoff.md)、
[发布回执](../verification/2026-09-07-windows-handoff/publication.json)。
这些旧包不代表当前五区域版本；9 月 8 日的存档修复见[历史验证](../verification/2026-09-08-save-recovery/README.md)。
