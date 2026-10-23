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
		{&"title": &"teaching.edit_title", &"body": &"teaching.edit"},
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
		{&"title": &"teaching.view_title", &"body": &"teaching.view"},
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
		"context": "我是壹。我曾参与重建你所在的文明。\n现在，我想把理解它的办法交给你。先接一条线路，看看你的操作怎样改变结果。" if not english else "I am Yi. I helped rebuild the civilization you live in.\nNow I want to share how it works. Connect a circuit and see how your actions change its result.",
		"goal_title": "眼前的小目标 · 接通一条 NOT 电路" if not english else "Your first goal · Connect a NOT circuit",
		"goal": "从输入 A 的输出端拖线到 NOT 的输入端，再从 NOT 的输出端接到输出灯。切换输入并点运行：0 应得到 1，1 应得到 0。灯灭也可能是正确结果。" if not english else "Drag from input A's output to NOT's input, then connect NOT's output to the output lamp. Change the input and Run: 0 should produce 1; 1 should produce 0. An unlit lamp can be the correct result.",
		"steps": [
			["看目标", "先看任务台的目标与步骤；任务规格说明输入、输出和通过条件。"],
			["放元件，接线路", "首关元件已摆好，先从输出端拖线到输入端；后续从元件台选件搭建。"],
			["调试，再完整测试", "切换输入看结果，再运行完整测试。首关跟着步骤卡完成接线、切换、运行、拆线和接回。"]
		] if not english else [
			["Read the goal", "Mission shows the goal and steps. Task specifications explain inputs, outputs and passing conditions."],
			["Place parts and connect", "The first task has its parts ready. Drag from an output port to an input port; use the component tray to build later circuits."],
			["Debug, then test", "Change an input and inspect the result, then run the full tests. Follow the first task's five actions: connect, change, run, disconnect and reconnect."]
		],
		"help": "卡住：F1 / Hint 看解题线索  ·  概念与元件图示：手册\n任务规格查本关要求，旅程地图选任务。这段讯息可从首页回看；阅读或跳过不会完成关卡。" if not english else "Stuck? F1 / Hint offers clues. Handbook explains concepts and components.\nTask specifications show requirements; Journey map selects tasks. Replay this message from Home. Reading or skipping it does not complete a task.",
	}


static func completion_response(chapter_id: StringName, level_id: StringName, english: bool) -> String:
	return str(task_context(chapter_id, level_id, english).get("completion", ""))


