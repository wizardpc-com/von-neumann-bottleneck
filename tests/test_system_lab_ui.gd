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

	graph.scroll_offset = Vector2(240.0, 160.0)
	var scroll_before_pan: Vector2 = graph.scroll_offset
	_key_down(main, KEY_D)
	_assert(graph.scroll_offset.is_equal_approx(scroll_before_pan), "Chapter 1 WASD input must not use fixed-distance key-repeat jumps.")
	for _pan_slice: int in range(15):
		main.call("_process", 1.0 / 60.0)
	_key_up(main, KEY_D)
	_assert(is_equal_approx(graph.scroll_offset.x - scroll_before_pan.x, 180.0), "Chapter 1 held-key camera motion must be smooth and frame-delta based.")
	var scroll_after_pan_release: Vector2 = graph.scroll_offset
	main.call("_process", 0.25)
	_assert(graph.scroll_offset.is_equal_approx(scroll_after_pan_release), "Chapter 1 key release must stop camera movement immediately.")
	_key_down(main, KEY_D)
	main.call("_notification", MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	main.call("_process", 0.10)
	_key_up(main, KEY_D)
	_assert(graph.scroll_offset.is_equal_approx(scroll_after_pan_release), "Chapter 1 application focus loss must clear held movement state.")
	_key_down(main, KEY_A)
	main.call("_process", 0.25)
	_key_up(main, KEY_A)
	_assert(graph.scroll_offset.is_equal_approx(scroll_before_pan), "Opposite Chapter 1 camera motion must restore the view without moving hardware; before=%s after=%s." % [scroll_before_pan, graph.scroll_offset])
	main.call("_open_instrument", &"program")
	var program_editor: CodeEdit = main.get("editor")
	program_editor.grab_focus()
	_key_down(main, KEY_D)
	main.call("_process", 0.10)
	_key_up(main, KEY_D)
	_assert(graph.scroll_offset.is_equal_approx(scroll_before_pan), "Chapter 1 program editing must not move the canvas with WASD.")
	var system_focus_click := InputEventMouseButton.new()
	system_focus_click.button_index = MOUSE_BUTTON_LEFT
	system_focus_click.pressed = true
	main.call("_on_system_graph_gui_input", system_focus_click)
	_key_down(main, KEY_D)
	main.call("_process", 0.10)
	_key_up(main, KEY_D)
	_assert(graph.scroll_offset.x > scroll_before_pan.x and root.gui_get_focus_owner() == graph, "Clicking the Chapter 1 canvas after program editing must restore responsive WASD immediately.")
	graph.scroll_offset = Vector2.ZERO
	await process_frame

	var device_nodes: Dictionary = main.get("device_nodes")
	var device_surfaces: Dictionary = main.get("device_surfaces")
	for child: Node in (device_nodes[&"CPU"] as GraphNode).get_children():
		if child is Label:
			_assert((child as Label).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Chapter 1 labels must pass left-drag gestures through to the whole movable device body.")
	var cpu_rect: Rect2 = graph.call("displayed_node_rect", device_nodes[&"CPU"])
	var bus_rect: Rect2 = graph.call("displayed_node_rect", device_nodes[&"BUS"])
	_drag_select(graph, cpu_rect.position - Vector2(32.0, 20.0), bus_rect.end + Vector2(4.0, 4.0), false)
	_assert((device_nodes[&"CPU"] as GraphNode).selected and (device_nodes[&"BUS"] as GraphNode).selected and not (device_nodes[&"RAM"] as GraphNode).selected, "Chapter 1 empty-canvas marquee selection must match the prologue replacement-selection rule.")
	_assert(bool((device_surfaces[&"CPU"] as Control).get("selection_active")), "A selected Chapter 1 device must highlight its actual procedural surface.")
	var shift_toggle := InputEventMouseButton.new()
	shift_toggle.button_index = MOUSE_BUTTON_LEFT
	shift_toggle.pressed = true
	shift_toggle.shift_pressed = true
	shift_toggle.position = (device_nodes[&"BUS"] as GraphNode).size * 0.5
	main.call("_on_system_device_gui_input", shift_toggle, &"BUS")
	_assert((device_nodes[&"CPU"] as GraphNode).selected and not (device_nodes[&"BUS"] as GraphNode).selected, "Shift-click must toggle one Chapter 1 device without clearing the rest of the selection.")

	main.call("_set_selected_system_devices", [&"CPU", &"BUS"] as Array[StringName])
	var cpu_position_before: Vector2 = (device_nodes[&"CPU"] as GraphNode).position_offset
	var bus_position_before: Vector2 = (device_nodes[&"BUS"] as GraphNode).position_offset
	main.call("_on_system_begin_node_move")
	(device_nodes[&"CPU"] as GraphNode).position_offset += Vector2(34.0, 18.0)
	(device_nodes[&"BUS"] as GraphNode).position_offset += Vector2(34.0, 18.0)
	main.call("_on_system_end_node_move")
	_shortcut(main, KEY_Z)
	_assert((device_nodes[&"CPU"] as GraphNode).position_offset.is_equal_approx(cpu_position_before) and (device_nodes[&"BUS"] as GraphNode).position_offset.is_equal_approx(bus_position_before), "Ctrl+Z history must restore a moved Chapter 1 selection as one edit.")
	_shortcut(main, KEY_Y)
	_assert((device_nodes[&"CPU"] as GraphNode).position_offset.is_equal_approx(cpu_position_before + Vector2(34.0, 18.0)) and (device_nodes[&"BUS"] as GraphNode).position_offset.is_equal_approx(bus_position_before + Vector2(34.0, 18.0)), "Ctrl+Y history must reapply the complete selected-group movement.")
	main.call("_save_level_session")
	var moved_session: Dictionary = (main.get("level_sessions") as Dictionary)[main.call("_level_session_key", &"assembly")]
	_assert((moved_session.get("positions", {}) as Dictionary).get("CPU", Vector2.ZERO).is_equal_approx(cpu_position_before + Vector2(34.0, 18.0)), "Chapter 1 level sessions must retain the player's final component layout.")
	_assert(not moved_session.has("editor_history") and not moved_session.has("redo_history"), "Chapter 1 sessions must not persist the operation chain.")

	_shortcut(main, KEY_A)
	_assert((main.call("_selected_system_device_ids") as Array).size() == 3, "Ctrl+A must select all three Chapter 1 system devices.")
	_key(main, KEY_DELETE)
	_assert(graph.get_connection_list().is_empty() and device_nodes.size() == 3, "Delete must clear routes incident to selected fixed system slots without making CPU, Bus, or RAM unrecoverable.")
	main.call("_undo_system_edit")
	_assert(graph.get_connection_list().size() == 6, "One Undo must restore all routes removed from a Chapter 1 selection.")

	var cpu_center: Vector2 = graph.call("displayed_node_rect", device_nodes[&"CPU"]).get_center()
	_right_drag_erase(graph, [cpu_center])
	_assert(graph.get_connection_list().size() == 3 and device_nodes.has(&"CPU"), "Right-clicking a fixed Chapter 1 device must remove its three incident routes while preserving the typed slot.")
	main.call("_undo_system_edit")
	_assert(graph.get_connection_list().size() == 6, "One Undo must atomically restore routes removed by a right-button device stroke.")

	var erase_connection: Dictionary = graph.get_connection_list()[0]
	var erase_curve: PackedVector2Array = graph.call("connection_curve", erase_connection)
	var erase_segment: int = _longest_path_segment(erase_curve)
	var erase_start: Vector2 = erase_curve[erase_segment]
	var erase_finish: Vector2 = erase_curve[erase_segment + 1]
	var erase_midpoint: Vector2 = erase_start.lerp(erase_finish, 0.5)
	var erase_normal: Vector2 = (erase_finish - erase_start).orthogonal().normalized()
	_right_drag_erase(graph, [erase_midpoint + erase_normal * 10.0])
	_assert(graph.get_connection_list().size() == 6, "The Chapter 1 eraser must use the cursor tip, not the broader hover radius.")
	_right_drag_erase(graph, [erase_midpoint])
	_assert(graph.get_connection_list().size() == 5, "Touching the rendered Chapter 1 route must delete exactly that route.")
	_shortcut(main, KEY_Z)
	_assert(graph.get_connection_list().size() == 6, "A route erased with the right mouse button must be undoable.")
	_shortcut(main, KEY_Z, true)
	_assert(graph.get_connection_list().size() == 5, "Ctrl+Shift+Z must remain a Chapter 1 redo alias consistent with the prologue editor.")
	_shortcut(main, KEY_Z)
	var topology_before_erase_stroke: String = main.call("_topology_from_graph").canonical_signature()
	var stroke_connections: Array[Dictionary] = graph.get_connection_list()
	var stroke_points: Array[Vector2] = []
	for stroke_connection: Dictionary in stroke_connections.slice(0, 2):
		var stroke_curve: PackedVector2Array = graph.call("connection_curve", stroke_connection)
		var stroke_segment: int = _longest_path_segment(stroke_curve)
		stroke_points.append(stroke_curve[stroke_segment].lerp(stroke_curve[stroke_segment + 1], 0.5))
	_right_drag_erase(graph, stroke_points)
	_assert(graph.get_connection_list().size() <= 4, "One held-right Chapter 1 sweep must continuously erase every rendered route crossed by its sampled path.")
	main.call("_undo_system_edit")
	_assert(graph.get_connection_list().size() == 6 and main.call("_topology_from_graph").canonical_signature() == topology_before_erase_stroke, "One Undo must atomically restore the exact topology removed by a continuous Chapter 1 erase stroke.")

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
		print("PASS: six-level system chapter map, coherent editor controls, applied program, typed wiring, floating tools, evidence progression, exact-path animation, and diagnosis tests passed")
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


func _longest_path_segment(path: PackedVector2Array) -> int:
	var longest_index: int = 0
	var longest_length: float = -1.0
	for index: int in range(path.size() - 1):
		var length: float = path[index].distance_squared_to(path[index + 1])
		if length > longest_length:
			longest_length = length
			longest_index = index
	return longest_index


func _shortcut(main: Control, keycode: Key, shifted: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.ctrl_pressed = true
	event.shift_pressed = shifted
	main.call("_input", event)


func _key(main: Control, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	main.call("_input", event)


func _key_down(main: Control, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	main.call("_input", event)


func _key_up(main: Control, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = false
	main.call("_input", event)


func _right_drag_erase(graph: GraphEdit, points: Array[Vector2]) -> void:
	if points.is_empty():
		return
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = points[0]
	graph.call("_gui_input", press)
	for index: int in range(1, points.size()):
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
		motion.position = points[index]
		graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = points[points.size() - 1]
	graph.call("_gui_input", release)


func _drag_select(graph: GraphEdit, start: Vector2, finish: Vector2, shifted: bool) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.shift_pressed = shifted
	press.position = start
	graph.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.shift_pressed = shifted
	motion.position = finish
	graph.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.shift_pressed = shifted
	release.position = finish
	graph.call("_gui_input", release)


func _t(key: StringName, args: Array = []) -> String:
	return String(root.get_node("Localization").call("text", key, args))


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
