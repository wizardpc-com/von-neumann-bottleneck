class_name MissionNarrativeCatalog
extends RefCounted

const HARDWARE_PAGES := {
	&"selector4": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"exploration.selector4.description"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"exploration.selector4.spec"},
	],
	&"parity": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"exploration.parity.description"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"exploration.parity.spec"},
	],
	&"alarm": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"exploration.alarm.description"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"exploration.alarm.spec"},
	],

	&"selector": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"exploration.selector.description"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"exploration.selector.spec"},
	],
	&"delay": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"exploration.delay.description"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"exploration.delay.spec"},
	],
	&"tutorial": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.tutorial.1"},
		{&"title": &"hardware.briefing.stage.understand", &"body": &"hardware.briefing.tutorial.gates"},
		{&"title": &"hardware.briefing.stage.operations", &"body": &"hardware.briefing.tutorial.2"},
		{&"title": &"teaching.edit_title", &"body": &"teaching.edit"},
		{&"title": &"teaching.view_title", &"body": &"teaching.view"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.tutorial.3"},
	],
	&"half_adder": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.half_adder.1"},
		{&"title": &"hardware.briefing.stage.truth_table", &"body": &"hardware.briefing.half_adder.2"},
		{&"title": &"hardware.briefing.stage.modules", &"body": &"hardware.briefing.half_adder.3"},
		{&"title": &"teaching.branch_title", &"body": &"teaching.branch"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.half_adder.4"},
	],
	&"full_adder": [
		{&"title": &"hardware.briefing.stage.concept", &"body": &"hardware.briefing.full_adder.1"},
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.full_adder.2"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.full_adder.3"},
	],
	&"alu": [
		{&"title": &"hardware.briefing.stage.concept", &"body": &"hardware.briefing.alu.1"},
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.alu.2"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.alu.3"},
	],
	&"latch": [
		{&"title": &"hardware.briefing.stage.concept", &"body": &"hardware.briefing.latch.1"},
		{&"title": &"hardware.briefing.stage.understand", &"body": &"hardware.briefing.latch.2"},
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.latch.3"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.latch.4"},
	],
	&"register": [
		{&"title": &"hardware.briefing.stage.concept", &"body": &"hardware.briefing.register.1"},
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.register.2"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.register.3"},
	],
	&"ram": [
		{&"title": &"hardware.briefing.stage.concept", &"body": &"hardware.briefing.ram.1"},
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.ram.2"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.ram.3"},
	],
	&"cpu": [
		{&"title": &"hardware.briefing.stage.goal", &"body": &"hardware.briefing.cpu.1"},
		{&"title": &"hardware.briefing.stage.opcodes", &"body": &"hardware.briefing.cpu.2"},
		{&"title": &"hardware.briefing.stage.modules", &"body": &"hardware.briefing.cpu.3"},
		{&"title": &"hardware.briefing.stage.stages", &"body": &"hardware.briefing.cpu.4"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.cpu.5"},
	],
	&"load_store": [
		{&"title": &"hardware.briefing.stage.concept", &"body": &"hardware.briefing.load_store.1"},
		{&"title": &"hardware.briefing.stage.verify", &"body": &"hardware.briefing.load_store.2"},
	],
}

const SYSTEM_PAGES := {
	&"read_once": [&"system.level.read_once.description", &"system.level.read_once.objective"],
	&"two_orders": [&"system.level.two_orders.description", &"system.level.two_orders.objective"],
	&"assembly": [&"system.level.assembly.briefing.1", &"system.level.assembly.briefing.2"],
	&"cpu_speed": [&"system.level.cpu_speed.briefing.1", &"system.level.cpu_speed.briefing.2", &"system.level.cpu_speed.briefing.3"],
	&"ram_wait": [&"system.level.ram_wait.briefing.1", &"system.level.ram_wait.briefing.2", &"system.level.ram_wait.briefing.3"],
	&"bus_width": [&"system.level.bus_width.briefing.1", &"system.level.bus_width.briefing.2"],
	&"bottleneck": [&"system.level.bottleneck.briefing.1", &"system.level.bottleneck.briefing.2", &"system.level.bottleneck.briefing.3"],
}

const LOCALITY_PAGES := {
	&"distant_reads": [&"chapter2.level.distant_reads.briefing.1", &"chapter2.level.distant_reads.briefing.2"],
	&"nearby_storage": [&"chapter2.level.nearby_storage.briefing.1", &"chapter2.level.nearby_storage.briefing.2"],
	&"cache_failure": [&"chapter2.level.cache_failure.briefing.1", &"chapter2.level.cache_failure.briefing.2"],
	&"access_order": [&"chapter2.level.access_order.briefing.1", &"chapter2.level.access_order.briefing.2"],
	&"working_set": [&"chapter2.level.working_set.briefing.1", &"chapter2.level.working_set.briefing.2"],
	&"blocking": [&"chapter2.level.blocking.briefing.1", &"chapter2.level.blocking.briefing.2"],
	&"capstone": [&"chapter2.level.capstone.briefing.1", &"chapter2.level.capstone.briefing.2", &"chapter2.level.capstone.briefing.3"],
}


static func next_capability_key(chapter_id: StringName, level_id: StringName) -> StringName:
	var chapters: Dictionary = {
		&"hardware_foundations": HARDWARE_PAGES,
		&"chapter_1": SYSTEM_PAGES,
		&"chapter_2": LOCALITY_PAGES,
	}
	if chapters.has(chapter_id) and (chapters[chapter_id] as Dictionary).has(level_id):
		return StringName("experience.next.%s.%s" % [chapter_id, level_id])
	return &""


