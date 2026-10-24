extends SceneTree
## Earn the ordinary campaign through its real controllers, then revisit the
## special HalfAdder seal path. Reference wires are construction inputs only:
## no completion, reusable reward, official verdict or chapter gate is injected.
## Playback is advanced as in test_hardware_prologue_ui; sealing uses its actual
## button and presentation timer. This is not native-input acceptance.
## No Chapter 1 tasks/receipts are earned here; this covers its gate and autosave,
## not runtime clearing of an already-populated Chapter 1 receipt store.

const SCENE_PATH = "res://src/hardware_foundations/hardware_foundations.tscn"
const Store = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const STORAGE_LEVELS: Array[StringName] = [&"latch", &"register", &"ram"]
const STORAGE_REWARDS: Array[StringName] = [&"SRLatch", &"Register1", &"Register4", &"RAM2x4"]
const DEPENDENT_LEVELS: Array[StringName] = [&"full_adder", &"alu", &"cpu", &"load_store"]
const DEPENDENT_REWARDS: Array[StringName] = [&"FullAdder", &"ALU1", &"ALU4", &"TinyComputer"]

var failures: Array[String] = []
var checks: int = 0
var main: Control
var save: Node
var system: Node
var navigation: Node


func _init() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)
	return value


func settle(frames: int = 4) -> void:
	for frame: int in frames:
		await process_frame


