extends RefCounted
## Saved, read-only evidence. No drafts, flags, leases or campaign authority.
const Representation = preload("res://experiments/representation_region/model.gd")
const Service = preload("res://experiments/service_plan/model.gd")
const Files = preload("res://experiments/candidate_session/files.gd")

static func unavailable(error: String) -> Dictionary:
	var evidence: Array[Dictionary] = []
	var completed: Array[int] = []
	return {"status":"unavailable","evidence":evidence,"completed":completed,"error":error if not error.is_empty() else "invalid"}

static func empty() -> Dictionary:
	var evidence: Array[Dictionary] = []
	var completed: Array[int] = []
	return {"status":"empty","evidence":evidence,"completed":completed,"error":""}

static func integer(value: Variant, low: int, high: int) -> bool:
	return value is int and value >= low and value <= high

static func plan_valid(plan: Variant, representation: bool) -> bool:
	if representation:
		if not plan is Array or plan.is_empty() or plan.size() > 8: return false
		for block: Variant in plan:
			if not block is Dictionary or block.size() != 3: return false
			if not integer(block.get("start"),0,63) or not integer(block.get("end"),1,64): return false
			if block.get("codec") not in ["raw","rle"]: return false
		return Representation.Base.validate(plan,Representation.asset()).is_empty()
	if not plan is Dictionary or plan.size() != 3 or not integer(plan.get("slots"),1,4): return false
	if not plan.get("representations") is Array or plan.representations.size() != 4: return false
	for format: Variant in plan.representations:
		if not format is String or format not in Service.REPRESENTATIONS: return false
	if not plan.get("groups") is Array or plan.groups.is_empty() or plan.groups.size() > 24: return false
	var seen: Dictionary = {}
	for group: Variant in plan.groups:
		if not group is Array or group.is_empty() or group.size() > 24: return false
		for id: Variant in group:
			if not integer(id,0,23) or seen.has(id): return false
			seen[id] = true
	return seen.size() == 24 # Stream order/scratch acceptance belongs to the model.

static func evaluate_domain(saved: Dictionary, representation: bool) -> Dictionary:
	if not saved.get("ok") is bool or not saved.ok:
		return unavailable(str(saved.get("error","invalid")))
	if saved.get("empty",false) == true: return empty()
	if not saved.get("runs") is Array or not saved.get("supports",[]) is Array: return unavailable("invalid")
	var count: int = 5 if representation else 3
	if saved.runs.size() > (100 if representation else 80) or saved.get("supports",[]).size() > count: return unavailable("invalid")
	var records: Array = saved.get("supports",[]).duplicate(true)
	records.append_array(saved.runs.duplicate(true))
	var accepted: Dictionary = {}
	for record: Variant in records:
		if not record is Dictionary or record.size() != 2 or not integer(record.get("task"),0,count-1) or not plan_valid(record.get("plan"),representation): return unavailable("invalid")
		var task: int = record.task
		if accepted.has(task): continue
		if representation:
			var traces: Array = []
			var metrics: Array[Dictionary] = []
			for spec: Dictionary in Representation.orders(task):
				var trace: RefCounted = Representation.run(spec,record.plan)
				traces.append(trace); metrics.append(trace.metrics.duplicate(true))
			if Representation.meets(task,traces): accepted[task] = {"task":task,"metrics":metrics}
		else:
			var trace: RefCounted = Service.run(record.plan)
			if Service.accepted(trace.metrics,task): accepted[task] = {"task":task,"metrics":trace.metrics.duplicate(true)}
	var evidence: Array[Dictionary] = []
	var completed: Array[int] = []
	for task: int in count:
		if accepted.has(task):
			completed.append(task); evidence.append(accepted[task].duplicate(true))
	return {"status":"complete" if completed.size() == count else "partial","evidence":evidence,"completed":completed,"error":""}

static func evaluate(representation: Dictionary, service: Dictionary) -> Dictionary:
	var rep: Dictionary = evaluate_domain(representation,true)
	var state: Dictionary = evaluate_domain(service,false)
	return {"representation":rep,"service":state,"complete":rep.status == "complete" and state.status == "complete"}

static func read_saved(path: String, representation: bool) -> Dictionary:
	if path.is_empty(): return {"ok":false,"error":"invalid_path"}
	# Loading the stores eagerly initializes their PATH adapters. Missing domains
	# must remain missing: do not load either store until transaction files exist.
	if Files.transaction_paths(path).is_empty(): return {"ok":true,"empty":true,"digest":""}
	var store: Script = load("res://experiments/representation_region/session_store.gd" if representation else "res://experiments/service_plan/session_store.gd")
	if store == null: return {"ok":false,"error":"decode"}
	return Files.read_session(path,store.decode)

static func finish_snapshot(evaluated: Dictionary, digests: Dictionary, before: Dictionary, after: Dictionary) -> Dictionary:
	var result: Dictionary = evaluated.duplicate(true)
	# Both domains belong to one displayed snapshot. A change makes it unavailable.
	if before != after:
		result = {"representation":unavailable("snapshot_changed"),"service":unavailable("snapshot_changed"),"complete":false}
	result.fingerprints = after.duplicate(true)
	result.digests = digests.duplicate(true)
	return result

static func read_pair(rep_path: String, service_path: String) -> Dictionary:
	var before := {"representation":Files.fingerprint(rep_path),"service":Files.fingerprint(service_path)}
	var representation: Dictionary = read_saved(rep_path,true)
	var service: Dictionary = read_saved(service_path,false)
	var result: Dictionary = evaluate(representation,service)
	var after := {"representation":Files.fingerprint(rep_path),"service":Files.fingerprint(service_path)}
	var digests := {"representation":str(representation.get("digest","")),"service":str(service.get("digest",""))}
	return finish_snapshot(result,digests,before,after)
