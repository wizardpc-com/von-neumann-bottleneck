# Region准备拒绝的一致计算证据 — 2026-11-05

第十一轮，任务分支`codex/gameplay-systems-20261104`，冻结基线
`cf27a8236db7faca56d6361cf9a44d35224b748e`。本记录对应本轮源码与隔离QA，
不更新公开版本，也不代表Windows或导出包验收。
[完成计划](../../exec-plans/completed/region-rejection-evidence-20261105.md) ·
[计算审计](../../development/COMPUTATION_AUDIT_20261105.md)。

## 修复的真实矛盾

原Region先执行Base服务，再检查准备参数。对公开短订单设置`clients=0`
时，结果已经失败且总周期为0、事件为空，却仍保留4请求周期、68搬运周期、
68字节流量、64个已解码值、64字节缓存峰值和输出`[7]`。
这些是实际旧运行时的字段，不是推测的界面问题。

现在只有`preparation_machine`这一拒绝分支返回全新的失败Trace：

- 保留原身份、失败原因、全部21个指标键，以及提交的spec／plan深复制。
- 14个执行／存储数字指标统一为整数0；输出、期望、编码块及访问记录为空。
- 顶层结果与期望为0，事件为空，其余字段使用新Trace默认值。
- 保持原参数类型和边界，包含离线订单的相同检查；不把浮点1.0转换为整数。

Base错误仍优先返回完整原证据。例如第一块已累计12字节、第二块超过
scratch限制时，即使准备参数也无效，仍保留原`scratch`结果和那12字节。
本轮没有把其他拒绝路径一并清零，也没有把准备检查提前到Base之前。

生产GDScript只修改`experiments/representation_region/model.gd`。合法
准备／服务路径、成本、Catalog、模型版本、条件身份、存档格式和旧成果
判定不变。保存的支持方案仍由真实模型重算；拒绝结果不能获得完成资格。
GDScript继续作为参考实现，没有原生模块或依赖变更。

## 旧版负控与候选回归

冻结项目独立来自基线Git归档；556个`src/experiments`文件逐一绑定到
Git原始字节，[冻结记录](invocation-tools/round11-reference.json)。
所有Godot进程由主线程串行运行，使用固定
`4.7.1.stable.official.a13da4feb`及独立`VonNeumannBottleneckChecks/...`
目录，普通玩家档案没有参与。

| 运行 | 实际结果 | 原始证据 |
| --- | --- | --- |
| 旧版既有Region套件 | 3329项通过，exit0 | [121527Z](checks/20261105T121527Z/results.json) |
| 新回归运行冻结旧版 | 854项／252预期失败，exit1 | [122300Z](checks/20261105T122300Z/results.json) |
| 候选标准验证器 | 六套全部通过，另有导入／隔离目录检查 | [完整记录](checks/candidate-standard/results.json) |

旧版252个失败全部对应63组输入的残留指标、数组、标量和非默认结果字段；
负控正常执行到最终FAIL，无脚本／解析异常。原始错误和调用栈完整保留。
相同测试在候选上为854项／0失败。

新回归覆盖63个准备参数拒绝案例、11个复合Base错误案例和12个合法边界
案例。它检查直接GDScript浮点及容器类型、缺失字段、两个在线模式、三种
编码方案、两种服务负载、完整类型化重复、双向深复制、后续执行不修改旧
证据，以及所有五个任务均不能接纳拒绝结果。案例数不是断言数。

候选六套分别为：

| 套件 | 检查数／失败数 |
| --- | --- |
| Region拒绝回归 | 854／0 |
| 既有Region模型与工作台 | 3329／0 |
| Region会话恢复 | 47／0 |
| 保护支持方案 | 54／0 |
| 旅程重算审查 | 45／0 |
| 表示工作台呈现 | 9303／0 |

完整日志均检查无异常诊断。六套相关检查不是全仓库回归，也不是GPU或
原生输入验收。[契约审查](reviews/contract-review.md) ·
[测试与兼容语料源码复核](reviews/test-source-followup.md)。

最终[独立证据审查](reviews/final-evidence-review.md)无遗留问题；
3235项结构与文件一致性检查涵盖源码、原始日志、完整类型化结果和文档，
不是额外游戏用例。[复核脚本](reviews/final-evidence-review.py)与
[逐项结果](reviews/final-evidence-review.json)一并保留。

## 完整结果与策略兼容

新旧运行使用相同六份测量GDScript、相同主机、同一固定次数和三批样本。
工具绑定及实际次数见[脚本哈希](invocation-tools/round11-measured-gd-sha256.json)
和[次数清单](invocation-tools/round11-iterations.json)。