func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	ProjectSettings.set_setting("playtest/offline_tester", false)
	root.get_node("GameMode").set_mode(&"game")
	navigation = root.get_node("TaskNavigation")
	navigation.pending = ""
	navigation.from_tree = false
	save = root.get_node("GlobalSave")
	system = root.get_node("SystemChapter")
	var prefix: String = "user://half-adder-reseal-progression-%d" % Time.get_ticks_usec()
	save.configure_for_test(prefix + "-save.json", prefix + "-boards.json")
	# Missing isolated files reset domains normally, without granting any access.
	var had_progress: bool = save.load_game()
	if check(not had_progress and not save.loaded_save and save.last_error.is_empty()
			and save.last_warning.is_empty() and save.disk_write_allowed,
			"Fresh ordinary profile has no previous progression or recovery error"):
		await exercise_campaign()
	await close_workbench()
	print(("PASS: " if failures.is_empty() else "FAIL: ")
		+ "half-adder reseal progression %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func exercise_campaign() -> void:
	if not check(not root.get_node("GameMode").is_test_mode() and not navigation.offline_tester_enabled()
			and save.game_player_content.completed_levels.is_empty()
			and save.game_player_content.component_library.is_empty() and not system.prologue_ready,
			"Game starts empty, with no reference-library access or pre-earned chapter gate"):
		return
	await open_workbench()
	if not await earn_tutorial(): return
	if not await open_level(&"half_adder"): return
	if not connect_reference_wires(main._half_adder_reference_wires(), "HalfAdder construction"): return
	if not await verify_and_seal(&"half_adder", &"HalfAdder"): return
	var original_half_adder: String = main.component_library[&"HalfAdder"].source_signature
	for pair: Array in [
		[&"full_adder", &"FullAdder"], [&"alu", &"ALU1"],
		[&"latch", &"SRLatch"], [&"register", &"Register1"],
		[&"ram", &"RAM2x4"], [&"cpu", &"TinyComputer"],
	]:
		var level_id: StringName = pair[0]
		if not await open_level(level_id): return
		if not connect_reference_wires(main.current_level_definition.reference_wires, String(level_id)): return
		if not await verify_and_seal(level_id, pair[1]): return
	if not await open_level(&"load_store"): return
	if not check(main.current_level_definition.get("locked_topology", false)
			and main.graph.get_connection_list().size() == main.current_level_definition.reference_wires.size(),
			"LOAD/STORE uses its normal fixed topology and the genuinely sealed TinyComputer"):
		return
	if not await run_official(&"load_store"): return
	if not check(main.completed_levels.get(&"load_store", false)
			and main.current_phase == &"prologue_complete" and system.prologue_ready,
			"Actual LOAD/STORE official run completes the prologue and captures its earned chapter gate"):
		return
	# Chapter 1 CPU8 carries a lineage fingerprint, not TinyComputer's circuit
	# signature directly (docs/architecture/content-system.md). Compute that
	# exact contract independently from the actually earned three source rewards.
	var cpu_sources: Array[String] = []
	for reward: StringName in [&"TinyComputer", &"ALU4", &"Register4"]:
		if not check(main.component_library.has(reward) and main.component_library[reward].is_ready(),
				"Chapter CPU provenance includes the actually earned %s source" % reward):
			return
		cpu_sources.append(String(main.component_library[reward].source_signature))
	cpu_sources.sort()
	var expected_cpu_lineage: String = "|".join(cpu_sources).sha256_text()
	if not check(system.cpu_source_signature == expected_cpu_lineage
			and system.ram_source_signature == main.component_library[&"RAM2x4"].source_signature,
			"Chapter gate retains the exact TinyComputer/ALU4/Register4 lineage hash and player-owned RAM source"):
		return
	check_gate(true, "Earned LOAD/STORE")
	var storage_sources: Dictionary = storage_signatures()
	if not check(storage_sources.size() == STORAGE_REWARDS.size(), "All independent storage rewards were actually earned"):
		return
	var complete_player: String = save.game_player_content.canonical_signature()

	# Negative control: the special path must not erase progress for the same
	# already-verified source. Reopening restores the real saved player board.
	if not await open_level(&"half_adder"): return
	if not check(main._circuit_from_graph().canonical_signature() == original_half_adder,
			"Revisited HalfAdder restores the original sealed source before the negative control"):
		return
	if not await verify_and_seal(&"half_adder", &"HalfAdder"): return
	check(save.game_player_content.canonical_signature() == complete_player,
		"Unchanged HalfAdder reseal retains all earned hardware rewards and completions")
	check_gate(true, "Unchanged reseal")
	check_storage_preserved(storage_sources, "Unchanged reseal")
	check_automatic_save(true, "Unchanged reseal")
	var unchanged_gate: Dictionary = gate_snapshot()
	if not await reload_saved_state("Unchanged reseal", complete_player): return
	check(gate_snapshot() == unchanged_gate, "Unchanged reseal keeps the same chapter gate before and after disk reload")
	check_gate(true, "Unchanged reseal after reload")
	check_storage_preserved(storage_sources, "Unchanged reseal after reload")

	# Positive control: AND is commutative, so exchanging its A/B input pins is
	# legal and truth-table equivalent, but changes the canonical source topology.
	await open_workbench()
	if not await open_level(&"half_adder"): return
	if not check(main._circuit_from_graph().canonical_signature() == original_half_adder,
			"Disk-restored HalfAdder reopens the original ordinary campaign board"):
		return
	main._on_disconnection_request(&"A_IN", 0, &"AND_1_COPY_002", 0)
	main._on_disconnection_request(&"B_IN", 0, &"AND_1_COPY_002", 1)
	main._on_connection_request(&"A_IN", 0, &"AND_1_COPY_002", 1)
	main._on_connection_request(&"B_IN", 0, &"AND_1_COPY_002", 0)
	await settle()
	var changed_source: String = main._circuit_from_graph().canonical_signature()
	if not check(main.graph.is_node_connected(&"A_IN", 0, &"AND_1_COPY_002", 1)
			and main.graph.is_node_connected(&"B_IN", 0, &"AND_1_COPY_002", 0)
			and not main.graph.is_node_connected(&"A_IN", 0, &"AND_1_COPY_002", 0)
			and not main.graph.is_node_connected(&"B_IN", 0, &"AND_1_COPY_002", 1)
			and changed_source != original_half_adder,
			"Real connection controllers swap only the carry AND inputs and change source identity"):
		return
	check(not main.official_passed and main.component_library[&"HalfAdder"].source_signature == original_half_adder
		and save.game_player_content.canonical_signature() == complete_player,
		"An unverified edited draft neither installs a replacement reward nor clears earned progress")
	check_gate(true, "Edited draft before official verification and sealing")
	if not await verify_and_seal(&"half_adder", &"HalfAdder"): return
	if not check(main.component_library[&"HalfAdder"].source_signature == changed_source,
			"Equivalent HalfAdder passes all four cases and installs the new verified source"):
		return
	check_hardware_invalidated("Changed reseal")
	check_gate(false, "Changed reseal must immediately invalidate Chapter 1")
	check_storage_preserved(storage_sources, "Changed reseal")
	check_automatic_save(false, "Changed reseal")
	var changed_gate: Dictionary = gate_snapshot()
	var changed_player: String = save.game_player_content.canonical_signature()
	if not await reload_saved_state("Changed reseal", changed_player): return
	check(gate_snapshot() == changed_gate,
		"Changed reseal has identical chapter eligibility immediately and after disk reload")
	check_gate(false, "Changed reseal after reload")
	check_hardware_invalidated("Changed reseal after reload")
	check_storage_preserved(storage_sources, "Changed reseal after reload")
	check(save.game_player_content.component_library[&"HalfAdder"].source_signature == changed_source,
		"Disk reload revalidates and preserves the changed HalfAdder, not its obsolete source")


func open_workbench() -> void:
	main = load(SCENE_PATH).instantiate()
	root.add_child(main)
	await settle()
	# Script launches normally use an in-memory board. Use the matching real
	# isolated file so GlobalSave must reconstruct every earned source from disk.
	main.workbench_store = Store.new(save.workbench_storage_path)


func close_workbench() -> void:
	if is_instance_valid(main):
		main._stop_playback()
		main.queue_free()
		await settle()
	main = null


func open_level(level_id: StringName) -> bool:
	if not check(main.level_catalog.is_unlocked(level_id, main.completed_levels),
			"%s entrance is unlocked by actually earned prerequisites" % level_id):
		return false
	main._start_campaign_level(level_id, false)
	await settle(8)
	if main.operation_demo != null: main.operation_demo.stop()
	var expected_phase: StringName = &"tutorial" if level_id == &"tutorial" else &"half_adder" if level_id == &"half_adder" else &"prologue"
	return check(main.current_level_id == level_id and main.current_phase == expected_phase
		and main.player_content == save.game_player_content and main.active_workbench_namespace == &"game"
		and not main.hint_mode and not main.mission_briefing_active,
		"%s enters the main ordinary campaign controller, not a hint or test-mode substitute" % level_id)


func earn_tutorial() -> bool:
	if not await open_level(&"tutorial"): return false
	main._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	main.input_a_button.button_pressed = not main.input_a_button.button_pressed
	main.bench_debug_button.pressed.emit()
	if main.playback_running: main._finish_playback()
	await settle()
	if not check(main.tutorial_created_wire and main.tutorial_changed_input and main.tutorial_valid_run
			and not main.completed_levels.get(&"tutorial", false),
			"Real tutorial wires, input toggle and valid run leave removal/reconnection still required"):
		return false
	main._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not main.completed_levels.get(&"tutorial", false), "Four tutorial actions do not grant completion")
	main._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	return check(main.tutorial_created_wire and main.tutorial_changed_input and main.tutorial_valid_run
		and main.tutorial_removed_wire and main.tutorial_reconnected_wire
		and main.completed_levels.get(&"tutorial", false) and main.level_completion_overlay.visible
		and main.component_library.is_empty(),
		"All five actual tutorial actions earn only tutorial completion, without fabricated reusable rewards")


