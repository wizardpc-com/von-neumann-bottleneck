extends SceneTree
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Code = preload("res://src/layout_chapter/layout_challenge_code.gd")
var failures: Array[String] = []
var checks: int = 0
var measured_count: int = 0


func _init() -> void: call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	_public_contract()
	_measurement_grid()
	_real_tradeoffs()
	_sparse_and_duplicate_outputs()
	_failures_and_reuse()
	_strict_inputs()
	_identity_and_legacy()
	print("LAYOUT_STRATEGY_MODEL checks=%d measured=%d failures=%d" % [checks,measured_count,failures.size()])
	if failures.is_empty(): print("PASS: independent scheduling, real copy costs, response causality, strict bounds and model identity")
	quit(0 if failures.is_empty() else 1)


func _public_contract() -> void:
	check(Model.scenario("unknown").is_empty(),"Unknown scenario does not manufacture a workload.")
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var source: Dictionary = Catalog.cases("mixed" if id.begins_with("mixed") else "batches")[0]
		check(task.size() == 5 and task.records == source.records and task.scratch_limit == 160,"Public "+id+" uses real declared data and scratch.")
		check(Simulator.expected(task) == Simulator.expected(source),"Public "+id+" retains the logical workload.")
		check(not task.has("target_cycles") and not task.has("target_bytes") and not task.has("native_layout"),"No old target/progression authority enters "+id+".")
		check(Model.validate(task,Model.starter_plan()).is_empty(),"Source-only starter is valid for "+id+".")
		task.records[0][0] += 1
		check(Model.scenario(id).records == source.records,"Scenario data is detached from callers.")
	var plan: Dictionary = Model.starter_plan()
	plan.recipe.groups[0].fields.reverse()
	check(Model.starter_plan().recipe == Recipe.record_major(),"Starter recipe is detached.")


func _measurement_grid() -> void:
	var plans: Array[Dictionary] = [Model.starter_plan()]
	for fields: Array in [[0],[0,3],[1,2]]:
		var plan: Dictionary = Model.starter_plan()
		plan.copy_mode = "full"
		plan.copy_fields = fields.duplicate()
		plan.recipe = Recipe.field_major()
		plans.append(plan)
	for id: String in Model.SCENARIO_IDS:
		var task: Dictionary = Model.scenario(id)
		var groups: Array[int] = [1]
		if task.release == "batch": groups.append(9 if id.begins_with("mixed") else 8)
		for group: int in groups:
			for tile: int in [1,2,4,8,17,64]:
				for original: Dictionary in plans:
					var plan: Dictionary = original.duplicate(true)
					plan.query_group = group
					plan.record_tile = tile
					var run: LayoutRun = _measure(task,plan,"%s/g%d/t%d/%s/%s" % [id,group,tile,plan.copy_mode,str(plan.copy_fields)])
					if run != null: _check_run(task,plan,run)
		var stable_plan: Dictionary = plans[2].duplicate(true)
		stable_plan.record_tile = 4
		var first: LayoutRun = _measure(task,stable_plan,"stable "+id)
		var restored_task: Dictionary = JSON.parse_string(JSON.stringify(task))
		var restored_plan: Dictionary = JSON.parse_string(JSON.stringify(stable_plan))
		var restored: LayoutRun = _measure(restored_task,restored_plan,"JSON "+id)
		if first != null and restored != null:
			check(first.canonical_signature() == restored.canonical_signature(),"JSON preserves every event, response and identity for "+id+".")


