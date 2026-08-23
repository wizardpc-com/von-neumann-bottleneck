extends SceneTree

const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const DSLParserType = preload("res://src/simulation/dsl_parser.gd")
const SimulationCoreType = preload("res://src/simulation/simulation_core.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_mode: Node = root.get_node("GameMode")
	var system_state: Node = root.get_node("SystemChapter")
	var locality_state: Node = root.get_node("LocalityChapter")
	game_mode.call("set_mode", &"game")
	var hub_scene: PackedScene = load("res://src/ui/prototype_hub.tscn")
	var hub: Control = hub_scene.instantiate()
	root.add_child(hub)
	await process_frame
	_assert((hub.get("locality_entry_button") as Button).disabled, "The hub must gate Chapter 2 until Chapter 1's diagnosis is complete.")
	for level_id: StringName in [&"assembly", &"cpu_speed", &"ram_wait", &"bus_width", &"bottleneck"]:
		system_state.call("mark_completed", level_id)
	await process_frame
	_assert(not (hub.get("locality_entry_button") as Button).disabled, "The hub must open Chapter 2 immediately after Chapter 1 completion.")
	hub.queue_free()
	await process_frame

	var scene: PackedScene = load("res://src/ui/main.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	for _frame: int in range(4):
		await process_frame

	var catalog = main.get("catalog")
	_assert(locality_state.call("chapter_unlocked"), "Completing Chapter 1 must unlock Chapter 2 in Game mode.")
	_assert(catalog.call("is_unlocked", &"distant_reads", locality_state.call("completed_levels"), true, false), "The first Chapter 2 observation must open after Chapter 1.")
	_assert(not catalog.call("is_unlocked", &"nearby_storage", locality_state.call("completed_levels"), true, false), "Normal progression must keep the paired exploration locked until its observation is complete.")

	main.call("_start_level", &"distant_reads")
	await process_frame
	var graph: GraphEdit = main.get("graph")
	_assert(not (graph.get_node("Cache") as GraphNode).visible, "2-1 must show the direct CPU → Bus → RAM path without a Cache node.")
	_assert(graph.get_connection_list().size() == 4, "2-1 must contain only Program, direct-memory, and result routes.")
	_assert("Cache" not in (main.get("mission_objective_label") as Label).text and "Cache" not in (main.get("notebook_label") as RichTextLabel).text, "2-1 player-facing evidence must not reveal the Cache concept early.")
	main.call("_run_simulation", "Official Test Set")
	var direct: SimulationTraceType = main.get("current_trace")
	_assert(int(direct.metrics["total_cycles"]) == 257 and int(direct.metrics["wait_cycles"]) == 240, "2-1 must expose repeated distant-read waiting with exact deterministic metrics.")
	_assert(_first_event(direct, &"value_return").route_devices == [&"RAM", &"Bus", &"CPU"], "2-1 Trace must carry each raw value back along RAM → Bus → CPU.")
	_assert(not bool(locality_state.call("completed_levels").get(&"distant_reads", false)), "Running an observation alone must not complete it.")
	main.call("_select_judgment", &"repeated_ram")
	_assert(bool(locality_state.call("completed_levels").get(&"distant_reads", false)), "2-1 must complete only after the player commits the evidence-supported waiting explanation.")
	_assert((main.get("level_completion_overlay") as Control).visible, "A completed short investigation must present a concise conclusion.")

	main.call("_start_level", &"nearby_storage")
	var cache_node: GraphNode = graph.get_node("Cache")
	var device_buttons: Dictionary = main.get("device_instrument_buttons")
	_assert(not _reveals_cache_term(cache_node.title) and not _reveals_cache_term((device_buttons[&"Cache"] as Button).text), "2-2 must describe the unexplained mechanism as nearby storage, including its graph action.")
	_assert(not _reveals_cache_term((main.get("profiler_detail_label") as Label).text), "2-2 Profiler guidance must use concrete far-fetch language before naming Cache or Miss.")
	var concrete_trace: SimulationTraceType = (main.get("simulation_core") as RefCounted).call(
		"run_workload", DSLParserType.parse(ProgramTemplatesType.ROW_FIRST), SimulationCoreType.official_data_copy(), 1, "Terminology Preview"
	)
	for event: SimulationEventType in concrete_trace.events:
		_assert(not _reveals_cache_term(String(main.call("_event_message", event))), "Pre-reveal Trace messages must describe data movement without naming Cache/Hit/Miss.")
		for device: StringName in event.route_devices:
			_assert(not _reveals_cache_term(String(main.call("_component_state_text", event, device))), "Pre-reveal device feedback must describe nearby data blocks without naming Cache/Hit/Miss.")
	main.call("_run_simulation", "Official Test Set")
	var nearby_baseline: SimulationTraceType = main.get("current_trace")
	_assert(int(nearby_baseline.metrics["total_cycles"]) == 257 and bool(main.get("current_bypass_cache")), "2-2 must begin from the same direct-memory baseline.")
	main.call("_select_cache", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var nearby: SimulationTraceType = main.get("current_trace")
	_assert(int(nearby.metrics["total_cycles"]) == 105 and int(nearby.metrics["cache_misses"]) == 4 and int(nearby.metrics["cache_hits"]) == 12, "2-2 must show a first fetch followed by nearby reuse on every line.")
	_assert(bool(locality_state.call("completed_levels").get(&"nearby_storage", false)), "2-2 must complete after both paths have valid evidence.")
	_assert(locality_state.call("concept_unlocked", &"cache") and locality_state.call("concept_unlocked", &"hit") and locality_state.call("concept_unlocked", &"miss"), "Cache, Hit, and Miss terminology must unlock only after the exploration.")
	_assert(_reveals_cache_term(cache_node.title), "Completing 2-2 must visibly name the nearby mechanism as Cache.")
	var comparison_text: String = (main.get("profiler_history_label") as Label).text
	_assert("257" in comparison_text and "105" in comparison_text and "CPU WAIT" in comparison_text, "2-2 Run History must foreground Before → After total and CPU-wait deltas.")

	main.call("_start_level", &"cache_failure")
	main.call("_run_simulation", "Official Test Set")
	var failure_trace: SimulationTraceType = main.get("current_trace")
	_assert(int(failure_trace.metrics["total_cycles"]) == 321 and int(failure_trace.metrics["cache_misses"]) == 16, "2-3 must create the clear cognitive reversal: Cache present, yet every access misses.")
	main.call("_select_judgment", &"replacement")
	_assert(bool(locality_state.call("completed_levels").get(&"cache_failure", false)), "2-3 must require the replacement-before-reuse explanation.")

	main.call("_start_level", &"access_order")
	main.call("_run_simulation", "Official Test Set")
	main.call("_load_strategy", ProgramTemplatesType.ROW_FIRST, "row-first")
	main.call("_apply_program")
	main.call("_run_simulation", "Official Test Set")
	var local_trace: SimulationTraceType = main.get("current_trace")
	_assert(int(local_trace.metrics["total_cycles"]) == 105 and int(local_trace.metrics["hardware_cost"]) == 4, "2-4 must meet the target by changing access order without upgrading Cache.")
	_assert(locality_state.call("concept_unlocked", &"locality"), "Locality must unlock after the player implements the access-order repair.")
	_assert("访问顺序" in (main.get("profiler_history_label") as Label).text or "access order" in (main.get("profiler_history_label") as Label).text, "2-4 comparison must identify access order as the changed item.")

	main.call("_start_level", &"working_set")
	main.call("_run_simulation", "Official Test Set")
	var working_set_trace: SimulationTraceType = main.get("current_trace")
	_assert(int(working_set_trace.metrics["total_cycles"]) == 210 and int(working_set_trace.metrics["cache_misses"]) == 8, "2-5 must reload all four lines despite already-good row-first order.")
	main.call("_select_judgment", &"does_not_fit")
	_assert(locality_state.call("concept_unlocked", &"working_set"), "Working Set must unlock only after the player explains the capacity mismatch.")

	main.call("_start_level", &"blocking")
	main.call("_run_simulation", "Official Test Set")
	var unblocked: SimulationTraceType = main.get("current_trace")
	main.call("_select_block_lines", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var blocked: SimulationTraceType = main.get("current_trace")
	_assert(int(unblocked.metrics["total_cycles"]) == 210 and int(blocked.metrics["total_cycles"]) == 138, "2-6 must turn work grouping into a measurable decision, not a standalone procedure.")
	_assert(int(blocked.metrics["cache_misses"]) == 4 and int(blocked.metrics["hardware_cost"]) == 4, "2-6 must shrink the active working set without hardware replacement.")
	_assert(locality_state.call("concept_unlocked", &"blocking"), "Blocking/Tiling must unlock after the implementation succeeds.")

	main.call("_start_level", &"capstone")
	var capstone_cache_buttons: Dictionary = main.get("cache_card_buttons")
	var capstone_block_buttons: Dictionary = main.get("block_card_buttons")
	_assert(not (main.get("editor") as TextEdit).editable, "2-7 must keep program changes locked until the given baseline has produced evidence.")
	_assert((capstone_cache_buttons[4] as Button).disabled and (capstone_block_buttons[1] as Button).disabled, "2-7 must prevent hardware or work-group changes before the baseline run.")
	main.call("_run_simulation", "Official Test Set")
	var capstone_baseline: SimulationTraceType = main.get("current_trace")
	_assert(int(capstone_baseline.metrics["total_cycles"]) == 642 and not bool(main.get("current_goal_met")), "2-7 must start from a new unresolved workload without suggesting a solution.")
	_assert((main.get("editor") as TextEdit).editable, "The baseline receipt must unlock program investigation.")
	_assert(not (capstone_cache_buttons[4] as Button).disabled and not (capstone_block_buttons[1] as Button).disabled, "The baseline receipt must unlock the capstone's hardware and work-group decisions.")
	main.call("_select_cache", 4, true)
	main.call("_run_simulation", "Official Test Set")
	var hardware_solution: SimulationTraceType = main.get("current_trace")
	_assert(int(hardware_solution.metrics["total_cycles"]) == 138 and int(hardware_solution.metrics["hardware_cost"]) == 13, "The capstone must accept a larger-Cache hardware solution.")
	_assert(bool(locality_state.call("completed_levels").get(&"capstone", false)), "A correct capstone run at or below 145 cycles must complete the chapter.")
	_assert(not (main.get("level_completion_overlay") as Control).visible and (main.get("mission_finish_button") as Button).visible, "Capstone completion must leave the lab active so the player may keep optimizing.")
	main.call("_select_cache", 1, true)
	main.call("_select_block_lines", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var software_solution: SimulationTraceType = main.get("current_trace")
	_assert(int(software_solution.metrics["total_cycles"]) == 138 and int(software_solution.metrics["hardware_cost"]) == 4, "The capstone must also accept a lower-cost blocking solution.")
	_assert((main.get("lab_host") as Control).visible and bool(locality_state.call("completed_levels").get(&"capstone", false)), "Further optimization must remain possible after chapter completion.")
	var notebook_text: String = (main.get("notebook_label") as RichTextLabel).text
	for learned_term: String in ["CPU WAIT", "Cache", "Locality", "Working Set", "Blocking"]:
		_assert(learned_term in notebook_text, "The completed Systems Notebook must retain %s." % learned_term)

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: complete seven-level Chapter 2 progression, concept reveals, comparisons, and multiple capstone solutions passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d Chapter 2 UI assertion(s) failed" % failures.size())
		quit(1)


func _first_event(trace: SimulationTraceType, kind: StringName) -> SimulationEventType:
	for event: SimulationEventType in trace.events:
		if event.kind == kind:
			return event
	return null


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _reveals_cache_term(text: String) -> bool:
	var normalized := text.to_lower()
	return "cache" in normalized or "缓存" in text or "命中" in text or "未命中" in text
