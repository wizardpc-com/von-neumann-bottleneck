冯·诺依曼瓶颈 — 免费公开开发版候选
构建：free-alpha-20260911-candidate1（准确源码提交与哈希见随包 build-manifest.json）

免费、单机、无需账户、无需安装 Godot。未公开发行，当前是可交付试玩的候选构建。
Mac 解压后打开 Von-Neumann-Bottleneck.app；Windows 解压后运行 Von-Neumann-Bottleneck.exe。
Mac 使用本地 ad-hoc 签名，尚未申请 Apple 公证；Windows 原生分发验收待完成。
不要为试玩关闭系统安全保护。公开下载渠道的签名/首次启动体验需要在发布前另行验收。

从“新游戏”开始；已有进度用“继续游戏”。总任务树可拖动、缩放、搜索和查看锁定任务规格。
路线：序章造机器 → 第一章找等待 → 第二章减少搬运 → 第三章安排到达 / 第四章数据布局。
共 40 个任务；探索支线不增加旧主线的通关门槛。八关替代版已彻底退役。

元件台默认打开。自由选件、拖动、从端口和线段中间分支、删除、命名方案继续保留。
Mac 用 ⌘Z 撤销、⇧⌘Z 重做；Windows 用 Ctrl+Z / Ctrl+Y。编辑文字时快捷键优先作用于文字。
细线和圆端口表示 1 位信号，宽线和方端口表示多位总线；交叉不自动相连。
右键/Esc 取消进行中的操作；工具窗可以移动和收起。任务与规格随时能回看。
调试当前输入、完整测试和回放分开；动画速度不改变模拟结果。
Hint 使用独立只读画布，H2/H3 各自主动请求并确认；提示不会替你接线或改布局。
手册按当前任务推荐少量概念，后续知识逐步开放。设置入口可减少界面淡入动效。

第四章：选择字段分组、排列和分块；后续任务引入实际复制成本与有限临时区。
同样正确的输出可以有不同有效布局。准备/查询/输出时间、读写流量和临时峰值分别显示。
点击运行结果的批次事件，可以看到该批真实地址；尾批保留余数记录。

F8 或反馈按钮可对当前/选中任务写意见，未通关也能评价。评分默认不选，部分填写也能保存。
行为记录默认只在本机；本候选没有配置回传服务器。可关闭本机操作统计，仍能保存主动意见。
自动回传须另行同意，意见须单独点击发送；网络不可用不影响游玩。导出只在你主动操作时生成文件。
随机安装标识不等于绝对匿名；不要在意见里填写敏感个人信息。

游戏进度：savegame_v1.json；电路方案：hardware_workbenches_v1.json。
第四章进度、草稿和命名布局位于原进度文件的可选 layout 部分。更新前请完整备份存档目录。
Mac 默认：~/Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck/
Windows 默认：%APPDATA%/Godot/app_userdata/Von Neumann Bottleneck/
不要用清档准备对照试玩。新游戏会询问是否删除旧方案，默认保护作品。
回退旧程序前先备份整套文件：旧程序可能不保留新章字段，不能保证自动向后兼容。

这不是“新手一定看得懂”的验收承诺。已验证和未验证范围见 KNOWN-ISSUES.md 与实际记录。
Noto Sans SC：SIL OFL 1.1；Godot：MIT 及所附第三方声明。图形和图解为本项目代码绘制，未使用图灵完备的美术资源。

Von Neumann Bottleneck — Free Public Alpha Candidate
Five regions, forty tasks. Offline single-player; no payment, account or Godot installation required.
Open the app (Mac) or EXE (Windows). Continue preserves existing progress. Optional branches do not gate the old mainline.
Free construction, mid-wire branching, deletion, undo/redo, named designs and independently confirmed read-only hints remain available.
Chapter 4 measures actual addresses, transfers, copy costs and bounded scratch memory. Different valid solutions are accepted.
F8 opens optional task feedback, including unfinished tasks. Unanswered ratings stay empty. Sharing is off; this build has no server URL.
The package is an unnotarized candidate. Windows native launch, external novice comprehension and comfort remain acceptance gates.
Back up both save and workbench files before updating or reverting. See the manifest and accompanying notes for exact evidence.
