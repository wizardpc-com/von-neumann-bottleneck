class_name ChapterWorkspace
extends RefCounted
## Work in progress, never an authority for task completion.
const MAX_SOURCE := 16000
const MAX_RECEIPTS := 32

static func encode(value: Variant, depth: int = 0) -> Variant:
	if depth > 8: return null
	if value is Vector2: return [value.x, value.y]
	if value is String or value is StringName: return String(value)
	if value is bool or value is int: return value
	if value is float: return (int(value) if value==floor(value) else value) if is_finite(value) else 0.0
	if value is Array:
		var result: Array = []
		for item: Variant in value.slice(0,256): result.append(encode(item,depth+1))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value.keys().slice(0,64): result[String(key).left(80)] = encode(value[key],depth+1)
		return result
	return null

static func bounded_workspaces(value: Variant, ids: Array) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary: return result
	for id: Variant in ids:
		var item: Variant=value.get(String(id),{})
		if not item is Dictionary or item.is_empty() or JSON.stringify(item).length()>100000: continue
		if item.has("part_ids") and not item.part_ids is Dictionary: continue
		if item.has("positions") and not item.positions is Dictionary: continue
		if item.has("connections") and not item.connections is Array: continue
		if not item.get("draft_source","") is String or not item.get("applied_source","") is String: continue
		result[String(id)]=encode(item)
	return result

static func fingerprint(paths: Array[String]) -> String:
	var key: String = paths[0]
	var packaged: Dictionary = ProjectSettings.get_setting("application/workspace_versions",{})
	if packaged.has(key): return packaged[key]
	var text: String = "workspace-v1"
	for path: String in paths: text += FileAccess.get_file_as_string(path).sha256_text()
	return text.sha256_text()
