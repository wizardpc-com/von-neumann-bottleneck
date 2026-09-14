extends SceneTree
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in range(10): await process_frame
func run() -> void:
	assert(str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("VonNeumannBottleneckChecks/"))
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for id: String in ["fields", "records", "batches", "mixed"]:
			root.get_node("TaskNavigation").pending = "chapter_4/" + id
			var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
			root.add_child(host)
			await settle()
			root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
			await settle()
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png("res://.godot/guidance-captures/mission-" + locale + "-" + id + ".png")
			host.queue_free()
			await settle()
	print("PASS: Mission rendering fixture")
	quit()
