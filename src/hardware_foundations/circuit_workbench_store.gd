class_name CircuitWorkbenchStore
extends RefCounted

const SCHEMA_VERSION: int = 2
const LEGACY_SCHEMA_VERSION: int = 1
const DEFAULT_NAME: String = "default"
const MAX_NAME_LENGTH: int = 32

var storage_path: String = ""
var last_error: String = ""
var disk_write_allowed: bool = true
var _namespaces: Dictionary = {}


func _init(p_storage_path: String = "") -> void:
	storage_path = p_storage_path
	if not storage_path.is_empty():
		_load_from_disk()


func ensure_default(namespace_id: StringName, level_id: StringName, seed_snapshot: Dictionary) -> void:
	var entry: Dictionary = _level_entry(namespace_id, level_id, true)
	var workbenches: Dictionary = entry["workbenches"]
	var current_seed_fingerprint: String = seed_fingerprint(seed_snapshot)
	if (
		not workbenches.has(DEFAULT_NAME)
		or String(entry.get("seed_fingerprint", "")) != current_seed_fingerprint
	):
		workbenches[DEFAULT_NAME] = seed_snapshot.duplicate(true)
		entry["seed_fingerprint"] = current_seed_fingerprint
	var active_name: String = String(entry.get("active", ""))
	if active_name.is_empty() or not workbenches.has(active_name):
		entry["active"] = DEFAULT_NAME
	_persist()


func workbench_names(namespace_id: StringName, level_id: StringName) -> Array[String]:
	var entry: Dictionary = _level_entry(namespace_id, level_id, false)
	var result: Array[String] = []
	for name_variant: Variant in (entry.get("workbenches", {}) as Dictionary):
		result.append(String(name_variant))
	result.sort()
	if DEFAULT_NAME in result:
		result.erase(DEFAULT_NAME)
		result.push_front(DEFAULT_NAME)
	return result


func active_name(namespace_id: StringName, level_id: StringName) -> String:
	var entry: Dictionary = _level_entry(namespace_id, level_id, false)
	return String(entry.get("active", ""))


func active_snapshot(namespace_id: StringName, level_id: StringName) -> Dictionary:
	var active: String = active_name(namespace_id, level_id)
	return workbench_snapshot(namespace_id, level_id, active)


func workbench_snapshot(
		namespace_id: StringName,
		level_id: StringName,
		workbench_name: String
	) -> Dictionary:
	var entry: Dictionary = _level_entry(namespace_id, level_id, false)
	var workbenches: Dictionary = entry.get("workbenches", {})
	var snapshot: Variant = workbenches.get(workbench_name)
	return (snapshot as Dictionary).duplicate(true) if snapshot is Dictionary else {}


func save_active(
		namespace_id: StringName,
		level_id: StringName,
		snapshot: Dictionary
	) -> bool:
	var name: String = active_name(namespace_id, level_id)
	if name.is_empty():
		last_error = "No active workbench exists."
		return false
	return save_workbench(namespace_id, level_id, name, snapshot)


func save_workbench(
		namespace_id: StringName,
		level_id: StringName,
		workbench_name: String,
		snapshot: Dictionary
	) -> bool:
	var entry: Dictionary = _level_entry(namespace_id, level_id, false)
	var workbenches: Dictionary = entry.get("workbenches", {})
	if not workbenches.has(workbench_name):
		last_error = "Unknown workbench: %s" % workbench_name
		return false
	workbenches[workbench_name] = snapshot.duplicate(true)
	last_error = ""
	return _persist()


func create_workbench(
		namespace_id: StringName,
		level_id: StringName,
		raw_name: String,
		seed_snapshot: Dictionary
	) -> StringName:
	var name: String = normalized_name(raw_name)
	var error: StringName = name_error(name)
	if not error.is_empty():
		return error
	var entry: Dictionary = _level_entry(namespace_id, level_id, true)
	var workbenches: Dictionary = entry["workbenches"]
	for existing_variant: Variant in workbenches:
		if String(existing_variant).to_lower() == name.to_lower():
			return &"duplicate"
	workbenches[name] = seed_snapshot.duplicate(true)
	entry["active"] = name
	_persist()
	return &""


func switch_workbench(
		namespace_id: StringName,
		level_id: StringName,
		workbench_name: String
	) -> bool:
	var entry: Dictionary = _level_entry(namespace_id, level_id, false)
	var workbenches: Dictionary = entry.get("workbenches", {})
	if not workbenches.has(workbench_name):
		last_error = "Unknown workbench: %s" % workbench_name
		return false
	entry["active"] = workbench_name
	last_error = ""
	return _persist()


