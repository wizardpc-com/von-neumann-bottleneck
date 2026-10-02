# 2026-10-02 后半程切片与有限代理验证

基线：`cd17d98`，启动时fetch确认main与origin/main一致。Godot
`4.7.1.stable.official.a13da4feb`，macOS / Apple M2 / OpenGL Compatibility。
本轮没有push、正式任务注册、存档格式更新或音频扩展。

## 交付与边界

- 正式runtime：Capstone实际方案清单去重；Buffers将不存在的缓冲器与越界批次
  分开诊断。失败仍停在原行、原周期，合法程序与40任务/前置保持不变。
- experiments：三个连续表示实验，一个单独隐藏推理场景；模型返回现有Trace，
  视图消费结果，进度只在场景内存中。详细规则与决定见
  [后半程框架](../../design/second-act-framework.md)。
- 可直接运行的入口与复现命令见 [实验说明](../../../experiments/README.md)。

## 自动测试

最终完整隔离项目：`.godot/verification/20261002T153423Z-cf53e2bb/project`。
[results.json](results.json)记录**45套件全部PASS**，另有导入与独立user目录检查。
命令：

```sh
python3 scripts/verify-project.py --godot /Users/yrq/Applications/Godot-4.7.1.app/Contents/MacOS/Godot
```

覆盖原有注册/DAG、正式模拟、双语、UI、GlobalSave、签名迁移、工作区恢复、Trace
ambience与新模型。关键完整输出保存在此目录；其余完整日志在上述本机QA目录。
本轮没有重新做多进程旧存档迁移；上轮3/3属于历史证据，不混入此次结果。

新模型枚举所有公开配置，验证可逆字节还原、元数据成本、事件总和、确定性
签名、非法容量拒绝、LRU复访与尾块、机器/数据/访问方式反例、实际量化输出及
质量指标、批量/驻留不改变数值结果。实验3的扫描/点读保持相同机器有独立断言。
代理测试验证隐藏答案字段注入不影响决策，有限预算能终止，并依据公开Total
重选较快方案而非固定按钮名称。

Python回归：receiver 2/2、storage 3/3、community 5/5（含导入的receiver用例），
report-playtests全部校准通过；见`python-*.txt`。receiver/community首次在沙箱
因无法绑定loopback端口失败，允许本机监听后重跑通过，不是产品故障。

## Agent 实际窗口操作：新实验

方式是Godot viewport鼠标/键盘事件，真实OptionButton菜单、运行按钮、阶段
按钮与Trace选中事件；不是直接调用模型结果冒充试玩。菜单在代理运行时使用
Godot PopupMenu代替macOS原生菜单，以便输入注入。不属于原生OS自动化。

- 中文最终：`.godot/experiments/ad0ba5436ff8`，**98检查PASS**，
  [完整运行](labs-zh.txt) / [检查列表](labs-zh-checks.json)。
- 英文：`.godot/experiments/e3069ad3ba0e`，**97检查PASS**，
  [完整运行](labs-en.txt) / [检查列表](labs-en-checks.json)。
  此轮英文截图早于最后的“OK→executed”和输出预览收拢；最终中文验证了两项
  小修及新增的Trace点击检查，最终英文文案由双语/模型UI套件覆盖。
- 这些路径知道验收配置，明确为**已知目标的操作验收**，不冒充unknown-answer。

实际路径包括：raw→RLE；三机器/数据配对；同机扫描→点读；64B→4B；容量超限；
推理基线→2bit误差失败→8bit平衡方案→batch8首响应超限；点击输出事件读实际误差。
代表截图：

- [压缩胜例](screens/zh_CN-representation-scan.png)、[快链路反例](screens/zh_CN-representation-crossover-1.png)
- [点读小块](screens/zh_CN-representation-point-improved.png)、[容量拒绝](screens/zh_CN-representation-memory-rejected.png)
- [低精度误差](screens/zh_CN-inference-quality-loss.png)、[输出证据](screens/zh_CN-inference-balanced.png)、[大批量延迟](screens/zh_CN-inference-batch-latency.png)
- [英文表示](screens/en-representation-point-improved.png)、[英文推理](screens/en-inference-balanced.png)

修正并复测：初版运行历史把周期放在长配置字典后，实际截图中被截断，现将周期
前置、配置压缩；初版实验3同时切换了解码速度，破坏同机访问对照，改为两订单
均decode4，重校准99/37/30/18周期与公开目标；推理初版输出列表过长，改预览4项
与按需事件详情；历史中的“OK”会误示质量达标，改为“已执行”。

## Unknown-answer / evidence-driven proxy：明确的能力下限

