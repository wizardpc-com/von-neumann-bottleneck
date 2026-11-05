extends SceneTree
## Read-only production-model probe. Root runs it inside an isolated QA project.
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const EXPECTED_CANDIDATES: int = 2046
const EXPECTED_REPLAYS: int = 56
const EXPECTED_VALUE_COMPARISONS: int = 16
var failures: Array[String] = []
var candidate_count: int = 0
var replay_count: int = 0
var space_failures: int = 0
var value_comparisons: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _metrics(run: LayoutRun) -> Dictionary:
	return {
		"first":int(run.metrics.first_request_cycles),
		"cycles":int(run.metrics.total_cycles),
		"traffic":int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes),
		"peak":int(run.metrics.peak_extra_bytes),
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
		var key: String = JSON.stringify(row.metrics,"",true)
		if not classes.has(key):
			classes[key] = {"metrics":row.metrics,"plans":[]}
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
		if int(a.metrics.first) != int(b.metrics.first):
			return int(a.metrics.first) < int(b.metrics.first)
		return JSON.stringify(a.metrics,"",true) < JSON.stringify(b.metrics,"",true))
	return result

func _copy_plans(min_fields: int, max_fields: int) -> Array[Dictionary]:
	var plans: Array[Dictionary] = []
	for mask: int in range(1,16):
		var fields: Array[int] = []
		for field: int in range(4):
			if mask & (1 << field): fields.append(field)
		if fields.size() < min_fields or fields.size() > max_fields: continue
		var recipes: Array[Dictionary] = [Recipe.record_major()]
		if fields.size() > 1: recipes.append(Recipe.field_major())
		for recipe: Dictionary in recipes:
			var plan: Dictionary = Model.starter_plan()
			plan.copy_mode = "full"
			plan.copy_fields = fields.duplicate()
			plan.recipe = recipe.duplicate(true)
			plans.append(plan)
	return plans

func _account(task: Dictionary, plan: Dictionary, run: LayoutRun, label: String) -> void:
	var mapping_bytes: int = 0
	if plan.copy_mode == "full":
		mapping_bytes = int(Recipe.mapping(plan.recipe,task.records.size(),0,plan.copy_fields).bytes)
	if mapping_bytes > int(task.scratch_limit):
		check(not run.passed and run.metrics.error == "space_limit",label+" expected space rejection")
		check(int(run.metrics.total_cycles) == 0 and int(run.metrics.ram_write_bytes) == 0,label+" no invented partial copy")
		check(int(run.metrics.first_request_cycles) == -1,label+" incomplete Q1 is unknown")
		space_failures += 1
		return
	var query_values: int = 0
	var jobs: int = 0
	for query: Dictionary in task.queries:
		var count: int = task.records.size() if query.indices.is_empty() else query.indices.size()
		query_values += count*query.fields.size()*int(query.repeat)
		jobs += int(query.repeat)
	var copied: int = task.records.size()*plan.copy_fields.size() if plan.copy_mode == "full" else 0
	var expected: Array[int] = Simulator.expected(task)
	check(run.passed and run.output_values == expected,label+" ordered real outputs")
	check(int(run.metrics.total_cycles) == 2*query_values+expected.size()+10*copied+16*int(run.metrics.fills),label+" cycle accounting")
	check(int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes) == 4*copied+16*int(run.metrics.fills),label+" traffic accounting")
	check(int(run.metrics.peak_extra_bytes) == mapping_bytes,label+" real copy space")
	check(int(run.metrics.first_request_cycles) == int(run.metrics.response_cycles[0]),label+" submitted Q1")
	check(int(run.metrics.response_cycles.max()) == int(run.metrics.total_cycles),label+" makespan")
	var outputs: int = 0
	var writes: int = 0
	var responses: Dictionary = {}
	var admissions: Dictionary = {}
	for event: SimulationEvent in run.events:
		if event.kind == &"output": outputs += 1
		if event.kind == &"write": writes += 1
		if event.kind == &"response":
			var job: int = int(event.details.job_id)
			check(not responses.has(job),label+" unique response")
			responses[job] = event.cycle
		if event.kind == &"request_admitted": admissions[int(event.details.job_id)] = event.cycle
		if event.details.has("job_id"):
			var job: int = int(event.details.job_id)
			check(event.cycle >= int(run.metrics.admission_cycles[job]),label+" causal event")
	check(outputs == expected.size() and int(run.metrics.output_cycles) == expected.size(),label+" output charged once")
	check(writes == copied and responses.size() == jobs and admissions.size() == jobs,label+" real writes and complete jobs")
	for job: int in range(jobs):
		var admitted: int = int(run.metrics.response_cycles[job-1]) if task.release == "serial" and job > 0 else 0
		check(admissions.get(job,-1) == admitted and int(run.metrics.admission_cycles[job]) == admitted,label+" admission rule")
		check(responses.get(job,-1) == int(run.metrics.response_cycles[job]),label+" event-bound response")

