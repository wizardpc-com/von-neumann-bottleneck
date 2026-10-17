# 全旅程续轮证据 · 2026-10-18

本轮实现60项任务语境、只读成长档案和真实3D观察站，保留原工作台、原完成权威及原导航。
这是持续开发中的证据入口，**active计划及完整goal均未关闭**。
需求与开放项见[覆盖账本](../../development/full-journey-coverage.md)，
执行与所有权见[active计划](../../exec-plans/active/full-journey-experience-20261018.md)。

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
这仍不是最终包SOURCE冻结；最新`3ec80941`隔离copy的模态栈已有真实GUI通过，原canonical离线反馈发布失败仍是P0，详见下方最新记录。
基线CI运行`39061439011`已由总控核读为completed/SUCCESS；它不证明本轮新增代码。
[旧7c固定包及限定原生验收](../20261018-night-experience/README.md)保留原身份，
本轮尚无新固定包、原生或陌生玩家验收结论。未执行公网发布、账号/服务器修改或旧存档迁移。

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

56fe晚于上述旧失败，**但早于**marker主题实际最小尺寸修正、system拓扑/语言刷新回归和
Journal→ThemeReflection→F8新栈。其成功不能认证这些后续差异。
视觉实现/素材替换接缝及失败细节见[观察站说明](../../development/full-journey-visual.md)。

## 当前等待的最终整合验证

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

Visual另发现System EN旧工具栏窄窗横溢及Overlap缩放后的关闭按钮不fit；总控已授权Narrative
在自有Host作最小布局修复，不因旧基线也有问题而忽略1280要求。默认clip与located检查分别记录。
下列项不得提前标PASS：

- 三套新定向及上述受影响11套旧/新保护已有固定855来源通过；完整全仓回归、
  其余未涵盖的UI/规则/模型保护仍待后续结果，不将定向范围扩大为全量。
- 三尺寸两语的九Host实际内容、marker边界、普通/测试渠道及Home/map实际打开/复用/关闭。
- Journal原手册及真实ThemeReflection/F8两渠道栈已有f584固定copy GUI通过；其他未覆盖时序
  （包括保存拒绝救援故障注入）仍未验证。headless的窗口栈NOT_RUN与新GUI结果分别保留。
- 新固定源码提交、完整回归、CI、新普通/测试者导出包的身份/开关/目录、真实解压启动、
  普通门禁、真实C→P→G/作品跨进程保护和最后ZIP反馈子链。
- 本轮限定原生观察、陌生玩家理解、异机/Mac、人设/CG/声线/剧情变体及团队正式素材审阅。

本轮原生验收为**NOT_RUN**，不是产品测试失败。Visual的官方`mcp__node_repl__js`实例初始化前遇到
`failed to write kernel assets: 系统找不到指定的路径。 (os error 3)`；一次`js_reset`成功后仅重试一次，
同错，`@oai/sky`导入尚未执行。没有启动或控制游戏、安装依赖、修改外部runtime或以Cua绕行。
这是工具初始化错误，不是自动审批拒绝，也不是新包运行失败。
随后Root在自己的官方node_repl实例按skill标准导入Sky成功，`skyReady=true`；
尚未调用窗口/输入API、启动游戏或安装/绕行。Visual实例的失败不泛化为主线程工具不可用，
新包限定OS验收仍待固定身份及唯一令牌释放后实际执行。
待命路线保存在本地`.godot/full-journey-native-preparation.md`。旧7c限定原生PASS保留原身份，
不能覆盖本轮原生缺口；真实renderer/控制器结果也不等于OS或陌生玩家验收。

重跑由总控授令牌后执行，不在原profile运行。headless定向可用
`python -X utf8 scripts/verify-project.py --godot <Godot4.7.1> --suite test_journey_journal`
（其余suite重复`--suite`）。真实渲染在隔离copy中运行同一Journal脚本，不加`--headless`；
观察站渲染需`--observatory-capture --capture-size=1280x720 --candidate-journey --creation-journey`。
具体执行身份与结果以新回执为准，不以这段命令示例当作已执行证据。

待构建身份：普通batch`FullJourneyExperience20261018`、profile`FullJourney20261018`；
测试者batch`FullJourneyAccess20261018`、profile`OfflineTeammate-FullJourney20261018`。
新manifest/ZIP/EXE/PCK SHA须在实际构建后填写；旧7c包及原profile全部保留。

## 次日入口与真人审阅

先查看本页最新Gate和[覆盖账本](../../development/full-journey-coverage.md)，再选择新普通包或测试者包。
以下新包字段在实际manifest出具前保持待填，不能把旧7c包更名当作本轮包：

| 用途 | 固定ZIP与manifest | SHA-256 | profile |
| --- | --- | --- | --- |
| 普通成长 | 待实际构建路径 | 待manifest | `FullJourney20261018` |
| 全入口测试者 | 待实际构建路径 | 待manifest | `OfflineTeammate-FullJourney20261018` |

镜头进入路径（新包验证后录制；当前不是已交付成片或真人验收）：

1. Home→开始/跳过壹→NOT五项操作→输入1/输出0→真实完成回应；突出灯灭也可能正确。
2. 测试者地图→System `cpu_speed`→Now/Verify→正式基线→只换CPU再运行→对照证据；明确测试访问不算成果。
3. Home→观察站→序章/创作区域、三个视角→比较真实已完成灯与未完成入口→定位原树；不录fixture冒充玩家进度。
4. 地图C1→学习/真实复原→P1提交后揭晓→当前模型准备成立后G1生成/Keep→按原配方回看作品。
5. 成长档案→主题回顾→F8→普通意见或测试者现场→逐层Esc回原页；保存/退出/重启素材只在新包实际验证后标注。

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
