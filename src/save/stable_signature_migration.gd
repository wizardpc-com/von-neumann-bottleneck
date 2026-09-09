class_name StableSignatureMigration
extends RefCounted

const VERSION: int = 2
const MAX_DEPTH: int = 16
const LogicComponentType = preload("res://src/circuit/logic_component.gd")


# Preserve every field and wire; only normalize the old process-dependent order
# and the same representation nested in reusable provenance. This is not a verifier.
static func normalize_signature(source: String, depth: int = 0) -> String:
	if source.is_empty() or depth >= MAX_DEPTH:
		return source
	var parser := JSON.new()
	if parser.parse(source) != OK:
		return source
	var value: Variant = parser.data
	if not value is Dictionary:
		return source
	var data: Dictionary = value
	if data.get("components") is Array and data.get("wires") is Array:
		var components: Array = data["components"]
		var seen: Dictionary = {}
		for entry: Variant in components:
			if not entry is Dictionary or not entry.get("id") is String:
				return source
			if String(entry["id"]).is_empty() or seen.has(entry["id"]):
				return source
			seen[entry["id"]] = true
			_normalize_binding(entry, depth + 1)
		components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	elif data.has("generated_component") and data.get("generated_from") is Array:
		var sources: Array = data["generated_from"]
		for index: int in range(sources.size()):
			if not sources[index] is String:
				return source
			sources[index] = normalize_signature(sources[index], depth + 1)
	else:
		return source
	return JSON.stringify(LogicComponentType.canonical_json_value(data))


static func normalize_workbench(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = snapshot.duplicate(true)
	if result.get("components") is Array:
		for component: Variant in result["components"]:
			if component is Dictionary:
				_normalize_binding(component, 0)
	return result


static func _normalize_binding(component: Dictionary, depth: int) -> void:
	var properties: Variant = component.get("properties")
	if properties is Dictionary and properties.get("source_signature") is String:
		properties["source_signature"] = normalize_signature(properties["source_signature"], depth)


# The content hash makes backups immutable across repeated/interrupted migrations.
# Verify existing contents instead of overwriting a previous recovery file.
static func preserve_file(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"ok": true, "path": ""}
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null:
		return {"ok": false, "error": "Could not read legacy file for backup: %s" % path}
	var bytes: PackedByteArray = source.get_buffer(source.get_length())
	source.close()
	var hash: String = FileAccess.get_sha256(path)
	if hash.is_empty():
		return {"ok": false, "error": "Could not hash legacy file: %s" % path}
	var backup: String = path + ".pre-stable-" + hash + ".bak"
	if not FileAccess.file_exists(backup):
		var output := FileAccess.open(backup, FileAccess.WRITE)
		if output == null:
			return {"ok": false, "error": "Could not create legacy backup: %s" % backup}
		output.store_buffer(bytes)
		output.flush()
		output.close()
	if FileAccess.get_sha256(backup) != hash:
		return {"ok": false, "error": "Legacy backup does not match original: %s" % backup}
	return {"ok": true, "path": backup}
