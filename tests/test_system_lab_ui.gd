extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_mode: Node = root.get_node("GameMode")
	var chapter: Node = root.get_node("SystemChapter")
	var game_cpu_source: String = String(chapter.get("cpu_source_signature"))
	var game_ram_source: String = String(chapter.get("ram_source_signature"))
	game_mode.call("set_mode", &"game")
	var hub_scene: PackedScene = load("res://src/ui/prototype_hub.tscn")
	var hub: Control = hub_scene.instantiate()
	root.add_child(hub)
	for _hub_frame: int in range(2):
		await process_frame
	_assert((hub.get("system_entry_button") as Button).disabled, "Game mode must gate Chapter 1 until the prologue provenance handoff.")
	var hub_fullscreen: Control = hub.get("fullscreen_button")
	_assert(hub.get_rect().encloses(hub_fullscreen.get_rect()), "The three-card hub must keep its fullscreen action completely on screen.")
	game_mode.call("set_mode", &"test")
	await process_frame
	_assert(not (hub.get("system_entry_button") as Button).disabled, "Test mode must expose the Chapter 1 hub entry immediately.")
	_assert(not bool(chapter.call("capture_prologue", {})), "Test mode must not fabricate or overwrite Game-mode prologue provenance.")
	hub.queue_free()
	await process_frame
	chapter.call("reset_test_progress")

	var scene: PackedScene = load("res://src/system_lab/system_lab.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	for _frame: int in range(5):
		await process_frame

	var map_view = main.get("map_view")
	var map_buttons: Dictionary = map_view.get("level_buttons")
	_assert(map_buttons.size() == 6, "Chapter map must expose the accepted six-level route.")
	for button: Button in map_buttons.values():
		_assert(not button.disabled, "Test mode must unlock every system chapter level.")
	_assert(
		String(chapter.get("cpu_source_signature")) == game_cpu_source
		and String(chapter.get("ram_source_signature")) == game_ram_source,
		"Test provenance must not overwrite player Game-mode source signatures."
	)

	main.call("_start_level", &"assembly")
	await process_frame
	var graph: GraphEdit = main.get("graph")
	_assert(graph.get_connection_list().is_empty(), "Assembly must begin laid out but unwired.")
	main.call("_auto_connect")
	await process_frame
	_assert(graph.get_connection_list().size() == 6, "Standard wiring must visibly create the six authoritative typed routes.")
	_assert(main.call("_topology_from_graph").is_valid(), "The simulation topology must be exported from the displayed graph.")
	_assert(graph.connection_lines_thickness == 0.0 and float(graph.get("settled_wire_thickness")) >= 6.0, "Chapter 1 must hide the native duplicate stroke and draw one player-colored route.")
	var system_port_image: Image = main.theme.get_icon("port", "GraphNode").get_image()
	_assert(system_port_image.get_width() == 24 and system_port_image.get_used_rect().size.x <= 13, "Chapter 1 ports must use the same compact visual disk without shrinking their GraphEdit interaction canvas.")
	var backward_route_found: bool = false
	for connection: Dictionary in graph.get_connection_list():
		var route_curve: PackedVector2Array = graph.call("connection_curve", connection)
		if route_curve.size() != 6 or route_curve[0].x <= route_curve[-1].x:
			continue
		var from_node: GraphNode = graph.get_node(NodePath(String(connection["from_node"])))
		var to_node: GraphNode = graph.get_node(NodePath(String(connection["to_node"])))
		var from_rect: Rect2 = graph.call("displayed_node_rect", from_node)
		var to_rect: Rect2 = graph.call("displayed_node_rect", to_node)
		var device_bottom: float = maxf(from_rect.end.y, to_rect.end.y)
		_assert(route_curve[2].y > device_bottom and route_curve[3].y > device_bottom, "Reverse-flow data must route below both devices instead of crossing their visible surfaces.")
		backward_route_found = true
	_assert(backward_route_found, "The read-data lane must exercise the explicit reverse-flow route.")
	var first_connection: Dictionary = graph.get_connection_list()[0]
	var first_curve: PackedVector2Array = graph.call("connection_curve", first_connection)
	var color_hover := InputEventMouseMotion.new()
	color_hover.position = first_curve[first_curve.size() / 2]
	graph.call("_gui_input", color_hover)
	main.call("_set_active_system_wire_color", 4)
	main.call("_color_hovered_system_wire", false)
	_assert(graph.call(
		"get_connection_color_index",
		first_connection["from_node"], first_connection["from_port"],
		first_connection["to_node"], first_connection["to_port"]
	) == 4, "The visible Chapter 1 palette must recolor the exact hovered route segment.")
	var first_lane: StringName = main.call("_system_connection_lane", first_connection)
	main.call("_set_active_system_wire_color", 5)
	main.call("_color_hovered_system_wire", true)
	var colored_lane_members: int = 0
	for connection: Dictionary in graph.get_connection_list():
		if main.call("_system_connection_lane", connection) != first_lane:
			continue
		_assert(graph.call(
			"get_connection_color_index",
			connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"]
		) == 5, "Ctrl+E semantics must recolor every displayed segment in the hovered request/write/read lane.")
		colored_lane_members += 1
	_assert(colored_lane_members == 2, "Every Chapter 1 logical lane must contain the two real CPU–Bus and Bus–RAM segments.")
	main.call("_save_level_session")
	var session: Dictionary = (main.get("level_sessions") as Dictionary)[main.call("_level_session_key", &"assembly")]
	var saved_custom_color: bool = false
	for connection: Dictionary in session.get("connections", []):
		saved_custom_color = saved_custom_color or int(connection.get("color_index", -1)) == 5
	_assert(saved_custom_color, "Chapter 1 session state must preserve player-selected route colors separately from topology evidence.")

	var instruments: Dictionary = main.get("instrument_windows")
	main.call("_open_instrument", &"program")
	main.call("_open_instrument", &"profiler")
	_assert(
		(instruments[&"mission"] as Control).visible
		and (instruments[&"parts"] as Control).visible
		and (instruments[&"program"] as Control).visible
		and (instruments[&"profiler"] as Control).visible,
		"Mission, Parts, Program, and Profiler windows must coexist."
	)
	var program_window: Control = instruments[&"program"]
	var old_position: Vector2 = program_window.position
	program_window.call("move_by", Vector2(35.0, 22.0))
	_assert(not program_window.position.is_equal_approx(old_position), "A system instrument must be draggable.")
	program_window.call("set_minimized", true)
	_assert(bool(program_window.get("minimized")), "A system instrument must be minimizable.")
	program_window.call("set_minimized", false)

	var editor: CodeEdit = main.get("editor")
	var original_source: String = editor.text
	editor.text = original_source + "\nnot valid"
	main.call("_on_program_changed")
	await process_frame
	_assert(bool(main.get("draft_dirty")) and (main.get("official_run_button") as Button).disabled, "An edited draft must not silently change executable code.")
	main.call("_run_official")
	_assert(main.get("latest_receipt") == null, "Running with an unapplied draft must not create evidence.")
	editor.text = original_source
	main.call("_on_program_changed")
	await process_frame
	main.call("_apply_program")
	_assert(not bool(main.get("draft_dirty")) and String(main.get("applied_program_source")) == original_source, "Confirm & Apply must make the exact valid draft executable.")

	main.call("_run_official")
	await process_frame
	var assembly_receipt = main.get("latest_receipt")
	_assert(assembly_receipt != null and assembly_receipt.all_passed, "Assembly official tests must produce a passing receipt.")
	_assert(bool(chapter.call("completed_levels").get(&"assembly", false)), "A passing wired assembly must unlock progression.")
	_assert(
		(main.get("level_completion_overlay") as Control).visible
		and StringName((main.get("level_completion_overlay") as Control).get("current_level_id")) == &"assembly",
		"The first system completion must automatically open its learning-summary window."
	)
	var trace = (main.get("latest_official_traces") as Array)[0]
	var request_event = trace.events[0]
	graph.zoom = 0.74
	graph.scroll_offset = Vector2(148.0, 92.0)
	for _transform_frame: int in range(2):
		await process_frame
	var exact_path: PackedVector2Array = main.call("_event_path", request_event)
	main.call("_show_event", request_event, 0.5)
	var overlay = main.get("trace_overlay")
	_assert(exact_path.size() >= 2 and _paths_equal(overlay.get("path"), exact_path), "Request animation must use the exact current GraphEdit connection curves.")
	var cpu_node: GraphNode = (main.get("device_nodes") as Dictionary)[&"CPU"]
	var overlay_start: Vector2 = overlay.get_global_transform().affine_inverse() * (cpu_node.get_global_transform() * cpu_node.get_output_port_position(0))
	_assert(exact_path[0].is_equal_approx(overlay_start), "The animated curve must begin on the displayed port after GraphEdit scroll and zoom transforms.")
	_assert(String((main.get("device_state_labels") as Dictionary)[&"CPU"].text) == _t(&"system.device.cpu_wait"), "Memory traffic must visibly put the actual CPU component into WAIT.")
	var topology_signature: String = main.call("_topology_from_graph").canonical_signature()
	(main.get("device_nodes") as Dictionary)[&"BUS"].position_offset += Vector2(75.0, 45.0)
	await process_frame
	_assert(main.call("_topology_from_graph").canonical_signature() == topology_signature, "Screen geometry must not change system identity or timing.")
	var moved_path: PackedVector2Array = main.call("_event_path", request_event)
	_assert(not _paths_equal(moved_path, exact_path), "Moving a component must update the exact visual route used by playback.")

	await _complete_comparison(main, chapter, &"cpu_speed", &"cpu", 0, 2)
	await _complete_comparison(main, chapter, &"ram_wait", &"ram", 0, 1)
	await _complete_comparison(main, chapter, &"bus_width", &"bus", 0, 1)

	main.call("_start_level", &"scale_up")
	await process_frame
	main.call("_run_official")
	await process_frame
	var scale_receipt = main.get("latest_receipt")
	_assert(scale_receipt.all_passed and scale_receipt.total_cases == 3, "Scale level must compare the fixed 4/16/64 workloads in one receipt.")
	_assert(bool(chapter.call("completed_levels").get(&"scale_up", false)), "Passing every workload scale must unlock the final investigation.")
	_assert(StringName((main.get("level_completion_overlay") as Control).get("current_level_id")) == &"scale_up", "Workload scaling must receive its own localized completion lesson.")

	main.call("_start_level", &"bottleneck")
	await process_frame
	main.call("_run_official")
	await process_frame
	var final_receipt = main.get("latest_receipt")
	_assert(final_receipt != null and final_receipt.all_passed, "Final investigation must first prove functional correctness.")
	_assert(not bool(chapter.call("completed_levels").get(&"bottleneck", false)), "The final level must not auto-complete before a diagnosis.")
	var selector: OptionButton = main.get("diagnosis_selector")
	for index: int in range(selector.item_count):
		if StringName(selector.get_item_metadata(index)) == final_receipt.diagnosed_bottleneck:
			selector.select(index)
			break
	main.call("_confirm_diagnosis")
	await process_frame
	_assert(bool(chapter.call("completed_levels").get(&"bottleneck", false)), "Submitting the trace-derived bottleneck must complete Chapter 1.")
	_assert(chapter.call("completed_levels").size() == 6, "The normal completion path must cover exactly all six chapter levels.")
	var final_completion: Control = main.get("level_completion_overlay")
	var final_continue: Button = final_completion.get("continue_button")
	_assert(
		final_completion.visible
		and StringName(final_completion.get("current_level_id")) == &"bottleneck"
		and not String((final_completion.get("summary_label") as Label).text).is_empty(),
		"The final diagnosis must open a chapter-specific evidence summary."
	)
	final_continue.pressed.emit()
	await process_frame
	_assert((main.get("map_host") as Control).visible and not (main.get("lab_host") as Control).visible, "Continue after any Chapter 1 completion must return to the six-node level map.")

	main.call("_stop_playback")
	main.queue_free()
	for _cleanup: int in range(5):
		await process_frame
	game_mode.call("set_mode", &"game")
	_assert(chapter.call("completed_levels").is_empty(), "Test-mode completion must stay isolated from Game-mode progression.")
	if failures.is_empty():
		print("PASS: six-level system chapter map, applied program, typed wiring, floating tools, evidence progression, exact-path animation, and diagnosis tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d system-lab UI assertion(s) failed" % failures.size())
		quit(1)


func _complete_comparison(
		main: Control,
		chapter: Node,
		level_id: StringName,
		kind: StringName,
		first_index: int,
		second_index: int
	) -> void:
	main.call("_start_level", level_id)
	await process_frame
	var selectors: Dictionary = main.get("part_selectors")
	var selector: OptionButton = selectors[kind]
	selector.select(first_index)
	main.call("_on_part_selected", first_index, kind)
	main.call("_run_official")
	await process_frame
	_assert(not bool(chapter.call("completed_levels").get(level_id, false)), "%s must require a second controlled part observation." % level_id)
	selector.select(second_index)
	main.call("_on_part_selected", second_index, kind)
	main.call("_run_official")
	await process_frame
	_assert(bool(chapter.call("completed_levels").get(level_id, false)), "%s must complete after two distinct parts pass under one applied program." % level_id)
	_assert(
		(main.get("level_completion_overlay") as Control).visible
		and StringName((main.get("level_completion_overlay") as Control).get("current_level_id")) == level_id,
		"%s must open its own completion summary after the controlled comparison." % level_id
	)


func _paths_equal(left: PackedVector2Array, right: PackedVector2Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if not left[index].is_equal_approx(right[index]):
			return false
	return true


func _t(key: StringName, args: Array = []) -> String:
	return String(root.get_node("Localization").call("text", key, args))


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
