extends SceneTree

const GlobalSaveType = preload("res://src/save/global_save.gd")
const PlayerContentStateType = preload("res://src/content/player_content_state.gd")
const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")
const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const PrologueLevelCatalogType = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
const CircuitWorkbenchStoreType = preload("res://src/hardware_foundations/circuit_workbench_store.gd")

var failures: Array[String] = []
var test_directory: String
var save_path: String
var workbench_path: String
var game_mode: Node
var system_chapter: Node
var locality_chapter: Node
var services: Array[Node] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	game_mode = root.get_node("GameMode")
	system_chapter = root.get_node("SystemChapter")
	locality_chapter = root.get_node("LocalityChapter")
	test_directory = "res://.godot/global_save_test_%d" % Time.get_ticks_usec()
	save_path = test_directory.path_join("savegame_v1.json")
	workbench_path = test_directory.path_join("hardware_workbenches_v1.json")
	game_mode.set_mode(&"game")
	_reset_chapters()
	_test_prologue_and_half_adder_resume()
	_test_branch_resume_and_fail_closed_provenance()
	_test_chapter_gates_and_notebook_resume()
	_test_dependency_invalidation_resume()
	_test_corrupt_and_unknown_schema()
	_test_new_game_and_mode_isolation()
	for service: Node in services:
		service.free()
	services.clear()
	_reset_chapters()
	game_mode.set_mode(&"game")
	_remove_tree(ProjectSettings.globalize_path(test_directory).replace("\\", "/"))
	if failures.is_empty():
		print("PASS: minimal global Save/Continue, provenance reconciliation, chapter gates, New Game, and mode isolation tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d global-save assertion(s) failed" % failures.size())
		quit(1)


func _test_prologue_and_half_adder_resume() -> void:
	_clear_fixture_files()
	var tutorial_player = _build_player([&"tutorial"])
	var writer = _service()
	writer.game_player_content = tutorial_player
	_assert(writer.save_game(true), "Tutorial progress must write a versioned global save.")
	var reader = _service()
	_assert(reader.load_game(), "A mid-prologue save must be resumable.")
	_assert(
		bool(reader.game_player_content.completed_levels.get(&"tutorial", false))
		and reader.continue_scene_path().ends_with("hardware_foundations.tscn"),
		"Continue must return a mid-prologue player to Hardware Foundations."
	)

	_clear_fixture_files()
	var half_player = _build_player([&"tutorial", &"half_adder"])
	writer = _service()
	writer.game_player_content = half_player
	_assert(writer.save_game(true), "A sealed HalfAdder must save.")
	reader = _service()
	_assert(reader.load_game(), "A sealed HalfAdder must restore from its matching workbench topology.")
	var restored_half = reader.game_player_content.component_library.get(&"HalfAdder")
	_assert(
		restored_half != null
		and restored_half.source_signature == half_player.component_library[&"HalfAdder"].source_signature
		and PrologueLevelCatalogType.new().is_unlocked(
			&"full_adder", reader.game_player_content.completed_levels
		),
		"HalfAdder restore must retain its exact source signature and unlock Full Adder."
	)


