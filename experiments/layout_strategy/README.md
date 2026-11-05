# 调度与复制实验室 / Scheduling and copying lab

独立实验模型 `layout-schedule-experiment-1`。它沿用第四章的实际内存操作，
将查询调度与物理复制拆开，比较首个请求响应、总周期、RAM流量和复制空间。
第五轮增加命名方案簿、可恢复的工作区，以及首答／复制空间限制下的个人
比较。数据文件只保存输入；已保留方案须本机复算后才参加比较。
第七轮增加两次温度扫描、温度后告警两种独立结构，使周期／流量取舍和
复制布局选择能直接游玩。原四种条件与计算规则保留；新历史使用独立v2文件，
读取上一版记录后，由玩家明确保存新副本。
第四轮的模型与原生试玩范围见[原证据](../../docs/verification/20261104-layout-scheduling/README.md)；
方案簿的[新增验收](../../docs/verification/20261104-layout-notebook/README.md)
独立记录，不沿用原生或导出包结论。

## 启动

从仓库根目录运行，使用Godot4.7.1稳定版：

```sh
python3 scripts/run-experiment.py layout_strategy --godot /path/to/Godot --profile my-notebook
python3 scripts/run-experiment.py layout_strategy --godot /path/to/Godot --profile my-notebook --locale en
```

启动器先复制项目、设置独立测试数据目录再导入。`--prepare-only`仅准备副本，
该副本的F5直接进入本实验。不要在普通玩家项目中直接运行此场景。
实验不接入60项旅程、正式成绩、完成判定或旧挑战码；不支持`--journey`
和旧实验的`--replay`路线。`--profile`只接受1至40位英文字母、数字和连字符，
同名配置在不同启动副本间使用同一个独立实验数据目录
`VonNeumannBottleneckChecks/layout_strategy/<name>`。不指定配置时，每次命令
使用新目录；也可直接重开原先准备的副本。

## 怎样探索

1. 选择温度统计、混合请求，或新增的“两次温度”“温度后告警”条件。
2. 先运行默认源数据方案，并选为比较基准。
3. 调整一起处理的请求数、每轮处理的记录数，或尝试一次复制选定字段。
4. 运行后分别比较四项指标；点“查看差异”进入运行证据，检查两次实测的
   准备、查询和输出成本，或查看缓存读计数及每份请求的实际响应。
5. 选择旧运行只改变查看对象。显式恢复方案才会修改草稿，并可一次撤销。
6. 在“方案笔记”中为所选实测方案命名保留；这保留的是所选运行的配方，
   即使当前编辑区已经不同。命名方案不会被近期运行淘汰。
7. 按需要启用首答或复制空间上限，再按总周期或RAM流量比较。上限包含
   边界；0是实际限制，“不限”单独表示。并列目标值共享名次，不合成总分。
8. 点“保存工作区”，或保留／移除方案时保存整个当前提案。退出后使用
   相同配置重开，返回原工作负载、各自草稿、目标与命名方案，继续探索。

每种条件独立保留草稿、撤销记录和本次运行历史。更改语言不应丢失它们。
最多保留24次运行和64步编辑，比较基准在历史淘汰时保留。每种工作负载
最多8个命名方案，满额需明确移除，不自动覆盖或淘汰。工作区显式保存，
未保存的草稿／目标会在退出时提醒；近期运行、撤销栈和比较基准仍只属于
本次启动。这里的排名只比较所显示的已测集合，没有全局最优含义；没有
方案满足限制也不代表不可能。第六轮增加离线挑战码；在线排行榜尚未接入。

比较解释的方向为“所选运行减去基准”。两侧显示各自已测方案，编辑区仍可
保留不同的草稿。选择阶段或请求行，再查看所选／基准事件，可以定位各自
原始Trace；切换查看来源不会改变历史列表的选中运行。查看差异不重新模拟，
也不保存、编辑草稿或清除撤销；尚未提交的数字输入保留到明确运行时。

“周期与RAM流量”分别显示阶段周期、真实RAM流量、已复制数据和分配空间。
“缓存读取”区分读查找、命中、缺失、写入次数和RAM读写字节；写入不计入
读命中的分母。原始事件表的RAM B只统计装入与写入，淘汰、分配、释放、
缓存读取的事件字节另有含义。“请求时序”按公开请求顺序显示就绪、完成和
两者之差；等待至完成包含准备和交替执行，多个请求的耗时不能相加当作
总工作量。Q1始终是第一份提交的请求。