# Candidate dialogue is presentation only; callers retain completion authority.
static func introduction(english: bool) -> Dictionary:
	return {
		"title": "壹 · 留给后来者的程序" if not english else "Yi · A program for those who follow",
		"context": "我是壹。这套学习程序，留给愿意亲手理解系统的人。\n旧文明曾深深依赖强大的系统。它的过去，留待你慢慢发现；现在，你可以先检验一条简单的规则。" if not english else "I am Yi. This learning program is for anyone who wants to understand systems by working with them.\nThe old civilization depended deeply on powerful systems. Its past can wait. Begin by testing one simple rule for yourself.",
		"goal_title": "眼前的小目标 · 接通一条 NOT 电路" if not english else "Your first goal · Connect a NOT circuit",
		"goal": "从输入 A 的输出端拖线到 NOT 的输入端，再从 NOT 的输出端接到输出灯。切换输入并点运行：0 应得到 1，1 应得到 0。灯灭也可能是正确结果。" if not english else "Drag from input A's output to NOT's input, then connect NOT's output to the output lamp. Change the input and Run: 0 should produce 1; 1 should produce 0. An unlit lamp can be the correct result.",
		"operations": "进入后，按屏幕上的提示一步步做：接线、切换输入、运行、拆一条线、再接回去。" if not english else "The Mission tracks five real actions: connect, change an input, run, disconnect and reconnect. Reading or skipping this introduction does not complete the task.",
		"help": "目标与操作：任务台  ·  元件规则与图示：手册  ·  解题方向：Hint\n这段讯息可以从首页回看。" if not english else "Goal and controls: Mission  ·  Component rules and diagrams: Handbook  ·  Strategy: Hint\nReplay this message from Home whenever you wish.",
	}


static func completion_response(chapter_id: StringName, level_id: StringName, english: bool) -> String:
	return str(task_context(chapter_id, level_id, english).get("completion", ""))


