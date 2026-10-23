extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func key(code: Key, control: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code
		event.pressed = down; event.ctrl_pressed = control
		root.push_input(event, true); await process_frame
func open_settings() -> void:
	await key(KEY_F10); await settle()
	var layer: CanvasLayer = root.get_node("WindowMode").settings_layer
	check(is_instance_valid(layer), "F10 opens Settings")
	if is_instance_valid(layer):
		var button: Button = layer.find_child("OptionsResumeButton", true, false)
		button.grab_focus()
		await process_frame
		check(root.gui_get_focus_owner() == button, "Settings owns non-text focus")
func close_settings() -> void:
	await key(KEY_ESCAPE); await settle()
	check(not is_instance_valid(root.get_node("WindowMode").settings_layer), "Escape closes only Settings")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	await system_input()
	await later_input(true)
	await later_input(false)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "chapter Settings input %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func system_input() -> void:
	root.get_node("TaskNavigation").pending = "chapter_1/assembly"
	var host: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(host); await settle()
	var cpu: GraphNode = host.device_nodes[&"CPU"]
	var original: Vector2 = cpu.position_offset
	host._set_selected_system_devices([&"CPU"] as Array[StringName])
	host._on_system_begin_node_move()
	cpu.position_offset += Vector2(50, 30)
	host._on_system_end_node_move()
	var moved: Vector2 = cpu.position_offset
	var history: Array = host.editor_history.duplicate(true)
	var topology: Array = host.graph.get_connection_list().duplicate(true)
	# A held pan must stop even when Settings is opened by its button.
	host.graph_pan_keys[KEY_D] = true
	root.get_node("WindowMode").open_settings()
	var scroll: Vector2 = host.graph.scroll_offset
	await settle()
	check(host.graph_pan_keys.is_empty() and host.graph.scroll_offset.is_equal_approx(scroll), "System Settings clears already-held pan without a release event")
	var layer: CanvasLayer = root.get_node("WindowMode").settings_layer
	(layer.find_child("OptionsResumeButton", true, false) as Button).grab_focus()
	await key(KEY_Z, true)
	check(cpu.position_offset == moved and host.editor_history == history, "System Settings blocks undo")
	await key(KEY_Y, true)
	for code: Key in [KEY_BACKSPACE, KEY_DELETE, KEY_3, KEY_W, KEY_D]: await key(code)
	check(host.editor_history == history and host.graph.get_connection_list() == topology, "System Settings preserves wiring and history")
	check(host.graph.scroll_offset.is_equal_approx(scroll) and host.graph_pan_keys.is_empty(), "System Settings blocks new pan keys")
	await close_settings()
	host.graph.grab_focus()
	await key(KEY_Z, true)
	check(cpu.position_offset == original, "System undo resumes after Settings")
	await key(KEY_Y, true)
	check(cpu.position_offset == moved, "System redo resumes after Settings")
	host.queue_free(); await settle()

func later_input(overlap: bool) -> void:
	var domain: String = "Overlap" if overlap else "Layout"
	root.get_node("TaskNavigation").pending = "chapter_3/buffers" if overlap else "chapter_4/fields"
	var host: Control = load("res://src/overlap_chapter/overlap_chapter.tscn" if overlap else "res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host); await settle()
	var original: Dictionary = (host.board if overlap else host.design).duplicate(true)
	if overlap: host._add_part("buffer", Vector2(500, 300))
	else: host._drop_field(0, 2)
	await settle()
	var edited: Dictionary = (host.board if overlap else host.design).duplicate(true)
	check(edited != original, domain + " fixture has a real reversible edit")
	var history: Array = host.undo_stack.duplicate(true)
	await open_settings()
	await key(KEY_Z, true)
	check((host.board if overlap else host.design) == edited and host.undo_stack == history, domain + " Settings blocks undo")
	await key(KEY_Y, true)
	check((host.board if overlap else host.design) == edited and host.undo_stack == history, domain + " Settings blocks redo")
	if overlap:
		# Put an actual card behind a Settings button: _input must not steal its click.
		var layer: CanvasLayer = root.get_node("WindowMode").settings_layer
		var button: Button = layer.find_child("OptionsResumeButton", true, false)
		var target: Vector2 = button.get_global_rect().get_center()
		var card: GraphNode = host.graph.get_node("A")
		var card_original: Vector2 = card.position_offset
		var local: Vector2 = host.graph.get_global_transform_with_canvas().affine_inverse() * target
		card.position_offset = host.graph.graph_position_for_local_pointer(local, card.size)
		await settle()
		check(card.get_global_rect().has_point(target), "Overlap pointer fixture places a real card behind Settings Return")
		var before: Vector2 = card.position_offset
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = target
		root.push_input(press, true); await process_frame
		check(host.body_drag.is_empty(), "Overlap Settings click cannot start a card drag underneath")
		var motion := InputEventMouseMotion.new()
		motion.position = target + Vector2(5, 3); motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true); await process_frame
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT; release.position = motion.position
		root.push_input(release, true); await settle()
		check(card.position_offset == before and host.body_drag.is_empty(), "Overlap Settings pointer leaves the card unchanged")
		check(not is_instance_valid(root.get_node("WindowMode").settings_layer), "The Settings Return button still receives the card-overlapping click")
		if is_instance_valid(root.get_node("WindowMode").settings_layer): await close_settings()
		card.position_offset = card_original
		host._capture_layout()
	else: await close_settings()
	var focus: Control = root.gui_get_focus_owner()
	if focus != null: focus.release_focus()
	await key(KEY_Z, true)
	check((host.board if overlap else host.design) == original, domain + " undo resumes after Settings")
	await key(KEY_Y, true)
	check((host.board if overlap else host.design) == edited, domain + " redo resumes after Settings")
	host.queue_free(); await settle()