func _measure(task: Dictionary, plan: Dictionary, label: String) -> Dictionary:
	var result: Dictionary = Model.evaluate(task,plan)
	candidate_count += 1
	check(result.valid and result.run != null,label+" valid declared plan")
	if not result.valid or result.run == null: return {}
	var run: LayoutRun = result.run
	_account(task,plan,run,label)
	check(run.model_version == Model.MODEL_VERSION and run.case_signature == Model.condition_id(task),label+" condition identity")
	check(run.recipe_signature == Model.plan_id(plan),label+" plan identity")
	var signature: String = run.canonical_signature().sha256_text()
	if int(plan.query_group) == 1 and int(plan.record_tile) == 17 and (plan.copy_mode == "none" or plan.copy_fields in [[0],[0,3]]):
		var repeated: LayoutRun = Model.evaluate(task,plan).run
		var json_run: LayoutRun = Model.evaluate(JSON.parse_string(JSON.stringify(task)),JSON.parse_string(JSON.stringify(plan))).run
		replay_count += 2
		check(repeated.canonical_signature().sha256_text() == signature and json_run.canonical_signature().sha256_text() == signature,label+" repeat and JSON Trace")
	return {
		"plan":plan.duplicate(true),"condition_id":run.case_signature,"plan_id":run.recipe_signature,
		"trace_id":signature,"metrics":_metrics(run),"response_cycles":run.metrics.response_cycles,
		"admission_cycles":run.metrics.admission_cycles,"correct":run.passed,"error":String(run.metrics.error),
	}

