extends RefCounted
## Filters current-process measurements. Stored numbers are never score inputs.
const Model = preload("res://experiments/layout_strategy/model.gd")
const MAX_LIMIT: int = 1000000
const MAX_EXACT_INTEGER: int = 9007199254740991
const KEYS: Array[String] = ["objective","first_limit","copy_limit"]

static func default_goal() -> Dictionary:
	return {"objective":"cycles","first_limit":-1,"copy_limit":-1}

static func normalize(goal: Dictionary) -> Dictionary:
	if goal.size() != KEYS.size(): return {}
	for key: Variant in goal:
		if not key is String or key not in KEYS: return {}
	if not goal.objective is String or goal.objective not in ["cycles","traffic"]: return {}
	if not _integer(goal.first_limit,-1,MAX_LIMIT) or not _integer(goal.copy_limit,-1,MAX_LIMIT): return {}
	return {
		"objective":String(goal.objective),
		"first_limit":int(goal.first_limit),"copy_limit":int(goal.copy_limit),
	}

static func rule_id(condition: String, goal: Dictionary) -> String:
	var normalized: Dictionary = normalize(goal)
	if condition.is_empty() or normalized.is_empty(): return ""
	return JSON.stringify({"version":1,"condition":condition,"goal":normalized},"",true).sha256_text()

static func rank(rows: Array[Dictionary], condition: String, goal: Dictionary) -> Array[Dictionary]:
	var normalized: Dictionary = normalize(goal)
	var ordered: Array[Dictionary] = []
	for index: int in range(rows.size()):
		var row: Dictionary = rows[index].duplicate(true)
		var exclusions: Array[String] = []
		if normalized.is_empty(): exclusions.append("invalid")
		if condition.is_empty() or not row.get("condition_id") is String or row.condition_id != condition:
			exclusions.append("condition")
		var problem: String = _measurement_error(row)
		if not problem.is_empty() and problem not in exclusions: exclusions.append(problem)
		if problem.is_empty() and not normalized.is_empty():
			if int(normalized.first_limit) >= 0 and int(row.metrics.first_request_cycles) > int(normalized.first_limit):
				exclusions.append("first")
			if int(normalized.copy_limit) >= 0 and int(row.metrics.peak_extra_bytes) > int(normalized.copy_limit):
				exclusions.append("copy")
		row["eligible"] = exclusions.is_empty()
		row["exclusions"] = exclusions
		row["rank"] = 0
		var value: int = 0
		if row.eligible:
			value = int(row.metrics.total_cycles) if normalized.objective == "cycles" else int(row.metrics.ram_read_bytes)+int(row.metrics.ram_write_bytes)
		ordered.append({"row":row,"position":index,"value":value})
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if bool(a.row.eligible) != bool(b.row.eligible): return bool(a.row.eligible)
		if bool(a.row.eligible) and int(a.value) != int(b.value): return int(a.value) < int(b.value)
		return int(a.position) < int(b.position))
	var result: Array[Dictionary] = []
	var eligible_count: int = 0
	var previous_value: int = -1
	var current_rank: int = 0
	for item: Dictionary in ordered:
		var row: Dictionary = item.row
		if row.eligible:
			eligible_count += 1
			if int(item.value) != previous_value:
				current_rank = eligible_count
				previous_value = int(item.value)
			row.rank = current_rank
		result.append(row)
	return result

static func _measurement_error(row: Dictionary) -> String:
	if not row.get("correct") is bool or not row.get("metrics") is Dictionary: return "invalid"
	var metrics: Dictionary = row.metrics
	if not row.correct: return "incomplete"
	for key: String in ["total_cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes"]:
		if not _integer(metrics.get(key),0,MAX_EXACT_INTEGER): return "invalid"
	if not _integer(metrics.get("first_request_cycles"),-1,MAX_EXACT_INTEGER): return "invalid"
	if not metrics.get("error") is String or not metrics.get("result_class") is String: return "invalid"
	if metrics.error != "" or metrics.result_class != "correct_output" or int(metrics.first_request_cycles) < 0:
		return "incomplete"
	if not _integer(metrics.get("job_count"),1,Model.MAX_JOBS): return "invalid"
	if not metrics.get("response_cycles") is Array or not metrics.get("admission_cycles") is Array:
		return "invalid"
	var responses: Array = metrics.response_cycles
	var admissions: Array = metrics.admission_cycles
	var count: int = int(metrics.job_count)
	if responses.size() != count or admissions.size() != count: return "incomplete"
	var latest: int = -1
	for index: int in range(count):
		if not _integer(responses[index],-1,MAX_EXACT_INTEGER) or not _integer(admissions[index],-1,MAX_EXACT_INTEGER):
			return "invalid"
		var response: int = int(responses[index])
		var admitted: int = int(admissions[index])
		if response < 0 or admitted < 0: return "incomplete"
		if admitted > response: return "invalid"
		latest = maxi(latest,response)
	if int(metrics.first_request_cycles) != int(responses[0]) or latest != int(metrics.total_cycles):
		return "invalid"
	return ""

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float): return false
	var numeric: float = float(value)
	return is_finite(numeric) and numeric == floorf(numeric) and numeric >= float(minimum) and numeric <= float(maximum)
