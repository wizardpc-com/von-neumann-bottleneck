# 首次操作与文案补查

在三轮叙事修改之后，以全新、隔离的普通 Game 存档补查首次入口。文案审计与改写由主控完成；没有改变模拟器、存档结构、正式用例或通关判定。

## 修改与发现

- NOT 原判定在第一条线接好时就记录“接线”动作，步骤卡会转到“改变输入”。该提示现在保留 **A→NOT→灯两段线都要接好** 的提醒，避免玩家漏掉第二段。
- 判定中的“有效运行”是 trace 有效且包含 LAMP 输出；它不是对完整 NOT 拓扑、两组输入都已运行的证明。实际输入回放确认：灯未连接时运行仍可记录该动作。保留原判定，并修正核心 60 关审计中此项的边界说明。
- 是否把教程通关进一步绑定完整反相行为属于玩法决定，本次不修改。壹的结算也不能据动作标记声称玩家已逐项验证所有输入。

## 验证范围

新增 `tests/test_first_lesson_input.gd` 复用已有 GUI 输入工具，通过 Viewport 的键盘、鼠标、拖线与右键划线事件进入真实界面。没有调用解题载入器、控制器运行方法、进度 setter 或模拟快进。

回放路径：唤醒终端 → 开始 NOT → 第一条线 → 改输入、运行尚未接灯的电路 → 接上灯 → 实测 A=1/LAMP=0 → 改为 A=0/LAMP=1 → 右键划掉灯线 → 接回 → 原五步判定完成 → 继续半加器 → 打开可选完整说明 → 返回搭建。

中英文各 **44 项检查通过**，包含各 10 张 1280×720 实际 GPU 渲染截图。七项相关测试及导入、隔离存档检查的结果见 `logs/results.json`。截图见 [画面索引](gallery.html)，源文件与证据校验值见 `evidence-manifest.json`。

图中的灯值来自实际 SimulationTrace。`not-incomplete-run` 特意保留未接灯的探查；`not-complete` 捕捉完成面板淡入时刻，不能用于判断稳定态透明度。逐字回应在部分即时截帧中尚未打完；操作提示即时显示，不依赖等待回应。

这些检查证明指定操作能走通，不等同于操作系统原生输入、新玩家理解或半加器完整解题验收。半加器本轮只检查自然进入、短目标和可选说明的开关。

## 为后续视觉与交互精修保留的事项

- NOT 步骤号来自已有动作标记；若希望“接线”在完整路径接通后才结束，需要明确区分引导进度与通关判定后另行决定。
- 720p 下半加器元件和完整说明较密，测试台的结果与辅助文字共用滚动区域。主操作能点击，但仍值得新玩家试玩确认视线落点。
- 未确认故事内容沿用[三轮审计待确认清单](../20261021-narrative/README.md)，不增加正史。

## 复现与证据

相关自动检查：

```powershell
python scripts/verify-project.py --godot <Godot-4.7.1.exe> --suite test_first_lesson_input --suite test_first_build_guidance --suite test_first_light --suite test_tutorial_replay --suite test_narrative_review --suite test_full_journey_narrative --suite test_localization
```

GPU 回放在已导入的隔离 QA 副本运行，每次使用新的 `config/custom_user_dir_name` 及独立 APPDATA。命令尾部为 `--windowed --resolution 1280x720 --rendering-method gl_compatibility --script res://tests/test_first_lesson_input.gd -- --locale=zh_CN --recovery-capture --evidence-dir=<独立证据目录>`；英文换为 `en`。不要在正常玩家存档上运行。

探索失败记录也予以保留：首次脚本未处理切场景时的短暂 null；修正后，原先“未接灯不能记录有效运行”的三个断言与真实规则不符，已依据源码及实际运行纠正。失败日志在 `logs/exploration/`，最终结果在 `logs/`。
