extends SceneTree
## Isolated scheduling proof. Scope is declared in /private/tmp/vnb-round4-model-audit.md.
## Root alone runs this script. No player state/save/progression calls.
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const PROBE_MODEL: String = "layout-scheduling-proof-1"
const TILES: Array[int] = [1,2,4,8,17]
const MAX_CANDIDATES: int = 340
var failures: Array[String] = []
var measured_count: int = 0
var started_us: int = 0


class ScheduledProbe:
	extends "res://src/layout_chapter/layout_simulator.gd"
	var query_group: int = 1
	var record_tile: int = 17
	var response_cycles: Array[int] = []
	var job_outputs: bool = false
	var active_job: int = -1

	func measure(task: Dictionary, design: Dictionary, group: int, tile: int) -> LayoutRun:
		query_group = group
		record_tile = tile
		response_cycles.clear()
		job_outputs = false
		active_job = -1
		assert(task.release in ["batch","serial"])
		assert(task.release != "serial" or group == 1)
		assert(design.strategy in ["direct","full"])
		assert(group >= 1 and group <= 16 and tile >= 1 and tile <= 64)
		var measured: LayoutRun = super.run(task,design)
		# The proof cannot be mistaken for official layout-memory-1 evidence.
		measured.model_version = "layout-scheduling-proof-1"
		measured.case_signature = JSON.stringify(task,"",true).sha256_text()
		measured.recipe_signature = JSON.stringify({
			"model":measured.model_version,"design":normalized_design(design),
			"query_group":query_group,"record_tile":record_tile,
		},"",true).sha256_text()
		measured.metrics["response_cycles"] = response_cycles.duplicate()
		measured.metrics["first_request_cycles"] = response_cycles[0] if not response_cycles.is_empty() else 0
		return measured

	func _query_batch(queries: Array, first: int, count: int) -> void:
		var jobs: Array[Dictionary] = []
		for query_index: int in queries.size():
			var query: Dictionary = queries[query_index]
			var slots: Dictionary = output_slots[query_index]
			for repetition: int in slots.slots.size():
				jobs.append({
					"id":jobs.size(),"query_index":query_index,"repetition":repetition,
					"indices":slots.indices,"slot":int(slots.slots[repetition]),
					"remaining":slots.indices.size()*query.fields.size(),
					"output_count":1 if query.kind == "sum" else slots.indices.size()*query.fields.size(),
					"responded":false,
				})
				response_cycles.append(0)
		for group_first: int in range(0,jobs.size(),query_group):
			for tile_first: int in range(first,first+count,record_tile):
				var tile_length: int = mini(record_tile,first+count-tile_first)
				for job_index: int in range(group_first,mini(group_first+query_group,jobs.size())):
					var job: Dictionary = jobs[job_index]
					if job.responded: continue
					var query: Dictionary = queries[int(job.query_index)]
					active_job = job_index
					_consume_tile(query,job,tile_first,tile_length)
					if not failure.is_empty(): return
					for record: int in job.indices:
						if record >= tile_first and record < tile_first+tile_length:
							job.remaining -= query.fields.size()
					if int(job.remaining) == 0:
						_emit_response(job)
		active_job = -1

	func _consume_tile(query: Dictionary, job: Dictionary, first: int, count: int) -> void:
		# Same value loop and real read/compute costs as the old kernel. A retained
		# copy's address origin is its allocation, never the current query tile.
		stage = "query"
		for index: int in job.indices.size():
			var record: int = int(job.indices[index])
			if record < first or record >= first+count: continue
			for field_index: int in query.fields.size():
				var field: int = int(query.fields[field_index])
				var address: int = int(trace.source_map.addresses[record*4+field])
				if not current_copy.is_empty() and copied_fields.has(field):
					address = int(current_copy.addresses[(record-int(current_copy.first_record))*4+field])
				var value: int = _read(address,record,field)
				if not failure.is_empty(): return
				_event(&"compute",1,address,record,field,value,0,&"CACHE",&"COMPUTE")
				var slot: int = int(job.slot)
				if query.kind == "sum": trace.output_values[slot] += value
				else: trace.output_values[slot+index*query.fields.size()+field_index] = value

	func _emit_response(job: Dictionary) -> void:
		var prior_stage: String = stage
		stage = "output"
		job_outputs = true
		for offset: int in int(job.output_count):
			_event(&"output",1,-1,-1,-1,trace.output_values[int(job.slot)+offset],0,&"COMPUTE",&"OUTPUT")
		_event(&"response",0,-1,-1,-1,int(job.id),0,&"OUTPUT",&"OUTPUT")
		trace.events[-1].details["job"] = int(job.id)
		trace.events[-1].details["query"] = int(job.query_index)
		trace.events[-1].details["repetition"] = int(job.repetition)
		response_cycles[int(job.id)] = clock_cycle
		job.responded = true
		job_outputs = false
		stage = prior_stage

	func _event(kind: StringName, duration: int, address: int, record: int, field: int, value: int, bytes: int, from: StringName, to: StringName) -> void:
		# Base run's final output loop is suppressed: each real output was charged
		# exactly once at its job completion, before that job's response marker.
		if kind == &"output" and not job_outputs: return
		super._event(kind,duration,address,record,field,value,bytes,from,to)
		if stage == "query" or kind in [&"output",&"response"]:
			trace.events[-1].details["job"] = active_job


