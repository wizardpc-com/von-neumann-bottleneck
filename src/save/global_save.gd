extends Node

const PlayerContentStateType = preload("res://src/content/player_content_state.gd")
const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const HalfAdderTestBenchType = preload("res://src/circuit/half_adder_test_bench.gd")
const PrologueSimulatorType = preload("res://src/circuit/prologue_simulator.gd")
const PrologueLevelCatalogType = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
const CircuitWorkbenchStoreType = preload("res://src/hardware_foundations/circuit_workbench_store.gd")

const SCHEMA_VERSION: int = 1
const DEFAULT_STORAGE_PATH: String = "user://savegame_v1.json"
const DEFAULT_WORKBENCH_PATH: String = "user://hardware_workbenches_v1.json"
const GAME_NAMESPACE: StringName = &"game"
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"
const REUSABLE_KINDS: Array[StringName] = [
	LogicComponentType.KIND_HALF_ADDER,
	LogicComponentType.KIND_FULL_ADDER,
	LogicComponentType.KIND_ALU1,
	LogicComponentType.KIND_SR_LATCH,
	LogicComponentType.KIND_REGISTER1,
	LogicComponentType.KIND_REGISTER4,
	LogicComponentType.KIND_ALU4,
	LogicComponentType.KIND_RAM2X4,
	LogicComponentType.KIND_TINY_COMPUTER,
]

var storage_path: String = DEFAULT_STORAGE_PATH
var workbench_storage_path: String = DEFAULT_WORKBENCH_PATH
var game_player_content = PlayerContentStateType.new()
var last_error: String = ""
var last_warning: String = ""
var disk_write_allowed: bool = true
var loaded_save: bool = false
var _loaded_from_backup: bool = false
var _suspend_saves: bool = false
var _signals_bound: bool = false


func _ready() -> void:
	_bind_persistent_sources()
	var arguments: PackedStringArray = OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	if "--reset-local-test-state" in arguments:
		var reset_result: Dictionary = start_new_game(false)
		if bool(reset_result.get("ok", false)):
			print("Global Game save reset; telemetry exports remain untouched.")
		else:
			push_error("Global Game save reset failed: %s" % String(reset_result.get("error", "unknown error")))
	elif _is_automated_launch(arguments):
		disk_write_allowed = false
	else:
		load_game()


func _exit_tree() -> void:
	if not _suspend_saves:
		save_game()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		save_game()


func configure_for_test(p_storage_path: String, p_workbench_storage_path: String) -> void:
	storage_path = p_storage_path
	workbench_storage_path = p_workbench_storage_path
	last_error = ""
	last_warning = ""
	disk_write_allowed = true
	loaded_save = false
	_loaded_from_backup = false
	_suspend_saves = false
	_set_game_player_content(PlayerContentStateType.new())


func load_game() -> bool:
	_suspend_saves = true
	last_error = ""
	last_warning = ""
	disk_write_allowed = true
	loaded_save = false
	_loaded_from_backup = false
	_reset_game_domains()
	var result: Dictionary = _read_save(storage_path)
	var status: StringName = StringName(result.get("status", &"corrupt"))
	if status == &"unknown_schema":
		last_error = String(result.get("error", "Unsupported future save schema."))
		disk_write_allowed = false
		_suspend_saves = false
		return false
	if status in [&"missing", &"corrupt"]:
		var backup_result: Dictionary = _read_save(storage_path + BACKUP_SUFFIX)
		var backup_status: StringName = StringName(backup_result.get("status", &"corrupt"))
		if backup_status != &"ok":
			if status == &"missing":
				if backup_status != &"missing":
					last_error = String(backup_result.get("error", "Global save backup is corrupt."))
					disk_write_allowed = false
				_suspend_saves = false
				return false
			last_error = String(result.get("error", "Global save is corrupt."))
			disk_write_allowed = false
			_suspend_saves = false
			return false
		result = backup_result
		_loaded_from_backup = true
		last_warning = "Recovered the previous valid global save backup."
	_apply_save(result.get("data", {}) as Dictionary)
	loaded_save = true
	_suspend_saves = false
	return has_resume_progress()


