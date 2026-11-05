# 调度与复制实验室 / Scheduling and copying lab

独立实验模型 `layout-schedule-experiment-1`。它沿用第四章的实际内存操作，
将查询调度与物理复制拆开，比较首个请求响应、总周期、RAM流量和复制空间。
模型、旧规则兼容、会话恢复和双语界面已在隔离环境验证；原生试玩已观察
运行、比较、编辑、恢复与撤销。原生设置下拉、导出包及其他平台仍有独立
验收边界。[完整证据](../../docs/verification/20261104-layout-scheduling/README.md)。

## 启动

从仓库根目录运行，使用Godot4.7.1稳定版：

```sh
python3 scripts/run-experiment.py layout_strategy --godot /path/to/Godot
python3 scripts/run-experiment.py layout_strategy --godot /path/to/Godot --locale en
```

启动器先复制项目、设置独立测试数据目录再导入。`--prepare-only`仅准备副本，
该副本的F5直接进入本实验。不要在普通玩家项目中直接运行此场景。
实验不接入60项旅程、正式成绩、完成判定或旧挑战码；不支持`--profile`、
`--journey`和旧实验的`--replay`路线。

## 怎样探索

1. 选择温度统计或混合请求，以及“同时到达”或“逐单到达”条件。
2. 先运行默认源数据方案，并选为比较基准。
3. 调整一起处理的请求数、每轮处理的记录数，或尝试一次复制选定字段。
4. 运行后分别比较四项指标；查看每个请求的响应与实际搬运事件。
5. 选择旧运行只改变查看对象。显式恢复方案才会修改草稿，并可一次撤销。

每种条件独立保留草稿、撤销记录和本次运行历史。更改语言不应丢失它们。
最多保留24次运行和64步编辑，比较基准在历史淘汰时保留。方案和历史只在
本进程中存在，退出确认会说明丢失范围；本轮没有跨进程保存和实验分享码。

## 公开计算规则

- 数据：17条记录，每条4个4B字段；源数据固定按记录排列且不可变。
- 温度场景：8次温度求和。混合场景：8次热点字段对求和及1次稀疏记录查看。
- 同时到达：所有请求在周期0可执行，连续的若干请求可以按记录块交替处理。
- 逐单到达：后一个请求只能在前一个完整回答后开始，分组数固定1。
  可以事先读取不可变源数据进行复制，复制准备计入首个请求等待。
- 每次回答紧随该请求最后一次真实输出操作。最终输出仍按公开请求、索引和
  字段顺序排列，重复索引保留。后面的稀疏请求可能先回答。
- “首个请求响应”始终是公开请求Q1的完成周期，不是所有响应中的最小值。
- 可以不复制，或一次复制完整的选定字段，保留至全部请求结束。
  复制空间上限160B，统计的是复制分配，不含累加器和输出存储。
- 缓存2行、每行16B，全相联LRU；查询1周期、填充16周期、4B写穿9周期，
  每个取出的查询值计算1周期、每个输出1周期。连线和调度没有额外收费。

若Q为查询值数、O为输出值数、M为实际复制字数、F为实际填充次数：

```text
总周期 = 2Q + O + 10M + 16F
RAM字节 = 4M + 16F
```

数值来自逐次执行的事件。相同完整条件下才计算历史差值，不合成总分。
分组可能用更晚的首答换取更少总工作；串行请求中，复制可能用准备时间和
空间换取后续复用。生产模型的595组声明组合均正确，其中385组来自四个
可玩场景，210组为额外16请求探针。90次重复及JSON重放一致。每个可玩
场景在该有限样本中都有多个非支配指标组合，不能据此宣称全局最优。

例如“温度扫描 · 全部就绪”：默认方案首答307、总计2456周期；每组8查询、
每块1记录、不复制，首答531、总计552周期。前者更早回答第一份请求，
后者更早完成全部工作。“逐次请求”中保留温度副本则是首答557、总计1362
周期和80B复制空间。[完整策略对照](../../docs/verification/20261104-layout-scheduling/strategy/README.md)。

## Compatibility and verification

This is an opt-in, session-only experiment with its own model/condition identities.
The old `layout-memory-1` campaign, valid recipes, targets and portable challenges
retain their meaning. The shared query-value/output helpers passed the frozen
141-design/282-case canonical Trace gate with3810 checks; the original sampled
identities, outputs, metrics, eligibility and complete Trace signatures agree.

Focused suites: `test_layout_strategy_model`, `test_layout_strategy_session`,
`test_layout_strategy_legacy`, and `test_layout_strategy_ui`, run through the
isolated verifier. Existing layout/challenge/save tests remain relevant.
See the [completed plan](../../docs/exec-plans/completed/layout-scheduling-lab-20261104.md).
