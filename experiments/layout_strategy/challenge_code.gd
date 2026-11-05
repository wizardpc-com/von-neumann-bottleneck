extends RefCounted
## Portable inputs. Live targets are measured locally under their immutable goal.
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const PREFIX: String = "VNBSC1:"
const MAX_BYTES: int = 4096
const MAX_DEPTH: int = 16
const ENVELOPE_KEYS: Array[String] = ["v","task","model","condition","goal","plan"]
const ENTRY_KEYS: Array[String] = [
	"task_id","plan","condition_id","trace_id","metrics","correct",
	"events","outputs","expected","source_map","scratch_maps",
]


static func create(task_id: String, plan: Dictionary, goal: Dictionary) -> Dictionary:
	if task_id not in Model.SCENARIO_IDS: return _failed("task")
	var normalized_goal: Dictionary = Goals.normalize(goal)
	if normalized_goal.is_empty(): return _failed("limits")
	var transported: Dictionary = _transport_plan(plan)
	if transported.is_empty(): return _failed("plan")
	var envelope: Dictionary = {
		"v":1,"task":task_id,"model":Model.MODEL_VERSION,
		"condition":Model.condition_id(Model.scenario(task_id)),
		"goal":normalized_goal,"plan":transported,
	}
	return inspect(PREFIX+_canonical(envelope))


static func decode(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES: return _failed("size")
	var cleaned: String = text.strip_edges()
	if not cleaned.begins_with(PREFIX):
		return _failed("version" if cleaned.begins_with("VNBSC") else "prefix")
	var payload: String = cleaned.substr(PREFIX.length())
	if not _bounded_depth(payload): return _failed("format")
	var parser := JSON.new()
	if parser.parse(payload) != OK or not parser.data is Dictionary: return _failed("format")
	var raw: Dictionary = parser.data
	if not _keys_exact(raw,ENVELOPE_KEYS): return _failed("format")
	if not _integer(raw.v,1,1): return _failed("version")
	if not raw.task is String or raw.task not in Model.SCENARIO_IDS: return _failed("task")
	if not raw.model is String or not _model_id(raw.model): return _failed("format")
	if not raw.condition is String or not _digest(raw.condition): return _failed("format")
	if not raw.goal is Dictionary: return _failed("limits")
	var goal: Dictionary = Goals.normalize(raw.goal)
	if goal.is_empty(): return _failed("limits")
	if not raw.plan is Dictionary: return _failed("plan")
	var plan: Dictionary = _transport_plan(raw.plan)
	if plan.is_empty(): return _failed("plan")
	var envelope: Dictionary = {
		"v":1,"task":String(raw.task),"model":String(raw.model),
		"condition":String(raw.condition),"goal":goal,"plan":plan,
	}
	# Exact canonical spelling also rejects duplicates, defaulting and dormant
	# no-copy variants. Semantic field/group array order is never sorted.
	if payload != _canonical(envelope): return _failed("format")
	return {"ok":true,"reason":"","code":PREFIX+payload,"envelope":envelope}


static func inspect(text: String) -> Dictionary:
	var decoded: Dictionary = decode(text)
	if not decoded.ok: return decoded
	var envelope: Dictionary = decoded.envelope
	var task: Dictionary = Model.scenario(envelope.task)
	if envelope.model != Model.MODEL_VERSION or envelope.condition != Model.condition_id(task):
		return _failed("stale")
	if not Model.validate(task,envelope.plan).is_empty(): return _failed("plan")
	var measured: Dictionary = Model.evaluate(task,envelope.plan)
	if not measured.get("valid",false) or measured.get("run") == null: return _failed("plan")
	var entry: Dictionary = _entry(envelope.task,envelope.plan,measured.run)
	var candidates: Array[Dictionary] = [entry]
	var ranked: Dictionary = Goals.rank(candidates,envelope.condition,envelope.goal)[0]
	if not ranked.eligible:
		var failed: Dictionary = _failed("incomplete" if _unavailable(ranked.exclusions) else "limits")
		failed["exclusions"] = ranked.exclusions.duplicate()
		return failed
	decoded["entry"] = entry
	decoded["challenge_id"] = String(decoded.code).sha256_text()
	return decoded


static func compare(target: Dictionary, attempt: Dictionary) -> Dictionary:
	# Callers provide a current inspect result and a freshly measured Session
	# entry. Persisted/pasted summaries are never accepted at that boundary.
	if not target.get("ok") is bool or not target.ok or not target.get("code") is String:
		return _comparison("unavailable",["target"])
	var decoded: Dictionary = decode(target.code)
	if not decoded.ok or not target.get("envelope") is Dictionary or target.envelope != decoded.envelope:
		return _comparison("unavailable",["target"])
	var envelope: Dictionary = decoded.envelope
	var task: Dictionary = Model.scenario(envelope.task)
	if envelope.model != Model.MODEL_VERSION or envelope.condition != Model.condition_id(task):
		return _comparison("unavailable",["target"])
	if target.get("challenge_id") != String(decoded.code).sha256_text() or not target.get("entry") is Dictionary:
		return _comparison("unavailable",["target"])
	var reference: Dictionary = target.entry
	if not _entry_error(reference,task).is_empty() or Model.plan_id(reference.plan) != Model.plan_id(envelope.plan):
		return _comparison("unavailable",["target"])
	var references: Array[Dictionary] = [reference]
	if not Goals.rank(references,envelope.condition,envelope.goal)[0].eligible:
		return _comparison("unavailable",["target"])
	var problem: String = _entry_error(attempt,task)
	if not problem.is_empty(): return _comparison("unavailable",[problem])
	var candidates: Array[Dictionary] = [attempt]
	var ranked: Dictionary = Goals.rank(candidates,envelope.condition,envelope.goal)[0]
	if not ranked.eligible:
		return _comparison("unavailable" if _unavailable(ranked.exclusions) else "outside",ranked.exclusions)
	var delta: int = _objective(attempt.metrics,envelope.goal)-_objective(reference.metrics,envelope.goal)
	var result: Dictionary = _comparison("improved" if delta < 0 else "behind" if delta > 0 else "tied",[])
	result["delta"] = delta
	return result


static func starter_goal(task_id: String) -> Dictionary:
	match task_id:
		"scan_batch":
			return Goals.normalize({"objective":"cycles","first_limit":350,"copy_limit":0})
		"scan_serial":
			return Goals.normalize({"objective":"cycles","first_limit":600,"copy_limit":80})
		"scan_pair_serial":
			return Goals.normalize({"objective":"traffic","first_limit":600,"copy_limit":80})
		"split_fields_serial":
			return Goals.normalize({"objective":"cycles","first_limit":800,"copy_limit":144})
	return {}


static func starter(task_id: String) -> Dictionary:
	var goal: Dictionary = starter_goal(task_id)
	return _failed("task") if goal.is_empty() else create(task_id,Model.starter_plan(),goal)


static func _transport_plan(plan: Dictionary) -> Dictionary:
	var normalized: Dictionary = Model.normalize_plan(plan)
	if normalized.is_empty(): return {}
	if normalized.copy_mode == "none":
		var defaults: Dictionary = Model.starter_plan()
		normalized.copy_fields = defaults.copy_fields.duplicate()
		normalized.recipe = defaults.recipe.duplicate(true)
	return normalized


static func _entry(task_id: String, plan: Dictionary, trace: LayoutRun) -> Dictionary:
	var events: Array[Dictionary] = []
	for event: SimulationEvent in trace.events: events.append(event.to_dictionary())
	return {
		"task_id":task_id,"plan":plan.duplicate(true),"condition_id":trace.case_signature,
		"trace_id":trace.canonical_signature().sha256_text(),"metrics":trace.metrics.duplicate(true),
		"correct":trace.passed,"events":events,"outputs":trace.output_values.duplicate(),
		"expected":trace.expected_values.duplicate(),"source_map":trace.source_map.duplicate(true),
		"scratch_maps":trace.scratch_maps.duplicate(true),
	}


static func _entry_error(row: Dictionary, task: Dictionary) -> String:
	if not row.has_all(ENTRY_KEYS): return "invalid"
	if not row.task_id is String or row.task_id != task.id: return "condition"
	if not row.condition_id is String or row.condition_id != Model.condition_id(task): return "condition"
	if not row.plan is Dictionary or not Model.validate(task,row.plan).is_empty(): return "invalid"
	if not row.trace_id is String or not _digest(row.trace_id): return "invalid"
	if not row.correct is bool or not row.metrics is Dictionary: return "invalid"
	if not row.events is Array or row.events.is_empty() or row.events.size() > Model.MAX_TRACE_EVENTS: return "invalid"
	if not row.outputs is Array or not row.expected is Array: return "invalid"
	if row.outputs.size() > Model.MAX_OUTPUT_VALUES or row.expected.size() > Model.MAX_OUTPUT_VALUES: return "invalid"
	if not row.source_map is Dictionary or not row.scratch_maps is Array: return "invalid"
	if not row.correct or row.outputs.is_empty() or row.outputs != row.expected: return "incomplete"
	return ""


static func _objective(metrics: Dictionary, goal: Dictionary) -> int:
	if goal.objective == "traffic": return int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes)
	return int(metrics.total_cycles)