func _public_grid(task: Dictionary, label: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var jobs: int = 0
	for query: Dictionary in task.queries: jobs += int(query.repeat)
	var groups: Array = range(1,jobs+1) if task.release == "batch" else [1]
	for group: int in groups:
		var direct_tiles: Array = range(1,18) if task.release == "batch" else [17]
		for tile: int in direct_tiles:
			var plan: Dictionary = Model.starter_plan()
			plan.query_group = group
			plan.record_tile = tile
			rows.append(_measure(task,plan,label+"/source/"+str(group)+"/"+str(tile)))
		var copied_tiles: Array = [1,2,3,4,8,17] if task.release == "batch" else [17]
		for tile: int in copied_tiles:
			for original: Dictionary in _copy_plans(1,2):
				var plan: Dictionary = original.duplicate(true)
				plan.query_group = group
				plan.record_tile = tile
				rows.append(_measure(task,plan,label+"/copy/"+str(candidate_count)))
	# Three/four-field copies are schema-valid UI plans that must fail real 160B allocation.
	for plan: Dictionary in _copy_plans(3,4):
		rows.append(_measure(task,plan,label+"/space/"+str(candidate_count)))
	return rows

func _serial_variations() -> Array[Dictionary]:
	var tasks: Array[Dictionary] = []
	for pattern: String in ["cluster","spread"]:
		var task: Dictionary = Model.scenario("scan_serial")
		task.queries = [{
			"kind":"sum","fields":[0],"repeat":16,
			"indices":[1,2,3] if pattern == "cluster" else [1,8,15],
		}]
		tasks.append({"label":"sparse3_"+pattern+"_serial","task":task,"shipped":false})
	var split: Dictionary = Model.scenario("mixed_serial")
	split.queries = [
		{"kind":"sum","fields":[0],"repeat":4,"indices":[]},
		{"kind":"sum","fields":[3],"repeat":4,"indices":[]},
	]
	tasks.append({"label":"split_hot_fields_serial","task":split,"shipped":false})
	return tasks

func _value_invariance() -> void:
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var changed: Dictionary = task.duplicate(true)
		for record: Array in changed.records:
			for field: int in range(record.size()): record[field] = int(record[field])+1000
		var source: Dictionary = Model.starter_plan()
		var grouped: Dictionary = source.duplicate(true)
		grouped.query_group = 1 if task.release == "serial" else 9 if id.begins_with("mixed") else 8
		grouped.record_tile = 1
		var one: Dictionary = source.duplicate(true)
		one.copy_mode = "full"
		one.copy_fields = [0]
		var pair: Dictionary = source.duplicate(true)
		pair.copy_mode = "full"
		pair.copy_fields = [0,3]
		pair.recipe = Recipe.field_major()
		for plan: Dictionary in [source,grouped,one,pair]:
			var original: LayoutRun = Model.evaluate(task,plan).run
			var varied: LayoutRun = Model.evaluate(changed,plan).run
			var same_metrics: bool = original.metrics == varied.metrics
			var changed_output: bool = original.output_values != varied.output_values
			check(original.passed and varied.passed and same_metrics and changed_output,id+" values-only changes outputs, not performance")
			check(original.case_signature != varied.case_signature,id+" values remain in condition identity")
			value_comparisons.append({
				"label":id,"plan":plan,"metrics_equal":same_metrics,"outputs_changed":changed_output,
				"original_condition":original.case_signature,"changed_condition":varied.case_signature,
				"metrics":_metrics(original),
			})

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Round5 strategy probe requires an isolated QA profile.")
		quit(1)
		return
	var started: int = Time.get_ticks_usec()
	var scenarios: Array[Dictionary] = []
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var rows: Array[Dictionary] = _public_grid(task,id)
		scenarios.append({"label":id,"shipped":true,"task":task,"candidates":rows,"frontier":_frontier(rows)})
	for record: Dictionary in _serial_variations():
		var rows: Array[Dictionary] = []
		var physical: Array[Dictionary] = [Model.starter_plan()]
		physical.append_array(_copy_plans(1,2))
		for plan: Dictionary in physical:
			rows.append(_measure(record.task,plan,record.label+"/"+str(candidate_count)))
		record["candidates"] = rows
		record["frontier"] = _frontier(rows)
		scenarios.append(record)
	_value_invariance()
	check(candidate_count == EXPECTED_CANDIDATES,"Declared2046 candidates complete")
	check(replay_count == EXPECTED_REPLAYS,"Declared56 repeat/JSON executions complete")
	check(value_comparisons.size() == EXPECTED_VALUE_COMPARISONS,"Declared16 value comparisons complete")
	check(space_failures == 40,"Declared40 over-budget UI copies rejected")
	var report: Dictionary = {
		"model":Model.MODEL_VERSION,"candidate_count":candidate_count,"replay_count":replay_count,
		"value_comparison_count":value_comparisons.size(),"value_measurement_count":value_comparisons.size()*2,
		"expected_space_failures":space_failures,"failures":failures,
		"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,
		"scope":"Finite expanded UI sample plus three unshipped serial workload probes; no global optimum or promotion claim.",
		"scenarios":scenarios,"value_comparisons":value_comparisons,
	}
	var output: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--probe-output="): output = argument.trim_prefix("--probe-output=")
	if output.is_empty(): output = "user://round5-strategy-probe.json"
	var file: FileAccess = FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write round5 strategy probe evidence")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for record: Dictionary in scenarios:
		print("%s: %d combinations, %d frontier classes" % [record.label,record.candidates.size(),record.frontier.size()])
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"round5 strategy probe %d candidates, %d expected space failures, %d replays, %d value comparisons, %.3f ms" % [
		candidate_count,space_failures,replay_count,value_comparisons.size(),report.elapsed_ms])
	quit(0 if failures.is_empty() else 1)