func connect_reference_wires(wires: Array, context: String) -> bool:
	if not check(not wires.is_empty() and main.graph.get_connection_list().is_empty(),
			context + ": a fresh unsolved board receives reference wires as input, not an earned solution"):
		return false
	for wire: Dictionary in wires:
		main._on_connection_request(
			StringName(wire.get("from", wire.get("from_node", ""))), int(wire.get("from_port", 0)),
			StringName(wire.get("to", wire.get("to_node", ""))), int(wire.get("to_port", 0)))
	return check(main.graph.get_connection_list().size() == wires.size(), context + ": editor accepts every construction wire")


func run_official(level_id: StringName) -> bool:
	main.official_button.pressed.emit()
	var frame_guard: int = 0
	# Only presentation playback is skipped. Each official case and the aggregate
	# verdict still execute the production simulation, exactly as the UI suite.
	while main.official_sequence_active and frame_guard < 512:
		if main.playback_running: main._finish_playback()
		await process_frame
		frame_guard += 1
	if not check(not main.official_sequence_active and main.official_passed,
			"%s actual official sequence reaches a passing aggregate verdict" % level_id):
		return false
	var report: Dictionary = main.official_report if level_id == &"half_adder" else main.prologue_report
	var cases: Array = report.get("cases", []) if level_id == &"half_adder" else report.get("steps", [])
	var expected_count: int = 4 if level_id == &"half_adder" else main.current_level_definition.official_steps.size()
	var all_cases_passed: bool = expected_count > 0 and cases.size() == expected_count
	for result: Dictionary in cases:
		all_cases_passed = all_cases_passed and bool(result.get("passed", false))
	return check(all_cases_passed and main.passing_topology_signature == main._circuit_from_graph().canonical_signature(),
		"%s all %d official cases pass and bind the exact displayed source" % [level_id, expected_count])


