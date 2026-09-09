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
