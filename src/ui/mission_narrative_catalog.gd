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
		"operations": "进入后，任务台会记录接线、切换输入、运行、拆线与重新接线这五项实际操作。看完或跳过这段文字都不会完成任务。" if not english else "The Mission tracks five real actions: connect, change an input, run, disconnect and reconnect. Reading or skipping this introduction does not complete the task.",
		"help": "目标与操作：任务台  ·  元件规则与图示：手册  ·  解题方向：Hint\n这段讯息可以从首页回看。" if not english else "Goal and controls: Mission  ·  Component rules and diagrams: Handbook  ·  Strategy: Hint\nReplay this message from Home whenever you wish.",
	}


static func completion_response(chapter_id: StringName, level_id: StringName, english: bool) -> String:
	var responses: Dictionary = {
		"hardware_foundations/tutorial": ["你已经亲手改变输入、运行并重新接通电路。NOT 的规则是反转：0 → 1，1 → 0；亮与灭都可以说明它正在正确工作。接下来，试着让两个输入一起参与计算。", "You changed the input, ran the circuit and reconnected it yourself. NOT inverts: 0 → 1 and 1 → 0; either lamp state can be correct. Next, let two inputs take part in a calculation."],
		"hardware_foundations/half_adder": ["你的电路把两个一位输入分成了和与进位。1 + 1 不再装进一位里：和为 0，进位为 1。可以封装这份成果，再用它构造更大的计算。", "Your circuit separates the sum and carry of two one-bit inputs. For 1 + 1, the sum is 0 and the carry is 1. Seal this work when you want to use it in a larger calculation."],
		"hardware_foundations/cpu": ["这台机器按指令读取、计算并保存结果。你的元件开始协作；往后的问题，还包括数据何时能够到达。", "This machine reads, computes and stores results under its instructions. Your components now work together; the next questions include when their data can arrive."],
		"chapter_1/cpu_speed": ["你比较了同一程序下的两种 CPU。结论来自上面的实测：计算变快后，总时间是否也同样减少？可以回到证据中看等待占了多少。", "You compared two CPUs under the same program. The measurements above tell you whether faster computation also reduced total time. Revisit the evidence to see how much time was spent waiting."],
		"chapter_2/capstone": ["这份方案达到了当前任务条件。复用数据改变了搬运的安排；是否还能继续改进，要看同条件下的周期与搬运记录。你的合法方案可以保留，再慢慢比较。", "This plan meets the current task conditions. Reuse changed how data was moved. Compare cycles and transfers under the same conditions to explore further improvements; you can keep this valid plan."],
	}
	var key: String = "%s/%s" % [chapter_id, level_id]
	if not responses.has(key): return ""
	return str(responses[key][1 if english else 0])
