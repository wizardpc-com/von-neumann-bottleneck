# 全旅程学习与操作审阅 · 2026-10-18

## 范围与读法

产品源码基线为`d14be32f81354eb062f38d39f860b16ff739921a`；本次完成度审阅从`e410cbe`交接检查点继续。依据附件手册§5B第134／144行，下面按实际60任务分别记录玩家决定、已有知识、成功判据与主要困难。这里的“已有知识”是理解所需概念，不新增解锁依赖；真正前置由原任务目录与模型合同决定。R＝规则理解，S＝策略选择，O＝操作／证据定位。

这是**逐任务源码语义盘点，不是60项实际解题、真人学习效果或OS验收**。每行“语境”链接定位该任务的双语呈现，“合同”链接定位原规格／判定入口；参数化合同仍以该行taskID选择，不从表中复制第二套阈值。原核心40＝序章14＋系统7＋局部性7＋时序6＋布局6；其余为表示5、服务3、可选地址预测3、C/P/G9。序章探索、系统应用等原有可选性不由“核心”计数改成必经。

身份来源：[原核心目录](../../src/campaign/task_navigation.gd#L17)、[第二阶段11项](../../src/campaign/second_act_tasks.gd#L6)、[创作9项](../../experiments/creation/catalog.gd#L3)。导出范围与真实验证等级见[当前F5证据](../verification/20261018-creation-connections/README.md)：完整176阶段、双包219／229父链与48项重启、测试者60实际入口分别只证明其实际范围，不证明60种最优解或新人理解；本轮原生因工具初始化阻断未验。

## 60项独立盘点

### 序章 · 14

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `hardware_foundations/tutorial` | 接通输入→NOT→输出，切输入、运行、拆线再重连 | 0/1、端口方向；无需先会造加法器 | 原任务五项实际操作均完成；NOT两种输入结果相反，灯灭可正确 | O：拖端口与拆重连；R：输入值不是通关灯号 | [语境](../../src/ui/mission_narrative_catalog.gd#L131) · [合同](../../src/hardware_foundations/hardware_foundations.gd#L8255) |
| `hardware_foundations/half_adder` | 用门把A+B拆成SUM与CARRY，选择接线后封装 | NOT/AND/OR/XOR及一位二进制加法 | 完整输入组合SUM/CARRY均符原规格，原官方验收通过后封装 | R：1+1的和位与进位；S：门组合而非指定唯一线法 | [语境](../../src/ui/mission_narrative_catalog.gd#L135) · [合同](../../src/hardware_foundations/hardware_foundations.gd#L6058) |
| `hardware_foundations/full_adder` | 把已有半加器和进位输入接成完整一位加法 | 已封装HalfAdder、SUM/CARRY、CIN含义 | A/B/CIN所有组合的SUM/COUT核验通过，原封装成立 | S：级联两次加法与合并进位；O：区分输入输出端口 | [语境](../../src/ui/mission_narrative_catalog.gd#L139) · [合同](../../src/content/prologue/arithmetic_content_pack.gd#L36) |
| `hardware_foundations/alu` | 用操作码选择逻辑或算术结果并接规定输出 | FullAdder、选择控制、多位数据与位宽 | 全部操作码案例输出/位宽正确，再按原流程封装 | R：控制位不同于数据位；S：共享数据通路的选择 | [语境](../../src/ui/mission_narrative_catalog.gd#L143) · [合同](../../src/content/prologue/arithmetic_content_pack.gd#L83) |
| `hardware_foundations/latch` | 安排反馈，使SET/CLEAR能写入而其他时刻保持状态 | 门电路反馈、前一步状态与当前输入 | 连续步骤的置位、清除和保持均符合原时序案例 | R：组合输出与保留状态；O：逐步运行而非只看末帧 | [语境](../../src/ui/mission_narrative_catalog.gd#L147) · [合同](../../src/content/prologue/storage_content_pack.gd#L37) |
| `hardware_foundations/register` | 用LOAD控制多位数据何时进入寄存器 | SRLatch、自制存储模块、受控写入 | LOAD开时写入、关闭后保持、再写入的完整序列通过 | S：保持路径与写入路径切换；O：多位端口对齐 | [语境](../../src/ui/mission_narrative_catalog.gd#L151) · [合同](../../src/content/prologue/storage_content_pack.gd#L78) |
| `hardware_foundations/ram` | 用地址选择与写控制组织多个可读写位置 | Register4、地址位与数据位、寄存器保持 | 各地址的写入、独立保持与读取均通过，不以最终一值代替全序列 | R：地址决定位置；S：写选通与读多路选择分开 | [语境](../../src/ui/mission_narrative_catalog.gd#L155) · [合同](../../src/content/prologue/storage_content_pack.gd#L125) |
| `hardware_foundations/cpu` | 把运算、寄存器、RAM与控制连成执行指令的机器 | 自制ALU4/Register4/RAM2x4、指令与状态变化 | 原指令序列的中间状态/结果与全部案例相符，封装来源有效 | S：控制/数据通路协作；O：较大电路的位宽与端口排查 | [语境](../../src/ui/mission_narrative_catalog.gd#L159) · [合同](../../src/content/prologue/integration_content_pack.gd#L25) |
| `hardware_foundations/load_store` | 使封装计算机按LOAD/STORE程序交换外部数据 | TinyComputer、地址/数据/读写控制 | 公开读写程序的地址、读值和写回均正确，桥接合同成立 | R：CPU内部运算与外部数据交换；O：原已接桥的测试次序 | [语境](../../src/ui/mission_narrative_catalog.gd#L163) · [合同](../../src/content/prologue/integration_content_pack.gd#L83) |
| `hardware_foundations/selector` | 用选择位控制A或B到同一输出 | 半加器之后的基本门组合、选择信号 | 全部A/B/选择位组合中输出严格等于被选输入 | S：两条互斥数据路径；R：选择位不是被选择的数据 | [语境](../../src/ui/mission_narrative_catalog.gd#L167) · [合同](../../src/content/prologue/exploration_content_pack.gd#L31) |
| `hardware_foundations/selector4` | 用两位选择信号选出四个来源之一 | 二选一结构、两位编码与位次 | 所有选择值和数据组合满足原四选一案例 | S：分层选择结构；O：选择位次序与多来源布线 | [语境](../../src/ui/mission_narrative_catalog.gd#L171) · [合同](../../src/content/prologue/exploration_content_pack.gd#L92) |
| `hardware_foundations/parity` | 由数据位与CHECK计算ERROR，判断奇偶不一致 | 半加器中的异或、奇偶规则 | 所有公开组合的ERROR正确；仅证明此校验规则而非任意纠错 | R：校验能发现的错误集合；S：异或链组织 | [语境](../../src/ui/mission_narrative_catalog.gd#L175) · [合同](../../src/content/prologue/exploration_content_pack.gd#L129) |
| `hardware_foundations/delay` | 在ACCEPT时输出上次接受值，暂停时保持 | Register4、接受事件与旧状态 | 连续接受/暂停案例的前值和保持全部正确，不按渲染帧计延迟 | R：一次接受与一次画面更新不同；S：旧值/新值存储 | [语境](../../src/ui/mission_narrative_catalog.gd#L179) · [合同](../../src/content/prologue/exploration_content_pack.gd#L60) |
| `hardware_foundations/alarm` | 让短暂FAULT留住报警，并按CLEAR清除 | Latch、状态保持、控制优先级 | 连续故障/保持/清除案例通过，FAULT与CLEAR同现按CLEAR优先 | R：优先级与保持；S：状态更新条件组合 | [语境](../../src/ui/mission_narrative_catalog.gd#L183) · [合同](../../src/content/prologue/exploration_content_pack.gd#L159) |

### 系统 · 7

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `chapter_1/assembly` | 接CPU、Bus与RAM的六条真实请求/读写路径 | LOAD/STORE桥接成果、请求/响应端口 | 有效拓扑下官方程序全部输出正确；连接图实际参与模拟 | O：接口/接线验证；R：连线本身不决定带宽 | [语境](../../src/ui/mission_narrative_catalog.gd#L187) · [合同](../../src/system_lab/system_level_catalog.gd#L278) |
| `chapter_1/cpu_speed` | 保持程序、RAM、Bus，换CPU做完整对照 | assembly、官方回执、控制变量 | 同程序/测试集/固定其他部件下两种CPU有效完整回执；选择但未运行不算 | S：控制变量；R：计算提速与总耗时不等价 | [语境](../../src/ui/mission_narrative_catalog.gd#L191) · [合同](../../src/system_lab/system_level_catalog.gd#L172) |
| `chapter_1/ram_wait` | 保持CPU/Bus和程序，比较另一种RAM的等待 | CPU对照、读请求、等待周期 | 相同固定条件下两种RAM完整官方回执；不能拿异条件旧记录凑数 | R：存储服务时间如何影响CPU等待；O：基线匹配 | [语境](../../src/ui/mission_narrative_catalog.gd#L195) · [合同](../../src/system_lab/system_level_catalog.gd#L291) |
| `chapter_1/bus_width` | 只更换Bus，观察分段搬运和传输周期 | RAM对照、数据量、总线带宽 | 同程序/CPU/RAM的两种Bus完整回执满足原对照合同 | R：数据分段与吞吐；O：部件Apply与实际重跑 | [语境](../../src/ui/mission_narrative_catalog.gd#L199) · [合同](../../src/system_lab/system_level_catalog.gd#L300) |
| `chapter_1/bottleneck` | 运行多规模负载后依据记录选择瓶颈判断 | 计算/等待/传输区别、前三项受控观测 | 有效官方运行后所选诊断等于该回执的实际瓶颈；猜测选择不作证据 | S：从不同规模事件归因；R：判断须绑定机器和负载 | [语境](../../src/ui/mission_narrative_catalog.gd#L203) · [合同](../../src/system_lab/system_level_catalog.gd#L150) |
| `chapter_1/read_once` | 改程序让一次load得到的数据复用而不改变结果 | RAM等待、循环/累加、寄存值复用 | 固定硬件全部输出正确，每案例请求数满足原上限；草稿须Apply后官方运行 | S：减少重复读取；R：输出正确与请求预算各自核对 | [语境](../../src/ui/mission_narrative_catalog.gd#L207) · [合同](../../src/system_lab/system_level_catalog.gd#L412) |
| `chapter_1/two_orders` | 分别为compute与move两订单选预算内机器 | 瓶颈诊断、成本/周期、不同工作负载 | 两种订单各有原预算和周期内有效回执；可用不同合法配置 | S：按需求折中而非一台通吃；O：订单切换与独立记录 | [语境](../../src/ui/mission_narrative_catalog.gd#L211) · [合同](../../src/system_lab/system_level_catalog.gd#L404) |

### 局部性 · 7

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `chapter_2/distant_reads` | 运行原访问，追查重复等待来自何处 | 系统bottleneck、RAM请求与Trace | 有效运行后提交repeated_ram判断；不是只点一次结论 | R：重复取数而非算术慢；O：事件/Notebook关联 | [语境](../../src/ui/mission_narrative_catalog.gd#L215) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L274) |
| `chapter_2/nearby_storage` | 对照直接取数与附近存储复用，解释第一次与后续读取 | distant_reads的直接回执、数据块重复利用 | 有直接取数记录及含miss和hit的非旁路记录；缓存由硬件管理 | R：先远取再近处复用；O：继承Before与当前记录区分 | [语境](../../src/ui/mission_narrative_catalog.gd#L219) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L111) |
| `chapter_2/cache_failure` | 观察Cache存在却每次仍远取的原因 | nearby_storage、hit/miss、容量与淘汰 | 有效运行并选replacement判断；当前控件不得解释旧回执 | R：Cache存在不保证复用；S：追踪复用前被替换的块 | [语境](../../src/ui/mission_narrative_catalog.gd#L223) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L279) |
| `chapter_2/access_order` | 改访问次序，保留计算含义并减少远取 | cache_failure的原Before、行列访问次序 | 本关有效row-first回执输出正确且周期不超公开目标；其他门槛沿原合同 | S：重排不漏算；O：Apply程序与对比Before | [语境](../../src/ui/mission_narrative_catalog.gd#L227) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L127) |
| `chapter_2/working_set` | 从重复计算和容量判断为何好次序仍重载 | row-first复用、Cache行与所需数据集合 | 有效观察后选does_not_fit；没有额外提速目标，不能把观察课标成性能失败 | R：同时需要的数据超过容量；O：Profiler命中/替换证据 | [语境](../../src/ui/mission_narrative_catalog.gd#L231) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L284) |
| `chapter_2/blocking` | 选择分块规模，使有限Cache中的数据及时复用 | working_set、重复遍历、分块覆盖范围 | 正block_lines的本关有效运行输出正确且满足公开周期目标 | S：块不能过大也不能漏算；R：工作集与分块关系 | [语境](../../src/ui/mission_narrative_catalog.gd#L235) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L127) |
| `chapter_2/capstone` | 基线诊断后综合次序、Cache和分块形成方案 | 前六项观测/优化、成本周期折中 | 本关原基线、正确诊断、达标回执三项均成立；economical为独立额外目标 | S：按证据选改动；O：基线/诊断解锁原顺序，非新增强制失败规则 | [语境](../../src/ui/mission_narrative_catalog.gd#L239) · [合同](../../src/locality_chapter/locality_level_catalog.gd#L146) |

### 时序 · 6

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `chapter_3/arrival` | 在请求后穿插独立工作，等ready再consume | 局部性收官、请求延迟、独立计算 | 所有案例状态/输出合法并达到公开周期目标，消费不能早于就绪 | R：ready因果；S：利用等待而非删等待 | [语境](../../src/ui/mission_narrative_catalog.gd#L243) · [合同](../../src/overlap_chapter/overlap_catalog.gd#L25) |
| `chapter_3/buffers` | 选择缓冲个数与装入/计算/复用排程 | arrival、缓冲生命周期、取数和处理重叠 | 全部案例输出正确、缓冲状态合法且周期达标；加元件不等于已交叠 | S：双缓冲排程；O：代码与电路/时间线对应 | [语境](../../src/ui/mission_narrative_catalog.gd#L247) · [合同](../../src/overlap_chapter/overlap_catalog.gd#L21) |
| `chapter_3/backpressure` | 根据变动处理时间协调生产和消费，避免覆盖 | buffers、ready/free、不同案例节奏 | standard与changing两案均合法达标，未释放缓冲不可重写 | R：所有权/释放；S：固定tick对变化负载不稳健 | [语境](../../src/ui/mission_narrative_catalog.gd#L251) · [合同](../../src/overlap_chapter/overlap_catalog.gd#L28) |
| `chapter_3/prefetch` | 提前请求后续地址，在Cache中等实际read | arrival、Cache、需求读取与预取区别 | 全部输出及周期目标通过，预取搬运的真实成本计入 | S：把请求提前但不过量；R：预取不是免费命中 | [语境](../../src/ui/mission_narrative_catalog.gd#L255) · [合同](../../src/overlap_chapter/overlap_catalog.gd#L30) |
| `chapter_3/distance` | 按计算节奏与容量调整预取提前量 | prefetch、Cache淘汰与在途请求 | 原完整案例合法且周期达标；无重复搬运额外目标不替代主通过 | S：来得早与留得住的折中；R：未用预取仍有成本 | [语境](../../src/ui/mission_narrative_catalog.gd#L259) · [合同](../../src/overlap_chapter/overlap_catalog.gd#L32) |
| `chapter_3/synthesis` | 在Buffer或Cache路线中自选结构与完整排程 | backpressure与distance、带宽和计算需求 | standard/bandwidth全部合法达标；两路线均有效，额外搬运目标独立 | S：跨负载稳定方案；R：不把参考结构当唯一答案 | [语境](../../src/ui/mission_narrative_catalog.gd#L263) · [合同](../../src/overlap_chapter/overlap_catalog.gd#L35) |

### 布局 · 6

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `chapter_4/fields` | 为只读温度查询重排字段，同时保留全部数据 | Cache行、字段/记录逻辑身份 | A/B输出正确且RAM总读写不超各自公开上限；不靠删字段降成本 | R：物理地址不同于逻辑记录；S：提高所需字段占比 | [语境](../../src/ui/mission_narrative_catalog.gd#L267) · [合同](../../src/layout_chapter/layout_catalog.gd#L48) |
| `chapter_4/records` | 为稀疏整条查询选择字段位置与记录布局 | fields、稀疏索引、完整记录输出 | A/B指定记录的四字段完整正确，均满足流量上限 | S：扫描最优未必适合点查；O：不同记录索引核对 | [语境](../../src/ui/mission_narrative_catalog.gd#L271) · [合同](../../src/layout_chapter/layout_catalog.gd#L56) |
| `chapter_4/hot_cold` | 把共同高频字段与低频抽查字段安排到合适组 | records、字段共用关系、分组/块 | 同一合法布局保留全部身份，A/B均满足公开周期合同 | S：冷热/共读折中；O：字段拖放和原方案身份 | [语境](../../src/ui/mission_narrative_catalog.gd#L275) · [合同](../../src/layout_chapter/layout_catalog.gd#L57) |
| `chapter_4/relocation` | 对一次与反复查询分别决定是否先复制整理 | fields、准备读/写与后续收益 | 两单各自方案输出/周期均达标，源读/准备/写入全部计费 | S：摊销是否值得；R：本关允许两单独立方案而非强迫相同 | [语境](../../src/ui/mission_narrative_catalog.gd#L279) · [合同](../../src/layout_chapter/layout_catalog.gd#L60) |
| `chapter_4/batches` | 在48B临时容量下选择批量并处理17条尾批 | relocation、临时峰值、整除与不足一批 | 两案记录不漏不重、输出/周期达标，临时空间不超原容量 | R：申请失败不等于已搬运；S：批量与峰值；O：尾批核验 | [语境](../../src/ui/mission_narrative_catalog.gd#L283) · [合同](../../src/layout_chapter/layout_catalog.gd#L61) |
| `chapter_4/mixed` | 用一套方案兼顾重复统计与稀疏整条抽查 | hot_cold/batches、全量和分批复制 | 同一方案A/B主合同均过；full与batch合法路线保留，额外空间/流量目标不挡通过 | S：跨订单折中；R：主目标与bonus分开 | [语境](../../src/ui/mission_narrative_catalog.gd#L287) · [合同](../../src/layout_chapter/layout_catalog.gd#L62) |

### 表示 · 5

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `representation/mixed_scan` | 对混合64B资产选划分和编码服务整段扫描 | 布局/搬运、编码复原、载荷与解码成本 | 原字节正确，整份存储与总周期同时满足本单公开合同 | S：压缩收益和解码开销；R：模型不只计压缩率 | [语境](../../src/ui/mission_narrative_catalog.gd#L291) · [合同](../../experiments/representation_region/catalog.gd#L25) |
| `representation/interior_hotspots` | 为重复内部点读选择块粒度/编码和缓存复用 | mixed_scan、块边界、点读复原范围 | 整份存储、时间、流量均达标；解码出但未请求的数据也计工作 | S：小请求与大块附带成本；O：内部地址事件定位 | [语境](../../src/ui/mission_narrative_catalog.gd#L295) · [合同](../../experiments/representation_region/catalog.gd#L25) |
| `representation/dense_sparse` | 让同一划分应对扫描与端点稀疏读取 | 前两任务、冷缓存和不同访问密度 | 两独立冷缓存订单各自达到公开存储/周期/流量合同 | S：不能只优化一单；R：两单缓存状态不共享 | [语境](../../src/ui/mission_narrative_catalog.gd#L299) · [合同](../../experiments/representation_region/catalog.gd#L25) |
| `representation/prepare_once` | 一次在线准备后服务短读和多次扫描 | dense_sparse、源读/编码/写入、摊销 | 共同准备成本加每客户冷服务成本全部计入，所有订单达标 | R：准备不是离线免费；S：短读与多次复用平衡 | [语境](../../src/ui/mission_narrative_catalog.gd#L303) · [合同](../../experiments/representation_region/catalog.gd#L25) |
| `representation/cross_assets` | 用相同划分/编码选择服务两份不同资产 | prepare_once、同方案跨数据分布比较 | 两公开资产的所有订单分别满足合同，不能只选好看结果 | S：避免对单一资产过拟合；O：资产与订单来源对应 | [语境](../../src/ui/mission_narrative_catalog.gd#L307) · [合同](../../experiments/representation_region/catalog.gd#L25) |

### 服务 · 3

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `service/move_state` | 调整请求分组和状态驻留，减少重复搬状态 | 同流历史/状态更新、搬运与驻留；表示/地址预测不是前置 | 同流保序、分数/最终状态精确，周期/状态读写/峰值合同均成立 | R：有状态服务不能任意重排；S：分组与驻留折中 | [语境](../../src/ui/mission_narrative_catalog.gd#L311) · [合同](../../experiments/service_plan/model.gd#L157) |
| `service/prompt_response` | 在总工作与每条流首次响应间安排服务顺序 | move_state合法已保存支持、每流先后关系 | 原结果仍精确，所有流的首响应及总周期均满足合同，不只看平均 | S：吞吐与公平响应；O：各流首响应见证定位 | [语境](../../src/ui/mission_narrative_catalog.gd#L315) · [合同](../../experiments/service_plan/model.gd#L157) |
| `service/one_plan` | 用同一方案协调驻留、表示质量和响应 | prompt_response已保存支持、误差与流量/时间指标 | 总周期/各流首响应/状态读写/真实误差逐项符合公开合同 | S：多约束同解；R：质量误差不能被吞吐优势抵消 | [语境](../../src/ui/mission_narrative_catalog.gd#L319) · [合同](../../experiments/service_plan/model.gd#L157) |

### 可选地址预测 · 3

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `prediction/regular` | 先记录Off基线，再选仅用已揭示历史的预测规则 | 预取、Cache、已揭示地址前缀；非内容预测P1 | 本临时会话有Off基线及确实消费预测数据的更快非Off记录 | R：未来地址不能喂给预测器；S：有用预取而非只发请求 | [语境](../../src/ui/mission_narrative_catalog.gd#L323) · [合同](../../experiments/prediction/lab.gd#L302) |
| `prediction/changed` | 让原规则面对规律变化，再选安全的非Off修订 | regular、浪费/污染、失效和基线区别 | 保留更慢且有浪费/污染的记录及不慢于基线的非Off修订 | S：识别规律失效；R：此可选调查的失效证据是原合同，非全游戏先失败门槛 | [语境](../../src/ui/mission_narrative_catalog.gd#L327) · [合同](../../experiments/prediction/lab.gd#L315) |
| `prediction/alternating` | 比较交替热点下不同预测规则与缓存影响 | changed、有限Cache、规则之间可比性 | 至少两种规则，并有慢且浪费/污染记录与不慢于基线非Off记录 | S：相邻规律与热点交替；O：本次临时记录离开丢弃 | [语境](../../src/ui/mission_narrative_catalog.gd#L331) · [合同](../../experiments/prediction/lab.gd#L315) |

### 内容压缩／预测／创造 · 9

| taskID | 玩家这次决定 | 所需已有知识 | 成功判据 | 主要R／S／O困难 | 源码锚点 |
| --- | --- | --- | --- | --- | --- |
| `creation/C1_restore` | 学习选定样例后发预测包，只靠包在接收端还原 | 符号样例、规则盒、RAW/预测包、无损相等 | 当前模型预测包无损还原；规则/修正可追溯，形成真实C1支持 | R：模型/规则也需交付；O：先学习再传输 | [语境](../../src/ui/mission_narrative_catalog.gd#L335) · [合同](../../experiments/creation/session.gd#L378) |
| `creation/C2_cost` | 固定原文/规则/机器，仅比较RAW与预测编码 | C1、头部/规则表/修正字节的完整计费 | 两份有效无损transport记录source/model/machine相同、codec不同；不要求预测包一定更小 | S：短文头部与规律收益；R：比较合同不等于节省合同 | [语境](../../src/ui/mission_narrative_catalog.gd#L339) · [合同](../../experiments/creation/session.gd#L411) |
| `creation/C3_conditions` | 固定原文/规则/codec，只换机器观察成本 | C2、机器参数、编码与执行条件区分 | 相同source/model/codec的两机器有效运行且实际成本不同；配送订单另行验收 | R：单元支持和临时配送分开；S：受控换机 | [语境](../../src/ui/mission_narrative_catalog.gd#L343) · [合同](../../experiments/creation/session.gd#L411) |
| `creation/P1_commit` | 对所选尚未揭晓片段，按公开前缀逐格先提交再揭晓 | 已学习规则、可见前缀、猜测与truth时间边界 | 当前模型非memorize完整commit/reveal轮结束；揭晓不暗中重学 | R：未揭晓truth不可见；O：提交/揭晓与完整轮次 | [语境](../../src/ui/mission_narrative_catalog.gd#L347) · [合同](../../experiments/creation/session.gd#L378) |
| `creation/P2_memory` | 只改记忆长度后重学，比较同材料/机器的整轮预测 | P1、上下文长度、重学产生新规则身份 | 同check/机器/训练样例而model.order不同的两轮有效预测形成比较支持 | S：记忆长度与区分能力；R：旧模型支持不冒充新准备 | [语境](../../src/ui/mission_narrative_catalog.gd#L351) · [合同](../../experiments/creation/session.gd#L411) |
| `creation/P3_check` | 用独立材料练习，再以冻结模型检查未见片段 | P1、训练/练习/检查划分、已见标识 | 完整check或check-v2非memorize轮形成P3支持；已见重查与首次检查明示区分 | R：不由检查truth反训规则；O：冻结检查来源追溯 | [语境](../../src/ui/mission_narrative_catalog.gd#L355) · [合同](../../experiments/creation/session.gd#L378) |
| `creation/G1_feedback` | 当前模型完成复原和预测准备后，把输出接回输入生成 | 当前模型C1式无损复原与整轮预测、seed/起始段 | 准备与当前模型身份匹配且真实生成；没有隐藏原文、正确率或审美分数 | R：创造不是预测隐藏标准答案；O：准备绑定原模型 | [语境](../../src/ui/mission_narrative_catalog.gd#L359) · [合同](../../experiments/creation/session.gd#L378) |
| `creation/G2_intent` | 带意图改一条件做受控对照，或直接Keep一件实际作品 | G1、seed/起始段/长度/机器、意图与可重复性 | 原受控设计记录按其合同比较；或真实Keep走独立保存合同，不能强迫先比较两次 | S：一条件变化；R：相同输出仍可有效，审美不评分 | [语境](../../src/ui/mission_narrative_catalog.gd#L363) · [合同](../../experiments/creation/session.gd#L378) |
| `creation/G3_keep` | 命名并保存当前实际输出，再区分查看/再生/分叉 | G1/G2中的真实输出、快照与完整recipe、保存身份 | 真实work含原output/recipe/training且Keep确认；回看原ID，不补造旧C/P历史 | O：保存和运行草稿分开；R：原作品不被后续编辑覆写 | [语境](../../src/ui/mission_narrative_catalog.gd#L367) · [合同](../../experiments/creation/session.gd#L378) |

## 代表操作入口与已存在的保护

1. 地图`hardware_foundations/tutorial`→手册NOT／AND／半加器：实际点击输入，读真值表，再Esc回原方案。[规则示例输入测试](../../tests/test_rule_practice_input.gd#L96)保护模型输出与原电路；三级Hint仍是方向→局部结构→明确参考，演示不替玩家接线。
2. `chapter_1/cpu_speed`：完整基线→只换CPU→再官方运行→原比较图／可选效率回顾。[下一行动](../../src/system_lab/system_lab.gd#L2577)区分缺运行、缺对照、缺规模及未达订单；[局部性原原因](../../src/ui/main.gd#L1447)另区分基线、诊断和target，不重造帮助框架。
3. `chapter_3/backpressure`／`synthesis`与`chapter_4/batches`／`mixed`：查看当前未满足谓词、原事件和差额，再按需请求Hint。[正反例与合法路线](../../tests/test_target_evidence_guidance.gd#L287)保留反向字段／full／batch、Buffer／Cache；[Layout反馈](../../src/layout_chapter/layout_chapter.gd#L387)与[Overlap案例结果](../../src/overlap_chapter/overlap_chapter.gd#L840)按原trace定位，草稿／board变更后旧行定位拒绝。无需为试不同合法答案先故意失败。
4. 地图“三组入口”→`creation/C1_restore`→`P1_commit`→`G1_feedback`→`G3_keep`：原Host中真实学习、无损传输、逐commit/reveal、生成与Keep；可选回顾读取本次观察，Saved只定位原Works ID。[不强迫先比较的真实Keep测试](../../tests/test_creation_choice_completion.gd#L92)与[原Session完整合同](../../experiments/creation/session.gd#L378)保持。普通新档仍按原模型／进度要求；测试者可进入不授予支持／完成。
5. 表示`prepare_once`和服务`prompt_response`：读取准备与逐客户成本、逐流响应／质量见证，再查超限条件。[表示证据提示](../../experiments/representation_region/region.gd#L642)与[服务逐谓词反馈](../../experiments/service_plan/lab.gd#L498)已承载这些说明；地址预测`prediction/*`始终是独立临时探索，不冒充内容预测P。

原R2分组表提出的系统缺证据提示及Overlap失败定位，后续已由现有下一行动与F4公开谓词／差额／定位实现，不再列为当前待开发项。正／失败／替代合法方案的现有模型与UI测试、导出controller实测分层保留；这张表没有新运行或重新认证全部60案例。`prediction/changed`／`alternating`中的失效记录、局部性capstone的基线／诊断是这些任务原有的教学合同，不把它们推广为所有玩家先失败或强制看Hint的通用门槛。

## 未证与人审边界

- 每个ID的动作、已有知识、判据和困难已按源码单列；实际目录和本表集合须完全相同。任务可用性、保存版本、普通／测试者、临时／持久成果仍由原代码验证，不以文档授予进度。
- 新人能否理解术语、是否需要补一个图示或改一句话，仍需实际观察；正式人物／CG／声线／结局、Mac与视频成片属于不同的人审／平台范围。不能把这些待审项当作60任务缺失或借本表推定学习效果。
- §6的真实状态保护须沿具体场景测试。当前Efficiency的同帧嵌入modal／延迟揭示边界另由总控安排有界实测；源码疑点只列候选，不在本表宣称已复现产品失败或扩张新框架。