func _test_branch_resume_and_fail_closed_provenance() -> void:
	_clear_fixture_files()
	var arithmetic = _build_player([&"tutorial", &"half_adder", &"full_adder", &"alu"])
	var writer = _service()
	writer.game_player_content = arithmetic
	_assert(writer.save_game(true), "The arithmetic branch must save independently.")
	var reader = _service()
	_assert(reader.load_game(), "The arithmetic branch must restore independently.")
	var restored_alu4 = reader.game_player_content.component_library.get(&"ALU4")
	_assert(
		bool(reader.game_player_content.completed_levels.get(&"alu", false))
		and not bool(reader.game_player_content.completed_levels.get(&"latch", false))
		and restored_alu4 != null
		and restored_alu4.is_generated_wrapper()
		and restored_alu4.generated_from == [reader.game_player_content.component_library[&"ALU1"].source_signature],
		"Arithmetic restore must recreate ALU4 only from the reverified ALU1 signature. completed=%s library=%s warning=%s" % [reader.game_player_content.completed_levels, reader.game_player_content.component_library.keys(), reader.last_warning]
	)

	_clear_fixture_files()
	var storage = _build_player([&"tutorial", &"latch", &"register", &"ram"])
	writer = _service()
	writer.game_player_content = storage
	_assert(writer.save_game(true), "The storage branch must save independently.")
	reader = _service()
	_assert(reader.load_game(), "The storage branch must restore independently.")
	var restored_register4 = reader.game_player_content.component_library.get(&"Register4")
	_assert(
		bool(reader.game_player_content.completed_levels.get(&"ram", false))
		and not bool(reader.game_player_content.completed_levels.get(&"half_adder", false))
		and restored_register4 != null
		and restored_register4.generated_from == [reader.game_player_content.component_library[&"Register1"].source_signature],
		"Storage restore must remain independent and bind Register4 to reverified Register1 provenance. completed=%s library=%s warning=%s" % [reader.game_player_content.completed_levels, reader.game_player_content.component_library.keys(), reader.last_warning]
	)

	_clear_fixture_files()
	var complete = _build_complete_hardware_player()
	writer = _service()
	writer.game_player_content = complete
	_assert(writer.save_game(true), "A complete prologue must save before provenance reconciliation.")
	var store := CircuitWorkbenchStoreType.new(workbench_path)
	var half_snapshot: Dictionary = store.workbench_snapshot(&"game", &"half_adder", "default")
	var half_wires: Array = half_snapshot.get("wires", [])
	if not half_wires.is_empty():
		half_wires.pop_back()
	_assert(
		store.save_workbench(&"game", &"half_adder", "default", half_snapshot),
		"The mismatch fixture must replace only the saved HalfAdder topology."
	)
	reader = _service()
	_assert(reader.load_game(), "A provenance mismatch on one branch must not destroy unrelated valid progress.")
	_assert(
		not bool(reader.game_player_content.completed_levels.get(&"half_adder", false))
		and not bool(reader.game_player_content.completed_levels.get(&"full_adder", false))
		and not bool(reader.game_player_content.completed_levels.get(&"cpu", false))
		and bool(reader.game_player_content.completed_levels.get(&"ram", false))
		and not system_chapter.prologue_ready,
		"A missing source signature match must fail closed and invalidate only the dependent arithmetic/CPU/gate chain. completed=%s system_ready=%s warning=%s" % [reader.game_player_content.completed_levels, system_chapter.prologue_ready, reader.last_warning]
	)


func _test_chapter_gates_and_notebook_resume() -> void:
	_clear_fixture_files()
	var player = _build_complete_hardware_player()
	_reset_chapters()
	_assert(system_chapter.capture_prologue(player.component_library), "Verified CPU/RAM provenance must open Chapter 1.")
	for level_id: StringName in [&"assembly", &"cpu_speed", &"ram_wait", &"bus_width", &"bottleneck"]:
		system_chapter.mark_completed(level_id)
	for level_id: StringName in [&"distant_reads", &"nearby_storage", &"cache_failure", &"access_order"]:
		locality_chapter.mark_completed(level_id)
	system_chapter.game_receipts[&"assembly"] = ["transient-system-receipt"]
	locality_chapter.game_receipts[&"distant_reads"] = ["transient-locality-receipt"]
	var writer = _service()
	writer.game_player_content = player
	_assert(writer.save_game(true), "Chapter gates and concept unlocks must save.")
	var saved_document: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	_assert(
		saved_document is Dictionary
		and int((saved_document as Dictionary).get("schema_version", 0)) == 1
		and not _contains_key_recursive(saved_document, "receipts")
		and not _contains_key_recursive(saved_document, "trace")
		and not _contains_key_recursive(saved_document, "clipboard")
		and not _contains_key_recursive(saved_document, "history"),
		"The versioned global save must exclude receipts and transient editor/playback state."
	)
	_reset_chapters()
	var reader = _service()
	_assert(reader.load_game(), "A complete Chapter 1 and partial Chapter 2 save must restore.")
	_assert(
		bool(reader.game_player_content.completed_levels.get(&"cpu", false))
		and bool(reader.game_player_content.completed_levels.get(&"load_store", false))
		and reader.game_player_content.component_library.has(&"TinyComputer")
		and system_chapter.prologue_ready
		and bool(system_chapter.game_completed.get(&"bottleneck", false))
		and locality_chapter.chapter_unlocked()
		and bool(locality_chapter.game_completed.get(&"access_order", false))
		and locality_chapter.concept_unlocked(&"cpu_wait")
		and locality_chapter.concept_unlocked(&"cache")
		and locality_chapter.concept_unlocked(&"locality")
		and reader.continue_scene_path().ends_with("main.tscn"),
		"Continue must restore Chapter 1→2 gates and derive Notebook unlocks from sanitized completion. hardware=%s system=%s locality=%s ready=%s warning=%s" % [reader.game_player_content.completed_levels, system_chapter.game_completed, locality_chapter.game_completed, system_chapter.prologue_ready, reader.last_warning]
	)
	_assert(
		system_chapter.game_receipts.is_empty() and locality_chapter.game_receipts.is_empty(),
		"Large run receipts must not be persisted as authoritative continuation state."
	)


