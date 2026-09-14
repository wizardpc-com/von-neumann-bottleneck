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
	await floating_input()
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

func pointer(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position=at; event.global_position=at
	event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed
	root.push_input(event,true)
	await process_frame

func floating_input() -> void:
	var desktop := Control.new()
	desktop.size=Vector2(1100,800); desktop.scale=Vector2(0.75,0.75)
	root.add_child(desktop)
	var panel: Control = load("res://src/ui/floating_instrument_panel.gd").new()
	panel.custom_minimum_size=Vector2(300,220)
	desktop.add_child(panel); panel.setup(&"task","Mission")
	panel.size=Vector2(400,300); panel.position=Vector2(50,50)
	await settle()
	var title: Control=panel.find_child("WindowTitle",true,false)
	var start: Vector2=title.get_global_rect().get_center()
	await pointer(start,true)
	var motion := InputEventMouseMotion.new()
	motion.position=start+Vector2(150,75); motion.global_position=motion.position
	# Captured motion may omit the button mask and leave the title bounds.
	root.push_input(motion,true); await process_frame
	check(panel.position.is_equal_approx(Vector2(250,150)),"Scaled Mission title follows viewport pointer without speed drift.")
	await pointer(motion.position,false)
	var before: Vector2=panel.position
	motion.position+=Vector2(30,30); motion.global_position=motion.position
	root.push_input(motion,true); await process_frame
	check(panel.position==before,"Release outside title ends the drag.")
	await pointer(title.get_global_rect().get_center(),true)
	panel.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	root.push_input(motion,true); await process_frame
	check(panel.position==before,"Floating Mission cancels on application focus loss.")
	await pointer(motion.position,false)
	desktop.queue_free(); await process_frame
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var ui: Control=load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
		root.add_child(ui); ui.size=Vector2(1600,1000)
		ui._show_tutorial(); await settle()
		check(ui.graph_stack.global_position.y < 230,"Compact header leaves more canvas in "+locale)
		var task: Control=ui.desktop_windows[&"task"]
		check(ui.graph_stack.size.y-task.size.y >= 80,"Initial Mission leaves vertical dragging room in "+locale)
		check(task.get_global_rect().encloses(ui.mission_briefing_continue_button.get_global_rect()),"Briefing navigation remains visible after compact sizing.")
		# At a shorter desktop the old 420px floor swallowed all vertical travel.
		ui.graph_stack.size=Vector2(1280,440)
		ui._layout_mission_briefing()
		check(task.size.y <= 360,"Short desktops keep Mission movable instead of forcing it full height.")
		ui.queue_free(); await process_frame
