extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 8:
		await process_frame

func check_edit(main: Control, fresh: bool, context: String) -> void:
	check(main.status_label.text == main._t(&"hardware.status.building" if fresh else &"hardware.status.topology_changed"),
		context + ": direct wiring distinguishes building from retesting")
	check(main.status_label.get_theme_color("font_color") == (main.ACCENT if fresh else main.WARNING),
		context + ": first-build guidance is calm; stale results remain a warning")
	check(main.trace_caption_label.text == main._t(&"hardware.trace.empty" if fresh else &"hardware.trace.topology_changed"),
		context + ": Trace copy does not invent an earlier run")
	check(not main.official_passed and main.passing_topology_signature.is_empty() and main.seal_button.disabled,
		context + ": editing never retains official evidence or sealing permission")

func finish_official(main: Control) -> void:
	for frame: int in 64:
		if not main.official_sequence_active:
			return
		if main.playback_running:
			main._finish_playback()
		await process_frame
	check(false, "Official sequence must reach its existing terminal result")

func run() -> void:
	root.get_node("GameMode").set_mode(&"game")
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test("user://first-build-save.json", "user://first-build-workbench.json")
	for locale: String in ["en", "zh_CN"]:
		root.get_node("Localization").set_locale(locale)
		var main: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
		root.add_child(main)
		await settle()
		# A synthetic prerequisite is only for these controller regressions.
		main.completed_levels[&"tutorial"] = true
		main._start_campaign_level(&"tutorial", false)
		await settle()
		main._run_debug()
		main._start_campaign_level(&"half_adder", false)
		await settle()
		main._clear_wires()
		main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
		check_edit(main, true, locale + " first Half Adder wire after Tutorial run")
		main.input_a_button.button_pressed = true
		await settle()
		check(main.current_trace != null, locale + ": input switching actually exercises live Trace preview")
		main._on_connection_request(&"B_IN", 0, &"NOT_1_COPY_001", 0)
		check_edit(main, true, locale + " live input preview")
		main._enter_hint_workbench()
		main._exit_hint_workbench()
		await settle()
		main._on_disconnection_request(&"A_IN", 0, &"NOT_1", 0)
		check_edit(main, true, locale + " untested Hint return")
		main._run_debug()
		main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
		check_edit(main, false, locale + " edit after debug attempt")
		main._on_disconnection_request(&"A_IN", 0, &"NOT_1", 0)
		check_edit(main, false, locale + " repeated edit")
		main._reset_current_simulation()
		main._enter_hint_workbench()
		main._exit_hint_workbench()
		await settle()
		main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
		check_edit(main, false, locale + " reset and tested Hint return")
		main._clear_wires()
		for wire: Dictionary in main._half_adder_reference_wires():
			main._on_connection_request(wire.from_node, wire.from_port, wire.to_node, wire.to_port)
		main._run_official()
		await finish_official(main)
		check(main.official_passed and not main.seal_button.disabled, locale + ": unchanged Half Adder passes all four cases")
		main._dismiss_level_completion()
		main._on_disconnection_request(&"B_IN", 0, &"NOT_1", 0)
		check_edit(main, false, locale + " official pass invalidation")
		# A newly opened storage board exercises the separate prologue run path.
		main._start_campaign_level(&"latch", false)
		await settle()
		main._clear_wires()
		var wire: Dictionary = main.current_level_definition.reference_wires[0]
		main._on_connection_request(wire.from, int(wire.get("from_port", 0)), wire.to, int(wire.get("to_port", 0)))
		check_edit(main, true, locale + " fresh prologue board")
		main._run_debug()
		main._on_disconnection_request(wire.from, int(wire.get("from_port", 0)), wire.to, int(wire.get("to_port", 0)))
		check_edit(main, false, locale + " prologue debug attempt")
		main._start_campaign_level(&"half_adder", false)
		await settle()
		main._clear_wires()
		main._run_official()
		await finish_official(main)
		check(not main.official_passed, locale + ": incomplete official circuit still fails")
		main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
		check_edit(main, false, locale + " failed official attempt")
		main.queue_free()
		await settle()
	print("PASS: first-build guidance (%d checks)" % checks if failures.is_empty() else "FAIL: first-build guidance")
	quit(0 if failures.is_empty() else 1)
