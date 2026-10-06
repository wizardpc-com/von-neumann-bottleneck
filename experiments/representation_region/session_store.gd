extends RefCounted
## Candidate-only storage. Persist decisions; recompute evidence on restore.
const Designs = preload("res://experiments/candidate_session/designs.gd")
const Model = preload("res://experiments/representation_region/model.gd")
const Catalog = preload("res://experiments/representation_region/catalog.gd")
const Base = preload("res://experiments/representation/plan_model.gd")
const Context = preload("res://experiments/candidate_session/context.gd")
static var PATH: String = Context.save_path("representation")
const MAX_BYTES := 262144
const Files = preload("res://experiments/candidate_session/files.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")

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
	if not data is Dictionary: return {"ok":false,"error":"schema"}
	if not integer(data.get("schema"),1,3): return {"ok":false,"error":"version"}
	if data.size() != 5 + int(data.schema): return {"ok":false,"error":"schema"}
	var keys: Array = ["schema","model","contracts","task","drafts","runs"]
	if int(data.schema) >= 2: keys.append("supports")
	if int(data.schema) == 3: keys.append("designs")
	for key: Variant in data:
		if key not in keys: return {"ok":false,"error":"schema"}
	if not integer(data.get("schema"),1,3) or not data.get("model") is String or not data.get("contracts") is String:
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
	var supports: Array = []
	if int(data.schema) >= 2:
		if not data.get("supports") is Array or data.supports.size() > 5: return {"ok":false,"error":"supports"}
		var seen: Dictionary = {}
		for run: Variant in data.supports:
			if not run is Dictionary or run.size() != 2 or not integer(run.get("task"),0,4) or seen.has(int(run.task)): return {"ok":false,"error":"support"}
			var plan = clean_plan(run.get("plan"))
			if plan.is_empty(): return {"ok":false,"error":"support_plan"}
			seen[int(run.task)] = true
			supports.append({"task":int(run.task),"plan":plan})
	var collection: Dictionary = Designs.clean(data.get("designs",[]),clean_plan,4)
	if not collection.ok: return collection
	return {"ok":true,"task":int(data.task),"drafts":drafts,"runs":runs,"supports":supports,"designs":collection.designs}

static func encode(task: int, drafts: Array, runs: Array, supports: Array = [], designs: Array = []) -> String:
	var data: Dictionary = {"schema":2,"model":Model.VERSION,"contracts":contract_id(),"task":task,"drafts":drafts,"runs":runs,"supports":supports}
	if not designs.is_empty():
		data.schema = 3; data["designs"] = designs
	return JSON.stringify(data)

static func read_session(path: String = PATH) -> Dictionary:
	return Files.read_session(path,decode)

static func write_session(raw: String, path: String = PATH, expected_digest: String = "", owner: RefCounted = null, stop_after: String = "") -> Error:
	return Files.write_session(raw,path,expected_digest,decode,owner,stop_after)

static func recover_session(source: String, expected_fingerprint: String, path: String = PATH, owner: RefCounted = null) -> Error:
	return Files.recover_session(path,source,expected_fingerprint,decode,owner)
