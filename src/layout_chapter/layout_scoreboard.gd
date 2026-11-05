class_name LayoutScoreboard
extends RefCounted
## A read-only comparison of player recipes, recomputed under the current task.
## Rows are never completion evidence and never read cached or telemetry scores.

const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")


static func build_rows(
		level_id: String,
		candidates: Array[Dictionary],
		objective: String = "cycles"
	) -> Array[Dictionary]:
	var tasks: Array[Dictionary] = Catalog.cases(level_id)
	var condition_id: String = condition_id_for(level_id)
	var rows: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		rows.append(_measure(level_id, candidate, tasks, condition_id))
	return rank_rows(rows,objective)


static func condition_id_for(level_id: String) -> String:
	return JSON.stringify({
		"task": level_id,
		"model": Simulator.MODEL_VERSION,
		"cases": Catalog.cases(level_id),
	}).sha256_text()


static func rank_rows(measured: Array[Dictionary], objective: String = "cycles") -> Array[Dictionary]:
	# Re-sort one immutable measurement snapshot while its exclusive window is
	# open. Opening/saving still calls build_rows to remeasure current recipes.
	var rows: Array[Dictionary] = measured.duplicate(true)
	var metric: String = "peak" if objective == "space" else "traffic" if objective == "traffic" else "cycles"
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.eligible != b.eligible:
			return bool(a.eligible)
		if a.eligible and int(a[metric]) != int(b[metric]):
			return int(a[metric]) < int(b[metric])
		if a.id != b.id:
			return String(a.id) < String(b.id)
		if a.recipe_id != b.recipe_id:
			return String(a.recipe_id) < String(b.recipe_id)
		return String(a.title) < String(b.title))
	var previous_metric: int = -1
	var previous_rank: int = 0
	for index: int in rows.size():
		var row: Dictionary = rows[index]
		if not row.eligible:
			continue
		var value: int = int(row[metric])
		if value != previous_metric:
			previous_rank = index + 1
			previous_metric = value
		row.rank = previous_rank
	return rows


static func _measure(
		level_id: String,
		candidate: Dictionary,
		tasks: Array[Dictionary],
		condition_id: String
	) -> Dictionary:
	var raw: Variant = candidate.get("design")
	var row: Dictionary = {
		"id": str(candidate.get("id", "")),
		"title": str(candidate.get("title", "")),
		"design": raw.duplicate(true) if raw is Dictionary else {},
		"eligible": false,
		"correct": false,
		"cycles": 0,
		"traffic": 0,
		"peak": 0,
		"rank": 0,
		"condition_id": condition_id,
		"recipe_id": "",
		"reason": "invalid_design",
		"cases": [],
	}
	if tasks.is_empty():
		row.reason = "unknown_task"
		return row
	var design: Dictionary = _validated_design(level_id,raw)
	if design.is_empty():
		return row
	row.design = design.duplicate(true)
	var report: Dictionary = Catalog.evaluate(level_id, design)
	var runs: Array = report.get("runs", [])
	var complete: bool = runs.size() == tasks.size()
	var correct: bool = complete
	var qualified: bool = complete and bool(report.get("passed", false))
	for index: int in runs.size():
		var run: LayoutRun = runs[index]
		var metrics: Dictionary = run.metrics
		var case_matches: bool = (
			index < tasks.size()
			and run.model_version == Simulator.MODEL_VERSION
			and run.case_signature == JSON.stringify(tasks[index]).sha256_text()
		)
		var case_correct: bool = case_matches and run.passed and str(metrics.get("error", "")).is_empty()
		var target_met: bool = case_correct and bool(metrics.get("target_met", false))
		correct = correct and case_correct
		qualified = qualified and target_met
		var traffic: int = int(metrics.ram_read_bytes) + int(metrics.ram_write_bytes)
		row.cycles += int(metrics.total_cycles)
		row.traffic += traffic
		row.peak = maxi(int(row.peak), int(metrics.peak_extra_bytes))
		row.cases.append({
			"name": run.test_name,
			"correct": case_correct,
			"target_met": target_met,
			"cycles": int(metrics.total_cycles),
			"traffic": traffic,
			"peak": int(metrics.peak_extra_bytes),
			"error": str(metrics.get("error", "")),
			"case_id": run.case_signature,
			"recipe_id": run.recipe_signature,
			"trace_id": run.canonical_signature().sha256_text(),
			"output": run.output_values.duplicate(),
			"expected": run.expected_values.duplicate(),
		})
	row.correct = correct
	row.eligible = qualified
	# Identity follows the recipes actually executed in official case order.
	# Dictionary insertion order and unused container fields cannot change it.
	var executed: Array = []
	for case: Dictionary in row.cases:
		executed.append([case.name,case.recipe_id])
	row.recipe_id = JSON.stringify(executed).sha256_text()
	if qualified:
		row.reason = "ranked"
	elif not complete:
		row.reason = "incomplete_cases"
	elif correct:
		row.reason = "target_unmet"
	else:
		row.reason = "wrong_output"
		for case: Dictionary in row.cases:
			if not String(case.error).is_empty():
				row.reason = case.error
				break
	return row


static func _validated_design(level_id: String, raw: Variant) -> Dictionary:
	# Use the model's pure validation/normalization without depending on autoload
	# state. These are the same bounded recipes accepted by named workbenches.
	if not raw is Dictionary or JSON.stringify(raw).length() > 12000:
		return {}
	if not Simulator.validate_design(raw,level_id in ["fields","records","hot_cold"]).is_empty():
		return {}
	var result: Dictionary = Simulator.normalized_design(raw)
	if level_id == "relocation" and raw.has("orders"):
		if not raw.orders is Dictionary or raw.orders.size() > 2: return {}
		result["orders"] = {}
		for key: String in ["A","B"]:
			if not raw.orders.has(key): continue
			var order: Variant = raw.orders[key]
			if not order is Dictionary or not Simulator.validate_design(order,false).is_empty(): return {}
			result.orders[key] = Simulator.normalized_design(order)
		if result.orders.size() != raw.orders.size(): return {}
	return result
