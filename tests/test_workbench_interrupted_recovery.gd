extends SceneTree
## Real Store transactions and truth-table-verified provenance, isolated from player files.
const Store = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
const Save = preload("res://src/save/global_save.gd")
const Player = preload("res://src/content/player_content_state.gd")
const Reusable = preload("res://src/circuit/reusable_component.gd")
const Catalog = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
const Component = preload("res://src/circuit/logic_component.gd")
const Circuit = preload("res://src/circuit/logic_circuit.gd")
const Bench = preload("res://src/circuit/half_adder_test_bench.gd")
var checks: int = 0
var failures: Array[String] = []
var directory: String
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func write(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Open isolated fixture "+path)
	if file == null: return
	file.store_string(raw); file.close()
func archive_matches(path: String, hash: String) -> bool:
	return FileAccess.get_sha256(path+".pre-stable-"+hash+".bak") == hash
func run() -> void:
	directory = "user://workbench-interrupted-"+Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(directory) == OK,"Open independent recovery fixture directory")
	root.get_node("GameMode").set_mode(&"game")
	var circuit: LogicCircuit = _half_adder_circuit()
	check(Bench.new().run_official(circuit).passed,"Prerequisite provenance passes all actual HalfAdder truth-table cases")
	var snapshot: Dictionary = _snapshot(circuit)
	var path: String = directory.path_join("boards.json")
	var store = Store.new(path)
	store.ensure_default(&"game",&"half_adder",snapshot)
	var old_bytes: String = FileAccess.get_file_as_string(path)
	check(store.create_workbench(&"game",&"half_adder","Named result",snapshot) == &"","Real Store persists a named completed topology")
	var new_bytes: String = FileAccess.get_file_as_string(path)
	var player = Player.new(); player.mark_completed(&"tutorial")
	player.install_reusable(&"half_adder",Reusable.new(&"HalfAdder",Component.KIND_HALF_ADDER,&"half_adder",circuit),Catalog.new())
	var global_path: String = directory.path_join("global.json")
	var writer = Save.new(); writer.configure_for_test(global_path,path); writer.game_player_content = player
	check(writer.save_game(true),"Persist global earned provenance before the interrupted workbench installation")
	# Replay the state between _persist's backup and install renames using its actual bytes.
	write(path+Store.TEMP_SUFFIX,new_bytes)
	check(DirAccess.rename_absolute(path,path+Store.BACKUP_SUFFIX) == OK,"Simulate the exact missing-main rename window")
	write(path+Store.BACKUP_SUFFIX,old_bytes)
	var old_hash: String = FileAccess.get_sha256(path+Store.BACKUP_SUFFIX)
	var new_hash: String = FileAccess.get_sha256(path+Store.TEMP_SUFFIX)
	var recovered = Store.new(path)
	check(recovered.disk_write_allowed and FileAccess.get_file_as_string(path) == new_bytes,"Reopening installs the newer validated temporary verbatim: "+recovered.last_error)
	check(recovered.active_name(&"game",&"half_adder") == "Named result" and recovered.workbench_names(&"game",&"half_adder").size() == 2,"Recovery retains named alternatives and actual active selection")
	check(archive_matches(path+Store.BACKUP_SUFFIX,old_hash) and archive_matches(path+Store.TEMP_SUFFIX,new_hash),"Both pre-install originals are archived byte-for-byte")
	var reader = Save.new(); reader.configure_for_test(global_path,path)
	check(reader.load_game(),"GlobalSave reopens against recovered workbench topology")
	var restored = reader.game_player_content.component_library.get(&"HalfAdder")
	check(restored != null and restored.source_signature == circuit.canonical_signature() and reader.game_player_content.completed_levels.get(&"half_adder",false),"Ordinary provenance revalidation preserves the verified reward and completion")
	writer.free(); reader.free()
	# Missing-main alternatives; no valid authoritative main is replaced by these cases.
	for scenario: String in ["backup-only","temporary-only","bad-temporary","all-bad","future-temporary","future-backup","legacy","archive-failure","recovery-temp-conflict","recovery-temp-reuse"]:
		var target: String = directory.path_join(scenario+".json")
		var backup: String = old_bytes
		var temporary: String = new_bytes
		if scenario in ["bad-temporary","all-bad"]: temporary = "{interrupted"
		if scenario == "all-bad": backup = "[broken"
		if scenario in ["future-temporary","future-backup"]:
			var future: Dictionary = JSON.parse_string(new_bytes); future.schema_version = 99
			if scenario == "future-temporary": temporary = JSON.stringify(future)
			else: backup = JSON.stringify(future)
		if scenario == "legacy":
			var legacy: Dictionary = JSON.parse_string(old_bytes); legacy.schema_version = 1; legacy.erase("signature_version")
			backup = JSON.stringify(legacy); temporary = "{interrupted"
		if scenario != "temporary-only": write(target+Store.BACKUP_SUFFIX,backup)
		if scenario != "backup-only": write(target+Store.TEMP_SUFFIX,temporary)
		var backup_hash: String = FileAccess.get_sha256(target+Store.BACKUP_SUFFIX) if scenario != "temporary-only" else ""
		var temporary_hash: String = FileAccess.get_sha256(target+Store.TEMP_SUFFIX) if scenario != "backup-only" else ""
		if scenario == "archive-failure":
			write(target+Store.TEMP_SUFFIX+".pre-stable-"+temporary_hash+".bak","conflicting archive")
		if scenario == "recovery-temp-conflict": write(target+".recover-"+temporary_hash+Store.TEMP_SUFFIX,"unknown recovery bytes")
		if scenario == "recovery-temp-reuse": write(target+".recover-"+temporary_hash+Store.TEMP_SUFFIX,temporary)
		var result = Store.new(target)
		var blocked: bool = scenario in ["all-bad","future-temporary","future-backup","archive-failure","recovery-temp-conflict"]
		check(result.disk_write_allowed != blocked,scenario+": recovery selects only safe supported candidates: "+result.last_error)
		if blocked:
			result.ensure_default(&"game",&"half_adder",snapshot)
			check(not FileAccess.file_exists(target),scenario+": automatic default cannot replace blocked transaction files")
		else:
			check(result.workbench_snapshot(&"game",&"half_adder","default") == JSON.parse_string(JSON.stringify(snapshot)),scenario+": complete topology is loaded")
			if not backup_hash.is_empty(): check(archive_matches(target+Store.BACKUP_SUFFIX,backup_hash),scenario+": backup original remains archived")
			if not temporary_hash.is_empty(): check(archive_matches(target+Store.TEMP_SUFFIX,temporary_hash),scenario+": temporary original remains archived")
		if scenario != "legacy":
			check((backup_hash.is_empty() or FileAccess.get_sha256(target+Store.BACKUP_SUFFIX) == backup_hash) and (temporary_hash.is_empty() or FileAccess.get_sha256(target+Store.TEMP_SUFFIX) == temporary_hash),scenario+": transaction source bytes remain unchanged")
		else:
			check(not result.migration_backup_path.is_empty(),"Legacy recovery additionally preserves pre-migration main bytes")
	var fresh = Store.new(directory.path_join("fresh.json"))
	fresh.ensure_default(&"game",&"half_adder",snapshot)
	check(fresh.disk_write_allowed and FileAccess.file_exists(fresh.storage_path),"All-missing first use still creates a normal new profile")
	var authoritative: String = directory.path_join("authoritative.json")
	write(authoritative,old_bytes); write(authoritative+Store.TEMP_SUFFIX,"{unknown residue")
	var stable = Store.new(authoritative)
	check(stable.disk_write_allowed and stable.active_name(&"game",&"half_adder") == "default" and FileAccess.get_file_as_string(authoritative) == old_bytes,"Existing valid main retains its original authority")
	print("PASS: workbench interrupted recovery %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)

func _half_adder_circuit() -> LogicCircuit:
	var circuit := Circuit.new()
	for component: LogicComponent in [
		Component.new(&"A_IN", Component.KIND_INPUT, "A", &"A", true),
		Component.new(&"B_IN", Component.KIND_INPUT, "B", &"B", true),
		Component.new(&"XOR_1", Component.KIND_XOR, "xor"),
		Component.new(&"AND_1", Component.KIND_AND, "and"),
		Component.new(&"SUM_OUT", Component.KIND_OUTPUT, "SUM", &"SUM", true),
		Component.new(&"CARRY_OUT", Component.KIND_OUTPUT, "CARRY", &"CARRY", true),
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