func _real_tradeoffs() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var direct: Dictionary = Model.starter_plan()
	var tiled: Dictionary = direct.duplicate(true)
	tiled.query_group = 8
	tiled.record_tile = 1
	var direct_run: LayoutRun = _measure(task,direct,"ready request-by-request")
	var tiled_run: LayoutRun = _measure(task,tiled,"ready fused source tiles")
	if direct_run != null and tiled_run != null:
		check(direct_run.metrics.first_request_cycles == 307 and direct_run.metrics.total_cycles == 2456,"Direct ready scan has the independently measured307/2456 result.")
		check(tiled_run.metrics.first_request_cycles == 531 and tiled_run.metrics.total_cycles == 552,"Fused source scan has the independently measured531/552 result.")
		check(tiled_run.metrics.first_request_cycles > direct_run.metrics.first_request_cycles and tiled_run.metrics.total_cycles < direct_run.metrics.total_cycles,"Actual batching trades first-request latency for total work.")
	task = Model.scenario("scan_serial")
	var copied: Dictionary = direct.duplicate(true)
	copied.copy_mode = "full"
	copied.copy_fields = [0]
	copied.recipe = Recipe.field_major()
	var copied_run: LayoutRun = _measure(task,copied,"serial retained projection")
	direct_run = _measure(task,direct,"serial source only")
	if copied_run != null and direct_run != null:
		check(copied_run.metrics.first_request_cycles == 557 and copied_run.metrics.total_cycles == 1362 and copied_run.metrics.peak_extra_bytes == 80,"Retained serial copy has measured557/1362/80 result.")
		check(copied_run.metrics.first_request_cycles > direct_run.metrics.first_request_cycles and copied_run.metrics.total_cycles < direct_run.metrics.total_cycles,"Real preparation pays up front and reuses physical words later.")


func _sparse_and_duplicate_outputs() -> void:
	var task: Dictionary = Model.scenario("mixed_batch")
	task.queries = [
		{"kind":"sum","fields":[0],"repeat":1,"indices":[]},
		{"kind":"records","fields":[0,3],"repeat":1,"indices":[0]},
	]
	var plan: Dictionary = Model.starter_plan()
	plan.query_group = 2
	plan.record_tile = 1
	var sparse: LayoutRun = _measure(task,plan,"sparse response before group end")
	if sparse != null:
		_check_run(task,plan,sparse)
		check(sparse.metrics.response_cycles[1] < sparse.metrics.response_cycles[0],"Sparse job responds before dense job0 finishes.")
		check(sparse.metrics.first_request_cycles == sparse.metrics.response_cycles[0],"Q1 means public job0, not the earliest cheap response.")
	task.queries = [
		{"kind":"records","fields":[3,0,3],"repeat":2,"indices":[16,0,16,3]},
		{"kind":"sum","fields":[0,0],"repeat":1,"indices":[16,1,16]},
	]
	for tile: int in [1,4,17,64]:
		plan.query_group = 3
		plan.record_tile = tile
		for copy_mode: String in ["none","full"]:
			plan.copy_mode = copy_mode
			plan.copy_fields = [0,3]
			plan.recipe = {"groups":[{"fields":[3,0],"order":"field"},{"fields":[1,2],"order":"record"}],"block":4}
			var duplicate: LayoutRun = _measure(task,plan,"duplicate/nonmonotone/tail "+copy_mode+str(tile))
			if duplicate != null: _check_run(task,plan,duplicate)
	var one: Dictionary = Model.scenario("scan_serial")
	one.records = [[7,8,9,10]]
	one.queries = [{"kind":"records","fields":[3,0],"repeat":1,"indices":[0,0]}]
	plan = Model.starter_plan()
	plan.copy_mode = "full"
	plan.copy_fields = [0,3]
	var single: LayoutRun = _measure(one,plan,"single-record duplicate output")
	if single != null: _check_run(one,plan,single)
	var maximum: Dictionary = Model.scenario("scan_batch")
	maximum.records = Catalog.records(64)
	maximum.queries = [{"kind":"records","fields":[0,1,2,3],"repeat":16,"indices":[]}]
	plan = Model.starter_plan()
	plan.query_group = 16
	plan.record_tile = 7
	var max_run: LayoutRun = _measure(maximum,plan,"maximum4096 query/output values")
	if max_run != null:
		_check_run(maximum,plan,max_run)
		check(max_run.output_values.size() == Model.MAX_OUTPUT_VALUES and max_run.events.size() < Model.MAX_TRACE_EVENTS,"Declared maximum workload stays bounded without truncating output or evidence.")


