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

func monitor_text(main: Control, q: String, nq: String) -> String:
	return main._t(&"hardware.storage.state.committed", [main._t(&"hardware.storage.state.latch", [q, nq])])

func install(main: Control, snapshot: Dictionary) -> void:
	main._apply_workbench_snapshot(snapshot)
	main._create_graph()
	main._build_component_nodes()
	main._load_pending_workbench_wires()

func renamed(snapshot: Dictionary) -> Dictionary:
	var copy: Dictionary = snapshot.duplicate(true)
	for item: Dictionary in copy.components:
		if String(item.id) == "NOR_Q": item.id = "PLAYER_UPPER"
		elif String(item.id) == "NOR_NQ": item.id = "PLAYER_LOWER"
	for wire: Dictionary in copy.wires:
		for key: String in ["from", "to"]:
			if String(wire[key]) == "NOR_Q": wire[key] = "PLAYER_UPPER"
			elif String(wire[key]) == "NOR_NQ": wire[key] = "PLAYER_LOWER"
	return copy

func exercise(main: Control, snapshot: Dictionary, context: String) -> void:
	install(main, snapshot)
	var circuit: LogicCircuit = main._circuit_from_graph()
	var prior: Dictionary = {}
	var runtime: Dictionary = {}
	var previous: Dictionary = {}
	var sequence: Array[Dictionary] = [
		{"inputs": {&"S": 1, &"R": 0}, "expected": {&"Q": 1, &"NQ": 0}},
		{"inputs": {&"S": 0, &"R": 0}, "expected": {&"Q": 1, &"NQ": 0}},
		{"inputs": {&"S": 0, &"R": 1}, "expected": {&"Q": 0, &"NQ": 1}},
		{"inputs": {&"S": 0, &"R": 0}, "expected": {&"Q": 0, &"NQ": 1}},
	]
	for index: int in sequence.size():
		var steps: Array[Dictionary] = [sequence[index]]
		var report: Dictionary = main.prologue_simulator.run_sequence(circuit, steps, true, runtime, prior)
		var result: PrologueSimulationResult = report.final_result
		check(report.passed, context + ": real SET/HOLD/RESET/HOLD step " + str(index))
		var signature: String = result.canonical_signature()
		main._play_prologue_events(report.events, result, report.initial_runtime_state, report.initial_prior_outputs)
		main.playback_running = false
		var before: String = main._t(&"hardware.storage.state.initial_latch") if previous.is_empty() else monitor_text(main, str(previous.Q), str(previous.NQ))
		var after: String = monitor_text(main, str(sequence[index].expected.Q), str(sequence[index].expected.NQ))
		check(main.storage_state_label.text == before, context + ": actual prior observation " + str(index))
		var boundary_seen: bool = false
		for batch: Dictionary in main.playback_batches:
			var boundary: bool = false
			for event: PrologueEvent in batch.events:
				boundary = boundary or event.kind == &"state_transition"
			main._show_playback_batch(batch, 0.5)
			check(main.storage_state_label.text == (after if boundary_seen else before), context + ": partial wave retains state")
			main._show_playback_batch(batch, 1.0)
			boundary_seen = boundary_seen or boundary
			check(main.storage_state_label.text == (after if boundary_seen else before), context + ": completed boundary shows correct Q/NQ")
		check(boundary_seen, context + ": actual state boundary exists")
		main._finish_playback()
		check(main.storage_state_label.text == after, context + ": final matches observation")
		main._toggle_playback()
		main.playback_running = false
		check(main.storage_state_label.text == before, context + ": replay restores prior")
		main._finish_playback()
		main._step_playback()
		check(main.storage_state_label.text == before, context + ": restarted step retains prior")
		main._finish_playback()
		check(result.canonical_signature() == signature, context + ": evidence unchanged")
		prior = report.prior_outputs
		runtime = report.runtime_state
		previous = sequence[index].expected