func save_game(force: bool = false) -> bool:
	if storage_path.is_empty():
		return true
	if not disk_write_allowed:
		return false
	if not force and not has_resume_progress():
		var removal_errors: Array[String] = []
		for path: String in [storage_path, storage_path + TEMP_SUFFIX, storage_path + BACKUP_SUFFIX]:
			var remove_error: String = _remove_file(path)
			if not remove_error.is_empty():
				removal_errors.append(remove_error)
		last_error = ", ".join(removal_errors)
		loaded_save = false
		return removal_errors.is_empty()
	var success: bool = _write_save(_save_snapshot())
	if success:
		loaded_save = true
	return success


func has_resume_progress() -> bool:
	var system_chapter := _autoload(&"SystemChapter")
	var locality_chapter := _autoload(&"LocalityChapter")
	return (
		not game_player_content.completed_levels.is_empty()
		or (system_chapter != null and not system_chapter.game_completed.is_empty())
		or (locality_chapter != null and not locality_chapter.game_completed.is_empty())
	)


func continue_scene_path() -> String:
	if not has_resume_progress():
		return ""
	var system_chapter := _autoload(&"SystemChapter")
	if system_chapter != null and bool(system_chapter.game_completed.get(&"bottleneck", false)):
		return "res://src/ui/main.tscn"
	if system_chapter != null and system_chapter.prologue_ready:
		return "res://src/system_lab/system_lab.tscn"
	return "res://src/hardware_foundations/hardware_foundations.tscn"


func start_new_game(clear_game_workbenches: bool) -> Dictionary:
	_suspend_saves = true
	var removal_errors: Array[String] = []
	for path: String in [storage_path, storage_path + TEMP_SUFFIX, storage_path + BACKUP_SUFFIX]:
		var remove_error: String = _remove_file(path)
		if not remove_error.is_empty():
			removal_errors.append(remove_error)
	if not removal_errors.is_empty():
		last_error = ", ".join(removal_errors)
		_suspend_saves = false
		return {"ok": false, "workbenches_cleared": false, "error": last_error}
	var workbenches_cleared: bool = not clear_game_workbenches
	var workbench_error: String = ""
	if clear_game_workbenches:
		var store := CircuitWorkbenchStoreType.new(workbench_storage_path)
		workbenches_cleared = store.clear_namespace(GAME_NAMESPACE)
		workbench_error = store.last_error if not workbenches_cleared else ""
	_reset_game_domains()
	last_error = workbench_error
	last_warning = ""
	disk_write_allowed = true
	loaded_save = false
	_loaded_from_backup = false
	_suspend_saves = false
	return {
		"ok": workbench_error.is_empty(),
		"workbenches_cleared": workbenches_cleared,
		"error": workbench_error,
	}


func _save_snapshot() -> Dictionary:
	var system_chapter := _autoload(&"SystemChapter")
	var locality_chapter := _autoload(&"LocalityChapter")
	return {
		"schema_version": SCHEMA_VERSION,
		"saved_at_utc": Time.get_datetime_string_from_system(true),
		"game": {
			"hardware": game_player_content.manifest_snapshot(),
			"system": system_chapter.game_snapshot() if system_chapter != null else {},
			"locality": locality_chapter.game_snapshot() if locality_chapter != null else {},
		},
	}


