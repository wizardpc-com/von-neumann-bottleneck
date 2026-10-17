# 全旅程续轮证据 · 2026-10-18

本轮实现60项任务语境、只读成长档案和真实3D观察站，保留原工作台、原完成权威及原导航。
这是持续开发中的证据入口，**active计划及完整goal均未关闭**。
需求与开放项见[覆盖账本](../../development/full-journey-coverage.md)，
执行与所有权见[active计划](../../exec-plans/active/full-journey-experience-20261018.md)。

## 当前Gate

- **F1双实包控制器链已通过，完整goal保持active**。包SOURCE为`8334ab137beb95f24f6092ac0a23df69c592255f`；普通包父77项/独立重启29项，测试者包父87项/独立重启29项均全部true、无失败，实际进程exit0。
- 普通最终来源`night-package/5acc08e7a872`；测试者最终来源`night-package/288ef5076947`及原始子链`offline-package/367b69c41ea4`。测试者实际60入口前景、真实C→P→G/作品逐字节重启、4现场/2会话、最终单ZIP导入/报告/去重均通过，随包collector SHA为`d0de7376…2f4bf`。
- 两包controller均为`52e78b94…41bf8`（QA检查点59209c6）；normal保留原强类型validator，tester只将既有编码器的六个CPU工作区坐标映射到expected-loaded整数，完整列出转换，其余typed JSON及全部protected文件SHA严格保持。源码、controller、validator完整SHA及原结果链接见[checks.json](checks.json)。
- SOURCE8334新增收集器已独审并14项Python实测通过；总控核其Godot runtime/assets/project/export-presets/tests与226无差异。226 `cdace219`原full **168/168 PASS/exit0**、13/13定向、原Rule真实401/Journal真实222及两CI成功只覆盖相同runtime，不冒称8334另跑full。Root另实时核8334的CI39071109957/39071106629均completed/SUCCESS。
- Store及collector均取消填满目录rename发布，使用排他fresh目标、先验证内容再最后发布元数据或原ZIP；不加sleep/retry，不承诺断电fsync、批次原子性或所有IO必成功。旧1639/637/226collector、7f工作区采样和8aa坐标类型QA失败均原样保留，不推断唯一OS根因。
- **normal与tester8334限定原生OS路线均PASS**：Root实际Sky输入完成normal真实教程五操作/唯一成果、普通F8/Esc/3D相机；tester60/60可进但0成果，Reflection内F8保存本地现场/截图并逐层Esc，不授完成。PID38852/47384均正常exit0，独立核pristine全部文件未变、normal仅tutorial成果/两根线、tester空进度context/本地PNG/无远程队列。不是新手、原生CPG/独立重启/中文长输入/真实旧作品/Mac验收，完整goal保持active。

文档恢复点`7b8b352`（此前`dea36d3`/`342e8e6`）只保存证据，不是包SOURCE。索引stat/CRLF假修改已由总控逐字节/filtered blob核同HEAD后刷新，cached diff为空，未改变生产字节；原检出`tests/test_ui.gd`的既有删除未动。

## 已保存的检查点（历史，不表示当前Gate）