func _test_dependency_invalidation_resume() -> void:
	_clear_fixture_files()
	var player = _build_complete_hardware_player()
	_reset_chapters()
	system_chapter.capture_prologue(player.component_library)
	system_chapter.mark_completed(&"assembly")
	player.invalidate_dependents(&"half_adder", PrologueLevelCatalogType.new())
	system_chapter.invalidate_prologue()
	var writer = _service()
	writer.game_player_content = player
	_assert(writer.save_game(true), "Selective dependency invalidation must be persistable.")
	var reader = _service()
	_assert(reader.load_game(), "Unaffected work must remain resumable after dependency invalidation.")
	_assert(
		bool(reader.game_player_content.completed_levels.get(&"half_adder", false))
		and not bool(reader.game_player_content.completed_levels.get(&"full_adder", false))
		and bool(reader.game_player_content.completed_levels.get(&"ram", false))
		and not bool(reader.game_player_content.completed_levels.get(&"cpu", false))
		and not system_chapter.prologue_ready
		and system_chapter.game_completed.is_empty(),
		"Saved invalidation must remove only downstream reusable components and chapter progress. hardware=%s system=%s warning=%s" % [reader.game_player_content.completed_levels, system_chapter.game_completed, reader.last_warning]
	)


func _test_corrupt_and_unknown_schema() -> void:
	_clear_fixture_files()
	var writer = _service()
	writer.game_player_content = _build_player([&"tutorial"])
	_assert(writer.save_game(true), "The backup fixture must write its first valid save.")
	writer.game_player_content = _build_player([&"tutorial", &"half_adder"])
	_assert(writer.save_game(true), "Replacing a valid save must rotate one recovery backup.")
	var primary_path: String = ProjectSettings.globalize_path(save_path).replace("\\", "/")
	_assert(DirAccess.remove_absolute(primary_path) == OK, "The interrupted-replacement fixture must remove only the primary save.")
	var reader = _service()
	_assert(
		reader.load_game()
		and bool(reader.game_player_content.completed_levels.get(&"tutorial", false))
		and not bool(reader.game_player_content.completed_levels.get(&"half_adder", false))
		and "backup" in reader.last_warning,
		"A missing primary after interrupted replacement must recover the previous valid backup."
	)

	_clear_fixture_files()
	writer = _service()
	writer.game_player_content = _build_player([&"tutorial"])
	writer.save_game(true)
	writer.game_player_content = _build_player([&"tutorial", &"half_adder"])
	writer.save_game(true)
	_write_text(save_path, "{interrupted")
	reader = _service()
	_assert(
		reader.load_game()
		and bool(reader.game_player_content.completed_levels.get(&"tutorial", false))
		and not bool(reader.game_player_content.completed_levels.get(&"half_adder", false))
		and "backup" in reader.last_warning,
		"A corrupt primary save must recover the previous valid atomic-write backup."
	)

	_clear_fixture_files()
	_write_text(save_path, "{interrupted")
	reader = _service()
	_assert(
		not reader.load_game() and not reader.disk_write_allowed and not reader.has_resume_progress(),
		"A corrupt save without a valid backup must fail closed and refuse an automatic overwrite."
	)
	_clear_fixture_files()
	_write_text(save_path, JSON.stringify({"schema_version": 99, "game": {}}))
	reader = _service()
	_assert(
		not reader.load_game()
		and not reader.disk_write_allowed
		and "schema 99" in reader.last_error,
		"An unknown future schema must be rejected without guessing or rewriting it."
	)

	_clear_fixture_files()
	_write_text(save_path + ".bak", JSON.stringify({"schema_version": 99, "game": {}}))
	reader = _service()
	_assert(
		not reader.load_game()
		and not reader.disk_write_allowed
		and FileAccess.file_exists(save_path + ".bak"),
		"A future-schema backup without a primary must also be preserved and rejected."
	)