# Authored context summarizes public contracts; it never evaluates a player plan.
# Rows contain action, verification and earned capability, each as a locale pair.
const TASK_CONTEXTS := {
	"hardware_foundations/tutorial": [
		"先接通输入、NOT与输出，再切换输入并运行。", "Connect input → NOT → lamp, toggle input, then run.",
		"完成任务台的接线、切换、运行、拆线、重连五项实际操作；NOT的0→1与1→0都正确。", "Finish all five tutorial actions; check NOT: 0→1 and 1→0.",
		"你亲手改变输入、运行并重新接通了电路。NOT反转信号：0 → 1，1 → 0；灯灭也可以是正确结果。", "You changed the input, ran and reconnected the circuit. NOT inverts: 0 → 1 and 1 → 0; an unlit lamp can be correct."],
	"hardware_foundations/half_adder": [
		"把两个一位输入相加，分别接出SUM与CARRY。", "Add two one-bit inputs and provide separate SUM and CARRY outputs.",
		"用完整测试核对输入组合、和与进位；封装仍按原验收进行。", "Run the full tests for every input combination, sum and carry. Sealing retains its existing validation.",
		"你的电路分别给出和与进位，1+1可以表示为SUM0、CARRY1；这份结构可以继续组合。", "Your circuit provides separate sum and carry: 1+1 becomes SUM0, CARRY1. This structure can take part in a larger machine."],
	"hardware_foundations/full_adder": [
		"让两路输入和上一位进位一起参与相加。", "Add both inputs together with the incoming carry.",
		"完整核对A、B、CIN到SUM、COUT的输入组合，不以某一组亮灯代替测试。", "Check all A/B/CIN combinations against SUM/COUT; one lamp pattern is not a full test.",
		"你把来自上一位的信息纳入计算，运算现在可以按位接续。", "You included information from the preceding bit, allowing arithmetic to continue across bit positions."],
	"hardware_foundations/alu": [
		"让控制信号选择运算，并把结果送到任务规定的输出。", "Use the control signal to choose an operation and deliver its specified output.",
		"核对任务中的操作码、结果与位宽，运行全部案例再封装。", "Check the specified opcodes, results and widths; run every case before sealing.",
		"同一条数据通路能服从不同操作码；计算的内容开始由控制决定。", "One data path now follows different opcodes; control determines which computation it performs."],
	"hardware_foundations/latch": [
		"构造能设置、清除并保持一个状态的电路。", "Build a circuit that sets, clears and holds a state.",
		"按连续输入步骤检查状态变化与保持，遵守任务给定的控制规则。", "Check state changes and holding across the input sequence, using the task's control rules.",
		"你让过去的输入留下可再次读取的状态，电路不再只回应眼前输入。", "Past input can now leave a readable state; the circuit responds to more than the current input alone."],
	"hardware_foundations/register": [
		"安排数据与LOAD控制，让多位值在需要时写入。", "Arrange data and LOAD control so a multi-bit value is written when required.",
		"核对写入、关闭LOAD后的保持以及下一次写入；使用全部时序案例。", "Check writes, holding with LOAD off and later writes across every sequence case.",
		"你把写入时机与数据值分开，多位信息可以稳定地等到下一次使用。", "You separated the write decision from the data value, so multi-bit information can wait for later use."],
	"hardware_foundations/ram": [
		"组合地址选择、写入控制与存储，按地址取回数据。", "Combine address selection, write control and storage to retrieve data by address.",
		"完整核对不同地址的写入、保持与读取，不能只检查最后一个输出。", "Check writes, holding and reads at different addresses, rather than only the final output.",
		"数据拥有了可寻址的位置，你可以保存不同内容并按地址重新取回。", "Data now has addressable locations; different contents can be stored and retrieved by address."],
	"hardware_foundations/cpu": [
		"把运算、状态和控制接成能按程序工作的机器。", "Connect arithmetic, state and control into a machine that follows a program.",
		"按任务指令序列核对中间状态与最终结果；临时测试参考不能替代自己的封装成果。", "Check intermediate states and final results through the instruction sequence. Tester references cannot replace your own earned components.",
		"你的部件开始按指令读取、计算并保存结果；接下来还可以追问数据何时到达。", "Your components now read, compute and store under instructions. You can next ask when their data arrives."],
	"hardware_foundations/load_store": [
		"让CPU通过LOAD和STORE与外部存储交换数据。", "Let the CPU exchange data with external storage through LOAD and STORE.",
		"运行公开的读写序列，核对地址、读值与写回结果。", "Run the public read/write sequences and check addresses, read values and stored results.",
		"计算与外部存储连在了一起；数据往返成为可以继续观察的过程。", "Computation is connected to external storage; the journey of data can now be examined."],
	"hardware_foundations/selector": [
		"用控制输入选择两路数据中的一路。", "Use a control input to select one of two data inputs.",
		"核对全部数据与选择位组合，输出必须来自被选中的输入。", "Check every data/selection combination; the output must follow the selected input.",
		"你让控制决定信息从哪里经过，同一输出可以接续不同来源。", "Control now determines which source reaches a shared output."],
	"hardware_foundations/selector4": [
		"按两位选择信号，把四路数据中的目标一路送到输出。", "Use two selection bits to route one of four data inputs to the output.",
		"完整测试所有选择值和数据组合，检查选择位次序。", "Test every selection value and data combination, including the selection-bit order.",
		"选择结构扩展到了四个来源；更大的选择仍由清楚的小规则组成。", "Selection now spans four sources, while remaining composed of precise small rules."],
	"hardware_foundations/parity": [
		"把数据与CHECK合起来判断奇偶校验是否出错。", "Combine the data and CHECK input to detect parity disagreement.",
		"完整核对所有组合的ERROR输出；校验只验证该奇偶规则，不承诺发现所有错误。", "Check ERROR across all combinations. Parity checks this rule; it does not detect every possible error.",
		"你用冗余信息检查了特定错误条件，也留下了这条检测规则的明确边界。", "You used redundant information to check a specific error condition, with a clear limit on what it detects."],
	"hardware_foundations/delay": [
		"让输出在接受新值时给出上一次已接受的数据；暂停接受时保持。", "On accepting new data, output the previously accepted value; hold when acceptance pauses.",
		"按连续ACCEPT序列检查前值与保持，包括连续接受和暂停；不是按画面帧数延迟。", "Check previous values and holding across consecutive accepts and pauses. This is not a delay measured in rendered frames.",
		"你把相邻两次接受分开，信息的先后关系成为了可验证的状态。", "You separated successive accepted values, making their order a verifiable state."],
	"hardware_foundations/alarm": [
		"让故障留下报警状态，并使CLEAR能清除报警。", "Let a fault retain an alarm state, with CLEAR able to reset it.",
		"按连续输入核对保持与清除；FAULT和CLEAR同时出现时按CLEAR优先。", "Check holding and clearing through sequences; CLEAR takes priority when FAULT and CLEAR occur together.",
		"短暂故障可以留下记录，又能按明确控制清除；记忆与响应有了分工。", "A brief fault can leave a record that is cleared by explicit control; memory and response have distinct roles."],
	"chapter_1/assembly": [
		"接通CPU、Bus和RAM的请求、写入与读取路径。", "Connect the request, write and read paths among CPU, Bus and RAM.",
		"可见线路必须形成有效拓扑，完整运行任务程序并核对输出。", "The visible wires must form a valid topology; run the full task program and check its outputs.",
		"你的计算部件与存储有了真实交换路径，之后的等待可以归到具体部件。", "Computation and storage now have real exchange paths, so later waiting can be attributed to modeled parts."],
	"chapter_1/cpu_speed": [
		"先记录指定程序的基线，再只改变CPU进行完整对照。", "Record a baseline for the specified program, then change only the CPU for a full comparison.",
		"两份有效回执须保持同一程序及其他部件；调试和未运行选择不增加对照。", "Two valid receipts must retain the same program and other parts. Debug runs and unrun selections add no comparison.",
		"你用受控实测区分了计算和等待；计算加速是否改变总时间，可以从自己的记录继续追查。", "Your controlled measurements separate computation from waiting; use those records to inspect how faster computation affects total time."],
	"chapter_1/ram_wait": [
		"保持程序与其他部件，比较RAM改变带来的等待差别。", "Hold the program and other parts fixed while comparing a RAM change.",
		"先有与当前固定条件匹配的基线，再记录另一种RAM的完整测试。", "First retain a baseline matching the current fixed conditions, then fully test another RAM part.",
		"你把存储服务的变化与CPU等待对应起来；来源仍是相同条件下的两份记录。", "You related storage service to CPU waiting using two observations under matching conditions."],
	"chapter_1/bus_width": [
		"固定程序和CPU、RAM，比较另一种Bus的传输过程。", "Fix the program, CPU and RAM while comparing another Bus's transfer behavior.",
		"完整对照有效Bus回执，检查传输阶段而非以画面线宽推断带宽。", "Compare valid full-test Bus receipts and their transfer phases; rendered wire width does not measure bandwidth.",
		"你验证了带宽如何改变数据分段搬运；连接关系与传输成本有了清楚区别。", "You verified how bandwidth changes segmented transfers, distinguishing connectivity from modeled transfer cost."],
	"chapter_1/bottleneck": [
		"运行指定工作负载，依据真实周期与等待记录作出瓶颈判断。", "Run the specified workloads and diagnose the bottleneck from measured cycles and waiting.",
		"有效观测后提交与该记录相符的判断；选择一个预测不等于得到诊断证据。", "After a valid observation, submit a diagnosis matching it. A prediction selection is not diagnostic evidence.",
		"你开始用记录解释限制来自哪里；结论有对应的机器与工作负载。", "You can explain where a limit arises, with the conclusion bound to its machine and workload."],
	"chapter_1/read_once": [
		"修改程序，让取回的数据得到需要的复用。", "Edit the program so fetched data receives the reuse the task needs.",
		"全部输出正确，并在固定硬件下满足每个案例的请求上限；应用草稿后再正式运行。", "Every output must be correct and every case must meet its request cap on fixed hardware; Apply before the official run.",
		"你用程序安排减少了不必要的请求，输出正确和搬运预算得到了分别核验。", "Your program avoided unnecessary requests while correctness and the transfer budget were checked separately."],
	"chapter_1/two_orders": [
		"分别为计算订单和搬运订单安排满足成本与时间限制的机器。", "Choose machines meeting time and cost limits for both the compute and move orders.",
		"两份不同订单均需有效达标记录；它们可以采用不同合法配置，重复一单不能代替另一单。", "Both distinct orders need qualifying receipts. They may use different valid configurations; repeating one cannot satisfy the other.",
		"你为不同需求作出了各自合适的取舍；一份机器配置不是所有订单的统一答案。", "You made trade-offs suited to distinct demands; one machine configuration need not answer every order."],
	"chapter_2/distant_reads": [
		"运行任务并观察相同数据为何反复经过RAM。", "Run the task and examine why the same data returns through RAM repeatedly.",
		"保留有效运行，再根据记录提交任务中的判断。", "Retain a valid run, then submit the task's judgment from that evidence.",
		"你从等待记录追到了重复取数，为之后的复用找到了可检验的起点。", "You traced waiting back to repeated fetching, giving reuse an observable starting point."],
	"chapter_2/nearby_storage": [
		"比较直接取数与Cache复用，观察命中和远取。", "Compare direct fetching with Cache reuse, observing hits and remote requests.",
		"记录任务要求的直接与复用观测；缓存由硬件规则管理，不能手放内容。", "Record the required direct and reuse observations. Hardware rules manage Cache contents; do not place them manually.",
		"你看见同一份数据可以在近处再次服务请求，复用不再只是一个名词。", "You observed nearby data serving later requests; reuse now has measured behavior."],
	"chapter_2/cache_failure": [
		"观察有Cache却仍然等待的运行，寻找对应的命中与淘汰记录。", "Inspect a run that still waits despite Cache, including its hit and eviction records.",
		"用有效运行支持任务判断；不要把当前控件当作旧回执的配置。", "Support the task judgment with a valid run; current controls do not describe an older receipt.",
		"你区分了拥有缓存与真正保留有用数据，失败的复用也成为可解释的证据。", "You distinguished having Cache from retaining useful data, making failed reuse explainable evidence."],
	"chapter_2/access_order": [
		"保持计算含义，改变访问次序并观察搬运。", "Preserve the computation while changing access order and observing transfers.",
		"完整运行，输出正确并满足本关公开周期目标；访问安排由你决定。", "Run the full test with correct output and the public cycle target; choose the access arrangement yourself.",
		"你改变的是数据到达计算的次序，结果含义保持不变。", "You changed the order in which data reaches computation while preserving the result's meaning."],
	"chapter_2/working_set": [
		"观察重复计算需要的数据与有限Cache如何相处。", "Observe how repeatedly needed data interacts with finite Cache capacity.",
		"用任务运行和记录支持工作集判断，不能只看Cache是否开启。", "Use the task's run and records to support a working-set judgment, beyond whether Cache is enabled.",
		"你把需要同时复用的数据与容量联系起来，能说明某些重复为何没有省下搬运。", "You related the data needed for reuse to capacity, explaining why repetition may still incur transfers."],
	"chapter_2/blocking": [
		"安排分块，让有限空间里的数据在离开前得到使用。", "Arrange blocks so data in finite space is used before it leaves.",
		"完整任务须输出正确并满足公开周期目标；分块不应漏算或改变计算。", "The full task must preserve correct output and meet the public cycle target; blocking must not omit or alter work.",
		"你把整体计算分成可复用的小段，同时保留了原来的计算结果。", "You divided the computation into reusable portions while retaining its original result."],
	"chapter_2/capstone": [
		"保留基线与诊断，再综合访问次序、Cache与分块形成自己的方案。", "Retain a baseline and diagnosis, then combine access order, Cache and blocking into your own plan.",
		"基线、判断和达标运行均依本关合同核验；原有合法取舍继续有效。", "Validate the baseline, judgment and target-meeting run under the existing contract; valid trade-offs remain accepted.",
		"你的方案把对限制的判断变成了实际安排；更进一步的改进仍可以与同条件记录比较。", "Your plan turned a diagnosis into a measured arrangement; further improvements can be compared under matching conditions."],
	"chapter_3/arrival": [
		"安排数据请求与独立工作，等数据就绪后再消费。", "Arrange a data request and independent work, consuming data only when ready.",
		"运行全部案例，既要状态与输出合法，也要达到公开周期条件。", "Run every case with valid state and output while meeting the public cycle condition.",
		"你让等待期间发生了独立工作，又保留了就绪再使用的因果次序。", "Independent work now occupies waiting time while readiness still precedes use."],
	"chapter_3/buffers": [
		"选择缓冲结构，协调装入、计算和再次使用。", "Choose a buffer structure and coordinate loading, computation and reuse.",
		"检查所有案例的输出、缓冲状态与周期；仅增加元件不会自动消除等待。", "Check output, buffer states and cycles for every case; adding parts alone does not remove waiting.",
		"你把数据的到达与处理安排成可以配合的两段工作。", "You coordinated data arrival and processing as two cooperating activities."],
	"chapter_3/backpressure": [
		"在不同处理节奏下协调生产和消费，避免覆盖仍被使用的数据。", "Coordinate production and consumption under changing processing times without overwriting live data.",
		"两份变化案例都须合法且达标；检查ready、释放和再次请求的实际次序。", "Both varying cases must be valid and meet their targets; inspect readiness, release and later requests in the actual sequence.",
		"你的安排能回应处理速度变化，反压保护了尚未完成的数据。", "Your arrangement responds to changing processing speed, with backpressure protecting unfinished data."],
	"chapter_3/prefetch": [
		"安排预取与实际读取，在有限缓存中准备稍后要用的数据。", "Arrange prefetches and demand reads to prepare later data in finite Cache.",
		"完整案例输出正确且达到周期目标，预取请求仍承担真实搬运成本。", "Full-case output must be correct and meet the cycle target; prefetches still incur modeled transfer costs.",
		"你把一部分请求提前发出，真实使用与提前搬运现在可以在时间线中对照。", "You issued some requests earlier; their later use can be compared with the advance transfers in the timeline."],
	"chapter_3/distance": [
		"按有限容量与工作节奏调整预取时机。", "Adjust prefetch timing to capacity and the pace of work.",
		"运行任务并检查周期与淘汰事件；提早搬来但未能用上的数据不是免费收益。", "Run the task and inspect cycles and evictions; early data that cannot be used is not a free gain.",
		"你把提早多久与能保留多久放在同一份证据里权衡。", "You weighed how early data arrives against how long it can remain available."],
	"chapter_3/synthesis": [
		"选择自己的Buffer或Cache路线，统筹搬运与计算。", "Choose your own Buffer or Cache route and coordinate transfers with computation.",
		"所有工作负载都须合法且达标；额外搬运目标与主通过分开，不强制一种参考结构。", "Every workload must be valid and meet its target. Extra transfer goals are separate; no reference structure is mandatory.",
		"你用一条经验证的路线协调了计算与搬运；其他合法结构仍值得继续探索。", "Your verified route coordinates computation and transfers; other valid structures remain open to exploration."],
	"chapter_4/fields": [
		"保留全部记录与字段，为只读取温度的查询安排布局。", "Keep all records and fields while arranging a layout for temperature-only queries.",
		"核对两单输出与公开RAM流量上限；不能靠删除无关字段降低成本。", "Check both outputs and public RAM-traffic caps; deleting other fields is not a valid cost reduction.",
		"你让需要的数据在搬运中占据更多有用位置，同时保留了完整记录。", "More of each transfer now serves the query while complete records remain intact."],
	"chapter_4/records": [
		"面向稀疏整条抽查，重新安排四个字段的位置。", "Reconsider field placement for sparse queries that inspect whole records.",
		"两单都须返回被指定记录的全部字段并满足流量条件。", "Both cases must return every field of the requested records and meet their traffic conditions.",
		"你看见上一种查询的好布局不一定适合另一种访问需求。", "You verified that a layout suited to one query may not suit a different access pattern."],
	"chapter_4/hot_cold": [
		"让频繁共同读取的字段与偶尔抽查的字段各有合适位置。", "Arrange frequently co-read fields and occasionally inspected fields to suit their access patterns.",
		"同一布局保留全部身份和字段，并在两份查询中满足周期合同。", "One layout must retain all identities and fields and meet cycle contracts for both queries.",
		"你把访问频率和共同使用关系转化成了布局取舍。", "You translated access frequency and co-use into a layout trade-off."],
	"chapter_4/relocation": [
		"分别判断一次查询与反复查询是否值得先复制整理。", "Decide separately whether one query and repeated queries justify copying first.",
		"两单各自的合法方案都须达标；源读、整理和写入成本全部计入。", "Each order's own valid design must meet its target, including source reads, preparation and writes.",
		"你把准备成本与后续服务放在一起比较，而非把复制当成免费步骤。", "You compared preparation with later service, rather than treating copying as free."],
	"chapter_4/batches": [
		"在有限临时空间里分批完成任务，准确处理最后不足一批的数据。", "Complete the task in bounded scratch space, correctly handling a partial final batch.",
		"每轮不漏算、不重复；两单输出、周期和临时峰值均须符合公开限制。", "Count each record exactly once per query; both cases must meet output, cycle and peak-scratch limits.",
		"你让超出临时空间的工作逐批完成，尾批仍遵守原来的记录含义。", "You completed work larger than scratch space in batches, preserving record meaning through the tail batch."],
	"chapter_4/mixed": [
		"用同一方案兼顾反复统计与稀疏整条抽查。", "Use one design for repeated scans and sparse whole-record inspections.",
		"两单输出与主合同都须通过；可选空间和流量目标不挡主通关。", "Both cases must meet output and main-contract conditions; optional space and traffic goals do not gate completion.",
		"你为两类访问找到了共同可用的安排，空间与流量还可以作为不同的改进方向。", "You found one arrangement usable by both access patterns; space and traffic remain distinct directions for further improvement."],
	"representation/mixed_scan": [
		"选择分块和编码，让混合资产的完整扫描满足合同。", "Choose partitions and encodings that serve a complete mixed-asset scan under its contract.",
		"实测整份存储与总周期，解码工作和被搬运的载荷均计入。", "Measure whole-asset storage and total cycles, including decoding work and transferred payload.",
		"你把信息的表示方式纳入成本比较，同时保留原字节内容。", "You included representation in the cost trade-off while preserving the original bytes."],
	"representation/interior_hotspots": [
		"为重复内部点读安排分块、编码和缓存复用。", "Arrange partitioning, encoding and Cache reuse for repeated interior reads.",
		"同时满足整份存储、周期和流量合同；还原但未被请求的字节也有成本。", "Meet storage, cycle and traffic contracts together; restored but unrequested bytes still cost work.",
		"你让表示与实际请求位置配合，能把有用字节与附带工作分开观察。", "You matched representation to requested locations and distinguished useful bytes from incidental work."],
	"representation/dense_sparse": [
		"用同一划分服务完整扫描与重复端点读取。", "Use one partition for a full scan and repeated endpoint reads.",
		"两份订单从冷缓存开始，各自都满足公开限制。", "Both orders start with cold Cache and must independently meet their public limits.",
		"你为密集与稀疏两种需求保留了同一份可用表示。", "One usable representation now serves both dense and sparse access."],
	"representation/prepare_once": [
		"比较准备一次后服务短读与多次冷扫描的安排。", "Arrange one preparation phase to serve a short read and multiple cold scans.",
		"准备源读、编码、写入和后续服务均计入；每位客户从冷缓存开始。", "Count preparation reads, encoding, writes and later service; each client starts with cold Cache.",
		"你把一次准备与后续复用放进了同一成本账本，服务加速有了完整来路。", "You accounted for preparation and later reuse together, including the cost behind faster service."],
	"representation/cross_assets": [
		"让同一划分与编码选择服务两份不同资产和各自订单。", "Use the same partition and encoding choices for two distinct assets and their orders.",
		"同一方案在两份公开资产上都须满足各项合同，不能只展示其中一单。", "One plan must meet every contract on both public assets; showing only one order is insufficient.",
		"你的表示选择经受了另一份资产的检验，取舍不再只适用于一段数据。", "Your representation choices survived a second asset, extending the trade-off beyond one data sample."],
	"service/move_state": [
		"安排分组与状态驻留，让历史服务后续请求。", "Arrange grouping and state residency so history serves later requests.",
		"同流保序，分数与最终状态精确，并满足周期、状态读写和峰值合同。", "Preserve within-stream order, exact scores and final states, and meet cycle, state-traffic and peak-memory contracts.",
		"你保留并重新使用了会变化的状态，记录证明了正确性与搬运的取舍。", "You retained and reused changing state, with measured correctness and transfer trade-offs."],
	"service/prompt_response": [
		"在有限资源中兼顾总工作与每条流的首次响应。", "Balance total work and each stream's first response under finite resources.",
		"同流顺序和精确结果仍有效，每条流都须满足首响应及总周期合同。", "Retain stream order and exact results; every stream must meet the first-response and total-cycle contracts.",
		"你把谁先等到结果纳入了系统安排，总吞吐不再是唯一观察。", "You included who receives a result first in the system arrangement, beyond aggregate throughput."],
	"service/one_plan": [
		"用同一服务方案同时处理时间、状态流量与质量要求。", "Use one service plan to meet timing, state-traffic and quality requirements together.",
		"按公开合同核对总周期、各流首响应、状态读写和真实误差。", "Check total cycles, every first response, state traffic and actual errors under the public contract.",
		"你用一份经验证的方案连接了服务编排、表示成本与质量边界。", "One verified plan now connects service scheduling, representation cost and quality limits."],
	"prediction/regular": [
		"先记录关闭猜测的基线，再观察仅靠已揭示历史能否提前搬来有用数据。", "Record an Off baseline, then explore whether revealed history can support useful advance transfers.",
		"本次记录须包含基线与实际消费了预测数据、且比基线更快的非关闭规则。", "This session needs an Off baseline and a faster non-Off rule whose predicted data was actually consumed.",
		"本次调查留下了有用地址预测的实测记录；它只属于当前临时会话。", "This investigation has measured useful address prediction, within the current temporary session only."],
	"prediction/changed": [
		"观察规律改变后，原预测如何影响等待与流量，再修订规则。", "Observe how a changed pattern affects prediction, waiting and traffic, then revise the rule.",
		"保留更慢且有浪费或污染的记录，再保留不慢于基线的非关闭修订；关闭不算安全修订。", "Retain a slower record with waste or pollution and a non-Off revision no slower than baseline; Off is not the safe revision.",
		"本次调查把失效与修订都留成证据；规则并未因此获得读取未来的能力。", "This investigation retains failure and revision as evidence; the rule has not gained access to future requests."],
	"prediction/alternating": [
		"在交替热点和有限缓存中比较不同规则的效果。", "Compare rules under alternating hotspots and finite Cache.",
		"比较不同规则，保留慢且有浪费或污染的例子和不慢于基线的非关闭记录。", "Compare distinct rules, retaining a slower waste/pollution example and a non-Off record no slower than baseline.",
		"你在本次会话中看见预测与缓存相互影响；离开后这些临时记录不会成为永久进度。", "You observed prediction and Cache interacting in this session; these temporary records do not become permanent progress after departure."],
	"creation/C1_restore": [
		"学习选定样例，发送预测包并核对接收端复原。", "Learn the selected examples, send a predictive packet and check receiver restoration.",
		"接收端只拿到这个包，也要把原文一格不差地还原出来。", "The receiver must restore exactly using only the packet, with rules and actual corrections traceable in the records.",
		"规律加上例外，信息完整地到了另一头——不是看起来像，而是真的一样。", "Rules and exceptions delivered the information, preserving the actual contents rather than an approximate appearance."],
	"creation/C2_cost": [
		"固定原文与条件，比较RAW和预测包的真实大小。", "Fix the source and conditions while comparing actual RAW and predictive packet sizes.",
		"规则本身、包头和修正都要算进大小；有时候压缩包反而更大。", "Count rules, headers and corrections while retaining exact restoration; a predictive packet is not guaranteed smaller.",
		"你发现：写下规律也要花地方。", "You counted the rules themselves as information cost, including the price of representation."],
	"creation/C3_conditions": [
		"保持原文、规则与路径，换机器比较成本；配送订单可另行尝试。", "Keep source, rules and codec fixed while changing the machine; delivery orders are separate options.",
		"只换机器、别的都不动，比较哪台更划算。", "This unit validates a controlled machine comparison; delivery deadlines and their records have separate session contracts.",
		"同一种写法，放在不同机器上代价不同。你把「换机器」和「换写法」分开看了。", "The same representation has different machine costs; you separated condition changes from encoding choices."],
	"creation/P1_commit": [
		"接到未见输入，先提交一格预测再揭晓，并完成整轮。", "Connect sealed input, commit one prediction before revealing it, then finish the full round.",
		"每一格都要先猜、再揭晓，整轮做完才算数；揭晓的答案不会偷偷拿去学习。", "Predict from the revealed prefix only. Complete the current model's commit/reveal round; revealing does not secretly train it.",
		"先说出你的猜测，再看答案——对和错都清清楚楚。", "You separated a prior commitment from later knowledge, giving both correct and incorrect predictions a clear time boundary."],
	"creation/P2_memory": [
		"改变记忆长度并重新学习，在同材料与机器上比较预测。", "Change history length and relearn, comparing predictions on matching material and machine.",
		"改了记忆长度就要重新学习，再用新规则完整预测一轮。", "Record context differences and actual rounds for these rules; old-model records do not prepare a new model.",
		"记得越多，能分辨的情况越多，但规则也会变多。", "You related retained history to distinguishable contexts, including the cost of the additional rules."],
	"creation/P3_check": [
		"先用独立材料练习，再带着冻结规则检查未见片段。", "Practice separately, then check an unseen passage with frozen rules.",
		"练习归练习；检查时规则冻结，只看它没见过的片段。", "Distinguish practice, frozen checks and seen repeats; explain results from revealed cells only.",
		"你看到了规则面对陌生内容时的真实表现，包括它不确定的地方。", "You retained the model's behavior on a passage it had not trained on, including exceptions and uncertainty."],
	"creation/G1_feedback": [
		"当前模型完成无损复原和整轮预测后，把输出接回输入并生成。", "After this model restores exactly and finishes prediction, feed its output back and generate.",
		"先让这套规则能复原、能预测，再把输出接回输入。这里没有标准答案。", "The current model's preparation must be real. Generation has no hidden original or accuracy score, and appearance does not decide acceptance.",
		"同一套有限的规则，开始接着自己的输出往下写。", "The same rules now extend their own output: generation by a finite model, not proof of general intelligence."],
	"creation/G2_intent": [
		"带着自己的意图改变条件；可做受控对照，也可确认保留一件作品。", "Change conditions with an intention; try a controlled comparison or explicitly keep a chosen work.",
		"想比较时只改一个条件；想直接留下也可以。", "Controlled design fixes seed, start, length and machine while changing one condition. Direct Keep follows its own contract and does not require comparison first.",
		"你的选择成了作品的一部分。好不好看，不由分数决定。", "Your choice becomes part of the work; identical output can still be a valid observation, without turning taste into a score."],
	"creation/G3_keep": [
		"给实际输出命名并确认保存，再选择观看、再生或分叉。", "Name real output and confirm Keep, then choose viewing, regeneration or forking.",
		"给它起个名字，保存下来；以后可以回看，也可以照原配方重新生成。", "Retain the actual snapshot and complete recipe; replaying saved work differs from running the current draft.",
		"这是你留下的作品。以后再怎么改，这一次都会保留。", "You kept a work that can be viewed and replayed from its original recipe; later edits do not rewrite this choice."],
}