缺少基准、条件不符、失败或无法核对的记录没有完整比较解释；原始事件仍
可检查。解释按当前两份快照核算，不把整个收益归因于单个设置，也不证明
全局最优。纯汇总器`explanation.gd`只读事件与指标、保留原事件索引，
不会写回模型结果或参与排名；这些本地一致性检查不构成联网成绩认证。

独立侧文件`layout_strategy_notebook_v2.json`保存完整公开任务、模型／条件
身份、方案、名称和目标，不保存可直接当作成绩使用的数字。整档限制128KiB，
严格检查嵌套内容、规范JSON和UTF-8。未知／损坏／旧规则文件进入只读保护；
当前会话仍可临时探索。写入失败保留内存提案，可显式重试；外部改写和并发
写者不会被静默覆盖。对已停止写者的恢复需要明确操作，活跃或无法确认的
写者不会被移除。这不构成突然断电持久性或网络防作弊保证。

## 分享与应战

在“比较”页点“挑战…”，可以分享所选实测方案，或输入另一份挑战码预览。
目标绑定当前六种工作负载之一、总周期或RAM流量目标，以及包含边界的
首答／复制空间上限。预览必须本机复算；点击“接纳目标”才保留它。
预览与接纳不修改草稿、撤销栈、所选证据、个人筛选或命名方案。
其他条件的代码会提示切换工作负载，不自动替换当前工作。

挑战条件独立于笔记筛选。运行完整正确方案后，按挑战本身的上限判断是否
合格，再显示尚未达到、持平或已改进。总周期更低但首答超限仍不能获胜。
“按挑战条件应战”把所选实测配方连同原目标限制生成新码；普通分享使用
当前个人条件。两者都重新计算，不采用复制来的分数。目标可能已很难改进，
任意合法代码不保证存在严格更好的解法，也不代表全局最优。

当前条件有入门挑战时，窗口显示一个对应入口。四个可选目标均为源数据方案：
温度全部就绪时按周期、Q1≤350、复制≤0；原温度逐单按周期、Q1≤600、
复制≤80；两次温度按RAM流量、Q1≤600、复制≤80；温度后告警按周期、
Q1≤800、复制≤144。混合条件没有预设挑战。它们不预填答案或增加正式进度。
查看目标证据会显式产生一次真实重放；恢复目标方案只产生一次可撤销编辑。
数值框中的⌘/Ctrl+Enter（包括组合键中的小键盘Enter）会先提交数值再运行一次；
普通Enter只提交数值。文字编辑器保留自己的文本操作。

`VNBSC1:`使用最多4096个UTF-8字节的规范JSON，只包含版本、任务、模型、
完整条件、目标和方案。附带分数、未知字段、重复键及非规范写法会被拒绝；
外侧剪贴板空白可接受，但仍计入字节限制。无复制方案的休眠复制配置统一
为默认传输形态，方案笔记中的编辑选择不变。它与正式第四章`VNB4C1:`分开。

目标侧文件`layout_strategy_challenges_v2.json`最多32KiB，每种负载一份目标。
它与方案笔记分别保存；接纳／清除／重试只保存目标提案，保存笔记不提交
目标。失败时保留精确临时提案与原文件，可明确重试；失败清除在本次会话
中停止挑战，旧目标仍留在磁盘直到成功保存。损坏／未知文件和外部修改进入
只读保护；检测到冲突后，缓存目标不再声称“已保存”。支持的旧模型／条件码
保留可复制，但不参加当前比较。独立写入租约、临时回读与原子替换保护合作
写者；停止写者恢复和保存是两个明确动作。退出会提醒待保存目标。
两个v2文件分别处理升级：存在的有效v2优先，空目标表也不会恢复旧目标；
损坏或未知v2进入保护，不退回旧文件。只有缺少v2时才严格读取对应v1，
界面显示上一版记录已载入、尚待保存副本。读取不写文件；明确保存、接纳、
清除或重试才创建v2，原v1内容始终保留。源文件在此期间改变也会阻止覆盖。
旧版本继续读取v1；再打开新版本会恢复v2。此后两边编辑是独立历史，不自动
合并。方案簿和挑战是两个独立保存动作；保存其中一份不会提交另一份。

