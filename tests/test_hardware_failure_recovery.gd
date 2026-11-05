extends SceneTree
## In-memory diagnostic circuit in the real Test-mode host. Renderer runs use
## viewport input; headless runs exercise the same controls' connected callbacks.
## This fixture does not establish native input or earned campaign completion.

const Component = preload("res://src/circuit/logic_component.gd")

var checks: int = 0
var failures: Array[String] = []
# Load the real scene after autoloads enter the tree; a script-class annotation
# would compile its autoload-dependent host before --script initializes them.
var bench: Control
var original_reduced_motion: bool = false
var game_signature: String = ""
var protected_files: Dictionary = {}


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
	return ok


func settle(frames: int = 6) -> void:
	for frame: int in frames:
		await process_frame


func _protected_files() -> Dictionary:
	var files: Dictionary = {}
	for base: String in ["user://savegame_v1.json", "user://hardware_workbenches_v1.json"]:
		for suffix: String in ["", ".tmp", ".bak"]:
			var path: String = base + suffix
			files[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else null
	return files


func _terminal(id: StringName, kind: StringName, signal_name: StringName, width: int) -> LogicComponent:
	return Component.new(id, kind, String(signal_name), signal_name, true,
		[], [], [], [], {"width": width})


func _install_diagnostic_board() -> void:
	# Preserve the actual registered lesson/progression authority. Only this
	# host's detached descriptor and temporary Test inventory receive the board.
	var definition: Dictionary = bench.current_level_definition.duplicate(true)
	var parts: Array[LogicComponent] = [
		_terminal(&"A_IN", Component.KIND_INPUT, &"A", 4),
		_terminal(&"B_IN", Component.KIND_INPUT, &"B", 4),
		_terminal(&"LOAD_IN", Component.KIND_INPUT, &"LOAD", 1),
		Component.new(&"REG", Component.KIND_REGISTER4, "Recovery register"),
		_terminal(&"Q_OUT", Component.KIND_OUTPUT, &"Q", 4),
	]
	definition["components"] = parts
	definition["debug_inputs"] = {&"A": 0, &"B": 0, &"LOAD": 0}
	definition["layout"] = {
		&"A_IN": Vector2(80, 80), &"B_IN": Vector2(80, 210),
		&"LOAD_IN": Vector2(80, 340), &"REG": Vector2(380, 160),
		&"Q_OUT": Vector2(700, 180),
	}
	definition["reference_wires"] = [
		{"from": &"A_IN", "to": &"REG", "from_port": 0, "to_port": 0},
		{"from": &"B_IN", "to": &"REG", "from_port": 0, "to_port": 0},
		{"from": &"LOAD_IN", "to": &"REG", "from_port": 0, "to_port": 1},
		{"from": &"REG", "to": &"Q_OUT", "from_port": 0, "to_port": 0},
	]
	bench.current_level_definition = definition
	bench._load_prologue_inventory(definition)
	bench._create_graph()
	bench._build_component_nodes()
	bench._load_reference_wires(definition)
	bench._build_prologue_side()
	bench.live_state_key = ""
	bench._schedule_live_refresh()
	bench._close_desktop_window(&"task")
	bench._close_desktop_window(&"components")
	bench._show_desktop_window(&"test_bench")
	# A long visual interval keeps the explicit Pause/Step observation stable;
	# the entire simulation still completes synchronously in the Debug callback.
	bench.clock_period_control.value = 0.5


func _reveal(control: Control, label: String) -> bool:
	if not check(is_instance_valid(control) and control.is_visible_in_tree(),
			"Visible control: " + label):
		return false
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			(ancestor as ScrollContainer).ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await settle()
	var point: Vector2 = control.get_global_rect().get_center()
	if not check(root.get_visible_rect().has_point(point), "On-screen control: " + label):
		return false
	ancestor = control.get_parent()
	while ancestor is Control:
		var parent_control := ancestor as Control
		if parent_control.clip_contents and not check(parent_control.get_global_rect().has_point(point),
				"Unclipped control: " + label):
			return false
		ancestor = ancestor.get_parent()
	return true


func _click(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event, true)
		await process_frame


func _press(button: BaseButton, label: String) -> bool:
	if not await _reveal(button, label):
		return false
	if not check(not button.disabled, "Enabled action: " + label):
		return false
	var activations: Array[int] = [0]
	var observer: Callable = func() -> void: activations[0] += 1
	button.pressed.connect(observer)
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
	else:
		await _click(button)
	# Keep the observer through the complete click and settling interval: a
	# one-shot listener would hide duplicate activations.
	await settle()
	if is_instance_valid(button) and button.pressed.is_connected(observer):
		button.pressed.disconnect(observer)
	return check(activations[0] == 1, "Exactly one activation: " + label)


func _key(code: Key, command: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		event.meta_pressed = command and OS.get_name() == "macOS"
		event.ctrl_pressed = command and OS.get_name() != "macOS"
		root.push_input(event, true)
		await process_frame


func _set_word(name: StringName, value: int) -> bool:
	var spin := bench.prologue_input_controls.get(name) as SpinBox
	if not check(spin != null, "Actual word input exists: " + String(name)):
		return false
	if not await _reveal(spin, String(name)):
		return false
	var analysis_before: int = bench.live_analysis_count
	if DisplayServer.get_name() == "headless":
		spin.value = value
	else:
		var field: LineEdit = spin.get_line_edit()
		await _click(field)
		if not check(field.has_focus(), "Word editor owns focus: " + String(name)):
			return false
		await _key(KEY_A, true)
		for character: String in str(value):
			var event := InputEventKey.new()
			event.unicode = character.unicode_at(0)
			event.pressed = true
			root.push_input(event, true)
			await process_frame
		await _key(KEY_ENTER)
	await settle()
	return check(int(spin.value) == value and int(bench._current_prologue_inputs().get(name, -1)) == value,
			"Visible word edit reaches host input: %s=%d" % [name, value]) \
		and check(bench.live_analysis_count > analysis_before,
			"Word edit invokes real live preview: " + String(name))


func _set_load(high: bool) -> bool:
	var toggle := bench.prologue_input_controls.get(&"LOAD") as CheckButton
	if not check(toggle != null and toggle.button_pressed != high, "LOAD has a real requested change"):
		return false
	if DisplayServer.get_name() == "headless":
		if not await _reveal(toggle, "LOAD"):
			return false
		toggle.button_pressed = high
		await settle()
	elif not await _press(toggle, "LOAD"):
		return false
	return check(toggle.button_pressed == high and int(bench._current_prologue_inputs()[&"LOAD"]) == int(high),
		"Visible LOAD edit reaches host input")


func _carry(values: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {}
	for key: Variant in values:
		var value: DigitalValue = values[key]
		snapshot[String(key)] = value.to_dictionary()
	return snapshot


func _result_snapshot(result: PrologueSimulationResult) -> Dictionary:
	# canonical_signature includes all value maps, runtime, events, errors and
	# settling fields; error_specs is the remaining authoritative result field.
	return {"canonical": result.canonical_signature(), "error_specs": result.error_specs.duplicate(true)}


func _playback_events() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for batch: Dictionary in bench.playback_batches:
		for event: PrologueEvent in batch.get("events", []):
			snapshot.append(event.to_dictionary())
	return snapshot


func _has_short(result: PrologueSimulationResult) -> bool:
	if result == null:
		return false
	for error: Dictionary in result.error_specs:
		if error.get("key", &"") == &"circuit.error.short_circuit":
			return true
	return false


func _register_value() -> int:
	return int(bench.prologue_runtime_state.get("registers", {}).get(&"REG", -1))


func _output(result: PrologueSimulationResult) -> int:
	var value: DigitalValue = result.observed_values.get(&"Q") if result != null else null
	return value.value if value != null and value.is_known() else -1


func _step_retains_result(label: String) -> bool:
	if bench.playback_running and not await _press(bench.pause_button, "Pause " + label):
		return false
	var result: PrologueSimulationResult = bench.prologue_live_result
	var frozen: Dictionary = _result_snapshot(result)
	var runtime: Dictionary = bench.prologue_runtime_state.duplicate(true)
	var carry: Dictionary = _carry(bench.prologue_prior_outputs)
	var events: Array[Dictionary] = _playback_events()
	var index: int = bench.playback_index
	var count: int = bench.playback_batches.size()
	if not check(count > 0 and not bench.playback_running, "Paused real trace exists: " + label):
		return false
	if not await _press(bench.trace_step_button, "Step " + label):
		return false
	check(bench.playback_index == (1 if index >= count else index + 1), "Step advances one existing batch: " + label)
	check(bench.prologue_runtime_state == runtime and _carry(bench.prologue_prior_outputs) == carry,
		"Step does not re-execute or reset storage: " + label)
	check(bench.prologue_live_result == result and _result_snapshot(result) == frozen
		and _playback_events() == events, "Step preserves complete authoritative observation: " + label)
	return true


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--hardware-recovery-capture" in OS.get_cmdline_user_args():
		return
	var directory: String = "res://.godot/hardware-recovery-captures/" + TranslationServer.get_locale()
	var error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if not check(error == OK, "Recovery capture directory opens"):
		return
	RenderingServer.force_draw(false)
	var image: Image = root.get_texture().get_image()
	check(image != null and image.save_png(directory.path_join(name + ".png")) == OK,
		"Recovery capture saved: " + name)


func run() -> void:
	var profile: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name", ""))
	if not check(profile.begins_with("VonNeumannBottleneckChecks/")
			and OS.get_user_data_dir().replace("\\", "/").ends_with(profile),
			"Host recovery runs only in an isolated verifier profile"):
		quit(1)
		return
	protected_files = _protected_files()
	game_signature = root.get_node("GlobalSave").game_player_content.canonical_signature()
	if not check(root.get_node("GameMode").set_mode(&"test"), "Test mode activates before host construction"):
		await finish()
		return
	root.get_node("TaskNavigation").pending = ""
	preload("res://src/lab/lab_features.gd").classic = true
	original_reduced_motion = bool(ProjectSettings.get_setting("game/reduced_motion", false))
	ProjectSettings.set_setting("game/reduced_motion", false)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	bench = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench)
	current_scene = bench
	await settle(10)
	bench._start_prologue_level(&"register", false)
	await settle()
	if not check(bench.current_level_id == &"register" and bench.current_phase == &"prologue"
			and bench.workbench_store.storage_path.is_empty()
			and bench.active_workbench_namespace == &"test",
			"Real register host uses temporary Test workbenches"):
		await finish()
		return
	var progress_before: String = bench.player_content.canonical_signature()
	var official_definition: String = JSON.stringify(bench.current_level_definition.get("official_steps", []))
	_install_diagnostic_board()
	await settle(10)
	check(bench._circuit_from_graph().wires.size() == 4 and bench.prologue_input_controls.size() == 3,
		"Diagnostic graph and visible controls are built by the actual host")
	check(bench.prologue_live_result != null and bench.prologue_live_result.is_valid()
		and bench.prologue_runtime_state.is_empty(), "Initial live preview does not commit storage")
	if not await _set_word(&"A", 3) or not await _set_word(&"B", 3) or not await _set_load(true):
		await finish()
		return
	check(bench.prologue_runtime_state.is_empty() and _output(bench.prologue_live_result) == 0,
		"Equal-driver preview leaves the register uncommitted")
	if not await _press(bench.bench_debug_button, "Debug write 3"):
		await finish()
		return
	if not check(bench.prologue_live_result.is_valid() and _register_value() == 3
			and _output(bench.prologue_live_result) == 3, "Debug commits and observes the actual value 3"):
		await finish()
		return
	var valid_carry: Dictionary = _carry(bench.prologue_prior_outputs)
	var valid_state: Dictionary = bench.prologue_runtime_state.duplicate(true)
	if not await _step_retains_result("valid write"):
		await finish()
		return
	if not await _set_word(&"A", 5) or not await _set_word(&"B", 6):
		await finish()
		return
	check(_has_short(bench.prologue_live_result) and _register_value() == 3,
		"Conflicting visible inputs produce a real live short without writing")
	if not await _press(bench.bench_debug_button, "Debug conflicting 5/6"):
		await finish()
		return
	var failed: PrologueSimulationResult = bench.prologue_live_result
	if not check(failed != null and not failed.is_valid() and _has_short(failed),
			"Debug keeps the electrical failure as a failed observation"):
		await finish()
		return
	var failed_snapshot: Dictionary = _result_snapshot(failed)
	var failed_events: Array[Dictionary] = _playback_events()
	check(failed.external_inputs[&"A"].value == 5 and failed.external_inputs[&"B"].value == 6,
		"Failed observation retains the actual conflicting stimulus")
	check(bench.prologue_runtime_state == valid_state and _carry(bench.prologue_prior_outputs) == valid_carry,
		"Failed Debug retains the last valid storage and continuation outputs")
	var retained_caption: String = bench._t(&"hardware.storage.component.register", [
		DigitalValue.known(4, 3).display_text()])
	check(bench.component_state_labels[&"REG"].text == retained_caption
		and bench.component_idle_state_text[&"REG"] == retained_caption,
		"Failed Debug replaces an interrupted old playback caption with its real incoming storage")
	check(not failed_events.is_empty() and not failed_events.any(
		func(event: Dictionary) -> bool: return event.kind == "state_transition"),
		"Failed pre-commit Debug retains events without a commit boundary")
	check(bench.debug_result_label.text.contains(bench._prologue_result_errors(failed))
		and bench.trace_caption_label.text.contains(bench._prologue_result_errors(failed)),
		"Debug and playback visibly report the real short")
	check(bench.player_content.canonical_signature() == progress_before and not bench.official_passed,
		"Failed Debug has not granted progression")
	await _capture("failed-conflicting-drivers")
	if not await _step_retains_result("failed observation"):
		await finish()
		return
	if not await _set_load(false) or not await _set_word(&"A", 0) or not await _set_word(&"B", 0):
		await finish()
		return
	var preview: PrologueSimulationResult = bench.prologue_live_result
	check(preview != null and preview.is_valid() and not _has_short(preview) and _output(preview) == 3,
		"Corrected visible inputs clear the live short and HOLD3 without reset")
	if preview == null:
		await finish()
		return
	check(bench.prologue_runtime_state == valid_state and _carry(bench.prologue_prior_outputs) == valid_carry,
		"Input correction and preview do not commit or erase retained state")
	check(not bench._events_have_state_transition(preview.events),
		"Recovered live preview has no fabricated storage boundary")
	check(not bench.diagnostics_label.text.contains(bench._prologue_result_errors(failed)),
		"Recovered live diagnostics clear the prior electrical error")
	check(_result_snapshot(failed) == failed_snapshot,
		"Correcting the controls does not rewrite retained failed evidence")
	if not await _step_retains_result("corrected live preview"):
		await finish()
		return
	check(bench.component_symbols[&"A_IN"].terminal_numeric_value == 0
		and bench.component_symbols[&"B_IN"].terminal_numeric_value == 0
		and bench.component_state_labels[&"REG"].text == retained_caption,
		"Preview's first completed source wave shows corrected inputs beside retained storage")
	await _capture("corrected-live-hold")
	if not await _press(bench.bench_debug_button, "Debug corrected HOLD"):
		await finish()
		return
	var recovered: PrologueSimulationResult = bench.prologue_live_result
	check(recovered != null and recovered.is_valid() and _register_value() == 3 and _output(recovered) == 3,
		"Corrected Debug succeeds with the same committed3 and no reset")
	check(bench.status_label.text == bench._t(&"hardware.status.debug_complete")
		and bench.debug_result_label.text == bench._t(&"hardware.prologue.debug.result", [
			bench._format_digital_values(recovered.observed_values)]),
		"Successful Debug replaces the failed status with actual output")
	check(_playback_events().any(func(event: Dictionary) -> bool: return event.kind == "state_transition"),
		"Recovered Debug records the real HOLD boundary")
	if not await _step_retains_result("recovered HOLD"):
		await finish()
		return
	check(_result_snapshot(failed) == failed_snapshot and _has_short(failed),
		"Later Debug and Step leave the complete earlier failure immutable")
	check(bench.player_content.canonical_signature() == progress_before
		and not bench.official_passed and bench.official_report.is_empty()
		and bench.prologue_report.is_empty() and not bench.official_sequence_active
		and bench.seal_button.disabled and not bench.level_completion_overlay.visible,
		"Debug, preview and Step grant no completion or reusable component")
	check(JSON.stringify(bench.level_catalog.definition(&"register", bench.component_library).get("official_steps", []))
		== official_definition, "Diagnostic board never mutates the registered official task")
	await _capture("recovered-debug-hold")
	await finish()


func finish() -> void:
	if is_instance_valid(bench):
		bench._stop_playback()
		bench.queue_free()
		await settle()
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == game_signature,
		"Game content state remains unchanged")
	check(_protected_files() == protected_files, "Game save and workbench bytes remain unchanged")
	ProjectSettings.set_setting("game/reduced_motion", original_reduced_motion)
	print(("PASS: " if failures.is_empty() else "FAIL: ")
		+ "hardware failure recovery %d checks / %d failures (%s, %s)"
		% [checks, failures.size(), TranslationServer.get_locale(),
			"headless callbacks" if DisplayServer.get_name() == "headless" else "viewport input"])
	quit(0 if failures.is_empty() else 1)