总控核准基线为`cf89a76`，分支`codex/full-journey-experience-20261018`。
F1源码可恢复检查点已由总控提交为`c50492a`及`0aa1866`；它们不是最终包冻结，也不声明所有Gate通过。
文档检查点为`4215a5b`，已随新分支推送；[草稿PR12](https://github.com/wizardpc-com/von-neumann-bottleneck/pull/12)
以旧候选分支PR11为base独立审查新增内容，未合main、未Release。
源码`0aa1866`的CI`39064173749`已由总控核读completed/FAIL：Service evidence tab在最小窗口、Hint展开时
有两项越界失败，原cf89基线为绿；不能归为旧已知失败。其余套与Python11项由总控核读通过。
该CI的完整head为`0aa1866fb48e375913804f7d0d23daec4552670f`，Godot job`117488197070`、
Python job`117488197257`；本地下载168份顶层txt（含import/userdir，166份test日志），
扫描仅`test_service_plan.txt`含两行ERROR。这里区分日志数量与进程退出码，不从无错误文本另造通过数。
后续恢复点为`e47c62a`（共享popup反馈窄修）、`79f12f3`（窄窗Host）、
`65974a1`（独立审图文档）。产品源码现冻结供Narrative取fresh copy，GUI/旧反馈回归与远端新CI尚待结果。
最后await guard为`13e1f84`；Service最小两列布局检查点为`5570327`，已连同guard推送。
这仍不是最终包SOURCE冻结；完整fresh原verify已结束为166/168通过，规则练习反馈关闭仍有P0待诊，不能据单套canonical通过宣布完整IO或交互已闭合。
基线CI运行`39061439011`已由总控核读为completed/SUCCESS；它不证明本轮新增代码。
[旧7c固定包及限定原生验收](../20261018-night-experience/README.md)保留原身份，
当时尚无本轮新固定包、原生或陌生玩家验收结论。未执行公网发布、账号/服务器修改或旧存档迁移。

## 已落盘的可观察变化

- 九个原工作台使用同一`MissionNarrativeCatalog.task_context()`：先显示Now/Verify，再按需展开
  壹的语境、卡点方向、承接与真实完成回顾；不替代原任务规格、手册和Hint，不改变验收。
- Home/map可选打开JourneyJournal。其目录取自真实`journey_tasks()`，原核心记录单独计数；
  展示历史成绩的已有case/model/build来源、原作品只读快照和明确标识的虚构候选片段。
  入口开放不算完成；临时/损坏/未来版本/只读证据不补造历史、不取得writer lease。
- Home/map可选打开真实3D观察站：SubViewport、Node3D、程序几何、三个固定视角与原生文字。
  灯和✓来源于同一合法完成判断，不能把测试者入口或地址预测临时记录当成果。
  灯是叙事映射，不是电路信号、能耗或文明测量；原任务树保留。

## 独立源审

| 作者范围 | 独立审查 | 结论及边界 |
| --- | --- | --- |
| Narrative：60context、ContextCard、完成overlay及9Host | Knowledge只读核对真实catalog、完成/历史/草稿、合法替代、切任务/撤销/语言、委托及临时探索 | 未发现生产阻断。测试中缺少必需reason参数已由作者修复；不代替运行/布局验收 |
| Knowledge：Journal及测试 | Narrative只读核对completed/session/只读、无写入/lease、导航失败保留、成绩来源及作品保护 | 无确定阻断；指出ThemeReflection/F8焦点栈缺口，新增真实渲染专用测试待跑 |
| Visual：观察站及Home/map入口、测试 | Knowledge只读核对完成与访问、坏档/session、浏览无写、实时门禁、3D及生命周期 | 无生产阻断；要求真实Host/F8/焦点链，已补测试，结果按各快照列示 |
| Knowledge：Store发布窄修与test_offline_store | Visual核对fresh排他/碰撞保全、旧pending、context/PNG/metadata/cache顺序、半写recovery与完整有效metadata后验失败可恢复边界 | 22603源审无静态阻断；后9a/be37/cba及cdace全量通过，8334相同runtime双实包链也通过，不扩大为所有IO或耐久保证 |
| Knowledge：离线收集器与原/新增Python回归 | Visual独立核批预验/去重/冲突、排他owned、逐hash、文件publish、两个reader及半成品/旧坏库边界；Root/Narrative附加审查 | 无静态阻断，原10+新增4共14实际通过；新8334包内tool原子链实际最终ZIP-only通过，不扩大为所有IO保证 |

测试前置和输入注入方式的问题单独保留，不把它们自动诊断成产品故障。

## 隔离快照与早期失败

Godot为`4.7.1.stable.official.a13da4feb`。原始日志留在本地忽略目录，
[脱敏摘要与原始结果SHA-256](checks.json)保留每次来源；未复制玩家内容或绝对用户目录。
目录名使用UTC，文档日期使用Asia/Shanghai。

| 来源 | 实际结果 | 适用范围与限制 |
| --- | --- | --- |
| `verification/20261017T192129Z-cbc56971` | import/userdir/旧地图通过；Hub 28/7483失败；新观察站测试编译/超时 | 24项旧固定按钮数量断言失效，另4项英文720p恢复提示实际越界；新测试过早preload引发autoload标识错误。保留失败 |
| `verification/20261017T192616Z-93ecc682` | 5/5阶段通过，Hub7507项通过 | dynamic-load测试、显式入口断言和首页间距修正后的早期copy；字体未缩小 |
| `night-render/ccba2cdd3da7` | 真实720p观察站12/454失败 | 3D/三视角已有实际PNG。F8轮询Input动作，而viewport-only注入未更新动作；后续改全Input注入，未删除断言 |
| `verification/20261017T192847Z-c6d957a2` / `night-render/17e7c6ccc3b0` | import/userdir/观察站通过；渲染仍2/454关闭链失败 | 首12→2可归因Input注入修正；剩余2项原因未确立，不能写成已定位产品bug |
| `verification/20261017T193052Z-12298ff6` | Narrative1/1128失败；Journal Nil运行错误并超时；观察站通过 | Synthesis双合法路线文本断言未满足；Journal未明确进入教程而访问空输入控件，后续改真实TaskNavigation进入并核对就绪。不是生产编译失败 |
| `verification/20261017T193442Z-fdd646fa` | import/userdir/观察站299项通过 | 仅此固定copy |
| `full-journey-visual-smoke/09b471c286b4` | 同fdd copy：Journal160项、Narrative1128项通过 | headless控制器/模型及只读保护，不是OS输入、完整关卡游玩或窗口渲染验收 |
| `night-render/56fea33b0d74` | 真实720p观察站454项通过；24张全帧/3D纹理 | 源摘要`1f1bfc7b43274e280c7ad9cba33492f4f8ea4a4c0145f33b05c42cf312e93096`；包含明确fixture灯亮/灭，不冒充玩家earned。旧2项关闭失败未在该fresh runtime重现，因果仍未建立 |
| `verification/20261017T193841Z-85535900` | import/userdir/观察站3/3阶段通过 | 最新coherent copy，包含后续marker、system topology/locale及Reflection测试；不与fdd源码混同 |
| `full-journey-narrative-runs/0388d903ab50` | 同855 copy：11/11套定向PASS/exit0，无超时终止子进程 | Journal160、全旅程Narrative1134、旧Narrative61、system guidance84、tester导航66、封装导航25、DirectKeep87、当前模型准备39，以及Overlap模拟/UI、Layout UI。Journal明确打印Reflection/F8窗口栈NOT_RUN |
| `full-journey-narrative-runs/574f3d275059` | 同855 copy：Narrative真实渲染及54帧通过；Journal渲染2项失败、exit1，无子进程超时终止 | Journal总174项；全user目录inventory变化、ThemeReflection上的tester首次Esc未仅关闭反馈。焦点窗口、反馈重挂popup、真实captured截图的前置断言均通过；不能据此前headless成功跳过修复 |
| `verification/20261017T194235Z-464601a8` / `verification/20261017T194755Z-be2664fe` | 464：import/userdir/Narrative3阶段通过；be：再含旧ThemeReflection共4阶段通过 | 字号/布局及ThemeReflection窄修后的新copy，不能沿用旧855的最终结论 |
| `full-journey-narrative-runs/05473520dca7` | be copy真实Journal诊断，exit1、181项，保留6项失败 | 唯一inventory变化确证为presentation.cfg；tester新Reflection全栈通过，ordinary Moments真实popup有5项失败。源摘要`e84171f0a5bf8e6250ef757b10cb427637176db22e7e022994beac3937880210` |
| `full-journey-narrative-runs/0ce751c48843` | 默认54帧真实clip检查通过；located EN硬件三窗3项失败，整体exit1/1398项 | 共108张默认/定位截图，不把默认通过扩大到定位可见性通过。QA随后改为定位Verify，须新回执 |
| `verification/20261017T195523Z-fa540e36` / `full-journey-narrative-runs/d19c0f3f2015` | fa540 import/userdir/旧ThemeReflection3阶段通过；d19另8套全部PASS/exit0 | 5反馈旧suite、全旅程Narrative1138、System UI及Overlap UI；源码摘要`3495e7579b1d97dd5357349d795de525953be117334ad228b3a079b5cc8aefb9` |
| `full-journey-narrative-runs/04248b56a603` | 同fa540固定copy：Journal真实GUI194项PASS/exit0 | 普通/测试者popup Esc栈、普通共享layer销毁/后续root F8及保护SHA均通过；采用既有capture-size契约。**不含后加tester销毁回归**，不能由普通生命周期通过替代 |
| `full-journey-narrative-runs/7e44804d9270` | 旧fa540产品+单独QA镜像：tester销毁实际SCRIPT ERROR，exit1 | OfflineFeedback:97对已释放panel调用get_viewport；runner仅因script_error终止自有child，后续paused=true/root恢复未执行。qa-only-delta证明原产品/测试未变，仅加镜像SHA`927042eb5006533860a5d0b1929024eff4b53aa2e6abe409b8e97a6a53dbff71` |
| `full-journey-narrative-runs/122d90b88ed3` | fa540原产品+QA镜像身份：真实9Host默认/定位矩阵1462项PASS | 对应ad48e787...摘要，共108帧；定位Verify的QA路径已复测。不能覆盖后续新增tester/await回归或新CI失败 |
| `ci-39064173749/20261017T195035Z-4f3b46f8/test_service_plan.txt` | 原0aa远端全仓CI失败，Service两次最小viewport/Hint tab越界 | 原断言保留，Narrative获准在原service Host作最小布局修复；真实字体/Now/Verify/Hint不能删改来放宽Gate |
| `verification/20261017T195934Z-23a79ab1` | 580e固定产品旧OfflineFeedback headless失败/超时exit-1；ThemeReflection通过 | 初始两次F8/首保存未失败，首错是历史note加载；原case的append-only revision1意见仍在，第二不同ID写在pending未发布。两context相同/root/headless；缺last_error，创建失败具体原因待诊，不归因新popup或最后await guard |
| `full-journey-narrative-runs/d1c0528fa6d4` | 同580e产品、外部即时诊断QA镜像保留全部旧断言，PASS/exit0 | 各open的last_error为空、pending为空、原意见正确恢复；这次未复现23a，不关闭原失败或推定Windows路径/环境原因 |
| `verification/20261017T200833Z-c4e3e37e` | 同580e产品与原verify环境形状的唯一追加诊断，PASS/exit0 | fresh隔离目录、原stamp/test stem与继承TEMP、无automated参数，所有原断言保留；仍未复现23a，确切原因UNKNOWN，不改Store |
| `full-journey-narrative-runs/f5842f09ab8c` | 最新3ec copy真实Journal GUI222项PASS/exit0 | source `33bba51fd47d7d7282646df8f59b14ef45f0bc48c92cb1c15ce3b6dbedd17c52`；带既有capture参数，普通/测试者真实Window、F8/Esc/Tab、销毁及等待capture退出、两原暂停分支、完整受保护SHA均通过；不等于原生验收 |
| `full-journey-narrative-runs/c373e13a8281` | 同3ec copy旧6套反馈定向均PASS/exit0 | 私有隔离runner结果不能替代原verify/canonical入口的重复失败闭合 |
| `verification/20261017T200848Z-3ec80941`、`full-journey-narrative-runs/abd2e6068691` | 原canonical OfflineFeedback先后失败；Service原suite7268与OfflineStore通过 | 最新原入口可首case为空；保留完整pending、脚本错误和owned failfast结果，不能写作只有早期一次偶发 |
| `verification/20261017T201148Z-4a0d0062` | 原canonical文件名/环境形状仅失败时QA日志，发布失败已定位rename阶段 | Godot Error1/Failed，last_error为Could not retain incident: Failed；write_verify/mkdir未报失败，生产Store未改。只读事后核验源243字符存在、目标241字符不存在、父目录存在，两份有效JSON完整；尚未取得该次底层OS错误 |
| `native-rename/20261018T041601` | 8个独立synthetic scratch原生文件IO：7成功，1个MoveFileW即时Win32 Error5/Access denied | 同原长路径243→241字符的其他3个case成功，短路径4个成功；失败源及JSON SHA仍完整，目标未创建。无Godot/UI、无旧pending移动/晋升、无sleep/retry。证明同形原生rename也能失败，不能据此判定具体锁/安全软件或把P0关闭 |
| `native-rename/temp-20261018T041735` | 一次系统TEMP隔离副本对照在首个short组建子目录时报WinError5；0次rename | 不改ACL/设置、不重试，不能宣称TEMP可靠；后续工具进程有不同sandbox TEMP身份，不能用其看不到前目录回溯失败权限 |
| `native-rename/escalated-20261018T041841` | 正式工具require_escalated一次对照：4个新独立case全部成功/error0/SHA保持 | short及同243→241长路径×MoveFileW/MoveFileEx各1；raw记录进程与限定环境，不是RunAs/UAC/安全设置修改。支持优先在正式权限上下文核验canonical原suite，不证明唯一根因或持久IO保证；无游戏/UI原生验收 |
| `verification/20261017T202023Z-2e1f125e` | 正式require_escalated下未改canonical `res://tests/test_offline_feedback.gd` PASS/exit0，无terminated child | test SHA `9b19562c62f0b4c42cfe0c354e053877aa7bbde195e803aac8b7d7c37c3b188a`，Store SHA保持3781…；raw日志文件名虽带diagnostic，实际command为原canonical脚本、无别名/QA日志改动。可进入整合验证，不将默认环境失败归为已证唯一沙箱原因 |
| 中间`557` CI `39065505735` / `verification/20261017T200935Z-94bd8364` | completed FAIL；completion_service_clarity 100项中2失败@76 | 旧断言要求summary/chart直接父节点为scroll.child0，与同一scroll内两列布局不符；其余数值、clip、滚动定位断言保留。总控授权test-only改祖先关系，并明确verdict/continue/playback在scroll外；不得改写该CI或当前679原full结果为全绿 |
| `verification/20261017T202144Z-1639bbd5` / `full-regression-watch/0b495ce99c5c` | 原full完整168阶段，166PASS/2FAIL，exit1，0脚本错误提前中止 | 651/651原始文件匹配679、无额外tests；FAIL为旧completion_service_clarity100/2与rule_practice_input391项。后者最早@180反馈Esc关闭/@181焦点恢复，随后输入级联；6cases+第7完整pending（root1440×900/headless/tester），尚缺同步last_error，不先归因具体IO阶段 |
| `verification/20261017T203448Z-298ed2bf` | 49c fresh import/userdir/clarity100/Service7268四阶段全部PASS/exit0 | 651/651原始文件匹配49c，无额外tests；该test-only修正闭合旧结构断言，不改写679原full166/168，也不关闭rule反馈P0 |
| `verification/20261017T203610Z-f74ffc45` / `203649Z-cd1936bb` | 原文件名QA即时诊断headless长/短目录各391项PASS/exit0 | 保留全部原断言，test与隔离Store仅日志增量；各18cases/pending空、同步last_error空。这两次通过不覆盖后续真实GUI失败 |
| `verification/20261017T203738Z-d4664dcc` | 未改canonical原rule、短根真实renderer FAIL/401项 | 原基础391项加实际10个capture保存断言；10cases+第11完整pending，root EN1280×720。后续帧反馈层底部实际“No writable incident…”证明无writable current且拒绝关闭，仍缺该次create失败同步stage/error；不是仅“Esc未送达”即可解释 |
| `verification/20261017T203859Z-6370806f` | 原assert与即时QA日志真实GUI短根FAIL/401项 | 第8case目录rename Error1/Failed、目标208字符，F8后同步current空/busy=false/paused=true；首Esc进入NoWritableIncident保护。原UI保全正确，生产Store发布协议窄修待独审/运行，不将原因归为输入或MAX_PATH |
| `full-journey-python-offline-original-20261018T0454.log` / `full-journey-python/20261018T044728` | 未改Python原导入器10测试PASS；额外synthetic recovery兼容PASS | recovery/cases中context-only/半metadata、旧pending未知version共5文件原样SHA保留，仅1正常incident，源ZIP与导入原件SHA同；正式权限文件IO，无Godot/UI。不是新Store实际导出ZIP或包验收 |
| `verification/20261017T204609Z-9a0116bc` | 新226固定fresh13/13定向阶段PASS/exit0 | 651/651原始文件匹配226、无额外tests；含Store新碰撞/半写/旧pending/PNG失败/后验失败边界及旧反馈保护 |
| `verification/20261017T204737Z-be37b124` | 原canonical Rule真实renderer401 PASS/exit0，10 PNG已hash | 原test未加QA日志；actual-incident-audit逐核18个真实captured records、pending0、三尺寸各6、PNG与context逐一同尺寸；不等于OS输入或陌生玩家验收 |
| `full-journey-narrative-runs/cba6b34bfc40` | 同226 fixed copy真实Journal222 PASS/exit0，无owned终止 | 普通/tester两渠道、实际Window/F8/Esc/Tab/销毁/等待capture两暂停分支及精确作品保护仍通过；新full与包尚待 |
| `verification/20261017T204927Z-cdace219` / `full-regression-watch/ef47b78c025e` | 新226完整原verify168/168 PASS、exit0，168 owned child无提前终止 | 651/651源码原始字节匹配226，无额外tests；原flags/assert/枚举/180秒不变，正式权限owned-only SCRIPT ERROR failfast监督包装。results SHA `323b150d04eeccaf26f17dcc231ba0cc799f4c95c0a830a1900dd2a5c1a58d4b`；不认证尚未执行的双包/native |
| 旧226 normal `night-package/2e6b054ba54a` / `0efcc61a5134` / 后续a914 | QA定位与重启基线失败均保留 | 2e6误开完整briefing而非compact任务卡；0efcc含Unicode辅助进程加载失败、退出autosave只改saved_at与备份轮转；a914 raw canonical JSON及disk相同、Godot parser int→float使直接==误报。之后QA增加post-exit不可变基线、raw typed canonical和原进程内全SHA，五类purefixture不放宽值/bool保护；产品/旧226 ZIP不改 |
| 旧226 normal `night-package/ffd39a6b6958` | 父77/77、strict embedded重启29/29及validation全部通过 | 同controller `548b33d3402da2c728c4d27d28567b9d7aee05939a925eb7f6361df1cb04d269`；只证明旧226 normal，不替代新8334封装 |
| 旧226 tester `offline-package/4a727fb25f53` | 游戏内捕获/独立重启通过，最终仅ZIP导入失败，整链不通过 | Python `stage.rename(target)`发布已填充目录时报WinError5；原stage由既有finally清理，原ZIP及前段library仍存。异常原始证据为exec session78397/chunk f9e63b工具输出，无持久stdout raw文件；目录内`final-import-failure-summary.json`为明示现场摘要及各原engine/ZIP SHA，不冒充traceback原日志。无自动重跑或最终成功父/child收据 |
| 新8334 tester `night-package/7f012fb299b0` / `offline-package/60be0ebe5225` | 父与包内tool最终ZIP子链通过；strict embedded重启前拒绝，未启动重启进程 | 递归值/类型比对仅磁盘新增`/game/system/workspaces/cpu_speed`，父workspaces为空；main/bak同SHA，非timestamp或JSON数值类型差异。真实CPU工作台退出会保存当前草稿，旧父在退出前采样。QA检查点59209c6在末次采样前flush/save并核CPU草稿存在且未授完成；不放宽保护、不改游戏或ZIP。旧拒绝回执保留，最终新链待证 |
| 新8334 tester `night-package/8aa60f052841` | 实际父/子链和引擎重启29项/全磁盘SHA通过；外层typed post gate失败 | 仅CPU/BUS/RAM六个位置从整值float按既有ChapterWorkspace编码回读为int；旧FAIL保留。QA纯fixture与独审后，仅这六个expected-loaded坐标转换，其他typed字段及全磁盘SHA保留；最终新288链通过，不把8aa追写绿 |
| 新8334最终 `night-package/5acc08e7a872` / `288ef5076947`、`offline-package/367b69c41ea4` | normal77+29、tester87+29与实际随包collector全链通过 | 重新核父/重启/基线SHA关联、ZIP/manifest SHA及实际exit0。测试者60入口与真实CPG/作品重启、4现场/2会话及最终ZIP独立导入/去重；原生另验 |
| `full-journey-python-offline-publish-20261018T0602.log` | 新收集器原10+新增4：14/14 PASS/exit0 | CLI SHA `d0de737615515b38db5ac45051c553ddd2ce5b2daf2206d00f6bd6980ab2f4bf`；覆盖顺序/逐hash/排他/marker可见性/损坏旧库/文件publish故障与owned回滚，不承诺消除所有真实IO风险 |

56fe晚于上述旧失败，**但早于**marker主题实际最小尺寸修正、system拓扑/语言刷新回归和
Journal→ThemeReflection→F8新栈。其成功不能认证这些后续差异。
视觉实现/素材替换接缝及失败细节见[观察站说明](../../development/full-journey-visual.md)。

## 历史整合过程与当时待证状态（非当前Gate）

本节保存各检查点当时的诊断、失败、等待项和命令，不描述当前状态。下文“当前”“仍待”“P0开放”“未运行”均只适用于相邻旧来源；最终F1结论见页首及新包限定原生观察，不追写旧失败为通过。

唯一引擎持有人为Narrative，总控负责令牌与最终整合。最新已完成的be2664fe/054735诊断确认：
inventory仅`presentation.cfg`从absent变为
`b9149c226c1e6142ced388947878597c7ca34b8f47e2eb79e39669e5f755d050`，
测试主动改窗口而触发WindowMode已有周期偏好保存；其余所有被盘点文件保持相同。
后续沿已有`--capture-size=1280x720`确定性渲染契约重跑，保留完整inventory断言，不新增忽略。
tester真实popup首Esc窄修已在054735通过；ordinary的panel显示、viewport、内部焦点、Tab和首Esc五项
均实际失败。现已落盘的PlaytestMoments最小修复复用原layer并挂到实际聚焦Window，
按该viewport布局和恢复焦点，销毁popup时归还layer；ThemeReflection仅桥接自身普通F8/反馈关闭。
Knowledge独占这一共享source窄修，不改数据渠道、模拟或存档；OfflineFeedback仅下述生命周期窄修。
该普通反馈窄修已在fa540/04248固定copy真实GUI194项通过，并通过上述旧反馈/ThemeReflection回归；
不将其扩大为后加测试者销毁路径通过。
独立审查指出的tester窗口销毁风险已在7e448旧产品真实复现。总控核准的最小修复现已落盘：
只给实际owned非root Window注册一次退出回调，先归还原layer再调用原close_panel；
原was_paused、反馈flag与草稿拒绝保存/救援策略沿用，无新状态、渠道或存档含义。
对称回归包括原paused=false/true、layer存活归还、flag/原暂停恢复、root F8再用及原作品SHA不变。
新源码和测试已冻交Narrative取fresh copy；最新f584真实GUI222已通过这些分支，不继承旧194结果。
另补post-draw后target有效/在树/未queued-free检查：目标在等待期间消失时恢复原暂停/busy/toolbar及合法焦点，
在任何纹理/title/incident访问前取消，不截root替代现场。同步capture→等待前queue_free的两原暂停回归已落盘；
Visual独立只读审查无阻断，最新f584实际运行已通过。保存拒绝时救援路径未作故障注入，不声称全时序保证。
最后await保护已保存为`13e1f84`恢复点；580e/23a旧headless失败并不含它。
23a存档与创建目录已只读检查：首意见没有丢失，第二incident在case写校验或目录发布阶段中止；
两ID不同、目标为root，不走新增非root退出分支。需外部QA记录每次open的last_error/status精确收窄，
不先改生产store，不把历史加载失败认作已确定的环境或异步故障。
Visual亦独立只读核对Store与23a文件，无确定静态合同违例或580e因果；完整pending JSON
不能区分case写后验证、创建cases目录、rename失败三处。随后4a0d失败日志已定位为rename返回Failed；
创建为空可级联导致关闭拒绝、历史未加载、暂停未退与后续task缺失。d1c/c4e及c373的成功不抹去
canonical重复失败；原生scratch单次Error5只缩小差异，不是该次Godot错误的OS归因。Store生产SHA保持
`3781da04c2702aa3c0668c2f3b5a3422e409d79fc29db24f35711252d657fb11`，P0仍开放，不加任意重试或放宽断言。
有界底层对照现已停止：默认沙箱中出现的同形原生Error5、系统TEMP的准备失败、正式权限四项成功
分别保留。下一步由总控决定正式权限上下文的canonical原测试；尚不改变Store、保存格式或玩家profile，
不晋升旧pending，不把少量scratch成功说成所有IO已可靠。
随后2e1f125e正式权限canonical已通过；总控核准同执行合同下fresh完整原verify一次。
包装仅监测自己启动的子进程，遇SCRIPT ERROR failfast；原flags/assert/测试枚举/180秒边界不变，
须在实际回执中注明包装。`3ec80941`与固定`6792202d63a5f3f812c08d0603c447740d2e624f`的651文件
原核验只有648 raw bytes相同，另3文件仅CRLF差异，并存在1个QA-only额外脚本；不宣称651原始字节全同。
这些EOL由各owner精确对齐Git blob，新fresh排除额外QA脚本，再核验固定身份。完整回归、最终源码冻结、
两包真实ZIP链及新限定OS观察仍未完成。文档恢复点`0445c61`不认证这些未完成项。
总控远端实核：`e945e8cb40ea977286d44082e8333485456b9d04`的CI `39066571426`及
`39066567602`均completed/SUCCESS，包含Python与完整Godot作业；此处未取得原日志计数，不写168项。
原679 CI `39066306203`的旧结构断言FAIL保留。拟包49c的CI `39067140525`/`39067137757`
仍in_progress；e945与49c的runtime相同、仅QA probe独立重启补充不同，不将e945绿说成49c实包通过，
也不以Linux CI绿覆盖Windows rule当前反馈P0。
中间557的后续CI发现另一旧结构断言：`test_completion_service_clarity:76`两语各失败一次；
raw已保留。当前679完整原verify继续运行，不因预期这两项失败中断或篡改原结果。
下一test-only焦点复跑及最新CI应与runtime679字节相同的完整运行分别记录，再冻结最终SOURCE；
不把后修断言的通过倒填成679原始全量通过。
原full随后出现另一P0：规则练习反馈关闭失败。现场完整pending的两JSON文件名为case/context，
493/3571B、路径长度256/259字符；未移动、修复或晋升。普通Moments因tester开关直接退出，
context为root且headless，不经过新非root销毁/等待capture分支。创建为空可令原保存拒绝关闭，
但该次current/last_error尚未同步记录，不能仅凭事后pending认定具体stage或同一原因。
保留391项原断言，最小下一步仅canonical原suite按每轮身份记录F8后/首Esc后的current、busy、
status、store.last_error与目录状态。完整full仍继续，不因已发现失败改写原结果或跳过后续项。
完整full现已自然结束，回执确证168阶段全部执行、166通过/2失败、无SCRIPT ERROR提前中止。
该fresh的651文件逐字节匹配`6792202`，无QA额外tests；与早期3ec的648/651分开。
拟实包源码为`49c20ead795e1be9de693b0509307ff3fa172fe6`，相对runtime679仅test_clarity与
QA probe的同embedded profile独立重启补充；Visual已源审strict外监督前后gate无阻断，实际包未跑。
Narrative下一步fresh focused clarity/Service，并在原rule长目录形状作失败即时日志、短workspace
`.qa/Rule-uuid`作一次同canonical脚本/namespace/flags对照；实际环境/长度须由回执确认。
P0未关闭，不能把当前166/168改写为168/168或提前freeze包。
短目录真实GUI也已失败：pending目录210字符、context子路径223字符，含case453B/context3579B及
115450B有效截图；无notes.jsonl。pending截图是反馈打开前的正常AND手册，随后
`d4664dcc/artifacts/en-half_adder-active.png`显示反馈仍在，明确提示无可写现场。
因此本次关闭拒绝已关联空current，而非仅输入消费假设；发布失败的准确阶段仍须同步诊断。
不以缩短目录、正式权限或前两次headless通过声称所有IO已解决，也不据此修改Store/输入/assert。

Visual另发现System EN旧工具栏窄窗横溢及Overlap缩放后的关闭按钮不fit；总控已授权Narrative
在自有Host作最小布局修复，不因旧基线也有问题而忽略1280要求。默认clip与located检查分别记录。
下列清单记录当时待证边界；其后的固定来源结果以页首Gate及checks为准：

- 三套新定向及上述受影响11套旧/新保护已有固定855来源通过；完整全仓回归、
  其余未涵盖的UI/规则/模型保护仍待后续结果，不将定向范围扩大为全量。
- 三尺寸两语的九Host实际内容、marker边界、普通/测试渠道及Home/map实际打开/复用/关闭。
- Journal原手册及真实ThemeReflection/F8两渠道栈已有f584固定copy GUI通过；其他未覆盖时序
  （包括保存拒绝救援故障注入）仍未验证。headless的窗口栈NOT_RUN与新GUI结果分别保留。
- 新固定源码提交、完整回归、CI、新普通/测试者导出包的身份/开关/目录、真实解压启动、
  普通门禁、真实C→P→G/作品跨进程保护和最后ZIP反馈子链。
- 本轮限定原生观察、陌生玩家理解、异机/Mac、人设/CG/声线/剧情变体及团队正式素材审阅。

原生预备阶段曾为**NOT_RUN**，以下保留工具边界；当前双渠道限定结果见页首。Visual的官方`mcp__node_repl__js`实例初始化前遇到
`failed to write kernel assets: 系统找不到指定的路径。 (os error 3)`；一次`js_reset`成功后仅重试一次，
同错，`@oai/sky`导入尚未执行。没有启动或控制游戏、安装依赖、修改外部runtime或以Cua绕行。
这是Visual该实例的工具初始化错误，不是自动审批拒绝，也不是新包运行失败。
随后Root在自己的官方node_repl实例按skill标准导入Sky成功，`skyReady=true`；
尚未调用窗口/输入API、启动游戏或安装/绕行。Visual实例的失败不泛化为主线程工具不可用，
该预备记录不冒称OS通过；后续Root实际normal/tester限定路线分别记录在页首。
待命路线保存在本地`.godot/full-journey-native-preparation.md`。旧7c限定原生PASS保留原身份，
不能覆盖本轮原生缺口；真实renderer/控制器结果也不等于OS或陌生玩家验收。

重跑由总控授令牌后执行，不在原profile运行。headless定向可用
`python -X utf8 scripts/verify-project.py --godot <Godot4.7.1> --suite test_journey_journal`
（其余suite重复`--suite`）。真实渲染在隔离copy中运行同一Journal脚本，不加`--headless`；
观察站渲染需`--observatory-capture --capture-size=1280x720 --candidate-journey --creation-journey`。
具体执行身份与结果以新回执为准，不以这段命令示例当作已执行证据。

固定包身份：普通batch`FullJourneyExperience20261018`、profile`FullJourney20261018`；
测试者batch`FullJourneyAccess20261018`、profile`OfflineTeammate-FullJourney20261018`。
两包SOURCE均为8334，旧7c/226 ZIP与原profile保留。双包实际目录/哈希见下表，
完整manifest/EXE/PCK/controller/validator SHA和来源链见checks，不混用后续QA或文档commit。

## 新包限定原生观察

Root以Sky真实OS鼠标/键盘操作normal8334，使用全新独立QA数据目录和已核pristine包；
未调用游戏handler或signal。Home/Journal最初0/60；Reflection内普通F8可用，三个Esc逐层返回并恢复焦点；
3D东侧相机可切换且初始无成果。Start/跳过仍0/5，实际两次端口拖线、切输入1、Run得到1→0、
右键断线与拖动重连完成5/5；普通地图21入口且锁仍在，Journal1/60、核心1/40、一个实际方案，
观察站恰一个合法成果灯。正常AltF4后PID38852退出0，日志无ERROR。

Knowledge只读复核进程/pristine完整文件哈希和最终QA存档：main/bak一致、只完成tutorial，
原电路保存A_IN→NOT_1→LAMP两根线，其他域未授完成；这些磁盘事实不代替每一步OS观察。
原始操作/进程/截图来源及SHA见checks的`native_normal_8334`。截图只保存已观察Sky原图的provenance。
tester8334亦由Root实际OS操作：地图60/60可进但0成果，Journal0/60/核心0/40；Reflection内F8保存本地现场及截图，三个Esc逐层回map、不授完成。PID47384正常exit0，包文件未变；独立核本地case为空意见/rev0、captured PNG1040×768，context明确非root Reflection窗口、零完成且来源为current_memory_not_disk；没有savegame文件或pending，远程outbox未启用/空队列/无endpoint。详见checks的`native_tester_8334`。

已知答案agent不是新手，原生CPG、原生独立重启、中文长输入、
真实旧作品、Mac/异机与陌生玩家理解均未在此路线执行。CPG跨进程另有上文原包controller证据。

两张normal原生游戏帧由Visual逐张审图，Knowledge复核原字节/SHA相同；实际1707×1067 JPEG/JFIF。
原raw误名`.png`保留，交付副本使用真实`.jpg`后缀，未转码，不能称无损PNG。

| 原生观察帧 | 可见范围 |
| --- | --- |
| [os-tutorial-completed](images/source8334ab137beb-native-normal-os-tutorial-completed.jpg) | 真实教程5/5完成页、1→0与灯灭正确；不证明其余关卡完成。 |
| [os-earned-observatory](images/source8334ab137beb-native-normal-os-earned-observatory.jpg) | 真实1/60、唯一tutorial成果灯与非信号/能耗警示；不证明真人理解。 |

测试者原生帧：[Reflection上的离线反馈](images/source8334ab137beb-native-tester-os-modal-offline-feedback.jpg)，
显示Journal0/60及本地保存成功。Visual独立审图、Knowledge核原字节JPEG/SHA一致，
158437字节、SHA`49017dd5802724671683f81cf5d4eff927d72536a174d5ddd284ce89ebca98a4`；
不把一帧截图扩展为整条OS路线或新人理解，实际操作以Root收据为准。

## 可核对的实包变化帧

四张均取自最终normal8334/5acc实际运行，逻辑1600×900、PNG1280×720、中文；
Visual逐张审图，Knowledge复核目标与raw逐字节/SHA相同。没有裁剪、拼图、修图、重渲染或旧图改名。
这是rendered controller证据，未获得同状态/同构图的旧包before，不凑前后对照。

| 实际帧 | 可见证据与限制 |
| --- | --- |
| [first-result](images/source8334ab137beb-work5acc08e7a872-first-result.png) | 真实教程五操作后的完成页、NOT1→0、能力承接及可选反馈；不证明其他任务完成。 |
| [context](images/source8334ab137beb-work5acc08e7a872-context.png) | 原compact语境按钮与工作台同屏；不证明长展开正文全文同屏。 |
| [journal](images/source8334ab137beb-work5acc08e7a872-journal.png) | 真实目录1/60，tutorial合法完成、half-adder未完成，虚构/事后回看及来源。 |
| [observatory](images/source8334ab137beb-work5acc08e7a872-observatory.png) | 真实3D、tutorial成果灯、未完成节点及原树/工作台入口；灯非信号或能耗。 |

逐图SHA/字节数和精确来源见[checks](checks.json)的`curated_images_8334`。

## 次日入口与真人审阅

先查看本页最新Gate和[覆盖账本](../../development/full-journey-coverage.md)，再选择新普通包或测试者包。
解压对应ZIP后运行`Windows/Von-Neumann-Bottleneck.exe`，保留同包README指定的数据目录。
普通包按正常门禁推进；测试者包开放入口但不授完成，F8为离线现场。测试者包内
`feedback-tools/offline-playtests.py`已经实际走完最终ZIP单独导入，完整工具SHA记录在checks。
这两份包均关闭public release与上传默认，未配置endpoint。

| 用途 | 固定ZIP与manifest | ZIP SHA-256 | profile |
| --- | --- | --- | --- |
| 普通成长 | [ZIP](../../../build/playtest-FullJourneyExperience20261018-8334ab137beb/Von-Neumann-Bottleneck-Windows-playtest-FullJourneyExperience20261018-8334ab137beb.zip) · [manifest](../../../build/playtest-FullJourneyExperience20261018-8334ab137beb/manifest.json) | `5e1ea0e4986a1bc4a0098358fafae1f986f7bbb05bf3431800b6e3d7131c28df` | `FullJourney20261018` |
| 全入口测试者 | [ZIP](../../../build/playtest-FullJourneyAccess20261018-8334ab137beb/Von-Neumann-Bottleneck-Windows-playtest-FullJourneyAccess20261018-8334ab137beb.zip) · [manifest](../../../build/playtest-FullJourneyAccess20261018-8334ab137beb/manifest.json) | `1c99f727a04134d4db2c6fb4742ba593e6484832d8b78efe1e7f1854469dc4f2` | `OfflineTeammate-FullJourney20261018` |

镜头进入路径（已验证导出包中的操作路线；当前不是已交付成片或真人验收）：

1. Home→开始/跳过壹→NOT五项操作→输入1/输出0→真实完成回应；突出灯灭也可能正确。
2. 测试者地图→System `cpu_speed`→Now/Verify→正式基线→只换CPU再运行→对照证据；明确测试访问不算成果。
3. Home→观察站→序章/创作区域、三个视角→比较真实已完成灯与未完成入口→定位原树；不录fixture冒充玩家进度。
4. 地图C1→学习/真实复原→P1提交后揭晓→当前模型准备成立后G1生成/Keep→按原配方回看作品。
5. 成长档案→主题回顾→F8→普通意见或测试者现场→逐层Esc回原页；独立重启已有控制器证据，原生输入镜头须另录。

次日最多五个真人问题，记录观察而非先教答案：

1. 首页和首个Now/Verify是否让你知道下一步可做什么、怎样判断结果？
2. 改过草稿后，你能分清当前结果、已有成绩和完成回顾各指哪份方案吗？
3. 观察站灯、空心入口与地址预测临时标记，是否让你误以为“可进就是已完成”？
4. 卡住时能否找到合适的规则/Hint，并从F8与弹窗逐层回到刚才的位置？
5. C→P→G与作品来路、虚构文明片段是否清楚，有没有把它误读为真实历史、意识或通用智能结论？

作品/素材接缝：保留新包README指定的完整数据目录、旧10月17日及7c的原profile和作品；
回看使用既有快照/配方，不用当前草稿覆盖旧作品。观察站几何可在`journey_observatory.gd::_build_geometry`
替换，动态编号/文字/✓与完成权威须保留；台词在任务catalog，候选片段在Journal，
均不写进模拟结果。CG、人物/声线、剧情变体、浅色全局方案及正式PPT/视频继续按账本逐项处理，
素材需来源/授权/AI辅助说明；本页不擅自替队友定稿或虚构已完成的成片。
