# 核心 40 关文案审计（只读，2026-10-21）

基线：读取 E:/VNB/game 当前工作树；未运行 Godot、未修改生产文件/测试、未操作 Git。每行对应 CSV 的开场+结算两卡。文案中的玩法陈述必须服从现有公开规格与正式判定。

## 映射与共性问题

- CSV 132 数据行均有16列：12章级引子/尾声 + 120关卡卡片。120关卡卡片的章节列全部错误填为“创造”；不能据此入库。
- CSV 编号 01 对应实际序章，02…05 对应第一…四章；不能直接作为当前显示编号。使用 domain/id 作为固定键。
- 以内容名/机制映射：01-8=alarm，01-9=latch；02-5=read_once，02-6=bottleneck；04-3=prefetch，04-4=backpressure；05-3=relocation，05-4=hot_cold。05-5标题漏“整”，唯一相符真实节点为batches。
- 局部拓扑自由，不能把参考接线的门数、时延、固定结果描述成所有玩家已获得的结果；屏幕连线没有传播延迟。
- 原稿大量“下一关”假定线性路线，但控制/存储可选支线及第三/第四章平行开放；不增添流程门槛。
- 多处开场已给失败原因或优化答案，结算又重复附注；不要批量接入，保留规格但让真实运行先给证据。
- “弥拉、洪水、雕像、钥匙”及人格化历史只入待确认候选；附注文档中的自由输入、跨章引用、强制回复均不是本轮授权。

## 逐任务表

