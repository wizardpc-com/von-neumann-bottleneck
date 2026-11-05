extends "res://tests/test_layout_strategy_model.gd"
## Root-only isolated research: finite physical maps, no UI or save authority.
const ResearchGoals = preload("res://experiments/layout_strategy/goals.gd")
const STRUCTURAL_IDS: Array[String] = ["scan_pair_serial","split_fields_serial"]
const EXPECTED_MAPS: int = 220
const EXPECTED_CANDIDATES: int = 442
var candidate_count: int = 0
var replay_count: int = 0


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Round7 structural probe requires an isolated QA profile.")
		quit(1)
		return
	var started: int = Time.get_ticks_usec()
	var physical: Array[Dictionary] = _physical_plans()
	check(physical.size() == EXPECTED_MAPS,"Declared220 distinct one/two-field physical maps.")
	var scenarios: Array[Dictionary] = []
	var frontier_count: int = 0
	for id: String in STRUCTURAL_IDS:
		var task: Dictionary = Model.scenario(id)
		var plans: Array[Dictionary] = [Model.starter_plan()]
		plans.append_array(physical)
		var rows: Array[Dictionary] = []
		for index: int in range(plans.size()):
			var plan: Dictionary = plans[index]
			var run: LayoutRun = _measure(task,plan,id+"/"+str(index))
			candidate_count += 1
			if run == null: continue
			_check_run(task,plan,run)
			rows.append({
				"id":id+"/"+str(index),"task_id":id,"condition_id":run.case_signature,
				"plan":plan.duplicate(true),"trace_id":run.canonical_signature().sha256_text(),
				"correct":run.passed,"metrics":run.metrics.duplicate(true),
				"outputs":run.output_values.duplicate(),
			})
		var frontier: Array[Dictionary] = _frontier(rows)
		frontier_count += frontier.size()
		for representative: Dictionary in frontier:
			var plan: Dictionary = representative.plans[0]
			var trace_id: String = representative.trace_ids[0]
			var repeated: LayoutRun = _measure(task,plan,id+"/frontier-repeat")
			var json_run: LayoutRun = _measure(JSON.parse_string(JSON.stringify(task)),JSON.parse_string(JSON.stringify(plan)),id+"/frontier-json")
			replay_count += 2
			if repeated != null and json_run != null:
				check(repeated.canonical_signature().sha256_text() == trace_id and json_run.canonical_signature().sha256_text() == trace_id,"Each newly observed frontier representative repeats its complete Trace.")
		scenarios.append({
			"task":task,"candidates":rows,"frontier":frontier,
			"goal_winners":_goal_winners(rows,Model.condition_id(task)),
		})
		print("%s: %d candidates, %d finite frontier classes" % [id,rows.size(),frontier.size()])
	check(candidate_count == EXPECTED_CANDIDATES,"Declared442 direct/physical candidates.")
	check(replay_count == 2*frontier_count,"Every observed frontier class receives repeat and JSON verification.")
	var report: Dictionary = {
		"model":Model.MODEL_VERSION,"candidate_count":candidate_count,
		"replay_count":replay_count,"measurements":measured_count,
		"checks":checks,"failures":failures,
		"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,
		"scope":"Two fixed new serial workloads. Source-only plus220 distinct one/two-field maps from effective blocks0..17, both selected-field orders and same/separate field groups; group1/tile17. Finite sample, not all legal physical layouts or global optimality.",
		"scenarios":scenarios,
	}
	var path: String = "user://round7-structure-probe.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--probe-output="): path = argument.trim_prefix("--probe-output=")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write Round7 structural probe evidence.")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+
		"round7 structures %d candidates, %d repeat/JSON, %d checks, %.3f ms" %
		[candidate_count,replay_count,checks,report.elapsed_ms])
	print("RESULT: "+ProjectSettings.globalize_path(path))
	quit(0 if failures.is_empty() else 1)


func _physical_plans() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	for mask: int in range(1,16):
		var fields: Array[int] = []
		var remaining: Array[int] = []
		for field: int in range(4):
			if mask & (1 << field): fields.append(field)
			else: remaining.append(field)
		if fields.size() > 2: continue
		var orders: Array[Array] = [fields.duplicate()]
		if fields.size() == 2:
			var reversed: Array[int] = fields.duplicate()
			reversed.reverse()
			orders.append(reversed)
		for order: Array in orders:
			var all_fields: Array = order.duplicate()
			all_fields.append_array(remaining)
			var recipes: Array[Dictionary] = []
			for block: int in range(18):
				recipes.append({"groups":[{"fields":all_fields.duplicate(),"order":"field"}],"block":block})
			if fields.size() == 2:
				recipes.append({"groups":[
					{"fields":[order[0]],"order":"record"},
					{"fields":[order[1]],"order":"record"},
					{"fields":remaining.duplicate(),"order":"record"},
				],"block":0})
			for recipe: Dictionary in recipes:
				var key: String = JSON.stringify(Recipe.mapping(recipe,17,0,fields),"",true)
				if seen.has(key): continue
				seen[key] = true
				var plan: Dictionary = Model.starter_plan()
				plan.copy_mode = "full"
				plan.copy_fields = fields.duplicate()
				plan.recipe = recipe
				result.append(plan)
	return result


func _values(row: Dictionary) -> Dictionary:
	return {
		"first":int(row.metrics.first_request_cycles),"cycles":int(row.metrics.total_cycles),
		"traffic":int(row.metrics.ram_read_bytes)+int(row.metrics.ram_write_bytes),
		"peak":int(row.metrics.peak_extra_bytes),
	}


func _dominates(a: Dictionary, b: Dictionary) -> bool:
	var strict: bool = false
	for key: String in ["first","cycles","traffic","peak"]:
		if int(a[key]) > int(b[key]): return false
		strict = strict or int(a[key]) < int(b[key])
	return strict


func _frontier(rows: Array[Dictionary]) -> Array[Dictionary]:
	var classes: Dictionary = {}
	for row: Dictionary in rows:
		if not row.correct: continue
		var metrics: Dictionary = _values(row)
		var key: String = JSON.stringify(metrics,"",true)
		if not classes.has(key): classes[key] = {"metrics":metrics,"plans":[],"trace_ids":[]}
		classes[key].plans.append(row.plan)
		classes[key].trace_ids.append(row.trace_id)
	var result: Array[Dictionary] = []
	for candidate: Dictionary in classes.values():
		var dominated: bool = false
		for other: Dictionary in classes.values():
			if _dominates(other.metrics,candidate.metrics):
				dominated = true
				break
		if not dominated: result.append(candidate)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if a.metrics.first != b.metrics.first: return a.metrics.first < b.metrics.first
		return JSON.stringify(a.metrics,"",true) < JSON.stringify(b.metrics,"",true))
	return result


func _goal_winners(rows: Array[Dictionary], condition: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for objective: String in ["cycles","traffic"]:
		var goal: Dictionary = {"objective":objective,"first_limit":600,"copy_limit":80}
		var ranked: Array[Dictionary] = ResearchGoals.rank(rows,condition,goal)
		var best: Array[Dictionary] = []
		for row: Dictionary in ranked:
			if row.rank == 1: best.append({"plan":row.plan,"metrics":_values(row)})
		result.append({"goal":goal,"sample_best":best})
	return result