策略文件 `experiments/evidence_proxy/policy.gd` 没有Node、文件、Catalog、模型
oracle或reference solution依赖。输入仅为actuator提供的public UI文本与可用动作。
忽略其他字典字段；不读取receipt、目标判定代码、标准接线或固定解序列。

这不是一个另起的、无项目知识的大模型玩家，而是**可审计的有限策略程序**：
先测starter，最多读H1，尝试一变量的未试选项（按界面逆序），从可见Profiler
`Total`提取实测周期，重验观测最低者。每任务最多8次决策；不能从任意语言综合
电路，也不具备完整诊断推理。不能把穷举比较称为人类顿悟。

**fixture边界**：所有目标使用Test模式任务隔离，前置组件库由既有Test机制提供；
目标仍是未修改starter，未注入目标答案。这避免把熟悉题目的前置回放伪装成
未知玩家，但Test模式不受普通Game完整诊断/进度门约束，因此**本轮不证明普通
Game的完整认知路径或解锁流程**。上轮普通Game已知解代理仍是独立历史证据。

观察是可见UI控件文本的读取，不是OCR；Tree限制在当前可见行，但Label可能包括
其滚动区内完整文本，遮挡与人的注意力不被模拟。截图展示实际桌面状态。

最终 `.godot/experiments/3f3640bc9bb2`：**23条决策记录，actuator检查通过**。
[策略完整日志](proxy.txt)、[逐步输入/决策原始记录](unknown-answer-journal.json)。

| 任务 | 实际观察/动作 | 结论 |
|---|---|---|
| ALU | 空接线starter跑32用例；H1说明并行产生候选、opcode只选择 | 能看到输入/控制分离问题；策略没有接线综合器而停滞。未通关，不能认定新手能自然完成 |
| CPU | 空starter正式运行；H1要求逐OP列源/目的并导出控制 | 接口提示有方向，策略仍停滞；未改关、不提供标准接法 |
| 2-6 | 基线210；按4→2→1→0比较得210/210/138/210，回选1重新测得138 | 在无答案条件下取得真实反例与可重复最优观测；不证明会自发选择这种实验方法 |
| 2-7 | Test基线642；同样单变量比较取得138并重验 | 只证明已有work-group路径可调查；没有走普通Game诊断门、没有独立陌生题、没有完整成本前沿调查 |
| Buffers | 空板运行报错，查看H1询问下一批能放哪里；停滞 | 原反馈混淆缺部件与批次编号，值得针对性修复；并未通过未知策略完成双缓冲调度 |

截图：[ALU H1](screens/en-alu-h1.png)、[CPU H1](screens/en-cpu-h1.png)、
[2-6收束](screens/en-blocking-stop.png)、[2-7收束](screens/en-capstone-stop.png)、
[Buffers H1](screens/en-buffers-h1.png)。

代理自身也迭代过：首轮未等待正式播放结束就点Hint，ALU/CPU H1检查失败，
[失败日志](proxy-first-failed.txt)保留。修正为经可见播放频率控件加速并等待按钮恢复，
后续两次通过。没有因此修改游戏Hint行为。macOS日志有IMKCFRunLoopWakeUpReliable
提示，未影响检查；无Godot SCRIPT ERROR。

Buffers实修的前后证据：[旧错误](screens/buffers-before.png) →
[新错误](screens/en-buffers-run.png)。将未知buffer、越界batch拆成两个诊断码，
不改调度/时间/输出规则；单元测试覆盖fetch/ready/consume无该部件的原失败点，
以及已有buffer但batch99越界。全部合法解与确定性测试仍通过。

## 未验证与归类

- **INCORPORATE**：Capstone去重、Buffers可解释错误分流。
- **KEEP EXPERIMENTAL**：表示三实验、隐藏线性推理、有限证据策略。默认入口仍
  是原40任务，实验没有正式receipt、持久化进度或独立打包验收。
- **DEFER**：正式新章、预测/投机、AI意识/世界观扩写、配乐系统。
- 原生OS操作：本轮**没有**；人工新手验证：**没有**；主观试听：**没有**。
- 较小窗口、手柄、跨平台发布及实验长期存档未验收。当前Trace详情仍是技术
  原型呈现，不宣称已达到正式关卡美术/新手可读性标准。
- 表示缓存槽数目前缺少主实验中的有效性能差异；推理只是32输入的微型线性
  workload，质量不代表分布外泛化。正式纳入条件见设计文档。

阶段提交：`1c83c87`（去重及计划）、`adf2077`（模型、可玩实验、代理和框架），
随后提交Buffers修正与本记录。工作区原有project.godot排序、提示/计划文本和
既有未跟踪UID均未纳入提交；最终Git检查见交付回复。