func _init() -> void:
	var profile: String = str(ProjectSettings.get_setting("application/config/custom_user_dir_name",""))
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir",false)) or not profile.begins_with("VonNeumannBottleneckChecks/"):
		print("VNB_SCHEDULE_ERROR isolated VonNeumannBottleneckChecks profile required")
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	started_us = Time.get_ticks_usec()
	print("VNB_SCHEDULE_SCOPE "+JSON.stringify({
		"model":PROBE_MODEL,"memory_model":Simulator.MODEL_VERSION,"candidates":MAX_CANDIDATES,
		"record_count":17,"scratch_bytes":160,"tiles":TILES,
		"plans":_plans(),"scenarios":_scenarios(),
		"scope":"bounded scheduling proof; no official progression, thresholds or optimality claim",
	}))
	for task: Dictionary in _scenarios():
		_probe(task)
	if measured_count != MAX_CANDIDATES:
		failures.append("Declared340 candidates differ from measured "+str(measured_count))
	print("VNB_SCHEDULE_DONE "+JSON.stringify({
		"candidates":measured_count,"elapsed_ms":(Time.get_ticks_usec()-started_us)/1000.0,
		"failures":failures,
	}))
	quit(0 if failures.is_empty() else 1)


func _scenarios() -> Array[Dictionary]:
	var tasks: Array[Dictionary] = []
	for workload: String in ["temperature8","temperature16","mixed9"]:
		for release: String in ["batch","serial"]:
			var task: Dictionary = Catalog.cases("mixed" if workload == "mixed9" else "batches")[0].duplicate(true)
			task["name"] = workload+"/"+release
			task["release"] = release
			task["target_cycles"] = 0
			task["target_bytes"] = 0
			task["scratch_limit"] = 160
			if workload == "temperature16": task.queries[0].repeat = 16
			task["query_groups"] = [1] if release == "serial" else [1,2,4,8] if workload == "temperature8" else [1,2,4,8,16] if workload == "temperature16" else [1,2,4,8,9]
			tasks.append(task)
	return tasks


func _plans() -> Array[Dictionary]:
	var hot: Dictionary = {"groups":[{"fields":[0,3],"order":"record"},{"fields":[1,2],"order":"record"}],"block":0}
	return [
		{"id":"direct","design":Catalog.starter_design()},
		{"id":"copy-temperature","design":{"recipe":Recipe.field_major(),"strategy":"full","copy_fields":[0],"batch":4}},
		{"id":"copy-hot","design":{"recipe":hot,"strategy":"full","copy_fields":[0,3],"batch":4}},
		{"id":"copy-cold","design":{"recipe":hot,"strategy":"full","copy_fields":[1,2],"batch":4}},
	]


