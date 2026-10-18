# 逐任务学习盘点与效率回顾焦点核验 · 2026-10-18

状态：DELIVERED_WITH_OPEN_OBSERVATIONS；完整goal ACTIVE，本计划保留在active队列。
当前产品bb5c817、外QA检查点ea6be8d，双Windows包及限定验收交付，旧失败原因仍开放。
基线为已推送的 `e410cbe6bb1990f52e3ef0ebcbd7b9a33faebbce`；
既有可运行产品固定d14be32，两个CreationLinks ZIP及其验收保持原身份。
本轮不以既有交付关闭完整目标，也不因为开放美术或真人事项新增无依据的功能。

## 已确认缺口与待实测问题

1. 手册§5B要求逐关记录玩家决定、已有知识、成功依据和困难类型。现有
   `night-journey-review.md`只有19个分组行覆盖60个ID，不能证明逐任务四项盘点完成。
   本轮补齐实际60项语义记录与源码锚点，不改变任务、判据或难度。
2. 效率回顾的延迟展开缺少窗口归属守卫，已有焦点判断仅看native窗口。
   既有CPG实测证实嵌入模态子窗可与native root同时报告持焦；这只是复现前提，
   尚不能据此断言效率回顾已经发生同类故障。先加真实模态负例，在固定源运行，
   实际失败后才核准最小修复。FirstLight不因表面相似而自动纳入改动。

## 所有权与权限

- Knowledge：只编辑 `docs/development/night-journey-review.md` 的逐任务审阅；
  独立审查Narrative的测试和以后经核准的生产修复，不编辑这些源文件。
- Narrative：先只编辑 `tests/test_efficiency_fragment.gd`，保留全部原保护和截图；
  未经Root核准实际失败与修复范围，不修改生产代码。
- Visual：独立审查逐任务语义记录与后续实际图面，不修改上述文件。
- Root：本计划、必要的当前状态/索引/覆盖说明、共享接口决策与唯一Git写入。
  所有Godot/renderer/导出运行分别授予唯一令牌；其他线程只读。

保留来源未明的测试文件状态、原仓库改动、全部旧包/档案/失败证据。
用户允许新提交和大改动推送独立分支；不增加合并、Release、服务器、账号、费用或
正式人物/剧情决定的权限。PR15正文已获用户明确授权并完成更新与回读核对，仍为OPEN草稿；
这次授权不包含合并或Release。
官方原生工具此前初始化失败；未有真实修复或环境变化时不再尝试，也不绕过官方接口。

## 验证顺序

1. 完成60行语义盘点，逐项对照真实任务目录和模型合同，由非作者独立审查。
   这份材料只证明源码语义覆盖，不代表60项实际解题或真人理解。
2. 冻结QA差异：真实AcceptDialog/Other焦点、嵌入子窗名单、native窗口焦点日志，
   同帧延迟展开/滚动和Esc保护，原Session/作品/成绩/租约保护不减。
   不手设窗口焦点、不增加sleep/retry、不移除旧断言、不以headless认证GUI。
3. 新检查点记录固定输入，先原import/userdir及效率suite编译回归，再独占执行实际renderer。
   保持原175个canonical测试、原180秒/ERROR守卫与隔离APPDATA/LOCALAPPDATA/TEMP/TMP。
   结果不管成功或失败均保存；原失败不改写，不自动重跑。
4. 若真实基线失败，按实际窗口/滚动证据核准最小呈现修复及独审，再保存新检查点复验。
   若未复现或前提不足，明确未证实，不把候选猜测变成产品改动。
5. 对实际生产改动运行受影响检查、必要的完整回归和新固定包验收。模拟、阈值、合法解、
   存档格式、支持、作品和原配方不得改变；无生产改动时不重复完整构建以冒充新成果。

## 交付与开放项

沿用现有交接入口，提供逐任务盘点、固定源码/测试/实际结果、可恢复检查点和下一步。
原生输入、Mac、陌生玩家、正式素材与视频成片仍按实际证据分别标记；本轮不声称补齐它们。

## 基线与QA检查点

新分支为 `codex/narrative-modal-focus-20261018`，从e410原HEAD创建；Knowledge的60行文档
WIP与Narrative新测试在切换前后SHA精确保持。测试新增44行且不删除原行；独审确认移除新函数
及唯一调用可逐字节重建F5旧测试。生产Efficiency和System Host尚未改动。
新fixed helper只更换输出目录名，单效率renderer只把明确门禁改为原import/userdir/效率三阶段，
其余固定输入、175 canonical、180秒严格判定、四环境、全产物与finally还原均保留。

切分支后观察到先前缺失的UID恢复为原e489da42字节，同时live新缺失
`tests/test_completion_route.gd`；Root未执行恢复/删除，这些变化归属尚未确认。
只记录并保留当前状态，不把任何未知删除暂存入本轮。固定Git归档仍含全部原测试及UID，
不会按live缺失降低枚举。观察收据位于`.godot/f6-baseline-workspace-observation.json`。

## 实际基线与核准修复

