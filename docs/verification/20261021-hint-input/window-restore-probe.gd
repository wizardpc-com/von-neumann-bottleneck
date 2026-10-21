extends SceneTree
var rows: Array[Dictionary] = []
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func settle(frames: int) -> void:
	for frame: int in frames: await process_frame
func snapshot(label: String) -> void:
	rows.append({"label": label, "mode": root.mode, "size": str(root.size),
		"position": str(root.position), "native_size": str(DisplayServer.window_get_size()),
		"native_position": str(DisplayServer.window_get_position()),
		"viewport_rect": str(root.get_visible_rect()), "content_scale": str(root.content_scale_size)})
func key() -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_F11; event.physical_keycode = KEY_F11; event.pressed = down
		root.push_input(event, true)
		await process_frame
func run() -> void:
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await settle(45)
	snapshot("fresh-fullscreen")
	for cycle: int in 6:
		await key()
		snapshot("window-immediate-%d" % cycle)
		await settle(45)
		snapshot("window-settled-%d" % cycle)
		var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		if root.mode != Window.MODE_WINDOWED or not usable.encloses(Rect2i(root.position, root.size)):
			failures.append("Window bounds cycle %d" % cycle)
		if cycle == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/window-first-exit.png")
		await key(); await settle(30)
		snapshot("fullscreen-%d" % cycle)
		if root.mode != Window.MODE_FULLSCREEN: failures.append("Fullscreen cycle %d" % cycle)
	var file := FileAccess.open("res://.godot/window-restore-result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows": rows, "failures": failures,
		"scope": "Rendered Windows native window geometry; synthetic viewport F11, not physical keyboard"}, "  "))
	file.close()
	print("PASS: window restore probe" if failures.is_empty() else "FAIL: window restore probe " + str(failures))
	quit(0 if failures.is_empty() else 1)