func _failures_and_reuse() -> void:
	var task: Dictionary = Model.scenario("scan_serial")
	var plan: Dictionary = Model.starter_plan()
	plan.copy_mode = "full"
	plan.copy_fields = [0]
	plan.recipe = Recipe.field_major()
	task.scratch_limit = 0
	var result: Dictionary = Model.evaluate(task,plan)
	check(result.valid and result.error == "space_limit" and result.run is LayoutRun,"Allocation failure is an executed failed trace, not schema rejection.")
	var failed: LayoutRun = result.run
	check(not failed.passed and failed.metrics.peak_extra_bytes == 0 and failed.metrics.ram_write_bytes == 0,"Failed allocation claims no completed copy or traffic.")
	check(failed.metrics.first_request_cycles == -1 and failed.metrics.response_cycles == [-1,-1,-1,-1,-1,-1,-1,-1],"Unfinished responses stay unknown.")
	check(failed.metrics.admission_cycles == [0,-1,-1,-1,-1,-1,-1,-1],"Serial allocation failure does not admit later requests.")
	check(failed.model_version == Model.MODEL_VERSION and failed.case_signature == Model.condition_id(task) and failed.recipe_signature == Model.plan_id(plan),"Failed run retains experiment identity.")
	check(failed.events[-1].kind == &"error" and failed.events[-1].details.error == "space_limit","Failure is present in authoritative evidence.")
	var executor := Model.Executor.new()
	executor.measure(task,plan)
	task = Model.scenario("mixed_batch")
	plan = Model.starter_plan()
	plan.query_group = 9
	plan.record_tile = 2
	var reused: LayoutRun = executor.measure(task,plan)
	var fresh: LayoutRun = Model.Executor.new().measure(task,plan)
	check(reused.canonical_signature() == fresh.canonical_signature(),"Executor reuse resets failed state, admissions, jobs, tiles and responses.")
	executor.measure(Model.scenario("scan_serial"),Model.starter_plan())
	var repeated: LayoutRun = executor.measure(task,plan)
	check(repeated.canonical_signature() == fresh.canonical_signature(),"Success-to-success reuse also resets the complete schedule.")


func _strict_inputs() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var plan: Dictionary = Model.starter_plan()
	for field: String in Model.TASK_KEYS:
		var missing: Dictionary = task.duplicate(true)
		missing.erase(field)
		_reject(missing,plan,"task","Missing scenario "+field)
	for field: String in Model.PLAN_KEYS:
		var missing: Dictionary = plan.duplicate(true)
		missing.erase(field)
		_reject(task,missing,"plan","Missing plan "+field)
	_reject(_changed(task,"future",1),plan,"task","Unknown scenario field")
	_reject(task,_changed(plan,"score",1),"plan","Externally claimed score")
	for value: Variant in ["","unknown",true,1]:
		_reject(_changed(task,"id",value),plan,"task","Unknown scenario identity")
	for value: Variant in ["unknown",true,1]:
		_reject(_changed(task,"release",value),plan,"release","Unknown release rule")
	for value: Variant in [-1,4097,0.5,true,"160",null,INF,NAN]:
		_reject(_changed(task,"scratch_limit",value),plan,"scratch_limit","Invalid scratch limit")
	for value: Variant in [[],[[]],[[1,2,3]],[[1,2,3,4,5]],true]:
		_reject(_changed(task,"records",value),plan,"records","Invalid record shape")
	_reject(_changed(task,"records",Catalog.records(65)),plan,"records","Too many records")
	for value: Variant in [-1,100001,0.5,true,"1",INF,NAN]:
		var bad_task: Dictionary = task.duplicate(true)
		bad_task.records = JSON.parse_string(JSON.stringify(task.records))
		bad_task.records[0][0] = value
		_reject(bad_task,plan,"value","Invalid authoritative record value")
	for value: Variant in [[],[{}],[{"kind":"sum"}],[{"kind":"sum","fields":[]}],[{"kind":"x","fields":[0]}],[{"kind":"sum","fields":[true]}],[{"kind":"sum","fields":[0],"extra":1}]]:
		_reject(_changed(task,"queries",value),plan,"queries","Invalid query schema")
	for value: Variant in [0,17,1.5,true,"8",INF,NAN]:
		var bad_query: Dictionary = task.queries[0].duplicate(true)
		bad_query.repeat = value
		_reject(_changed(task,"queries",[bad_query]),plan,"queries","Invalid query repetition")
	for value: Variant in [[-1],[17],[0.5],[true],"0",null]:
		var bad_query: Dictionary = task.queries[0].duplicate(true)
		bad_query.indices = value
		_reject(_changed(task,"queries",[bad_query]),plan,"indices","Invalid query indices")
	var too_many: Dictionary = task.duplicate(true)
	too_many.queries = [
		{"kind":"sum","fields":[0],"repeat":16,"indices":[]},
		{"kind":"sum","fields":[0],"repeat":1,"indices":[]},
	]
	_reject(too_many,plan,"jobs","More than16 logical jobs")
	for value: Variant in ["batch","unknown",true,1]:
		_reject(task,_changed(plan,"copy_mode",value),"copy_mode","Unsupported copy lifetime")
	for value: Variant in [0,17,1.5,true,"1",INF,NAN]:
		_reject(task,_changed(plan,"query_group",value),"query_group","Invalid group")
	_reject(task,_changed(plan,"query_group",9),"query_group","Group exceeds actual jobs")
	_reject(Model.scenario("scan_serial"),_changed(plan,"query_group",2),"serial_group","Serial grouping cannot silently clamp")
	for value: Variant in [0,65,1.5,true,"1",INF,NAN]:
		_reject(task,_changed(plan,"record_tile",value),"record_tile","Invalid record tile")
	for value: Variant in [[0,0],[4],[-1],[true],[0.5],"0",null]:
		_reject(task,_changed(plan,"copy_fields",value),"copy_fields","Invalid copy field subset")
	var empty_full: Dictionary = _changed(plan,"copy_mode","full")
	empty_full.copy_fields = []
	_reject(task,empty_full,"copy_fields","Full copy needs a field")
	for value: Variant in [
		{},{"groups":[],"block":0},{"groups":Recipe.record_major().groups},
		{"groups":Recipe.record_major().groups,"block":0,"extra":1},
		{"groups":[{"fields":[0,0,2,3],"order":"record"}],"block":0},
		{"groups":[{"fields":[0,1,2,3],"order":"record","extra":1}],"block":0},
		{"groups":[{"fields":[0,1,2,true],"order":"record"}],"block":0},
		{"groups":[{"fields":[0,1,2,3],"order":true}],"block":0},
		{"groups":Recipe.record_major().groups,"block":true},
		{"groups":Recipe.record_major().groups,"block":65},
	]:
		_reject(task,_changed(plan,"recipe",value),"recipe","Invalid exact recipe")


