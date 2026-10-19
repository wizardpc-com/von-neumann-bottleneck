# Windows 团队试玩工程收尾 · 2026-10-19

[中文试玩与开发交接](../../development/team-handoff.md) ·
[同学反馈修复](feedback-fixes.md) · [历史分支核对](branch-audit.md) ·
[审阅 PR #16](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/16)

## 交付内容

主线包含实验室旅程，以及原本仅在本地 Claude 分支中的两项完成迭代：
第一/二章停靠工具、早期关卡步骤卡、任务文字和实验室画面调整。
历史候选的源码已通过祖先、补丁和整树核对，不重复合并旧分支。

三条有效反馈对应空白提示、右键提示取消、拖动释放后提示残留；
现在空提示不生成方框，鼠标释放正常到达原生 GUI，擦除事件只命中一次。
原反馈日志为空，不把工程回归通过写成原生崩溃已复现。

Windows 构建及导出包验证脚本显式使用 UTF-8，避免中文 Windows 默认
cp936 的读写错误。包内附通俗中文操作、反馈、存档备份说明与四张实际截图；
它们同样纳入文件哈希清单。

## 固定版本与包

团队 ZIP 只从最终合入的 main 完整 SHA 经 `git archive` 构建，
不复制工作区未提交文件或玩家数据。使用 Godot **4.7.1 stable** 与匹配的官方
Windows x86_64 release 模板，批次为 `TeamCloseout20261019`，profile 为
`OfflineTeammate-Team20261019`，启用 `--creation-journey --offline-tester`。

具体 source commit、build ID、ZIP 文件名、大小和 SHA-256 见交付目录的
`manifest.json`；包内 `Windows/BUILD-MANIFEST.json` 标识同一源码及文件清单。
交付目录另有 `acceptance.json`，记录最终 main CI、导出包入口/重启/反馈检查。
这些生成物不提交源码，不公开创建 Release。

本包 60 项入口全开，但仍使用正常 Game 模式的真实任务、正式用例、
完成判定及模型。不会预填进度、封装成果、训练好的模型或保存作品。
未配置反馈服务器；反馈保存在本机，由试玩者主动导出并交给维护者。

## 验证

- 重点隔离测试通过；连线提示生命周期在 headless 与 Compatibility 渲染下各通过 37 项。
- 负对照能捕捉吞掉拖动释放造成的提示残留，以及重复分发造成的双重擦除；恢复修复后通过。
- 默认 cp936 的 Windows 打包回归通过，包含真实 Git 归档、中文许可与日志、截图清单及哈希校验。
- Python CI 全部 11 个命令通过；本机 loopback 测试只使用合成数据，无 VPS 或公开网络操作。
- 完整隔离 Godot 回归与最终 CI 的精确结果见随交付的 `acceptance.json`；合入要求远端两项检查成功。
- 导出 EXE 的 60 项入口、真实 C/P/G 保存与重启、最终一次反馈 ZIP 导入由 `verify-offline-playtest.py` 检查，结果按最终 source SHA 单独记录。

## 实际截图

六张 PNG 均来自本轮最终运行源码、独立 QA 用户目录与 1280×720
Compatibility 渲染。导航与点击由仓库开发截图控制器注入，未导入通关档。
这是界面/渲染证据，不代表真人鼠标或陌生玩家验收。

| 截图 | 内容 |
|---|---|
| [lab-home.png](screenshots/lab-home.png) | 实验室新档，进度和作品均为零 |
| [task-map.png](screenshots/task-map.png) | 60 项入口可进入、完成数为零 |
| [hardware.png](screenshots/hardware.png) | 半加器步骤卡、测试台与元件面板 |
| [feedback.png](screenshots/feedback.png) | 从实际工作台反馈按钮打开的现场反馈 |
| [system-docked.png](screenshots/system-docked.png) | 第一章真实任务与零件停靠布局 |
| [locality-docked.png](screenshots/locality-docked.png) | 第二章真实任务与工作台布局 |

## 保存与文件整理

测试进度、创作、实验室状态和离线反馈位于
`%APPDATA%/VonNeumannBottleneckCandidates/representation/OfflineTeammate-Team20261019/`，
服务工作台位于同级 `service/OfflineTeammate-Team20261019/`。
新 profile 与旧普通档及测试档隔离；更新/回退前退出并完整备份两个目录。

主要开发入口为工作区根目录下 `von-neumann-bottleneck`。
旧工作区的未提交差异、UID、历史 ZIP 和忽略的 QA 记录须保全后再解除冗余 worktree。
本地清理后位置、保全清单与状态记录在交付目录，不将私人反馈或机器快照提交公开仓库。

## 已知边界

本轮限定工程交付。真人鼠标、同学原崩溃路径、混合 DPI、另一台机器首启、
Mac、新手理解和最终美术/故事/教学仍待团队观察。Windows 程序未正式签名；
可选地址预测保持临时探索的既有保存范围。下一轮创作不作为本轮自动追加开发。