func verify_and_seal(level_id: StringName, reward: StringName) -> bool:
	var was_completed: bool = main.completed_levels.get(level_id, false)
	if not await run_official(level_id): return false
	if not check(bool(main.completed_levels.get(level_id, false)) == was_completed
			and main.level_completion_overlay.visible and not main.seal_button.disabled,
			"%s tests alone do not grant a new completion; the real Seal action is available" % level_id):
		return false
	var source: String = main._circuit_from_graph().canonical_signature()
	main.level_completion_overlay.primary_action_button.pressed.emit()
	if not check(main.sealing and (main.sealing_level_id.is_empty() if level_id == &"half_adder" else main.sealing_level_id == level_id),
			"%s primary Seal enters its %s production path" % [level_id, "special HalfAdder" if level_id == &"half_adder" else "generic prologue"]):
		return false
	var deadline: int = Time.get_ticks_msec() + 10000
	while main.sealing and Time.get_ticks_msec() < deadline:
		await process_frame
	var expected_phase: StringName = &"sealed" if level_id == &"half_adder" else &"prologue_complete"
	return check(not main.sealing and main.current_phase == expected_phase
		and main.completed_levels.get(level_id, false) and main.component_library.has(reward)
		and main.component_library[reward].source_signature == source,
		"%s actual timed encapsulation installs only its officially verified %s" % [level_id, reward])


func gate_snapshot() -> Dictionary:
	var unlocked: Variant = null
	for task: Dictionary in navigation.tasks():
		if task.key == "chapter_1/assembly":
			unlocked = task.unlocked
			break
	return {"prologue_ready": bool(system.prologue_ready), "assembly_unlocked": unlocked}


func check_gate(expected: bool, context: String) -> void:
	var gate: Dictionary = gate_snapshot()
	check(gate.prologue_ready == expected, context + ": SystemChapter.prologue_ready matches earned hardware validity")
	check(gate.assembly_unlocked is bool and gate.assembly_unlocked == expected,
		context + ": actual TaskNavigation Chapter 1 entrance matches earned hardware validity")


func storage_signatures() -> Dictionary:
	var signatures: Dictionary = {}
	for reward: StringName in STORAGE_REWARDS:
		if save.game_player_content.component_library.has(reward):
			signatures[reward] = save.game_player_content.component_library[reward].source_signature
	return signatures