## 公开计算规则

- 数据：17条记录，每条4个4B字段；源数据固定按记录排列且不可变。
- 原温度场景：8次温度求和。混合场景：8次热点字段对求和及1次稀疏记录查看。
- 两次温度：2次温度求和；温度后告警：先4次温度、再4次告警求和。均逐次到达。
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
空间换取后续复用。第四轮模型的595组声明组合均正确，其中385组来自原四个
可玩场景，210组为额外16请求探针。90次重复及JSON重放一致。每个原场景
在该有限样本中都有多个非支配指标组合，不能据此宣称全局最优。

例如“温度扫描 · 全部就绪”：默认方案首答307、总计2456周期；每组8查询、
每块1记录、不复制，首答531、总计552周期。前者更早回答第一份请求，
后者更早完成全部工作。“逐次请求”中保留温度副本则是首答557、总计1362
周期和80B复制空间。[原始策略对照](../../docs/verification/20261104-layout-scheduling/strategy/README.md)。

“两次温度”中，源数据方案为首答307／总计614周期／544B流量／0B复制；
温度副本为557／672／500／80。在首答≤600、复制≤80的相同条件下，源方案
周期更少，副本流量更少。“温度后告警”的双字段副本，按记录排列为
791／2044／1560／144，按字段排列为727／1516／1032／144。
这些是实际方案对照，不是所有合法输入的全局最优结论。

## Compatibility and verification

This is an opt-in experiment with its own model/condition identities and a
separate version2 notebook with read-only v1 copy-forward. Model, Session and Goals remain pure; Workspace owns
proposed inputs and fresh remeasurement, while NotebookStore owns validated
committed inputs and cooperative transactional writes. UI only requests actions.
The old `layout-memory-1` campaign, valid recipes, targets and portable challenges
retain their meaning. The shared query-value/output helpers passed the frozen
141-design/282-case canonical Trace gate with3810 checks; the original sampled
identities, outputs, metrics, eligibility and complete Trace signatures agree.

Focused suites: `test_layout_strategy_model`, `test_layout_strategy_session`,
`test_layout_strategy_legacy`, `test_layout_strategy_goals`,
`test_layout_strategy_notebook_store`, `test_layout_strategy_workspace`,
`test_layout_strategy_ui` and `test_layout_strategy_notebook_ui`, run through the
isolated verifier. Existing layout/challenge/save tests remain relevant.
Runner routing has a separate Python test; genuine process restart/contention
checks use `tests/recovery/layout_notebook_process_probe.gd` in a fresh named QA
profile. None of these tests establish exported or other-platform acceptance.
See the [notebook plan](../../docs/exec-plans/completed/layout-notebook-20261104.md)
and the [original model plan](../../docs/exec-plans/completed/layout-scheduling-lab-20261104.md).

Replay challenges add pure`challenge_code.gd`, protected`challenge_store.gd`,
proposal controller`challenges.gd` and the secondary`challenge_window.gd`.
The controller reconstructs an attempted plan and validates its full Trace
identity before comparison; stale display metrics have no authority. Run
`test_layout_strategy_challenge_code`, `test_layout_strategy_challenge_store`,
`test_layout_strategy_challenges` and `test_layout_strategy_challenge_ui`
alongside the existing suites. Process checks use
`tests/recovery/layout_challenge_process_probe.gd` in fresh named QA profiles.
These local checks do not authenticate a remote client or establish native
OS input, exported builds, newcomer comprehension or other-platform behavior.

The six-condition extension adds `test_layout_strategy_structures`,
`test_layout_strategy_catalog_parity`, `test_layout_strategy_store_upgrade`,
`test_layout_strategy_upgrade` and `test_layout_strategy_structures_ui`.
The frozen pre-extension fixture binds56 exact original observations and112
code outcomes. The real `layout_structure_process_probe.gd` additionally runs
against the frozen old runtime to prove rollback and independent subsequent
histories. See the [seventh-round receipt](../../docs/verification/20261105-structural-layout-workloads/README.md)
and [finite strategy evidence](../../docs/verification/20261105-structural-layout-workloads/strategy/README.md).