func _probe(task: Dictionary) -> void:
	var rows: Array[Dictionary] = []
	var classes: Dictionary = {}
	for group: int in task.query_groups:
		for tile: int in TILES:
			for plan: Dictionary in _plans():
				var run: LayoutRun = ScheduledProbe.new().measure(task,plan.design,group,tile)
				var row: Dictionary = _row(task,plan,group,tile,run)
				rows.append(row)
				measured_count += 1
				_check_run(task,plan.design,run,row.id)
				var key: String = JSON.stringify([row.correct,row.first,row.cycles,row.traffic,row.peak])
				if not classes.has(key):
					classes[key] = row.duplicate(true)
					classes[key]["count"] = 0
					classes[key]["examples"] = []
				classes[key].count += 1
				if classes[key].examples.size() < 6: classes[key].examples.append(row.id)
	var frontier: Array[Dictionary] = []
	for row: Dictionary in classes.values():
		if not row.correct: continue
		var dominated: bool = false
		for other: Dictionary in classes.values():
			if other.correct and _dominates(other,row):
				dominated = true
				break
		if not dominated: frontier.append(row)
	var selected: Dictionary = {}
	for metric: String in ["first","cycles","peak"]:
		var best: Dictionary = {}
		for row: Dictionary in rows:
			if row.correct and (best.is_empty() or int(row[metric]) < int(best[metric])): best = row
		if not best.is_empty(): selected[best.id] = best
	var repeated: Array[Dictionary] = []
	for row: Dictionary in selected.values():
		var again: LayoutRun = ScheduledProbe.new().measure(task,row.design,int(row.group),int(row.tile))
		var restored_design: Dictionary = JSON.parse_string(JSON.stringify(row.design))
		var restored: LayoutRun = ScheduledProbe.new().measure(task,restored_design,int(row.group),int(row.tile))
		var stable: bool = row.trace_id == again.canonical_signature().sha256_text() and row.trace_id == restored.canonical_signature().sha256_text()
		repeated.append({"id":row.id,"stable":stable})
		if not stable: failures.append(String(task.name)+": unstable "+String(row.id))
	print("VNB_SCHEDULE_RESULT "+JSON.stringify({
		"scenario":task.name,"candidate_count":rows.size(),"frontier":frontier,
		"classes":classes.values(),"repeats":repeated,
	}))


func _row(task: Dictionary, plan: Dictionary, group: int, tile: int, run: LayoutRun) -> Dictionary:
	return {
		"id":"%s/group%d/tile%d" % [plan.id,group,tile],"scenario":task.name,
		"design":plan.design.duplicate(true),"group":group,"tile":tile,"correct":run.passed,
		"cycles":run.metrics.total_cycles,
		"traffic":int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes),
		"peak":run.metrics.peak_extra_bytes,"first":run.metrics.first_request_cycles,
		"responses":run.metrics.response_cycles.duplicate(),
		"trace_id":run.canonical_signature().sha256_text(),
	}


func _dominates(a: Dictionary, b: Dictionary) -> bool:
	var strictly: bool = false
	for metric: String in ["first","cycles","traffic","peak"]:
		if int(a[metric]) > int(b[metric]): return false
		strictly = strictly or int(a[metric]) < int(b[metric])
	return strictly


func _check_run(task: Dictionary, design: Dictionary, run: LayoutRun, label: String) -> void:
	var consumed: int = 0
	var output_count: int = 0
	var job_count: int = 0
	for query: Dictionary in task.queries:
		var indices: Array = query.get("indices",[])
		var count: int = task.records.size() if indices.is_empty() else indices.size()
		var repeat: int = int(query.get("repeat",1))
		consumed += count*query.fields.size()*repeat
		output_count += repeat if query.kind == "sum" else count*query.fields.size()*repeat
		job_count += repeat
	var copied: int = 0 if design.strategy == "direct" else task.records.size()*design.copy_fields.size()
	var expected_cycles: int = 2*consumed+output_count+10*copied+16*int(run.metrics.fills)
	var expected_traffic: int = 4*copied+16*int(run.metrics.fills)
	var responses: int = 0
	var outputs: int = 0
	var serial_responses: int = 0
	for event: SimulationEvent in run.events:
		if event.kind == &"output": outputs += 1
		if event.kind == &"response":
			responses += 1
			serial_responses += 1
		elif task.release == "serial" and event.details.get("stage","") == "query" and event.kind in [&"lookup",&"read",&"compute",&"fill",&"evict"]:
			if int(event.details.get("job",-1)) != serial_responses:
				failures.append(String(task.name)+": cross-request execution "+label)
				break
	var okay: bool = (
		run.passed and int(run.metrics.total_cycles) == expected_cycles
		and int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes) == expected_traffic
		and outputs == output_count and responses == job_count
		and run.metrics.response_cycles.size() == job_count
	)
	if not okay: failures.append(String(task.name)+": output/accounting/response mismatch "+label)
