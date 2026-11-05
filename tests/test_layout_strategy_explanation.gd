extends SceneTree
const Explanation = preload("res://experiments/layout_strategy/explanation.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
var checks: int = 0
var measurements: int = 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for explanation checks.")
		quit(1)
		return
	_pair_accounting()
	_layout_accounting()
	_grouped_responses()
	_sparse_and_bounds()
	_invalid_evidence()
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy explanation %d checks, %d measurements, %d failures" % [checks,measurements,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _entry(task: Dictionary, plan: Dictionary, id: int = 1) -> Dictionary:
	var measured: Dictionary = Model.evaluate(task,plan)
	measurements += 1
	check(measured.valid and measured.run is LayoutRun,"Fixture executes the authoritative model.")
	if not measured.valid or not measured.run is LayoutRun: return {}
	var run: LayoutRun = measured.run
	var events: Array[Dictionary] = []
	for event: SimulationEvent in run.events: events.append(event.to_dictionary())
	return {
		"id":id,"task_id":task.id,"condition_id":run.case_signature,
		"trace_id":run.canonical_signature().sha256_text(),"plan":Model.normalize_plan(plan),
		"correct":run.passed,"metrics":run.metrics.duplicate(true),"events":events,
		"outputs":run.output_values.duplicate(),"expected":run.expected_values.duplicate(),
		"source_map":run.source_map.duplicate(true),"scratch_maps":run.scratch_maps.duplicate(true),
	}


func _copy(fields: Array, field_major: bool = false) -> Dictionary:
	var plan: Dictionary = Model.starter_plan()
	plan.copy_mode = "full"
	plan.copy_fields = fields.duplicate()
	plan.recipe = Recipe.field_major() if field_major else Recipe.record_major()
	return plan


func _summary(entry: Dictionary) -> Dictionary:
	if entry.is_empty(): return {"ok":false,"reason":"fixture"}
	var result: Dictionary = Explanation.summarize(entry,entry.condition_id)
	check(result.ok,"Actual complete run can be explained: "+str(result.get("reason","")))
	return result


func _phase(summary: Dictionary, key: String) -> Dictionary:
	for row: Dictionary in summary.phases:
		if row.key == key: return row
	return {}


func _counts(row: Dictionary, expected: Dictionary, label: String) -> void:
	for key: String in expected:
		check(row.get(key) == expected[key],label+" has measured "+key+" = "+str(expected[key]))


func _pair_accounting() -> void:
	var task: Dictionary = Model.scenario("scan_pair_serial")
	var direct: Dictionary = _entry(task,Model.starter_plan(),1)
	var copied: Dictionary = _entry(task,_copy([0],true),2)
	var before: String = JSON.stringify([direct,copied],"",true)
	var source: Dictionary = _summary(direct)
	var retained: Dictionary = _summary(copied)
	if not source.ok or not retained.ok: return
	_counts(_phase(source,"prepare"),{"cycles":0,"ram_bytes":0,"lookups":0,"fills":0,"hits":0,"writes":0},"Direct preparation")
	_counts(_phase(source,"query"),{"cycles":612,"ram_read_bytes":544,"ram_write_bytes":0,"lookups":34,"fills":34,"hits":0,"writes":0},"Direct queries")
	_counts(_phase(retained,"prepare"),{"cycles":442,"ram_read_bytes":272,"ram_write_bytes":68,"ram_bytes":340,"lookups":17,"fills":17,"hits":0,"writes":17},"Copied preparation")
	_counts(_phase(retained,"query"),{"cycles":228,"ram_read_bytes":160,"ram_write_bytes":0,"ram_bytes":160,"lookups":34,"fills":10,"hits":24,"writes":0},"Copied queries")
	_counts(_phase(retained,"output"),{"cycles":2,"ram_bytes":0,"lookups":0,"fills":0,"hits":0,"writes":0},"Copied outputs")
	_counts(_phase(retained,"total"),{"cycles":672,"ram_read_bytes":432,"ram_write_bytes":68,"ram_bytes":500,"lookups":51,"fills":27,"hits":24,"writes":17},"Copied total")
	check(copied.metrics.requests == 68 and _phase(retained,"total").lookups == 51,"Write requests do not enter the read hit denominator.")
	check(retained.copy_payload_bytes == 68 and retained.copy_allocated_bytes == 80,"Payload68B and padded allocation80B remain separate.")
	check(retained.first_request_cycles == 557 and retained.jobs[0].elapsed == 557,"Q1 includes preparation after admission.")
	check(retained.jobs[1].admission == 557 and retained.jobs[1].completion == 672 and retained.jobs[1].elapsed == 115,"Second serial response reuses preparation and takes115 cycles.")
	var comparison: Dictionary = Explanation.compare(copied,direct,task_condition(task))
	check(comparison.ok,"Actual pair compares under one complete condition.")
	if comparison.ok:
		_counts(comparison.phases[0].delta,{"cycles":442,"ram_read_bytes":272,"ram_write_bytes":68,"ram_bytes":340},"Preparation delta")
		_counts(comparison.phases[1].delta,{"cycles":-384,"ram_bytes":-384,"fills":-24},"Query delta")
		_counts(comparison.phases[3].delta,{"cycles":58,"ram_bytes":-44,"lookups":17,"fills":-7,"hits":24,"writes":17},"Total delta")
		_counts(comparison.jobs[1].delta,{"admission":250,"completion":58,"elapsed":-192},"Second request delta")
		check(comparison.selected.id == 2 and comparison.baseline.id == 1,"Comparison retains both exact run identities and selected-minus-baseline direction.")
	_check_indices(copied,retained)
	var summed_event_bytes: int = 0
	for event: Dictionary in copied.events: summed_event_bytes += int(event.details.bytes)
	check(summed_event_bytes > _phase(retained,"total").ram_bytes,"Allocation/release/read/evict bytes are present but excluded from RAM traffic.")
	var repeated: Dictionary = _entry(task,_copy([0],true),2)
	check(repeated.trace_id == copied.trace_id,"Repeated fixture retains complete Trace identity.")
	check(Explanation.summarize(repeated,repeated.condition_id) == retained,"Repeated real evidence produces identical explanations.")
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(copied))
	check(Explanation.summarize(parsed,parsed.condition_id) == retained,"Integral JSON numbers produce the same normalized summary.")
	check(JSON.stringify([direct,copied],"",true) == before,"Summaries and comparison never mutate their raw inputs.")
	retained.plan.copy_fields.clear()
	retained.phases[3].event_indices.clear()
	retained.jobs[0].event_indices.clear()
	check(JSON.stringify([direct,copied],"",true) == before,"Returned nested plans/indexes are detached from measured entries.")
	var same: Dictionary = Explanation.compare(direct,direct,direct.condition_id)
	check(same.ok,"The same run is a valid zero-delta comparison.")
	if same.ok:
		for row: Dictionary in same.phases:
			for value: Variant in row.delta.values(): check(value == 0,"Same-run phase delta is zero.")
		for row: Dictionary in same.jobs:
			for value: Variant in row.delta.values(): check(value == 0,"Same-run timing delta is zero.")


