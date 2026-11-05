extends "res://tests/test_layout_strategy_model.gd"
## New fixed inputs reuse the original authoritative accounting/causality checks.
const StructuralGoals = preload("res://experiments/layout_strategy/goals.gd")
const NEW_IDS: Array[String] = ["scan_pair_serial","split_fields_serial"]
var structural_rows: Array[Dictionary] = []


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for structural workload checks.")
		quit(1)
		return
	_definitions()
	_structural_grid()
	_exact_measurements()
	_objectives_and_caps()
	_request_order()
	_structural_failures()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+
		"layout strategy structures %d checks, %d measurements, %d failures" %
		[checks,measured_count,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _definitions() -> void:
	var expected_queries: Dictionary = {
		"scan_pair_serial":[{"kind":"sum","fields":[0],"repeat":2,"indices":[]}],
		"split_fields_serial":[
			{"kind":"sum","fields":[0],"repeat":4,"indices":[]},
			{"kind":"sum","fields":[3],"repeat":4,"indices":[]},
		],
	}
	var expected_outputs: Dictionary = {
		"scan_pair_serial":[363,363],
		"split_fields_serial":[363,363,363,363,8,8,8,8],
	}
	var conditions: Array[String] = []
	for id: String in Model.SCENARIO_IDS:
		var condition: String = Model.condition_id(Model.scenario(id))
		check(condition.length() == 64 and condition not in conditions,"Each fixed workload has a distinct complete condition: "+id)
		conditions.append(condition)
	for id: String in NEW_IDS:
		var task: Dictionary = Model.scenario(id)
		check(task.keys().size() == 5 and task.id == id and task.release == "serial" and task.scratch_limit == 160,"New task has exact independent identity/admission/space: "+id)
		check(task.records == Catalog.records(17) and task.queries == expected_queries[id],"New fixed records and ordered requests match the authored structure.")
		check(Simulator.expected(task) == expected_outputs[id],"Independent ordered oracle has the exact public outputs.")
		check(Model.validate(task,Model.starter_plan()).is_empty(),"Unoptimized ordinary starter executes the new workload.")
		task.queries[0].repeat = 1
		task.records[0][0] = 0
		check(Model.scenario(id).queries == expected_queries[id] and Model.scenario(id).records == Catalog.records(17),"New authored inputs are detached from caller mutation.")
	check(Model.MODEL_VERSION == "layout-schedule-experiment-1","Content addition does not relabel unchanged execution rules.")
	check(StructuralGoals.default_goal() == {"objective":"cycles","first_limit":-1,"copy_limit":-1},"Structural tasks do not impose hidden personal caps or objectives.")


func _copy_plan(fields: Array, field_major: bool = false) -> Dictionary:
	var plan: Dictionary = Model.starter_plan()
	if not fields.is_empty():
		plan.copy_mode = "full"
		plan.copy_fields = fields.duplicate()
		plan.recipe = Recipe.field_major() if field_major else Recipe.record_major()
	return plan


func _structural_grid() -> void:
	var plans: Array[Dictionary] = [Model.starter_plan()]
	for mask: int in range(1,16):
		var fields: Array[int] = []
		for field: int in range(4):
			if mask & (1 << field): fields.append(field)
		if fields.size() > 2: continue
		plans.append(_copy_plan(fields))
		if fields.size() == 2: plans.append(_copy_plan(fields,true))
	check(plans.size() == 17,"Declared structural grid has17 direct/basic physical choices.")
	for id: String in NEW_IDS:
		var task: Dictionary = Model.scenario(id)
		for index: int in range(plans.size()):
			var task_before: Dictionary = task.duplicate(true)
			var plan_before: Dictionary = plans[index].duplicate(true)
			var run: LayoutRun = _measure(task,plans[index],id+"/grid/"+str(index))
			if run != null: _check_run(task,plans[index],run)
			check(task == task_before and plans[index] == plan_before,"Physical execution preserves both authored task and caller recipe.")


func _cases() -> Array[Dictionary]:
	return [
		{
			"id":"pair/direct","task":"scan_pair_serial","probe_task":"scan_serial","fields":[],
			"first":307,"cycles":614,"traffic":544,"peak":0,"responses":[307,614],
			"probe_trace":"9f030594fa09d229c6c2769e486fce8ef36a23a76c6e8c134b26ff8ae3353317",
		},
		{
			"id":"pair/temperature","task":"scan_pair_serial","probe_task":"scan_serial","fields":[0],
			"first":557,"cycles":672,"traffic":500,"peak":80,"responses":[557,672],
			"probe_trace":"a7b4ae451f5c6c7352bc119d8dac6cabc98e5546f173221c00239bc5b8b26f47",
		},
		{
			"id":"phased/direct","task":"split_fields_serial","probe_task":"mixed_serial","fields":[],
			"first":307,"cycles":2456,"traffic":2176,"peak":0,"responses":[307,614,921,1228,1535,1842,2149,2456],
			"probe_trace":"fa725fc8030db62557bcc57fddd3635592042a069f20f110f2749e6e7466c4e7",
		},
		{
			"id":"phased/temperature","task":"split_fields_serial","probe_task":"mixed_serial","fields":[0],
			"first":557,"cycles":2130,"traffic":1748,"peak":80,"responses":[557,672,787,902,1209,1516,1823,2130],
			"probe_trace":"ad3cd741770dd78b1b4dc7f69d39220a2a360dc01b9413256d8440310061d75d",
		},
		{
			"id":"phased/alarm","task":"split_fields_serial","probe_task":"mixed_serial","fields":[3],
			"first":749,"cycles":2130,"traffic":1748,"peak":80,"responses":[749,1056,1363,1670,1785,1900,2015,2130],
			"probe_trace":"1a56fd7df5ca322726d86ac120d6f276732c3ad297b9fb36b5821169a66a4c27",
		},
		{
			"id":"phased/record","task":"split_fields_serial","probe_task":"mixed_serial","fields":[0,3],
			"first":791,"cycles":2044,"traffic":1560,"peak":144,"responses":[791,970,1149,1328,1507,1686,1865,2044],
			"probe_trace":"7c59a6dc84f6e8477ec3f062f6c6fc66647a38dc86de94e252115a4d64f96792",
		},
		{
			"id":"phased/field","task":"split_fields_serial","probe_task":"mixed_serial","fields":[0,3],"field_major":true,
			"first":727,"cycles":1516,"traffic":1032,"peak":144,"responses":[727,842,957,1072,1171,1286,1401,1516],
			"probe_trace":"5c4f2cb9b0951aa11dc8d232d1d8cabf44e44b7a6527cb542f8414be4e1752fa",
		},
	]


func _event_data(run: LayoutRun) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for event: SimulationEvent in run.events: events.append(event.to_dictionary())
	return events


func _exact_measurements() -> void:
	for sample: Dictionary in _cases():
		var task: Dictionary = Model.scenario(sample.task)
		var plan: Dictionary = _copy_plan(sample.fields,bool(sample.get("field_major",false)))
		var run: LayoutRun = _measure(task,plan,sample.id)
		if run == null: continue
		_check_run(task,plan,run)
		check(run.metrics.first_request_cycles == sample.first and run.metrics.total_cycles == sample.cycles,"Exact Q1/total measurement: "+sample.id)
		check(run.metrics.ram_read_bytes+run.metrics.ram_write_bytes == sample.traffic and run.metrics.peak_extra_bytes == sample.peak,"Exact traffic/physical allocation: "+sample.id)
		check(run.metrics.response_cycles == sample.responses,"Every expected response has its observed causal cycle: "+sample.id)
		structural_rows.append({
			"id":sample.id,"condition_id":run.case_signature,
			"correct":run.passed,"metrics":run.metrics.duplicate(true),
		})
		var repeated: LayoutRun = _measure(task,plan,sample.id+"/repeat")
		var json_run: LayoutRun = _measure(JSON.parse_string(JSON.stringify(task)),JSON.parse_string(JSON.stringify(plan)),sample.id+"/json")
		if repeated != null and json_run != null:
			check(repeated.canonical_signature() == run.canonical_signature() and json_run.canonical_signature() == run.canonical_signature(),"Complete new-ID Trace repeats and survives JSON: "+sample.id)
		var probe_task: Dictionary = task.duplicate(true)
		probe_task.id = sample.probe_task
		var probe: LayoutRun = _measure(probe_task,plan,sample.id+"/historical-probe")
		if probe != null:
			check(probe.canonical_signature().sha256_text() == sample.probe_trace,"Historical measured structure retains its frozen full Trace: "+sample.id)
			check(_event_data(run) == _event_data(probe) and run.metrics == probe.metrics,"New fixed ID preserves every actual event and metric.")
			check(run.output_values == probe.output_values and run.expected_values == probe.expected_values and run.source_map == probe.source_map and run.scratch_maps == probe.scratch_maps,"New fixed ID preserves all ordered data and physical maps.")
			check(run.test_name == sample.task and probe.test_name == sample.probe_task and run.case_signature != probe.case_signature and run.recipe_signature == probe.recipe_signature,"Only task naming/full condition deliberately changes, with the same measured plan.")
			check(run.canonical_signature() != probe.canonical_signature(),"A new catalog condition never impersonates the probe-only old-ID Trace.")
		for tile: int in [1,4,64]:
			var tiled: Dictionary = plan.duplicate(true)
			tiled.record_tile = tile
			var tile_run: LayoutRun = _measure(task,tiled,sample.id+"/tile"+str(tile))
			if tile_run == null: continue
			_check_run(task,tiled,tile_run)
			check(tile_run.metrics == run.metrics and tile_run.output_values == run.output_values,"Serial full-scan tiling preserves real costs and output.")
			check(tile_run.recipe_signature != run.recipe_signature and tile_run.canonical_signature() != run.canonical_signature(),"Preserved tile choice still binds its own plan/Trace identity.")


func _named(id: String) -> Dictionary:
	for row: Dictionary in structural_rows:
		if row.id == id: return row.duplicate(true)
	return {}


func _rank(rows: Array[Dictionary], task_id: String, objective: String, first: int, copy: int) -> Array[Dictionary]:
	return StructuralGoals.rank(rows,Model.condition_id(Model.scenario(task_id)),{
		"objective":objective,"first_limit":first,"copy_limit":copy,
	})


func _objectives_and_caps() -> void:
	if structural_rows.size() != 7:
		check(false,"All seven genuine measurements are required for goal tests.")
		return
	var pair: Array[Dictionary] = [_named("pair/direct"),_named("pair/temperature")]
	var cycles: Array[Dictionary] = _rank(pair,"scan_pair_serial","cycles",600,80)
	var traffic: Array[Dictionary] = _rank(pair,"scan_pair_serial","traffic",600,80)
	check(cycles[0].id == "pair/direct" and cycles[0].rank == 1 and cycles[1].rank == 2,"Two scans favor actual direct cycles under the shared600/80 envelope.")
	check(traffic[0].id == "pair/temperature" and traffic[0].rank == 1 and traffic[1].rank == 2,"The same eligible runs favor actual copied RAM traffic.")
	var only_copy: Array[Dictionary] = [_named("pair/temperature")]
	check(not _rank(only_copy,"scan_pair_serial","traffic",556,80)[0].eligible,"556 excludes the actual557-cycle Q1.")
	check(_rank(only_copy,"scan_pair_serial","traffic",557,80)[0].eligible,"557 includes the actual Q1 boundary.")
	check(not _rank(only_copy,"scan_pair_serial","traffic",600,79)[0].eligible,"79 excludes the padded80-byte copy allocation.")
	var singles: Array[Dictionary] = [_named("phased/temperature"),_named("phased/alarm")]
	var ties: Array[Dictionary] = _rank(singles,"split_fields_serial","cycles",-1,-1)
	check(ties[0].rank == 1 and ties[1].rank == 1,"Equal actual totals tie despite different first responses.")
	check(_rank(singles,"split_fields_serial","cycles",600,80)[1].exclusions == ["first"],"Request order is visible when Q1 is constrained.")
	var field: Array[Dictionary] = [_named("phased/field")]
	check(not _rank(field,"split_fields_serial","cycles",726,144)[0].eligible,"726 excludes the actual727-cycle phased response.")
	check(_rank(field,"split_fields_serial","cycles",727,144)[0].eligible,"727/144 includes the exact phased copy boundaries.")
	check(not _rank(field,"split_fields_serial","cycles",800,143)[0].eligible,"143 cannot conceal the144-byte pair allocation.")
	check(not _rank(pair,"scan_serial","cycles",-1,-1)[0].eligible,"Actual new-task rows cannot enter a legacy condition bucket.")


func _request_order() -> void:
	var task: Dictionary = Model.scenario("split_fields_serial")
	var original_condition: String = Model.condition_id(task)
	var reversed_queries: Array = task.queries.duplicate(true)
	reversed_queries.reverse()
	task.queries = reversed_queries
	var plan: Dictionary = _copy_plan([0])
	var reversed: LayoutRun = _measure(task,plan,"alarm-before-temperature")
	if reversed == null: return
	_check_run(task,plan,reversed)
	check(reversed.output_values == [8,8,8,8,363,363,363,363],"Reordered requests retain authored output positions.")
	check(reversed.case_signature != original_condition,"Request order participates in full condition identity.")
	check(reversed.metrics.first_request_cycles == 749 and reversed.metrics.total_cycles == 2130,"Moving temperature requests later changes real Q1 but retains measured total.")
	check(Model.scenario("split_fields_serial").queries[0].fields == [0],"Custom audit execution cannot mutate the fixed catalog.")


func _structural_failures() -> void:
	for id: String in NEW_IDS:
		var task: Dictionary = Model.scenario(id)
		var plan: Dictionary = Model.starter_plan()
		_reject(task,_changed(plan,"query_group",2),"serial_group","New serial work cannot admit grouped future requests")
		var jobs: int = 2 if id == "scan_pair_serial" else 8
		_reject(task,_changed(plan,"query_group",jobs+1),"query_group","Group cannot exceed actual new request count")
		for fields: Array in [[0,1,2],[0,1,2,3]]:
			var oversized: Dictionary = _copy_plan(fields)
			var measured: Dictionary = Model.evaluate(task,oversized)
			measured_count += 1
			check(measured.valid and measured.run is LayoutRun and measured.error == "space_limit","Oversized copying executes a genuine failed allocation trace.")
			if not measured.valid or not measured.run is LayoutRun: continue
			var failed: LayoutRun = measured.run
			check(not failed.passed and failed.metrics.peak_extra_bytes == 0 and failed.metrics.ram_write_bytes == 0,"Failed allocation claims no copy or complete work.")
			check(failed.metrics.first_request_cycles == -1 and failed.metrics.response_cycles.size() == jobs and failed.metrics.response_cycles.count(-1) == jobs,"Every unfinished response remains unknown.")
			check(failed.metrics.admission_cycles[0] == 0 and failed.metrics.admission_cycles.count(-1) == jobs-1,"Allocation failure cannot admit future serial requests.")
			var rows: Array[Dictionary] = [{"id":"failed","correct":failed.passed,"condition_id":failed.case_signature,"metrics":failed.metrics}]
			check(not _rank(rows,id,"cycles",-1,-1)[0].eligible,"Zero partial cycles never win a structural comparison.")
