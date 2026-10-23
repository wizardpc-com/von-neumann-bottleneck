extends SceneTree

var failures: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)

func settle(frames: int = 5) -> void:
	for frame: int in frames: await process_frame

func key(code: Key, control: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code
		event.pressed = pressed; event.ctrl_pressed = control
		root.push_input(event, true)
		await process_frame

func run() -> void:
	preload("res://src/lab/lab_features.gd").classic = true
	root.size = Vector2i(1280, 720)
	var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench); current_scene = bench
	await settle()
	bench._show_tutorial(false)
	await settle(12)
	var graph: GraphEdit = bench.graph
	var component: GraphNode = bench.component_nodes[&"NOT_1"]
	var original: Vector2 = component.position_offset
	bench._on_begin_node_move()
	component.position_offset += Vector2(40, 20)
	bench._on_end_node_move()
	bench._set_selected_ids([&"NOT_1"] as Array[StringName])
	var moved: Vector2 = component.position_offset
	var undo_count: int = bench.wire_history.size()
	var component_count: int = bench.component_catalog.size()
	var wire_count: int = graph.get_connection_list().size()
	var color: int = bench.active_wire_color_index
	var result: String = bench.debug_result_label.text
	await key(KEY_F10)
	await settle()
	var window_mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(window_mode.settings_layer), "F10 opens the real settings layer")
	if not is_instance_valid(window_mode.settings_layer):
		bench.queue_free(); quit(1); return
	var resume: Button = window_mode.settings_layer.find_child("OptionsResumeButton", true, false)
	check(resume != null, "Settings has a non-text focus target")
	if resume == null:
		window_mode.settings_layer.queue_free(); bench.queue_free(); quit(1); return
	resume.grab_focus()
	await settle(2)
	check(root.gui_get_focus_owner() == resume, "Settings button owns actual viewport focus")
	var scroll: Vector2 = graph.scroll_offset
	await key(KEY_Z, true)
	check(component.position_offset == moved and bench.wire_history.size() == undo_count and bench.redo_history.is_empty(), "Settings blocks undo beneath non-text focus")
	await key(KEY_Y, true)
	check(component.position_offset == moved and bench.wire_history.size() == undo_count and bench.redo_history.is_empty(), "Settings blocks undo and redo beneath non-text focus")
	for code: Key in [KEY_BACKSPACE, KEY_DELETE, KEY_3, KEY_W, KEY_A, KEY_S, KEY_D, KEY_HOME, KEY_F6]:
		await key(code)
	check(bench.component_catalog.size() == component_count and graph.get_connection_list().size() == wire_count, "Settings blocks component deletion")
	check(bench.wire_history.size() == undo_count and bench.redo_history.is_empty(), "Settings preserves both edit histories")
	check(graph.scroll_offset.is_equal_approx(scroll) and bench.graph_pan_keys.is_empty(), "Settings blocks keyboard pan and circuit focus")
	check(bench.active_wire_color_index == color and bench.debug_result_label.text == result, "Settings blocks wire colors and running the board")
	await key(KEY_ESCAPE)
	await settle()
	check(not is_instance_valid(window_mode.settings_layer), "Escape closes settings without leaving the workbench")
	if failures > 0:
		bench.queue_free(); await settle()
		print("FAIL: hardware settings input %d failures" % failures)
		quit(1); return
	graph.grab_focus()
	await key(KEY_Z, true)
	check(component.position_offset.is_equal_approx(original), "Undo resumes after settings closes")
	await key(KEY_Y, true)
	check(component.position_offset.is_equal_approx(moved), "Redo resumes after settings closes")
	await key(KEY_BACKSPACE)
	check(not bench.component_catalog.has(&"NOT_1"), "Deletion resumes after settings closes")
	await key(KEY_Z, true)
	check(bench.component_catalog.has(&"NOT_1"), "The resumed deletion remains undoable")
	bench.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "hardware settings input %d failures" % failures)
	quit(1 if failures else 0)