func check_storage_preserved(expected: Dictionary, context: String) -> void:
	for level_id: StringName in STORAGE_LEVELS:
		check(save.game_player_content.completed_levels.get(level_id, false), context + ": independent %s completion remains earned" % level_id)
	check(storage_signatures() == expected, context + ": independent SRLatch/Register1/Register4/RAM2x4 source signatures are unchanged")


func check_hardware_invalidated(context: String) -> void:
	var player = save.game_player_content
	check(player.completed_levels.get(&"tutorial", false) and player.completed_levels.get(&"half_adder", false),
		context + ": actual tutorial and replacement HalfAdder remain earned")
	for level_id: StringName in DEPENDENT_LEVELS:
		check(not player.completed_levels.get(level_id, false), context + ": stale %s completion is invalidated" % level_id)
	for reward: StringName in DEPENDENT_REWARDS:
		check(not player.component_library.has(reward), context + ": stale dependent %s reward is removed" % reward)


func check_automatic_save(expected_ready: bool, context: String) -> void:
	# Read the actual primary save BEFORE reload_saved_state can manually save or
	# reload it. install_reusable first autosaves hardware; invalidate_prologue
	# must then autosave the matching closed chapter gate through its own signal.
	# This observer must never call save_game/load_game or repair in-memory state.
	var file: FileAccess = FileAccess.open(save.storage_path, FileAccess.READ)
	if not check(file != null, context + ": sealing automatically writes a readable primary save"):
		return
	var decoded: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not check(decoded is Dictionary and decoded.get("game") is Dictionary
			and decoded.game.get("hardware") is Dictionary and decoded.game.get("system") is Dictionary,
			context + ": automatic primary save contains real hardware and SystemChapter records"):
		return
	var hardware: Dictionary = decoded.game.hardware
	var chapter: Dictionary = decoded.game.system
	# Normalize only expected in-memory values to the actual JSON storage types;
	# retain and compare every field rather than ignoring signatures or rewards.
	var expected_hardware: Dictionary = JSON.parse_string(JSON.stringify(
		save.game_player_content.manifest_snapshot(), "", false, true))
	var expected_chapter: Dictionary = JSON.parse_string(JSON.stringify(
		system.game_snapshot(), "", false, true))
	check(hardware == expected_hardware,
		context + ": autosave exactly retains current hardware completions, rewards and source provenance")
	check(chapter == expected_chapter,
		context + ": autosave exactly matches the current SystemChapter record without a manual second save")
	var ready: Variant = chapter.get("prologue_ready")
	check(ready is bool and ready == expected_ready,
		context + ": automatic disk chapter gate has the expected same-source/changed-source eligibility")
	var expected_completed: Array[String] = ["half_adder", "latch", "ram", "register", "tutorial"]
	if expected_ready:
		for level_id: StringName in DEPENDENT_LEVELS:
			expected_completed.append(String(level_id))
	expected_completed.sort()
	check(hardware.get("completed_levels", []) == JSON.parse_string(JSON.stringify(expected_completed)),
		context + ": disk completion set preserves storage and contains exactly the valid arithmetic dependents")
	check(ready is bool and ready == ("load_store" in hardware.get("completed_levels", [])),
		context + ": automatic disk chapter gate and LOAD/STORE hardware validity agree")


func reload_saved_state(context: String, expected_player: String) -> bool:
	if not check(save.save_game() and FileAccess.file_exists(save.storage_path)
			and FileAccess.file_exists(save.workbench_storage_path),
			context + ": ordinary Game progression and its source workbenches exist on disk"):
		return false
	await close_workbench()
	var restored_progress: bool = save.load_game()
	if not check(restored_progress and save.loaded_save and save.disk_write_allowed
			and save.last_error.is_empty() and save.last_warning.is_empty(),
			context + ": ordinary save reloads with actual earned progress and no discarded-provenance warning: "
			+ save.last_error + " " + save.last_warning):
		return false
	return check(save.game_player_content.canonical_signature() == expected_player,
		context + ": disk reload revalidates every retained source and restores exact earned hardware state")
