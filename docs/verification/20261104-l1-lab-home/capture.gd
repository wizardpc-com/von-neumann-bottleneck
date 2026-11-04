extends "res://tests/test_lab_saved_work_window.gd"
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	ProjectSettings.set_setting("game/reduced_motion", true)
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	var phase := "before"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	hub = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await create_timer(4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/l1c/%s-room.png" % phase)
	var room = hub.laboratory.room
	for id in ["handbook","settings","feedback","works","achievements","archive"]:
		print("BOUNDS ", id, " ",room.region_bounds(id)," RECT ", room.region_screen_rect(id))
		room.set_physics_process(false)
		var rect: Rect2 = room.region_screen_rect(id)
		var event := InputEventMouseMotion.new()
		event.position = rect.get_center()
		if room._pick(event.position) != id:
			for y in range(int(rect.position.y), int(rect.end.y), 3):
				for x in range(int(rect.position.x), int(rect.end.x), 3):
					if room._pick(Vector2(x,y)) == id:
						event.position = Vector2(x,y)
						break
				if room._pick(event.position) == id: break
		event.global_position = event.position
		Input.warp_mouse(event.position)
		root.push_input(event)
		# Exercise the production ray and hover presentation without depending on OS cursor ownership.
		room._set_hover(room._pick(event.position))
		await create_timer(0.4).timeout
		print("HOVER ", id, " actual=",room._hovered)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/l1c/%s-%s.png" % [phase,id])
	if prepare_saved_work():
		hub.laboratory._read_progress()
		var rows: Array[Dictionary] = hub.laboratory.LabState.tasks()
		var counts: Dictionary = hub.laboratory.LabState.progress_counts(rows)
		room.update_progress(hub.laboratory.station_progress,counts.done,counts.total,1,rows,[fixture],false)
		await settle(20)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/l1c/%s-work.png" % phase)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/l1c/%s-reduced.png" % phase)
	room.set_physics_process(true)
	ProjectSettings.set_setting("game/reduced_motion", false)
	Input.warp_mouse(Vector2(640,360))
	await create_timer(1).timeout
	var samples: Array[float] = []
	for i in 180:
		var start := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec()-start)/1000.0)
	var sum := 0.0
	for sample in samples: sum += sample
	print("FRAME_MEAN_MS ",sum/samples.size()," FPS_MONITOR ",Performance.get_monitor(Performance.TIME_FPS))
	quit()
