extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	var main = load("res://src/ui/main.tscn").instantiate()
	if "--baseline" in OS.get_cmdline_user_args(): main.set_script(load("res://.godot/s2-locality/base-main.gd"))
	root.add_child(main)
	current_scene = main
	await create_timer(1.0).timeout
	main._start_level(&"capstone" if "--capstone" in OS.get_cmdline_user_args() else &"distant_reads" if "--distant" in OS.get_cmdline_user_args() else &"access_order")
	await create_timer(1.0).timeout
	main._run_simulation("Official Test Set")
	await create_timer(1.5).timeout
	if "--distant" not in OS.get_cmdline_user_args() and "--capstone" not in OS.get_cmdline_user_args():
		main._load_strategy(preload("res://src/simulation/program_templates.gd").ROW_FIRST, "row-first")
		main._apply_program()
		main._run_simulation("Official Test Set")
	await create_timer(4.0).timeout
	var settings: Button = main.find_child("InLevelSettings", true, false)
	if "--baseline" not in OS.get_cmdline_user_args():
		assert(settings != null and root.get_visible_rect().encloses(settings.get_global_rect()))
	if "--flow" in OS.get_cmdline_user_args():
		await click(main.finish_playback_button)
		if "--distant" not in OS.get_cmdline_user_args():
			await click(main.result_trace_button)
			assert(main.instrument_windows[&"profiler"].visible)
			await click(main.instrument_windows[&"profiler"].find_child("CloseButton", true, false))
		if "--distant" in OS.get_cmdline_user_args():
			await click(main.test_evidence_button)
		else:
			await click(main.instrument_open_buttons[&"mission"])
		assert(main.instrument_windows[&"mission"].visible)
		var choice: Button = main.mission_judgment_buttons[&"repeated_ram" if "--distant" in OS.get_cmdline_user_args() else &"repeated_far_fetch"]
		var scroll: ScrollContainer = main.mission_judgment_box.get_parent().get_parent()
		scroll.ensure_control_visible(choice)
		await create_timer(0.5).timeout
		await click(choice)
		assert(not main.selected_judgment.is_empty())
		print("PASS: real viewport clicks: playback/evidence -> mission -> judgment: " if "--distant" in OS.get_cmdline_user_args() else "PASS: real viewport clicks: result -> trace -> mission -> judgment: ", main.selected_judgment)
	root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()

func click(control: Control) -> void:
	assert(control != null and control.is_visible_in_tree())
	var point: Vector2 = control.get_global_rect().get_center()
	assert(root.get_visible_rect().has_point(point))
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await process_frame
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await create_timer(0.4).timeout
