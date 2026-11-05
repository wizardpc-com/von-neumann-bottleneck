# Round 4 模型与测试独立审查 — 2026-11-04

审查者：`/root/review_records_final`。依据 `.godot/collaboration/round4-implementation.md`、`round4-tasks.md` 以及当前模型交接说明，对已落地实现进行了只读审查。

**结论：当前审查范围内未确认需要修复的源码缺陷。** 可以进入主线程的隔离运行验证；此结论不代表模型测试、旧模型 Trace 保真或可玩 UI 已通过运行验收。本审查没有启动 Godot、操作玩家存档、修改 Git，也没有编辑源代码、测试或已释放探针。

审查范围：

- `experiments/layout_strategy/model.gd` 全文。
- `tests/test_layout_strategy_model.gd` 全文。
- `src/layout_chapter/layout_simulator.gd` 与最终 Round 3 QA 对照。
- `tests/test_layout_strategy_legacy.gd` 及其冻结 fixture 的来源。
- `layout_recipe.gd`、`layout_run.gd`、`simulation_trace.gd`、`simulation_event.gd` 的相关调用链。
- `session.gd` 及其测试此前已作辅助阅读；本次结论重点是模型、共享模拟器提取和模型测试。

已确认的实现边界：

1. 复制地址使用 `current_copy.first_record`，与查询 tile 起点分离。当前实验保留整份选定字段复制，查询 tile 变化不会重新解释复制内相对地址。新增网格包含 tile 1/2/4/8 和尾块；乱序、重复索引测试也覆盖保留复制路径。
2. 请求按公开 query/repeat 顺序编号；每个 job 保留原输出槽。按升序 tile 执行可以改变物理访问顺序，但不会改变逻辑输出中的 index/field 位置。稀疏 job 在最后一个值及其实际输出开销结束时回应；`first_request_cycles` 明确取 job 0，未偷换为最早完成的任意请求。
3. batch 请求在 0 入场；serial 强制 group 1，后续请求仅在上一响应之后入场。复制准备允许预先读取不可变源数据，这与已接受规则一致。输出在各 job 回应前计费一次，实验的末尾输出 hook 不再重复计费。
4. 查询事件、输出和请求/响应携带 `job_id`；现有 `SimulationEvent.to_dictionary()` 没有剔除此字段。测试会修改响应中的 job ID 并要求完整签名改变。未发现 UI、时钟、随机数、文件、网络或正式结果写入依赖。
5. 严格 task/plan/query/recipe/group 校验在规范化和执行之前完成。整数、有限值、数组结构、重复复制字段、未知键、任务数量、记录数和输出规模均有明确边界。允许 query 的重复字段与索引是保持原逻辑工作量的设计，不会被错误去重。
6. 有效但空间不足的计划返回真实失败 Trace，未完成响应保持 -1；公开 `evaluate()` 在成功和失败时均写入新模型、条件和计划身份。条件包含规范化完整任务及实际内存参数；未启用复制时，仅在有效计划身份中忽略休眠复制配置，原草稿仍保留。
7. `Executor.measure()` 是内部受信任执行接缝，身份封装位于公开 `evaluate()`。当前 Session 使用后者；直接使用前者的测试只比较重用与新建执行器的状态清理。当前没有把内部旧身份结果送入正式成绩的调用路径，因此不把移动封装视为本轮必修问题。

共享模拟器与旧成果保护：

- 已直接对照 `.godot/verification/20261104T210749Z-5839019c/project/src/layout_chapter/layout_simulator.gd`。差异仅为约定的 `_emit_outputs()` 与 `_consume_query_value()` 两处提取，以及复制地址改为复制自身起点。
- 官方调度仍保证 query batch 与当前 copy 的起点相同；旧模型版本、操作成本、缓存机制、目标及执行顺序均未改动。源码推理支持兼容，但仍需要真实完整 Trace 回归作最终证明。
- `tests/fixtures/layout_strategy/legacy-layout-traces.json` 含 141 个设计、六项任务。其 provenance SHA256 与实际 Round 3 `strategy/results.json` 完全匹配。旧模型测试逐项比较 282 个 case 的 `trace_id`、身份、正确性、门槛、各指标及错误，不是重新计算期望值的自证测试。

新增模型测试的有效覆盖：

- 144 项调度/复制网格，真实独立逻辑 oracle，真实 compute/write/output 数量。
- 周期与流量恒等式、阶段周期总和、事件时间连续性、一次响应与一次入场、串行入场因果关系。
- 既有独立探针的 307/2456 与 531/552，以及 557/1362/80 权衡样例。
- 稀疏提前响应、重复字段/索引、乱序索引、单记录、尾块和 4096 值上限。
- 分配失败、执行器失败后/成功后重用、精确嵌套 schema、JSON 整数归一化、完整 Trace 重放、语言与插入顺序、调用者数据不变性。
- 旧挑战 envelope/旧设计拒绝，以及正式 VNB4C1 检查器对实验身份的拒绝。

运行边界仍由主线程完成：模型 suite、Session suite、141 设计/282 case 旧 Trace 保真、相关正式模型/成绩/挑战回归，以及 UI/GPU/启动和最终源文件绑定。发现探针通过的历史收据不能代替当前实现的这些运行结果。

审查版本 SHA256：

```text
8c980ac8a9e09fd4a491d3cf392a267cd64108550af77cf54bd95a0f2b36b23f  experiments/layout_strategy/model.gd
8aa5e0566c523c31b8ceb4e9fbeedd00319a2ab03f2b437d9f95ea71b615843c  tests/test_layout_strategy_model.gd
a8941642055d2e968817921115fb7b3387ea17c1582bcd272bbf2dfecee46387  src/layout_chapter/layout_simulator.gd
bad2e4d0dfeee0ff9bb5139e70902828c2dc9cecc144d2c45fd27ab330284b6e  tests/test_layout_strategy_legacy.gd
cd713025f675b736053631c96d67141ab40e582fbe2c8b7ef98069f7e2e30683  tests/fixtures/layout_strategy/legacy-layout-traces.json
```
