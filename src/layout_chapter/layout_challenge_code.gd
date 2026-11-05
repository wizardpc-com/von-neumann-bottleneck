extends RefCounted
## Portable recipes only. Every live target is measured by the local simulator.
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const PREFIX: String = "VNB4C1:"
const MAX_BYTES: int = 4096
const OBJECTIVES := ["cycles","traffic","space"]
const ENVELOPE_FIELDS := ["v","task","model","condition","objective","design"]
const DESIGN_FIELDS := ["recipe","strategy","copy_fields","batch"]

static func encode(task: String, design: Dictionary, objective: String) -> Dictionary:
	if task not in Catalog.IDS: return _failed("task")
	if objective not in OBJECTIVES: return _failed("objective")
	var candidates: Array[Dictionary] = [{"id":"challenge","title":"","design":design}]
	var row: Dictionary = Board.build_rows(task,candidates,objective)[0]
	if not row.eligible: return _failed("ineligible")
	var transported: Dictionary = _transport_design(task,row.design)
	var challenge: Dictionary = {
		"v":1,"task":task,"model":Simulator.MODEL_VERSION,
		"condition":Board.condition_id_for(task),"objective":objective,"design":transported
	}
	var code: String = PREFIX+_canonical(challenge)
	if code.to_utf8_buffer().size() > MAX_BYTES: return _failed("size")
	var internal: Dictionary = _internal_design(task,transported)
	row.design = internal.duplicate(true)
	return {"ok":true,"reason":"","code":code,"challenge":challenge,"row":row,
		"task":task,"design":internal}

static func decode(code: String) -> Dictionary:
	if code.to_utf8_buffer().size() > MAX_BYTES: return _failed("size")
	var cleaned: String = code.strip_edges()
	if not cleaned.begins_with(PREFIX):
		return _failed("version" if cleaned.begins_with("VNB4C") else "format")
	var payload: String = cleaned.substr(PREFIX.length())
	var parser := JSON.new()
	if parser.parse(payload) != OK or not parser.data is Dictionary: return _failed("format")
	var raw: Dictionary = parser.data
	if not _keys_exact(raw,ENVELOPE_FIELDS): return _failed("format")
	if not _integer(raw.v,1,1): return _failed("version")
	if not raw.task is String or raw.task not in Catalog.IDS: return _failed("task")
	if not raw.objective is String or raw.objective not in OBJECTIVES: return _failed("objective")
	if not raw.model is String or not _model_id(raw.model): return _failed("model")
	if not raw.condition is String or not _digest(raw.condition): return _failed("condition")
	var task: String = raw.task
	if task == "relocation":
		if not _keys_exact(raw.design,["orders"]) or not _keys_exact(raw.design.orders,["A","B"]): return _failed("recipe")
		for order: String in ["A","B"]:
			if not _strict_design(raw.design.orders[order],false): return _failed("recipe")
	elif not _strict_design(raw.design,task in ["fields","records","hot_cold"]):
		return _failed("recipe")
	var internal: Dictionary = _internal_design(task,raw.design)
	var challenge: Dictionary = {
		"v":1,"task":task,"model":raw.model,"condition":raw.condition,
		"objective":raw.objective,"design":_transport_design(task,internal)
	}
	# Canonical spelling rejects duplicate keys, ignored fields and silent defaults.
	if payload != _canonical(challenge): return _failed("format")
	return {"ok":true,"reason":"","code":PREFIX+payload,"challenge":challenge,
		"task":task,"design":internal}

static func inspect(code: String, expected_task: String = "") -> Dictionary:
	var result: Dictionary = decode(code)
	if not result.ok: return result
	if not expected_task.is_empty() and result.task != expected_task: return _rejected(result,"wrong_task")
	if result.challenge.model != Simulator.MODEL_VERSION: return _rejected(result,"model")
	if result.challenge.condition != Board.condition_id_for(result.task): return _rejected(result,"condition")
	var candidates: Array[Dictionary] = [{"id":"challenge","title":"","design":result.design}]
	var row: Dictionary = Board.build_rows(result.task,candidates,result.challenge.objective)[0]
	if not row.eligible: return _rejected(result,"ineligible")
	result["row"] = row
	return result

static func _strict_design(value: Variant, native_layout: bool) -> bool:
	if not _keys_exact(value,DESIGN_FIELDS): return false
	if not value.strategy is String or value.strategy not in ["direct","full","batch"]: return false
	if native_layout and value.strategy != "direct": return false
	if not _integer(value.batch,1,64): return false
	if not value.copy_fields is Array or value.copy_fields.size() > 4: return false
	if value.strategy != "direct" and value.copy_fields.is_empty(): return false
	var copied: Array[int] = []
	for field: Variant in value.copy_fields:
		if not _integer(field,0,3) or copied.has(int(field)): return false
		copied.append(int(field))
	if not _keys_exact(value.recipe,["groups","block"]): return false
	if not _integer(value.recipe.block,0,64): return false
	if not value.recipe.groups is Array or value.recipe.groups.is_empty() or value.recipe.groups.size() > 4: return false
	var seen: Array[int] = []
	for group: Variant in value.recipe.groups:
		if not _keys_exact(group,["fields","order"]): return false
		if not group.order is String or group.order not in ["record","field"]: return false
		if not group.fields is Array or group.fields.is_empty() or group.fields.size() > 4: return false
		for field: Variant in group.fields:
			if not _integer(field,0,3) or seen.has(int(field)): return false
			seen.append(int(field))
	return seen.size() == 4 and Simulator.validate_design(value,native_layout).is_empty()

static func _transport_design(task: String, internal: Dictionary) -> Dictionary:
	if task != "relocation": return Simulator.normalized_design(internal)
	var orders: Dictionary = {}
	for order: String in ["A","B"]:
		var chosen: Dictionary = internal.get("orders",{}).get(order,internal)
		orders[order] = Simulator.normalized_design(chosen)
	return {"orders":orders}

static func _internal_design(task: String, transported: Dictionary) -> Dictionary:
	if task != "relocation": return Simulator.normalized_design(transported)
	var result: Dictionary = Catalog.starter_design()
	result["orders"] = {}
	for order: String in ["A","B"]:
		result.orders[order] = Simulator.normalized_design(transported.orders[order])
	return result

static func _keys_exact(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size(): return false
	for key: Variant in value:
		if not key is String or key not in fields: return false
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum

static func _model_id(value: String) -> bool:
	if value.is_empty() or value.length() > 80: return false
	for index: int in value.length():
		var character: int = value.unicode_at(index)
		if character < 33 or character > 126: return false
	return true

static func _digest(value: String) -> bool:
	if value.length() != 64: return false
	for index: int in value.length():
		if value[index] not in "0123456789abcdef": return false
	return true

static func _canonical(value: Dictionary) -> String:
	return JSON.stringify(value,"",true)

static func _failed(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}

static func _rejected(decoded: Dictionary, reason: String) -> Dictionary:
	decoded["ok"] = false
	decoded["reason"] = reason
	return decoded