| CSV ID / 原名 | 真实 key / 名称 | 实际操作与通关边界 | 文案审计 | 源码依据 |
|---|---|---|---|---|
| 01-1 接线 | `hardware_foundations/tutorial` / 序章·接线教程 | 把输入经NOT接到灯，切换输入、运行、拆线重连；五项操作均完成；有效运行 | 原稿只有直连；缺NOT与后四步；把连线归为1周期违背零延迟连接。 | `src/hardware_foundations/hardware_foundations.gd:2973`；`src/hardware_foundations/hardware_foundations.gd:8451`；`AGENTS.md:37` |
| 01-2 半加器 | `hardware_foundations/half_adder` / 序章·搭建 1 位半加器 | 两路1位输入产生SUM和CARRY；四组真值均正确，正式通过后才可封装 | 目标基本相符；“两个一位数相加会得到两位”应是两位表示；不能断言进位比和慢/贵，取决于玩家拓扑。 | `src/circuit/half_adder_test_bench.gd:7` |
| 01-3 全加器 | `hardware_foundations/full_adder` / 全加器 | A、B与来自低位的CIN相加；八种组合SUM/COUT正确 | “多出来的那个低位”实际是进位输入；复用两半加器是自然路径，不能当唯一拓扑判定；门数增长非本关计时结论。 | `src/content/prologue/arithmetic_content_pack.gd:36` |
| 01-4 一位校验 | `hardware_foundations/parity` / 错了一位 | 读取D0-D3和CHECK，输出奇偶不符ERROR；全部32组输入ERROR正确 | 不是玩家生成校验位，也不是检查算术自知对错；不能定位/纠错，偶数位翻转可能漏过。 | `src/content/prologue/exploration_content_pack.gd:129`；`localization/game.zh_CN.po:5923` |
| 01-5 两路选择 | `hardware_foundations/selector` / 谁能通过？ | S选择A或B输出；8组输入全对 | 依据控制位而非来源顺序；“比想象贵”无计时验收证据。 | `src/content/prologue/exploration_content_pack.gd:31` |
| 01-6 四路选择 | `hardware_foundations/selector4` / 四路择一 | 两位选择信号从D0-D3选一路；4选择×16数据=64组全对 | 不是选择项摆上去就自动增加延迟；不能对任意玩家结构断言一大截。 | `src/content/prologue/exploration_content_pack.gd:92` |
| 01-7 晚一拍 | `hardware_foundations/delay` / 晚一拍 | ACCEPT=1输出上次已接受的4位值；0保持；12步公开序列均正确，初始输出0 | 不是前项做完才做后项，也不是任意一帧/普通周期延迟；两寄存器同边界提交。 | `src/content/prologue/exploration_content_pack.gd:60` |
| 01-8 留住一瞬 | `hardware_foundations/alarm` / 留住一瞬 | 记录FAULT直至CLEAR，CLEAR优先；覆盖所有相邻输入状态的64步序列正确 | 按唯一关名映射alarm；内容却误写成最早存储/保持至少一拍，遗漏清除优先。此关依赖latch，不能放成latch的前课。 | `src/content/prologue/exploration_content_pack.gd:159`；`localization/game.zh_CN.po:5947` |
| 01-9 锁存器 | `hardware_foundations/latch` / SR 锁存器 | 设置、清除、保持1位状态；5步Q/NQ序列正确 | 这是SET/RESET反馈锁存器，不是“给之前记忆加门”；门控D/LOAD是下一寄存器。 | `src/content/prologue/storage_content_pack.gd:37` |
| 01-10 寄存器 | `hardware_foundations/register` / 一位寄存器 | D/LOAD控制一位写入与保持；5步Q正确，封装Register1并自动生成Register4 | 原稿8位、8格均错；当前制作1位，扩展4位；不因并排就推断更快。 | `src/content/prologue/storage_content_pack.gd:17`；`src/content/prologue/storage_content_pack.gd:78` |
| 01-11 RAM | `hardware_foundations/ram` / 2×4 RAM | 组合两个4位寄存器，按1位地址独立读写；5步地址切换、保持、改写全对 | 泛称很多格掩盖2×4规格；下一章才建模搬运，当前不应说每次拿有路程成本。 | `src/content/prologue/storage_content_pack.gd:125` |
| 01-12 ALU | `hardware_foundations/alu` / 一位 ALU | 操作码选择AND、OR、ADD、NOT；64组合中RESULT正确，ADD另核CARRY；生成ALU4 | 原稿“比较、选位”不是实际操作；“算得再快也快不过搬”不是普遍定理，提前给瓶颈结论。 | `src/content/prologue/arithmetic_content_pack.gd:83` |
| 01-13 CPU | `hardware_foundations/cpu` / 四位累加器 CPU | 把ALU4、Register4、RAM2x4和控制/选择接成小机器；7步指令中ACC与MEM均正确，来源绑定玩家模块 | 不是搭总线+时钟就完成；外部指令流，不能暗示自存程序取指或新时钟部件。 | `src/content/prologue/integration_content_pack.gd:25`；`src/content/prologue/integration_content_pack.gd:113` |
| 01-14 存取指令 | `hardware_foundations/load_store` / LOAD/STORE 桥接实验 | 在锁定拓扑复用自制CPU，观察读写；同7步公开序列ACC/MEM正确 | 不是从RAM取指；外部OP/ARG/ADDR输入；实际读写数据。 | `src/content/prologue/integration_content_pack.gd:83`；`src/content/prologue/integration_content_pack.gd:113` |
| 02-1 三器相连 | `chapter_1/assembly` / 三器相连 | 连接CPU、Bus、RAM请求/写入/读取六段路线；指定加1程序两正式案例均对，含255回绕0 | “中间那根线唯一碰到”误导三种通路；系统是8位简化模型，别混同序章4位。 | `src/system_lab/system_level_catalog.gd:278`；`src/system_lab/system_topology.gd:10` |
| 02-2 快慢之间 | `chapter_1/cpu_speed` / 快慢之间 | 先预测，记录Eco基线后只换Fast，比较计算与等待；同程序/RAM/Bus下两CPU完整正式记录均对 | 计算单步4→1，计算时间会减少，总时间也会减少；“总时间没有少/计算时间几乎没变”错且剧透。 | `src/system_lab/system_level_catalog.gd:172`；`src/system_lab/system_level_catalog.gd:245`；`src/system_lab/system_level_catalog.gd:282`；`localization/game.zh_CN.po:2273` |
| 02-3 等待什么 | `chapter_1/ram_wait` / 等待的来处 | 预测后只换RAM，比较等待；程序/CPU/Bus相同的slow/fast RAM完整正式记录 | 原稿误成纯标记等待位置观察关，漏控制变量对照。 | `src/system_lab/system_level_catalog.gd:172`；`src/system_lab/system_level_catalog.gd:291` |
| 02-4 宽窄之间 | `chapter_1/bus_width` / 宽窄之间 | 只换Bus，比较固定8位数据的传输分段；同程序/CPU/RAM两Bus正式记录 | 改变的是每周期带宽2→8 bit，不是数据字宽；成本不同但零件数不变。 | `src/system_lab/system_level_catalog.gd:266`；`src/system_lab/system_level_catalog.gd:300` |
| 02-5 一取再用 | `chapter_1/read_once` / 一取再用 | 固定机器，改程序计算每输入两倍和(mod256)；五用例输出正确，逐例memory_requests<=N+1 | 目标方向可用；应包括写回一次；后续不必进入所谓下一关，属可选支线。 | `src/system_lab/system_level_catalog.gd:317`；`src/system_lab/system_level_catalog.gd:412` |
| 02-6 循环寻因 | `chapter_1/bottleneck` / 循时寻因 | 执行4/16/64规模正式负载再据记录判断瓶颈；有效最新正式记录+与其诊断一致 | CSV次序把read_once放前；不可按位置映射；不保证一个位置解释全部空白，判断须绑定实际运行。 | `src/system_lab/system_level_catalog.gd:150`；`src/system_lab/system_level_catalog.gd:309` |
| 02-7 两张订单 | `chapter_1/two_orders` / 一笔预算，两张订单 | 分别为计算/搬运订单选件；两订单各有正式记录，硬件<=24，周期<=66/320 | 不是两并发请求排先后；两个独立机器配置问题；次序文案须弃用。 | `src/system_lab/system_level_catalog.gd:17`；`src/system_lab/system_level_catalog.gd:326`；`src/system_lab/system_level_catalog.gd:412` |
| 03-1 远取之累 | `chapter_2/distant_reads` / 远取之累 | 直接RAM运行，观察取数等待；有效运行+repeated_ram证据判断 | 本关没有近处对照；“量出远近差别”越界下一关。 | `src/locality_chapter/locality_level_catalog.gd:100`；`src/locality_chapter/locality_level_catalog.gd:274` |
| 03-2 留待再用 | `chapter_2/nearby_storage` / 留待再用 | 比较直接取数和自动Cache复用；direct记录+同时有miss/hit的Cache记录 | 不可暗示玩家手动放置/选择缓存内容；首次取回仍付搬运成本。 | `src/locality_chapter/locality_level_catalog.gd:111`；`src/locality_chapter/locality_level_catalog.gd:277` |
| 03-3 留不住什么 | `chapter_2/cache_failure` / 留不住的数据 | 固定列优先/一行Cache看淘汰；有效运行+replacement判断 | 玩家不制定淘汰规矩；固定LRU；规矩不会被下一关违反。 | `src/locality_chapter/locality_level_catalog.gd:100`；`src/locality_chapter/locality_level_catalog.gd:279` |
| 03-4 先后有序 | `chapter_2/access_order` / 先后有序 | 修改并应用循环访问次序；正式结果正确，<=105周期，row-first遍历 | 方向可用；不是改变物理距离，改变同一cache line的复用；明确Apply后才运行新程序。 | `src/locality_chapter/locality_level_catalog.gd:127`；`src/locality_chapter/locality_level_catalog.gd:282` |
| 03-5 容量有界 | `chapter_2/working_set` / 容量有界 | 固定容量观察两轮复用失效；有效运行+does_not_fit判断 | 本关观察判断，不能声称找到有限容量解决方案；解决分组在下一关。 | `src/locality_chapter/locality_level_catalog.gd:100`；`src/locality_chapter/locality_level_catalog.gd:284` |
| 03-6 分而复用 | `chapter_2/blocking` / 分而复用 | 调整工作分组，在局部数据尚在时完成两遍使用；正确，<=145周期，block_lines>0 | 不是改变每次硬件搬运批量；没有最优性证明，成功不能称最佳值。 | `src/locality_chapter/locality_level_catalog.gd:127`；`src/locality_chapter/locality_level_catalog.gd:287` |
| 03-7 循迹而行 | `chapter_2/capstone` / 循迹而行 | 记录基线、诊断、单因素实验，再组合优化；指定基线+repeated_far_fetch诊断+正确<=145周期 | 原稿只追踪解释，漏真实优化达标；不强迫第三章，3/4章为平行后继。 | `src/locality_chapter/locality_level_catalog.gd:127`；`src/locality_chapter/locality_level_catalog.gd:186`；`src/locality_chapter/locality_level_catalog.gd:289`；`src/campaign/task_navigation.gd:50` |
| 04-1 尚在途中 | `chapter_3/arrival` / 尚在途中 | 安排请求、独立工作、等待ready后消费；一批数据正确+work4完成+<=10周期 | 不是仅观察空闲；结算“机器什么也没干”与目标相反。 | `src/overlap_chapter/overlap_catalog.gd:22`；`src/overlap_chapter/overlap_catalog.gd:107` |
| 04-2 交接接力 | `chapter_3/buffers` / 交替接力 | 搭缓冲、安排装入/计算/重用；四批有效正确、成本<=2、<=28周期 | 目标就是搬运与计算重叠；结算“仍串行”错误；不能保证消除全部空档。 | `src/overlap_chapter/overlap_catalog.gd:22`；`src/overlap_chapter/overlap_catalog.gd:107` |
| 04-3 先行一步 | `chapter_3/prefetch` / 先行一步 | 在自动Cache中安排预取和读取；四批正确、成本<=1、<=28周期 | 按名称/机制映射，不按数组序号；提前搬并不必定多取一个无用数据。 | `src/overlap_chapter/overlap_catalog.gd:5`；`src/overlap_chapter/overlap_catalog.gd:22`；`src/overlap_chapter/overlap_catalog.gd:107` |
| 04-4 进退有度 | `chapter_3/backpressure` / 进退有度 | 按ready/free协调可变处理速度，避免覆盖；两个节奏用例均正确，<=28/32周期，成本<=2 | CSV3/4与实际顺序反转；错误必须为零，“错的数据少了很多”不可当通关结论。 | `src/overlap_chapter/overlap_catalog.gd:5`；`src/overlap_chapter/overlap_catalog.gd:22`；`src/overlap_chapter/overlap_catalog.gd:107` |
| 04-5 过犹不及 | `chapter_3/distance` / 过犹不及 | 有限容量中调整预取距离，避免未用先淘汰；正确且<=30周期，成本<=1；不重复搬运为额外目标 | 不是泛化保留/闸门松紧；避免将可选零重复提升必选。 | `src/overlap_chapter/overlap_catalog.gd:22`；`src/overlap_chapter/overlap_catalog.gd:107`；`src/overlap_chapter/overlap_catalog.gd:129` |
| 04-6 各行其时 | `chapter_3/synthesis` / 各行其时 | 自行选Buffer/Cache路径同时适应标准和带宽负载；两用例正确，<=28/33周期，成本<=2 | 不是数重叠周期；12和40→28只可作某条实测参考，非任意玩家成果；并行不保证必定缩短。 | `src/overlap_chapter/overlap_catalog.gd:22`；`src/overlap_chapter/overlap_catalog.gd:107` |
| 05-1 只取所需 | `chapter_4/fields` / 只取所需 | 保留全部字段/记录，为温度统计安排布局；两用例正确，读写流量<=64/96B | 不要暗示删字段或只请求几个字节即可；搬运按真实块计费。 | `src/layout_chapter/layout_catalog.gd:8`；`src/layout_chapter/layout_catalog.gd:43`；`src/layout_chapter/layout_catalog.gd:66` |
| 05-2 一窥全貌 | `chapter_4/records` / 一窥全貌 | 稀疏抽查记录，每条取全四字段，重新安排布局；两用例正确，读写流量<=64/96B | 原稿误解成看全局图/时间线；真实是整记录查询优化。 | `src/layout_chapter/layout_catalog.gd:9`；`src/layout_chapter/layout_catalog.gd:43`；`src/layout_chapter/layout_catalog.gd:66` |
| 05-3 搬迁有价 | `chapter_4/relocation` / 搬迁有价 | 一次查询和8次查询分别决定是否复制整理；两订单各方案正确，<=307/1400周期，scratch<=160B | 按标题机制映射；与hot_cold次序对调；包含源读取、写入和查询，不只重排。 | `src/layout_chapter/layout_catalog.gd:5`；`src/layout_chapter/layout_catalog.gd:43`；`src/layout_chapter/layout_catalog.gd:66` |
| 05-4 冷热有别 | `chapter_4/hot_cold` / 冷热有别 | 温度+告警频繁共同用，ID+电量偶尔抽查，安排字段分组；同一布局两用例正确且<=640周期 | 不是不同层级存储、冷热距离或两层代价；不要凭完成断言冷层慢很多。 | `src/layout_chapter/layout_catalog.gd:5`；`src/layout_chapter/layout_catalog.gd:10`；`src/layout_chapter/layout_catalog.gd:43`；`src/layout_chapter/layout_catalog.gd:66` |
| 05-5 化为零 | `chapter_4/batches` / 化整为零 | 48B临时空间内分批处理17记录，准确处理尾批；两用例正确、<=1100周期、peak scratch<=48B | 漏字误成“化为零”，整段变为零代价/不占空间，必须弃用重写。 | `src/layout_chapter/layout_catalog.gd:12`；`src/layout_chapter/layout_catalog.gd:43`；`src/layout_chapter/layout_catalog.gd:66` |
| 05-6 两全之策 | `chapter_4/mixed` / 两全之策 | 同一方案兼顾重复统计与稀疏整记录抽查；两用例正确、<=2450/1550周期，scratch<=160B；额外空间流量目标非门槛 | 不是三批数据各自策略；同一方案过两单。 | `src/layout_chapter/layout_catalog.gd:13`；`src/layout_chapter/layout_catalog.gd:43`；`src/layout_chapter/layout_catalog.gd:66` |

