# Execution queue

第十一轮已完成[Region准备拒绝的一致证据](../completed/region-rejection-evidence-20261105.md)：
旧版负控、新版六套回归及完整Trace对照通过，独立差异审查确认只改变声明的拒绝字段。
32份正式订单Trace、20个目标判定及既有4份在线Trace精确一致；
无效准备参数不再保留已完成服务的成本与输出。Base错误优先级、旧成果、
存档与条件身份保持。[本轮证据](../../verification/20261105-region-rejection-evidence/README.md)。

第十轮已完成[电路失败后的状态续接](../completed/circuit-failure-recovery-20261105.md)：
独立冻结b765dd2并保留旧版负向证据；11个成功场景完整Trace一致，
修正输入后沿用最后有效输出恢复，原失败观察与整段失败判定仍保留。
13套相关检查末次通过，中英文GPU各158项通过；实际发现并修复旧回放
存储标签残留。完整记录见[第十轮证据](../../verification/20261105-circuit-failure-recovery/README.md)。

第九轮完成[内部计算审计与实测优化](../completed/computation-kernels-20261105.md)：
保留GDScript，Creation生成组合3.96倍、完整传输组合2.71倍实测提速；
35组有效场景完整结果／状态／成本／Trace一致。16套Creation、快照及两套
GPU通过。已复现电路失败后恢复缺陷，独立保留失败证据，不混入通过统计。
[完整证据和隔离试玩](../../verification/20261105-computation-kernels/README.md)。

下一增量实测Region重复冷客户端计算及其证据生成占比。其余Trace复制、scratch删除、
重复冷客户端与Off基线复用先实测占比，再选择局部GDScript优化。
原生试点仍需独立分支、完整差分、实际收益与Windows/macOS验证；未选定模块。

第八轮已完成[实测比较解释](../completed/explain-layout-comparisons-20261105.md)：
只读比较真实阶段、RAM、缓存和响应，导航两侧原事件；浏览保留待提交数字。
14套相关无头检查与五套GPU通过，首次结构点击异常与后续两次复跑分别记录。
[最终证据和隔离试玩](../../verification/20261105-layout-comparison-explanation/README.md)。

2026-11-05用户追加优先级：完成并验证／push当前增量后，全面深化各模拟器
的内部计算系统。先建立正确性、状态转移与性能实测，再优化重复计算、
数据结构、Trace生成和批量实验；继续研究有真实取舍的机制和负载。
GDScript参考实现优先保留。C++／Rust试点仅用于实测确认的高价值模块，
须在独立分支完成确定性、结果、成本、完整Trace及兼容对照和性能比较，
收益确认后再逐步迁移。不可用更换语言代替瓶颈定位，旧成果与公平规则保持。
该审计现已在第九轮展开，后续按已确认问题和实测收益推进；联网重算暂列后续。

第七轮已完成[结构化工作负载与历史升级](../completed/structural-layout-workloads-20261105.md)：
新增两次温度、温度后告警两种独立条件，真实周期／流量取舍、按字段／记录
复制布局对照、当前条件入门挑战，以及严格v1只读载入和独立v2保存。
21套相关无头检查、四套GPU界面、真正的新旧运行时竞争／恢复／回退通过；
42张原图已独立核对。本轮原生因锁屏未运行，导出／跨平台仍未验收。
[验证与试玩入口](../../verification/20261105-structural-layout-workloads/README.md)。
原四条件、60项正式内容与既有结果保持；442候选的有限前沿呈现真实选择，
不构成长期趣味性或全局最优结论。

第七轮结束时的历史后续安排是完整探索循环的可理解性和跨条件复玩：
当前计算审计优先级以上方2026-11-05用户指令为准；后续仍需在原生环境验证目标、
方案保留／恢复、有效比较及升级提示，再依据真实试玩观察确定下一项机制。
在线排行仍需服务端固定版本重算与明确信任边界。不要用增加任务数量或
纯数值随机化替代策略深度；正式采用仍须独立评估旅程、教程和历史兼容。

以下为此前已完成增量与当时的下一步，后续结构工作以第七轮结果为准。

第六轮已完成[可复算的调度挑战](../completed/layout-replay-challenges-20261104.md)：
现有四种条件、固定目标限制、独立目标侧文件和数值编辑后直接运行。
16套相关无头检查、三套GPU界面和实际跨进程恢复通过；后续原生中文路径
已观察接纳、修改、应战分享和保存退出。原生验收限于该明确路径。
[验证与试玩入口](../../verification/20261104-layout-replay-challenges/README.md)。
新增1475候选／48次重放和1140次复制布局探测均已完成；两次串行扫描有真实
周期／流量取舍，新增物理布局样本未出现新的优势指标组合。
结构化工作负载暂留后续独立身份与兼容设计，不替换既有任务或笔记。

