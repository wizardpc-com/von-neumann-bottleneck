extends SceneTree
## Isolated physical-screen routing checks; no actual quit or player saves.
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for frame: int in 10: await process_frame
	await physics_frame
func screen_pixel(room, texture_pixel: Vector2) -> Vector2:
	var bounds: AABB = room._screen.get_aabb()
	var uv: Vector2 = texture_pixel / Vector2(room.standby_viewport.size_2d_override)
	var point := Vector3(bounds.position.x + uv.x * bounds.size.x, bounds.position.y + (1.0 - uv.y) * bounds.size.y, bounds.end.z)
	return room.camera.unproject_position(room._screen.to_global(point)) * room.size / Vector2(room.viewport.size)
func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var hub = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub)
		current_scene = hub
		await settle()
		var lab = hub.laboratory
		var room = lab.room
		var terminal = lab.terminal
		if lab.room_focus:
			lab.leave_terminal()
			await settle()
		var menu_parent: Node = terminal.quit_view.get_parent()
		lab.escape()
		await settle()
		check(terminal.confirming() and room.confirmation_active(), locale + " room Esc opens confirmation")
		check(room.visible and not terminal.visible and not lab.room_input_shield.visible, "Physical screen remains visible and receives input")
		check(terminal.quit_view.get_parent() == room.standby_viewport and not room._standby_text.visible, "Same confirmation controls replace standby on glass")
		check(room.standby_viewport.gui_get_focus_owner() == terminal.quit_no, "Cancel receives default keyboard focus")
		check(not room._interaction_enabled, "Confirmation prevents ordinary room navigation")
		var button_center: Vector2 = terminal.quit_no.get_global_rect().get_center()
		var pixel := screen_pixel(room, button_center)
		var mapped: Vector2 = room.screen_position(pixel)
		print("SCREEN ", locale, " button=", button_center, " pixel=", pixel, " mapped=", mapped, " view=", terminal.quit_view.get_rect(), " scale=", terminal.quit_view.scale)
		var screen_bounds := Rect2(Vector2.ZERO, Vector2(room.standby_viewport.size_2d_override))
		for control: Control in [terminal.quit_title, terminal.quit_note, terminal.quit_yes, terminal.quit_no]:
			check(screen_bounds.encloses(control.get_global_rect()), "Confirmation content stays inside the screen in " + locale)
		check(mapped.distance_to(button_center) < 2.0, "Screen ray maps real button through perspective")
		check(room.screen_position(Vector2(-20, -20)) == Vector2(-1, -1), "Outside screen cannot activate a choice")
		for down: bool in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			click.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
			click.position = pixel
			click.global_position = pixel
			root.push_input(click, true)
			await physics_frame
		await settle()
		check(not terminal.confirming() and not lab.room_focus, "Physical No click returns to original room")
		check(terminal.quit_view.get_parent() == menu_parent and room._standby_text.visible, "Cancel restores original control parent and standby")
		lab.open_terminal()
		await settle()
		lab._on_terminal_action("quit")
		await settle()
		check(terminal.confirming() and room.confirmation_active() and room.visible, "Menu quit uses physical screen too")
		lab.escape()
		await settle()
		check(lab.room_focus and terminal.visible and terminal.primary.has_focus(), "Menu cancellation restores menu focus")
		lab.leave_terminal()
		await settle()
		lab._on_room_action("settings")
		await settle()
		hub.options_quit_button.pressed.emit()
		await settle()
		check(not hub.options_overlay.visible and terminal.confirming() and room.visible, "Room Settings quit cannot hide confirmation behind its return transition")
		for down: bool in [true, false]:
			var key := InputEventKey.new()
			key.keycode = KEY_ENTER
			key.pressed = down
			root.push_input(key, true)
			await process_frame
		await settle()
		check(not terminal.confirming() and not lab.room_focus and room.visible, "Enter on default No returns to room")
		hub.free()
		await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "physical terminal confirmation %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
