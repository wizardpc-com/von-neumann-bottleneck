extends SceneTree
## QA controller routes on real workbenches; this script earns no progress.
func _init() -> void: call_deferred("run")
func settle() -> void:
	for frame: int in 12: await process_frame
func capture(name: String) -> void:
	await settle(); RenderingServer.force_draw(false); await process_frame
	DirAccess.make_dir_recursive_absolute("res://.godot/card-polish-captures")
	var result: Error = root.get_texture().get_image().save_png("res://.godot/card-polish-captures/" + name + ".png")
	assert(result == OK)
func run() -> void:
	assert(OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"))
	root.size = Vector2i(1280, 720); root.content_scale_size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var hardware: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
		root.add_child(hardware); await settle()
		hardware._show_tutorial(true); await settle()
		hardware._open_yi_help(); await settle()
		hardware.yi_help_card.body.complete_now()
		await capture(locale + "-tutorial-help")
		hardware.yi_help_card.close()
		hardware._start_campaign_level(&"half_adder", false); await settle()
		hardware._open_yi_help(); await settle()
		hardware.yi_help_card.body.complete_now()
		await capture(locale + "-half-adder-help")
		hardware.queue_free(); await settle()
		var system: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
		root.add_child(system); await settle()
		system._start_level(&"cpu_speed"); await settle()
		system._open_instrument(&"mission"); await settle()
		system.journey_context.toggle.button_pressed = true
		await capture(locale + "-cpu-context")
		var opening: CanvasLayer = load("res://src/ui/yi_opening.gd").present(self, &"chapter_1", &"cpu_speed", true)
		await settle(); opening.body.complete_now()
		await capture(locale + "-cpu-opening")
		opening.queue_free(); system.queue_free(); await settle()
	print("PASS: card-polish captures 8 real workbench frames")
	quit()
