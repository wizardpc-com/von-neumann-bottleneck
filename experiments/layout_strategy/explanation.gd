extends RefCounted
## Observational accounting of existing run snapshots. Never executes a plan.
const Model = preload("res://experiments/layout_strategy/model.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const MAX_INTEGER: int = 9007199254740991
const MAX_CYCLES: int = Model.MAX_TRACE_EVENTS*Simulator.FILL_CYCLES
const PHASE_KEYS: Array[String] = ["prepare","query","output","total"]
const COUNTERS: Array[String] = [
	"cycles","ram_read_bytes","ram_write_bytes","ram_bytes",
	"lookups","fills","hits","writes",
]
const DURATIONS: Dictionary = {
	"request_admitted":0,"response":0,"lookup":Simulator.READ_LOOKUP,
	"fill":Simulator.FILL_CYCLES,"read":0,"write":Simulator.WRITE_CYCLES,
	"evict":0,"compute":1,"output":1,"allocate":0,"release":0,
}


static func summarize(entry: Dictionary, current_condition: String) -> Dictionary:
	var problem: String = _entry_error(entry,current_condition)
	if not problem.is_empty(): return _unavailable(problem)
	var metrics: Dictionary = entry.metrics
	var job_count: int = int(metrics.job_count)
	var phases: Array[Dictionary] = []
	var jobs: Array[Dictionary] = []
	for key: String in PHASE_KEYS: phases.append(_phase(key))
	for id: int in range(job_count):
		jobs.append({"id":id,"admission":-1,"completion":-1,"elapsed":-1,
			"event_indices":[]})
	var state: Dictionary = {
		"clock":0,"lookup":{},"value":{},"output_job":-1,
		"allocation":{},"released":false,"query_started":false,
		"evictions":0,"computes":0,"responses":0,"output_seen":{},
		"job_tags":{},"job_outputs":{},"job_last_output":{},
		"job_computes":{},"response_spans":{},
	}
	for index: int in range(entry.events.size()):
		var event: Variant = entry.events[index]
		problem = _event_error(event,index,state,phases,jobs,entry.outputs)
		if not problem.is_empty(): return _unavailable(problem)
	problem = _finish_error(entry,state,phases,jobs)
	if not problem.is_empty(): return _unavailable(problem)
	return {
		"ok":true,"reason":"","id":int(entry.id),"task_id":String(entry.task_id),
		"condition_id":String(entry.condition_id),"trace_id":String(entry.trace_id),
		"plan":Model.normalize_plan(entry.plan),"phases":phases,"jobs":jobs,
		"copy_payload_bytes":int(phases[0].ram_write_bytes),
		"copy_allocated_bytes":int(metrics.peak_extra_bytes),
		"first_request_cycles":int(metrics.first_request_cycles),
	}


static func compare(selected: Dictionary, baseline: Dictionary, current_condition: String) -> Dictionary:
	var selected_summary: Dictionary = summarize(selected,current_condition)
	if not selected_summary.ok: return selected_summary
	var baseline_summary: Dictionary = summarize(baseline,current_condition)
	if not baseline_summary.ok: return baseline_summary
	if selected_summary.task_id != baseline_summary.task_id: return _unavailable("task")
	if selected_summary.jobs.size() != baseline_summary.jobs.size(): return _unavailable("jobs")
	var phases: Array[Dictionary] = []
	var jobs: Array[Dictionary] = []
	for index: int in range(PHASE_KEYS.size()):
		var chosen: Dictionary = selected_summary.phases[index]
		var reference: Dictionary = baseline_summary.phases[index]
		var delta: Dictionary = {}
		for key: String in COUNTERS: delta[key] = int(chosen[key])-int(reference[key])
		phases.append({"key":PHASE_KEYS[index],"selected":chosen,"baseline":reference,"delta":delta})
	for index: int in range(selected_summary.jobs.size()):
		var chosen: Dictionary = selected_summary.jobs[index]
		var reference: Dictionary = baseline_summary.jobs[index]
		var delta: Dictionary = {}
		for key: String in ["admission","completion","elapsed"]:
			delta[key] = int(chosen[key])-int(reference[key])
		jobs.append({"id":index,"selected":chosen,"baseline":reference,"delta":delta})
	return {"ok":true,"reason":"","selected":selected_summary,"baseline":baseline_summary,
		"phases":phases,"jobs":jobs}


static func _entry_error(entry: Dictionary, condition: String) -> String:
	if entry.is_empty(): return "entry"
	if condition.is_empty() or not entry.get("condition_id") is String or entry.condition_id != condition:
		return "condition"
	if not _integer(entry.get("id"),1,MAX_INTEGER): return "entry"
	if not entry.get("task_id") is String or entry.task_id not in Model.SCENARIO_IDS: return "entry"
	if not _fingerprint(entry.get("trace_id")) or not _fingerprint(entry.condition_id): return "entry"
	if not entry.get("correct") is bool: return "entry"
	if not entry.correct: return "incomplete"
	if not entry.get("plan") is Dictionary or Model.normalize_plan(entry.plan).is_empty(): return "plan"
	if not entry.get("metrics") is Dictionary: return "metrics"
	var metrics: Dictionary = entry.metrics
	for key: String in [
		"total_cycles","prepare_cycles","query_cycles","output_cycles",
		"ram_read_bytes","ram_write_bytes","prepare_read_bytes","prepare_write_bytes",
		"query_read_bytes","query_write_bytes","requests","fills","hits","evictions",
		"peak_extra_bytes",
	]:
		if not _integer(metrics.get(key),0,MAX_INTEGER): return "metrics"
	if int(metrics.total_cycles) > MAX_CYCLES: return "metrics"
	if not metrics.get("error") is String or not metrics.get("result_class") is String: return "metrics"
	if metrics.error != "" or metrics.result_class != "correct_output": return "incomplete"
	if not _integer(metrics.get("first_request_cycles"),-1,MAX_CYCLES): return "metrics"
	if not _integer(metrics.get("job_count"),1,Model.MAX_JOBS): return "metrics"
	if not metrics.get("admission_cycles") is Array or not metrics.get("response_cycles") is Array:
		return "metrics"
	var count: int = int(metrics.job_count)
	if metrics.admission_cycles.size() != count or metrics.response_cycles.size() != count: return "incomplete"
	for id: int in range(count):
		for key: String in ["admission_cycles","response_cycles"]:
			if not _integer(metrics[key][id],-1,MAX_CYCLES): return "metrics"
			if int(metrics[key][id]) < 0: return "incomplete"
	if int(metrics.first_request_cycles) < 0: return "incomplete"
	if not entry.get("outputs") is Array or not entry.get("expected") is Array: return "outputs"
	if entry.outputs.is_empty() or entry.outputs.size() > Model.MAX_OUTPUT_VALUES: return "outputs"
	if entry.expected.size() != entry.outputs.size(): return "outputs"
	for index: int in range(entry.outputs.size()):
		if not _integer(entry.outputs[index],-MAX_INTEGER,MAX_INTEGER): return "outputs"
		if not _integer(entry.expected[index],-MAX_INTEGER,MAX_INTEGER): return "outputs"
		if int(entry.outputs[index]) != int(entry.expected[index]): return "outputs"
	if not entry.get("events") is Array or entry.events.is_empty() or entry.events.size() > Model.MAX_TRACE_EVENTS:
		return "events"
	return ""


static func _event_error(raw: Variant, index: int, state: Dictionary, phases: Array[Dictionary],
		jobs: Array[Dictionary], outputs: Array) -> String:
	if not raw is Dictionary: return "events"
	var event: Dictionary = raw
	if not event.get("kind") is String or not DURATIONS.has(event.kind): return "events"
	var kind: String = event.kind
	if not _integer(event.get("cycle"),0,MAX_CYCLES) or not _integer(event.get("duration"),0,MAX_CYCLES): return "events"
	if int(event.cycle) != int(state.clock) or int(event.duration) != int(DURATIONS[kind]): return "clock"
	for key: String in ["address","cache_line","value"]:
		if not _integer(event.get(key),-MAX_INTEGER,MAX_INTEGER): return "events"
	if not event.get("source") is String or not event.get("target") is String: return "events"
	if not event.get("details") is Dictionary: return "events"
	var details: Dictionary = event.details
	if not details.get("stage") is String or details.stage not in ["prepare","query","output"]: return "phase"
	if not _integer(details.get("bytes"),0,Model.MAX_SCRATCH_BYTES): return "events"
	for key: String in ["record","field"]:
		if not _integer(details.get(key),-1,Recipe.MAX_RECORDS-1 if key == "record" else Recipe.FIELD_COUNT-1):
			return "events"
	var stage: String = details.stage
	var bytes: int = int(details.bytes)
	var expected_bytes: int = Recipe.LINE_BYTES if kind in ["fill","evict"] else Recipe.WORD_BYTES if kind in ["read","write"] else 0
	if kind not in ["allocate","release"] and bytes != expected_bytes: return "bytes"
	if kind in ["allocate","release"] and (bytes < Recipe.LINE_BYTES or bytes%Recipe.LINE_BYTES != 0): return "bytes"
	if int(state.output_job) >= 0 and kind not in ["output","response"]: return "outputs"
	if not state.lookup.is_empty() and kind not in ["evict","fill","read"]: return "reads"
	if not state.value.is_empty() and kind not in ["compute","write"]: return "reads"

	var job_id: int = -1
	var requires_job: bool = kind in ["request_admitted","response","output","compute"] or (
		stage == "query" and kind in ["lookup","fill","evict","read"])
	if requires_job:
		if not _integer(details.get("job_id"),0,jobs.size()-1): return "jobs"
		job_id = int(details.job_id)
		if not _integer(details.get("query_index"),0,7) or not _integer(details.get("repeat_index"),0,Model.MAX_JOBS-1):
			return "jobs"
		var tags: Array[int] = [int(details.query_index),int(details.repeat_index)]
		if state.job_tags.has(job_id) and state.job_tags[job_id] != tags: return "jobs"
		state.job_tags[job_id] = tags
		if kind != "request_admitted" and (int(jobs[job_id].admission) < 0 or int(jobs[job_id].completion) >= 0):
			return "timing"
		if stage == "query" and kind != "request_admitted":
			if not _integer(details.get("query_tile_first"),0,Recipe.MAX_RECORDS-1): return "jobs"
	elif details.has("job_id"):
		return "jobs"

	match kind:
		"request_admitted":
			if stage != "query" or int(jobs[job_id].admission) >= 0: return "timing"
			if int(event.value) != job_id: return "jobs"
			if not _integer(details.get("admitted_cycle"),0,MAX_CYCLES) or int(details.admitted_cycle) != int(state.clock): return "timing"
			jobs[job_id].admission = int(state.clock)
		"lookup":
			if stage not in ["prepare","query"] or int(event.address) < 0 or int(event.address)%Recipe.WORD_BYTES != 0: return "reads"
			if stage == "prepare" and (state.allocation.is_empty() or state.query_started): return "allocation"
			if stage == "query": state.query_started = true
			state.lookup = {"address":int(event.address),"stage":stage,"job":job_id,
				"record":int(details.record),"field":int(details.field),"filled":false,"evicted":false}
		"evict","fill":
			if state.lookup.is_empty() or state.lookup.stage != stage or int(state.lookup.job) != job_id: return "reads"
			if state.lookup.filled: return "reads"
			if kind == "evict":
				if state.lookup.evicted: return "reads"
				state.lookup.evicted = true
				state.evictions = int(state.evictions)+1
			else:
				var line_start: int = int(state.lookup.address)-int(state.lookup.address)%Recipe.LINE_BYTES
				if int(event.address) != line_start: return "reads"
				state.lookup.filled = true
		"read":
			if state.lookup.is_empty() or state.lookup.stage != stage or int(state.lookup.job) != job_id: return "reads"
			if int(event.address) != int(state.lookup.address) or int(details.record) != int(state.lookup.record) or int(details.field) != int(state.lookup.field): return "reads"
			if state.lookup.evicted and not state.lookup.filled: return "reads"
			state.value = {"address":int(event.address),"value":int(event.value),
				"record":int(details.record),"field":int(details.field),"job":job_id,"stage":stage}
			state.lookup = {}
		"compute","write":
			if state.value.is_empty() or state.value.stage != stage or int(state.value.job) != job_id: return "reads"
			if int(event.value) != int(state.value.value) or int(details.record) != int(state.value.record) or int(details.field) != int(state.value.field): return "reads"
			if kind == "compute":
				if stage != "query" or int(event.address) != int(state.value.address): return "reads"
				state.computes = int(state.computes)+1
				state.job_computes[job_id] = int(state.job_computes.get(job_id,0))+1
			else:
				if stage != "prepare" or state.allocation.is_empty(): return "allocation"
				if int(event.address) < int(state.allocation.address) or int(event.address)+Recipe.WORD_BYTES > int(state.allocation.address)+int(state.allocation.bytes): return "allocation"
			state.value = {}
		"allocate":
			if stage != "prepare" or not state.allocation.is_empty() or state.query_started: return "allocation"
			if int(event.address) < 0 or int(event.address)%Recipe.LINE_BYTES != 0: return "allocation"
			state.allocation = {"address":int(event.address),"bytes":bytes}
		"release":
			if stage != "query" or state.allocation.is_empty() or state.released or int(state.responses) != jobs.size(): return "allocation"
			if int(event.address) != int(state.allocation.address) or bytes != int(state.allocation.bytes): return "allocation"
			state.released = true
		"output":
			if stage != "output" or int(state.job_computes.get(job_id,0)) < 1: return "outputs"
			if int(state.output_job) >= 0 and int(state.output_job) != job_id: return "outputs"
			if not _integer(details.get("output_index"),0,outputs.size()-1): return "outputs"
			var output_index: int = int(details.output_index)
			if state.output_seen.has(output_index) or int(event.value) != int(outputs[output_index]): return "outputs"
			var span: Array = state.job_outputs.get(job_id,[])
			if not span.is_empty() and output_index != int(span[-1])+1: return "outputs"
			span.append(output_index)
			state.job_outputs[job_id] = span
			state.output_seen[output_index] = true
			state.job_last_output[job_id] = int(state.clock)+int(event.duration)
			state.output_job = job_id
		"response":
			if stage != "output" or int(state.output_job) != job_id: return "timing"
			if int(event.value) != job_id: return "jobs"
			if not _integer(details.get("response_cycle"),0,MAX_CYCLES) or int(details.response_cycle) != int(state.clock): return "timing"
			if int(state.job_last_output.get(job_id,-1)) != int(state.clock): return "timing"
			if not _integer(details.get("output_first"),0,outputs.size()-1) or not _integer(details.get("output_count"),1,outputs.size()): return "outputs"
			var span: Array = state.job_outputs.get(job_id,[])
			if span.size() != int(details.output_count) or int(span[0]) != int(details.output_first): return "outputs"
			state.response_spans[job_id] = {"first":int(details.output_first),"count":int(details.output_count)}
			jobs[job_id].completion = int(state.clock)
			jobs[job_id].elapsed = int(state.clock)-int(jobs[job_id].admission)
			state.responses = int(state.responses)+1
			state.output_job = -1

	var phase: Dictionary = phases[PHASE_KEYS.find(stage)]
	_accumulate(phase,kind,int(event.duration),bytes,index)
	_accumulate(phases[3],kind,int(event.duration),bytes,index)
	if job_id >= 0: jobs[job_id].event_indices.append(index)
	state.clock = int(state.clock)+int(event.duration)
	return ""


static func _finish_error(entry: Dictionary, state: Dictionary, phases: Array[Dictionary], jobs: Array[Dictionary]) -> String:
	if not state.lookup.is_empty() or not state.value.is_empty() or int(state.output_job) >= 0: return "incomplete"
	var metrics: Dictionary = entry.metrics
	var total: Dictionary = phases[3]
	if int(state.clock) != int(metrics.total_cycles): return "metrics"
	if int(state.responses) != jobs.size() or state.output_seen.size() != entry.outputs.size(): return "incomplete"
	if int(state.computes) < 1 or int(state.computes) > Model.MAX_QUERY_VALUES: return "events"
	var first_output: int = 0
	var latest_response: int = -1
	var batch_admission: bool = true
	var serial_admission: bool = true
	for id: int in range(jobs.size()):
		var job: Dictionary = jobs[id]
		if int(job.admission) < 0 or int(job.completion) < int(job.admission): return "timing"
		if int(job.admission) != int(metrics.admission_cycles[id]) or int(job.completion) != int(metrics.response_cycles[id]): return "timing"
		batch_admission = batch_admission and int(job.admission) == 0
		var serial_start: int = 0 if id == 0 else int(jobs[id-1].completion)
		serial_admission = serial_admission and int(job.admission) == serial_start
		latest_response = maxi(latest_response,int(job.completion))
		var span: Dictionary = state.response_spans[id]
		if int(span.first) != first_output: return "outputs"
		first_output += int(span.count)
	if not batch_admission and not serial_admission: return "timing"
	if int(jobs[0].completion) != int(metrics.first_request_cycles) or latest_response != int(metrics.total_cycles): return "timing"
	for index: int in range(3):
		var phase: Dictionary = phases[index]
		phase.hits = int(phase.lookups)-int(phase.fills)
		if int(phase.hits) < 0 or int(phase.cycles) != int(metrics[PHASE_KEYS[index]+"_cycles"]): return "metrics"
		if index < 2:
			if int(phase.ram_read_bytes) != int(metrics[PHASE_KEYS[index]+"_read_bytes"]) or int(phase.ram_write_bytes) != int(metrics[PHASE_KEYS[index]+"_write_bytes"]): return "metrics"
	total.hits = int(total.lookups)-int(total.fills)
	for key: String in ["ram_read_bytes","ram_write_bytes","fills","hits"]:
		if int(total[key]) != int(metrics[key]): return "metrics"
	if int(total.lookups)+int(total.writes) != int(metrics.requests) or int(state.evictions) != int(metrics.evictions): return "metrics"
	if int(phases[2].cycles) != entry.outputs.size(): return "outputs"
	if int(total.lookups) != int(state.computes)+int(total.writes): return "reads"
	if int(total.cycles) != 2*int(state.computes)+entry.outputs.size()+10*int(total.writes)+Simulator.FILL_CYCLES*int(total.fills): return "metrics"
	if int(total.ram_bytes) != Recipe.WORD_BYTES*int(total.writes)+Recipe.LINE_BYTES*int(total.fills): return "metrics"
	var allocated: int = 0 if state.allocation.is_empty() else int(state.allocation.bytes)
	if allocated != int(metrics.peak_extra_bytes) or allocated > Model.MAX_SCRATCH_BYTES: return "allocation"
	if entry.plan.copy_mode == "none":
		if allocated != 0 or int(phases[0].cycles) != 0 or int(total.writes) != 0: return "allocation"
	else:
		if allocated == 0 or not state.released or int(total.writes) < 1 or int(total.writes) > Recipe.MAX_RECORDS*Recipe.FIELD_COUNT: return "allocation"
		if int(phases[0].ram_write_bytes) > allocated: return "allocation"
	return ""


static func _accumulate(phase: Dictionary, kind: String, duration: int, bytes: int, index: int) -> void:
	phase.cycles = int(phase.cycles)+duration
	phase.event_indices.append(index)
	match kind:
		"lookup": phase.lookups = int(phase.lookups)+1
		"fill":
			phase.fills = int(phase.fills)+1
			phase.ram_read_bytes = int(phase.ram_read_bytes)+bytes
			phase.ram_bytes = int(phase.ram_bytes)+bytes
		"write":
			phase.writes = int(phase.writes)+1
			phase.ram_write_bytes = int(phase.ram_write_bytes)+bytes
			phase.ram_bytes = int(phase.ram_bytes)+bytes


static func _phase(key: String) -> Dictionary:
	var result: Dictionary = {"key":key,"event_indices":[]}
	for field: String in COUNTERS: result[field] = 0
	return result


static func _unavailable(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float): return false
	var number: float = float(value)
	return is_finite(number) and number == floorf(number) and number >= float(minimum) and number <= float(maximum)


static func _fingerprint(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if character not in "0123456789abcdef": return false
	return true
