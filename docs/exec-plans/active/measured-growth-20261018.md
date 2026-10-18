# 看懂未达标，也看见真实改进 · 2026-10-18

状态：ACTIVE。基线`2e488c387ab1a0b95f37036ca025878fdeaab085`，新分支
`codex/measured-growth-20261018`；Root核远端同SHA、工作树干净。上一轮产品SOURCEc109
完整172/172、两实包与限定原生路线已通过；外QA0bc3两CI已成功，交接2e的两CI启动时仍pending。
这些结果是可恢复基线，不能认证本轮新代码。上一目标回合分类为PROGRESS：完成了实现、验证与已推送交付；
本轮继续完整goal，而非把既有交付重述成全目标完成。

## 要解决的玩家问题

1. 布局结果虽给数值，却仍让玩家自己跨窗拼出输出、周期、流量或空间哪一条未满足。
2. 并行工作台虽已有错误说明与行号，却默认显示case0，缺少将当前失败与原代码/事件串联的查看入口。
3. 系统工作台已有真实受控对照图，但完成回应仍是通用文字；缺少能回看原记录的可选叙事承接。
4. 可选3D观察站已有真实导航，所有章节却仍是同样灯台，不能从装置直接辨认能力差异。

## 当前范围与所有权

- Knowledge：`src/layout_chapter/layout_chapter.gd`、`src/overlap_chapter/overlap_chapter.gd`、
  新`tests/test_target_evidence_guidance.gd`。在原结果/trace内说明真实未达标项与差额，定位原证据。
  Overlap按原合同选择首个未达标case；草稿变化后旧行号不得定位成当前错误。Layout提示仅说明公开
  合同、准备账本或空间申请，不自动改布局，也不把bonus混为主目标。
- Narrative：`src/system_lab/system_lab.gd`、新`src/ui/efficiency_fragment.gd`、
  新`tests/test_efficiency_fragment.gd`。仅cpu_speed的原受控pair，复用原history_chart，不重复造图。
  EfficiencyFragment为默认折叠的原生VBox，接脱离receipt引用的深副本；支持set_pair/clear_pair/collapse、
  optional Texture2D与缺图文字回退。2–3步按需观察、真实指标/来源与候选壹回应，允许持平或变慢。
- Visual：`src/ui/journey_observatory.gd`、新`tests/test_observatory_apparatus.gd`。
  先为硬件/系统两区实现可区分的程序几何成果装置与选中近看/还原；沿用原任务行、合法完成状态、
  任务列表/定位/进入和三固定视角，不另造可操控人物或自由相机系统。
- Root：本计划、active索引、集成证据与当前状态、唯一Git写入者。任何上述外文件需要先协调；
  一个文件仅一位作者。引擎/renderer/native令牌单独发放，现在全部idle。

## 窄范围事实语义修正

Root全仓核事件消费者后，核准Layout Host两处新事件的“输出正确但合同未满足”类别改用System/Overlap已存在的
`correct_but_target_unmet`，避免把流量超限记为必然超时。case/aggregate字段与所有指标、passed/target_met不变，
旧历史不重写，不改report/server/保存schema；真实流量超限测试核该类别。

## 不变量与非目标

模拟器、Catalog/合同阈值、Session、存档格式、部件来源及已有合法解不变。UI只读取实际结果，
定位不写代码/布局/连线/进度；旧记录仍属于原方案。普通、测试参考、临时、不可核验与合法完成分别显示。
效率片段是学习程序内候选呈现，不伪造旧事件时间线、文明史、现实节能、百分比学习收益或奖励。
未完成/单次正确运行/失配pair不能伪造比较成果；真实负向差值诚实表达。素材缺失不阻塞操作。
3D几何标明成果隐喻，不作为电路信号或物理测量；现有高效任务树保留。F8、反馈拒存救援、低动效、
Esc层级与精确焦点返回沿原机制。测试仅隔离QA档案，旧安装包、作品、原repo test_ui删除及旧失败均保留。
本轮不决定最终人物/声线/结局，不触及公网/账户/服务器/付费，不合并PR11–14或发布Release。

## 实施、交叉审查与验证

1. 本计划先提交为可恢复检查点，再正式授权三位作者并行编辑不重叠文件。作者交源码差异、合同与冻结SHA。
2. 交叉独审：Knowledge审Narrative；Narrative审Visual；Visual审Knowledge。阻断回作者修正；作者不自评独审。
   Root核共享接口/实际文件/字节与可见行为，禁止靠调整阈值或删断言刷绿。