func _apply_save(snapshot: Dictionary) -> void:
	var system_chapter := _autoload(&"SystemChapter")
	var locality_chapter := _autoload(&"LocalityChapter")
	var game_value: Variant = snapshot.get("game", {})
	var game: Dictionary = game_value if game_value is Dictionary else {}
	var hardware_value: Variant = game.get("hardware", {})
	var hardware: Dictionary = hardware_value if hardware_value is Dictionary else {}
	_set_game_player_content(_restore_hardware(hardware))
	var hardware_gate_ready: bool = bool(game_player_content.completed_levels.get(&"load_store", false))
	var system_value: Variant = game.get("system", {})
	var system: Dictionary = system_value if system_value is Dictionary else {}
	if system_chapter != null:
		system_chapter.restore_game(system, game_player_content.component_library, hardware_gate_ready)
	var locality_value: Variant = game.get("locality", {})
	var locality: Dictionary = locality_value if locality_value is Dictionary else {}
	if locality_chapter != null:
		locality_chapter.restore_game(
			locality,
			system_chapter != null and bool(system_chapter.game_completed.get(&"bottleneck", false))
		)


func _restore_hardware(manifest: Dictionary):
	var restored = PlayerContentStateType.new()
	if int(manifest.get("schema_version", 0)) != 1:
		return restored
	var requested: Dictionary[StringName, bool] = _level_set(manifest.get("completed_levels", []))
	var designs: Dictionary[StringName, Dictionary] = _design_index(manifest.get("designs", []))
	var catalog := PrologueLevelCatalogType.new()
	var store := CircuitWorkbenchStoreType.new(workbench_storage_path)
	var rejected: Array[String] = []
	for level_id: StringName in catalog.level_ids():
		if not bool(requested.get(level_id, false)):
			continue
		if not _dependencies_completed(level_id, restored.completed_levels, catalog):
			rejected.append(String(level_id))
			continue
		if level_id in [&"tutorial", &"load_store"]:
			restored.mark_completed(level_id)
			continue
		var reusable = _restore_reusable(level_id, designs, restored.component_library, catalog, store)
		if reusable == null:
			rejected.append(String(level_id))
			continue
		restored.install_reusable(level_id, reusable, catalog)
	if not rejected.is_empty():
		last_warning = "Ignored progression without current provenance: %s." % ", ".join(rejected)
	return restored


func _restore_reusable(
		level_id: StringName,
		designs: Dictionary[StringName, Dictionary],
		library: Dictionary,
		catalog,
		store
	):
	var generated_names: Dictionary[StringName, bool] = {}
	for recipe: Dictionary in catalog.generated_rewards(level_id):
		generated_names[StringName(recipe.get("name", &""))] = true
	var base_rewards: Array[StringName] = []
	for reward_name: StringName in catalog.reward_names(level_id):
		if not generated_names.has(reward_name):
			base_rewards.append(reward_name)
	if base_rewards.size() != 1:
		return null
	var component_name: StringName = base_rewards[0]
	var saved_design: Dictionary = designs.get(component_name, {})
	if (
		saved_design.is_empty()
		or StringName(saved_design.get("source_level", &"")) != level_id
		or String(saved_design.get("source_signature", "")).is_empty()
	):
		return null
	var definition: Dictionary = catalog.definition(level_id, library)
	var behavior_kind: StringName = (
		LogicComponentType.KIND_HALF_ADDER
		if level_id == &"half_adder"
		else StringName(definition.get("seal_kind", &""))
	)
	if (
		behavior_kind.is_empty()
		or StringName(saved_design.get("component_name", &"")) != component_name
		or StringName(saved_design.get("behavior_kind", &"")) != behavior_kind
	):
		return null
	var source_signature: String = String(saved_design.get("source_signature", ""))
	for workbench_name: String in store.workbench_names(GAME_NAMESPACE, level_id):
		var circuit: LogicCircuit = _circuit_from_workbench(
			store.workbench_snapshot(GAME_NAMESPACE, level_id, workbench_name)
		)
		if circuit == null or circuit.canonical_signature() != source_signature:
			continue
		if not _library_bindings_match(circuit, library):
			continue
		if not _official_passes(level_id, circuit, library, catalog):
			continue
		return ReusableComponentType.new(component_name, behavior_kind, level_id, circuit)
	return null


