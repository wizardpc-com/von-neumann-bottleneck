extends SceneTree
## Run only in an imported isolated copy with a fresh custom user directory.
## Real scenes, ordinary unlocked Tutorial, no injected completion or solution.
func _init() -> void:
	call_deferred("run")

func settle() -> void:
	for frame: int in range(12): await process_frame

func snap(label: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image.save_png("res://.godot/" + label + ".png") == OK)

func run() -> void:
	assert(ProjectSettings.get_setting("application/config/use_custom_user_dir", false))
	assert(str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("VonNeumannBottleneckChecks/"))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = Vector2i(1600, 1000)
	var navigation: Node = root.get_node("TaskNavigation")
	for locale: String in ["en", "zh_CN"]:
		root.get_node("Localization").set_locale(locale)
		change_scene_to_file("res://src/ui/prototype_hub.tscn")
		await snap(locale + "-hub")
		navigation.camera_saved = false
		change_scene_to_file("res://src/campaign/task_tree.tscn")
		await settle()
		var tree: Control = current_scene
		var area: Rect2 = tree.canvas.region_rects[0]
		tree.canvas.magnification = minf(0.68, (tree.canvas.size.x - 48.0) / area.size.x)
		tree.canvas.pan = Vector2(24, 26) - area.position * tree.canvas.magnification
		tree.canvas.queue_redraw()
		await snap(locale + "-tree")
		assert(navigation.enter("hardware_foundations/tutorial"))
		await settle()
		current_scene.call("_start_building_from_briefing")
		await settle()
		var palette: Control = current_scene.desktop_windows[&"components"]
		var card: Control = current_scene.palette_cards[0]
		assert(palette.get_global_rect().encloses(card.get_global_rect()), "First component card must be fully visible on entry")
		await snap(locale + "-tutorial")
	print("PASS: six direct bilingual scene captures, fresh profile, full first palette card")
	quit()
