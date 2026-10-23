extends SceneTree

var destination: String
var phase: String = "before"
var frames_root: String = "res://.godot/closeout-frames"

func _init() -> void:
	call_deferred("capture")

func settle() -> void:
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw

func capture() -> void:
	if DisplayServer.get_name() == "headless" or not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)):
		quit(2)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): destination = arg.trim_prefix("--evidence-dir=")
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		if arg.begins_with("--frames-dir="): frames_root = arg.trim_prefix("--frames-dir=")
	DirAccess.make_dir_recursive_absolute(destination)
	ProjectSettings.set_setting("game/reduced_motion", true)
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub)
	current_scene = hub
	await settle()
	var lab: Control = hub.get_node("Laboratory")
	var room: Control = lab.room
	var measurements: Array[Dictionary] = []
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1280,800), Vector2i(1440,1080), Vector2i(1920,900)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await settle()
		room.set_look(Vector2.ZERO)
		room.set_zoom(0.0)
		room._process(1.0)
		await settle()
		var label := "%s-%dx%d" % [phase, dimensions.x, dimensions.y]
		var rendered: Image = root.get_texture().get_image()
		if rendered.get_size() != dimensions:
			push_error("Unexpected capture dimensions: %s vs %s" % [rendered.get_size(), dimensions])
			quit(3)
			return
		rendered.save_png(destination.path_join(label + ".png"))
		var row: Dictionary = {"name": label, "fov": room.camera.fov, "room_size": str(room.size), "regions": {}}
		for id: String in ["archive", "journey", "terminal", "works", "handbook", "settings", "feedback"]:
			var rect: Rect2 = room.region_screen_rect(id)
			row.regions[id] = {"rect": str(rect), "enclosed": Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(rect)}
		measurements.append(row)
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	await settle()
	var empty_stations: Array[Dictionary] = []
	var empty_tasks: Array[Dictionary] = []
	room.update_progress(empty_stations, 0, 60, 1, empty_tasks, [{"name": "这是一个用于验证作品墙长名称完整边界的测试名字", "output": [0,1,2,3]}])
	await settle()
	root.get_texture().get_image().save_png(destination.path_join(phase + "-long-work.png"))
	var file := FileAccess.open(destination.path_join(phase + "-measurements.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements, "\t"))
	file.close()
	if phase == "after":
		lab._on_room_action("terminal")
		await settle()
		for english: bool in [false, true]:
			var state: Dictionary = lab.terminal.state.duplicate(true)
			state["english"] = english
			state["new_player"] = true
			state["response"] = {}
			lab.terminal.configure(state)
			ProjectSettings.set_setting("game/reduced_motion", false)
			lab.terminal.message.play(lab.terminal.message.text, true)
			lab.terminal.message.set_process(false)
			var frames_path: String = frames_root.path_join("yi-en" if english else "yi-zh")
			DirAccess.make_dir_recursive_absolute(frames_path)
			for frame in range(60):
				lab.terminal.message._process(0.1)
				lab.terminal.message.set_process(false)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(frames_path.path_join("%03d.png" % frame))
			ProjectSettings.set_setting("game/reduced_motion", true)
	print("CAPTURE_COMPLETE ", phase, " ", destination)
	quit()
