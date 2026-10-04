extends SceneTree

const C = preload("res://src/circuit/logic_component.gd")
const DV = preload("res://src/circuit/digital_value.gd")
const Result = preload("res://src/circuit/prologue_simulation_result.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func register_text(main: Control, value: int, width: int = 4) -> String:
	return main._t(&"hardware.storage.component.register", [DV.known(width, value).display_text()])

func ram_text(main: Control, first: int, second: int) -> String:
	return main._t(&"hardware.storage.component.ram", [DV.known(4, first).display_text(), DV.known(4, second).display_text()])

func check_caption(main: Control, id: StringName, expected: String, context: String) -> void:
	check(main.component_idle_state_text.get(id) == expected, context + ": retained caption " + String(id))
	check(main.component_state_labels[id].text == expected, context + ": visible caption " + String(id))

func install(main: Control, level: StringName) -> void:
	main._start_prologue_level(level, false)
	if level == &"delay":
		main._apply_workbench_snapshot(main._build_hint_snapshot(3))
		main._create_graph()
		main._build_component_nodes()
		main._load_pending_workbench_wires()
	else:
		main._load_reference_wires(main.current_level_definition)
	main.current_circuit = main._circuit_from_graph()
	for frame: int in 3: await process_frame

func play(main: Control, inputs: Dictionary, runtime: Dictionary = {}, prior: Dictionary = {}) -> Dictionary:
	var steps: Array[Dictionary] = [{"inputs": inputs, "expected": {}}]
	var report: Dictionary = main.prologue_simulator.run_sequence(main.current_circuit, steps, false, runtime, prior)
	check(report.passed, "real simulation fixture passes")
	main.prologue_runtime_state = report.runtime_state.duplicate(true)
	main._play_prologue_events(report.events, report.final_result, report.initial_runtime_state, report.initial_prior_outputs)
	main.playback_running = false
	return report

func finish_batches(main: Control) -> void:
	for batch: Dictionary in main.playback_batches:
		main._show_playback_batch(batch, 0.5)
		main._show_playback_batch(batch, 1.0)
	main._finish_playback()

func exercise_ram(main: Control, context: String) -> void:
	await install(main, &"ram")
	var first: Dictionary = play(main, {&"ADDR": 0, &"DATA": 3, &"WRITE": 1})
	finish_batches(main)
	check_caption(main, &"REG_0", register_text(main, 3), context + " debug write")
	# Native reproduction: no reset button between debug and the official sequence.
	main._run_prologue_official()
	main.playback_running = false
	await process_frame
	check_caption(main, &"REG_0", register_text(main, 0), context + " official initial")
	check_caption(main, &"REG_1", register_text(main, 0), context + " official initial")
	check(main.storage_state_label.text.count("0x0") == 2, context + ": official monitor starts at zero")
	main._cancel_official_sequence()
	main._stop_playback()
	var report: Dictionary = play(main, {&"ADDR": 0, &"DATA": 5, &"WRITE": 1}, first.runtime_state, first.prior_outputs)
	var signature: String = report.final_result.canonical_signature()
	var prior_monitor: String = main.storage_state_label.text
	check_caption(main, &"REG_0", register_text(main, 3), context + " second write starts from three")
	finish_batches(main)
	check_caption(main, &"REG_0", register_text(main, 5), context + " second write committed")
	for attempt: int in 2:
		main._toggle_playback()
		main.playback_running = false
		check_caption(main, &"REG_0", register_text(main, 3), context + " replay " + str(attempt))
		check(main.storage_state_label.text == prior_monitor, context + ": replay restores immutable prior monitor")
		finish_batches(main)
		main._step_playback()
		check(main.component_idle_state_text[&"REG_0"] == register_text(main, 3), context + ": step restores prior caption")
		check(main.storage_state_label.text == prior_monitor, context + ": step restores prior monitor")
		finish_batches(main)
	check(report.final_result.canonical_signature() == signature, context + ": presentation preserves result identity")
	var preview: PrologueSimulationResult = main.prologue_simulator.evaluate(main.current_circuit, {&"ADDR": 0, &"DATA": 5, &"WRITE": 0}, report.prior_outputs, report.runtime_state)
	check(not main._events_have_state_transition(preview.events), context + ": preview has no state boundary")
	main._play_prologue_events(preview.events, preview)
	main.playback_running = false
	main._finish_playback()
	var preview_monitor: String = main.storage_state_label.text
	main._toggle_playback()
	main.playback_running = false
	check_caption(main, &"REG_0", register_text(main, 5), context + " preview replay")
	check(main.storage_state_label.text == preview_monitor, context + ": preview keeps current monitor")
	main._finish_playback()
	main._reset_storage_debug_state()
	check_caption(main, &"REG_0", register_text(main, 0), context + " explicit reset")
	main._step_playback()
	check_caption(main, &"REG_0", register_text(main, 0), context + " reset step cannot restore stale caption")

func exercise_cpu(main: Control, context: String) -> void:
	await install(main, &"cpu")
	var register_id: StringName
	var ram_id: StringName
	for id: StringName in main.component_catalog:
		if main.component_catalog[id].kind == C.KIND_REGISTER4: register_id = id
		if main.component_catalog[id].kind == C.KIND_RAM2X4: ram_id = id
	var initial: Dictionary = {"registers": {register_id: 6}, "ram": {ram_id: [9, 12]}}
	var report: Dictionary = play(main, {&"OP": 0, &"ARG": 3, &"ADDR": 1}, initial)
	check_caption(main, register_id, register_text(main, 6), context + " CPU initial ACC")
	check_caption(main, ram_id, ram_text(main, 9, 12), context + " CPU initial RAM")
	var signature: String = report.final_result.canonical_signature()
	finish_batches(main)
	check_caption(main, register_id, register_text(main, 3), context + " CPU committed ACC")
	main._toggle_playback()
	main.playback_running = false
	check_caption(main, register_id, register_text(main, 6), context + " CPU replay ACC")
	check_caption(main, ram_id, ram_text(main, 9, 12), context + " CPU replay RAM")
	finish_batches(main)
	main._step_playback()
	check(main.component_idle_state_text[register_id] == register_text(main, 6), context + ": CPU stepped prior ACC")
	finish_batches(main)
	check(report.final_result.canonical_signature() == signature, context + ": CPU evidence unchanged")
	main._run_prologue_official()
	main.playback_running = false
	await process_frame
	check_caption(main, register_id, register_text(main, 0), context + " CPU official reset ACC")
	check_caption(main, ram_id, ram_text(main, 0, 0), context + " CPU official reset RAM")
	main._cancel_official_sequence()
	main._stop_playback()

func exercise_register(main: Control, context: String) -> void:
	await install(main, &"register")
	var prior: Dictionary = {Result.output_key(&"LATCH", 0): DV.high(), Result.output_key(&"LATCH", 1): DV.low()}
	var report: Dictionary = play(main, {&"D": 0, &"LOAD": 1}, {}, prior)
	var before: String = main._t(&"hardware.storage.component.latch", ["1", "0"])
	var monitor: String = main.storage_state_label.text
	check_caption(main, &"LATCH", before, context + " register prior")
	finish_batches(main)
	main._step_playback()
	check(main.component_idle_state_text[&"LATCH"] == before, context + ": register step prior caption")
	check(main.storage_state_label.text == monitor, context + ": register step prior monitor")
	finish_batches(main)
	main._toggle_playback()
	main.playback_running = false
	check_caption(main, &"LATCH", before, context + " register replay")
	for values: Array in [[DV.high(), DV.high()], [DV.high_z(), DV.conflict()], [null, DV.low()]]:
		var exact: Dictionary = {}
		for port: int in 2:
			if values[port] != null: exact[Result.output_key(&"LATCH", port)] = values[port]
		main._play_prologue_events(report.events, report.final_result, {}, exact)
		main.playback_running = false
		check_caption(main, &"LATCH", main._t(&"hardware.storage.component.latch", [values[0].display_text() if values[0] != null else "—", values[1].display_text()]), context + " exact prior latch outputs")
	main._stop_playback()
	var stopped_caption: String = main.component_state_labels[&"LATCH"].text
	main._step_playback()
	check(main.component_state_labels[&"LATCH"].text == stopped_caption, context + ": stopped trace cannot restart earlier snapshots")

func exercise_delay(main: Control, context: String) -> void:
	await install(main, &"delay")
	var register_count: int = 0
	for component: LogicComponent in main.component_catalog.values():
		if component.kind == C.KIND_REGISTER4: register_count += 1
	check(register_count > 0, context + ": delay fixture contains real storage")
	var steps: Array = main.current_level_definition.official_steps
	var first: Dictionary = play(main, steps[1].inputs)
	finish_batches(main)
	var report: Dictionary = play(main, steps[2].inputs, first.runtime_state, first.prior_outputs)
	var before: String = main.storage_state_label.text
	var captions: Dictionary = main.component_idle_state_text.duplicate()
	finish_batches(main)
	check(main.storage_state_label.text != before, context + ": delay monitor changes at the real boundary")
	main._toggle_playback()
	main.playback_running = false
	check(main.storage_state_label.text == before, context + ": delay replay restores prior monitor")
	for id: StringName in main.component_catalog:
		if main.component_catalog[id].kind == C.KIND_REGISTER4:
			check_caption(main, id, captions[id], context + " delay replay")
	finish_batches(main)
	main._step_playback()
	check(main.storage_state_label.text == before, context + ": delay step restores prior monitor")
	for id: StringName in main.component_catalog:
		if main.component_catalog[id].kind == C.KIND_REGISTER4:
			check(main.component_idle_state_text[id] == captions[id], context + ": delay step restores prior caption")
	main._stop_playback()

func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var main: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(main)
	for frame: int in 4: await process_frame
	# Synthetic controller fixtures; native earned progression is verified separately.
	main._bootstrap_capture_library(true)
	for locale: String in ["en", "zh_CN"]:
		TranslationServer.set_locale(locale)
		await exercise_ram(main, locale)
		await exercise_cpu(main, locale)
		await exercise_register(main, locale)
		await exercise_delay(main, locale)
	main.queue_free()
	for frame: int in 4: await process_frame
	print("PASS: storage caption playback (%d checks)" % checks if failures.is_empty() else "FAIL: storage caption playback (%d/%d)" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
