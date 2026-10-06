extends RefCounted
## Player-owned candidate plans, independent of rolling measured history.
const LIMIT := 24
const NAME_LIMIT := 48

static func valid_name(value: Variant) -> bool:
	if not value is String or value != value.strip_edges() or value.is_empty() or value.length() > NAME_LIMIT: return false
	for i: int in value.length():
		var code: int = value.unicode_at(i)
		if code < 32 or (code >= 127 and code <= 159): return false
	return true

static func index_of(designs: Array, record: Dictionary) -> int:
	for i: int in designs.size():
		if designs[i].task == record.task and designs[i].plan == record.plan: return i
	return -1

static func clean(value: Variant, validator: Callable, max_task: int) -> Dictionary:
	if not value is Array or value.size() > LIMIT: return {"ok":false,"error":"designs"}
	var result: Array[Dictionary] = []
	for entry: Variant in value:
		if not entry is Dictionary: return {"ok":false,"error":"design"}
		for key: Variant in entry:
			if key not in ["task","plan","name"]: return {"ok":false,"error":"schema"}
		if entry.size() != 3: return {"ok":false,"error":"design"}
		var task: Variant = entry.get("task")
		if not (task is int or task is float) or not is_finite(float(task)) or float(task) != floor(float(task)) or task < 0 or task > max_task: return {"ok":false,"error":"design_task"}
		if not valid_name(entry.get("name")): return {"ok":false,"error":"design_name"}
		var plan: Variant = validator.call(entry.get("plan"))
		if plan.is_empty(): return {"ok":false,"error":"design_plan"}
		var record: Dictionary = {"task":int(task),"plan":plan,"name":str(entry.name)}
		if index_of(result,record) >= 0: return {"ok":false,"error":"design_duplicate"}
		result.append(record)
	return {"ok":true,"designs":result}

static func remember(designs: Array[Dictionary], record: Dictionary, name: String) -> Dictionary:
	var trimmed: String = name.strip_edges()
	if not valid_name(trimmed): return {"ok":false,"error":"name"}
	if not record.has("task") or not record.has("plan"): return {"ok":false,"error":"record"}
	var index: int = index_of(designs,record)
	if index < 0 and designs.size() >= LIMIT: return {"ok":false,"error":"limit"}
	var result: Array[Dictionary] = []
	result.assign(designs.duplicate(true))
	var entry: Dictionary = {"task":int(record.task),"plan":record.plan.duplicate(true),"name":trimmed}
	if index < 0: result.append(entry)
	else: result[index] = entry
	return {"ok":true,"designs":result}
