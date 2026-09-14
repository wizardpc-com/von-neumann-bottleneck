extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func settle() -> void:
	for frame: int in range(5): await process_frame
func move_panel(panel: Control, handle: Control, delta: Vector2) -> void:
	var start: Vector2 = handle.get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true; down.global_position = start
	handle.gui_input.emit(down)
	var motion := InputEventMouseMotion.new(); motion.global_position = start + delta
	panel._input(motion)
	var up := InputEventMouseButton.new(); up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false
	panel._input(up)
func run() -> void:
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub); hub.size = Vector2(1600, 1000)
		hub._open_options_menu(); await settle()
		var panel: Control = hub.find_child("ChapterOptionsPanel",true,false)
		var handle: Control = panel.get_child(0).get_child(0)
		var before: Vector2 = panel.position
		move_panel(panel,handle,Vector2(80,0)); await settle()
		check(panel.position.is_equal_approx(before+Vector2(80,0)), "Settings title moves its panel in "+locale)
		check(panel.get_global_rect().encloses(hub.options_resume_button.get_global_rect()), "Moved settings keep Close inside the panel.")
		move_panel(panel,handle,Vector2(-9000,-9000)); await settle()
		check(panel.position.x >= 16 and panel.position.y >= 16,"Dragging cannot lose the title offscreen.")
		hub.size = Vector2(1280,720); await settle()
		check(Rect2(Vector2.ZERO,hub.size).encloses(panel.get_global_rect()),"Moved settings remain reachable after shrinking the viewport.")
		var down := InputEventMouseButton.new(); down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; down.global_position=handle.get_global_rect().get_center()
		handle.gui_input.emit(down)
		panel.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		before=panel.position
		var motion := InputEventMouseMotion.new(); motion.global_position=Vector2(500,500); panel._input(motion)
		check(panel.position==before,"Focus loss cancels title dragging.")
		hub._close_options_menu()
		var book: Control = hub.terminology_handbook
		book.open_handbook(); await settle()
		var shell: Control = book.find_child("HandbookPanel",true,false)
		check(Rect2(Vector2.ZERO,hub.size).encloses(shell.get_global_rect()),"Handbook fits the minimum window in "+locale)
		var heading: Control = book.title_label.get_parent()
		move_panel(shell,heading,Vector2(-20,0)); await settle()
		check(shell.get_global_rect().has_point(book.title_label.global_position),"Handbook title moves together with the panel.")
		book.close_handbook(); hub.queue_free(); await process_frame
	if OS.get_name()=="macOS":
		var mode: Node = root.get_node("WindowMode")
		var key := InputEventKey.new(); key.keycode=KEY_COMMA; key.meta_pressed=true; key.pressed=true
		mode._input(key); await settle()
		check(is_instance_valid(mode.settings_layer),"macOS Command-comma opens settings.")
		if is_instance_valid(mode.settings_layer):
			mode.settings_layer.queue_free(); mode.settings_layer=null; await process_frame
	if failures.is_empty(): print("PASS: bilingual title drag, bounds, focus cancellation and macOS settings shortcut")
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
