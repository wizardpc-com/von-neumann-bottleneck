extends RefCounted
## Pure scheduling experiment. No progression, file access or official result sink.
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const MODEL_VERSION: String = "layout-schedule-experiment-1"
const SCENARIO_IDS: Array[String] = ["scan_batch","scan_serial","mixed_batch","mixed_serial"]
const MAX_JOBS: int = 16
const MAX_QUERY_VALUES: int = 4096
const MAX_OUTPUT_VALUES: int = 4096
const MAX_TRACE_EVENTS: int = 32768
const MAX_SCRATCH_BYTES: int = 4096
const TASK_KEYS: Array[String] = ["id","records","queries","release","scratch_limit"]
const PLAN_KEYS: Array[String] = ["copy_mode","copy_fields","recipe","query_group","record_tile"]
const QUERY_KEYS: Array[String] = ["kind","fields","repeat","indices"]


class Executor:
	extends "res://src/layout_chapter/layout_simulator.gd"
	var query_group: int = 1
	var record_tile: int = 17
	var release_rule: String = "batch"
	var jobs: Array[Dictionary] = []
	var responses: Array[int] = []
	var admissions: Array[int] = []
	var active_job: int = -1
	var active_tile: int = -1

	func measure(task: Dictionary, plan: Dictionary) -> LayoutRun:
		query_group = int(plan.query_group)
		record_tile = int(plan.record_tile)
		release_rule = String(task.release)
		jobs.clear()
		responses.clear()
		admissions.clear()
		active_job = -1
		active_tile = -1
		var base_task: Dictionary = {
			"name":task.id,"records":task.records,"queries":task.queries,
			"native_layout":false,"scratch_limit":task.scratch_limit,
		}
		var base_design: Dictionary = {
			"recipe":plan.recipe,"strategy":"full" if plan.copy_mode == "full" else "direct",
			"copy_fields":plan.copy_fields,"batch":4,
		}
		var result: LayoutRun = super.run(base_task,base_design)
		result.metrics["first_request_cycles"] = responses[0] if not responses.is_empty() else -1
		result.metrics["response_cycles"] = responses.duplicate()
		result.metrics["admission_cycles"] = admissions.duplicate()
		result.metrics["job_count"] = jobs.size()
		return result

	func _prepare_outputs(queries: Array) -> void:
		super._prepare_outputs(queries)
		for query_index: int in range(queries.size()):
			var query: Dictionary = queries[query_index]
			var slots: Dictionary = output_slots[query_index]
			for repetition: int in range(slots.slots.size()):
				var value_count: int = slots.indices.size()*query.fields.size()
				jobs.append({
					"id":jobs.size(),"query_index":query_index,"repeat_index":repetition,
					"indices":slots.indices,"fields":query.fields,"kind":query.kind,
					"slot":int(slots.slots[repetition]),"remaining":value_count,
					"output_count":1 if query.kind == "sum" else value_count,
				})
		responses.resize(jobs.size())
		responses.fill(-1)
		admissions.resize(jobs.size())
		admissions.fill(-1)
		if release_rule == "batch":
			for job_id: int in range(jobs.size()): _admit(job_id)
		else:
			_admit(0)

	func _admit(job_id: int) -> void:
		var previous_stage: String = stage
		var previous_job: int = active_job
		stage = "query"
		active_job = job_id
		admissions[job_id] = clock_cycle
		_event(&"request_admitted",0,-1,-1,-1,job_id,0,&"INPUT",&"COMPUTE")
		trace.events[-1].details["admitted_cycle"] = clock_cycle
		stage = previous_stage
		active_job = previous_job

	func _query_batch(_queries: Array, first: int, count: int) -> void:
		stage = "query"
		for group_first: int in range(0,jobs.size(),query_group):
			if release_rule == "serial" and group_first > 0:
				_admit(group_first)
			for tile_first: int in range(first,first+count,record_tile):
				active_tile = tile_first
				var tile_length: int = mini(record_tile,first+count-tile_first)
				for job_id: int in range(group_first,mini(group_first+query_group,jobs.size())):
					if responses[job_id] >= 0: continue
					active_job = job_id
					var job: Dictionary = jobs[job_id]
					_consume_tile(job,tile_first,tile_length)
					if not failure.is_empty(): return
					if int(job.remaining) == 0: _respond(job)
			active_job = -1
			active_tile = -1
		for response_cycle: int in responses:
			if response_cycle < 0:
				_fail("unfinished_jobs")
				return

	func _consume_tile(job: Dictionary, first: int, count: int) -> void:
		stage = "query"
		for index: int in range(job.indices.size()):
			var record: int = int(job.indices[index])
			if record < first or record >= first+count: continue
			for field_index: int in range(job.fields.size()):
				var field: int = int(job.fields[field_index])
				var output_index: int = int(job.slot)
				var additive: bool = job.kind == "sum"
				if not additive: output_index += index*job.fields.size()+field_index
				_consume_query_value(record,field,output_index,additive)
				if not failure.is_empty(): return
				job.remaining = int(job.remaining)-1

	func _respond(job: Dictionary) -> void:
		var previous_stage: String = stage
		stage = "output"
		for offset: int in range(int(job.output_count)):
			var output_index: int = int(job.slot)+offset
			_event(&"output",1,-1,-1,-1,trace.output_values[output_index],0,&"COMPUTE",&"OUTPUT")
			trace.events[-1].details["output_index"] = output_index
		_event(&"response",0,-1,-1,-1,int(job.id),0,&"OUTPUT",&"OUTPUT")
		trace.events[-1].details["response_cycle"] = clock_cycle
		trace.events[-1].details["output_first"] = int(job.slot)
		trace.events[-1].details["output_count"] = int(job.output_count)
		responses[int(job.id)] = clock_cycle
		stage = previous_stage

	func _emit_outputs() -> void:
		# Each logical output already paid its real cost at its job's response.
		pass

	func _event(kind: StringName, duration: int, address: int, record: int, field: int, value: int, bytes: int, from: StringName, to: StringName) -> void:
		super._event(kind,duration,address,record,field,value,bytes,from,to)
		if active_job >= 0:
			trace.events[-1].details["job_id"] = active_job
			trace.events[-1].details["query_index"] = int(jobs[active_job].query_index)
			trace.events[-1].details["repeat_index"] = int(jobs[active_job].repeat_index)
			if stage == "query" and active_tile >= 0:
				trace.events[-1].details["query_tile_first"] = active_tile