static func _unavailable(exclusions: Array) -> bool:
	for reason: Variant in exclusions:
		if reason not in ["first","copy"]: return true
	return false


static func _comparison(status: String, exclusions: Array) -> Dictionary:
	return {"status":status,"exclusions":exclusions.duplicate()}


static func _keys_exact(value: Dictionary, keys: Array) -> bool:
	if value.size() != keys.size(): return false
	for key: Variant in value:
		if not key is String or key not in keys: return false
	return true


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= float(minimum) and float(value) <= float(maximum)


static func _model_id(value: String) -> bool:
	if value.is_empty() or value.length() > 80: return false
	for index: int in range(value.length()):
		if value.unicode_at(index) < 33 or value.unicode_at(index) > 126: return false
	return true


static func _digest(value: String) -> bool:
	if value.length() != 64: return false
	for index: int in range(value.length()):
		if value[index] not in "0123456789abcdef": return false
	return true


static func _bounded_depth(payload: String) -> bool:
	var depth: int = 0
	var quoted: bool = false
	var escaped: bool = false
	for index: int in range(payload.length()):
		var character: String = payload[index]
		if quoted:
			if escaped: escaped = false
			elif character == "\\": escaped = true
			elif character == "\"": quoted = false
		elif character == "\"":
			quoted = true
		elif character in ["{","["]:
			depth += 1
			if depth > MAX_DEPTH: return false
		elif character in ["}","]"]:
			depth -= 1
			if depth < 0: return false
	return depth == 0 and not quoted


static func _canonical(value: Dictionary) -> String:
	return JSON.stringify(value,"",true)


static func _failed(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