func _test_new_game_and_mode_isolation() -> void:
	_clear_fixture_files()
	var game_store := CircuitWorkbenchStoreType.new(workbench_path)
	var marker_snapshot: Dictionary = _snapshot(_half_adder_circuit())
	game_store.ensure_default(&"game", &"half_adder", marker_snapshot)
	game_store.ensure_default(&"test", &"half_adder", marker_snapshot)
	var telemetry_export: String = test_directory.path_join("exports/keep.json")
	_write_text(telemetry_export, "{\"anonymous\":true}")
	var writer = _service()
	writer.game_player_content = _build_player([&"tutorial"])
	_assert(writer.save_game(true), "New Game fixture must begin with a valid save.")
	var preserve_result: Dictionary = writer.start_new_game(false)
	var preserved_store := CircuitWorkbenchStoreType.new(workbench_path)
	_assert(
		bool(preserve_result.get("ok", false))
		and not FileAccess.file_exists(save_path)
		and not preserved_store.workbench_names(&"game", &"half_adder").is_empty()
		and FileAccess.file_exists(telemetry_export),
		"New Game must clear Game progression while preserving workbenches and telemetry exports by default."
	)

	writer.game_player_content = _build_player([&"tutorial"])
	writer.save_game(true)
	var clear_result: Dictionary = writer.start_new_game(true)
	var cleared_store := CircuitWorkbenchStoreType.new(workbench_path)
	_assert(
		bool(clear_result.get("ok", false))
		and cleared_store.workbench_names(&"game", &"half_adder").is_empty()
		and not cleared_store.workbench_names(&"test", &"half_adder").is_empty()
		and FileAccess.file_exists(telemetry_export),
		"Optional workbench clearing must affect only the Game namespace and never telemetry exports."
	)

	_clear_fixture_files()
	game_mode.set_mode(&"test")
	system_chapter.test_completed[&"bottleneck"] = true
	locality_chapter.test_completed[&"capstone"] = true
	writer = _service()
	writer.game_player_content = _build_player([&"tutorial"])
	_assert(writer.save_game(true), "Saving while Test Mode is active must serialize only the Game snapshot.")
	system_chapter.test_completed.clear()
	locality_chapter.test_completed.clear()
	game_mode.set_mode(&"game")
	var reader = _service()
	_assert(reader.load_game(), "Game progress saved during a Test session must still restore in Game Mode.")
	_assert(
		bool(reader.game_player_content.completed_levels.get(&"tutorial", false))
		and system_chapter.test_completed.is_empty()
		and locality_chapter.test_completed.is_empty(),
		"Test Mode progression must never be reconstructed from the global Game save."
	)


func _build_complete_hardware_player():
	return _build_player([
		&"tutorial", &"half_adder", &"full_adder", &"alu",
		&"latch", &"register", &"ram", &"cpu", &"load_store",
	])


