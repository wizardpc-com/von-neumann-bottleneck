extends "res://tests/test_global_save.gd"

const Migration = preload("res://src/save/stable_signature_migration.gd")


func _run() -> void:
	game_mode = root.get_node("GameMode")
	system_chapter = root.get_node("SystemChapter")
	locality_chapter = root.get_node("LocalityChapter")
	game_mode.set_mode(&"game")
	var phase: String = ""
	test_directory = "res://.godot/signature_migration_%d" % Time.get_ticks_usec()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--migration-write="):
			phase = "write"
			test_directory = argument.trim_prefix("--migration-write=")
		elif argument.begins_with("--migration-read="):
			phase = "read"
			test_directory = argument.trim_prefix("--migration-read=")
	# Deliberately intern unrelated dynamic IDs before reconstructing saved IDs.
	for index: int in range(400):
		StringName("restart_%s_%04d" % [phase, 399 - index])
	save_path = test_directory.path_join("savegame_v1.json")
	workbench_path = test_directory.path_join("hardware_workbenches_v1.json")
	if phase == "write":
		_write_legacy_fixture()
	elif phase == "read":
		_verify_recovery()
	else:
		_write_legacy_fixture()
		_verify_recovery()
		_verify_recovery()
		_test_rejection_and_preservation()
		_test_interruption_and_backup_failure()
		_test_seed_adoption()
	for service: Node in services:
		service.free()
	services.clear()
	_reset_chapters()
	if phase.is_empty():
		_remove_tree(ProjectSettings.globalize_path(test_directory))
	if failures.is_empty():
		print("PASS: stable save signatures, legacy provenance, backup, restart and seed preservation (%s)" % phase)
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _write_legacy_fixture() -> void:
	_clear_fixture_files()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_directory))
	var player = _build_complete_hardware_player()
	_reset_chapters()
	system_chapter.capture_prologue(player.component_library)
	for level: StringName in [&"assembly", &"cpu_speed", &"ram_wait", &"bus_width", &"bottleneck"]:
		system_chapter.mark_completed(level)
	for level: StringName in [&"distant_reads", &"nearby_storage", &"cache_failure", &"access_order", &"working_set", &"blocking", &"capstone"]:
		locality_chapter.mark_completed(level)
	var writer = _service()
	writer.game_player_content = player
	_assert(writer.save_game(true), "Legacy fixture must first save a verified full dependency tree.")
	var global: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	global.erase("signature_version")
	var designs: Dictionary = {}
	for design: Dictionary in global["game"]["hardware"]["designs"]:
		design["source_signature"] = _legacy_signature(design["source_signature"])
		for index: int in range(design["generated_from"].size()):
			design["generated_from"][index] = _legacy_signature(design["generated_from"][index])
		designs[design["component_name"]] = design
	var cpu: Array[String] = []
	for name: String in ["TinyComputer", "ALU4", "Register4"]:
		cpu.append(designs[name]["source_signature"])
	cpu.sort()
	global["game"]["system"]["cpu_source_signature"] = "|".join(cpu).sha256_text()
	global["game"]["system"]["ram_source_signature"] = designs["RAM2x4"]["source_signature"]
	_write_text(save_path, JSON.stringify(global))
	var workbenches: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(workbench_path))
	workbenches.erase("signature_version")
	for entry: Dictionary in workbenches["namespaces"]["game"].values():
		entry.erase("seed_signature_version")
		entry["seed_fingerprint"] = "old-process-seed-hash"
		for snapshot: Dictionary in entry["workbenches"].values():
			for component: Dictionary in snapshot["components"]:
				if component["properties"].has("source_signature"):
					component["properties"]["source_signature"] = _legacy_signature(component["properties"]["source_signature"])
			snapshot["components"].reverse()
	var half: Dictionary = workbenches["namespaces"]["game"]["half_adder"]
	half["workbenches"]["default"]["layout"] = {"XOR_1": {"x": 432.5, "y": 117.25}}
	half["workbenches"]["default"]["wires"][0]["color_index"] = 3
	half["workbenches"]["My design"] = half["workbenches"]["default"].duplicate(true)
	half["active"] = "My design"
	workbenches["namespaces"]["test"] = {"sentinel": {"workbenches": {}, "unchanged": true}}
	_write_text(workbench_path, JSON.stringify(workbenches))
	_write_text(test_directory.path_join("legacy-global.json"), FileAccess.get_file_as_string(save_path))
	_write_text(test_directory.path_join("legacy-workbenches.json"), FileAccess.get_file_as_string(workbench_path))
	var digest_path: String = test_directory.path_join("stable-digest.txt")
	if FileAccess.file_exists(digest_path):
		DirAccess.remove_absolute(digest_path)


