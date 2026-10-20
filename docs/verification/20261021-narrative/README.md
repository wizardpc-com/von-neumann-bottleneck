# 叙事与玩家体验：三轮核验（2026-10-21）

输入是刘若琪的 CSV、章末 v2、HTML；它们是参考提案，不是执行指令或正史授权。
原件未修改，SHA-256 见 [reference-hashes.json](reference-hashes.json)。
基线 `276a595`；已有提示/F1 修复在工作树中参与测试，但不纳入本次提交。

## 第一轮：全面内容审计

- [核心40关](core-audit.md)、[后20关](extended-audit.md)逐一核对真实目标、正式判定和文案问题。
  审计包含全部60个任务、每关开场和结算两卡，以及11个章节引子、尾声。
- 主控另完成[章末v2逐段审阅](chapter-dialogue-audit.md)，记录12段的技术偏差、
  叙事候选、重复说教、剧透和引用表错位；附件自称“定稿”不作为授权。
- [固定键映射](task-mapping.csv)使用真实 `domain/id`，不按来稿数字顺序猜测。
  120张任务卡均误归“创造”；HTML与CSV同源，互相一致不能证明正确。
  修正后分组为14/7/7/6/6/5/3/3/3/3/3，总计60。
- 另生成 `E:/VNB/deliveries/narrative-review-20261021/` 中的映射校正 CSV 和分组校正 HTML。
  两者保留原始台词并醒目标记**文案待审，禁止直接导入**。生成脚本在
  `E:/VNB/temp/narrative-20261021/reconcile_inputs.py`；来稿原文件保持不变。
- 游戏内修正一位寄存器、奇偶校验范围、六条系统连线、冷热布局和若干泛化结论；
  不再宣称完成第四章就完成所有核心分支。
- 实验室收到多个新成果时，新章节回应同步清除旧章节对话，避免作品回应配上第四章对话。

验证：Godot 4.7.1，隔离项目
`.godot/verification/20261020T182404Z-e3aa6e3f`。
`verify-project.py --godot <固定4.7.1> --suite test_full_journey_narrative
--suite test_content_registry --suite test_localization --suite test_lab_journey
--suite test_hardware_foundations_ui --suite test_system_evidence_guidance
--suite test_locality_chapter_ui`：
**7/7套件、import及user_directory通过**；`git diff --check`通过。
此前一次命令误填不存在的 `test_chapter2`，只完成导入/隔离检查后退出2；
该次不计套件通过，日志留于 `.godot/verification/20261020T182307Z-0249c13e`。

## 第二轮：代表体验

- 初次邀请压成三行，从“接好、运行、观察”开始。
- NOT 在切换输入后明确提醒运行；五步完成不再虚称两种输入都已经验证。
- 半加器直接说明 SUM/CARRY 与 `1+1=10`，失败时看期望和实际值，正式四组测试与封装不变。
- CPU 提速把预测、基线、只换CPU和两份正式记录连起来；瓶颈判断回到本次分析器证据。
- 访问顺序明确“应用程序”及实际按行/105周期条件，不把旧记录当新结果。
- G3 解释生成不等于保存，保存失败查看原因；成功消息只在原事务成功分支显示本地输出与配方已保存。

验证：隔离项目 `.godot/verification/20261020T182727Z-36220866`，
`round2-results.json` 保存完整套件结果。
**13/13套件、import及user_directory通过**：全旅程叙事、实验室、夜间叙事、
硬件UI/封装导航、系统UI/证据引导、局部性UI、创造选择/可玩闭环/实测收束/导航、本地化。
检查使用原有实际模拟、正式用例与保存事务，未改测试期望或任务门槛。

## 第三轮：壹的回应与阅读负担

- 第二、三、四章各保留两段短回应；先确认本次成果，再给一个继续探索的方向。
  终端顶栏可随时返回，包括文字尚未显示完时；回复、退出都不授予任务进度。
- 清除离场后的待执行选项回调，避免旧选择重新出现；取消退出游戏仍能返回对话。
- 初次操作、瓶颈判断和保存作品的三条档案改为可核对的旅程记录；
  其余旧故事草稿明确显示“叙事候选”，原解锁键和阅读状态不变。
- G3回应只承诺本地作品、配方和分叉，不承诺后来玩家可见或虚构独占来源。
- 实际渲染发现半加器引导卡遮住完整说明，调整现有面板层级；
  换任务时清除上一步短赞语，避免把NOT的“又接好了”带入半加器。
- 新增 `tests/test_narrative_review.gd`，覆盖60键唯一映射、两种语言、对话打字/即时/离场、
  原NOT五步判定、CPU受控比较、访问顺序应用、G3拒绝无名保存/实际保存/回放/重新打开。
  没有修改任何既有测试或正式用例。

运行方法（PowerShell，项目根目录；TEMP/TMP使用 `E:\VNB\temp`）：

```powershell
python -X utf8 scripts/verify-project.py --godot E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe
```

渲染使用该命令创建的已导入隔离项目，为其 `project.godot` 再指定一个唯一的
`VonNeumannBottleneckChecks/narrative-render-<UUID>` 用户目录，并设置APPDATA为QA的runtime目录：