static func scenario(id: String) -> Dictionary:
	if id not in SCENARIO_IDS: return {}
	var original: Dictionary = Catalog.cases("mixed" if id.begins_with("mixed") else "batches")[0]
	return _normalized_task({
		"id":id,"records":original.records,"queries":original.queries,
		"release":"serial" if id.ends_with("serial") else "batch","scratch_limit":160,
	})


static func starter_plan() -> Dictionary:
	return {
		"copy_mode":"none","copy_fields":[0],"recipe":Recipe.record_major(),
		"query_group":1,"record_tile":17,
	}


static func normalize_plan(plan: Dictionary) -> Dictionary:
	if not _plan_error(plan).is_empty(): return {}
	var fields: Array[int] = []
	for field: Variant in plan.copy_fields: fields.append(int(field))
	return {
		"copy_mode":String(plan.copy_mode),"copy_fields":fields,
		"recipe":Recipe.normalized(plan.recipe),
		"query_group":int(plan.query_group),"record_tile":int(plan.record_tile),
	}


static func validate(task: Dictionary, plan: Dictionary) -> String:
	var problem: String = _task_error(task)
	if not problem.is_empty(): return problem
	problem = _plan_error(plan)
	if not problem.is_empty(): return problem
	var job_count: int = 0
	for query: Dictionary in task.queries: job_count += int(query.get("repeat",1))
	if int(plan.query_group) > job_count: return "query_group"
	if task.release == "serial" and int(plan.query_group) != 1: return "serial_group"
	return ""


static func condition_id(task: Dictionary) -> String:
	if not _task_error(task).is_empty(): return ""
	return JSON.stringify({
		"model":MODEL_VERSION,"task":_normalized_task(task),
		"memory":{
			"model":Simulator.MODEL_VERSION,"cache_lines":Simulator.CACHE_LINES,
			"line_bytes":Recipe.LINE_BYTES,"word_bytes":Recipe.WORD_BYTES,
			"read_lookup":Simulator.READ_LOOKUP,"fill_cycles":Simulator.FILL_CYCLES,
			"write_cycles":Simulator.WRITE_CYCLES,"compute_cycles":1,"output_cycles":1,
			"cache_policy":"fully_associative_lru","write_policy":"write_through_no_allocate",
		},
	},"",true).sha256_text()


static func plan_id(plan: Dictionary) -> String:
	var normalized: Dictionary = normalize_plan(plan)
	if normalized.is_empty(): return ""
	if normalized.copy_mode == "none":
		normalized.erase("copy_fields")
		normalized.erase("recipe")
	return JSON.stringify({"model":MODEL_VERSION,"plan":normalized},"",true).sha256_text()


static func evaluate(task: Dictionary, plan: Dictionary) -> Dictionary:
	var problem: String = validate(task,plan)
	if not problem.is_empty(): return {"valid":false,"error":problem,"run":null}
	var normalized_task: Dictionary = _normalized_task(task)
	var normalized_plan: Dictionary = normalize_plan(plan)
	var measured: LayoutRun = Executor.new().measure(normalized_task,normalized_plan)
	measured.model_version = MODEL_VERSION
	measured.case_signature = condition_id(normalized_task)
	measured.recipe_signature = plan_id(normalized_plan)
	return {"valid":true,"error":String(measured.metrics.error),"run":measured}