func _circuit_from_workbench(snapshot: Dictionary) -> LogicCircuit:
	if int(snapshot.get("schema_version", 0)) != 1:
		return null
	var circuit := LogicCircuitType.new()
	for component_value: Variant in snapshot.get("components", []):
		if not component_value is Dictionary:
			return null
		var component = LogicComponentType.from_dictionary(component_value)
		if component == null or not circuit.add_component(component):
			return null
	for wire_value: Variant in snapshot.get("wires", []):
		if not wire_value is Dictionary:
			return null
		var wire := wire_value as Dictionary
		var diagnostic: Dictionary = circuit.connect_ports_detailed(
			StringName(wire.get("from", wire.get("from_component", &""))),
			int(wire.get("from_port", 0)),
			StringName(wire.get("to", wire.get("to_component", &""))),
			int(wire.get("to_port", 0))
		)
		if not diagnostic.is_empty():
			return null
	return circuit


func _library_bindings_match(circuit: LogicCircuit, library: Dictionary) -> bool:
	for component: LogicComponent in circuit.components.values():
		if component.kind not in REUSABLE_KINDS:
			continue
		var library_name := StringName(component.properties.get("library_name", &""))
		var source_signature: String = String(component.properties.get("source_signature", ""))
		var definition = library.get(library_name)
		if (
			library_name.is_empty()
			or definition == null
			or definition.behavior_kind != component.kind
			or String(definition.source_signature) != source_signature
		):
			return false
	return true


func _official_passes(level_id: StringName, circuit: LogicCircuit, library: Dictionary, catalog) -> bool:
	if level_id == &"half_adder":
		return bool(HalfAdderTestBenchType.new().run_official(circuit).get("passed", false))
	var definition: Dictionary = catalog.definition(level_id, library)
	var steps: Array = definition.get("official_steps", [])
	if definition.is_empty() or steps.is_empty():
		return false
	return bool(PrologueSimulatorType.new().run_sequence(
		circuit, steps, bool(definition.get("allow_feedback", false))
	).get("passed", false))


func _dependencies_completed(level_id: StringName, completed: Dictionary, catalog) -> bool:
	for dependency: StringName in catalog.dependencies(level_id):
		if not bool(completed.get(dependency, false)):
			return false
	return true


func _design_index(source: Variant) -> Dictionary[StringName, Dictionary]:
	var result: Dictionary[StringName, Dictionary] = {}
	if source is Array:
		for design_value: Variant in source:
			if not design_value is Dictionary:
				continue
			var design := design_value as Dictionary
			var component_name := StringName(design.get("component_name", &""))
			if not component_name.is_empty() and not result.has(component_name):
				result[component_name] = design.duplicate(true)
	return result


func _level_set(source: Variant) -> Dictionary[StringName, bool]:
	var result: Dictionary[StringName, bool] = {}
	if source is Array:
		for level_id: Variant in source:
			result[StringName(level_id)] = true
	return result


func _reset_game_domains() -> void:
	_set_game_player_content(PlayerContentStateType.new())
	var system_chapter := _autoload(&"SystemChapter")
	var locality_chapter := _autoload(&"LocalityChapter")
	if system_chapter != null:
		system_chapter.restore_game({}, {}, false)
	if locality_chapter != null:
		locality_chapter.restore_game({}, false)


func _set_game_player_content(next_state) -> void:
	if _signals_bound and game_player_content != null:
		var old_callback := Callable(self, "_on_persistent_state_changed")
		if game_player_content.persistent_state_changed.is_connected(old_callback):
			game_player_content.persistent_state_changed.disconnect(old_callback)
	game_player_content = next_state
	if _signals_bound:
		var callback := Callable(self, "_on_persistent_state_changed")
		if not game_player_content.persistent_state_changed.is_connected(callback):
			game_player_content.persistent_state_changed.connect(callback)


