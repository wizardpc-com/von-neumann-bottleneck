extends SceneTree
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
var failures: Array[String] = []
var replay_count: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _metrics(run: LayoutRun) -> Dictionary:
	return {
		"first":int(run.metrics.first_request_cycles),"cycles":int(run.metrics.total_cycles),
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
		var dominated: bool = false
		for other: Dictionary in rows:
			if _dominates(other.metrics,row.metrics):
				dominated = true
				break
		if dominated: continue
		var key: String = JSON.stringify(row.metrics)
		if not classes.has(key): classes[key] = {"metrics":row.metrics,"plans":[]}
		classes[key].plans.append(row.plan)
	var result: Array[Dictionary] = []
	for value: Dictionary in classes.values(): result.append(value)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.metrics.first)<int(b.metrics.first))
	return result

func _account(task: Dictionary, plan: Dictionary, run: LayoutRun, label: String) -> void:
	var query_values: int = 0
	for query: Dictionary in task.queries:
		var count: int = task.records.size() if query.indices.is_empty() else query.indices.size()
		query_values += count*query.fields.size()*int(query.repeat)
	var copied: int = task.records.size()*plan.copy_fields.size() if plan.copy_mode == "full" else 0
	var metrics: Dictionary = run.metrics
	var expected: Array[int] = Simulator.expected(task)
	check(run.passed and run.output_values == expected,label+" correct ordered outputs")
	check(int(metrics.total_cycles) == 2*query_values+expected.size()+10*copied+16*int(metrics.fills),label+" cycle accounting")
	check(int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes) == 4*copied+16*int(metrics.fills),label+" traffic accounting")
	check(int(metrics.first_request_cycles) == int(metrics.response_cycles[0]),label+" public job0 response")
	check(int(metrics.response_cycles.max()) == int(metrics.total_cycles),label+" final makespan")
	var outputs: int = 0
	var writes: int = 0
	var responses: Dictionary = {}
	var admissions: Dictionary = {}
	for event: SimulationEvent in run.events:
		if event.kind == &"output": outputs += 1
		if event.kind == &"write": writes += 1
		if event.kind == &"response":
			var job: int = int(event.details.job_id)
			check(not responses.has(job),label+" one response per job")
			responses[job] = event.cycle
		if event.kind == &"request_admitted": admissions[int(event.details.job_id)] = event.cycle
		if event.details.has("job_id"):
			var job: int = int(event.details.job_id)
			check(event.cycle >= int(metrics.admission_cycles[job]),label+" causal job event")
	check(outputs == expected.size() and int(metrics.output_cycles) == expected.size(),label+" each real output charged once")
	check(writes == copied,label+" actual copy writes")
	check(responses.size() == int(metrics.job_count) and admissions.size() == responses.size(),label+" complete job markers")
	for job: int in range(int(metrics.job_count)):
		check(responses.get(job,-1) == int(metrics.response_cycles[job]),label+" response event binds metric")
		var admission: int = int(metrics.response_cycles[job-1]) if task.release == "serial" and job>0 else 0
		check(admissions.get(job,-1) == admission and int(metrics.admission_cycles[job]) == admission,label+" declared admission")

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Production grid requires an isolated QA profile.")
		quit(1)
		return
	var started: int = Time.get_ticks_usec()
	var tasks: Array[Dictionary] = []
	for id: String in Model.SCENARIO_IDS:
		tasks.append({"label":id,"task":Model.scenario(id),"shipped":true})
	for release: String in ["batch","serial"]:
		var task: Dictionary = Model.scenario("scan_"+release)
		task.queries[0].repeat = 16
		tasks.append({"label":"scan16_"+release,"task":task,"shipped":false})
	var physical: Array[Dictionary] = [{"copy_mode":"none","copy_fields":[0],"recipe":Recipe.record_major()}]
	for fields: Array in [[0],[0,3],[1,2]]:
		for recipe: Dictionary in [Recipe.record_major(),Recipe.field_major()]:
			physical.append({"copy_mode":"full","copy_fields":fields,"recipe":recipe})
	var records: Array[Dictionary] = []
	var candidate_count: int = 0
	for record: Dictionary in tasks:
		var task: Dictionary = record.task
		var groups: Array = [1]
		if task.release == "batch":
			groups = [1,2,4,8,9] if String(record.label).begins_with("mixed") else [1,2,4,8,16] if String(record.label).begins_with("scan16") else [1,2,4,8]
		var rows: Array[Dictionary] = []
		for group: int in groups:
			for tile: int in [1,2,4,8,17]:
				for copy: Dictionary in physical:
					var plan: Dictionary = Model.starter_plan()
					plan.merge(copy,true)
					plan.query_group = group
					plan.record_tile = tile
					var result: Dictionary = Model.evaluate(task,plan)
					var label: String = String(record.label)+"/"+str(candidate_count)
					candidate_count += 1
					check(result.valid and result.run != null,label+" valid actual run")
					if not result.valid or result.run == null: continue
					var run: LayoutRun = result.run
					_account(task,plan,run,label)
					var signature: String = run.canonical_signature().sha256_text()
					if tile == 1 and (group == groups[0] or group == groups[-1]) and copy.copy_fields in [[0],[0,3]]:
						var repeat: LayoutRun = Model.evaluate(task,plan).run
						var json_run: LayoutRun = Model.evaluate(JSON.parse_string(JSON.stringify(task)),JSON.parse_string(JSON.stringify(plan))).run
						replay_count += 2
						check(repeat.canonical_signature().sha256_text() == signature and json_run.canonical_signature().sha256_text() == signature,label+" deterministic and JSON Trace")
					rows.append({
						"plan":plan.duplicate(true),"condition_id":run.case_signature,
						"plan_id":run.recipe_signature,"trace_id":signature,
						"metrics":_metrics(run),"response_cycles":run.metrics.response_cycles,
						"admission_cycles":run.metrics.admission_cycles,"correct":run.passed,
					})
		records.append({"label":record.label,"shipped":record.shipped,"task":task,"candidates":rows,"frontier":_frontier(rows)})
	var output: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--grid-output="): output = argument.trim_prefix("--grid-output=")
	if output.is_empty(): output = "user://layout-scheduling-grid.json"
	var report: Dictionary = {
		"model":Model.MODEL_VERSION,"candidate_count":candidate_count,"replay_count":replay_count,
		"elapsed_ms":(Time.get_ticks_usec()-started)/1000.0,"failures":failures,
		"scope":"Finite declared group/tile/physical-plan sample, not global optimization.",
		"scenarios":records,
	}
	check(candidate_count == 595,"Declared595-candidate grid is complete")
	var file: FileAccess = FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write production grid evidence")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"production scheduling grid %d candidates, %d replays, %.3f ms" % [candidate_count,replay_count,report.elapsed_ms])
	quit(0 if failures.is_empty() else 1)
