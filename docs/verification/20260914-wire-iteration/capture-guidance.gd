extends SceneTree
## Renderer fixture: use only an isolated verifier copy. Does not claim earned play.
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in range(8): await process_frame
func run() -> void:
	assert(str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).begins_with("VonNeumannBottleneckChecks/"))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	var handbook: Variant = load("res://src/ui/terminology_handbook.gd").new()
	root.add_child(handbook)
	var folder := "res://.godot/guidance-captures/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for term: StringName in [&"bit_width", &"data_layout", &"field_group", &"copy_cost", &"bounded_batch", &"multiplexer", &"alu", &"accumulator", &"cache"]:
			handbook.open_handbook(term)
			await settle()
			# Locale/display preferences may finish restoring after startup.
			root.mode = Window.MODE_WINDOWED
			root.size = Vector2i(1280, 720)
			root.content_scale_size = Vector2i(1280, 720)
			for step: int in range(handbook.detail_diagram.example_count()):
				await settle()
				RenderingServer.force_draw(false)
				print(locale, " ", term, " ", step, " pixels=", root.get_texture().get_size(), " logical=", root.content_scale_size)
				assert(root.get_texture().get_image().save_png(folder + locale + "-" + String(term) + "-" + str(step) + ".png") == OK)
				handbook.detail_diagram.advance_example(1)
				handbook._refresh_diagram_controls()
	print("PASS: bilingual compact handbook rendering fixture")
	quit()
