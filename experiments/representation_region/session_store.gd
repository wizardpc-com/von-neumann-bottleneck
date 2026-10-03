extends RefCounted
## Candidate-only storage. Persist decisions; recompute evidence on restore.
const Model = preload("res://experiments/representation_region/model.gd")
const Catalog = preload("res://experiments/representation_region/catalog.gd")
const Base = preload("res://experiments/representation/plan_model.gd")
const PATH := "user://representation-session.json"
const MAX_BYTES := 262144

static func contract_id() -> String:
	var specs: Array = []
	for i: int in 5: specs.append([Catalog.orders(i), Catalog.goals(i)])
	return JSON.stringify(specs).sha256_text()

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func clean_plan(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array or value.is_empty() or value.size() > 8: return result
	for block: Variant in value:
		if not block is Dictionary or block.size() != 3: return []
		if not integer(block.get("start"),0,63) or not integer(block.get("end"),1,64): return []
		if block.get("codec") not in ["raw","rle"]: return []
		result.append({"start":int(block.start),"end":int(block.end),"codec":str(block.codec)})
	if not Base.validate(result,Model.asset()).is_empty(): return []
	return result

static func decode(raw: String) -> Dictionary:
	if raw.to_utf8_buffer().size() > MAX_BYTES: return {"ok":false,"error":"size"}
	var parser := JSON.new()
	if parser.parse(raw) != OK: return {"ok":false,"error":"json"}
	var data: Variant = parser.data
	if not data is Dictionary or data.size() != 6: return {"ok":false,"error":"schema"}
	if not integer(data.get("schema"),1,1) or not data.get("model") is String or not data.get("contracts") is String:
		return {"ok":false,"error":"version"}
	if data.model != Model.VERSION or data.contracts != contract_id():
		return {"ok":false,"error":"version"}
	if not integer(data.get("task"),0,4) or not data.get("drafts") is Array or data.drafts.size() != 5:
		return {"ok":false,"error":"drafts"}
	if not data.get("runs") is Array or data.runs.size() > 100: return {"ok":false,"error":"runs"}
	var drafts: Array = []
	for value: Variant in data.drafts:
		var plan := clean_plan(value)
		if plan.is_empty(): return {"ok":false,"error":"plan"}
		drafts.append(plan)
	var runs: Array = []
	for run: Variant in data.runs:
		if not run is Dictionary or run.size() != 2 or not integer(run.get("task"),0,4): return {"ok":false,"error":"run"}
		var plan := clean_plan(run.get("plan"))
		if plan.is_empty(): return {"ok":false,"error":"run_plan"}
		runs.append({"task":int(run.task),"plan":plan})
	return {"ok":true,"task":int(data.task),"drafts":drafts,"runs":runs}

static func encode(task: int, drafts: Array, runs: Array) -> String:
	return JSON.stringify({"schema":1,"model":Model.VERSION,"contracts":contract_id(),"task":task,"drafts":drafts,"runs":runs})

static func read_session(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok":true,"empty":true,"digest":""}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"ok":false,"error":"read"}
	if file.get_length() > MAX_BYTES: return {"ok":false,"error":"size"}
	var raw := file.get_as_text()
	var result := decode(raw)
	result["digest"] = raw.sha256_text()
	return result

static func write_session(raw: String, path: String = PATH, expected_digest: String = "") -> Error:
	if not decode(raw).ok: return ERR_INVALID_DATA
	# Never overwrite unknown, corrupt or newer data implicitly.
	var current := read_session(path)
	if not current.ok: return ERR_INVALID_DATA
	if current.get("digest", "") != expected_digest: return ERR_ALREADY_IN_USE
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(raw); file.flush()
	var write_error := file.get_error(); file.close()
	if write_error != OK: return write_error
	if not read_session(temporary).ok: return ERR_FILE_CORRUPT
	var had_previous := FileAccess.file_exists(path)
	if had_previous:
		var moved := DirAccess.rename_absolute(path,backup)
		if moved != OK: return moved
	var installed := DirAccess.rename_absolute(temporary,path)
	if installed != OK and had_previous: DirAccess.rename_absolute(backup,path)
	return installed