func _layout_accounting() -> void:
	var task: Dictionary = Model.scenario("split_fields_serial")
	var records: Dictionary = _entry(task,_copy([0,3]),3)
	var fields: Dictionary = _entry(task,_copy([0,3],true),4)
	var result: Dictionary = Explanation.compare(fields,records,task_condition(task))
	check(result.ok,"Two physical copy layouts compare without changing the condition.")
	if not result.ok: return
	_counts(result.selected.phases[0],{"cycles":612,"ram_bytes":408,"lookups":34,"fills":17,"hits":17,"writes":34},"Shared real preparation")
	_counts(result.selected.phases[1],{"cycles":896,"ram_bytes":624,"lookups":136,"fills":39,"hits":97},"Field-major query work")
	_counts(result.baseline.phases[1],{"cycles":1424,"ram_bytes":1152,"lookups":136,"fills":72,"hits":64},"Record-major query work")
	_counts(result.phases[0].delta,{"cycles":0,"ram_bytes":0,"writes":0},"Unchanged preparation")
	_counts(result.phases[3].delta,{"cycles":-528,"ram_bytes":-528,"fills":-33,"writes":0},"Real layout delta")
	check(result.selected.copy_allocated_bytes == 144 and result.selected.copy_payload_bytes == 136,"Two-field payload remains distinct from physical allocation.")
	_check_indices(fields,result.selected)


