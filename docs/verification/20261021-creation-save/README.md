# 创造：名称定位与保存反馈

G3 的名称框位于底部操作行。空名称时，现在直接聚焦该框，保留玩家正在查看的证据页；壹的说明也指向下方名称框。其他单元仍打开名称框所在的“作品与配方”页。没有新增弹窗或必读步骤。

“保存草稿”与“保存作品”的反馈分开：前者明确保存的是草稿；当前输出尚未留下时，提示命名后保存为作品。上方常驻状态也显示“草稿已保存”。作品库达到原有12件上限时，提示本次没有新增作品、当前输出仍可查看；即便同样的输出以前保存过，这句话也准确。

这些修改只涉及呈现和名称框定位。生成、命名限制、保存事务、作品上限、存档格式及G2/G3通关判定均不变。文案由主控亲自审计、改写；没有新增或确认故事设定。

重新进入G3并恢复上次作品时，底栏说明作品已经打开，可回看或从配方另开草稿；不再沿用新档案的“点学习”提示。只读档仍保留原有只读与恢复诊断。

## 验证范围

新增 `tests/test_creation_save_input.gd` 使用独立存档。准备阶段通过现有控制器真实学习、传输和逐格预测；G3阶段通过Viewport点击生成、保存草稿、尝试空名称、输入过长名称、纠正名称并保存。核对实际输出与配方一致，并重新打开场景读取磁盘中的作品。最后通过原保存事务建立12件作品的明确测试场景，点击保存第13件，验证旧作品全部保留。

这不是从第一关开始的完整玩家旅程，不是操作系统原生输入或真人理解验收。回看窗口的打开来自实际点击；测试通过控制器关闭该嵌入窗口，窗口内部操作另由既有作品查看测试覆盖。满库场景是测试准备，不代表玩家手工创造了12件不同作品。

相关测试：`test_creation_save_input`、`test_creation_measured_closure`、`test_creation_choice_completion`、`test_creation_input_validation`、`test_creation_workbench`、`test_creation_navigation`、`test_creation_state_regressions`、`test_narrative_review`，以及导入和隔离存档检查。

结果：上述8项相关测试及两项环境检查通过。完成最终措辞和重新打开提示后，重新运行 `creation_save_input`、`creation_workbench`、`creation_raw_readonly`、`creation_choice_completion` 四项及两项环境检查，全部通过。最终中英文GPU回放各45项检查通过，共10张1280×720截图；已目视检查名称定位、成功反馈、恢复作品和满库拒绝。501个运行及测试源文件与最终QA副本哈希一致，`git diff --check`通过。

运行命令：`python -X utf8 scripts/verify-project.py --godot <Godot 4.7.1 executable>`，为上述测试分别指定 `--suite`。图形回放使用隔离QA副本、独立APPDATA和新的自定义user目录，参数为 `--windowed --resolution 1280x720 --rendering-method gl_compatibility --script res://tests/test_creation_save_input.gd -- --locale=<zh_CN或en> --recovery-capture --evidence-dir=<证据目录>`。

最终结果、命令和观察值见 `logs/` 与 `evidence-manifest.json`；[中英文关键画面](gallery.html)展示保存草稿、空名称、成功保存、重新打开和满库拒绝。

补强“先切换证据页，再触发空名称错误”的测试时，回放脚本曾错误调用TabBar不支持的坐标转换方法。错误日志保留在 `logs/exploration/`；最终回放使用控件的实际全局变换，没有改动正式测试或游戏逻辑来绕过该错误。

## 后续交互精修

保持“草稿保存”和“命名留下作品”的区别，避免把两种操作都缩成没有对象的“已保存”。G3名称框始终与保存按钮相邻；错误反馈应保持可见且允许直接修正。作品回看和继续修改仍由玩家主动选择。

弥拉、洪水、雕像、钥匙、壹的身世等仍待主创确认。原故事候选清单及三轮审计见[叙事报告](../20261021-narrative/README.md)。本次后续改动未提交，没有推送、合并远端或发布。

本轮保留此前全部工作：16个原有文件保持最初哈希，`hardware_foundations.gd`保持上一轮已经核验的呈现增量和原有帮助改动；3份来稿保持原哈希。证据清单记录具体文件校验值。
