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
	_assert((main.get("instrument_windows") as Dictionary)[&"mission"].minimized, "Running evidence must collapse the Mission window so it cannot cover the CPU → memory Trace path.")
	_assert(int(direct.metrics["total_cycles"]) == 257 and int(direct.metrics["wait_cycles"]) == 240, "2-1 must expose repeated distant-read waiting with exact deterministic metrics.")
	_assert(_first_event(direct, &"value_return").route_devices == [&"RAM", &"Bus", &"CPU"], "2-1 Trace must carry each raw value back along RAM → Bus → CPU.")
	_assert(not (main.get("next_evidence_button") as Button).disabled and not (main.get("finish_playback_button") as Button).disabled, "A long Trace must offer key-evidence navigation and an explicit finish action.")
	main.call("_jump_to_next_evidence")
	var selected_evidence: SimulationEventType = direct.events[int(main.get("playback_index"))]
	_assert(selected_evidence.kind in [&"cache_hit", &"cache_miss", &"cache_evict", &"ram_access", &"store_result"], "Next evidence must land on a causal memory or result event without altering the Trace.")
	var adjacent_evidence_index: int = -1
	for event_index: int in range(1, direct.events.size()):
		if direct.events[event_index].kind in [&"cache_hit", &"cache_miss", &"cache_evict", &"ram_access", &"store_result"] and direct.events[event_index - 1].kind not in [&"cache_hit", &"cache_miss", &"cache_evict", &"ram_access", &"store_result"]:
			adjacent_evidence_index = event_index
			break
	_assert(adjacent_evidence_index > 0, "The authored Trace must contain a key event immediately after ordinary flow evidence.")
	main.set("playback_index", adjacent_evidence_index - 1)
	main.set("playback_index_is_next_unshown", false)
	main.call("_step_trace")
	main.call("_jump_to_next_evidence")
	_assert(int(main.get("playback_index")) == adjacent_evidence_index, "Next evidence after Step must include the next unshown event instead of skipping an adjacent key event.")
	_assert(not bool(locality_state.call("completed_levels").get(&"distant_reads", false)), "Running an observation alone must not complete it.")
	main.call("_select_judgment", &"repeated_ram")
	_assert(not bool(locality_state.call("completed_levels").get(&"distant_reads", false)), "A correct explanation must remain pending while its authoritative Trace is still playing.")
	_assert(not (main.get("mission_review_button") as Button).visible and not (main.get("level_completion_overlay") as Control).visible, "2-1 must not cover raw evidence with an immediate completion layer.")
	main.call("_finish_playback")
	_assert((main.get("mission_review_button") as Button).visible, "Finishing playback must expose an explicit Review finding action.")
	main.call("_review_pending_finding")
	_assert(bool(locality_state.call("completed_levels").get(&"distant_reads", false)), "2-1 must complete only after the player reviews the evidence-supported finding.")
	_assert((main.get("level_completion_overlay") as Control).visible, "Reviewing a completed short investigation must present its concise conclusion.")

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
	var inherited_history: Array = main.get("run_history")
	_assert(inherited_history.size() == 1 and int(inherited_history[0]["cycles"]) == 257 and bool(inherited_history[0]["bypass_cache"]), "2-2 must inherit 2-1's qualifying direct-memory receipt as its read-only Before evidence.")
	var inherited_receipts: Array = main.call("_completion_receipts")
	_assert(inherited_receipts.size() == 1 and inherited_receipts[0].level_id == &"distant_reads" and catalog.call("is_qualifying_paired_baseline", &"nearby_storage", inherited_receipts[0]), "Paired evidence must remain owned by 2-1 and pass an explicit strict-configuration check instead of being rewritten as a 2-2 receipt.")
	main.call("_select_cache", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var nearby: SimulationTraceType = main.get("current_trace")
	_assert(int(nearby.metrics["total_cycles"]) == 105 and int(nearby.metrics["cache_misses"]) == 4 and int(nearby.metrics["cache_hits"]) == 12, "2-2 must show a first fetch followed by nearby reuse on every line.")
	_assert(not bool(locality_state.call("completed_levels").get(&"nearby_storage", false)), "2-2 must keep the nearby mechanism unnamed until the player reviews the successful comparison.")
	_assert(not locality_state.call("concept_unlocked", &"cache") and not (main.get("level_completion_overlay") as Control).visible, "The successful run must leave Trace and Profiler evidence visible before terminology is revealed.")
	var comparison_text: String = (main.get("profiler_history_label") as Label).text
	_assert("257" in comparison_text and "105" in comparison_text and "CPU WAIT" in comparison_text, "2-2 Run History must foreground Before → After total and CPU-wait deltas.")
	main.call("_toggle_pause")
	main.call("_step_trace")
	_assert(bool(main.get("pending_completion_review")) and not (main.get("mission_review_button") as Button).visible, "Pausing and stepping must preserve the pending finding without revealing Review before the end.")
	main.call("_invalidate_current_run", "test invalidation")
	_assert(not bool(main.get("pending_completion_review")) and main.get("current_trace") == null, "Invalidating inputs must clear a pending review tied to stale evidence.")
	main.call("_run_simulation", "Official Test Set")
	_assert(bool(main.get("pending_completion_review")) and not (main.get("mission_review_button") as Button).visible, "Rerunning the successful comparison must create a fresh pending review bound to the new playback.")
	main.call("_finish_playback_early")
	_assert(bool(main.get("playback_completed")) and (main.get("finish_playback_button") as Button).disabled, "Finishing a Trace early must use the canonical playback completion path.")
	main.call("_review_pending_finding")
	_assert(bool(locality_state.call("completed_levels").get(&"nearby_storage", false)), "2-2 must complete after the inherited direct path and new nearby path are reviewed together.")
	_assert(locality_state.call("concept_unlocked", &"cache") and locality_state.call("concept_unlocked", &"hit") and locality_state.call("concept_unlocked", &"miss"), "Cache, Hit, and Miss terminology must unlock only after the exploration.")
	_assert(_reveals_cache_term(cache_node.title), "Completing 2-2 must visibly name the nearby mechanism as Cache.")

	main.call("_start_level", &"cache_failure")
	main.call("_run_simulation", "Official Test Set")
	var failure_trace: SimulationTraceType = main.get("current_trace")
	_assert(int(failure_trace.metrics["total_cycles"]) == 321 and int(failure_trace.metrics["cache_misses"]) == 16, "2-3 must create the clear cognitive reversal: Cache present, yet every access misses.")
	main.call("_select_judgment", &"replacement")
	_assert(not bool(locality_state.call("completed_levels").get(&"cache_failure", false)), "2-3 must leave its causal Trace inspectable before revealing the finding.")
	main.call("_finish_playback")
	main.call("_review_pending_finding")
	_assert(bool(locality_state.call("completed_levels").get(&"cache_failure", false)), "2-3 must require the replacement-before-reuse explanation.")

	main.call("_start_level", &"access_order")
	var access_history: Array = main.get("run_history")
	_assert(access_history.size() == 1 and int(access_history[0]["cycles"]) == 321 and String(access_history[0]["pattern"]) == "column-first", "2-4 must carry 2-3's failed access pattern forward as its Before evidence.")
	main.call("_load_strategy", ProgramTemplatesType.ROW_FIRST, "row-first")
	main.call("_apply_program")
	main.call("_run_simulation", "Official Test Set")
	var local_trace: SimulationTraceType = main.get("current_trace")
	_assert(int(local_trace.metrics["total_cycles"]) == 105 and int(local_trace.metrics["hardware_cost"]) == 4, "2-4 must meet the target by changing access order without upgrading Cache.")
	_assert(not locality_state.call("concept_unlocked", &"locality"), "Locality terminology must remain locked while the successful Trace is being inspected.")
	main.call("_finish_playback")
	main.call("_review_pending_finding")
	_assert(locality_state.call("concept_unlocked", &"locality"), "Locality must unlock after the player implements the access-order repair.")
	_assert("访问顺序" in (main.get("profiler_history_label") as Label).text or "access order" in (main.get("profiler_history_label") as Label).text, "2-4 comparison must identify access order as the changed item.")

	main.call("_start_level", &"working_set")
	main.call("_run_simulation", "Official Test Set")
	var working_set_trace: SimulationTraceType = main.get("current_trace")
	_assert(int(working_set_trace.metrics["total_cycles"]) == 210 and int(working_set_trace.metrics["cache_misses"]) == 8, "2-5 must reload all four lines despite already-good row-first order.")
	main.call("_select_judgment", &"does_not_fit")
	main.call("_finish_playback")
	main.call("_review_pending_finding")
	_assert(locality_state.call("concept_unlocked", &"working_set"), "Working Set must unlock only after the player explains the capacity mismatch.")

	main.call("_start_level", &"blocking")
	var blocking_history: Array = main.get("run_history")
	_assert(blocking_history.size() == 1 and int(blocking_history[0]["cycles"]) == 210 and int(blocking_history[0]["block_lines"]) == 0, "2-6 must inherit the unblocked Working Set evidence instead of rerunning it.")
	main.call("_select_block_lines", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var blocked: SimulationTraceType = main.get("current_trace")
	_assert(int(blocked.metrics["total_cycles"]) == 138, "2-6 must turn work grouping into a measurable decision against the inherited 210-cycle baseline.")
	_assert(int(blocked.metrics["cache_misses"]) == 4 and int(blocked.metrics["hardware_cost"]) == 4, "2-6 must shrink the active working set without hardware replacement.")
	var schedule_groups: Array[Dictionary] = []
	_collect_schedule_groups((main.get("profiler_tree") as Tree).get_root(), schedule_groups)
	_assert(schedule_groups.size() == 8, "The Profiler must persist the four work groups × two passes as inspectable schedule evidence.")
	_assert(
		schedule_groups.size() >= 3
		and schedule_groups[0] == {"pass_index": 0, "work_group_index": 0}
		and schedule_groups[1] == {"pass_index": 1, "work_group_index": 0}
		and schedule_groups[2] == {"pass_index": 0, "work_group_index": 1},
		"Blocked schedule evidence must show both passes for one work group before advancing to the next group."
	)
	_assert(not locality_state.call("concept_unlocked", &"blocking"), "Blocking terminology must remain locked during the successful playback.")
	main.call("_finish_playback")
	main.call("_review_pending_finding")
	_assert(locality_state.call("concept_unlocked", &"blocking"), "Blocking/Tiling must unlock after the implementation succeeds.")

	main.call("_start_level", &"capstone")
	var capstone_cache_buttons: Dictionary = main.get("cache_card_buttons")
	var capstone_block_buttons: Dictionary = main.get("block_card_buttons")
	_assert(not (main.get("editor") as TextEdit).editable, "2-7 must keep program changes locked until the given baseline has produced evidence.")
	_assert((capstone_cache_buttons[4] as Button).disabled and (capstone_block_buttons[1] as Button).disabled, "2-7 must prevent hardware or work-group changes before the baseline run.")
	main.call("_run_simulation", "Official Test Set")
	var capstone_baseline: SimulationTraceType = main.get("current_trace")
	_assert(int(capstone_baseline.metrics["total_cycles"]) == 642 and not bool(main.get("current_goal_met")), "2-7 must start from a new unresolved workload without suggesting a solution.")
	_assert(not catalog.call("capstone_modified_experiment_seen", locality_state.call("receipts_for", &"capstone")), "The exact authored capstone baseline must not count as the first modified experiment.")
	var capstone_profiler: Tree = main.get("profiler_tree")
	var raw_cycles: TreeItem = capstone_profiler.get_root().get_child(0)
	var raw_memory: TreeItem = capstone_profiler.get_root().get_child(1)
	_assert(raw_cycles.get_child_count() == 1 and raw_memory.get_child_count() == 1, "Before diagnosis, the capstone Profiler must show raw totals while withholding the aggregate cycle and memory breakdown.")
	var raw_history: String = (main.get("profiler_history_label") as Label).text
	var expected_raw_history: String = "\n".join([
		main.call("_t", &"chapter2.capstone.history.raw_title"),
		main.call("_t", &"chapter2.capstone.history.raw_metrics", [642, 608, 32]),
		main.call("_t", &"chapter2.capstone.history.diagnose_first"),
	])
	_assert(raw_history == expected_raw_history, "Run History must share the diagnosis gate and expose only total, CPU WAIT, and request count before the first diagnosis.")
	_assert(not (main.get("editor") as TextEdit).editable, "The baseline alone must not unlock program changes before a diagnosis.")
	_assert((capstone_cache_buttons[4] as Button).disabled and (capstone_block_buttons[1] as Button).disabled, "Hardware and work-group decisions must remain locked until the raw evidence is diagnosed.")
	main.call("_select_cache", 4, true)
	_assert(int(main.get("current_cache_lines")) == 1 and main.get("current_trace") == capstone_baseline, "A direct change attempt must not bypass the capstone diagnosis gate.")
	main.call("_select_judgment", &"more_cpu_math")
	_assert(not (main.get("editor") as TextEdit).editable and (capstone_cache_buttons[4] as Button).disabled, "An unsupported diagnosis must keep every solution control locked.")
	main.call("_select_judgment", &"repeated_far_fetch")
	var revealed_cycles: TreeItem = capstone_profiler.get_root().get_child(0)
	var revealed_memory: TreeItem = capstone_profiler.get_root().get_child(1)
	_assert((main.get("editor") as TextEdit).editable, "A correct evidence diagnosis must unlock program investigation.")
	_assert(not (capstone_cache_buttons[4] as Button).disabled and not (capstone_block_buttons[1] as Button).disabled, "A correct diagnosis must unlock the capstone's existing hardware and work-group decisions.")
	_assert(revealed_cycles.get_child_count() >= 2 and revealed_memory.get_child_count() >= 2, "The full Profiler breakdown must appear only after the correct first diagnosis.")
	main.call("_select_cache", 4, true)
	main.call("_select_block_lines", 1, true)
	_assert(int(main.get("current_block_lines")) == 0, "The first capstone experiment must reject a second simultaneous lever so its result remains attributable.")
	main.call("_run_simulation", "Official Test Set")
	var hardware_solution: SimulationTraceType = main.get("current_trace")
	_assert(int(hardware_solution.metrics["total_cycles"]) == 138 and int(hardware_solution.metrics["hardware_cost"]) == 13, "The capstone must accept a larger-Cache hardware solution.")
	_assert(catalog.call("capstone_modified_experiment_seen", locality_state.call("receipts_for", &"capstone")), "The first one-lever run must create official evidence without treating receipt creation as observation.")
	_assert(bool(main.call("_capstone_first_experiment_pending")) and not bool(locality_state.call("completed_levels").get(&"capstone", false)), "The first experiment must remain controlled and incomplete until its Trace is observed.")
	main.call("_select_block_lines", 1, true)
	_assert(int(main.get("current_block_lines")) == 0, "A second lever must remain blocked while the first experiment Trace is still unobserved.")
	main.call("_start_level", &"capstone")
	main.call("_run_simulation", "Official Test Set")
	main.call("_select_judgment", &"repeated_far_fetch")
	main.call("_finish_playback")
	_assert(not locality_state.call("capstone_first_experiment_observed") and not bool(locality_state.call("completed_levels").get(&"capstone", false)), "Re-entering the level and finishing a baseline Trace must not consume an earlier unobserved target receipt or complete the chapter.")
	main.call("_select_cache", 4, true)
	main.call("_run_simulation", "Official Test Set")
	main.call("_finish_playback")
	_assert(locality_state.call("capstone_first_experiment_observed") and not bool(main.call("_capstone_first_experiment_pending")), "Finishing the first experiment Trace must unlock later combination experiments.")
	_assert(bool(locality_state.call("completed_levels").get(&"capstone", false)), "A correct capstone run at or below 145 cycles must complete only after its evidence is observed.")
	_assert(not (main.get("level_completion_overlay") as Control).visible and (main.get("mission_finish_button") as Button).visible, "Capstone completion must leave the lab active so the player may keep optimizing.")
	main.call("_select_cache", 1, true)
	main.call("_select_block_lines", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var software_solution: SimulationTraceType = main.get("current_trace")
	_assert(int(software_solution.metrics["total_cycles"]) == 138 and int(software_solution.metrics["hardware_cost"]) == 4, "The capstone must also accept a lower-cost blocking solution.")
	_assert((main.get("lab_host") as Control).visible and bool(locality_state.call("completed_levels").get(&"capstone", false)), "Further optimization must remain possible after chapter completion.")
	var capstone_history: String = (main.get("profiler_history_label") as Label).text
	_assert("642" in capstone_history and "138" in capstone_history and ("个人最佳" in capstone_history or "Personal best" in capstone_history), "Run History must keep Baseline → Current visible and identify the best lower-cost solution after several experiments.")
	var notebook_text: String = (main.get("notebook_label") as RichTextLabel).text
	for learned_term: String in ["CPU WAIT", "Cache", "Locality", "Working Set", "Blocking"]:
		_assert(learned_term in notebook_text, "The completed Systems Notebook must retain %s." % learned_term)
	main.call("_show_capstone_summary")
	var completion_overlay: Control = main.get("level_completion_overlay")
	_assert(completion_overlay.visible, "Finish Chapter must present a final evidence summary before returning to the map.")
	var summary_text: String = (completion_overlay.get("summary_label") as Label).text
	_assert("642" in summary_text and "138" in summary_text and "4" in summary_text, "The final summary must compare the baseline with the best lower-cost solution.")
	completion_overlay.call("_on_continue_pressed")
	_assert((main.get("chapter_map_host") as Control).visible, "Continuing from the final summary must return to the Chapter 2 map.")

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


func _collect_schedule_groups(item: TreeItem, output: Array[Dictionary]) -> void:
	if item == null:
		return
	var metadata: Variant = item.get_metadata(1)
	if metadata is Dictionary and metadata.has("pass_index") and metadata.has("work_group_index"):
		output.append((metadata as Dictionary).duplicate())
	for child_index: int in range(item.get_child_count()):
		_collect_schedule_groups(item.get_child(child_index), output)
