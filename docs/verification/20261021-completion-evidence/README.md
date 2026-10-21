# 结算证据与半加器体验

半加器失败时，测试台现在在实际输出下方显示该用例的期望 SUM/CARRY，并在重新排版后滚动到完整结果行。玩家可以就地找出不一致，不必回翻真值表。四项正式测试通过时标题为“测试通过”；玩家执行封装、真正获得元件后才显示“关卡完成”。原有模拟、正式用例、封装和通关条件均不变。

## 文案调整

- NOT 总结只确认已经完成的五项操作，不把动作标记当成完整接线已获验证。壹鼓励玩家再试 NOT 时先预测灯的状态，再运行检查。
- 半加器中，指标和规则由测试结果说明；壹改为一句“以后搭更大的电路，试试从你自己的零件开始”，减少重复解释 1+1。
- 局部性综合结算将“最佳结果／最佳配置”限定为已记录方案中的最好结果。真实的周期、等待、成本与配置仍从既有 receipts 选择和展示；删去与壹回应、下一步建议重复的总结段落，使英文结算完整适配720p。
- 交替接力结算不再复述写死的“12周期”，让玩家在真实指标和时间线上观察重叠；壹以不同处理节奏作为下一次探索的问题。本轮使用的参考场景实测仍为28周期、重叠12周期，**没有证明存在重叠量不同的合格解**，也未修改目标或模型。

文案由主控亲自复核和改写；子任务只提供事实核查。核心与扩展60条壹结算回复、主要结算调用路径及保存状态做了静态交叉检查。这不等于60关全部经过本轮实际游玩。

## 实际运行与截图

[截图索引](gallery.html)包含中英各15张1280×720实机渲染，分为两类：

1. `test_half_adder_input.gd`：全新隔离的普通 Game 存档，通过 Viewport 鼠标、键盘和拖线事件，从终端进入 NOT 并完成五项操作，继续半加器。先把 SUM 接成 OR，实际运行四项正式测试，确认1+1的 SUM错误而CARRY正确；拆线修正后四项通过，再点击封装。每种语言84项检查，涵盖失败结果行的完整可见性、封装前后状态与标题。
2. `test_completion_evidence.gd`：明确标注的隔离 Test 模式控制器场景。局部性综合执行基线、诊断及两种方案的真实模拟，验证642→138周期和成本4的记录；交替接力使用公开参考方案执行真实模拟。每种语言10项检查，含结算在720p内完整显示。不是玩家从头挣得的整章进度。

人工目视核对了半加器失败、待封装、已封装和两项章节结算的中英文关键画面。首次操作阶段沿用先前输入回放；其完成画面是即时淡入截帧。章节控制器场景等待现有开场提示自然退场再截取稳定画面。

## 自动验证与复现

13项相关测试：`test_half_adder_input`、`test_completion_evidence`、`test_localization`、`test_narrative_review`、`test_ui_convergence`、`test_first_lesson_input`、`test_first_build_guidance`、`test_hardware_foundations_ui`、`test_locality_chapter_ui`、`test_overlap_ui`、`test_overlap_simulation`、`test_full_journey_narrative`、`test_bilingual_typography`。同时执行导入及隔离存档检查。最终压缩局部性结算文字后，重新执行与其相关的`completion_evidence`、`localization`、`locality_chapter_ui`、`full_journey_narrative`、`bilingual_typography`五项，以及中英文四次GPU回放。

调用 `scripts/verify-project.py --godot <Godot-4.7.1.exe>`，为上述每项重复指定 `--suite`。GPU回放在已导入的隔离副本，以新的自定义 user目录和独立 APPDATA 运行，参数为 `--windowed --resolution 1280x720 --rendering-method gl_compatibility --script res://tests/<suite>.gd -- --locale=<zh_CN或en> --recovery-capture --evidence-dir=<证据目录>`。不要使用正常玩家存档。

最终日志和运行命令见 `logs/`，源文件与证据校验值见 `evidence-manifest.json`。探索中的旧断言以及结果行裁切失败日志保留在 `logs/exploration/`；未降低既有正式测试来换取通过。

结果：13项相关测试及导入、隔离存档检查全部通过；最后的5项复测及两项环境检查全部通过。四次最终GPU回放共188项检查通过，生成30张截图。当前500个运行和测试源文件与最终QA副本哈希一致，`git diff --check`通过。

## 保留边界

- `hardware_foundations.gd`原有帮助/F1改动保持完整。本次只增加失败期望值呈现及滚动前等待布局两处，共7行。逆向移除这两处后，文件字节与本次开始前快照一致；另外16个原有改动文件及3份来稿保持原哈希。
- 子审计曾误报五条硬件支线缺少总结映射。主控重读完整字典后撤回：五项映射原已存在，没有改动。这不是未修复缺陷。
- 没有改动模拟器、存档格式、正式用例、通关条件或未确认故事。弥拉、洪水、雕像、钥匙等仍按[原待确认清单](../20261021-narrative/README.md)处理。
- 回放证明指定操作与反馈相符，不替代操作系统原生输入、新玩家理解和全程人工试玩。本轮改动保持可审阅的未提交状态，没有合并远端或发布。