func _build_player(requested_levels: Array[StringName]):
	var requested: Dictionary[StringName, bool] = {}
	for level_id: StringName in requested_levels:
		requested[level_id] = true
	var player = PlayerContentStateType.new()
	var catalog := PrologueLevelCatalogType.new()
	var store := CircuitWorkbenchStoreType.new(workbench_path)
	for level_id: StringName in catalog.level_ids():
		if not bool(requested.get(level_id, false)):
			continue
		if level_id in [&"tutorial", &"load_store"]:
			player.mark_completed(level_id)
			continue
		var circuit: LogicCircuit = (
			_half_adder_circuit()
			if level_id == &"half_adder"
			else catalog.reference_circuit(level_id, player.component_library)
		)
		_assert(circuit != null, "Fixture circuit for %s must exist." % level_id)
		if circuit == null:
			continue
		var generated_names: Dictionary[StringName, bool] = {}
		for recipe: Dictionary in catalog.generated_rewards(level_id):
			generated_names[StringName(recipe.get("name", &""))] = true
		var component_name: StringName = &""
		for reward_name: StringName in catalog.reward_names(level_id):
			if not generated_names.has(reward_name):
				component_name = reward_name
				break
		var behavior_kind: StringName = (
			LogicComponentType.KIND_HALF_ADDER
			if level_id == &"half_adder"
			else StringName(catalog.definition(level_id, player.component_library).get("seal_kind", &""))
		)
		store.ensure_default(&"game", level_id, _snapshot(circuit))
		player.install_reusable(
			level_id,
			ReusableComponentType.new(component_name, behavior_kind, level_id, circuit),
			catalog
		)
	return player


func _half_adder_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	for component: LogicComponent in [
		LogicComponentType.new(&"A_IN", LogicComponentType.KIND_INPUT, "A", &"A", true),
		LogicComponentType.new(&"B_IN", LogicComponentType.KIND_INPUT, "B", &"B", true),
		LogicComponentType.new(&"XOR_1", LogicComponentType.KIND_XOR, "xor"),
		LogicComponentType.new(&"AND_1", LogicComponentType.KIND_AND, "and"),
		LogicComponentType.new(&"SUM_OUT", LogicComponentType.KIND_OUTPUT, "SUM", &"SUM", true),
		LogicComponentType.new(&"CARRY_OUT", LogicComponentType.KIND_OUTPUT, "CARRY", &"CARRY", true),
	]:
		circuit.add_component(component)
	for wire: Array in [
		[&"A_IN", 0, &"XOR_1", 0], [&"B_IN", 0, &"XOR_1", 1],
		[&"A_IN", 0, &"AND_1", 0], [&"B_IN", 0, &"AND_1", 1],
		[&"XOR_1", 0, &"SUM_OUT", 0], [&"AND_1", 0, &"CARRY_OUT", 0],
	]:
		circuit.connect_ports(wire[0], wire[1], wire[2], wire[3])
	return circuit


func _snapshot(circuit: LogicCircuit) -> Dictionary:
	var components: Array[Dictionary] = []
	for component: LogicComponent in circuit.components.values():
		components.append(component.to_dictionary())
	var wires: Array[Dictionary] = []
	for wire: LogicWire in circuit.wires:
		wires.append(wire.to_dictionary())
	return {"schema_version": 1, "components": components, "layout": {}, "wires": wires}


func _service():
	var service = GlobalSaveType.new()
	service.configure_for_test(save_path, workbench_path)
	services.append(service)
	return service


func _reset_chapters() -> void:
	system_chapter.restore_game({}, {}, false)
	locality_chapter.restore_game({}, false)
	system_chapter.test_completed.clear()
	system_chapter.test_receipts.clear()
	locality_chapter.test_completed.clear()
	locality_chapter.test_receipts.clear()


func _clear_fixture_files() -> void:
	_reset_chapters()
	for path: String in [save_path, save_path + ".tmp", save_path + ".bak", workbench_path]:
		var absolute_path: String = ProjectSettings.globalize_path(path).replace("\\", "/")
		if FileAccess.file_exists(absolute_path):
			DirAccess.remove_absolute(absolute_path)


func _write_text(path: String, contents: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path).replace("\\", "/")
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		failures.append("Could not create fixture %s." % path)
		return
	file.store_string(contents)
	file.close()


func _contains_key_recursive(value: Variant, target: String) -> bool:
	if value is Dictionary:
		for key: Variant in value:
			if String(key) == target or _contains_key_recursive(value[key], target):
				return true
	elif value is Array:
		for entry: Variant in value:
			if _contains_key_recursive(entry, target):
				return true
	return false


func _remove_tree(absolute_path: String) -> void:
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var child: String = absolute_path.path_join(entry)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
