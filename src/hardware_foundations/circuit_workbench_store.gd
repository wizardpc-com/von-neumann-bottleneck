class_name CircuitWorkbenchStore
extends RefCounted

const SCHEMA_VERSION: int = 2
const LEGACY_SCHEMA_VERSION: int = 1
const DEFAULT_NAME: String = "default"
const MAX_NAME_LENGTH: int = 32
const TEMP_SUFFIX: String = ".tmp"
const BACKUP_SUFFIX: String = ".bak"
const Migration = preload("res://src/save/stable_signature_migration.gd")

var storage_path: String = ""
var last_error: String = ""
var disk_write_allowed: bool = true
var migration_backup_path: String = ""
var _namespaces: Dictionary = {}


func _init(p_storage_path: String = "") -> void:
	storage_path = p_storage_path
	if not storage_path.is_empty():
		_load_from_disk()


func ensure_default(namespace_id: StringName, level_id: StringName, seed_snapshot: Dictionary) -> void:
	var entry: Dictionary = _level_entry(namespace_id, level_id, true)
	var workbenches: Dictionary = entry["workbenches"]
	var current_seed_fingerprint: String = seed_fingerprint(seed_snapshot)
	var legacy_seed: bool = int(entry.get("seed_signature_version", 0)) < Migration.VERSION
	if (
		not workbenches.has(DEFAULT_NAME)
		or String(entry.get("seed_fingerprint", "")) != current_seed_fingerprint
	):
		if not legacy_seed or not workbenches.has(DEFAULT_NAME):
			workbenches[DEFAULT_NAME] = seed_snapshot.duplicate(true)
		entry["seed_fingerprint"] = current_seed_fingerprint
	entry["seed_signature_version"] = Migration.VERSION
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
	var previous_namespaces: Dictionary = _namespaces.duplicate(true)
	var entry: Dictionary = _level_entry(namespace_id, level_id, true)
	var workbenches: Dictionary = entry["workbenches"]
	for existing_variant: Variant in workbenches:
		if String(existing_variant).to_lower() == name.to_lower():
			return &"duplicate"
	workbenches[name] = seed_snapshot.duplicate(true)
	entry["active"] = name
	if not _persist():
		# A failed creation must not leave a phantom active board in memory.
		_namespaces = previous_namespaces
		return &"write_failed"
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
	var previous_active: String = String(entry.get("active", DEFAULT_NAME))
	entry["active"] = workbench_name
	last_error = ""
	if not _persist():
		# The UI keeps its old selection on failure; the store must agree.
		entry["active"] = previous_active
		return false
	return true