# Authored context summarizes public contracts; it never evaluates a player plan.
# Rows contain action, verification and earned capability, each as a locale pair.
const TASK_CONTEXTS := {
	"hardware_foundations/tutorial": [
		"先接通输入、NOT与输出，再切换输入并运行。", "Connect input → NOT → lamp, toggle input, then run.",
		"按步骤卡做完五步：接线、切换输入、运行、拆一条线、再接回去。", "Finish all five tutorial actions; check NOT: 0→1 and 1→0.",
		"线路接错了还能重来。NOT 将 0 → 1、1 → 0；先猜灯会怎样，再运行核对。", "You can reconnect and try again. NOT maps 0 → 1 and 1 → 0. Predict the lamp, then run to check."],
	"hardware_foundations/half_adder": [
		"计算 A+B：SUM 接个位，CARRY 接进位。1+1=二进制 10，所以 SUM=0、CARRY=1。", "Add A+B: SUM is the low bit and CARRY the carry. For 1+1, binary 10 means SUM=0, CARRY=1.",
		"正式测试的四组输入（00、01、10、11）都输出正确，再封装。失败时对照期望与实际值。", "Pass the four official cases (00, 01, 10, 11), then seal. Compare expected and actual values when a case fails.",
		"以后搭更大的电路，试试从你自己的零件开始。", "For a larger circuit, try starting with a part you built yourself."],
	"hardware_foundations/full_adder": [
		"让两路输入和上一位进位一起参与相加。", "Add both inputs together with the incoming carry.",
		"A、B 和进位输入的八种组合都要对；只亮对一组还不够。", "Check all A/B/CIN combinations against SUM/COUT; one lamp pattern is not a full test.",
		"上一位的进位也算进来了。把它们串起来，就能做多位加法。", "You included information from the preceding bit, allowing arithmetic to continue across bit positions."],
	"hardware_foundations/alu": [
		"让控制信号选择运算，并把结果送到任务规定的输出。", "Use the control signal to choose an operation and deliver its specified output.",
		"每个操作码都要给出正确结果，全部用例通过再封装。", "Check the specified opcodes, results and widths; run every case before sealing.",
		"同一条线路，换一个控制信号就做另一种运算。机器开始听从指令了。", "One data path now follows different opcodes; control determines which computation it performs."],
	"hardware_foundations/latch": [
		"构造能设置、清除并保持一个状态的电路。", "Build a circuit that sets, clears and holds a state.",
		"按顺序给出置位、保持、清除，看它能不能记住上一次的状态。", "Check state changes and holding across the input sequence, using the task's control rules.",
		"电路第一次记住了过去：输入撤掉以后，状态还在。", "Past input can now leave a readable state; the circuit responds to more than the current input alone."],
	"hardware_foundations/register": [
		"用DATA与LOAD控制一位数据的写入和保持。", "Use DATA and LOAD to write or hold one bit.",
		"写进去、关掉 LOAD 保持住、再写一次——每一步都对才算完成。", "Check writes, holding with LOAD off and later writes across every sequence case.",
		"这一位能按需写入、保持了。封装后，系统会用它组成四位寄存器。", "This bit can now be written or held. Sealing also builds a four-bit register from it."],
	"hardware_foundations/ram": [
		"组合地址选择、写入控制与存储，按地址取回数据。", "Combine address selection, write control and storage to retrieve data by address.",
		"往不同地址写、再按地址读回来，每一次都要对。", "Check writes, holding and reads at different addresses, rather than only the final output.",
		"每份数据都有了自己的地址，想要哪份就去哪里取。", "Data now has addressable locations; different contents can be stored and retrieved by address."],
	"hardware_foundations/cpu": [
		"把运算、状态和控制接成能按程序工作的机器。", "Connect arithmetic, state and control into a machine that follows a program.",
		"按给定的指令一条条执行，中间状态和最终结果都要对。", "Check intermediate states and final results through the instruction sequence. Tester references cannot replace your own earned components.",
		"你拼出了一台会按程序工作的小机器。接下来的问题是：数据什么时候才到？", "Your components now read, compute and store under instructions. You can next ask when their data arrives."],
	"hardware_foundations/load_store": [
		"让CPU通过LOAD和STORE与外部存储交换数据。", "Let the CPU exchange data with external storage through LOAD and STORE.",
		"跑完给定的读写序列，地址、读到的值和写回的值都要对。", "Run the public read/write sequences and check addresses, read values and stored results.",
		"计算和存储连起来了。数据来回搬运的过程，下一章会仔细看。", "Computation is connected to external storage; the journey of data can now be examined."],
	"hardware_foundations/selector": [
		"用控制输入选择两路数据中的一路。", "Use a control input to select one of two data inputs.",
		"不管怎么选，输出都要来自被选中的那一路。", "Check every data/selection combination; the output must follow the selected input.",
		"控制信号决定信息走哪条路，同一个出口可以接不同的来源。", "Control now determines which source reaches a shared output."],
	"hardware_foundations/selector4": [
		"按两位选择信号，把四路数据中的目标一路送到输出。", "Use two selection bits to route one of four data inputs to the output.",
		"四种选择值都要试，注意两位选择信号的先后。", "Test every selection value and data combination, including the selection-bit order.",
		"从二选一到四选一，大的选择也是由小规则拼出来的。", "Selection now spans four sources, while remaining composed of precise small rules."],
	"hardware_foundations/parity": [
		"把数据与CHECK合起来判断奇偶校验是否出错。", "Combine the data and CHECK input to detect parity disagreement.",
		"每种组合下 ERROR 都要对。奇数个位翻转会被检出，偶数个位翻转可能漏过。", "Check ERROR across all combinations. Parity detects an odd number of flipped bits; an even number can go undetected.",
		"多加一位，就能发现一位出错——也知道了它发现不了什么。", "You used redundant information to check a specific error condition, with a clear limit on what it detects."],
	"hardware_foundations/delay": [
		"让输出在接受新值时给出上一次已接受的数据；暂停接受时保持。", "On accepting new data, output the previously accepted value; hold when acceptance pauses.",
		"连续接受、暂停、再接受，输出总是上一次接受的值。", "Check previous values and holding across consecutive accepts and pauses. This is not a delay measured in rendered frames.",
		"电路记住了「上一次」，先后顺序变成了可以检查的状态。", "You separated successive accepted values, making their order a verifiable state."],
	"hardware_foundations/alarm": [
		"让故障留下报警状态，并使CLEAR能清除报警。", "Let a fault retain an alarm state, with CLEAR able to reset it.",
		"故障出现后报警一直亮着，按 CLEAR 才熄灭；两者同时出现时 CLEAR 优先。", "Check holding and clearing through sequences; CLEAR takes priority when FAULT and CLEAR occur together.",
		"一闪而过的故障也会被记下，直到有人确认清除。", "A brief fault can leave a record that is cleared by explicit control; memory and response have distinct roles."],
	"chapter_1/assembly": [
		"接通CPU、Bus和RAM的请求、写入与读取路径。", "Connect the request, write and read paths among CPU, Bus and RAM.",
		"接好 CPU↔Bus↔RAM 的请求、写入和返回路径，共六条连线；跑完正式测试，输出都正确。", "Connect all six request, write and return links through CPU, Bus and RAM; pass the full official output tests.",
		"CPU、总线和内存连成了一台机器。之后的每一次等待，都能找到是谁在等谁。", "Computation and storage now have real exchange paths, so later waiting can be attributed to modeled parts."],
	"chapter_1/cpu_speed": [
		"先猜，再跑 Eco CPU；只换成 Fast CPU 再跑，比较计算、等待和总周期。", "Predict, then test Eco CPU. Change only to Fast CPU and compare compute, wait and total cycles.",
		"同一程序、RAM 和总线下，两种 CPU 的正式测试都通过。只换选项或运行调试不算完成对照。", "Pass official tests with both CPUs and the same program, RAM and Bus. Selecting a part or running debug alone is not a comparison.",
		"你量出了换 CPU 前后的差别。计算省了多少、等待还剩多少，都在这两次记录里。", "You measured what changing the CPU did. These two records show the change in computation and the waiting that remains."],
	"chapter_1/ram_wait": [
		"保持程序与其他部件，比较RAM改变带来的等待差别。", "Hold the program and other parts fixed while comparing a RAM change.",
		"先跑一次原样，再只换内存跑一次，比较等待的变化。", "First retain a baseline matching the current fixed conditions, then fully test another RAM part.",
		"换了内存，CPU 的等待就跟着变了。等待的来源找到了。", "You related storage service to CPU waiting using two observations under matching conditions."],
	"chapter_1/bus_width": [
		"固定程序和CPU、RAM，比较另一种Bus的传输过程。", "Fix the program, CPU and RAM while comparing another Bus's transfer behavior.",
		"只换总线再跑一次，看数据被分成几段搬运。", "Compare valid full-test Bus receipts and their transfer phases; rendered wire width does not measure bandwidth.",
		"总线更宽，一次能搬的数据更多。线连着，不等于搬得快。", "You verified how bandwidth changes segmented transfers, distinguishing connectivity from modeled transfer cost."],
	"chapter_1/bottleneck": [
		"运行指定工作负载，依据真实周期与等待记录作出瓶颈判断。", "Run the specified workloads and diagnose the bottleneck from measured cycles and waiting.",
		"跑完正式测试，再按这次的周期与等待记录提交判断。判断不符时，回到分析器核对。", "Finish the official run, then diagnose from its cycles and waiting. If the diagnosis does not match, check the Profiler.",
		"瓶颈找到了。换一份工作，最慢的还会是它吗？", "You found the bottleneck. Would it be the same for a different workload?"],
	"chapter_1/read_once": [
		"修改程序，让取回的数据得到需要的复用。", "Edit the program so fetched data receives the reuse the task needs.",
		"输出都对，而且每个用例的取数次数不超过上限。改完程序记得先应用。", "Every output must be correct and every case must meet its request cap on fixed hardware; Apply before the official run.",
		"同样的硬件，改一下程序安排，就少跑了很多趟。", "Your program avoided unnecessary requests while correctness and the transfer budget were checked separately."],
	"chapter_1/two_orders": [
		"分别为计算订单和搬运订单安排满足成本与时间限制的机器。", "Choose machines meeting time and cost limits for both the compute and move orders.",
		"两张订单各自达标，可以用不同的机器配置。", "Both distinct orders need qualifying receipts. They may use different valid configurations; repeating one cannot satisfy the other.",
		"两份订单都达标了。比较它们的时间和成本，看看不同需求下的取舍。", "Both orders meet their limits. Compare their time and cost to examine the trade-offs."],
	"chapter_2/distant_reads": [
		"运行任务并观察相同数据为何反复经过RAM。", "Run the task and examine why the same data returns through RAM repeatedly.",
		"运行一次，根据记录说出：哪些数据被反复取了。", "Retain a valid run, then submit the task's judgment from that evidence.",
		"你发现同一份数据被一遍遍从远处取来。这就是下一步要解决的。", "You traced waiting back to repeated fetching, giving reuse an observable starting point."],
	"chapter_2/nearby_storage": [
		"比较直接取数与Cache复用，观察命中和远取。", "Compare direct fetching with Cache reuse, observing hits and remote requests.",
		"分别跑一次「直接取」和「用缓存」，比较命中和远取。缓存由硬件自己管理。", "Record the required direct and reuse observations. Hardware rules manage Cache contents; do not place them manually.",
		"命中的那几次，数据不用再从 RAM 搬来。", "On a Cache hit, the data no longer needs another trip from RAM."],
	"chapter_2/cache_failure": [
		"观察有Cache却仍然等待的运行，寻找对应的命中与淘汰记录。", "Inspect a run that still waits despite Cache, including its hit and eviction records.",
		"运行一次，从命中和淘汰记录里找出为什么还在等。", "Support the task judgment with a valid run; current controls do not describe an older receipt.",
		"有缓存不等于有用：有用的数据可能已经被挤走了。", "You distinguished having Cache from retaining useful data, making failed reuse explainable evidence."],
	"chapter_2/access_order": [
		"调整循环先后，点「应用程序」再运行；比较取数次数和总周期。", "Change the loop order, Apply program, then run. Compare data requests and total cycles.",
		"按行连续访问，正式结果正确且不超过 105 周期。未达标时，查命中、淘汰和 RAM 取数记录。", "Use row-first access with correct official output in at most 105 cycles. If it falls short, inspect hits, evictions and RAM requests.",
		"同样的数据和计算，换了访问顺序。看看这次少了哪些取数。", "The data and computation stayed the same; the access order changed. Inspect which requests were avoided."],
	"chapter_2/working_set": [
		"观察重复计算需要的数据与有限Cache如何相处。", "Observe how repeatedly needed data interacts with finite Cache capacity.",
		"运行并看记录：需要同时留在手边的数据，放得下吗？", "Use the task's run and records to support a working-set judgment, beyond whether Cache is enabled.",
		"要反复用的数据不一定留得住。容量和访问次序，要一起看。", "Data needed again may not stay in Cache. Capacity and access order both matter."],
	"chapter_2/blocking": [
		"安排分块，让有限空间里的数据在离开前得到使用。", "Arrange blocks so data in finite space is used before it leaves.",
		"输出正确，周期不超过目标；分块不能漏算。", "The full task must preserve correct output and meet the public cycle target; blocking must not omit or alter work.",
		"把大任务切成放得下的小块，每块用完再换下一块。", "You divided the computation into reusable portions while retaining its original result."],
	"chapter_2/capstone": [
		"保留基线与诊断，再综合访问次序、Cache与分块形成自己的方案。", "Retain a baseline and diagnosis, then combine access order, Cache and blocking into your own plan.",
		"先跑原样、写下判断，再用你自己的组合方案达标。", "Validate the baseline, judgment and target-meeting run under the existing contract; valid trade-offs remain accepted.",
		"你把判断变成了能运行的方案。下一次，你想先改哪里？", "You turned your diagnosis into a working plan. What would you try next?"],
	"chapter_3/arrival": [
		"安排数据请求与独立工作，等数据就绪后再消费。", "Arrange a data request and independent work, consuming data only when ready.",
		"处理第0批，恰好完成4周期独立工作；总用时不超过10周期。", "Process batch 0 and exactly 4 cycles of independent work, within 10 total cycles.",
		"等数据的时候先做别的事，数据到了再用。等待不再是空白。", "Independent work now occupies waiting time while readiness still precedes use."],
	"chapter_3/buffers": [
		"选择缓冲结构，协调装入、计算和再次使用。", "Choose a buffer structure and coordinate loading, computation and reuse.",
		"所有用例正确且达标。只多放几个缓冲区，不一定就不等了。", "Check output, buffer states and cycles for every case; adding parts alone does not remove waiting.",
		"看看哪些时段同时在搬、在算。换一种处理节奏，还能这样安排吗？", "Look for the intervals where transfer and computation overlap. Would this arrangement still work at a different pace?"],
	"chapter_3/backpressure": [
		"在不同处理节奏下协调生产和消费，避免覆盖仍被使用的数据。", "Coordinate production and consumption under changing processing times without overwriting live data.",
		"两种处理节奏下都要正确且达标，注意什么时候可以释放、再请求。", "Both varying cases must be valid and meet their targets; inspect readiness, release and later requests in the actual sequence.",
		"后面忙不过来时前面会等一等，还没用完的数据不会被覆盖。", "Your arrangement responds to changing processing speed, with backpressure protecting unfinished data."],
	"chapter_3/prefetch": [
		"安排预取与实际读取，在有限缓存中准备稍后要用的数据。", "Arrange prefetches and demand reads to prepare later data in finite Cache.",
		"输出正确且达标。提前搬也要花真实的搬运时间。", "Full-case output must be correct and meet the cycle target; prefetches still incur modeled transfer costs.",
		"在需要之前就把数据请来，时间线上能看到提前量。", "You issued some requests earlier; their later use can be compared with the advance transfers in the timeline."],
	"chapter_3/distance": [
		"按有限容量与工作节奏调整预取时机。", "Adjust prefetch timing to capacity and the pace of work.",
		"看周期和淘汰记录：搬得太早，可能还没用就被挤走了。", "Run the task and inspect cycles and evictions; early data that cannot be used is not a free gain.",
		"提前多少才合适？太早太晚都不好。", "You weighed how early data arrives against how long it can remain available."],
	"chapter_3/synthesis": [
		"选择自己的Buffer或Cache路线，统筹搬运与计算。", "Choose your own Buffer or Cache route and coordinate transfers with computation.",
		"所有工作负载都正确且达标，用哪种结构由你选。", "Every workload must be valid and meet its target. Extra transfer goals are separate; no reference structure is mandatory.",
		"你找到了一条让计算和搬运各行其时的路。别的路线也值得试试。", "Your verified route coordinates computation and transfers; other valid structures remain open to exploration."],
	"chapter_4/fields": [
		"保留全部记录与字段，为只读取温度的查询安排布局。", "Keep all records and fields while arranging a layout for temperature-only queries.",
		"两张查询的结果都对，内存流量不超过上限；所有字段都要保留。", "Check both outputs and public RAM-traffic caps; deleting other fields is not a valid cost reduction.",
		"把常用的字段放在一起，一次搬运里的有用数据就多了。", "More of each transfer now serves the query while complete records remain intact."],
	"chapter_4/records": [
		"面向稀疏整条抽查，重新安排四个字段的位置。", "Reconsider field placement for sparse queries that inspect whole records.",
		"两张查询都要取回被抽查记录的全部字段，并且流量达标。", "Both cases must return every field of the requested records and meet their traffic conditions.",
		"适合上一种查询的布局，不一定适合这一种。", "You verified that a layout suited to one query may not suit a different access pattern."],
	"chapter_4/hot_cold": [
		"让频繁共同读取的字段与偶尔抽查的字段各有合适位置。", "Arrange frequently co-read fields and occasionally inspected fields to suit their access patterns.",
		"同一种布局下，两份查询都要达到周期目标。", "One layout must retain all identities and fields and meet cycle contracts for both queries.",
		"常一起读的字段与偶尔抽查的字段，找到了兼顾两种查询的摆法。", "Your field arrangement serves both frequent reads and occasional inspections."],
	"chapter_4/relocation": [
		"分别判断一次查询与反复查询是否值得先复制整理。", "Decide separately whether one query and repeated queries justify copying first.",
		"两张订单各自达标；搬过去、整理、写回的成本都要算上。", "Each order's own valid design must meet its target, including source reads, preparation and writes.",
		"整理一次值不值得，要看之后会用多少次。", "You compared preparation with later service, rather than treating copying as free."],
	"chapter_4/batches": [
		"在有限临时空间里分批完成任务，准确处理最后不足一批的数据。", "Complete the task in bounded scratch space, correctly handling a partial final batch.",
		"分批处理不漏不重，最后不满一批的也要算对；周期和临时空间都要达标。", "Count each record exactly once per query; both cases must meet output, cycle and peak-scratch limits.",
		"放不下就分批做，最后一小批也一样准确。", "You completed work larger than scratch space in batches, preserving record meaning through the tail batch."],
	"chapter_4/mixed": [
		"用同一方案兼顾反复统计与稀疏整条抽查。", "Use one design for repeated scans and sparse whole-record inspections.",
		"两张订单都正确且达标；空间和流量的额外目标可以以后再挑战。", "Both cases must meet output and main-contract conditions; optional space and traffic goals do not gate completion.",
		"你找到了一种同时照顾两类查询的布局。还可以比较它的空间和流量。", "You found one arrangement usable by both access patterns; space and traffic remain distinct directions for further improvement."],
	"representation/mixed_scan": [
		"选择分块和编码，让混合资产的完整扫描达标。", "Choose partitions and encodings that serve a complete mixed-asset scan under its contract.",
		"存储大小和总周期都达标；解码也要花时间。", "Measure whole-asset storage and total cycles, including decoding work and transferred payload.",
		"内容没变，写法变了。省下的搬运，够抵过解码的时间吗？", "Same content, different encoding. Do the saved transfers outweigh decoding time?"],
	"representation/interior_hotspots": [
		"为重复内部点读安排分块、编码和缓存复用。", "Arrange partitioning, encoding and Cache reuse for repeated interior reads.",
		"存储、周期和流量都达标；解出来却没用上的字节也算成本。", "Meet storage, cycle and traffic contracts together; restored but unrequested bytes still cost work.",
		"表示方式配合常读的位置，多余的解码就少了。", "You matched representation to requested locations and distinguished useful bytes from incidental work."],
	"representation/dense_sparse": [
		"用同一划分服务完整扫描与重复端点读取。", "Use one partition for a full scan and repeated endpoint reads.",
		"两张订单都从空缓存开始，各自达标。", "Both orders start with cold Cache and must independently meet their public limits.",
		"同一份表示，既能整段扫描，也能挑着读。", "One usable representation now serves both dense and sparse access."],
	"representation/prepare_once": [
		"用同一分块方案，分别服务一次短读和八次完整扫描。", "Use one block plan for a short read and eight full scans.",
		"两张订单的总周期与存储均达标，各自计一次准备。", "Meet both orders' time and storage limits. Each pays preparation once.",
		"准备和服务的成本合在一起，才知道这次整理值不值得。", "Preparation and service costs together show whether this rearrangement pays off."],
	"representation/cross_assets": [
		"让同一划分与编码选择服务两份不同资产和各自订单。", "Use the same partition and encoding choices for two distinct assets and their orders.",
		"同一个方案在两份资产上都要达标。", "One plan must meet every contract on both public assets; showing only one order is insufficient.",
		"你的写法换一份数据也成立，不是只对一段数据有效。", "Your representation choices survived a second asset, extending the trade-off beyond one data sample."],
	"service/move_state": [
		"安排分组与状态驻留，让历史服务后续请求。", "Arrange grouping and state residency so history serves later requests.",
		"每条流保持顺序，结果与最终状态精确；周期、状态搬运和峰值内存都达标。", "Preserve within-stream order, exact scores and final states, and meet cycle, state-traffic and peak-memory contracts.",
		"状态留住多久，能少搬几次？看看这次的载入和写回记录。", "How many transfers did keeping state nearby save? Check the loads and writebacks."],
	"service/prompt_response": [
		"在有限资源中兼顾总工作与每条流的首次响应。", "Balance total work and each stream's first response under finite resources.",
		"保持结果精确，每条流的第一次回应与总周期都要达标。", "Retain stream order and exact results; every stream must meet the first-response and total-cycle contracts.",
		"每条流都及时收到了第一次回应。再看看，保住这些回应要搬多少状态。", "Every stream received its first response in time. Now look at how much state those responses moved."],
	"service/one_plan": [
		"用同一服务方案同时处理时间、状态流量与质量要求。", "Use one service plan to meet timing, state-traffic and quality requirements together.",
		"总周期、首次回应、状态搬运和误差都要达标。", "Check total cycles, every first response, state traffic and actual errors under the public contract.",
		"你的一个方案同时照顾了速度、回应和质量。", "One verified plan now connects service scheduling, representation cost and quality limits."],
	"prediction/regular": [
		"先记录关闭猜测的基线，再观察仅靠已揭示历史能否提前搬来有用数据。", "Record an Off baseline, then explore whether revealed history can support useful advance transfers.",
		"先关掉预测跑基线，再用规则跑一次：预测的数据被用上，且总周期更少。", "This session needs an Off baseline and a faster non-Off rule whose predicted data was actually consumed.",
		"预测来的数据用上了，也更快了。记录只保留到离开本章。", "The predicted data was used, and the run was faster. These records last only until you leave."],
	"prediction/changed": [
		"观察规律改变后，原预测如何影响等待与流量，再修订规则。", "Observe how a changed pattern affects prediction, waiting and traffic, then revise the rule.",
		"留下更慢且有浪费或污染的记录，再用非关闭规则做到不慢于基线。", "Retain a slower record with waste or pollution and a non-Off revision no slower than baseline; Off is not the safe revision.",
		"你找到了不慢于基线的规则。换一段访问，它还管用吗？", "You found a rule no slower than Off. Would it still help on a different stream?"],
	"prediction/alternating": [
		"在交替热点和有限缓存中比较不同规则的效果。", "Compare rules under alternating hotspots and finite Cache.",
		"比较几种规则：有的反而更慢、挤掉了有用数据，有的不比基线慢。", "Compare distinct rules, retaining a slower waste/pollution example and a non-Off record no slower than baseline.",
		"预测和缓存会互相影响：猜错的数据也会占位置。", "You observed prediction and Cache interacting in this session; these temporary records do not become permanent progress after departure."],
	"creation/C1_restore": [
		"学习选定样例，发送预测包并核对接收端复原。", "Learn the selected examples, send a predictive packet and check receiver restoration.",
		"接收端只拿到这个包，也要把原文一格不差地还原出来。", "With only this packet, the receiver must restore the original exactly, cell for cell.",
		"规律加上例外，原文一格不差地到了另一头。", "Pattern plus exceptions carried the original across, cell for cell."],
	"creation/C2_cost": [
		"固定原文与条件，比较RAW和预测包的真实大小。", "Fix the source and conditions while comparing actual RAW and predictive packet sizes.",
		"规则本身、包头和修正都要算进大小；有时候压缩包反而更大。", "Rules, header and corrections all count toward size; sometimes the packet ends up larger.",
		"你发现：写下规律也要花地方。", "You found that writing a pattern down also takes space."],
	"creation/C3_conditions": [
		"保持原文、规则与路径，换机器比较成本；配送订单可另行尝试。", "Keep source, rules and codec fixed while changing the machine; delivery orders are separate options.",
		"只换机器、别的都不动，比较哪台更划算。", "Change only the machine, keep everything else, and compare which one costs less.",
		"写法相同，机器不同。这次的时间花在哪里？", "Same encoding, different machine. Where did the time go?"],
	"creation/P1_commit": [
		"接到未见输入，先提交一格预测再揭晓，并完成整轮。", "Connect sealed input, commit one prediction before revealing it, then finish the full round.",
		"每一格都要先猜、再揭晓，整轮做完才算数；揭晓的答案不会偷偷拿去学习。", "Guess each cell before it is revealed and finish the whole round; revealed answers are never used to learn.",
		"先说出你的猜测，再看答案——对和错都清清楚楚。", "You committed to a guess before seeing the answer, so right and wrong are both clear."],
	"creation/P2_memory": [
		"改变记忆长度并重新学习，在同材料与机器上比较预测。", "Change history length and relearn, comparing predictions on matching material and machine.",
		"改了记忆长度就要重新学习，再用新规则完整预测一轮。", "After changing the history length, learn again and predict a full round with the new rules.",
		"记忆长度改变了规则看到的上下文。有没有猜得更好，要看同一材料上的对照。", "History length changes the context available to the rules. Compare matching material to see whether prediction improved."],
	"creation/P3_check": [
		"先用独立材料练习，再带着冻结规则检查未见片段。", "Practice separately, then check an unseen passage with frozen rules.",
		"练习归练习；检查时规则冻结，只看它没见过的片段。", "Practice is separate; during the check the rules are frozen and only see an unseen passage.",
		"你看到了规则面对陌生内容时的真实表现，包括它不确定的地方。", "You saw how the rules really behave on unfamiliar material, including where they are unsure."],
	"creation/G1_feedback": [
		"当前模型完成无损复原和整轮预测后，把输出接回输入并生成。", "After this model restores exactly and finishes prediction, feed its output back and generate.",
		"先让这套规则能复原、能预测，再把输出接回输入。这里没有标准答案。", "Once these rules can restore and predict, feed the output back in. There is no answer key here.",
		"同一套有限的规则，开始接着自己的输出往下写。", "The same finite rules now keep writing from their own output."],
	"creation/G2_intent": [
		"带着自己的意图改变条件；可做受控对照，也可确认保留一件作品。", "Change conditions with an intention; try a controlled comparison or explicitly keep a chosen work.",
		"想比较时只改一个条件；想直接留下也可以。", "To compare, change only one condition; or keep a work directly.",
		"你的选择成了作品的一部分。好不好看，不由分数决定。", "Your choice became part of the work. Whether it is beautiful is not decided by a score."],
	"creation/G3_keep": [
		"想留下这一段，就在下方填个名称，再点保存。", "To keep this passage, give it a name below, then save it.",
		"确认保存成功，输出和配方才会一起留下。失败时保留当前草稿，查看状态栏原因。", "Keep must succeed to retain the output and recipe together. If it fails, keep the draft open and read the status message.",
		"你选择留下这一段。可以回看它，也可以从原配方另开一份草稿。", "You chose to keep this passage. View it again, or fork its recipe into another draft."],
}