static func _task_error(task: Dictionary) -> String:
	if not _keys_exact(task,TASK_KEYS): return "task"
	if not task.id is String or task.id not in SCENARIO_IDS: return "task"
	if not task.release is String or task.release not in ["batch","serial"]: return "release"
	if not _integer(task.scratch_limit,0,MAX_SCRATCH_BYTES): return "scratch_limit"
	if not task.records is Array or task.records.is_empty() or task.records.size() > Recipe.MAX_RECORDS: return "records"
	for record: Variant in task.records:
		if not record is Array or record.size() != Recipe.FIELD_COUNT: return "records"
		for value: Variant in record:
			if not _integer(value,0,100000): return "value"
	if not task.queries is Array or task.queries.is_empty() or task.queries.size() > 8: return "queries"
	var jobs: int = 0
	var query_values: int = 0
	var output_values: int = 0
	for query: Variant in task.queries:
		if not query is Dictionary or not query.has_all(["kind","fields"]): return "queries"
		for key: Variant in query:
			if not key is String or key not in QUERY_KEYS: return "queries"
		if not query.kind is String or query.kind not in ["sum","records"]: return "queries"
		if not query.fields is Array or query.fields.is_empty() or query.fields.size() > Recipe.FIELD_COUNT: return "queries"
		for field: Variant in query.fields:
			if not _integer(field,0,Recipe.FIELD_COUNT-1): return "queries"
		if not _integer(query.get("repeat",1),1,MAX_JOBS): return "queries"
		var indices: Variant = query.get("indices",[])
		if not indices is Array or indices.size() > Recipe.MAX_RECORDS: return "indices"
		for index: Variant in indices:
			if not _integer(index,0,task.records.size()-1): return "indices"
		var repeat: int = int(query.get("repeat",1))
		var index_count: int = task.records.size() if indices.is_empty() else indices.size()
		var values: int = index_count*query.fields.size()*repeat
		jobs += repeat
		query_values += values
		output_values += repeat if query.kind == "sum" else values
	if jobs > MAX_JOBS: return "jobs"
	if query_values > MAX_QUERY_VALUES: return "query_values"
	if output_values > MAX_OUTPUT_VALUES: return "output_values"
	# Worst case: lookup/eviction/fill/read/compute per query value; read/write
	# preparation costs at most five events per copied word. No trace truncation.
	var max_events: int = 5*query_values+output_values+5*task.records.size()*Recipe.FIELD_COUNT+2*jobs+3
	if max_events > MAX_TRACE_EVENTS: return "trace_limit"
	return ""


static func _plan_error(plan: Dictionary) -> String:
	if not _keys_exact(plan,PLAN_KEYS): return "plan"
	if not plan.copy_mode is String or plan.copy_mode not in ["none","full"]: return "copy_mode"
	if not _integer(plan.query_group,1,MAX_JOBS): return "query_group"
	if not _integer(plan.record_tile,1,Recipe.MAX_RECORDS): return "record_tile"
	if not plan.copy_fields is Array or plan.copy_fields.size() > Recipe.FIELD_COUNT: return "copy_fields"
	if plan.copy_mode == "full" and plan.copy_fields.is_empty(): return "copy_fields"
	var seen: Array[int] = []
	for field: Variant in plan.copy_fields:
		if not _integer(field,0,Recipe.FIELD_COUNT-1) or seen.has(int(field)): return "copy_fields"
		seen.append(int(field))
	if not _recipe_valid(plan.recipe): return "recipe"
	return ""


static func _recipe_valid(value: Variant) -> bool:
	if not _keys_exact(value,["groups","block"]): return false
	if not _integer(value.block,0,Recipe.MAX_RECORDS): return false
	if not value.groups is Array or value.groups.is_empty() or value.groups.size() > Recipe.FIELD_COUNT: return false
	for group: Variant in value.groups:
		if not _keys_exact(group,["fields","order"]): return false
		if not group.order is String or group.order not in ["record","field"]: return false
		if not group.fields is Array or group.fields.is_empty() or group.fields.size() > Recipe.FIELD_COUNT: return false
		for field: Variant in group.fields:
			if not _integer(field,0,Recipe.FIELD_COUNT-1): return false
	return Recipe.error(value).is_empty()


static func _normalized_task(task: Dictionary) -> Dictionary:
	var records: Array[Array] = []
	for raw_record: Array in task.records:
		var record: Array[int] = []
		for value: Variant in raw_record: record.append(int(value))
		records.append(record)
	var queries: Array[Dictionary] = []
	for raw_query: Dictionary in task.queries:
		var fields: Array[int] = []
		var indices: Array[int] = []
		for field: Variant in raw_query.fields: fields.append(int(field))
		for index: Variant in raw_query.get("indices",[]): indices.append(int(index))
		queries.append({
			"kind":String(raw_query.kind),"fields":fields,
			"repeat":int(raw_query.get("repeat",1)),"indices":indices,
		})
	return {
		"id":String(task.id),"records":records,"queries":queries,
		"release":String(task.release),"scratch_limit":int(task.scratch_limit),
	}


static func _keys_exact(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key: Variant in value:
		if not key is String or key not in keys: return false
	return true


static func _integer(value: Variant, low: int, high: int) -> bool:
	return Recipe._integer(value) and float(value) >= float(low) and float(value) <= float(high)
