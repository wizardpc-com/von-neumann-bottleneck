extends SceneTree
var options: Dictionary = {}
func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2: options[pair[0]] = pair[1]
	call_deferred("run")
func run() -> void:
	ProjectSettings.set_setting("playtest/offline_tester", true)
	var save: Node = root.get_node("GlobalSave")
	save.disk_write_allowed = true
	auto_accept_quit = false
	root.get_node("GameMode").set_mode(&"game")
	save.load_game()
	var route: String = options.route
	root.get_node("TaskNavigation").enter(route)
	for frame: int in 20: await process_frame
	var host: Control = current_scene
	var layout: bool = route.begins_with("chapter_4")
	if options.phase == "load":
		var actual: String = str(host.design.batch) if layout else host.editor.text
		print("RESTORED: ", actual == ("2" if layout else "# D1 recovery marker"))
		quit()
		return
	if layout:
		host.design.batch = 2
		host._changed(false)
	else:
		host.editor.select_all()
		host.editor.insert_text_at_caret("# D1 recovery marker")
	if options.scenario == "late": await create_timer(2.5).timeout
	if options.scenario in ["early", "late"]:
		FileAccess.open(options.ready, FileAccess.WRITE).store_string("ready")
		await create_timer(120).timeout
	elif options.scenario == "close":
		root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	elif options.scenario == "quit":
		save.request_quit()
	elif options.scenario == "map":
		if layout: host._leave()
		elif route.begins_with("chapter_3"): host._show_map()
		else: host._open_map()
		for frame: int in 10: await process_frame
		quit()
	elif options.scenario == "lab":
		if layout: host._leave_to_lab()
		else:
			if route.begins_with("chapter_3"): host._save_draft()
			change_scene_to_file("res://src/ui/prototype_hub.tscn")
		for frame: int in 10: await process_frame
		quit()