const DOMAIN_CONTEXTS := {
	"hardware_foundations": ["几条简单规则，能拼出多大的机器？", "How far can a few simple rules take your machine?", "先组合逻辑，再保存状态，最后接成 CPU；支线随时可以探索。", "Combine logic, store state, then build a CPU. Side routes are open to exploration.", "检查端口方向与位宽，再找测试台里第一处不符。", "Check port direction and width, then find the first mismatch in Test Bench.", "正式测试通过后，记得封装自己的电路。", "After the official tests pass, seal your circuit."],
	"chapter_1": ["机器接通了，时间都花在哪里？", "The machine is connected. Where does its time go?", "分清计算与等待，再试着少搬几趟。", "Separate computation from waiting, then try making fewer transfers.", "先查输出，再看正式测试是否留下了同条件的基线与对照。", "Check outputs, then confirm official baseline and comparison runs under matching conditions.", "改了配置要重新运行；旧记录仍对应旧配置。", "Run again after changing the setup; old records still describe the old setup."],
	"chapter_2": ["下次还要用的数据，能留在近处吗？", "Can data you need again stay nearby?", "搭配容量、访问顺序与分块；下一步再安排搬运时机。", "Combine capacity, access order and blocking; next, arrange when transfers happen.", "先看任务台缺哪项记录，再查命中、淘汰和 RAM 取数。", "Check Mission for missing evidence, then inspect hits, evictions and RAM requests.", "Cache 自动管理内容；改了方案要重新运行。", "Cache manages its contents automatically. Rerun after changing your plan."],
	"chapter_3": ["等数据的时候，还能先做什么？", "What can you do while waiting for data?", "从一批数据到完整调度，Buffer 和 Cache 都有可探索的路线。", "From one batch to a full schedule, explore both Buffer and Cache routes.", "查看首个状态错误或超出的周期，再沿时间线追踪请求、就绪、使用与释放。", "Find the first state error or cycle overrun, then trace requests, readiness, use and release.", "普通连线不增加延迟；搬运和等待的时间看部件与事件。", "Wires add no delay. Transfer and waiting times come from components and events."],
	"chapter_4": ["同一份数据，换个摆法，能少搬多少？", "Same data, different layout. How much less needs to move?", "试过布局，再看复制整理和分批各适合什么情况。", "After layout, explore when copying and batching pay off.", "先查漏算、重算和最后一批，再看流量、周期与临时空间。", "Check missing or repeated records and the final batch, then traffic, cycles and scratch space.", "记录和字段都要保留；准备成本也要算。", "Keep every record and field, and count preparation costs."],
	"representation": ["少搬一点、多解码一点，这笔账划算吗？", "Move less, decode more. Does it pay off?", "同一写法，换份资产或订单，再比较一次。", "Try the same encoding on another asset or order and compare again.", "逐单看超限项目，分开核对存储、搬运、解码和准备成本。", "Check each order’s exceeded limits, separating storage, transfer, decoding and preparation costs.", "按本关目标核对；压得小，不一定读得快。", "Check this task’s targets. A smaller encoding may take longer to read."],
	"service": ["留住状态的同时，能让每条流都及时收到回应吗？", "Can you keep state nearby and still respond to every stream in time?", "先管状态搬运，再兼顾首次回应、总时间和质量。", "Start with state transfers, then balance first responses, total time and quality.", "看哪条流回应迟了，再查状态载入、写回和误差记录。", "Find late streams, then inspect state loads, writebacks and error records.", "同一条流按顺序处理，状态不能跳过。", "Process each stream in order without skipping its state."],
	"prediction": ["猜对能省时间，猜错要付出什么？", "A good guess can save time. What does a bad one cost?", "这里预测下次访问的地址；后面的光纹实验预测内容。", "Here you predict the next address; later signal experiments predict content.", "对照当时已知的历史，看哪些预测被用上、哪些白搬或挤走了有用数据。", "Compare known history with used predictions, wasted transfers and displaced data.", "记录仅在本次游玩保留，离开本章后清空。", "These records last only for this session and clear when you leave the chapter."],
	"creation": ["能复原、能预测的规则，接着自己的输出会写出什么？", "What will rules that restore and predict produce from their own output?", "复原、预测、生成共用一套规则；改变样例，看看结果怎么变。", "Restoration, prediction and generation share rules. Change the examples and see what changes.", "改样例或记忆长度后重新学习；生成前，先完成当前模型的复原与整轮预测。", "Relearn after changing examples or history length. Before generating, finish restoration and prediction with the current model.", "保存成功才留下作品；草稿改变不会覆盖已存作品。", "A work is kept only after saving succeeds. Draft edits do not overwrite saved works."],
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