func _bind_persistent_sources() -> void:
	_signals_bound = true
	_set_game_player_content(game_player_content)
	var callback := Callable(self, "_on_persistent_state_changed")
	var system_chapter := _autoload(&"SystemChapter")
	var locality_chapter := _autoload(&"LocalityChapter")
	if system_chapter != null and not system_chapter.persistent_state_changed.is_connected(callback):
		system_chapter.persistent_state_changed.connect(callback)
	if locality_chapter != null and not locality_chapter.persistent_state_changed.is_connected(callback):
		locality_chapter.persistent_state_changed.connect(callback)


func _on_persistent_state_changed() -> void:
	var game_mode := _autoload(&"GameMode")
	if _suspend_saves or (game_mode != null and game_mode.is_test_mode()):
		return
	save_game()


func _autoload(node_name: StringName) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(NodePath(String(node_name))) if tree != null else null


func _read_save(path: String) -> Dictionary:
	var absolute_path: String = _global_path(path)
	if not FileAccess.file_exists(absolute_path):
		return {"status": &"missing"}
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return {"status": &"corrupt", "error": "Could not open global save."}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"status": &"corrupt", "error": "Global save contains invalid JSON."}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {"status": &"corrupt", "error": "Global save is not a JSON object."}
	var snapshot := parsed as Dictionary
	var schema_version: int = int(snapshot.get("schema_version", 0))
	if schema_version != SCHEMA_VERSION:
		return {
			"status": &"unknown_schema",
			"error": "Unsupported global save schema %d." % schema_version,
		}
	if not snapshot.get("game", {}) is Dictionary:
		return {"status": &"corrupt", "error": "Global save has no Game object."}
	return {"status": &"ok", "data": snapshot.duplicate(true)}


func _write_save(snapshot: Dictionary) -> bool:
	var target: String = _global_path(storage_path)
	var temporary: String = target + TEMP_SUFFIX
	var backup: String = target + BACKUP_SUFFIX
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		last_error = "Could not create the global save directory."
		return false
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Could not create the temporary global save."
		return false
	file.store_string(JSON.stringify(snapshot, "\t", false, true))
	file.flush()
	file.close()
	if StringName(_read_save(temporary).get("status", &"corrupt")) != &"ok":
		last_error = "Temporary global save validation failed."
		_remove_file(temporary)
		return false
	if _loaded_from_backup:
		var corrupt_remove_error: String = _remove_file(target)
		if not corrupt_remove_error.is_empty():
			last_error = corrupt_remove_error
			return false
	elif FileAccess.file_exists(target):
		var stale_backup_error: String = _remove_file(backup)
		if not stale_backup_error.is_empty():
			last_error = stale_backup_error
			return false
		var backup_error: Error = DirAccess.rename_absolute(target, backup)
		if backup_error != OK:
			last_error = "Could not rotate the previous global save: %s" % error_string(backup_error)
			return false
	var replace_error: Error = DirAccess.rename_absolute(temporary, target)
	if replace_error != OK:
		if not FileAccess.file_exists(target) and FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, target)
		last_error = "Could not install the new global save: %s" % error_string(replace_error)
		return false
	last_error = ""
	_loaded_from_backup = false
	return true


func _remove_file(path: String) -> String:
	if path.is_empty():
		return ""
	var absolute_path: String = _global_path(path)
	if not FileAccess.file_exists(absolute_path):
		return ""
	var remove_error: Error = DirAccess.remove_absolute(absolute_path)
	return "" if remove_error == OK else "%s: %s" % [absolute_path, error_string(remove_error)]


func _global_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return ProjectSettings.globalize_path(path).replace("\\", "/")
	return path.replace("\\", "/")


func _is_automated_launch(arguments: PackedStringArray) -> bool:
	if "--script" in arguments or DisplayServer.get_name() == "headless":
		return true
	for argument: String in arguments:
		if argument.begins_with("--capture"):
			return true
	return false
