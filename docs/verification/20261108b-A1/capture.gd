extends "res://tests/test_lab_saved_work_window.gd"
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	var phase := "before"
	var english: bool = get_root().get_node("Localization").current_locale() == "en"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	hub = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await create_timer(8).timeout
	var room = hub.laboratory.room
	var samples: Array[float] = []
	for i in 180:
		var start := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec()-start)/1000.0)
	var sum := 0.0
	for sample in samples: sum += sample
	print("FRAME_MEAN_MS ",sum/samples.size()," FPS ",Performance.get_monitor(Performance.TIME_FPS))
	await shot(phase + ("-en" if english else "-room"))
	if not english:
		ProjectSettings.set_setting("game/reduced_motion",true)
		room.set_physics_process(false)
		for id in ["settings","archive"]:
			room._set_hover(id)
			hub.laboratory._process_immersive_room(0.0)
			await create_timer(0.5).timeout
			await shot(phase + "-" + id)
		room._set_hover("")
		room.activated.emit("archive")
		await create_timer(1).timeout
		hub.laboratory.archive.close()
		await create_timer(1).timeout
		await shot(phase + "-returned")
	print("ROOM_CAPTURE_DONE")
	quit()
func shot(stem: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/verification/20261108b-A1/" + stem + ".png")
