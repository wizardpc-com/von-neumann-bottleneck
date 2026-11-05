extends SceneTree
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
var failures: Array[String] = []
var measured: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func metrics(run: LayoutRun) -> Dictionary:
	return {"first":int(run.metrics.first_request_cycles),"cycles":int(run.metrics.total_cycles),
		"traffic":int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes),
		"peak":int(run.metrics.peak_extra_bytes)}

func measure(task: Dictionary, plan: Dictionary, origin: String) -> Dictionary:
	var result: Dictionary = Model.evaluate(task,plan)
	measured += 1
	check(result.valid and result.run != null,origin+" valid")
	if not result.valid or result.run == null: return {}
	var run: LayoutRun = result.run
	check(run.passed and run.output_values == Simulator.expected(task),origin+" exact ordered outputs")
	check(run.case_signature == Model.condition_id(task),origin+" condition")
	var q: int = 0
	for query: Dictionary in task.queries:
		q += (task.records.size() if query.indices.is_empty() else query.indices.size())*query.fields.size()*int(query.repeat)
	var m: int = task.records.size()*plan.copy_fields.size() if plan.copy_mode == "full" else 0
	check(run.metrics.total_cycles == 2*q+run.output_values.size()+10*m+16*int(run.metrics.fills),origin+" accounting")
	return {"plan":Model.normalize_plan(plan),"metrics":metrics(run),
		"condition":run.case_signature,"trace":run.canonical_signature().sha256_text(),"origin":origin}

func dominates(a: Dictionary, b: Dictionary) -> bool:
	var strict: bool = false
	for key: String in ["first","cycles","traffic","peak"]:
		if a[key] > b[key]: return false
		strict = strict or a[key] < b[key]
	return strict

func frontier(rows: Array[Dictionary]) -> Array[Dictionary]:
	var unique: Dictionary = {}
	for row: Dictionary in rows:
		if not row.is_empty() and not unique.has(JSON.stringify(row.metrics,"",true)):
			unique[JSON.stringify(row.metrics,"",true)] = row
	var result: Array[Dictionary] = []
	for row: Dictionary in unique.values():
		var beaten: bool = false
		for other: Dictionary in unique.values():
			if dominates(other.metrics,row.metrics): beaten = true; break
		if not beaten: result.append(row)
	return result

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		quit(2)
		return
	var before: int = Time.get_ticks_usec()
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://docs/verification/20261104-layout-notebook/strategy/strategy-results.json"))
	var scenarios: Array[Dictionary] = []
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var rows: Array[Dictionary] = []
		var baseline: Array[Dictionary] = []
		for known: Dictionary in old.scenarios:
			if known.label != id: continue
			for point: Dictionary in known.frontier:
				var row: Dictionary = measure(task,point.plans[0],"prior frontier")
				for key: String in row.metrics:
					check(row.metrics[key] == int(point.metrics[key]),id+" prior frontier reproduced "+key)
				rows.append(row)
				baseline.append(row)
		var jobs: int = 0
		for query: Dictionary in task.queries: jobs += int(query.repeat)
		var groups: Array = [1,jobs] if task.release == "batch" else [1]
		var tiles: Array = [1,4,17] if task.release == "batch" else [17]
		for mask: int in range(1,16):
			var fields: Array[int] = []
			for field: int in range(4):
				if mask & (1 << field): fields.append(field)
			if fields.size() != 2: continue
			for block: int in [0,1,2,3,4,5,6,7,8,9,12,16,17]:
				for group: int in groups:
					for tile: int in tiles:
						var plan: Dictionary = Model.starter_plan()
						plan.copy_mode = "full"
						plan.copy_fields = fields.duplicate()
						plan.recipe = Recipe.field_major()
						plan.recipe.block = block
						plan.query_group = group
						plan.record_tile = tile
						rows.append(measure(task,plan,"copy block"))
		var best: Array[Dictionary] = frontier(rows)
		for row: Dictionary in best:
			var replayed: Dictionary = measure(task,row.plan,"frontier repeat")
			var json_run: Dictionary = measure(JSON.parse_string(JSON.stringify(task)),JSON.parse_string(JSON.stringify(row.plan)),"frontier JSON")
			check(replayed.metrics == row.metrics and replayed.trace == row.trace and json_run.trace == row.trace,id+" repeat/JSON complete Trace")
		scenarios.append({"id":id,"baseline":baseline,"candidates":rows.size(),"frontier":best})
	var output: Dictionary = {"measured":measured,"elapsed_ms":float(Time.get_ticks_usec()-before)/1000.0,
		"scenarios":scenarios,"failures":failures,"scope":"Finite copy-block probe and freshly remeasured prior frontier representatives; not global optimum."}
	var file := FileAccess.open("user://copy-probe.json",FileAccess.WRITE)
	check(file != null,"output opens")
	if file != null:
		file.store_string(JSON.stringify(output,"  ",true))
		file.close()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"copy block probe measured=%d failures=%d" % [measured,failures.size()])
	print("RESULT: "+ProjectSettings.globalize_path("user://copy-probe.json"))
	quit(0 if failures.is_empty() else 1)