func _identity_and_legacy() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var plan: Dictionary = Model.starter_plan()
	var before_task: Dictionary = task.duplicate(true)
	var before_plan: Dictionary = plan.duplicate(true)
	var run: LayoutRun = _measure(task,plan,"identity baseline")
	check(task == before_task and plan == before_plan,"Evaluation does not mutate caller task or draft.")
	if run == null: return
	check(run.model_version != Simulator.MODEL_VERSION and run.case_signature == Model.condition_id(task) and run.recipe_signature == Model.plan_id(plan),"All returned identities belong to the experiment.")
	check(Model.condition_id(task) != Model.condition_id(Model.scenario("scan_serial")),"Batch and serial conditions cannot compare as one bucket.")
	var changed_data: Dictionary = task.duplicate(true)
	changed_data.records[0][0] += 1
	check(Model.condition_id(task) != Model.condition_id(changed_data),"Actual data values participate in conditions.")
	check(Model.condition_id(task) != Model.condition_id(_changed(task,"scratch_limit",159)),"Scratch limits participate in conditions.")
	var inactive: Dictionary = plan.duplicate(true)
	inactive.recipe = Recipe.field_major()
	inactive.copy_fields = [3,2]
	check(Model.normalize_plan(inactive) == inactive,"Structural normalization preserves dormant edit choices.")
	check(Model.plan_id(inactive) == Model.plan_id(plan),"Inactive copy choices do not create a different measured source-only plan.")
	check(Model.plan_id(_changed(plan,"record_tile",1)) != Model.plan_id(plan),"Actual query scheduling is part of plan identity.")
	var reordered: Dictionary = {}
	var keys: Array = task.keys()
	keys.reverse()
	for key: String in keys: reordered[key] = task[key]
	check(Model.condition_id(reordered) == Model.condition_id(task),"Dictionary insertion order does not change conditions.")
	var numeric: Dictionary = JSON.parse_string(JSON.stringify(plan))
	numeric.query_group = 1.0
	numeric.record_tile = 17.0
	check(Model.normalize_plan(numeric) == plan and Model.plan_id(numeric) == Model.plan_id(plan),"JSON integral floats normalize to the same integers and identity.")
	var previous_locale: String = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var english: LayoutRun = _measure(task,plan,"English identity")
	TranslationServer.set_locale("zh_CN")
	var chinese: LayoutRun = _measure(task,plan,"Chinese identity")
	TranslationServer.set_locale(previous_locale)
	if english != null and chinese != null:
		check(english.canonical_signature() == chinese.canonical_signature(),"Locale never alters model evidence.")
	var exported: Dictionary = Code.encode("mixed",Catalog.reference_solution("mixed"),"cycles")
	check(exported.ok,"Existing official challenge still encodes.")
	if exported.ok:
		_reject(task,exported.challenge,"plan","Old challenge envelope cannot enter the experiment")
		var forged: Dictionary = exported.challenge.duplicate(true)
		forged.model = Model.MODEL_VERSION
		check(Code.inspect(Code.PREFIX+JSON.stringify(forged,"",true)).reason == "model","Official challenge inspector rejects experimental model identity.")
	_reject(task,Catalog.starter_design(),"plan","Old strategy/batch design cannot masquerade as experiment plan")
	var mutated: LayoutRun = _measure(task,plan,"signature-bearing response")
	if mutated != null:
		var original_signature: String = mutated.canonical_signature()
		for event: SimulationEvent in mutated.events:
			if event.kind == &"response":
				event.details.job_id = 99
				break
		check(mutated.canonical_signature() != original_signature,"Job identity is signature-bearing, not a stripped presentation coordinate.")


