# Execution queue

第五轮已完成[方案笔记与限制条件比较](../completed/layout-notebook-20261104.md)：
可命名保留实测配方、显式保存工作区、同配置重开复算，并按首答与复制空间
限制比较真实总周期或RAM流量。整档保护、失败重试、并发拒绝以及停止写者
恢复后的实际新内容写入均有隔离证据。正式模型和旧成果未改。
[验证与试玩入口](../../verification/20261104-layout-notebook/README.md)。

下一优先级是实际探索体验与结构化工作负载。新增有限探测说明响应上限
确实改变可选策略，而16组纯数值变化不改变性能；不要用数字随机化冒充
新挑战。先检验玩家能否读懂取舍、有效保留和继续改进，再评估有意义的
新条件、实验配方分享及服务端固定版本重算。正式采用仍须兼容和回退分析。
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