func _legacy_signature(source: String) -> String:
	var data: Dictionary = JSON.parse_string(source)
	if data.has("components"):
		for component: Dictionary in data["components"]:
			if component["properties"].has("source_signature"):
				component["properties"]["source_signature"] = _legacy_signature(component["properties"]["source_signature"])
		data["components"].reverse()
	elif data.has("generated_from"):
		for index: int in range(data["generated_from"].size()):
			data["generated_from"][index] = _legacy_signature(data["generated_from"][index])
	return JSON.stringify(data)


func _verify_recovery() -> void:
	var reader = _service()
	_assert(reader.load_game(), "Separate process must restore old full Game progress.")
	_assert(reader.game_player_content.completed_levels.size() == 9 and system_chapter.game_completed.size() == 5 and locality_chapter.game_completed.size() == 7, "All 21 verified completions and generated wrapper gates must survive migration/restart: %s" % reader.last_warning)
	_assert(reader.continue_scene_path().ends_with("main.tscn"), "Continue must reach the deepest verified chapter.")
	for filename: String in ["global", "workbenches"]:
		var original: String = test_directory.path_join("legacy-%s.json" % filename)
		var target: String = save_path if filename == "global" else workbench_path
		var backup: String = target + ".pre-stable-" + FileAccess.get_sha256(original) + ".bak"
		_assert(FileAccess.get_sha256(backup) == FileAccess.get_sha256(original), "Immutable %s backup must remain byte-exact across restarts." % filename)
	var store := CircuitWorkbenchStoreType.new(workbench_path)
	var saved: Dictionary = store.workbench_snapshot(&"game", &"half_adder", "default")
	_assert(saved["layout"]["XOR_1"]["x"] == 432.5 and int(saved["wires"][0]["color_index"]) == 3 and saved["wires"].size() == 6, "Migration must preserve layout, wire colors and all connections.")
	_assert(store.active_name(&"game", &"half_adder") == "My design" and store.workbench_names(&"game", &"half_adder").size() == 2, "Named workbench selection must survive.")
	_assert(store.manifest_snapshot()["namespaces"]["test"]["sentinel"]["workbenches"].is_empty(), "Test namespace must remain separate.")
	var signatures: Dictionary = {}
	for name: StringName in reader.game_player_content.component_library:
		signatures[String(name)] = reader.game_player_content.component_library[name].source_signature
	var digest: String = JSON.stringify(signatures).sha256_text()
	var digest_path: String = test_directory.path_join("stable-digest.txt")
	if FileAccess.file_exists(digest_path):
		_assert(FileAccess.get_file_as_string(digest_path) == digest, "Canonical signatures must be byte-identical in separate reader processes.")
	else:
		_write_text(digest_path, digest)
	_assert(reader.save_game(true), "Recovered current signatures must save normally.")


