extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.get_node("TaskNavigation").pending="chapter_4/fields"
		var host: Control=load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
		root.add_child(host)
		for frame: int in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/typography/"+locale+"-layout-mission-1280.png")
		host.queue_free(); await process_frame
	print("PASS: bilingual layout mission renders")
	quit()