## 现有运行时叙事目录额外错误

- `src/ui/mission_narrative_catalog.gd:151` register action/reward 说“多位值”，当前亲手制作一位，随后自动扩四位。
- `src/ui/mission_narrative_catalog.gd:177` parity 中文“只能发现错了一位”过窄；正式规格 `localization/game.zh_CN.po:5930` 明确奇数位翻转都可发现、偶数位可能漏过。
- `src/ui/mission_narrative_catalog.gd:189` assembly “三条线”与 `system_topology.gd:10` 六段连线不符，应区分三种通路和六条线。
- `src/ui/mission_narrative_catalog.gd:229` access_order “怎么安排由你决定”需避免暗示任意顺序均可判过；实际判定绑定 row-first +105周期。保留解题空间并以公开任务规格为准。
- `src/ui/mission_narrative_catalog.gd:278` hot_cold “偶尔用的放远一点”可能暗示物理距离成本，实际是布局分组与取回块内有用字节。
- `src/ui/mission_narrative_catalog.gd:214` two_orders “没有一种配置能通吃”属于普遍化；当前任务证明两种需求应分别核验，而不证明所有任务不存在通用配置。

## 验证边界

本表为源码/正式用例/设计规范交叉核对，不构成40关原生通关或新手理解验收。参考 `docs/design/core-principles.md` 的零延迟连线、自动Cache、显式Apply、复用玩家模块以及当前1/4/8位模型边界。历史叙事方案只能提供审计线索，不代替本次源代码。