func _test_rejection_and_preservation() -> void:
	for problem: String in ["invalid", "different", "missing", "binding"]:
		_write_legacy_fixture()
		var global: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		var wb: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(workbench_path))
		var level: String = "full_adder" if problem == "binding" else "half_adder"
		var boards: Dictionary = wb["namespaces"]["game"][level]["workbenches"]
		if problem == "missing":
			boards.clear()
		else:
			for board: Dictionary in boards.values():
				if problem == "invalid":
					board["wires"].pop_back()
				elif problem == "different":
					board["components"][0]["display_name"] = "Different valid topology identity"
				else:
					for component: Dictionary in board["components"]:
						if component["properties"].has("source_signature"):
							component["properties"]["source_signature"] = "unverified source"
			if problem in ["invalid", "binding"]:
				var circuit: LogicCircuit = _service()._circuit_from_workbench(boards["default"])
				for design: Dictionary in global["game"]["hardware"]["designs"]:
					if design["source_level"] == level:
						design["source_signature"] = circuit.canonical_signature()
		_write_text(save_path, JSON.stringify(global))
		_write_text(workbench_path, JSON.stringify(wb))
		var old_hash: String = FileAccess.get_sha256(save_path)
		var reader = _service()
		reader.load_game()
		_assert(not reader.game_player_content.completed_levels.has(StringName(level)) and reader.game_player_content.completed_levels.has(&"ram") and not system_chapter.prologue_ready, "Reject %s evidence while preserving independent storage progress." % problem)
		_assert(reader.recovery_notice == &"save.recovery.partial" and FileAccess.get_sha256(save_path + ".pre-stable-" + old_hash + ".bak") == old_hash, "Rejected originals must remain intact with a player-facing partial-recovery notice.")


func _test_interruption_and_backup_failure() -> void:
	_write_legacy_fixture()
	CircuitWorkbenchStoreType.new(workbench_path)
	_verify_recovery() # Simulated interruption after workbench upgrade, before global upgrade.
	_write_legacy_fixture()
	var global_hash: String = FileAccess.get_sha256(save_path)
	var wb_hash: String = FileAccess.get_sha256(workbench_path)
	_write_text(save_path + ".pre-stable-" + global_hash + ".bak", "conflicting backup")
	var reader = _service()
	_assert(not reader.load_game() and not reader.disk_write_allowed and reader.recovery_notice == &"save.recovery.failed", "Backup mismatch must fail closed instead of overwriting either original.")
	_assert(FileAccess.get_sha256(save_path) == global_hash and FileAccess.get_sha256(workbench_path) == wb_hash, "Backup failure must leave both original files byte-identical.")
	DirAccess.remove_absolute(save_path + ".pre-stable-" + global_hash + ".bak")
	_write_legacy_fixture()
	var future: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	future["signature_version"] = 99
	_write_text(save_path, JSON.stringify(future))
	global_hash = FileAccess.get_sha256(save_path)
	reader = _service()
	_assert(not reader.load_game() and not reader.disk_write_allowed and FileAccess.get_sha256(save_path) == global_hash, "Unknown signature revisions must never be coerced or rewritten.")


func _test_seed_adoption() -> void:
	_write_legacy_fixture()
	var store := CircuitWorkbenchStoreType.new(workbench_path)
	var before: Dictionary = store.workbench_snapshot(&"game", &"half_adder", "default")
	var seed: Dictionary = _snapshot(_half_adder_circuit())
	seed["wires"] = []
	store.ensure_default(&"game", &"half_adder", seed)
	_assert(store.workbench_snapshot(&"game", &"half_adder", "default") == before, "First stable seed adoption must not replace an old player's wired default with an empty board.")
	var restarted := CircuitWorkbenchStoreType.new(workbench_path)
	restarted.ensure_default(&"game", &"half_adder", seed)
	_assert(restarted.workbench_snapshot(&"game", &"half_adder", "default") == before, "Subsequent unchanged seeds must preserve the same default.")
	seed["layout"] = {"A_IN": {"x": 900.0, "y": 40.0}}
	restarted.ensure_default(&"game", &"half_adder", seed)
	_assert(restarted.workbench_snapshot(&"game", &"half_adder", "default") == seed and restarted.workbench_snapshot(&"game", &"half_adder", "My design") == before, "A later genuine seed change must reset only default while retaining named designs.")