func _measure(task: Dictionary, plan: Dictionary, label: String) -> LayoutRun:
	var result: Dictionary = Model.evaluate(task,plan)
	measured_count += 1
	check(result.valid and result.run is LayoutRun,label+" produces an authoritative run.")
	if not result.valid or not result.run is LayoutRun: return null
	check(result.error.is_empty(),label+" has no runtime failure.")
	return result.run


func _check_run(task: Dictionary, plan: Dictionary, run: LayoutRun) -> void:
	check(run.passed and run.output_values == Simulator.expected(task),"Complete physical run matches the ordered logical oracle.")
	check(run.model_version == Model.MODEL_VERSION and run.case_signature == Model.condition_id(task) and run.recipe_signature == Model.plan_id(plan),"Measured identities bind the current experiment task and plan.")
	var query_values: int = 0
	var output_count: int = 0
	var job_count: int = 0
	for query: Dictionary in task.queries:
		var indices: Array = query.get("indices",[])
		var index_count: int = task.records.size() if indices.is_empty() else indices.size()
		var repeat: int = int(query.get("repeat",1))
		query_values += index_count*query.fields.size()*repeat
		output_count += repeat if query.kind == "sum" else index_count*query.fields.size()*repeat
		job_count += repeat
	var copied: int = task.records.size()*plan.copy_fields.size() if plan.copy_mode == "full" else 0
	check(run.metrics.total_cycles == 2*query_values+output_count+10*copied+16*int(run.metrics.fills),"Cycles count actual reads, compute, writes, fills and outputs once.")
	check(run.metrics.ram_read_bytes+run.metrics.ram_write_bytes == 4*copied+16*int(run.metrics.fills),"Traffic counts actual writes and cache-line fills.")
	check(run.metrics.total_cycles == run.metrics.prepare_cycles+run.metrics.query_cycles+run.metrics.output_cycles,"All cycles have exactly one phase.")
	check(run.metrics.output_cycles == output_count and run.metrics.ram_write_bytes == copied*4,"Response outputs and copied words each pay once.")
	check(run.metrics.job_count == job_count and run.metrics.response_cycles.size() == job_count and run.metrics.admission_cycles.size() == job_count,"Every logical job has a bounded admission/response slot.")
	if plan.copy_mode == "none":
		check(run.scratch_maps.is_empty() and run.metrics.peak_extra_bytes == 0 and run.metrics.prepare_cycles == 0,"Source-only scheduling has no fabricated copy or scratch.")
	else:
		var mapping: Dictionary = Recipe.mapping(plan.recipe,task.records.size(),0,plan.copy_fields)
		check(run.scratch_maps.size() == 1 and run.metrics.peak_extra_bytes == mapping.bytes,"One retained copy uses exact mapper allocation.")
	var response_counts: Array[int] = []
	var admission_counts: Array[int] = []
	var last_output_end: Array[int] = []
	response_counts.resize(job_count)
	response_counts.fill(0)
	admission_counts.resize(job_count)
	admission_counts.fill(0)
	last_output_end.resize(job_count)
	last_output_end.fill(-1)
	var output_indices: Dictionary = {}
	var actual_compute: int = 0
	var actual_write: int = 0
	var last_end: int = 0
	var chronology_ok: bool = true
	var job_tags_ok: bool = true
	var output_ok: bool = true
	var responses_ok: bool = true
	var duration_ok: bool = true
	for event: SimulationEvent in run.events:
		chronology_ok = chronology_ok and event.cycle == last_end and event.duration >= 0
		last_end = event.cycle+event.duration
		var job_id: int = int(event.details.get("job_id",-1))
		var is_query_operation: bool = event.details.get("stage","") == "query" and event.kind in [&"lookup",&"fill",&"evict",&"read",&"compute"]
		if is_query_operation or event.kind in [&"output",&"response",&"request_admitted"]:
			job_tags_ok = job_tags_ok and job_id >= 0 and job_id < job_count
			if job_id >= 0 and job_id < job_count:
				job_tags_ok = job_tags_ok and int(run.metrics.admission_cycles[job_id]) >= 0 and event.cycle >= int(run.metrics.admission_cycles[job_id])
		if event.kind == &"compute": actual_compute += 1
		if event.kind == &"write": actual_write += 1
		if event.kind == &"request_admitted" and job_id >= 0 and job_id < job_count:
			admission_counts[job_id] += 1
			responses_ok = responses_ok and event.duration == 0 and event.cycle == int(run.metrics.admission_cycles[job_id]) and event.details.admitted_cycle == event.cycle
		if event.kind == &"output":
			var output_index: int = int(event.details.get("output_index",-1))
			output_ok = output_ok and output_index >= 0 and output_index < run.output_values.size() and not output_indices.has(output_index)
			if output_index >= 0 and output_index < run.output_values.size():
				output_ok = output_ok and event.value == run.output_values[output_index]
				output_indices[output_index] = true
			if job_id >= 0 and job_id < job_count: last_output_end[job_id] = last_end
		if event.kind == &"response" and job_id >= 0 and job_id < job_count:
			response_counts[job_id] += 1
			responses_ok = responses_ok and event.duration == 0 and event.cycle == last_output_end[job_id] and event.cycle == int(run.metrics.response_cycles[job_id]) and event.details.response_cycle == event.cycle
		var expected_duration: int = {&"lookup":1,&"fill":16,&"write":9,&"compute":1,&"output":1}.get(event.kind,0)
		duration_ok = duration_ok and event.duration == expected_duration
	check(chronology_ok and last_end == run.metrics.total_cycles,"Trace clock is continuous and equals measured makespan.")
	check(duration_ok,"Every duration comes from unchanged explicit memory/compute/output costs.")
	check(job_tags_ok,"Query operations and responses carry real admitted job identities.")
	check(output_ok and output_indices.size() == output_count and actual_compute == query_values and actual_write == copied,"No output is duplicated, reordered logically or omitted; actual work is complete.")
	var causality_ok: bool = responses_ok
	for job_id: int in range(job_count):
		causality_ok = causality_ok and response_counts[job_id] == 1 and admission_counts[job_id] == 1
		if task.release == "serial":
			var expected_admission: int = 0 if job_id == 0 else int(run.metrics.response_cycles[job_id-1])
			causality_ok = causality_ok and int(run.metrics.admission_cycles[job_id]) == expected_admission
		else:
			causality_ok = causality_ok and int(run.metrics.admission_cycles[job_id]) == 0
	check(causality_ok,"Every response follows its actual outputs and serial readiness follows the previous response.")
	check(run.metrics.first_request_cycles == run.metrics.response_cycles[0] and run.metrics.response_cycles.max() == run.metrics.total_cycles,"Q1 and final makespan are actual completion cycles.")


func _reject(task: Dictionary, plan: Dictionary, reason: String, label: String) -> void:
	var result: Dictionary = Model.evaluate(task,plan)
	check(not result.valid and result.error == reason and result.run == null,label+" rejects before simulation with "+reason+".")


func _changed(source: Dictionary, key: String, value: Variant) -> Dictionary:
	var copy: Dictionary = source.duplicate(true)
	copy[key] = value
	return copy
