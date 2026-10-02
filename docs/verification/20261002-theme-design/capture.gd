extends SceneTree
## Render-only fixture: Test mode, never ordinary Game completion evidence.
var failed: bool = false

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.get_node("GameMode").set_mode(&"test")
	for frame: int in range(8): await process_frame
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		root.mode = Window.MODE_WINDOWED
		await create_timer(1.5).timeout
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
		var main: Control = load("res://src/ui/main.tscn").instantiate()
		root.add_child(main)
		for frame: int in range(8): await process_frame
		main.call("_start_level", &"blocking")
		for id: StringName in main.instrument_windows:
			main.call("_close_instrument", id)
		main.call("_open_instrument", &"blocking")
		for frame: int in range(8): await process_frame
		var window: Control = main.instrument_windows[&"blocking"]
		window.position = Vector2(40, 20)
		window.size = Vector2(450, 370)
		for frame: int in range(4): await process_frame
		var button: Button = main.block_card_buttons[4]
		var scroll: ScrollContainer = button.get_parent().get_parent()
		scroll.ensure_control_visible(button)
		for frame: int in range(4): await process_frame
		failed = failed or not window.get_global_rect().encloses(button.get_global_rect())
		button.pressed.emit()
		failed = failed or main.current_block_lines != 4
		await _save(locale+"-groups")
		main.call("_close_instrument", &"blocking")
		main.call("_open_instrument", &"mission")
		for frame: int in range(5): await process_frame
		await _save(locale+"-mission")
		main.queue_free()
		await process_frame
	print("FAIL: blocking capture" if failed else "PASS: bilingual 1280x720 rendered blocking controls and mission")
	quit(1 if failed else 0)

func _save(label: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	print(label, " window=", root.size, " viewport=", root.get_texture().get_size())
	failed = failed or root.size != Vector2i(1280, 720)
	var code: Error = root.get_texture().get_image().save_png("res://docs/verification/20261002-theme-design/"+label+".png")
	failed = failed or code != OK