func canonical_signature() -> String:
	return JSON.stringify(manifest_snapshot())


func manifest_snapshot() -> Dictionary:
	var ordered_namespaces: Dictionary = {}
	var namespace_ids: Array[String] = []
	for namespace_variant: Variant in _namespaces:
		namespace_ids.append(String(namespace_variant))
	namespace_ids.sort()
	for namespace_key: String in namespace_ids:
		var source_namespace: Dictionary = _namespaces[namespace_key]
		var ordered_levels: Dictionary = {}
		var level_ids: Array[String] = []
		for level_variant: Variant in source_namespace:
			level_ids.append(String(level_variant))
		level_ids.sort()
		for level_key: String in level_ids:
			var source_entry: Dictionary = source_namespace[level_key]
			var source_workbenches: Dictionary = source_entry.get("workbenches", {})
			var ordered_workbenches: Dictionary = {}
			var names: Array[String] = []
			for name_variant: Variant in source_workbenches:
				names.append(String(name_variant))
			names.sort()
			for name: String in names:
				ordered_workbenches[name] = (source_workbenches[name] as Dictionary).duplicate(true)
			ordered_levels[level_key] = {
				"active": String(source_entry.get("active", DEFAULT_NAME)),
				"seed_fingerprint": String(source_entry.get("seed_fingerprint", "")),
				"workbenches": ordered_workbenches,
			}
		ordered_namespaces[namespace_key] = ordered_levels
	return {
		"schema_version": SCHEMA_VERSION,
		"namespaces": ordered_namespaces,
	}


static func normalized_name(raw_name: String) -> String:
	return raw_name.strip_edges()


static func seed_fingerprint(seed_snapshot: Dictionary) -> String:
	return JSON.stringify(seed_snapshot).sha256_text()


static func name_error(name: String) -> StringName:
	if name.is_empty():
		return &"empty"
	if name.length() > MAX_NAME_LENGTH:
		return &"too_long"
	for character: String in ["\n", "\r", "\t"]:
		if character in name:
			return &"invalid_character"
	return &""


func _level_entry(
		namespace_id: StringName,
		level_id: StringName,
		create: bool
	) -> Dictionary:
	var namespace_key: String = String(namespace_id)
	var level_key: String = String(level_id)
	if namespace_key.is_empty() or level_key.is_empty():
		return {}
	if not _namespaces.has(namespace_key):
		if not create:
			return {}
		_namespaces[namespace_key] = {}
	var namespace_data: Dictionary = _namespaces[namespace_key]
	if not namespace_data.has(level_key):
		if not create:
			return {}
		namespace_data[level_key] = {
			"active": DEFAULT_NAME,
			"seed_fingerprint": "",
			"workbenches": {},
		}
	var entry: Variant = namespace_data[level_key]
	if not entry is Dictionary:
		if not create:
			return {}
		namespace_data[level_key] = {
			"active": DEFAULT_NAME,
			"seed_fingerprint": "",
			"workbenches": {},
		}
	if not (namespace_data[level_key] as Dictionary).get("workbenches", {}) is Dictionary:
		(namespace_data[level_key] as Dictionary)["workbenches"] = {}
	return namespace_data[level_key]


func _load_from_disk() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		last_error = "Could not open workbench save for reading."
		disk_write_allowed = false
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		last_error = "Workbench save is not a JSON object."
		disk_write_allowed = false
		return
	var manifest := parsed as Dictionary
	var schema_version: int = int(manifest.get("schema_version", 0))
	if schema_version not in [LEGACY_SCHEMA_VERSION, SCHEMA_VERSION]:
		last_error = "Unsupported workbench save schema."
		disk_write_allowed = false
		return
	var namespaces: Variant = manifest.get("namespaces", {})
	if not namespaces is Dictionary:
		last_error = "Workbench save has no namespaces object."
		disk_write_allowed = false
		return
	_namespaces = (namespaces as Dictionary).duplicate(true)
	last_error = ""


func _persist() -> bool:
	if storage_path.is_empty():
		last_error = ""
		return true
	if not disk_write_allowed:
		return false
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open workbench save for writing."
		return false
	file.store_string(JSON.stringify(manifest_snapshot(), "\t", false, true))
	file.flush()
	last_error = ""
	return true
