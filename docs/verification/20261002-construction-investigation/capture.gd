extends "res://tests/test_hardware_prologue_ui.gd"
## Rendered fixture with test-earned reusable components; not native player evidence.
var capture_locale := "zh_CN"

func _run() -> void:
	if "--english" in OS.get_cmdline_user_args(): capture_locale = "en"
	root.get_node("Localization").set_locale(capture_locale)
	await super._run()

func _exercise_investigation(main: Control, level: StringName) -> void:
	await super._exercise_investigation(main, level)
	var panel: VBoxContainer = main.get("construction_investigation")
	for values: Dictionary in preload("res://src/hardware_foundations/construction_investigation.gd").presets(level):
		main.call("_apply_investigation_inputs", values)
		main.call("_run_debug")
		main.call("_finish_playback")
	panel.get_child(0).button_pressed = true
	root.mode = Window.MODE_WINDOWED
	await create_timer(1.5).timeout
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	for key: StringName in main.desktop_windows:
		main.desktop_windows[key].hide()
	main.call("_show_desktop_window", &"test_bench")
	var window: Control = main.desktop_windows[&"test_bench"]
	window.position = Vector2(30, 20)
	window.size = Vector2(520, 380)
	for frame: int in 5: await process_frame
	var scroll: ScrollContainer = main.side_box.get_parent()
	scroll.ensure_control_visible(panel.get_child(1).get_child(0))
	await _capture_image(level, "inputs")
	scroll.ensure_control_visible(panel.evidence)
	await _capture_image(level, "evidence")
	main.call("_reset_storage_debug_state")

func _capture_image(level: StringName, section: String) -> void:
	for frame: int in 3: await process_frame
	RenderingServer.force_draw(false)
	_assert(root.size == Vector2i(1280, 720), "Capture viewport is 1280x720")
	var path := "res://docs/verification/20261002-construction-investigation/%s-%s-%s.png" % [capture_locale, level, section]
	_assert(root.get_texture().get_image().save_png(path) == OK, "Capture is saved")