第五轮已完成[方案笔记与限制条件比较](../completed/layout-notebook-20261104.md)：
可命名保留实测配方、显式保存工作区、同配置重开复算，并按首答与复制空间
限制比较真实总周期或RAM流量。整档保护、失败重试、并发拒绝以及停止写者
恢复后的实际新内容写入均有隔离证据。正式模型和旧成果未改。
[验证与试玩入口](../../verification/20261104-layout-notebook/README.md)。

下一优先级是实际探索体验与结构化工作负载。新增有限探测说明响应上限
确实改变可选策略，而16组纯数值变化不改变性能；不要用数字随机化冒充
新挑战。先检验玩家能否读懂取舍、有效保留和继续改进，再评估有意义的
新条件及服务端固定版本重算。实验配方分享已在第六轮交付，正式采用仍须
兼容和回退分析。
第五轮原生输入因锁屏未执行，不继承第四轮的有限原生结论。

第四轮已实现独立的[调度与复制实验室](../completed/layout-scheduling-lab-20261104.md)：
源数据查询分块与真实复制分别控制，真实响应事件与总周期、RAM 流量、复制
空间形成可比较的取舍。595 组有限网格组合全部正确，其中 385 组属于四个
可玩工作负载，210 组为额外探测；90 次重复与 JSON 往返执行通过。
[策略解释与原始证据](../../verification/20261104-layout-scheduling/strategy/README.md)
不构成全局最优或长期趣味性结论。最终 GPU 界面242项检查通过，两张错误
尺寸截图的夹具问题已修复，12张最终原图尺寸核对通过。原生运行/编辑/
恢复已有观察，普通设置语言下拉与发布包仍有独立验收边界。

第四轮提出的后续问题是更广策略空间、工作负载和探索体验，以及正式采用的
兼容影响与回退方式。正式 `layout-memory-1`、旧合法方案和成绩含义保持
不变；实验使用独立身份。第五轮增加输入方案簿，运行历史仍在进程内，
不自动修改旧阈值或使旧成绩失效。

第三轮已完成：[可保存与分享的实测挑战](../completed/portable-challenges-20261104.md)。
版本化配方、受保护侧文件、导入复测及可撤销改进循环已通过隔离验证。
其 2555 候选实测揭示的存储与查询调度耦合，是第四轮实验的起点。

已完成两轮局部增量：[游戏系统接手与第一轮可玩改进](../completed/gameplay-systems-20261104.md)、
[同条件个人记录与最佳实验恢复](../completed/comparable-records-20261104.md)。
用户已授权在独立分支持续推进，长期目标仍有效；版本化挑战配方与受限复算
已交付，后续模型工作以策略证据和兼容评估为前提。
第二、三轮原生点击因 Mac 锁屏仍未验收。上一轮设计争议保留在
[待审核清单](../../development/GAMEPLAY_AUDIT_20261104.md)，不自动回退。

当前工程交付见 [团队试玩与开发交接](../../development/team-handoff.md)；
实验室与已完成的 Claude 后续迭代已纳入本轮工程收尾。
下列 10 月 18 日队列为历史记录，其中“F5 只有 40 项”已被完整旅程默认入口取代。
后续玩法、美术、故事及教学由团队另行决定，不构成自动追加任务。

## Historical queue — 2026-10-18

Owner acceptance follow-up: root source F5 exposes40 tasks and the3D display does
not meet the requested laboratory experience. Small source-entry correction
`caf9e2b` and an isolated60-task preview are verified within a headless scope.
[Claude development handoff](../../development/CLAUDE_HANDOFF_20261018.md) records
all conversation changes and unmet requirements; engineering closure below does
not mean product acceptance. No further autonomous feature round is scheduled.


The [final journey candidate](../completed/journey-final-candidate-20261018.md),
[full-journey development](../completed/full-journey-experience-20261018.md) and
[narrative modal-focus round](../completed/narrative-modal-focus-20261018.md) are
complete within the engineering scope requested by the user. Product5bd3792 has
fixed ordinary and tester Windows packages, successful source CI, actual exported
save/restart/feedback checks and independent data/image review. Package identities,
original failures and change evidence live in the
[final verification](../../verification/20261018-journey-final/README.md).

Native input, Mac, newcomer understanding, final creative choices and the older
exported Efficiency positive-control observation remain in the
[next-day handoff](../../development/night-handoff-20261018.md). They do not schedule
another feature round. Videos remain NOT_RECORDED; original images and operation
scripts are available to the team.

The earlier [distributable playtest plan](distributable-cloud-playtest.md) and
[offline teammate record](offline-teammate-playtest.md) retain their recorded
scope; this closeout does not change their external gates. Other completed rounds
remain under [completed](../completed/).

Use [CURRENT_STATE](../../CURRENT_STATE.md) for the delivered version and
[RELEASE_BLOCKERS](../../../RELEASE_BLOCKERS.md) for external acceptance.
Create a new plan only when [PLANS.md](../../../PLANS.md) requires one.
