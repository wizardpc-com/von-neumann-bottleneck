extends SceneTree
var failed := false
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var chapter: Node = root.get_node("SystemChapter")
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN", "en"]:
		chapter.reset_test_progress()
		root.get_node("Localization").set_locale(locale)
		var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
		root.add_child(main)
		for frame: int in 5: await process_frame
		var parts := {&"cpu": &"cpu_fast", &"ram": &"ram_slow", &"bus": &"bus_8"}
		chapter.record_receipt(&"cpu_speed", main.catalog.replay_observation(&"cpu_speed",main.catalog.PROGRAM_SUM,parts))
		main._start_level(&"ram_wait")
		root.mode = Window.MODE_WINDOWED
		await create_timer(1.5).timeout
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		for id: StringName in main.instrument_windows: main._close_instrument(id)
		main._open_instrument(&"test_bench")
		main.instrument_windows[&"test_bench"].position = Vector2(30,20)
		main.instrument_windows[&"test_bench"].size = Vector2(550,400)
		for frame: int in 5: await process_frame
		failed = failed or main.reuse_baseline_button.disabled or not main.instrument_windows[&"test_bench"].get_global_rect().encloses(main.reuse_baseline_button.get_global_rect())
		await _capture(locale+"-reuse")
		main.prediction_selector.select(1)
		main._lock_prediction()
		main.reuse_baseline_button.pressed.emit()
		failed = failed or chapter.receipts_for(&"ram_wait").size() != 1 or chapter.completed_levels().get(&"ram_wait",false)
		main._close_instrument(&"history")
		await _capture(locale+"-reused")
		main.queue_free()
		await process_frame
	print("FAIL: baseline render fixture" if failed else "PASS: bilingual 1280x720 optional reuse action and verified status")
	quit(1 if failed else 0)
func _capture(label: String) -> void:
	for frame: int in 4: await process_frame
	RenderingServer.force_draw(false)
	failed = failed or root.size != Vector2i(1280,720)
	failed = root.get_texture().get_image().save_png("res://docs/verification/20261002-baseline-continuity/"+label+".png") != OK or failed
