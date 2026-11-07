extends SceneTree
var phase := "before"
func _init() -> void: call_deferred("run")
func wait() -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute("res://.godot/a3")
	if "--after" in OS.get_cmdline_user_args(): phase = "after"
	var populated: bool = "--populated" in OS.get_cmdline_user_args()
	if populated:
		phase = "after-populated"
		var session_type = load("res://experiments/creation/session.gd")
		var writer = session_type.new()
		assert(writer.open(session_type.default_path()).writable)
		assert(writer.train().ok and writer.transport([0, 1, 0, 2], "predictive").ok)
		writer.set_mode("predict"); writer.begin_prediction("practice")
		while not writer.prediction.finished: writer.commit_prediction(); writer.reveal_prediction()
		writer.set_mode("generate")
		for index: int in 3:
			assert(writer.generate().ok and writer.save_work("QA work %d" % (index + 1)).ok)
		writer.close()
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_preferred_locale(locale)
		var hub: Node = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub); current_scene = hub
		await wait()
		for world: String in ["room", "terminal"]:
			for id: String in ["archive", "works", "achievements", "settings", "feedback"]:
				if populated and id != "works": continue
				match id:
					"archive": hub.laboratory._present_archive()
					"works": hub._open_journey_journal()
					"achievements": hub._open_hub_navigation()
					"settings": hub._open_options_menu()
					"feedback": root.get_node("PlaytestMoments").toggle()
				if world == "room":
					var empty: Array[Control] = []
					hub.laboratory._dress_pages(id, empty)
				else: hub.laboratory._clear_skins()
				await wait()
				root.get_texture().get_image().save_png("res://.godot/a3/"+phase+"-"+world+"-"+id+"-"+locale+".png")
				match id:
					"archive": hub.laboratory.archive.close()
					"works": hub.journey_journal.close()
					"achievements": hub._close_hub_navigation()
					"settings": hub._close_options_menu()
					"feedback": root.get_node("PlaytestMoments").close()
				await wait()
		hub.queue_free()
		await wait()
	quit()