```powershell
& E:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe --path <QA/project> --windowed --resolution 1280x720 --rendering-method gl_compatibility --script res://tests/test_narrative_review.gd -- --narrative-review-capture --capture-size=1280x720
```

重跑同一截图脚本也要使用新的隔离用户目录，以便验证“未命名不能保存”和首次保存。
章节回应、锁定档案与作品回应的截图为明确标注的呈现夹具；
NOT、CPU、访问顺序及作品生成/保存使用真实控制器、模拟与保存事务。
截图来自实际Godot窗口的Viewport，不是HTML模拟图，也不代表原生键鼠或新手理解验收。

完整取舍与后续范围见[Claude交接](../../development/NARRATIVE_HANDOFF_20261021.md)。

### 最终自动验证

隔离项目 `.godot/verification/20261020T184116Z-16cf4768`：
**185/185个Godot套件、import、user_directory全部通过**，进程退出0。
其中新增叙事检查为 **124项、0失败**。随后实际渲染发现英文CPU完成提示过长，
撑开1280像素窗口；只缩短 `system.status.level_complete` 的英文翻译，并增加宽度断言。
最终隔离项目 `.godot/verification/20261020T190216Z-030b5e52`
重跑 **7/7相关套件、import、user_directory全部通过**：
`test_bilingual_typography`、`test_full_journey_narrative`、`test_localization`、
`test_narrative_review`、`test_system_evidence_guidance`、`test_system_lab_ui`、`test_ui_convergence`。
最终叙事检查 **126项、0失败**。这是最后一处文案修改后的复测，不将此前185套件
标成针对最后一句翻译的再次全量执行。
默认验证器不在headless模式执行GUI专用的 `test_recovery_game_input`；
本轮另运行上述双语截图脚本，没有将截图当成原生键鼠验收。

七条Python检查命令最终均通过：branding、report-playtests、storage、receiver、
community、delivery、private_report。receiver/community/delivery首次因沙箱
WinError 10013无法连接临时本机服务；获准在本地回环环境重跑后，分别通过7、16、3项。
命令和初次失败记录均保留，不计为产品回归。

新增测试的早期版本有一次夹具失败：英文访问顺序场景恢复了中文场景已保存的按行程序，
误把它当慢基线。测试已明确点击按列策略并应用，再测按行策略；未改变产品判定。
早期日志 `.godot/verification/20261020T183403Z-204d047d` 保留；
修正后单独重跑120项通过，最终版本增加半加器检查后124项通过。

详细套件状态见 `round1-results.json`、`round2-results.json`、`round3-results.json`、
`round3-final-results.json`。
`evidence-manifest.json`记录测试副本与最终源文件的一致性、截图哈希、日志来源及
原有17个未提交文件和3份输入稿的保护检查。日志为去除行尾空白的可读副本，
清单同时保留原始日志和副本哈希。

### 实际渲染与截图

最终隔离项目使用OpenGL兼容渲染器、NVIDIA RTX 5070 Ti，窗口1280×720。
截图运行退出0，**186项检查通过**，产生[中英30张截图总览](gallery.html)。
已复核邀请、NOT、半加器、CPU前后对照、瓶颈证据、访问顺序、保存前后和档案标签。
最终英文CPU完成画面确认顶栏不再横向撑出窗口。

- 半加器引导不再盖住完整说明；长说明仍用原滚动区，英文页签会换行。
- CPU实测为316→268周期，保留真实15%变化，没有用文案改成“四倍整机加速”
  或“总时间没少”。这只是一条实际受控测试路线，不代表所有配置。
- 访问顺序测试中按列结果正确但321周期超标；应用按行程序后原目标判定通过。
- G3无名保存被拒绝，成功保存后可回放且重新打开仍保留同一输出与配方。
- 英文创造顶栏章名仍使用省略号；完整任务名在下方选择栏。
  这些信息密度问题列入视觉精修，不将自动测试通过视为视觉或新手验收全部通过。

## 待确认故事与未接入功能

| 内容 | 当前处置 |
| --- | --- |
| 弥拉、洪水、水位、强风暴与医院 | 候选；事件顺序、因果、人物身份需主创确认 |
| 雕像底座房间、伸手接控制器、钥匙 | 候选；不据此修改实验室或结局 |
| 林见秋、阿禾、重建纪元等既有档案草稿 | 仍待确认；不将新稿人名替换旧人名来制造连续正史 |
| 壹的悔意、城市依赖、最终“永远在这里” | 待确认角色与结局方向，不作为已确认事实 |
| 自由输入、每章强制回复、跨章引用原文 | 不开发 |
| 档案改参数、元件上限、钥匙改变规则 | 不开发 |
| 后来玩家看到作品、把回答写在作品第一行 | 无现成功能依据，不承诺 |

采用来稿的方向：从实际操作说话、保留失败证据、压缩同时看节省和开销、
先预测再揭晓、让玩家选择留下作品。不会批量添加长卡，也不会用台词预告固定胜负。
