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