3. 固定提交后由唯一执行者用原隔离verifier跑新suite及受影响System/Overlap/Layout/Observatory/反馈回归。
   实际模型产生正反例，保留替代合法路线；头less不替代renderer。
4. renderer以两语、1280×720/1920×1080/16:10覆盖展开/折叠、来源/差值、失败定位、陈旧结果、3D近看/还原、
   缺图/低动效/重看、F8/逐层Esc/焦点，以及game/workbench/works/lease/navigation保护。控制器与OS证据分列。
5. 共用/跨Host新变化整合后完整Windows回归；稳定后再产一对固定新普通/测试者实包，原ZIP/manifest/嵌入
   profile、真实首段/代表中期/创作保存重启与最终离线ZIP链分别验收。新包不能借c109结果代证。
6. 每轮实际变化commit；大改动push本新分支并保留草稿PR。集中追加一份证据/次日入口，不复制版本源码目录。
   SOURCE/外QA/退出前后文件边界精确分列，失败保留原身份。余量在运行前检查，避免无谓重复物化文档。

## 后续仍须实现或审阅

下一候选是C1→P1→G3的实际模型/揭晓/保存短片段；当前CPG工作台已有账本、符号演出与来源，不重造已有功能。
展示架构图与当前版本实机镜头材料仍可交本地可编辑产物，不替PPT/视频负责人定稿。
正式人物、CG、声线、结局与更广平台/新人/真人旧作品仍需相应真实材料与审阅；这些开放项不阻止当前可逆实现。
完整goal保持active，本计划阶段完成不会被写成所有规划和想法均已完成。

## 首次实现与静态交叉审查

三组生产UI与新测试已冻结，作者均未运行引擎。Knowledge→Narrative、Narrative→Visual、Visual→Knowledge
逐文件独审已闭合，无剩余确定静态阻断。效率片段的当前草稿差异改为明确局部呈现状态，切观察步骤后仍保留；
renderer busy测试在真实frame_pre_draw观测F8轮询已开始、截图未结束的边界，不直接设置flag或删除断言。
TargetGuidance建立真实C/P/G保存作品再关闭writer，定位与反馈保护其实际字节和空lease；不把缺档保护算已有作品。
所有新数值、布局、窗口、模型夹具和操作断言尚未运行；首个固定源码门禁仍须给出真实PASS/FAIL。

## 固定1d887c5首次运行

原隔离验证器实际完成20阶段：18通过，2失败；全部owned进程自然退出，没有脚本错误、超时或重试。
观察站恢复全景后几何/投影矩形的复合断言失败一次；Overlap编辑后旧问题定位禁用的断言在两语各失败一次。
原始日志、失败提交和哈希保留在`.godot/verification/20261018T000421Z-6f7d6860`及
`.godot/f4-focused-1d887c5-summary.json`，不得以作者静态审查覆盖失败。
效率片段54项已在headless通过；实际renderer、完整回归和本轮新包均未执行。
作者分别定位与最小修复，交叉审查后形成新检查点，方可重新进入固定源码门禁。

## 固定040c198诊断结果

独审后提交的真实CodeEdit编辑测试及失败同帧诊断，经原验证器完成4阶段：3通过，观察站1项精确矩形比较仍失败。
两语CodeEdit各发出一次实际text_changed，trace_stale及禁用状态为真，TargetGuidance108项通过，两个生产Host未改。
观察站实际差异仅为zh_CN/1440×900/硬件alarm标记宽度63→63.000030517578125像素；
矩形其余字段、相机及装置变换全部相同。原失败日志保留，不据此声称底层引擎机制已证明。
下一修正限定为该浮点矩形比较的精度契约；装置变换、投影位置、实际指针可达、裁剪与最小尺寸仍须验证。
原raw：`.godot/verification/20261018T001059Z-3cefbc75`；汇总`.godot/f4-diagnostic-040c198-summary.json`。
全部4进程自然退出；renderer、完整回归和新实包仍未执行。

## 本轮导出验收扩展

Knowledge独占三个外部QA文件：night-package-probe.gd、verify-night-package.py、verify-embedded-profile-reopen.py。
新普通/测试者profile为MeasuredGrowth20261018/OfflineTeammate-MeasuredGrowth20261018，保留旧Creative档案。
原128/138父链、47独立重开及测试者原随包收集器的60入口/真实CPG/最终反馈ZIP链分别保留。
新功能补充进程仅在原父链和严格重开成功后，复制其实际退出档案至独立QA根再执行，
原父收据、runtime及ZIP不重写；四环境目录隔离，源码/包/控制器/种子/前后保护分别绑定。
测试模式CPU受控对照与失败方案明确为QA，不称玩家自然成就；由Visual独审扩展，未授权运行。

