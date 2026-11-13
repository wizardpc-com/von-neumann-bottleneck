extends SceneTree

var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func settle(frames: int = 5) -> void:
	for frame: int in frames: await process_frame

func key(code: Key, command: bool = false, shift: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.ctrl_pressed = command
		event.shift_pressed = shift
		root.push_input(event, true)
		await process_frame

func mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)
	await process_frame

func motion(position: Vector2, delta: Vector2, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = delta
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event, true)
	await process_frame

func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile.")
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
	var component: GraphNode = bench.component_nodes[&"NOT_1"]
	var original: Vector2 = component.position_offset
	var history_size: int = bench.wire_history.size()
	var pointer: Vector2 = component.get_global_rect().get_center()
	await mouse_button(pointer, true)
	check(bench.body_drag_component_id == &"NOT_1", "Real viewport press begins component body drag")
	pointer += Vector2(70, 40)
	await motion(pointer, Vector2(70, 40), true)
	var moved: Vector2 = component.position_offset
	check(not moved.is_equal_approx(original), "Held pointer moves the component")
	await key(KEY_ESCAPE)
	await settle()
	check(bench.current_phase == &"tutorial" and bench.current_level_id == &"tutorial", "Escape ends the nearest drag without navigating to the map")
	check(bench.body_drag_component_id.is_empty(), "Escape ends the active body drag")
	# Keep sending the physical remainder of the gesture, including motion
	# while still held. Escape retains one undoable move, like focus loss.
	pointer += Vector2(35, 20)
	await motion(pointer, Vector2(35, 20), true)
	await mouse_button(pointer, false)
	await motion(pointer + Vector2(30, 0), Vector2(30, 0), false)
	await settle()
	if bench.current_phase == &"tutorial" and is_instance_valid(component):
		check(component.position_offset.is_equal_approx(moved), "Held motion and release after Escape do not restart movement")
		check(bench.wire_history.size() == history_size + 1 and bench.node_move_start_positions.is_empty(), "Escape records exactly one completed move")
		bench.graph.grab_focus()
		await key(KEY_Z, true)
		check(component.position_offset.is_equal_approx(original), "Undo restores the pre-drag position")
		await key(KEY_Z, true, true)
		check(component.position_offset.is_equal_approx(moved), "Redo restores the Escape-ended position")
		await key(KEY_ESCAPE)
		check(bench.current_phase == &"campaign", "A later Escape with no gesture still opens the map")
	bench.queue_free()
	await settle()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "hardware drag Escape %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
