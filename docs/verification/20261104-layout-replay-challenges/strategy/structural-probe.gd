extends SceneTree
## Bounded structural probe. Root alone executes this in an isolated QA copy.
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const EXPECTED_CANDIDATES: int = 1475
const EXPECTED_REPLAYS: int = 48
var failures: Array[String] = []
var candidates: int = 0
var replays: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _values(row: Dictionary) -> Dictionary:
	var metrics: Dictionary = row.metrics
	return {
		"first":int(metrics.first_request_cycles),"cycles":int(metrics.total_cycles),
		"traffic":int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes),
		"peak":int(metrics.peak_extra_bytes),
	}

func _plans() -> Array[Dictionary]:
	var plans: Array[Dictionary] = [Model.starter_plan()]
	for mask: int in range(1,16):
		var fields: Array[int] = []
		for field: int in 4:
			if mask & (1 << field): fields.append(field)
		if fields.size() > 2: continue
		var recipes: Array[Dictionary] = [Recipe.record_major()]
		if fields.size() == 2: recipes.append(Recipe.field_major())
		for recipe: Dictionary in recipes:
			var plan: Dictionary = Model.starter_plan()
			plan.copy_mode = "full"
			plan.copy_fields = fields.duplicate()
			plan.recipe = recipe
			plans.append(plan)
	return plans

func _tasks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for repeat: int in [1,2,3]:
		var task: Dictionary = Model.scenario("scan_serial")
		task.queries[0].repeat = repeat
		result.append({"label":"full_scan_serial_r"+str(repeat),"task":task,"shipped":false})
	result.append({"label":"scan_serial_control","task":Model.scenario("scan_serial"),"shipped":true})
	result.append({"label":"mixed_serial_control","task":Model.scenario("mixed_serial"),"shipped":true})
	var split: Dictionary = Model.scenario("mixed_serial")
	split.queries = [
		{"kind":"sum","fields":[0],"indices":[],"repeat":4},
		{"kind":"sum","fields":[3],"indices":[],"repeat":4},
	]
	result.append({"label":"split_fields_serial","task":split,"shipped":false})
	for clustered: bool in [true,false]:
		var sparse: Dictionary = Model.scenario("scan_serial")
		sparse.queries = [{
			"kind":"sum","fields":[0],"repeat":16,
			"indices":[1,2,3] if clustered else [1,8,15],
		}]
		result.append({
			"label":"sparse_cluster_serial" if clustered else "sparse_spread_serial",
			"task":sparse,"shipped":false,
		})
	return result

func _physical_plans() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	for mask: int in range(1,16):
		var fields: Array[int] = []
		var remaining: Array[int] = []
		for field: int in 4:
			if mask & (1 << field): fields.append(field)
			else: remaining.append(field)
		if fields.size() > 2: continue
		var orders: Array[Array] = [fields.duplicate()]
		if fields.size() == 2:
			var reverse: Array[int] = fields.duplicate()
			reverse.reverse()
			orders.append(reverse)
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
				var mapping: Dictionary = Recipe.mapping(recipe,17,0,fields)
				var key: String = JSON.stringify(mapping,"",true)
				if seen.has(key): continue
				seen[key] = true
				var plan: Dictionary = Model.starter_plan()
				plan.copy_mode = "full"
				plan.copy_fields = fields.duplicate()
				plan.recipe = recipe
				result.append(plan)
	return result