func exercise_edges(main: Control, original: Dictionary, locale: String) -> void:
	var changed: Dictionary = original.duplicate(true)
	changed.wires.append({"from": "S_IN", "from_port": 0, "to": "Q_OUT", "to_port": 0})
	install(main, changed)
	var prior: Dictionary = {Result.output_key(&"NOR_NQ", 0): DV.high(), Result.output_key(&"NOR_Q", 0): DV.high(), Result.output_key(&"S_IN", 0): DV.high()}
	main._prepare_storage_playback_state({}, prior)
	check(main.storage_state_label.text == monitor_text(main, "1", "1"), locale + ": matching drivers and non-complementary observations remain exact")
	prior[Result.output_key(&"S_IN", 0)] = DV.low()
	main._prepare_storage_playback_state({}, prior)
	check(main.storage_state_label.text == monitor_text(main, DV.conflict().display_text(), "1"), locale + ": conflicting drivers retain SHORT")
	prior.erase(Result.output_key(&"S_IN", 0))
	main._prepare_storage_playback_state({}, prior)
	check(main.storage_state_label.text == main._t(&"hardware.storage.state.initial_latch"), locale + ": partially missing prior driver is not invented")
	install(main, original)
	var circuit: LogicCircuit = main._circuit_from_graph()
	var before: Dictionary = {Result.output_key(&"NOR_NQ", 0): DV.low(), Result.output_key(&"NOR_Q", 0): DV.high()}
	var steps: Array[Dictionary] = [{"inputs": {&"S": 1, &"R": 0}, "expected": {&"Q": 1, &"NQ": 0}}]
	var report: Dictionary = main.prologue_simulator.run_sequence(circuit, steps, true, {}, before)
	main._play_prologue_events(report.events, report.final_result, {}, before)
	main._finish_playback()
	var preview: PrologueSimulationResult = main.prologue_simulator.evaluate(circuit, {&"S": 0, &"R": 0}, report.prior_outputs, {}, true)
	check(preview.is_valid() and not main._events_have_state_transition(preview.events), locale + ": live preview has no commit boundary")
	main._play_prologue_events(preview.events, preview)
	main._finish_playback()
	var preview_text: String = main.storage_state_label.text
	check(preview_text == monitor_text(main, "1", "0"), locale + ": preview fixture differs from the previous run's prior")
	main._toggle_playback()
	main.playback_running = false
	check(main.storage_state_label.text == preview_text, locale + ": preview replay does not resurrect old prior state")
	main._finish_playback()
	main._step_playback()
	check(main.storage_state_label.text == preview_text, locale + ": preview step does not resurrect old prior state")
	main._finish_playback()
	main._reset_storage_debug_state()
	check(main.storage_state_label.text == main._t(&"hardware.storage.state.cleared"), locale + ": explicit reset still clears temporal state")

func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var main: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(main)
	for frame: int in 4: await process_frame
	main._start_prologue_level(&"latch", false)
	for frame: int in 4: await process_frame
	var original: Dictionary = main._build_hint_snapshot(3)
	# Synthetic controller fixtures, separate from native earned play.
	for locale: String in ["en", "zh_CN"]:
		TranslationServer.set_locale(locale)
		exercise(main, original, locale + " authored")
		var changed: Dictionary = renamed(original)
		exercise(main, changed, locale + " renamed gates")
		changed.components.append(C.new(&"PLAYER_ROUTE", C.KIND_JUNCTION, "Route").to_dictionary())
		for wire: Dictionary in changed.wires:
			if String(wire.to) == "Q_OUT": wire.to = "PLAYER_ROUTE"
		changed.wires.append({"from": "PLAYER_ROUTE", "from_port": 0, "to": "Q_OUT", "to_port": 0})
		exercise(main, changed, locale + " routed output")
		var reusable: Dictionary = original.duplicate(true)
		reusable.components = reusable.components.filter(func(item: Dictionary) -> bool: return String(item.id) not in ["NOR_Q", "NOR_NQ"])
		reusable.components.append(C.new(&"PLAYER_MEMORY", C.KIND_SR_LATCH, "Memory").to_dictionary())
		reusable.wires = [
			{"from": "S_IN", "from_port": 0, "to": "PLAYER_MEMORY", "to_port": 0},
			{"from": "R_IN", "from_port": 0, "to": "PLAYER_MEMORY", "to_port": 1},
			{"from": "PLAYER_MEMORY", "from_port": 0, "to": "Q_OUT", "to_port": 0},
			{"from": "PLAYER_MEMORY", "from_port": 1, "to": "NQ_OUT", "to_port": 0},
		]
		exercise(main, reusable, locale + " nonzero output port")
		install(main, original)
		var unknown: Dictionary = {Result.output_key(&"NOR_NQ", 0): DV.high_z(), Result.output_key(&"NOR_Q", 0): DV.high()}
		main._prepare_storage_playback_state({}, unknown)
		check(main.storage_state_label.text == monitor_text(main, DV.high_z().display_text(), "1"), locale + ": unknown data preserved")
		main._prepare_storage_playback_state({}, {})
		check(main.storage_state_label.text == main._t(&"hardware.storage.state.initial_latch"), locale + ": absent evidence remains uninitialized")
		exercise_edges(main, original, locale)
	main.queue_free()
	for frame: int in 4: await process_frame
	print("PASS: latch playback readout (%d checks)" % checks if failures.is_empty() else "FAIL: latch playback readout (%d/%d)" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
