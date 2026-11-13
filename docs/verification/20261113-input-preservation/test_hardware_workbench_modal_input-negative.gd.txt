extends SceneTree

var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle(frames: int = 5) -> void:
	for frame: int in frames: await process_frame

func key(code: Key, command: bool = false, meta: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.ctrl_pressed = command
		event.meta_pressed = meta
		root.push_input(event, true)
		await process_frame

func _init() -> void: call_deferred("run")

func run() -> void:
	if not "VonNeumannBottleneckChecks" in OS.get_user_data_dir():
		push_error("Refusing to test against ordinary player data")
		quit(2)
		return
	preload("res://src/lab/lab_features.gd").classic = true
	root.size = Vector2i(1280, 720)
	var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench)
	current_scene = bench
	await settle()
	bench._show_tutorial(false)
	await settle(12)
	for duplicate: bool in [false, true]:
		var component: GraphNode = bench.component_nodes[&"NOT_1"]
		var original: Vector2 = component.position_offset
		bench._on_begin_node_move()
		component.position_offset += Vector2(40, 20)
		bench._on_end_node_move()
		bench._set_selected_ids([&"NOT_1"] as Array[StringName])
		var moved: Vector2 = component.position_offset
		var undo_count: int = bench.wire_history.size()
		var color: int = bench.active_wire_color_index
		var result: String = bench.debug_result_label.text
		var original_name: String = bench.active_workbench_name
		# Exercise the same menu callback as New / Duplicate, then move actual
		# viewport focus away from the text field without dismissing the dialog.
		bench._refresh_workbench_menu()
		var menu: PopupMenu = bench.workbench_menu_button.get_popup()
		for index: int in menu.item_count:
			var metadata: Variant = menu.get_item_metadata(index)
			if metadata is Dictionary and metadata.get("action") == (&"duplicate" if duplicate else &"create"):
				bench._on_workbench_menu_item_pressed(menu.get_item_id(index))
				break
		await settle()
		check(bench.workbench_name_dialog.visible, "New/duplicate opens the naming dialog")
		bench.workbench_create_button.grab_focus()
		await settle(2)
		check(root.gui_get_focus_owner() == bench.workbench_create_button, "Naming dialog button owns viewport focus")
		for meta: bool in [false, true]:
			await key(KEY_Z, not meta, meta)
			check(component.position_offset == moved and bench.wire_history.size() == undo_count and bench.redo_history.is_empty(), "Naming dialog blocks Ctrl/Meta board Undo")
			await key(KEY_Y, not meta, meta)
		await key(KEY_3)
		await key(KEY_F6)
		check(component.position_offset == moved and bench.wire_history.size() == undo_count and bench.redo_history.is_empty(), "Naming dialog preserves edit history")
		check(bench.active_wire_color_index == color and bench.debug_result_label.text == result, "Naming dialog blocks palette and Debug shortcuts")
		var scroll: Vector2 = bench.graph.scroll_offset
		for code: Key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_HOME, KEY_F1]:
			await key(code)
			check(root.gui_get_focus_owner() == bench.workbench_create_button, "Naming dialog retains focus while board navigation/help shortcuts are pressed")
		check(bench.graph.scroll_offset.is_equal_approx(scroll) and bench.graph_pan_keys.is_empty(), "Naming dialog blocks held camera keys and Home")
		check(not bench.hint_mode, "Naming dialog does not enter hint mode")
		await key(KEY_BACKSPACE)
		check(bench.component_catalog.has(&"NOT_1"), "Naming dialog blocks board deletion")
		await key(KEY_ESCAPE)
		await settle()
		check(not bench.workbench_name_dialog.visible and bench.current_phase == &"tutorial" and bench.active_workbench_name == original_name, "Escape cancels naming without leaving or switching the board")
		# Restore a failed negative-control deletion before testing the next entry.
		if not bench.component_catalog.has(&"NOT_1"):
			bench._undo_wire()
		bench.graph.grab_focus()
		await key(KEY_Z, true)
		component = bench.component_nodes[&"NOT_1"]
		check(component.position_offset.is_equal_approx(original), "Board Undo resumes after naming closes")
		await key(KEY_Y, true)
		check(component.position_offset.is_equal_approx(moved), "Board Redo resumes after naming closes")
		# Enter in the text field keeps its existing creation/duplication path.
		bench._show_new_workbench_dialog(false, duplicate)
		bench.workbench_name_edit.text = "Modal input %s %s" % ["copy" if duplicate else "new", Time.get_ticks_usec()]
		var requested_name: String = bench.workbench_name_edit.text
		await key(KEY_ENTER)
		await settle(12)
		check(not bench.workbench_name_dialog.visible and bench.active_workbench_name == requested_name, "Enter submits New/duplicate naming normally")
	bench.queue_free()
	await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "hardware workbench modal input %d failures" % failures)
	quit(1 if failures else 0)