func _measure(task: Dictionary, plan: Dictionary, label: String, verify_repeat: bool = true) -> Dictionary:
	var result: Dictionary = Model.evaluate(task,plan)
	candidates += 1
	check(result.valid and result.run != null,label+": actual valid model execution")
	if not result.valid or result.run == null: return {}
	var run: LayoutRun = result.run
	var expected: Array[int] = Simulator.expected(task)
	var query_values: int = 0
	var jobs: int = 0
	for query: Dictionary in task.queries:
		var count: int = task.records.size() if query.indices.is_empty() else query.indices.size()
		query_values += count*query.fields.size()*int(query.repeat)
		jobs += int(query.repeat)
	var copied: int = task.records.size()*plan.copy_fields.size() if plan.copy_mode == "full" else 0
	var allocated: int = int(Recipe.mapping(plan.recipe,task.records.size(),0,plan.copy_fields).bytes) if copied > 0 else 0
	check(run.passed and run.output_values == expected,label+": complete ordered output")
	check(int(run.metrics.total_cycles) == 2*query_values+expected.size()+10*copied+16*int(run.metrics.fills),label+": actual cycle accounting")
	check(int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes) == 4*copied+16*int(run.metrics.fills),label+": actual traffic accounting")
	check(int(run.metrics.peak_extra_bytes) == allocated,label+": actual allocation")
	check(run.metrics.job_count == jobs and run.metrics.response_cycles.size() == jobs,label+": complete logical jobs")
	check(run.metrics.first_request_cycles == run.metrics.response_cycles[0],label+": public Q1 response")
	check(run.metrics.response_cycles.max() == run.metrics.total_cycles,label+": final response/makespan")
	var writes: int = 0
	var outputs: int = 0
	var responses: Dictionary = {}
	for event: SimulationEvent in run.events:
		if event.kind == &"write": writes += 1
		if event.kind == &"output": outputs += 1
		if event.kind == &"response":
			var job_id: int = int(event.details.job_id)
			check(not responses.has(job_id),label+": one response per job")
			responses[job_id] = event.cycle
		if event.details.has("job_id"):
			var job_id: int = int(event.details.job_id)
			check(event.cycle >= int(run.metrics.admission_cycles[job_id]),label+": causal execution")
	check(writes == copied and outputs == expected.size() and responses.size() == jobs,label+": authoritative event totals")
	for job_id: int in jobs:
		var admitted: int = 0 if task.release == "batch" or job_id == 0 else int(run.metrics.response_cycles[job_id-1])
		check(run.metrics.admission_cycles[job_id] == admitted,label+": serial admission")
		check(responses.get(job_id,-1) == run.metrics.response_cycles[job_id],label+": event-bound response")
	check(run.case_signature == Model.condition_id(task) and run.recipe_signature == Model.plan_id(plan),label+": complete identities")
	var signature: String = run.canonical_signature().sha256_text()
	if verify_repeat and (plan.copy_mode == "none" or plan.copy_fields == [0] or (plan.copy_fields == [0,3] and plan.recipe == Recipe.field_major())):
		var repeated: LayoutRun = Model.evaluate(task,plan).run
		var json_run: LayoutRun = Model.evaluate(JSON.parse_string(JSON.stringify(task)),JSON.parse_string(JSON.stringify(plan))).run
		replays += 2
		check(repeated.canonical_signature().sha256_text() == signature and json_run.canonical_signature().sha256_text() == signature,label+": repeat/JSON exact Trace")
	return {
		"id":label,"task_id":task.id,"condition_id":run.case_signature,
		"plan":plan.duplicate(true),"trace_id":signature,"correct":run.passed,
		"metrics":run.metrics.duplicate(true),
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
		if row.is_empty() or not row.correct: continue
		var metrics: Dictionary = _values(row)
		var key: String = JSON.stringify(metrics,"",true)
		if not classes.has(key): classes[key] = {"metrics":metrics,"plans":[]}
		classes[key].plans.append(row.plan)
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
		var ranked: Array[Dictionary] = Goals.rank(rows,condition,goal)
		var best: Array[Dictionary] = []
		for row: Dictionary in ranked:
			if row.rank == 1: best.append({"plan":row.plan,"metrics":_values(row)})
		result.append({"goal":goal,"rule_id":Goals.rule_id(condition,goal),"sample_best":best})
	return result

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Round6 probe requires an isolated QA profile.")
		quit(1)
		return
	var started: int = Time.get_ticks_usec()
	var records: Array[Dictionary] = []
	var plans: Array[Dictionary] = _plans()
	check(plans.size() == 17,"Declared17 physical plans")
	for record: Dictionary in _tasks():
		var rows: Array[Dictionary] = []
		for plan_index: int in plans.size():
			rows.append(_measure(record.task,plans[plan_index],record.label+"/"+str(plan_index)))
		record["candidates"] = rows
		record["frontier"] = _frontier(rows)
		record["goal_winners"] = _goal_winners(rows,Model.condition_id(record.task))
		records.append(record)
		print(record.label+": "+str(rows.size())+" plans, "+str(record.frontier.size())+" sampled frontier classes")
	var physical: Array[Dictionary] = []
	var physical_plans: Array[Dictionary] = _physical_plans()
	check(physical_plans.size() == 220,"Declared220 distinct one/two-field physical mappings")
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var jobs: int = 0
		for query: Dictionary in task.queries: jobs += int(query.repeat)
		var rows: Array[Dictionary] = []
		var source_groups: Array = range(1,jobs+1) if task.release == "batch" else [1]
		for group: int in source_groups:
			var plan: Dictionary = Model.starter_plan()
			plan.query_group = group
			plan.record_tile = 1
			rows.append(_measure(task,plan,id+"/source/"+str(group),false))
		var copied_groups: Array = [1,jobs] if task.release == "batch" else [1]
		for group: int in copied_groups:
			for original: Dictionary in physical_plans:
				var plan: Dictionary = original.duplicate(true)
				plan.query_group = group
				plan.record_tile = 1
				rows.append(_measure(task,plan,id+"/physical/"+str(candidates),false))
		var record: Dictionary = {
			"label":id,"task":task,"candidates":rows,"frontier":_frontier(rows),
			"scope":"All220 distinct one/two-field mappings from same/separate field groups, both field orders and effective copy blocks1..17. All source groups; copy groups1/max only; query tile1 only.",
		}
		physical.append(record)
		print(id+" physical: "+str(rows.size())+" plans, "+str(record.frontier.size())+" sampled frontier classes")
	check(candidates == EXPECTED_CANDIDATES,"Declared1475 candidates")
	check(replays == EXPECTED_REPLAYS,"Declared48 repeat/JSON executions")
	var report: Dictionary = {
		"model":Model.MODEL_VERSION,"candidate_count":candidates,"replay_count":replays,
		"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"failures":failures,
		"scope":"136 structural and1339 physical-layout/scheduling candidates in the unchanged model. New task labels are probe-only; not a catalog or protocol decision. Physical mappings exhaust the stated one/two-field map construction, not all schedule combinations.",
		"scenarios":records,"physical_scenarios":physical,
	}
	var path: String = "user://round6-strategy-probe.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--probe-output="): path = argument.trim_prefix("--probe-output=")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write Round6 probe evidence.")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"round6 structural probe %d candidates, %d repeat/JSON executions, %.3f ms" % [candidates,replays,report.elapsed_ms])
	quit(0 if failures.is_empty() else 1)