const DOMAIN_CONTEXTS := {
	"hardware_foundations": ["我留下规则，让你亲手决定信号如何成为机器。", "I leave the rules so you can decide how signals become a machine.", "从组合规则到保存状态，再把它们接成自己的机器；支线可以独立探索。", "Combine rules, retain state, then compose your machine; side routes remain independent.", "先查端口方向与位宽，再看测试台中首个不符的输入、输出或时序。Hint仍按原层级提供。", "Check port direction and width, then inspect the first mismatching input, output or step in Test Bench. Hint retains its existing levels.", "语境候选；原任务规格、真实测试与自制成果来源保持权威。", "Candidate context; task specifications, real tests and earned component provenance remain authoritative."],
	"chapter_1": ["机器已经接通；现在，试着解释它把时间花在哪里。", "The machine is connected; now investigate where its time goes.", "用同条件实测区分计算与搬运，再把观察带到复用与访问安排。", "Separate computation and transfers under matching conditions, then carry that observation into reuse and access arrangement.", "分开检查输出正确、正式程序身份、基线与对照是否齐全；具体缺失以任务台与原回执为准。", "Check correctness, official program identity, matching baseline and comparison evidence separately; Mission and original receipts identify what is missing.", "结论对应已运行的机器与程序，当前未运行控件不重写旧记录。", "Conclusions belong to the measured machine and program; unrun controls do not rewrite older records."],
	"chapter_2": ["如果数据还会再用，怎样安排它与计算相遇？", "If data will be used again, how should it meet computation?", "容量、次序与分块相互配合；之后还可以安排搬运发生的时机。", "Coordinate capacity, order and blocking, then explore when transfers take place.", "先区分尚未运行、判断未成立和性能未达标，再查命中、淘汰与RAM请求。缓存内容由模型管理。", "Distinguish a missing run, unsupported judgment and unmet target; inspect hits, evictions and RAM requests. The model manages Cache contents.", "以任务公开合同为准；改方案不会重新解释旧回执。", "The public task contract governs; editing does not reinterpret old receipts."],
	"chapter_3": ["等待可以容纳别的工作，但先后关系仍需要你安排。", "Waiting can contain other work, but you still arrange the causal order.", "从到达、就绪与消费走向完整编排；有效的Buffer和Cache路线都保留。", "Move from arrival, readiness and consumption to full coordination; valid Buffer and Cache routes remain available.", "先查当前案例的状态错误或周期差额，再在时间线定位请求、就绪、消费、释放与淘汰。", "Check the current case's state error or cycle gap, then locate requests, readiness, consumption, release and eviction in the timeline.", "普通连线只有连接含义；时间与成本来自被建模的部件和事件。", "Ordinary wires express connectivity; modeled parts and events own time and cost."],
	"chapter_4": ["同一份信息，可以因放置方式不同而需要不同的搬运。", "The same information can require different transfers depending on placement.", "从原始布局到有价的复制与有限分批，再问表示本身能否改变成本。", "Move from native layout to paid copying and bounded batches, then ask how representation changes cost.", "先查记录身份与尾批，再对照准备读写、总流量、总周期与临时峰值；不同订单各有合同。", "Check record identity and tail batches, then preparation traffic, total cycles and peak scratch; orders retain their own contracts.", "不能删记录换成绩；准备不是免费，可选目标不代替主合同。", "Do not remove records to improve a score; preparation is not free and optional goals do not replace the main contract."],
	"representation": ["改变承载方式，也要把恢复信息付出的工作算进去。", "Change how information is carried while accounting for the work needed to recover it.", "表示服务实际请求；同一资产、不同订单与在线准备的成本分别对照。", "Representations serve actual requests; compare assets, orders and online preparation in their proper scopes.", "查看原结果中逐单超限项目与事件；分开读存储、载荷、请求、解码、准备和缓存，勿只看压缩率。", "Inspect per-order limit failures and events; separate storage, payload, requests, decoding, preparation and Cache rather than reading only a compression ratio.", "候选有限模型；本阶段合同与原核心、服务阶段各自独立。", "Bounded candidate model; this stage retains contracts separate from the original core and Service."],
	"service": ["历史不仅要留下来，还要在别人等待时及时派上用场。", "History must be retained and become useful while someone is waiting.", "从留住状态到公平响应，再将表示与误差纳入同一服务安排。", "Move from retaining state to timely responses, then include representation and error in one service plan.", "查看每条流首响应、状态重新载入、写回和质量见证；正确性、流量、时间与误差分别核对。", "Inspect each first response, state reload, writeback and quality witness; check correctness, traffic, time and error separately.", "候选服务合同；同流保序与真实状态计算不可被呈现跳过。", "Candidate service contract; presentation cannot bypass stream order or actual state computation."],
	"prediction": ["从已经发生的历史猜下一步，也需要保留猜错后的代价。", "Predict from observed history while retaining the cost of being wrong.", "这是可选地址预测，与之后对光纹内容的逐格预测不同。", "This optional address prediction differs from later cell-by-cell prediction of signal content.", "回看预测发出时已知的历史、后续真实请求、未使用搬运与污染；不要用未揭示的地址选规则。", "Inspect history known at issue time, later demand, unused transfers and pollution; do not choose rules from unrevealed addresses.", "仅本次临时会话；离开丢弃观察，不写成永久成长或必经门槛。", "Temporary session only; departure discards observations, without permanent growth or a mandatory gate."],
	"creation": ["同一套有限规则，可以复原、预测，也可以接续你选择的下一段。", "The same finite rules can restore, predict and extend a passage you choose.", "压缩→内容预测→创造使用同一模型；早期电路是构造来路，不冒称执行这些算法。", "Compression → Content prediction → Creation share a model; earlier circuits provide construction provenance, not execution of these algorithms.", "先查当前模型是否已学习、无损复原及整轮预测是否成立；改记忆或样例后重新准备。作品仍按原快照和配方回看。", "Check learning, exact restoration and full prediction for the current model; re-prepare after changing examples or history. Saved work remains bound to its original snapshot and recipe.", "有限模型候选；无通用智能或意识结论，作品与审美选择不以虚构分数替代。", "Bounded candidate model, without general-intelligence or consciousness claims; real works and aesthetic choices are not replaced by invented scores."],
}


static func task_context(chapter_id: StringName, level_id: StringName, english: bool) -> Dictionary:
	var key: String = "%s/%s" % [chapter_id, level_id]
	if not TASK_CONTEXTS.has(key) or not DOMAIN_CONTEXTS.has(String(chapter_id)): return {}
	var row: Array = TASK_CONTEXTS[key]
	var domain: Array = DOMAIN_CONTEXTS[String(chapter_id)]
	var language: int = 1 if english else 0
	return {"task_id": key, "intent": domain[language], "action": row[language],
		"verify": row[2 + language], "completion": row[4 + language],
		"connection": domain[2 + language], "failure": domain[4 + language], "scope": domain[6 + language]}
