# 终端任务名称核对

终端的继续按钮现在分两行显示操作和完整任务名，复用旅程地图已有的名称处理。悬停仍可查看包含章节前缀的原始标题。壹的下一项提示与普通完成回应也保留完整任务名。

旧规则会把英文接线教程、半加器缩成 `Prologue`，把表示章节的四项任务缩成数字；其他较长名称可能在关键名词中间截断。此次逐项核对真实目录的60项任务及两种语言，没有另建简称表或改写关卡名称。初次邀请和导航动作保持原样。

## 验证与画面

Godot 4.7.1 的六项相关测试及导入、存档隔离检查全部通过：`test_terminal_task_titles`、`test_lab_terminal_routing`、`test_lab_journey`、`test_ui_convergence`、`test_terminal_presentation_polish`、`test_creation_lab_return_input`。

新增名称检查覆盖120条本地化目录记录，核对按钮、悬停说明、下一项提示、普通完成回应、名称唯一性及720p可见范围。无界面运行964项检查通过；中英文图形运行各490项检查通过，保留16张截图。源码与QA副本逐文件校验，详见 `evidence-manifest.json`。

[截图索引](gallery.html)和[名称对照表](task-title-comparison.csv)可供复核。主控目视检查中英文接线、半加器、表示与G3代表画面；完整名称可读，原有导航按钮仍在终端内。

这些截图使用真实目录驱动终端的**呈现夹具**，没有授予通关或解锁。因此终端显示的候选任务可能与旁边读取真实新存档的“下一项”小屏不同，不能作为60关连贯通关证据。实际路线由既有导航测试及真实作品返回测试另行验证；没有原生操作系统输入或新手理解验收结论。

复现：运行 `python -X utf8 scripts/verify-project.py --godot <Godot 4.7.1 executable>`，对上述测试逐项指定 `--suite`。图形截图在已导入的隔离副本运行 `--windowed --resolution 1280x720 --rendering-method gl_compatibility --script res://tests/test_terminal_task_titles.gd -- --locale=<zh_CN或en> --recovery-capture --evidence-dir=<目录>`，使用独立APPDATA及自定义user目录。完整命令、检查和日志位于 `logs/`。

## 边界

仅修改终端展示；任务键、导航选择、模拟器、存档、正式测试和通关判定均未改动。既有修改与三份来稿保留。本项补查未创建提交、合并、推送或发布。

恢复无作品草稿时的阶段提示仍待后续核对；英文实验室游戏名截尾继续留给视觉精修。弥拉、洪水、雕像、钥匙等故事候选仍待主创确认。
