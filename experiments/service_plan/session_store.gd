extends RefCounted
## Candidate-only decisions; all measurements and unlocks are recomputed.
const Designs = preload("res://experiments/candidate_session/designs.gd")
const Model = preload("res://experiments/service_plan/model.gd")
const Context = preload("res://experiments/candidate_session/context.gd")
static var PATH: String = Context.save_path("service")
const MAX_BYTES := 262144
const Files = preload("res://experiments/candidate_session/files.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")

static func contract_id() -> String:
	var data: Array = []
	for stream: int in 4:
		var inputs: Array = []
		for step: int in 6: inputs.append(Model.input(stream,step))
		data.append([Model.initial(stream),inputs])
	return JSON.stringify([Model.VERSION,Model.WEIGHTS,data,Model.REPRESENTATIONS,Model.SCRATCH_LIMIT,
		[64,72,4,4,24,8,0.65,0.35],[1420,350,600,320,320,0.000000001,0.02]]).sha256_text()

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func clean_plan(value: Variant) -> Dictionary:
	if not value is Dictionary or value.size() != 3: return {}
	if not integer(value.get("slots"),1,4): return {}
	if not value.get("representations") is Array or value.representations.size() != 4: return {}
	var formats: Array = []
	for format: Variant in value.representations:
		if not format is String or format not in Model.REPRESENTATIONS: return {}
		formats.append(format)
	if not value.get("groups") is Array or value.groups.is_empty() or value.groups.size() > 24: return {}
	var groups: Array = []; var seen: Dictionary = {}
	for group: Variant in value.groups:
		if not group is Array or group.is_empty() or group.size() > 24: return {}
		var ids: Array = []
		for id: Variant in group:
			if not integer(id,0,23) or seen.has(int(id)): return {}
			ids.append(int(id)); seen[int(id)] = true
		groups.append(ids)
	if seen.size() != 24: return {}
	return {"slots":int(value.slots),"representations":formats,"groups":groups}

static func decode(raw: String) -> Dictionary:
	if raw.to_utf8_buffer().size() > MAX_BYTES: return {"ok":false,"error":"size"}
	var parser := JSON.new()
	if parser.parse(raw) != OK: return {"ok":false,"error":"json"}
	var data: Variant = parser.data
	if not data is Dictionary: return {"ok":false,"error":"schema"}
	if not integer(data.get("schema"),1,3): return {"ok":false,"error":"version"}
	if data.size() != 5 + int(data.schema): return {"ok":false,"error":"schema"}
	var keys: Array = ["schema","model","contracts","task","draft","runs"]
	if int(data.schema) >= 2: keys.append("supports")
	if int(data.schema) == 3: keys.append("designs")
	for key: Variant in data:
		if key not in keys: return {"ok":false,"error":"schema"}
	if not integer(data.get("schema"),1,3) or data.get("model") != Model.VERSION or data.get("contracts") != contract_id(): return {"ok":false,"error":"version"}
	if not integer(data.get("task"),0,2): return {"ok":false,"error":"task"}
	var draft: Dictionary = clean_plan(data.get("draft"))
	if draft.is_empty(): return {"ok":false,"error":"draft"}
	if not data.get("runs") is Array or data.runs.size() > 80: return {"ok":false,"error":"runs"}
	var runs: Array = []
	for run: Variant in data.runs:
		if not run is Dictionary or run.size() != 2 or not integer(run.get("task"),0,2): return {"ok":false,"error":"run"}
		var plan: Dictionary = clean_plan(run.get("plan"))
		if plan.is_empty(): return {"ok":false,"error":"run_plan"}
		runs.append({"task":int(run.task),"plan":plan})
	var supports: Array = []
	if int(data.schema) >= 2:
		if not data.get("supports") is Array or data.supports.size() > 3: return {"ok":false,"error":"supports"}
		var seen: Dictionary = {}
		for run: Variant in data.supports:
			if not run is Dictionary or run.size() != 2 or not integer(run.get("task"),0,2) or seen.has(int(run.task)): return {"ok":false,"error":"support"}
			var plan = clean_plan(run.get("plan"))
			if plan.is_empty(): return {"ok":false,"error":"support_plan"}
			seen[int(run.task)] = true
			supports.append({"task":int(run.task),"plan":plan})
	var collection: Dictionary = Designs.clean(data.get("designs",[]),clean_plan,2)
	if not collection.ok: return collection
	return {"ok":true,"task":int(data.task),"draft":draft,"runs":runs,"supports":supports,"designs":collection.designs}

static func encode(task: int, draft: Dictionary, runs: Array, supports: Array = [], designs: Array = []) -> String:
	var data: Dictionary = {"schema":2,"model":Model.VERSION,"contracts":contract_id(),"task":task,"draft":draft,"runs":runs,"supports":supports}
	if not designs.is_empty():
		data.schema = 3; data["designs"] = designs
	return JSON.stringify(data)

static func read_session(path: String = PATH) -> Dictionary:
	return Files.read_session(path,decode)

static func write_session(raw: String, path: String = PATH, expected_digest: String = "", owner: RefCounted = null, stop_after: String = "") -> Error:
	return Files.write_session(raw,path,expected_digest,decode,owner,stop_after)

static func recover_session(source: String, expected_fingerprint: String, path: String = PATH, owner: RefCounted = null) -> Error:
	return Files.recover_session(path,source,expected_fingerprint,decode,owner)