func _grouped_responses() -> void:
	var task: Dictionary = Model.scenario("scan_batch")
	var plan: Dictionary = Model.starter_plan()
	var direct: Dictionary = _entry(task,plan,5)
	plan.query_group = 8
	plan.record_tile = 1
	var grouped: Dictionary = _entry(task,plan,6)
	var result: Dictionary = Explanation.compare(grouped,direct,task_condition(task))
	check(result.ok,"Source-only grouping produces explainable physical tradeoffs.")
	if not result.ok: return
	_counts(result.phases[3].delta,{"cycles":-1904,"ram_bytes":-1904,"lookups":0,"fills":-119,"hits":119,"writes":0},"Grouped real delta")
	check(result.jobs[0].delta.completion == 224,"The public first request slows while total work improves.")
	check(result.selected.copy_payload_bytes == 0 and result.selected.copy_allocated_bytes == 0,"Source-only reuse never invents copying.")
	var elapsed_sum: int = 0
	for job: Dictionary in result.selected.jobs:
		check(job.admission == 0 and job.elapsed == job.completion,"Batch elapsed uses actual shared admission.")
		elapsed_sum += int(job.elapsed)
	check(elapsed_sum > result.selected.phases[3].cycles,"Overlapping elapsed intervals are not treated as additive work.")
	_check_indices(grouped,result.selected)


func _sparse_and_bounds() -> void:
	var task: Dictionary = Model.scenario("mixed_batch")
	task.queries = [
		{"kind":"sum","fields":[0],"repeat":1,"indices":[]},
		{"kind":"records","fields":[0,3],"repeat":1,"indices":[0]},
	]
	var plan: Dictionary = Model.starter_plan()
	plan.query_group = 2
	plan.record_tile = 1
	var entry: Dictionary = _entry(task,plan)
	var summary: Dictionary = _summary(entry)
	if summary.ok:
		check(summary.jobs[1].completion < summary.jobs[0].completion,"Later sparse job can respond first.")
		check(summary.first_request_cycles == summary.jobs[0].completion,"Q1 does not become the earliest response.")
		_check_indices(entry,summary)
	task.queries = [
		{"kind":"records","fields":[3,0,3],"repeat":2,"indices":[16,0,16,3]},
		{"kind":"sum","fields":[0,0],"repeat":1,"indices":[16,1,16]},
	]
	plan.query_group = 3
	plan.copy_fields = [0,3]
	plan.recipe = {"groups":[{"fields":[3,0],"order":"field"},{"fields":[1,2],"order":"record"}],"block":4}
	for mode: String in ["none","full"]:
		plan.copy_mode = mode
		for tile: int in [1,4,17]:
			plan.record_tile = tile
			entry = _entry(task,plan)
			summary = _summary(entry)
			if summary.ok:
				check(summary.jobs.size() == 3,"Duplicate/nonmonotone/tail access keeps public job count.")
				_check_indices(entry,summary)
	var maximum: Dictionary = Model.scenario("scan_batch")
	maximum.records = Catalog.records(64)
	maximum.queries = [{"kind":"records","fields":[0,1,2,3],"repeat":16,"indices":[]}]
	plan = Model.starter_plan()
	plan.query_group = 16
	plan.record_tile = 7
	entry = _entry(maximum,plan)
	summary = _summary(entry)
	if summary.ok:
		check(entry.outputs.size() == Model.MAX_OUTPUT_VALUES and summary.jobs.size() == Model.MAX_JOBS,"Maximum real output/job bounds remain explainable.")
		check(summary.phases[3].event_indices.size() == entry.events.size(),"No event is truncated at the supported workload bound.")


