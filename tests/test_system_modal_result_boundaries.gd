extends SceneTree
## Real viewport keys and real measurements at Chapter 1 presentation boundaries.
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func key(code: Key, command: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		event.meta_pressed = command and OS.get_name() == "macOS"
		event.ctrl_pressed = command and OS.get_name() != "macOS"
		root.push_input(event, true); await process_frame
func new_host() -> Control:
	root.get_node("SystemChapter").reset_test_progress()
	root.get_node("TaskNavigation").pending = "chapter_1/cpu_speed"
	var host: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(host); await settle()
	await fit_capture_window()
	return host
func fit_capture_window() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	if "--system-boundary-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		await settle()
		return
	var stable: int = 0
	for attempt: int in 60:
		DisplayServer.window_set_size(Vector2i(1280,720))
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var frame: Image = root.get_texture().get_image()
		stable = stable+1 if frame != null and frame.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Actual system viewport settles at 1280x720")
	await settle()
func capture(_host: Control, label: String) -> void:
	if "--system-boundary-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await fit_capture_window()
	RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame != null and frame.get_size() == Vector2i(1280, 720), label + ": capture size")
	if frame == null: return
	var path: String = "user://system-boundary-" + label + ".png"
	check(frame.save_png(path) == OK, label + ": capture saved")
	print("CAPTURE: " + ProjectSettings.globalize_path(path))
func measured(host: Control) -> void:
	host.prediction_selector.select(1); host._lock_prediction()
	host._run_official(); host._finish_playback()
	await settle()
	check(host.latest_receipt != null and host.latest_receipt.all_passed, "Real baseline run succeeds")
func cleared(host: Control, label: String) -> void:
	await settle()
	check(host.latest_receipt == null and host.current_trace == null and host.latest_official_traces.is_empty(), label + ": current evidence invalidated")
	check(host.official_result_box.get_child_count() == 0, label + ": obsolete case rows removed")
	check(host.test_status_label.text == host._t(&"system.test_bench.not_run"), label + ": verdict requires another run")
	check(not host.cycle_budget.visible and not host.cpu_time_breakdown.visible and not host.run_comparison.visible, label + ": old measured graphics hidden")
	check(host.profiler_labels[&"total_cycles"].text == host._t(&"system.profiler.no_data", [host._profiler_metric_name(&"total_cycles")]), label + ": profiler has no current metrics")
	check(host.playback_caption.text == host._t(&"system.test_bench.not_run"), label + ": playback caption is not stale")
func modal(host: Control, handbook: bool, label: String) -> void:
	var cpu: GraphNode = host.device_nodes[&"CPU"]
	var original: Vector2 = cpu.position_offset
	host._set_selected_system_devices([&"CPU"] as Array[StringName])
	host._on_system_begin_node_move(); cpu.position_offset += Vector2(35, 25); host._on_system_end_node_move()
	var moved: Vector2 = cpu.position_offset
	var history: Array = host.editor_history.duplicate(true)
	var topology: String = host._topology_from_graph().canonical_signature()
	var active_color: int = host.active_wire_color_index
	host.graph_pan_keys[KEY_D] = true
	if handbook:
		host.terminology_handbook.open_handbook()
		host.terminology_handbook.recommended_toggle.grab_focus()
	else: host._show_level_completion(&"cpu_speed")
	var scroll: Vector2 = host.graph.scroll_offset
	await settle()
	check(not root.gui_get_focus_owner() is LineEdit and not root.gui_get_focus_owner() is TextEdit, label + ": modal owns non-text focus")
	check(host.graph_pan_keys.is_empty() and host.graph.scroll_offset.is_equal_approx(scroll), label + ": modal clears held pan")
	await key(KEY_Z, true)
	check(cpu.position_offset == moved and host.editor_history == history, label + ": modal blocks undo")
	await key(KEY_A, true)
	await key(KEY_DELETE)
	for code: Key in [KEY_W, KEY_D, KEY_3]: await key(code)
	check(host._topology_from_graph().canonical_signature() == topology and host.editor_history == history, label + ": modal blocks board edits")
	check(host.graph.scroll_offset.is_equal_approx(scroll) and host.graph_pan_keys.is_empty(), label + ": modal blocks new pan")
	check(host.active_wire_color_index == active_color, label + ": modal preserves active wire color")
	await capture(host, label)
	if handbook:
		await key(KEY_ESCAPE)
		check(not host.terminology_handbook.is_open() and host.current_level_id == &"cpu_speed", label + ": Escape closes only handbook")
	else: host._dismiss_level_completion()
	host.graph.grab_focus(); await key(KEY_Z, true)
	check(cpu.position_offset == original, label + ": undo resumes after modal")
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use the isolated verification runner."); quit(1); return
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for handbook: bool in [true, false]:
			var modal_host: Control = await new_host()
			await modal(modal_host, handbook, locale + ("-handbook" if handbook else "-completion"))
			modal_host.queue_free(); await settle()
		var host: Control = await new_host()
		await measured(host)
		var chapter: Node = root.get_node("SystemChapter")
		var signature: String = chapter.receipts_for(&"cpu_speed")[0].canonical_signature()
		var old_trace = host.current_trace
		var old_receipt = host.latest_receipt
		var before: Dictionary = host._capture_system_editor_snapshot()
		host.device_nodes[&"CPU"].position_offset += Vector2(30, 20)
		host._commit_system_editor_snapshot(&"move", before)
		var wire: Dictionary = host.graph.get_connection_list()[0]
		before = host._capture_system_editor_snapshot()
		host.graph.set_connection_color_index(wire.from_node, wire.from_port, wire.to_node, wire.to_port, 2)
		host._commit_system_editor_snapshot(&"wire_color", before)
		check(host.current_trace == old_trace and host.latest_receipt == old_receipt, locale + ": moving and recoloring preserve actual evidence")
		var source: String = host.applied_program_source
		host.editor.text = source + "\n# pending draft\n"; host._on_program_changed()
		check(host.current_trace == old_trace and host.latest_receipt == old_receipt and host.official_result_box.get_child_count() > 0, locale + ": unapplied draft retains original measurement")
		host._apply_program()
		await cleared(host, locale + " Apply")
		check(chapter.receipts_for(&"cpu_speed")[0].canonical_signature() == signature, locale + ": Apply preserves historical evidence")
		# Restore exact authored source before another official measurement.
		host.editor.text = source; host._on_program_changed(); host._apply_program()
		await measured(host)
		host._on_disconnection_request(wire.from_node, wire.from_port, wire.to_node, wire.to_port)
		await cleared(host, locale + " disconnect")
		host._open_instrument(&"test_bench"); host._open_instrument(&"profiler")
		await capture(host, locale + "-invalidated")
		host._undo_system_edit(); await cleared(host, locale + " undo topology")
		await measured(host)
		host._redo_system_edit(); await cleared(host, locale + " redo topology")
		check(chapter.receipts_for(&"cpu_speed")[0].canonical_signature() == signature, locale + ": topology edits preserve historical evidence")
		host.queue_free(); await settle()
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "system modal/result boundaries %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
