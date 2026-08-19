extends SceneTree

const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_resource: PackedScene = load("res://src/ui/main.tscn")
	var main: Control = scene_resource.instantiate()
	root.add_child(main)
	for _frame: int in range(4):
		await process_frame

	var graph: GraphEdit = main.get("graph")
	var instruments: Dictionary = main.get("instrument_windows")
	var game_mode: Node = root.get_node("GameMode")
	_assert(main.get("mode_selector") != null and not bool(game_mode.call("is_test_mode")), "The locality lab must expose the shared selector and start in Game mode by default.")
	_assert(graph != null, "Main UI must create the fixed Machine Workbench GraphEdit.")
	_assert(graph.get_connection_list().size() == 6, "Fixed topology must contain all six programmatic links.")
	_assert(instruments.size() == 4, "Program, Test Bench, Profiler, and Cache must each own a floating instrument.")
	for id: StringName in instruments:
		_assert(not (instruments[id] as Control).visible, "%s instrument must be closed by default." % id)
	for device_name: String in ["ProgramController", "CPU", "Cache", "Bus", "RAM", "TestBench", "Profiler"]:
		_assert(graph.has_node(NodePath(device_name)), "Workbench must contain %s." % device_name)
	var connection_count: int = graph.get_connection_list().size()
	graph.emit_signal("connection_request", &"RAM", 0, &"CPU", 0)
	await process_frame
	_assert(graph.get_connection_list().size() == connection_count, "A user connection request must not edit the fixed topology.")

	main.call("_open_instrument", &"profiler")
	main.call("_open_instrument", &"program")
	var profiler_window: Control = instruments[&"profiler"]
	var program_window: Control = instruments[&"program"]
	_assert(profiler_window.visible and program_window.visible, "Program and Profiler instruments must coexist instead of replacing one another.")
	var program_position: Vector2 = program_window.position
	var program_size: Vector2 = program_window.size
	program_window.call("move_by", Vector2(44.0, 26.0))
	program_window.call("resize_by", Vector2(36.0, 18.0))
	_assert(not program_window.position.is_equal_approx(program_position), "A floating instrument must be movable inside the workbench.")
	_assert(not program_window.size.is_equal_approx(program_size), "A floating instrument must be resizable within the available workbench bounds.")
	main.call("_close_instrument", &"profiler")
	_assert(not profiler_window.visible and program_window.visible, "Closing Profiler must leave Program open.")
	main.call("_open_instrument", &"profiler")

	var cache_node: GraphNode = graph.get_node("Cache")
	var canonical_cache_position: Vector2 = cache_node.position_offset
	cache_node.position_offset += Vector2(70.0, 95.0)
	await process_frame
	main.call("_auto_layout", false)
	await process_frame
	_assert(cache_node.position_offset.is_equal_approx(canonical_cache_position), "Auto Layout must restore the canonical Cache position.")

	var effect_label: Label = main.get("program_effect_label")
	_assert(_t(&"strategy.column_first") in effect_label.text and "0 → 4 → 8 → 12" in effect_label.text, "Program must preview the starter's real column-first address order before a run.")
	var explanation_label: RichTextLabel = main.get("program_explanation_label")
	var apply_label: Label = main.get("program_apply_label")
	var apply_button: Button = main.get("apply_program_button")
	var official_button: Button = main.get("official_run_button")
	_assert(_t(&"dsl.explanation.for_range.outer", ["col"]) in explanation_label.text and "A[row][col]" in explanation_label.text, "Program must explain the parsed starter line by line.")
	_assert(String(main.get("applied_program_source")) == ProgramTemplatesType.COLUMN_FIRST and apply_label.text == _t(&"program.apply.applied", [_t(&"strategy.column_first")]), "Column-first starter must begin as the explicit applied program.")
	_assert(not official_button.disabled and apply_button.disabled, "Applied starter may run immediately and does not need redundant confirmation.")
	_assert((main.get("column_strategy_button") as Button) != null and (main.get("row_strategy_button") as Button) != null, "Both column-first and row-first strategy controls must be directly available.")
	main.call("_run_simulation", "Official Test Set")
	var column_one: SimulationTraceType = main.get("current_trace")
	_assert(column_one != null and column_one.passed, "Official starter run must remain correct.")
	_assert(int(column_one.metrics["total_cycles"]) == 321 and not bool(main.get("current_goal_met")), "Column-first plus one line must be correct but over the 105-cycle target.")
	_assert(program_window.visible and profiler_window.visible, "Starting playback must preserve every instrument the player chose to keep open.")
	_assert(String(main.get("last_executed_source")) == ProgramTemplatesType.COLUMN_FIRST, "Run must capture and execute the exact applied source.")

	var request_event: SimulationEventType = _first_event(column_one, &"request")
	var miss_event: SimulationEventType = _first_event(column_one, &"cache_miss")
	var return_event: SimulationEventType = _first_event(column_one, &"line_return")
	_assert(request_event != null and miss_event != null and return_event != null, "Official trace must expose request, miss, and line-return stages.")
	var request_curve: PackedVector2Array = main.call("_connection_curve", &"CPU", &"Cache")
	var request_path: PackedVector2Array = main.call("_event_path", request_event)
	_assert(_paths_equal(request_path, request_curve), "Authoritative request wiring must remain the exact displayed CPU → Cache curve.")
	var request_animation: Dictionary = main.call("_event_animation", request_event)
	var request_ranges: Array = request_animation["processing_ranges"]
	_assert(request_ranges.size() == 3, "A load request must visibly process in Program, CPU, and Cache in sequence.")
	_assert((request_animation["path"] as PackedVector2Array).size() > request_curve.size(), "Presentation must add internal component paths instead of jumping from input to output.")
	if request_ranges.size() == 3:
		_assert(StringName(request_ranges[0]["device"]) == &"ProgramController" and StringName(request_ranges[1]["device"]) == &"CPU" and StringName(request_ranges[2]["device"]) == &"Cache", "Request processing order must be Program → CPU → Cache.")
		for process_range: Dictionary in request_ranges:
			var movement_midpoint: float = (float(process_range["start"]) + float(process_range["end"])) * 0.5
			var process_point: Vector2 = (main.get("trace_overlay") as Control).call("_point_on_path", request_animation["path"], movement_midpoint)
			_assert((process_range["rect"] as Rect2).has_point(process_point), "Component processing data must remain inside the actual displayed device body.")
			main.call("_draw_event", request_event, _raw_progress_for_movement(movement_midpoint))
			_assert(StringName(main.get("active_component")) == StringName(process_range["device"]), "Only the component containing the packet may be strongly active.")
		var wire_midpoint: float = (float(request_ranges[0]["end"]) + float(request_ranges[1]["start"])) * 0.5
		main.call("_draw_event", request_event, _raw_progress_for_movement(wire_midpoint))
		_assert(StringName(main.get("active_component")).is_empty(), "Wire travel must not light both endpoint components at once.")

	var return_path: PackedVector2Array = main.call("_event_path", return_event)
	var ram_bus: PackedVector2Array = main.call("_connection_curve", &"RAM", &"Bus")
	var bus_cache: PackedVector2Array = main.call("_connection_curve", &"Bus", &"Cache")
	_assert(return_path.size() == ram_bus.size() + bus_cache.size(), "Authoritative line-return wiring must retain the two exact reverse curves.")
	var return_animation: Dictionary = main.call("_event_animation", return_event)
	var return_ranges: Array = return_animation["processing_ranges"]
	_assert(return_ranges.size() == 3 and StringName(return_ranges[1]["device"]) == &"Bus", "Line return must visibly process RAM → Bus → Cache, including a Bus dwell.")
	_assert((return_animation["path"] as PackedVector2Array).size() > return_path.size(), "Line return must include internal RAM, Bus, and Cache processing paths.")

	var path_before_move: PackedVector2Array = request_path.duplicate()
	cache_node.position_offset += Vector2(65.0, 80.0)
	await process_frame
	var path_after_move: PackedVector2Array = main.call("_event_path", request_event)
	var curve_after_move: PackedVector2Array = main.call("_connection_curve", &"CPU", &"Cache")
	_assert(not _paths_equal(path_before_move, path_after_move), "Moving Cache must change the packet wire path.")
	_assert(_paths_equal(path_after_move, curve_after_move), "After movement the packet must still use the newly rendered connection curve.")
	main.call("_auto_layout", false)
	await process_frame

	var miss_animation: Dictionary = main.call("_event_animation", miss_event)
	var miss_range: Dictionary = (miss_animation["processing_ranges"] as Array)[0]
	_assert((miss_animation["path"] as PackedVector2Array).size() <= 5, "An internal Cache event must use a short in-body lane instead of an invented circular orbit.")
	_assert(not (main.get("trace_overlay") as Control).has_method("_draw_processing_indicator"), "The trace overlay must not draw a generic radial component indicator over the actual device.")
	main.call("_draw_event", miss_event, _raw_progress_for_movement((float(miss_range["start"]) + float(miss_range["end"])) * 0.5))
	var states: Dictionary = main.get("device_state_labels")
	_assert(StringName(main.get("active_component")) == &"Cache", "Cache miss must strongly highlight only Cache while it processes the lookup result.")
	_assert((states[&"CPU"] as Label).text == _t(&"state.waiting_for_memory"), "CPU may retain passive waiting context without simultaneous strong highlighting.")
	_assert((states[&"Cache"] as Label).text == _t(&"event.state.miss_line", [miss_event.cache_line]), "Active Cache feedback must identify the miss.")
	var editor: CodeEdit = main.get("editor")
	_assert(editor.get_line_background_color(miss_event.source_line - 1).a > 0.0 and program_window.visible, "The open Program instrument must visibly highlight the executing source line.")

	var profiler_tree: Tree = main.get("profiler_tree")
	var profiler_summary: Label = main.get("profiler_summary_label")
	_assert(profiler_tree.get_root() != null and profiler_tree.get_root().get_child_count() >= 2, "Profiler must expose expandable cycle and memory evidence.")
	_assert("321" in profiler_summary.text and "304" in profiler_summary.text, "Profiler summary must match authoritative trace metrics.")
	_assert("switch" not in profiler_summary.text.to_lower() and "poor stride" not in profiler_summary.text.to_lower(), "Profiler must not provide an optimization answer.")
	var first_miss_index: int = _first_event_index(column_one, &"cache_miss")
	main.set("selected_profiler_event_index", first_miss_index)
	main.call("_inspect_profiler_event")
	_assert(int(main.get("playback_index")) == first_miss_index and not bool(main.get("playback_running")), "Profiler Inspect must jump to and pause on the selected Trace event.")
	_assert(profiler_window.visible and program_window.visible, "Inspect in Trace must preserve the player's instrument workspace.")

	main.call("_select_cache", 4, true)
	_assert(main.get("current_trace") == null, "Replacing Cache must invalidate stale trace and Profiler evidence.")
	main.call("_run_simulation", "Official Test Set")
	var column_four: SimulationTraceType = main.get("current_trace")
	_assert(int(column_four.metrics["total_cycles"]) == 105 and bool(main.get("current_goal_met")), "Column-first plus four lines must meet the target through hardware capacity.")
	_assert(int(column_four.metrics["hardware_cost"]) == 13, "Four-line hardware solution must record cost 13.")

	main.call("_load_strategy", ProgramTemplatesType.ROW_FIRST, "row-first")
	await process_frame
	_assert(main.get("current_trace") == null and bool(main.get("program_dirty")), "Editing the Program must visibly mark prior evidence stale.")
	_assert(_t(&"strategy.row_first") in effect_label.text and "0 → 1 → 2 → 3" in effect_label.text, "Changing loop order must immediately preview a different address sequence.")
	_assert(_t(&"dsl.explanation.for_range.outer", ["row"]) in explanation_label.text, "Line-by-line explanation must update from the row-first draft IR.")
	_assert(String(main.get("applied_program_source")) == ProgramTemplatesType.COLUMN_FIRST, "Loading a strategy must not silently replace the applied program.")
	_assert(official_button.disabled and not apply_button.disabled and apply_label.text == _t(&"program.apply.draft_pending"), "An unapplied valid draft must block Test Bench and offer explicit Apply.")
	main.call("_select_cache", 1, true)
	main.call("_run_simulation", "Official Test Set")
	_assert(main.get("current_trace") == null and main.get("run_history").size() == 2, "Direct run calls must also reject an unapplied draft without adding evidence.")
	main.call("_apply_program")
	_assert(String(main.get("applied_program_source")) == ProgramTemplatesType.ROW_FIRST and not bool(main.get("program_dirty")), "Apply Program must confirm the exact row-first draft.")
	_assert(not official_button.disabled and apply_button.disabled and apply_label.text == _t(&"program.apply.applied", [_t(&"strategy.row_first")]), "Applying must unlock Test Bench and update visible application state.")
	main.call("_run_simulation", "Official Test Set")
	var row_one: SimulationTraceType = main.get("current_trace")
	_assert(int(row_one.metrics["total_cycles"]) == 105 and bool(main.get("current_goal_met")), "Row-first plus one line must meet the same target through software.")
	_assert(int(row_one.metrics["hardware_cost"]) == 4, "Software solution must record lower hardware cost 4.")
	_assert(row_one.program_source == ProgramTemplatesType.ROW_FIRST, "SimulationTrace must retain the exact explicitly applied row-first source.")
	_assert(String(main.get("last_executed_source")) == ProgramTemplatesType.ROW_FIRST and not bool(main.get("program_dirty")), "Last-run receipt must prove the edited row-first source was executed.")
	var run_label: Label = main.get("program_run_label")
	_assert(_t(&"strategy.row_first") in run_label.text and "105" in run_label.text and "4" in run_label.text, "Program instrument must report the measurable result of the edited source.")
	var history: Array[Dictionary] = main.get("run_history")
	_assert(history.size() == 3, "Run History must retain all compared evidence across program and Cache changes.")
	var history_label: Label = main.get("profiler_history_label")
	_assert("13" in history_label.text and "4" in history_label.text, "Run History must make the two valid solution costs comparable.")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: staged animation, floating instruments, explicit Program apply/explanation/strategies, Profiler, and Cache tradeoff tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d UI assertion(s) failed" % failures.size())
		quit(1)


func _first_event(trace: SimulationTraceType, kind: StringName) -> SimulationEventType:
	for event: SimulationEventType in trace.events:
		if event.kind == kind:
			return event
	return null


func _first_event_index(trace: SimulationTraceType, kind: StringName) -> int:
	for index: int in range(trace.events.size()):
		if trace.events[index].kind == kind:
			return index
	return -1


func _paths_equal(left: PackedVector2Array, right: PackedVector2Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if not left[index].is_equal_approx(right[index]):
			return false
	return true


func _raw_progress_for_movement(target: float) -> float:
	var low: float = 0.0
	var high: float = 1.0
	for _iteration: int in range(24):
		var middle: float = (low + high) * 0.5
		if smoothstep(0.0, 1.0, middle) < target:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _t(key: StringName, arguments: Array = []) -> String:
	var localization: Node = root.get_node("Localization")
	return localization.call("text", key, arguments)
