extends SceneTree

const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")
const SimulationEventType = preload("res://src/simulation/simulation_event.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")
const UiTypographyType = preload("res://src/ui/ui_typography.gd")

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
	var clock_period_control: SpinBox = main.get("clock_period_control")
	_assert(
		clock_period_control != null
		and clock_period_control.name == "PlaybackFrequencyControl"
		and is_equal_approx(clock_period_control.value, 2.0)
		and clock_period_control.suffix == "Hz",
		"Chapter 2 must expose the shared editable playback-frequency control."
	)
	clock_period_control.value = 10.0
	_assert(is_equal_approx(float(main.get("clock_period_seconds")), 0.1), "Chapter 2 playback Hz must update presentation duration only.")
	_assert(
		int(ProjectSettings.get_setting("display/window/size/mode", 0)) == 3
		and bool(ProjectSettings.get_setting("display/window/size/resizable", false))
		and String(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand",
		"The game window must default to resizable fullscreen and expand its logical desktop across the available aspect ratio."
	)
	_assert(root.has_node("WindowMode") and main.get("fullscreen_button") != null, "Every gameplay screen must expose the shared fullscreen controller and visible toggle.")
	var terminology_handbook: Control = main.get("terminology_handbook")
	_assert(terminology_handbook != null, "Chapter 2 must expose the shared terminology handbook.")
	var terminology_button: Button = terminology_handbook.get("entry_button")
	var terminology_rect := Rect2(terminology_button.global_position, terminology_button.size)
	_assert(
		terminology_rect.end.x >= main.size.x - 16.1 and terminology_rect.end.y >= main.size.y - 16.1
		and Rect2(Vector2.ZERO, main.size).encloses(terminology_rect),
		"The terminology entry must stay anchored at the bottom-right corner."
	)
	terminology_handbook.call("open_handbook", &"truth_table")
	var terminology_tree: Tree = terminology_handbook.get("term_tree")
	var terminology_ids: Array = terminology_handbook.get("visible_term_ids")
	_assert(terminology_ids.size() == 89 and _unique_count(terminology_ids) == 89, "The global handbook must classify all 89 terms exactly once before filtering.")
	_assert(
		terminology_tree.get_root().get_child_count() == 4
		and _tree_max_depth(terminology_tree.get_root()) == 3
		and _tree_directory_count(terminology_tree.get_root()) == 14,
		"The handbook must organize terms into four top-level topics and fourteen second-level directories without exceeding three visible levels."
	)
	var terminology_search: LineEdit = terminology_handbook.get("search_edit")
	terminology_search.text = "真值表"
	terminology_handbook.call("_refresh_terms")
	await process_frame
	_assert((terminology_handbook.get("visible_term_ids") as Array).size() == 1, "Terminology search must narrow the handbook to the matching concept while retaining its directory path.")
	_assert("00" in (terminology_handbook.get("detail_body_label") as RichTextLabel).text, "The truth-table entry must immediately define its four two-input rows for a new player.")
	terminology_search.clear()
	terminology_handbook.call("_refresh_terms", &"accumulator")
	await process_frame
	var terminology_diagram: Control = terminology_handbook.get("detail_diagram")
	var terminology_example: RichTextLabel = terminology_handbook.get("detail_example_label")
	_assert(
		terminology_diagram.visible
		and StringName(terminology_diagram.get("diagram_id")) == &"accumulator"
		and "ADD_IMM 2" in terminology_example.text
		and "ACC=5" in terminology_example.text,
		"Difficult Handbook entries must pair their definition with a concrete worked example and the matching in-game diagram."
	)
	for illustrated_term: StringName in [
		&"multiplexer", &"alu", &"sr_latch", &"decoder", &"bus", &"accumulator",
		&"serialization", &"cpu_wait", &"bottleneck", &"cache", &"working_set", &"blocking",
	]:
		terminology_handbook.call("_refresh_terms", illustrated_term)
		await process_frame
		_assert(
			terminology_diagram.visible and not terminology_example.text.is_empty(),
			"Illustrated Handbook term %s must expose both its diagram and worked example." % illustrated_term
		)
	terminology_handbook.call("_refresh_terms", &"bit")
	await process_frame
	_assert(not terminology_diagram.visible and not terminology_example.visible, "Simple Handbook terms must remain concise without an empty illustration block.")
	var handbook_escape := InputEventKey.new()
	handbook_escape.pressed = true
	handbook_escape.keycode = KEY_ESCAPE
	main.call("_input", handbook_escape)
	_assert(not bool(terminology_handbook.call("is_open")) and (main.get("chapter_map_host") as Control).visible, "Escape must close the handbook before navigating away from the Chapter 2 map.")
	_assert(
		main.get("mode_selector") != null
		and not (main.get("mode_selector") as Control).visible
		and not bool(game_mode.call("is_test_mode")),
		"A normal launch must start in Game mode with the developer selector hidden."
	)
	_assert((main.get("chapter_map_host") as Control).visible, "Chapter 2 must open on its seven-level investigation map rather than dropping directly into the old lab.")
	game_mode.call("set_mode", &"test")
	var locality_state: Node = root.get_node("LocalityChapter")
	for completed_level: StringName in [&"distant_reads", &"nearby_storage", &"cache_failure", &"access_order", &"working_set", &"blocking"]:
		locality_state.call("mark_completed", completed_level)
	main.call("_start_level", &"capstone")
	for _level_frame: int in range(3):
		await process_frame
	_assert(graph != null, "Main UI must create the fixed Machine Workbench GraphEdit.")
	_assert(graph.get_connection_list().size() == 6, "Fixed topology must contain all six programmatic links.")
	_assert(instruments.size() == 7, "Chapter 2 must retain the four v0.2 instruments and add Mission, Work Group, and Notebook.")
	for id: StringName in instruments:
		_assert((instruments[id] as Control).visible == (id == &"mission"), "Only Mission should open automatically when a Chapter 2 level starts (%s)." % id)
	var chapter2_mission: Control = instruments[&"mission"]
	var chapter2_mission_minimize: Button = chapter2_mission.find_child("MinimizeButton", true, false)
	_assert(not chapter2_mission_minimize.visible and (main.get("mission_title_label") as Label).get_theme_font_size("font_size") == UiTypographyType.TITLE_SIZE and (main.get("mission_objective_label") as RichTextLabel).get_theme_font_size("font_size") == UiTypographyType.BODY_SIZE, "Chapter 2 Mission must use the shared title/body sizes and omit minimization.")
	var mission_position: Vector2 = chapter2_mission.position
	var mission_size: Vector2 = chapter2_mission.size
	var mission_button: Button = (main.get("instrument_open_buttons") as Dictionary)[&"mission"]
	mission_button.pressed.emit()
	_assert(not chapter2_mission.visible, "The active Chapter 2 Mission button must close its window.")
	mission_button.pressed.emit()
	_assert(chapter2_mission.visible and chapter2_mission.position.is_equal_approx(mission_position) and chapter2_mission.size.is_equal_approx(mission_size), "Reopening Chapter 2 Mission must restore its remembered position and size.")
	main.call("_close_instrument", &"mission")
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
	var instrument_host: Control = main.get("instrument_host")
	program_window.position = instrument_host.size + Vector2(300.0, 200.0)
	program_window.size = instrument_host.size * 2.0
	program_window.call("fit_to_parent", 10.0)
	_assert(_control_fits(program_window, instrument_host, 10.0), "A resized/fullscreen workbench must pull every floating instrument completely back inside the visible desktop.")
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
	_assert(int(column_one.metrics["total_cycles"]) == 642 and not bool(main.get("current_goal_met")), "The capstone's two-pass column-first baseline must be correct but far above 145 cycles.")
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
	_assert("642" in profiler_summary.text and "608" in profiler_summary.text, "Profiler summary must match the capstone's authoritative two-pass trace metrics.")
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
	_assert(int(column_four.metrics["total_cycles"]) == 138 and bool(main.get("current_goal_met")), "Column-first plus four lines must meet the capstone target through hardware capacity.")
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
	_assert(int(row_one.metrics["total_cycles"]) == 210 and not bool(main.get("current_goal_met")), "Good access order alone must still reload a working set larger than the one-line Cache.")
	_assert(int(row_one.metrics["hardware_cost"]) == 4, "Software solution must record lower hardware cost 4.")
	_assert(row_one.program_source == ProgramTemplatesType.ROW_FIRST, "SimulationTrace must retain the exact explicitly applied row-first source.")
	main.call("_select_block_lines", 1, true)
	main.call("_run_simulation", "Official Test Set")
	var row_blocked: SimulationTraceType = main.get("current_trace")
	_assert(int(row_blocked.metrics["total_cycles"]) == 138 and bool(main.get("current_goal_met")), "Line-sized blocking with the one-line Cache must provide a low-cost capstone solution.")
	_assert(String(main.get("last_executed_source")) == ProgramTemplatesType.ROW_FIRST and not bool(main.get("program_dirty")), "Last-run receipt must prove the edited row-first source was executed.")
	var run_label: Label = main.get("program_run_label")
	_assert(_t(&"strategy.row_first") in run_label.text and "138" in run_label.text and "4" in run_label.text, "Program instrument must report the measurable result of the blocked edited source.")
	var history: Array[Dictionary] = main.get("run_history")
	_assert(history.size() == 4, "Run History must retain all compared evidence across program, Cache, and blocking changes.")
	var history_label: Label = main.get("profiler_history_label")
	_assert("642" in history_label.text and "138" in history_label.text and "CPU WAIT" in history_label.text, "Run History must keep the authored Baseline → Current total and wait deltas visible after several experiments.")
	_assert("个人最佳" in history_label.text or "Personal best" in history_label.text, "Run History must identify the best official result instead of losing it among adjacent runs.")

	main.queue_free()
	await process_frame
	var hub_scene: PackedScene = load("res://src/ui/prototype_hub.tscn")
	var hub: Control = hub_scene.instantiate()
	root.add_child(hub)
	for _hub_frame: int in range(2):
		await process_frame
	_assert(hub.get("fullscreen_button") != null, "The startup hub must expose the same visible fullscreen toggle as both gameplay screens.")
	_assert(hub.get("terminology_handbook") != null, "Chapter selection must keep the terminology handbook available in the bottom-right corner.")
	var hub_fullscreen: Button = hub.get("fullscreen_button")
	var fullscreen_rect := Rect2(hub_fullscreen.position, hub_fullscreen.size)
	_assert(
		Rect2(Vector2.ZERO, hub.size).encloses(fullscreen_rect),
		"The Hub fullscreen control must remain inside the visible viewport; got %s in %s." % [fullscreen_rect, hub.size]
	)
	var options_overlay: Control = hub.get("options_overlay")
	var options_resume: Button = hub.get("options_resume_button")
	var options_fullscreen: Button = hub.get("options_fullscreen_button")
	var options_export: Button = hub.get("options_export_button")
	var options_export_status: Label = hub.get("options_export_status")
	var options_quit: Button = hub.get("options_quit_button")
	var hub_escape := InputEventKey.new()
	hub_escape.keycode = KEY_ESCAPE
	hub_escape.pressed = true
	hub.call("_unhandled_key_input", hub_escape)
	_assert(
		options_overlay.visible
		and options_resume.text == _t(&"hub.options.resume")
		and options_export.text == _t(&"playtest.export.button")
		and options_quit.text == _t(&"hub.options.quit")
		and options_fullscreen.text in [_t(&"window.fullscreen.enter"), _t(&"window.fullscreen.exit")],
		"Esc on chapter selection must open a localized Options menu with Resume, fullscreen, Playtest export, and Quit actions."
	)
	options_export.pressed.emit()
	_assert(
		not options_export_status.text.is_empty(),
		"Playtest export must report a contained success or failure without blocking the Options menu."
	)
	hub.call("_unhandled_key_input", hub_escape)
	_assert(not options_overlay.visible, "A second Esc on chapter selection must close Options and return to chapter selection.")
	var hub_handbook: Control = hub.get("terminology_handbook")
	hub_handbook.call("open_handbook", &"truth_table")
	hub.call("_input", hub_escape)
	_assert(not bool(hub_handbook.call("is_open")) and not options_overlay.visible, "Esc must close the handbook without also opening Options.")
	hub.queue_free()
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


func _tree_max_depth(item: TreeItem, depth: int = 0) -> int:
	var maximum: int = depth
	var child: TreeItem = item.get_first_child()
	while child != null:
		maximum = maxi(maximum, _tree_max_depth(child, depth + 1))
		child = child.get_next()
	return maximum


func _tree_directory_count(root_item: TreeItem) -> int:
	var count: int = 0
	var category: TreeItem = root_item.get_first_child()
	while category != null:
		count += category.get_child_count()
		category = category.get_next()
	return count


func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value: Variant in values:
		unique[value] = true
	return unique.size()


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


func _control_fits(control: Control, parent: Control, margin: float) -> bool:
	return (
		control.position.x >= margin - 0.1
		and control.position.y >= margin - 0.1
		and control.position.x + control.size.x <= parent.size.x - margin + 0.1
		and control.position.y + control.size.y <= parent.size.y - margin + 0.1
	)


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