func clear_namespace(namespace_id: StringName) -> bool:
	var namespace_key: String = String(namespace_id)
	if namespace_key.is_empty():
		last_error = "Cannot clear an empty workbench namespace."
		return false
	if not disk_write_allowed:
		return false
	_namespaces.erase(namespace_key)
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
				"seed_signature_version": int(source_entry.get("seed_signature_version", 0)),
				"workbenches": ordered_workbenches,
			}
		ordered_namespaces[namespace_key] = ordered_levels
	return {
		"schema_version": SCHEMA_VERSION,
		"signature_version": Migration.VERSION,
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
		if not _recover_missing_main(): return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		last_error = "Could not open workbench save for reading."
		disk_write_allowed = false
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	file = null
	if not parsed is Dictionary:
		last_error = "Workbench save is not a JSON object."
		disk_write_allowed = false
		return
	var manifest := parsed as Dictionary
	var signature_version: int = int(manifest.get("signature_version", 1))
	if signature_version not in [1, Migration.VERSION]:
		last_error = "Unsupported workbench signature version."
		disk_write_allowed = false
		return
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
	if signature_version == 1:
		var backup: Dictionary = Migration.preserve_file(storage_path)
		if not bool(backup.get("ok", false)):
			last_error = String(backup.get("error", "Legacy backup failed."))
			disk_write_allowed = false
			return
		migration_backup_path = String(backup.get("path", ""))
		var game: Dictionary = _namespaces.get("game", {})
		for level: Variant in game.values():
			if not level is Dictionary or not level.get("workbenches") is Dictionary:
				continue
			var workbenches: Dictionary = level["workbenches"]
			for workbench: Variant in workbenches:
				if workbenches[workbench] is Dictionary:
					workbenches[workbench] = Migration.normalize_workbench(workbenches[workbench])
		if not _persist():
			disk_write_allowed = false


func _recovery_candidate(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"status":"corrupt"}
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK: return {"status":"corrupt"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return {"status":"corrupt"}
	for pair: Array in [["schema_version",[LEGACY_SCHEMA_VERSION,SCHEMA_VERSION],0],["signature_version",[1,Migration.VERSION],1]]:
		var version: Variant = parsed.get(pair[0],pair[2])
		if not (version is int or version is float) or not is_finite(float(version)) or float(version) != floor(float(version)):
			return {"status":"corrupt"}
		# JSON represents integral numbers as floats; Array membership distinguishes
		# those from the supported integer constants even after integrality checks.
		if int(version) not in pair[1]: return {"status":"unknown"}
	if not parsed.get("namespaces") is Dictionary: return {"status":"corrupt"}
	for namespace_entries: Variant in parsed.namespaces.values():
		if not namespace_entries is Dictionary: return {"status":"corrupt"}
		for entry: Variant in namespace_entries.values():
			if not entry is Dictionary or not entry.get("active") is String or not entry.get("workbenches") is Dictionary:
				return {"status":"corrupt"}
			if not entry.workbenches.has(entry.active): return {"status":"corrupt"}
			for snapshot: Variant in entry.workbenches.values():
				if not snapshot is Dictionary or not snapshot.get("components") is Array or not snapshot.get("layout") is Dictionary or not snapshot.get("wires") is Array:
					return {"status":"corrupt"}
				for component: Variant in snapshot.components:
					if not component is Dictionary or not component.get("id") is String or not component.get("kind") is String:
						return {"status":"corrupt"}
					for key: String in ["input_port_names","output_port_names","input_port_widths","output_port_widths"]:
						if not component.get(key,[]) is Array: return {"status":"corrupt"}
					if not component.get("properties",{}) is Dictionary: return {"status":"corrupt"}
				for position: Variant in snapshot.layout.values():
					if not position is Dictionary: return {"status":"corrupt"}
				for wire: Variant in snapshot.wires:
					if not wire is Dictionary: return {"status":"corrupt"}
	return {"status":"ok","bytes":bytes}


func _recover_missing_main() -> bool:
	# A validated temporary precedes backup rotation, so it is the newer intended
	# snapshot. Never treat transaction leftovers as a first-use empty profile.
	var candidates: Array[String] = []
	for path: String in [storage_path+TEMP_SUFFIX,storage_path+BACKUP_SUFFIX]:
		if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path): candidates.append(path)
	if candidates.is_empty(): return false
	disk_write_allowed = false
	var selected: Dictionary = {}
	for path: String in candidates:
		var candidate: Dictionary = _recovery_candidate(path)
		if candidate.status == "unknown":
			last_error = "Unsupported workbench transaction version; original files preserved."
			return false
		if selected.is_empty() and candidate.status == "ok": selected = candidate
	if selected.is_empty():
		last_error = "No valid workbench transaction snapshot; original files preserved."
		return false
	for path: String in candidates:
		var preserved: Dictionary = Migration.preserve_file(path)
		if not preserved.ok:
			last_error = String(preserved.get("error","Could not preserve interrupted workbench files."))
			return false
	var bytes: PackedByteArray = selected.bytes
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	var hash: String = context.finish().hex_encode()
	var temporary: String = storage_path+".recover-"+hash+TEMP_SUFFIX
	if FileAccess.file_exists(temporary) or DirAccess.dir_exists_absolute(temporary):
		if FileAccess.get_sha256(temporary) != hash:
			last_error = "Workbenches recovery temporary differs; original files preserved."
			return false
	else:
		var file := FileAccess.open(temporary,FileAccess.WRITE)
		if file == null:
			last_error = "Could not create workbench recovery temporary."
			return false
		file.store_buffer(bytes); file.flush()
		var error: Error = file.get_error(); file.close()
		if error != OK:
			last_error = "Could not write workbench recovery temporary."
			return false
	if FileAccess.get_sha256(temporary) != hash or DirAccess.rename_absolute(temporary,storage_path) != OK:
		last_error = "Could not install verified workbench recovery snapshot."
		return false
	disk_write_allowed = true
	return true


func _persist() -> bool:
	if storage_path.is_empty():
		last_error = ""
		return true
	if not disk_write_allowed:
		if last_error.is_empty(): last_error = "Workbench save is read-only."
		return false
	var temporary: String = storage_path + TEMP_SUFFIX
	var backup: String = storage_path + BACKUP_SUFFIX
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Could not open workbench save for writing."
		return false
	file.store_string(JSON.stringify(manifest_snapshot(), "\t", false, true))
	file.flush()
	file.close()
	file = null
	var validation_file := FileAccess.open(temporary, FileAccess.READ)
	if validation_file == null:
		last_error = "Could not reopen temporary workbench save for validation."
		return false
	var parsed: Variant = JSON.parse_string(validation_file.get_as_text())
	validation_file.close()
	validation_file = null
	if not parsed is Dictionary:
		last_error = "Temporary workbench validation failed."
		return false
	if FileAccess.file_exists(backup):
		var stale_backup_error: Error = DirAccess.remove_absolute(backup)
		if stale_backup_error != OK:
			last_error = "Could not remove the previous workbench backup: %s" % error_string(stale_backup_error)
			return false
	if FileAccess.file_exists(storage_path):
		var backup_error: Error = DirAccess.rename_absolute(storage_path, backup)
		if backup_error != OK:
			last_error = "Could not rotate the previous workbench save: %s" % error_string(backup_error)
			return false
	var replace_error: Error = DirAccess.rename_absolute(temporary, storage_path)
	if replace_error != OK:
		if not FileAccess.file_exists(storage_path) and FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, storage_path)
		last_error = "Could not replace workbench save: %s" % error_string(replace_error)
		return false
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	last_error = ""
	return true
