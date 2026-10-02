extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var failed := false
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate(); root.add_child(hub)
		root.mode=Window.MODE_WINDOWED; await create_timer(1.5).timeout
		root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720)
		hub._open_options_menu()
		for frame: int in 5: await process_frame
		var slider: HSlider=hub.find_child("AmbienceVolume",true,false)
		var steady: CheckButton=hub.find_child("AmbienceReducedDynamics",true,false)
		var scroll: ScrollContainer=hub.find_child("SettingsScroll",true,false)
		scroll.ensure_control_visible(steady)
		for frame: int in 4: await process_frame
		failed=failed or not scroll.get_global_rect().encloses(slider.get_global_rect()) or not scroll.get_global_rect().encloses(steady.get_global_rect())
		RenderingServer.force_draw(false)
		failed=hub.get_viewport().get_texture().get_image().save_png("res://docs/verification/20261002-trace-ambience/"+locale+"-settings.png")!=OK or failed
		hub.queue_free(); await process_frame
	print("FAIL: ambience settings render" if failed else "PASS: bilingual ambience controls in 1280x720 settings")
	quit(1 if failed else 0)
