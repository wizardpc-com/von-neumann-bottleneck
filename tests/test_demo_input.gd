extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func click(position: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = position
	root.push_input(move)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.global_position = position
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event)
		await process_frame

func drag(from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.position = from
	press.global_position = from
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press)
	await process_frame
	for index: int in range(1, 6):
		var move := InputEventMouseMotion.new()
		move.position = from.lerp(to, index / 5.0)
		move.global_position = move.position
		move.relative = (to - from) / 5.0
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(move)
		await process_frame
	var release := InputEventMouseButton.new()
	release.position = to
	release.global_position = to
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release)
	await process_frame

func _run() -> void:
	root.size = Vector2i(1600, 900)
	var progress: Node = root.get_node("DemoProgress")
	progress.game = progress._empty()
	change_scene_to_file("res://src/demo/demo_menu.tscn")
	await process_frame
	await process_frame
	var menu: Control = current_scene
	check(not menu.start_button.disabled and menu.continue_button.disabled, "Fresh ordinary menu offers Start without fabricated Continue.")
	if "--capture-mainline" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/redesign/demo-menu.png")
	await click(menu.start_button.get_global_rect().get_center())
	await process_frame
	await process_frame
	var ui: Control = current_scene
	check(ui.name == "DemoWorkbench", "Actual Start click enters the ordinary mainline.")
	if ui.name != "DemoWorkbench":
		quit(1)
		return
	var board: Control = ui.circuit_board
	var graph: GraphEdit = board.graph
	await process_frame
	var source: GraphNode = board.graph_nodes[&"A"]
	var target: GraphNode = board.graph_nodes[&"MUX"]
	await drag(source.global_position + source.get_output_port_position(0) * graph.zoom, target.global_position + target.get_input_port_position(0) * graph.zoom)
	check(board.circuit.has_connection(&"A", 0, &"MUX", 0), "Mouse drag connects visible ports through GraphEdit hit testing.")
	graph.zoom = 0.8
	await process_frame
	await process_frame
	graph.scroll_offset = Vector2(-40, -25)
	await process_frame
	await process_frame
	await process_frame
	source = board.graph_nodes[&"B"]
	await drag(source.global_position + source.get_output_port_position(0) * graph.zoom, target.global_position + target.get_input_port_position(1) * graph.zoom)
	check(board.circuit.has_connection(&"B", 0, &"MUX", 1), "Zoom and pan retain correct port hit targets.")
	var before: Vector2 = target.position_offset
	await drag(target.global_position + Vector2(60, 13) * graph.zoom, target.global_position + Vector2(130, 53) * graph.zoom)
	check(target.position_offset != before, "Dragging a component title moves the actual graph node.")
	await click(ui.run_button.get_global_rect().get_center())
	check(not ui.completed and not ui.latest_run.is_empty(), "Run click evaluates incomplete player wiring and rejects it.")
	ui.handbook.open_handbook()
	await process_frame
	check(ui.handbook.is_open(), "The shared Handbook opens without progression gates.")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	check(current_scene == ui and not ui.handbook.is_open(), "Escape closes help before leaving the task.")
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1920, 1200)]:
		root.size = dimensions
		await process_frame
		await process_frame
		check(ui.get_global_rect().encloses(ui.run_button.get_global_rect()), "Run remains inside the visible workspace at %s." % dimensions)
		check(ui.get_global_rect().encloses(ui.continue_button.get_global_rect()), "Continue remains inside the visible workspace at %s." % dimensions)
		if "--capture-mainline" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/redesign/input-%dx%d.png" % [dimensions.x, dimensions.y])
	change_scene_to_file("res://src/ui/prototype_hub.tscn")
	await process_frame
	await process_frame
	await click(current_scene.mainline_button.get_global_rect().get_center())
	await process_frame
	check(current_scene.name == "DemoMenu", "A real click returns from legacy records to the mainline menu.")
	if failures.is_empty():
		print("PASS: native Godot input dispatch, Start/Run, transformed port wiring, node drag, Esc and responsive controls")
	quit(0 if failures.is_empty() else 1)