func _check_indices(entry: Dictionary, summary: Dictionary) -> void:
	var phase_count: int = 0
	for row: Dictionary in summary.phases:
		var previous: int = -1
		var valid: bool = true
		for index: int in row.event_indices:
			valid = valid and index > previous and index < entry.events.size()
			if index < entry.events.size() and row.key != "total":
				valid = valid and entry.events[index].details.stage == row.key
			previous = index
		check(valid,"Phase navigation retains increasing original event indexes: "+row.key)
		if row.key != "total": phase_count += row.event_indices.size()
	check(phase_count == entry.events.size() and summary.phases[3].event_indices.size() == entry.events.size(),"Three phases and total each cover exactly the original events.")
	for job: Dictionary in summary.jobs:
		var previous: int = -1
		var valid: bool = not job.event_indices.is_empty()
		for index: int in job.event_indices:
			valid = valid and index > previous and index < entry.events.size()
			if index < entry.events.size(): valid = valid and entry.events[index].details.job_id == job.id
			previous = index
		check(valid,"Job navigation preserves original job identity and event order.")
		check(entry.events[job.event_indices[0]].kind == "request_admitted" and entry.events[job.event_indices[-1]].kind == "response","Each job index range includes its actual admission and response.")
	if summary.jobs.size() > 1 and summary.jobs[1].admission > 0:
		check(summary.jobs[0].event_indices[-1] < summary.jobs[1].event_indices[0],"Same-cycle serial response precedes next admission by original event index.")