固定867ec81的原三阶段3/3通过；真实renderer为239项检查、4个断言错误，
PID50104自然exit1，无强制终止。两语均实际观察到嵌入模态Other持焦、root同时持焦，
unfinished blend从0推进到1。直接Host Esc的组合断言失败，但缺少独立post-Esc body值；
后续authority保护通过。Scroll原值未变，不能称本次复现滚动故障。
原失败收据与完整界限见`docs/verification/20261018-narrative-modal-focus/`，不覆盖旧F5结果。

Root据实测与Knowledge独审核准Narrative仅修改Efficiency组件、SystemLab的fragment Esc分支
及原测试：纯窗口归属判断阻止模态持焦期间渐变、延迟展示与Host关闭；不得使Esc落入map/Home。
追加真实滚动正控制、同起点模态负控制与分别记录post-Esc值，原F8和存档保护保留。
当时安排Knowledge独审后再提交固定源、运行新门禁；修后结果见下节。
Visual只读复核原26张基线图，静态图不证明动画暂停、OS焦点或Esc成功。

60任务语义表已于20c9515提交推送并由Visual独审；展示索引的d14双包和五个实际镜头已由
Knowledge独审，视频仍未录制。两项文档完成不扩张867运行来源或实际玩家验收范围。

## 固定修复门禁

三文件修复已于bb5c817提交推送，经Knowledge独审。原三阶段3/3自然通过；同源真实
renderer245项检查、零ERROR/WARNING/SCRIPTERROR，PID21700自然exit0。
正常展开正控制实际scroll由0到中文42/英文110，source/step/metric均在原clip内；
同起点模态负例在真实Other持焦/root亦持焦时scroll0、blend0、step1保持。
直接Host Esc分别记录body可见、authority精确、map未打开，六条原F8 accepted边界通过。
这只认证固定System controller/嵌入子窗，不是OS或导出模态输入。
26张原图独审另行记录，原239/4失败不改写。

原完整Windows回归176/176自然通过：176有序自有调用、169不同PID；零ERROR/SCRIPTERROR，
原六条anchor WARNING单列。远端CI39097738231已由Root只读核为SUCCESS。
新双包已由原builder/identity独审通过。保留d14双包作为实际可运行恢复交付。

## 导出首链失败与诊断边界

新普通包的原40b控制器实际216/219：F8视口/焦点复合断言、第二次Esc和Journey返回
复合断言失败，PID21788自然exit1，无SCRIPTERROR或监管终止；当时strict未启动，测试者链未跑。
失败summary为`.godot/f6-normal-parent-strict-bb5c817-summary.json`（a9466dcc…），原raw、20根帧
与存档保护保留；反馈命名帧实际未见面板，不用文件名替代图面或焦点值。

Root据缺少的分项值只核准外QA控制器添加同步LOG-ONLY字段：Window/嵌入子窗、panel/viewport/
owner、反馈flag、fragment和scene/离开guard。原219断言、动作、Input、await、超时与全部
生产代码不改；独审后新检查点仅允许一次诊断运行，旧失败不覆盖，不以反复重跑取得绿色。

该次3ad/c73诊断实测保留为第二次失败：原180秒守卫定向终止自有PID25692，非自然退出。
六个CPG快照本次均正确，但随后未生成embedded.json或成功receipt；17根帧含saved-work，
不能依截图名推断唯一卡点。总219检查数不可得，strict未启动；Session/作品与租约已读值
只保持其局部范围，不补造本次缺失的完整最终authority快照。summary为333b19c6…。

Knowledge只读核源后界定等待范围为creative_work_review的Play/F8/Esc及原settle
（8process_frame再frame_post_draw），不是独立重启。Root只核准这些原等待点前后追加同步
小日志，包含真实时间、帧数、窗口状态与安全caller；不加Timer、await、超时、focus请求、
force_draw、状态或跳过。作者冻结、独审和新提交后才允许下一次有明确新观测点的运行。

ea6/f567同步遥测的一次新运行d196已获独审PASS_SCOPE：父EXE26360自然exit0、219项全真，
独立严格重开EXE53548自然exit0、48项通过，Python包装进程另列。386条等待日志与六个CPG
快照逐原日志匹配，140次process及140次draw等待均返回，31.377秒记录最终JSON写入。
21实际图（19根/Window＋2独立纹理）获独审，作品/Session/五支持和主备保护按原范围通过。
原a946三错与333b超时原因仍UNKNOWN，不把同步日志当成产品修复或回填旧缺值。
当前测试者父229、原collector142 capture/19 reopen及strict48项全部实际通过，
60入口、真实CPG/作品重启、最终单ZIP独立导入去重获数据独审；45份图片副本/31独立SHA
完成逐图独审。原outer在父wrapper exit0后读取混合编码stdout失败，exit1保留；Root只准
单独继续尚未启动的原strict，实际自然exit0，没有重跑父或child，也没有生产改动。

当前双包、manifests、精确SHA、原失败与最多五项次日问题集中在
[本轮证据](../../verification/20261018-narrative-modal-focus/README.md)；
[次日交接](../../development/night-handoff-20261018.md)以普通包为默认入口，
[展示脚本](../../distribution/showcase-shots.md)绑定实际新包图，旧d14与六张源码代表帧保原身份。
官方原生工具阻断、Mac、新人理解、正式素材和未录制视频仍按实际权限与证据开放。
