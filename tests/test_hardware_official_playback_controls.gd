extends SceneTree
## Actual keyboard input must match the advertised Step button during a test.

var failures: Array[String] = []
var checks: int = 0
var bench: Control

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle(frames: int = 5) -> void:
	for frame: int in frames: await process_frame

func key(code: Key, command: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.ctrl_pressed = command
		root.push_input(event, true)
		await process_frame

func settle_capture_window() -> void:
	# Native macOS startup can resize after the initial deferred window setup.
	# Require consecutive rendered frames at the requested size, never rescale evidence.
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable + 1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: return

func capture_controls() -> void:
	if "--official-playback-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle_capture_window()
	await settle()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	for control: Control in [bench.trace_step_button, bench.finish_official_button, bench.clock_period_control]:
		check(control.is_visible_in_tree() and viewport_rect.encloses(control.get_global_rect()),
			"Playback controls fit the rendered viewport: " + control.name)
	RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame.get_size() == Vector2i(1280, 720), "Official playback capture retains 1280x720 pixels")
	var folder: String = "res://.godot/official-playback/"
	DirAccess.make_dir_recursive_absolute(folder)
	check(frame.save_png(folder + root.get_node("Localization").current_locale() + ".png") == OK,
		"Official playback controls capture is saved")

func evidence(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for name: Variant in value: result[name] = evidence(value[name])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(evidence(item))
		return result
	if value is Object:
		if value is DigitalValue:
			return value.to_dictionary()
		if value is CircuitTrace or value is PrologueSimulationResult:
			return {"signature": value.canonical_signature(), "error_specs": value.error_specs.duplicate(true)}
		if value is CircuitEvent or value is PrologueEvent: return evidence(value.to_dictionary())
		check(false, "Every evidence object has an explicit complete snapshot")
	return value

func prepare(level: StringName, valid: bool = true) -> void:
	bench._start_campaign_level(level, false)
	await settle(8)
	bench._clear_wires()
	var wires: Array = bench._half_adder_reference_wires() if level == &"half_adder" else bench.current_level_definition.reference_wires
	for wire: Dictionary in wires:
		bench._on_connection_request(wire.get("from", wire.get("from_node")), int(wire.get("from_port", 0)),
			wire.get("to", wire.get("to_node")), int(wire.get("to_port", 0)))
	if not valid:
		# Remove one real output connection: all original cases still run, with
		# actual wrong/missing output evidence rather than fabricated verdicts.
		var last: Dictionary = wires.back()
		bench._on_disconnection_request(last.get("from", last.get("from_node")), int(last.get("from_port", 0)),
			last.get("to", last.get("to_node")), int(last.get("to_port", 0)))
	await settle()
	bench.set_process(false)

func row_texts(labels: Array) -> Array[String]:
	var texts: Array[String] = []
	for label: Variant in labels:
		texts.append(label.text if is_instance_valid(label) else "<missing result row>")
	return texts

func result_snapshot() -> Dictionary:
	return {
		"report": evidence(bench.official_report if bench.current_phase == &"half_adder" else bench.prologue_report),
		"runtime": evidence(bench.prologue_runtime_state), "prior": evidence(bench.prologue_prior_outputs),
		"passed": bench.official_passed, "signature": bench.passing_topology_signature,
		"seal_disabled": bench.seal_button.disabled,
		# The final prologue report is independently re-simulated. These actual
		# row presentations and ALU outcomes separately prove every case was revealed.
		"half_rows": row_texts(bench.official_case_labels) if bench.current_level_id == &"half_adder" else [],
		"prologue_rows": row_texts(bench.prologue_case_labels) if bench.current_level_id != &"half_adder" else [],
		"alu_outcomes": bench.alu_case_outcomes.duplicate(true),
	}

func check_revealed_rows(level: StringName, path: String) -> void:
	var half: bool = level == &"half_adder"
	var cases: Array = bench.official_report.get("cases", []) if half else bench.prologue_report.get("steps", [])
	var rows: Array[String] = row_texts(bench.official_case_labels if half else bench.prologue_case_labels)
	var count: int = 4 if half else bench.current_level_definition.official_steps.size()
	check(rows.size() == count and cases.size() == count, "%s/%s has exactly one real row for every authored case" % [level, path])
	for index: int in mini(rows.size(), cases.size()):
		var outcome: String = bench._t(&"outcome.pass" if cases[index].passed else &"outcome.fail")
		check(rows[index].contains(outcome), "%s/%s row %d reveals its actual pass/fail outcome instead of pending text" % [level, path, index + 1])
		if not half:
			check(rows[index].begins_with("#%d  " % (index + 1)), "%s/%s row %d retains its authored sequence number" % [level, path, index + 1])
		if level == &"alu":
			check(bench.alu_case_outcomes.has(index) and bench.alu_case_outcomes[index] == cases[index].passed,
				"%s ALU outcome %d was revealed with the actual verdict" % [path, index + 1])
	if level == &"alu":
		check(bench.alu_case_outcomes.size() == count, "%s ALU outcomes cover every original case without duplicates" % path)

func finish_normally() -> void:
	var remaining: int = 150
	while bench.official_sequence_active and remaining > 0:
		bench._finish_playback()
		await process_frame
		remaining -= 1
	check(not bench.official_sequence_active, "Ordinary per-case completion terminates")

func finish_requested() -> void:
	bench.finish_official_button.pressed.emit()
	var index: int = bench.official_sequence_index
	# Repeated input must not synchronously consume another case or award credit.
	bench.finish_official_button.pressed.emit()
	bench._finish_official_playback()
	check(bench.official_sequence_index == index and not bench.official_passed,
		"Repeated finish requests do not skip cases or award completion")
	check(bench.finish_official_button.disabled, "Finish request immediately disables its action")
	var remaining: int = 150
	while bench.official_sequence_active and remaining > 0:
		await process_frame
		remaining -= 1
	check(not bench.official_sequence_active and not bench.official_finish_requested,
		"Requested completion drains through existing deferred cases and clears its flag")
	check(not bench.finish_official_button.visible, "Finish control hides when the official sequence finishes")

func compare_runs(level: StringName, valid: bool) -> void:
	await prepare(level, valid)
	var progression: String = bench.player_content.canonical_signature()
	var topology: String = bench._circuit_from_graph().canonical_signature()
	bench._run_official()
	await finish_normally()
	check_revealed_rows(level, "ordinary")
	var normal: Dictionary = result_snapshot()
	check(bench.official_passed == valid, "Ordinary fixture has expected verdict: %s/%s" % [level, valid])
	bench.level_completion_overlay.dismiss()
	bench._run_official()
	await finish_requested()
	check_revealed_rows(level, "requested")
	check(result_snapshot() == normal, "Full report, ordered events, storage state and seal gate match ordinary completion: %s/%s" % [level, valid])
	check(bench.player_content.canonical_signature() == progression and bench._circuit_from_graph().canonical_signature() == topology,
		"Viewing results preserves unsealed progression and circuit: %s/%s" % [level, valid])
	var report: Dictionary = bench.official_report if level == &"half_adder" else bench.prologue_report
	var expected_count: int = 4 if level == &"half_adder" else bench.current_level_definition.official_steps.size()
	check(report.get("cases", report.get("steps", [])).size() == expected_count,
		"All authored cases remain in the final report: %s/%s" % [level, valid])
	var saved: Dictionary = result_snapshot()
	bench._finish_official_playback()
	await settle()
	check(result_snapshot() == saved, "Finish after completion is a no-op")
	bench.level_completion_overlay.dismiss()

func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile.")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	var game_before: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	bench = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench)
	current_scene = bench
	await settle()
	check(not bench.finish_official_button.visible, "Non-official workbench has no unrelated finish control")
	bench._start_campaign_level(&"ram", false)
	await settle(8)
	for wire: Dictionary in bench.current_level_definition.reference_wires:
		bench._on_connection_request(wire["from"], int(wire.get("from_port", 0)),
			wire["to"], int(wire.get("to_port", 0)))
	bench._run_official()
	bench.playback_running = false
	# Freeze only the presentation clock: viewport input and deferred callbacks
	# still run, so a single F5 is the sole cause of any step in this assertion.
	bench.set_process(false)
	check(bench.official_sequence_active and bench.playback_batches.size() > 2,
		"Real RAM official case has multiple presentation batches")
	check(not bench.trace_step_button.disabled and bench.trace_step_button.text.contains("F5"),
		"Official test advertises an enabled F5 Step action")
	check(bench.finish_official_button.visible and not bench.finish_official_button.disabled,
		"Official sequence exposes the finish action")
	await capture_controls()
	bench.graph.grab_focus()
	await settle(2)
	var before: int = bench.playback_index
	var case_before: int = bench.official_sequence_index
	var history_before: int = bench.wire_history.size()
	await key(KEY_F5)
	check(bench.playback_index == before + 1 and not bench.playback_running,
		"Viewport F5 advances exactly one paused official playback batch")
	check(bench.official_sequence_active and bench.official_sequence_index == case_before,
		"F5 preserves the ongoing official case rather than skipping its result")
	check(bench.wire_history.size() == history_before and not bench.official_passed and bench.seal_button.disabled,
		"Stepping changes no topology or sealing eligibility")
	var button_before: int = bench.playback_index
	bench.trace_step_button.pressed.emit()
	check(bench.playback_index == button_before + 1,
		"Existing Step button advances the same official playback")
	# Modifier and real text focus must not borrow the official playback shortcut.
	var protected_index: int = bench.playback_index
	await key(KEY_F5, true)
	check(bench.playback_index == protected_index, "Modified F5 does not step the official test")
	bench.clock_period_control.get_line_edit().grab_focus()
	await key(KEY_F5)
	check(bench.playback_index == protected_index, "Numeric text focus keeps F5 out of the workbench")
	await key(KEY_F10)
	await settle()
	var settings: CanvasLayer = root.get_node("WindowMode").settings_layer
	check(is_instance_valid(settings), "Actual Settings opens during the paused official test")
	if is_instance_valid(settings):
		var resume: Button = settings.find_child("OptionsResumeButton", true, false)
		if resume != null: resume.grab_focus()
		await key(KEY_F5)
		check(bench.playback_index == protected_index, "Settings button focus blocks official F5")
		await key(KEY_ESCAPE)
	bench._cancel_official_sequence()
	bench._stop_playback()
	for level: StringName in [&"half_adder", &"ram", &"alu"]:
		await compare_runs(level, true)
		await compare_runs(level, false)
	# A queued completion from the abandoned run must not consume the new run.
	await prepare(&"ram")
	bench._run_official()
	bench._finish_official_playback()
	bench._cancel_official_sequence()
	check(not bench.finish_official_button.visible, "Cancelling the official sequence hides its finish action")
	bench._stop_playback()
	bench._run_official()
	await settle()
	check(bench.official_sequence_active and bench.official_sequence_index == 0 and bench.playback_index == 0
		and not bench.official_finish_requested and not bench.finish_official_button.disabled,
		"Cancellation isolates queued callbacks and restores ordinary presentation for the next run")
	bench._cancel_official_sequence()
	bench._stop_playback()
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == game_before,
		"Test playback controls never modify earned Game content")
	bench.queue_free()
	await settle()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "hardware official playback controls %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