func _invalid_evidence() -> void:
	var task: Dictionary = Model.scenario("scan_pair_serial")
	var direct: Dictionary = _entry(task,Model.starter_plan())
	var copied: Dictionary = _entry(task,_copy([0]))
	var condition: String = task_condition(task)
	_reject({},condition,"entry","Missing entry")
	_reject(direct,"other-condition","condition","Current condition mismatch")
	var bad: Dictionary = direct.duplicate(true)
	bad.correct = false
	_reject(bad,condition,"incomplete","Unsuccessful measurement")
	bad = direct.duplicate(true)
	bad.plan["invented_score"] = 0
	_reject(bad,condition,"plan","Malformed plan")
	for value: Variant in [true,"1",1.25,NAN,INF,-1]:
		bad = direct.duplicate(true)
		bad.metrics.requests = value
		_reject(bad,condition,"metrics","Nonintegral/invalid count "+str(value))
	for key: String in ["prepare_cycles","ram_read_bytes","query_read_bytes","requests","fills","hits","evictions"]:
		bad = direct.duplicate(true)
		bad.metrics[key] = int(bad.metrics[key])+1
		_reject(bad,condition,"metrics","Unreconciled "+key)
	bad = direct.duplicate(true)
	bad.metrics.response_cycles[1] = -1
	_reject(bad,condition,"incomplete","Unknown response")
	bad = direct.duplicate(true)
	bad.metrics.response_cycles[1] = int(bad.metrics.response_cycles[1])-1
	_reject(bad,condition,"timing","Claimed response disagrees with event")
	bad = direct.duplicate(true)
	bad.metrics.first_request_cycles = 0
	_reject(bad,condition,"timing","Fabricated first completion")
	bad = direct.duplicate(true)
	bad.expected[0] = int(bad.expected[0])+1
	_reject(bad,condition,"outputs","Incorrect ordered output")
	bad = direct.duplicate(true)
	bad.events = []
	_reject(bad,condition,"events","Empty trace")
	bad = direct.duplicate(true)
	bad.events.resize(Model.MAX_TRACE_EVENTS+1)
	_reject(bad,condition,"events","Oversized trace")
	var lookup_index: int = _find(direct,"lookup")
	var output_index: int = _find(direct,"output")
	var response_index: int = _find(direct,"response")
	var fill_index: int = _find(direct,"fill")
	# A parsed transport has an untyped array; the actual in-memory event array
	# rejects this malformed value before the reducer could inspect it.
	bad = JSON.parse_string(JSON.stringify(direct))
	bad.events[lookup_index] = "not-an-event"
	_reject(bad,condition,"events","Malformed event")
	bad = direct.duplicate(true)
	bad.events[lookup_index].cycle = 0.5
	_reject(bad,condition,"events","Fractional event clock")
	bad = direct.duplicate(true)
	bad.events[lookup_index].duration = 2
	_reject(bad,condition,"clock","Invented operation cost")
	bad = direct.duplicate(true)
	bad.events[lookup_index].details.stage = "imaginary"
	_reject(bad,condition,"phase","Unknown phase")
	bad = direct.duplicate(true)
	bad.events[fill_index].details.bytes = 4
	_reject(bad,condition,"bytes","Wrong transfer unit")
	bad = direct.duplicate(true)
	bad.events[lookup_index].details.query_index = 1
	_reject(bad,condition,"jobs","Job identity changes midstream")
	bad = direct.duplicate(true)
	bad.events[fill_index].address = int(bad.events[fill_index].address)+16
	_reject(bad,condition,"reads","Fill does not match original lookup")
	bad = direct.duplicate(true)
	bad.events[output_index].value = int(bad.events[output_index].value)+1
	_reject(bad,condition,"outputs","Emitted value disagrees with logical output")
	bad = direct.duplicate(true)
	bad.events[response_index].details.output_count = 2
	_reject(bad,condition,"outputs","Response claims wrong output span")
	bad = direct.duplicate(true)
	bad.events.pop_back()
	_reject(bad,condition,"incomplete","Missing final response")
	bad = copied.duplicate(true)
	bad.metrics.peak_extra_bytes = 68
	_reject(bad,condition,"allocation","Payload impersonates padded allocation")
	bad = direct.duplicate(true)
	bad.task_id = "scan_serial"
	var comparison: Dictionary = Explanation.compare(direct,bad,condition)
	check(not comparison.ok and comparison.reason == "task","Same claimed condition never permits different task identities.")
	check(not Explanation.compare(direct,{},condition).ok,"Missing baseline cannot produce a zero improvement.")
	var other: Dictionary = _entry(Model.scenario("scan_serial"),Model.starter_plan())
	check(not Explanation.compare(direct,other,condition).ok,"Different real admission conditions cannot compare.")
	var failed: Dictionary = _entry(task,_copy([0,1,2,3]))
	check(not failed.correct and failed.metrics.error == "space_limit","Partial fixture is an actual bounded allocation failure.")
	_reject(failed,condition,"incomplete","Failed zero-cycle trace")
	bad = direct.duplicate(true)
	bad.source_map = {"fake":"not authoritative"}
	bad.scratch_maps = []
	check(Explanation.summarize(bad,condition) == Explanation.summarize(direct,condition),"Auxiliary unsigned maps do not change an event-derived explanation.")


func _find(entry: Dictionary, kind: String) -> int:
	for index: int in range(entry.events.size()):
		if entry.events[index].kind == kind: return index
	return -1


func _reject(entry: Dictionary, condition: String, reason: String, label: String) -> void:
	var before: PackedByteArray = var_to_bytes(entry)
	var result: Dictionary = Explanation.summarize(entry,condition)
	check(not result.ok and result.reason == reason,label+" has stable unavailable reason "+reason)
	check(result.size() == 2,"Unavailable result contains no partial improvement data.")
	check(var_to_bytes(entry) == before,"Rejected evidence remains untouched: "+label)


func task_condition(task: Dictionary) -> String:
	return Model.condition_id(task)