观察站测试修正仅允许数值近似相等的Rect2，且新增floor左上/ceil右下像素包围盒精确相同条件；
装置变换继续精确相同，相机变换/size从近似加强为精确相同，可见标记额外核原最小点击靶。
没有移动取样基线、增加等待或改变生产投影。上述新条件的实际通过情况仍待新固定20阶段检查。

## 固定e3e475d定向门禁

原18套件加import/userdir共20阶段全部通过；效率54、观察站3292、TargetGuidance108实际通过，
全部20进程自然exit0，无ERROR、SCRIPT ERROR、timeout或终止。Root独立核全部原日志/owned退出/输入清单，
714文件精确复制、174canonical测试无extra；full5759身份中5045docs仅未物化，不称整树当前全复制。
实际执行来源为提交e3，工作区三个外QA改动未进入该次固定输入。raw与哈希摘要：
`.godot/verification/20261018T001457Z-693891e7/results.json`，SHA
`a290f55d06017713172b4235b1635ad7a24a5d264e64bad6ef5e168a21b29586`。
Headless仍不覆盖实际F8窗口/渲染。三新suite真实renderer经独审helper获单一令牌，正在运行；
未授权自动重试、完整回归或构建。1d与040c失败身份保留。

## 固定e3真实渲染失败

首个效率suite实际174检查、16条ERROR、自然exit1，原helper停止后两suite；原24帧/日志保留在
`.godot/f4-rendered/43d52fb3d59a`。720p两语展开后的来源标识被滚动祖先裁剪；Root已实看中文原帧。
另四条角色反馈路径在首个frame_pre_draw未观察到真实F8 active/busy，后续步骤/渐变保护随之失败；
实际面板、焦点、逐层Esc及保护断言后续通过，不能覆盖前面的错误。
settings在finally恢复原字节、固定输入仍精确；TargetGuidance/观察站renderer均NOT_RUN。
Narrative负责最小布局及实际输入相位诊断，Knowledge独审；不得直接设busy/feedback标志或删除原断言刷绿。

效率修正与相位诊断已独审：生产展开后的ensure目标由整块body改为metric_label，以保留其前方来源/步骤阅读区；
完整文字、原比较图与16px正文保留，实际布局仍待运行。canonical测试只增加只读输入相位日志，
每信号最多4条并断开，原45个check调用、41个await及Input顺序不变，未修改F8断言或共享标志。
下一次只执行原import/userdir/效率3阶段，再以独立DIAGNOSTIC身份运行该canonical真实GUI一次，
保持180s/严格ERROR/四环境与固定来源；这次诊断不替代最终20阶段、三suite渲染、完整回归或实包。

## 固定fcad2真实相位诊断

原3阶段全部通过；单canonical GUI DIAGNOSTIC174检查仍14ERROR、自然exit1，24原帧保留，
`.godot/f4-efficiency-diagnostic-rendered/d1a9ccf31fc6`。新版两语720原帧经Visual独立view/hash，
完整候选性质、Test records来源、同程序/测试集/CPU身份、步骤与数值可读；深层内容仍走原滚动，未称全部同屏。
旧e3来源裁剪已由生产metric滚动目标窄修解决，不能把整次诊断改判为通过。

四条实际相位日志均显示：parse与原predraw同帧、请求尚未被处理，flag/busy均false，fade正常前进约0.066；
原测试此时自行改变step造成后续级联。下一process周期普通面板已开，测试者下一predraw真实busy/paused为真，
再下一帧面板打开。Root与Knowledge独立解析一致，依据installed4.7.1实际结果，不泛称其他引擎输入机制。
据此只核准一次process_frame后再pre_draw的测试同步，真实accepted/capture-busy时冻结fade/step/scroll，
新增unfinishedfade和原step核对，原忙碌、不可推进、返回焦点、暂停、逐层Esc及字节保护保留。
临时详细phase连接从最终test移除，诊断提交/raw仍保留；不改共享生产输入。最终20+三renderer/full/包仍待。

最终accepted-boundary测试35abfaa4已获Knowledge独审：请求前step/scroll→真实accepted必须不变，
此时fade仍未结束；tester必须正在busy且尚未显示面板，然后冻结后续观察值。
仅一次process_frame后pre_draw，无轮询/flush/睡眠或手设flag。诊断详细logger已移除，
原全栈、准确焦点和作品保护继续保留。下一新固定检查点执行原20阶段及完整三suite渲染，尚未运行。