`representation_region_compatibility`覆盖全部八种正式订单，每任务使用
整块RAW、整块RLE和两个已有替代方案，共32份完整Trace及20个实际
`meets()`结果。合法但超出目标预算的方案也参加对照。
既有`representation_online_clients`另外保留四份完整Trace。

两个场景通过[严格比较](invocation-tools/round11-valid-comparison.json)：
输入、结果类型、完整事件、客户端标识、缓存快照、真实编码字节、阶段成本、
输出及目标判定精确一致。测量器还检查重复执行、JSON往返、输入不变，以及
后续调用不修改先前保留结果。有限语料不证明任意输入都正确。

| 场景 | 旧版中位耗时／范围 | 候选中位耗时／范围 |
| --- | --- | --- |
| 既有在线组合 | 29.633ms／28.302–29.854ms | 30.258ms／30.028–31.312ms |
| 32份兼容组合 | 81.655ms／81.473–82.143ms | 84.149ms／82.678–88.982ms |

这是完整公共调用组合的主机耗时，包含正常模型工作及证据生成；测量器的
快照／哈希／导出不计入。两组中位数分别约高2.1%和3.1%，不作本轮提速
宣称，也不推断FPS或跨平台性能。Base服务仍先运行，再拒绝准备参数。

独立`workload_rejections`保留原始旧结果；相同严格语义检查在旧版产生15
个预期失败，候选为零失败。该组合结果发生有意变化，其旧运行也失败，
[严格比较器拒绝为它生成可接受速度比](invocation-tools/round11-diagnostic-strict-comparison.json)。

独立[逐字段审查](reviews/diagnostic-compare.md)确认：拒绝语料中其余13个
成员完整类型化结果不变；只有Region的九个原先非零指标归零，四个结果
数组变空，顶层两个标量从7变为0。输入、错误、身份、失败判定和指标键集
精确保留。输出／期望数组由`Array[int]`、块数组由`Array[Dictionary]`
回到普通空数组，这是本次全新拒绝结果的明确类型变化。

审查核对34,593,526字节原始JSON、原始隔离输出、快照字节哈希和完整日志，
重新封存后得到相同文件。[复核脚本](reviews/diagnostic-compare.py) ·
[完整结果](reviews/diagnostic-compare.json)。
首次检查器因参考QA多一个空行中止；[原始检查失败](reviews/diagnostic-initial-checker-failure.json)
保留，后续只准确允许该格式差异，没有修改模型、计算文件或比较器。

四份实际运行记录、原始／封存完整JSON及完整日志均已保存：

- [旧版有效语料](benchmarks/20261105T122550Z-reference-valid/invocations.json)
- [候选有效语料](benchmarks/20261105T123217Z-candidate-valid/invocations.json)
- [旧版拒绝缺陷](benchmarks/20261105T122734Z-reference-rejection-defect/invocations.json)
- [候选一致拒绝](benchmarks/20261105T123341Z-candidate-rejection/invocations.json)

## 隔离试玩、回退与剩余工作

QA与试玩共用`.godot/verification/20261105T122827Z-1645209e/project`。
本地可执行入口`.godot/region-evidence-preview-20261105.command`使用
`VonNeumannBottleneckChecks/round11/playable-preview-20261105`独立档，
保持普通实验室／Game入口；可选择Test访问表示区域。没有向正式订单、
默认方案或玩家数据注入无效准备参数。

[源码绑定](source-sha256.json)涵盖1250个源码／测试／支持文件与
`project.godot`，共1251项。源码与QA一致，设置只多两项隔离目录配置，
普通主场景不变。启动脚本通过`zsh -n`；普通主场景
`--headless --quit-after 8`启动exit0且无诊断，
见[最终启动记录](checks/20261105T123906Z/results.json)。

回退可恢复基线中唯一的Region拒绝分支及相应诊断预期，无需迁移、改写或
删除玩家文件。原始失败证据继续留在Git。本轮没有新的GPU、原生OS输入、
Windows、导出包、新玩家、长时间、音频或内存峰值验收。

下一项实测重复冷客户端Base服务和客户证据生成的开销，先做局部GDScript
优化及完整差分。Base自身已包含Trace分配，不能把其耗时标成纯算术耗时；
若复用结果，还需要额外证明不同客户端事件之间的修改隔离。C++／Rust
试点仍需独立价值、完整对照及Windows/macOS证据。

[证据文件清单](artifact-sha256.json)绑定本目录除清单本身以外的所有文件，
包含原始失败日志；清单不改变它们的字节内容。
