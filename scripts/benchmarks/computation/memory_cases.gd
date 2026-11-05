extends RefCounted
## Deterministic computation fixtures. Timing, snapshots and verification belong
## to the shared runner; every returned run retains its complete event objects.

const LocalityCore = preload("res://src/simulation/simulation_core.gd")
const LocalityParser = preload("res://src/simulation/dsl_parser.gd")
const LocalityPrograms = preload("res://src/simulation/program_templates.gd")
const SystemCore = preload("res://src/system_lab/system_simulation_core.gd")
const SystemParser = preload("res://src/system_lab/system_dsl_parser.gd")
const SystemCatalog = preload("res://src/system_lab/system_level_catalog.gd")
const SystemTopologyType = preload("res://src/system_lab/system_topology.gd")
const SystemReceipt = preload("res://src/system_lab/system_run_receipt.gd")
const OverlapCore = preload("res://src/overlap_chapter/overlap_simulator.gd")
const OverlapCatalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
const LayoutCore = preload("res://src/layout_chapter/layout_simulator.gd")
const LayoutCatalog = preload("res://src/layout_chapter/layout_catalog.gd")
const LayoutRecipeType = preload("res://src/layout_chapter/layout_recipe.gd")
const Scheduling = preload("res://experiments/layout_strategy/model.gd")
const TraceType = preload("res://src/simulation/simulation_trace.gd")
const EventType = preload("res://src/simulation/simulation_event.gd")
const SystemTraceType = preload("res://src/system_lab/system_trace.gd")
const SystemEventType = preload("res://src/system_lab/system_event.gd")
const LayoutRunType = preload("res://src/layout_chapter/layout_run.gd")


static func cases() -> Array[Dictionary]:
	return [
		_spec("memory.locality.public", "locality",
			"Official row/column DSL, three cache capacities and direct RAM.",
			{"capacities":[1,2,4]}),
		_spec("memory.locality.blocked64", "locality",
			"Bounded 64-pass public workload, unblocked versus one-line groups.",
			{"passes":64,"groups":[0,1]}),
		_spec("memory.system.public", "system",
			"Official final 4/16/64-input cases, complete traces and receipt.",
			{"level":"bottleneck","cpu":"cpu_balanced","ram":"ram_balanced","bus":"bus_4"}),
		_spec("memory.system.failure_reuse", "system",
			"Valid, disconnected, out-of-bounds and valid runs on one core.",
			{"level":"assembly","cpu":"cpu_balanced","ram":"ram_balanced","bus":"bus_8"}),
		_spec("memory.overlap.public", "overlap",
			"All six authored buffer/cache workloads through public evaluation.",
			{"levels":["arrival","buffers","backpressure","prefetch","distance","synthesis"]}),
		_spec("memory.overlap.queue64", "overlap",
			"64 legal batches with over-eager prefetch, bounded FIFO and eviction.",
			{"count":64,"transfer":16,"compute":8,"capacity":1}),
		_spec("memory.overlap.failure_reuse", "overlap",
			"Backpressure success, premature consumption, deadlock and reset.",
			{"level":"backpressure"}),
		_spec("memory.layout.public_native64", "layout",
			"All six official layouts plus record/field-major native 64-record runs.",
			{"levels":["fields","records","hot_cold","relocation","batches","mixed"],"count":64}),
		_spec("memory.layout.batch64_reuse", "layout",
			"64 one-record copies, allocation failure, invalid recipe and reset.",
			{"count":64,"repeat":8,"scratch_limit":16,"batch":1}),
		_spec("memory.scheduling.public", "scheduling",
			"Six public conditions with source-only and retained-copy measurements.",
			{"levels":["scan_batch","scan_serial","mixed_batch","mixed_serial","scan_pair_serial","split_fields_serial"]}),
		_spec("memory.scheduling.maximum4096", "scheduling",
			"Declared 4096 query/output-value bound, 16 jobs and a seven-record tail.",
			{"count":64,"repeat":16,"group":16,"tile":7}),
		_spec("memory.scheduling.failure_reuse", "scheduling",
			"Public allocation/schema failures, sparse duplicate outputs and executor reuse.",
			{"task":"mixed_batch","group":3,"tile":4}),
	]


static func run_case(spec: Dictionary) -> Variant:
	var input: Dictionary = (spec.get("input", {}) as Dictionary).duplicate(true)
	match String(spec.get("id", "")):
		"memory.locality.public": return _locality_public(input)
		"memory.locality.blocked64": return _locality_blocked(input)
		"memory.system.public": return _system_public(input)
		"memory.system.failure_reuse": return _system_failure_reuse(input)
		"memory.overlap.public": return _overlap_public(input)
		"memory.overlap.queue64": return _overlap_queue(input)
		"memory.overlap.failure_reuse": return _overlap_failure_reuse(input)
		"memory.layout.public_native64": return _layout_public(input)
		"memory.layout.batch64_reuse": return _layout_batch_reuse(input)
		"memory.scheduling.public": return _scheduling_public(input)
		"memory.scheduling.maximum4096": return _scheduling_maximum(input)
		"memory.scheduling.failure_reuse": return _scheduling_failure_reuse(input)
	return {"adapter_error":"unknown_case","id":String(spec.get("id", ""))}


static func _spec(id: String, subsystem: String, description: String, input: Dictionary) -> Dictionary:
	return {"id":id,"subsystem":subsystem,"description":description,"input":input}


static func _integers(values: Array) -> Array[int]:
	# JSON round trips produce untyped arrays and floating-point numbers.
	var result: Array[int] = []
	for value: Variant in values:
		result.append(int(value))
	return result


static func _locality_public(input: Dictionary) -> Dictionary:
	var core := LocalityCore.new()
	var runs: Array = []
	var data: Array[int] = _integers(LocalityCore.official_data_copy())
	for source: String in [LocalityPrograms.ROW_FIRST, LocalityPrograms.COLUMN_FIRST]:
		for capacity: int in _integers(input.capacities):
			runs.append(core.run_source(source, data, capacity, "benchmark-public-locality"))
	var program = LocalityParser.parse(LocalityPrograms.ROW_FIRST)
	runs.append(core.run_workload(program, data, 0, "benchmark-direct-locality", 1, 0, true))
	return {"runs":runs,"final_simulator":core}


static func _locality_blocked(input: Dictionary) -> Dictionary:
	var core := LocalityCore.new()
	var program = LocalityParser.parse(LocalityPrograms.ROW_FIRST)
	var data: Array[int] = _integers(LocalityCore.official_data_copy())
	var runs: Array = []
	for group: int in _integers(input.groups):
		runs.append(core.run_workload(
			program, data, 1, "benchmark-blocked-locality", int(input.passes), group, false))
	return {"runs":runs,"final_simulator":core}


static func _system_topology(catalog, input: Dictionary):
	var topology := SystemTopologyType.new()
	for kind: String in ["cpu","ram","bus"]:
		topology.set_part(StringName(kind.to_upper()), catalog.part(StringName(input[kind])))
	topology.connect_required_routes()
	return topology


static func _system_public(input: Dictionary) -> Dictionary:
	var catalog := SystemCatalog.new()
	var level_id := StringName(input.level)
	var level: Dictionary = catalog.definition(level_id)
	var program = SystemParser.parse(String(level.program_source))
	var topology = _system_topology(catalog, input)
	var core := SystemCore.new()
	var runs: Array = []
	for fixture: Dictionary in level.cases:
		runs.append(core.run(program, topology, _integers(fixture.input),
			_integers(fixture.expected), String(fixture.name)))
	var receipt := SystemReceipt.new()
	receipt.populate_from_traces(level_id, runs, catalog.test_set_signature(level_id),
		{"cpu":String(input.cpu),"ram":String(input.ram),"bus":String(input.bus)})
	return {"runs":runs,"receipt":receipt,"final_simulator":core,"topology":topology}


static func _system_failure_reuse(input: Dictionary) -> Dictionary:
	var catalog := SystemCatalog.new()
	var level: Dictionary = catalog.definition(StringName(input.level))
	var fixture: Dictionary = level.cases[1] # Official 255 -> 0 byte-wrap fixture.
	var program = SystemParser.parse(String(level.program_source))
	var topology = _system_topology(catalog, input)
	var core := SystemCore.new()
	var runs: Array = []
	runs.append(core.run(program, topology, _integers(fixture.input),
		_integers(fixture.expected), String(fixture.name)))
	var disconnected = topology.duplicate_topology()
	disconnected.connections.clear()
	runs.append(core.run(program, disconnected, _integers(fixture.input),
		_integers(fixture.expected), "benchmark-disconnected"))
	var bounds_program = SystemParser.parse(
		"value = load(INPUT[63])\nstore(OUTPUT[0], value)")
	runs.append(core.run(bounds_program, topology, _integers(fixture.input),
		_integers(fixture.expected), "benchmark-out-of-bounds"))
	runs.append(core.run(program, topology, _integers(fixture.input),
		_integers(fixture.expected), String(fixture.name)))
	return {"runs":runs,"final_simulator":core,"topology":topology}


static func _overlap_public(input: Dictionary) -> Dictionary:
	var results: Dictionary = {}
	for raw_id: Variant in input.levels:
		var id: String = String(raw_id)
		var design: Dictionary = OverlapCatalog.reference_solution(id)
		results[id] = OverlapCatalog.evaluate(id, design.board, String(design.program))
	return results


static func _overlap_queue(input: Dictionary) -> Dictionary:
	var count: int = int(input.count)
	var values: Array[int] = []
	var durations: Array[int] = []
	var lines: PackedStringArray = PackedStringArray()
	for index: int in range(count):
		values.append((index * 7 + 3) % 31)
		durations.append(int(input.compute))
		lines.append("prefetch %d" % index)
	for index: int in range(count):
		lines.append("read %d" % index)
		lines.append("idle")
	var task: Dictionary = {
		"name":"benchmark-queue64","values":values,"compute":durations,
		"transfer":int(input.transfer),"budget":int(input.capacity),
		"work":0,"commands":OverlapCatalog.CACHE_COMMANDS.duplicate(),
	}
	var core := OverlapCore.new()
	var run = core.run("\n".join(lines), OverlapCatalog.cache_board(int(input.capacity)), task)
	return {"run":run,"final_simulator":core}


static func _overlap_failure_reuse(input: Dictionary) -> Dictionary:
	var id: String = String(input.level)
	var design: Dictionary = OverlapCatalog.reference_solution(id)
	var task: Dictionary = OverlapCatalog.cases(id)[0]
	var core := OverlapCore.new()
	var runs: Array = []
	runs.append(core.run(String(design.program), design.board, task))
	runs.append(core.run("fetch A 0\nconsume A", design.board, task))
	runs.append(core.run("ready A", design.board, task))
	runs.append(core.run(String(design.program), design.board, task))
	return {"runs":runs,"final_simulator":core}


static func _layout_public(input: Dictionary) -> Dictionary:
	var results: Dictionary = {}
	for raw_id: Variant in input.levels:
		var id: String = String(raw_id)
		results[id] = LayoutCatalog.evaluate(id, LayoutCatalog.reference_solution(id))
	var task: Dictionary = _native_layout_task(input)
	var core := LayoutCore.new()
	var runs: Array = []
	var design: Dictionary = LayoutCatalog.starter_design()
	for recipe: Dictionary in [LayoutRecipeType.record_major(), LayoutRecipeType.field_major()]:
		design.recipe = recipe
		runs.append(core.run(task, design))
	results["native64"] = {"runs":runs,"final_simulator":core}
	return results


static func _native_layout_task(input: Dictionary) -> Dictionary:
	return {
		"name":"benchmark-native64","records":LayoutCatalog.records(int(input.count), 5),
		"queries":[
			{"kind":"sum","fields":[0],"repeat":2},
			{"kind":"records","fields":[0,1,2,3],"indices":[63,0,31]},
		],"native_layout":true,"scratch_limit":0,
	}


static func _batch_layout_task(input: Dictionary) -> Dictionary:
	return {
		"name":"benchmark-batch64","records":LayoutCatalog.records(int(input.count), 11),
		"queries":[{"kind":"sum","fields":[0,3],"repeat":int(input.repeat)}],
		"native_layout":false,"scratch_limit":int(input.scratch_limit),
	}


static func _layout_batch_reuse(input: Dictionary) -> Dictionary:
	var task: Dictionary = _batch_layout_task(input)
	var design: Dictionary = LayoutCatalog.starter_design()
	design.recipe = LayoutRecipeType.field_major()
	design.strategy = "batch"
	design.copy_fields = [0,1,2,3]
	design.batch = int(input.batch)
	var core := LayoutCore.new()
	var runs: Array = [core.run(task, design)]
	var too_large: Dictionary = design.duplicate(true)
	too_large.strategy = "full"
	runs.append(core.run(task, too_large))
	var invalid: Dictionary = design.duplicate(true)
	invalid.recipe.groups[0].fields = [0,0,2,3]
	runs.append(core.run(task, invalid))
	runs.append(core.run(task, design))
	return {"runs":runs,"final_simulator":core}


static func _scheduling_public(input: Dictionary) -> Dictionary:
	var results: Dictionary = {}
	for raw_id: Variant in input.levels:
		var id: String = String(raw_id)
		var task: Dictionary = Scheduling.scenario(id)
		var plan: Dictionary = Scheduling.starter_plan()
		var runs: Array = [Scheduling.evaluate(task, plan)]
		plan.copy_mode = "full"
		plan.copy_fields = [0,3] if id.begins_with("mixed") or id == "split_fields_serial" else [0]
		plan.recipe = LayoutRecipeType.field_major()
		runs.append(Scheduling.evaluate(task, plan))
		results[id] = runs
	return results


static func _scheduling_maximum(input: Dictionary) -> Dictionary:
	var task: Dictionary = _maximum_scheduling_task(input)
	var plan: Dictionary = Scheduling.starter_plan()
	plan.query_group = int(input.group)
	plan.record_tile = int(input.tile)
	return Scheduling.evaluate(task, plan)


static func _maximum_scheduling_task(input: Dictionary) -> Dictionary:
	var task: Dictionary = Scheduling.scenario("scan_batch")
	task.records = LayoutCatalog.records(int(input.count))
	task.queries = [{"kind":"records","fields":[0,1,2,3],"repeat":int(input.repeat),"indices":[]}]
	return task


static func _sparse_scheduling_task(input: Dictionary) -> Dictionary:
	var task: Dictionary = Scheduling.scenario(String(input.task))
	task.queries = [
		{"kind":"records","fields":[3,0,3],"repeat":2,"indices":[16,0,16,3]},
		{"kind":"sum","fields":[0,0],"repeat":1,"indices":[16,1,16]},
	]
	return task


static func _sparse_scheduling_plan(input: Dictionary) -> Dictionary:
	var plan: Dictionary = Scheduling.starter_plan()
	plan.query_group = int(input.group)
	plan.record_tile = int(input.tile)
	plan.copy_mode = "full"
	plan.copy_fields = [0,3]
	plan.recipe = {
		"groups":[{"fields":[3,0],"order":"field"},{"fields":[1,2],"order":"record"}],
		"block":4,
	}
	return plan


static func _scheduling_failure_reuse(input: Dictionary) -> Dictionary:
	var failed_task: Dictionary = Scheduling.scenario("scan_serial")
	failed_task.scratch_limit = 0
	var copy_plan: Dictionary = Scheduling.starter_plan()
	copy_plan.copy_mode = "full"
	copy_plan.recipe = LayoutRecipeType.field_major()
	var results: Dictionary = {"allocation":Scheduling.evaluate(failed_task, copy_plan)}
	var invalid_plan: Dictionary = copy_plan.duplicate(true)
	invalid_plan.query_group = 2
	results["invalid_serial_group"] = Scheduling.evaluate(failed_task, invalid_plan)
	var task: Dictionary = _sparse_scheduling_task(input)
	var plan: Dictionary = _sparse_scheduling_plan(input)
	results["public_sparse"] = Scheduling.evaluate(task, plan)
	var executor := Scheduling.Executor.new()
	var runs: Array = [executor.measure(failed_task, copy_plan)]
	runs.append(executor.measure(task, plan))
	runs.append(executor.measure(Scheduling.scenario("scan_serial"), Scheduling.starter_plan()))
	runs.append(executor.measure(task, plan))
	results["reused_runs"] = runs
	results["final_executor"] = executor
	return results


## Untimed semantic checks complement the runner's full-object parity checks.
## Expected work comes from fixtures and logical queries, never elapsed timings
## or a captured metric snapshot.
static func validate_case(spec: Dictionary, result: Variant) -> Array[String]:
	var issues: Array[String] = []
	var label: String = String(spec.get("id", "unknown"))
	if not spec.get("input") is Dictionary or not result is Dictionary:
		issues.append(label + ": expected input and result dictionaries")
		return issues
	var input: Dictionary = spec.input
	var report: Dictionary = result
	match label:
		"memory.locality.public":
			var runs: Array = _array(report.get("runs"), input.capacities.size()*2+1, label, issues)
			for index: int in range(runs.size()):
				var direct: bool = index == runs.size()-1
				var capacity: int = 0 if direct else int(input.capacities[index % input.capacities.size()])
				_validate_locality(runs[index], 1, capacity, label + "/%d" % index, issues)
		"memory.locality.blocked64":
			var runs: Array = _array(report.get("runs"), input.groups.size(), label, issues)
			for index: int in range(runs.size()):
				_validate_locality(runs[index], int(input.passes), 1, label + "/%d" % index, issues)
		"memory.system.public", "memory.system.failure_reuse":
			_validate_system_case(input, report, label.ends_with("failure_reuse"), label, issues)
		"memory.overlap.public":
			_expect(report.size() == input.levels.size(), label, "missing or extra official workflow", issues)
			for raw_id: Variant in input.levels:
				var id: String = String(raw_id)
				var nested: Dictionary = _dictionary(report.get(id), label + "/" + id, issues)
				_expect(nested.get("passed") == true, label + "/" + id, "reference workload did not pass", issues)
				var tasks: Array = OverlapCatalog.cases(id)
				var runs: Array = _array(nested.get("runs"), tasks.size(), label + "/" + id, issues)
				for index: int in range(runs.size()):
					_validate_overlap(runs[index], tasks[index], "", label + "/" + id + "/%d" % index, issues)
		"memory.overlap.queue64":
			var values: Array[int] = []
			var durations: Array[int] = []
			for index: int in range(int(input.count)):
				values.append((index*7+3)%31)
				durations.append(int(input.compute))
			var task: Dictionary = {"values":values,"compute":durations,"work":0,
				"transfer":int(input.transfer),"budget":int(input.capacity)}
			var stats: Dictionary = _validate_overlap(report.get("run"), task, "", label, issues)
			if not stats.is_empty():
				var run: Variant = report.run
				_expect(_metric(run.metrics,"queue_wait",label,issues)>0, label, "queue stress never waited", issues)
				_expect(_metric(run.metrics,"evictions",label,issues)>0, label, "cache stress never evicted", issues)
				_expect(_metric(run.metrics,"hits",label,issues)+_metric(run.metrics,"misses",label,issues)==int(input.count),
					label, "demand-read count differs from declared batches", issues)
				_validate_overlap_state(report.get("final_simulator"), run, int(input.count), label, issues)
		"memory.overlap.failure_reuse":
			var tasks: Array = OverlapCatalog.cases(String(input.level))
			var runs: Array = _array(report.get("runs"), 4, label, issues)
			for index: int in range(runs.size()):
				var failure: String = "not_ready" if index == 1 else "deadlock" if index == 2 else ""
				_validate_overlap(runs[index], tasks[0], failure, label + "/%d" % index, issues)
			if runs.size() == 4:
				_validate_recovery(runs[0], runs[3], label, issues)
				_validate_overlap_state(report.get("final_simulator"), runs[3], tasks[0].values.size(), label, issues)
		"memory.layout.public_native64":
			_validate_layout_public(input, report, label, issues)
		"memory.layout.batch64_reuse":
			var task: Dictionary = _batch_layout_task(input)
			var runs: Array = _array(report.get("runs"), 4, label, issues)
			for index: int in range(runs.size()):
				var failure: String = "space_limit" if index == 1 else "fields" if index == 2 else ""
				var stats: Dictionary = _validate_layout(runs[index], task, failure, label + "/%d" % index, issues)
				if runs[index] is LayoutRunType:
					_expect(runs[index].model_version==LayoutCore.MODEL_VERSION, label, "wrong layout model identity", issues)
				if failure.is_empty() and not stats.is_empty():
					_validate_copy(runs[index], stats, int(input.count)*4,
						ceili(float(input.count)/float(input.batch)), label + "/%d" % index, issues)
			if runs.size() == 4:
				_validate_recovery(runs[0], runs[3], label, issues)
				_validate_layout_state(report.get("final_simulator"), runs[3], task, label, issues)
		"memory.scheduling.public":
			_expect(report.size()==input.levels.size(), label, "missing or extra official workflow", issues)
			for raw_id: Variant in input.levels:
				var id: String = String(raw_id)
				var task: Dictionary = Scheduling.scenario(id)
				var runs: Array = _array(report.get(id), 2, label + "/" + id, issues)
				for index: int in range(runs.size()):
					var plan: Dictionary = Scheduling.starter_plan()
					if index == 1:
						plan.copy_mode = "full"
						plan.copy_fields = [0,3] if id.begins_with("mixed") or id == "split_fields_serial" else [0]
						plan.recipe = LayoutRecipeType.field_major()
					_validate_scheduling_envelope(runs[index], task, plan, "", label + "/" + id + "/%d" % index, issues)
		"memory.scheduling.maximum4096":
			var task: Dictionary = _maximum_scheduling_task(input)
			var plan: Dictionary = Scheduling.starter_plan()
			plan.query_group = int(input.group)
			plan.record_tile = int(input.tile)
			_validate_scheduling_envelope(report, task, plan, "", label, issues)
		"memory.scheduling.failure_reuse":
			_validate_scheduling_reuse(input, report, label, issues)
		_:
			issues.append(label + ": unknown semantic validator")
	return issues


static func _expect(condition: bool, label: String, message: String, issues: Array[String]) -> void:
	if not condition:
		issues.append(label + ": " + message)


static func _dictionary(value: Variant, label: String, issues: Array[String]) -> Dictionary:
	if not value is Dictionary:
		issues.append(label + ": expected dictionary")
		return {}
	return value


static func _array(value: Variant, count: int, label: String, issues: Array[String]) -> Array:
	if not value is Array or value.size() != count:
		issues.append(label + ": expected array of %d entries" % count)
		return []
	return value


static func _metric(metrics: Dictionary, key: String, label: String, issues: Array[String], minimum: int = 0) -> int:
	var value: Variant = metrics.get(key)
	if not value is int or value < minimum:
		issues.append(label + ": invalid integer metric " + key)
		return minimum-1
	return int(value)


static func _count(stats: Dictionary, kind: String) -> int:
	return int(stats.counts.get(kind, 0))


static func _duration(stats: Dictionary, kind: String) -> int:
	return int(stats.durations.get(kind, 0))


static func _trace_stats(value: Variant, label: String, issues: Array[String],
		system: bool = false, sequential: bool = true) -> Dictionary:
	if (system and not value is SystemTraceType) or (not system and not value is TraceType):
		issues.append(label + ": wrong trace type")
		return {}
	var stats: Dictionary = {"counts":{},"durations":{},"stages":{},"events":[],"duration":0}
	var previous_cycle: int = -1
	for event: Variant in value.events:
		if (system and not event is SystemEventType) or (not system and not event is EventType):
			issues.append(label + ": wrong or null event type")
			continue
		var kind: String = String(event.kind)
		_expect(not kind.is_empty() and event.cycle >= 0 and event.duration >= 0,
			label, "invalid event identity or time", issues)
		_expect(event.cycle >= previous_cycle, label, "event cycles moved backwards", issues)
		if sequential:
			_expect(event.cycle == int(stats.duration), label, "sequential event timeline has a gap or overlap", issues)
		previous_cycle = event.cycle
		stats.counts[kind] = int(stats.counts.get(kind,0))+1
		stats.durations[kind] = int(stats.durations.get(kind,0))+int(event.duration)
		stats.duration += event.duration
		var stage: String = String(event.details.get("stage",""))
		stats.stages[stage] = int(stats.stages.get(stage,0))+int(event.duration)
		stats.events.append(event)
	if sequential:
		_expect(int(stats.duration)==_metric(value.metrics,"total_cycles",label,issues),
			label, "event durations do not reconcile with total cycles", issues)
	return stats


static func _validate_locality(value: Variant, passes: int, capacity: int,
		label: String, issues: Array[String]) -> void:
	var stats: Dictionary = _trace_stats(value, label, issues)
	if stats.is_empty(): return
	var expected: int = 0
	for number: int in LocalityCore.OFFICIAL_DATA: expected += number
	_expect(value.passed and value.result_value==expected and value.expected_value==expected,
		label, "official locality sum failed", issues)
	_expect(value.cache_capacity_lines==capacity, label, "wrong cache capacity", issues)
	var loads: int = LocalityCore.ARRAY_LENGTH*passes
	_expect(_count(stats,"request")==loads and _count(stats,"compute")==loads
		and _count(stats,"store_result")==passes, label, "load/compute/result work was skipped", issues)
	var address_counts: Dictionary = {}
	for event: Variant in stats.events:
		if event.kind == &"request":
			var address: int = event.address
			_expect(address>=0 and address<LocalityCore.ARRAY_LENGTH, label, "load address outside official data", issues)
			if address>=0 and address<LocalityCore.ARRAY_LENGTH:
				_expect(event.value==LocalityCore.OFFICIAL_DATA[address], label, "load value disagrees with input", issues)
				address_counts[address] = int(address_counts.get(address,0))+1
		elif event.kind == &"store_result":
			_expect(event.value==expected, label, "one pass stored an incorrect result", issues)
	for address: int in range(LocalityCore.ARRAY_LENGTH):
		_expect(int(address_counts.get(address,0))==passes, label, "a data address was skipped or repeated", issues)
	var misses: int = _metric(value.metrics,"cache_misses",label,issues)
	var hits: int = _metric(value.metrics,"cache_hits",label,issues)
	var transfers: int = loads if capacity==0 else misses
	_expect(_count(stats,"cache_lookup")==(0 if capacity==0 else loads)
		and _count(stats,"cache_miss")==misses and _count(stats,"cache_hit")==hits
		and hits+misses==(0 if capacity==0 else loads), label, "cache counters differ from executed reads", issues)
	_expect(_count(stats,"ram_access")==transfers and _count(stats,"bus_request")==transfers
		and _count(stats,"line_return")==(0 if capacity==0 else misses)
		and _count(stats,"cache_fill")==(0 if capacity==0 else misses)
		and _count(stats,"value_return")==(loads if capacity==0 else 0),
		label, "RAM/return events differ from actual transfers", issues)
	var compute: int = _duration(stats,"compute")+_duration(stats,"store_result")
	_expect(_metric(value.metrics,"compute_cycles",label,issues)==compute
		and _metric(value.metrics,"wait_cycles",label,issues)+compute==int(stats.duration),
		label, "compute and wait cycles do not reconcile", issues)
	_expect(_metric(value.metrics,"ram_bytes_transferred",label,issues)==transfers*(4 if capacity==0 else 16),
		label, "RAM bytes differ from transfer events", issues)
	_expect(_metric(value.metrics,"hardware_cost",label,issues)==(0 if capacity==0 else LocalityCore.CACHE_COSTS[capacity]),
		label, "hardware selection was not measured", issues)


static func _validate_system_case(input: Dictionary, report: Dictionary, reuse: bool,
		label: String, issues: Array[String]) -> void:
	var catalog := SystemCatalog.new()
	var level: Dictionary = catalog.definition(StringName(input.level))
	var fixtures: Array = level.cases
	var runs: Array = _array(report.get("runs"), 4 if reuse else fixtures.size(), label, issues)
	if reuse:
		if runs.size()!=4: return
		for index: int in [0,3]:
			_validate_system_run(runs[index], fixtures[1], 1, label + "/%d" % index, issues)
		for index: int in [1,2]:
			var failed: Variant = runs[index]
			if not failed is SystemTraceType:
				issues.append(label + "/%d: wrong failed trace type" % index)
				continue
			_expect(not failed.passed and failed.events.is_empty()
				and failed.expected_output==_integers(fixtures[1].expected),
				label + "/%d" % index, "invalid topology/bounds did not fail before work", issues)
			if index==1:
				_expect(failed.output_data.is_empty() and failed.metrics.is_empty(),
					label, "disconnected topology produced execution data", issues)
			else:
				_expect(failed.output_data==[0], label, "bounds failure did not retain zero output", issues)
				for metric: String in ["total_cycles","cpu_compute_cycles","cpu_wait_cycles","ram_service_cycles",
						"bus_control_cycles","bus_transfer_cycles","memory_requests","bytes_transferred"]:
					_expect(_metric(failed.metrics,metric,label,issues)==0, label, "bounds failure performed work", issues)
		_validate_recovery(runs[0],runs[3],label,issues)
		return
	for index: int in range(runs.size()):
		_validate_system_run(runs[index], fixtures[index], fixtures[index].input.size()*3, label + "/%d" % index, issues)
	var receipt: Variant = report.get("receipt")
	if not receipt is SystemReceipt:
		issues.append(label + ": missing system receipt")
		return
	_expect(receipt.all_passed and receipt.total_cases==fixtures.size() and receipt.passed_cases==fixtures.size(),
		label, "receipt did not retain every successful case", issues)
	_expect(receipt.case_metrics.size()==runs.size() and receipt.trace_signatures.size()==runs.size(),
		label, "receipt lost a case or trace binding", issues)
	_expect(String(receipt.level_id)==String(input.level)
		and receipt.test_set_signature==catalog.test_set_signature(StringName(input.level)),
		label, "receipt has wrong workload identity", issues)
	var totals: Dictionary = {}
	for index: int in range(runs.size()):
		if not runs[index] is SystemTraceType: continue
		if index<receipt.case_metrics.size():
			_expect(receipt.case_metrics[index]==runs[index].metrics, label, "receipt case metrics differ from trace", issues)
		if index<receipt.trace_signatures.size():
			_expect(receipt.trace_signatures[index]==runs[index].canonical_signature().sha256_text(),
				label, "receipt trace binding differs", issues)
		for key: Variant in runs[index].metrics:
			totals[key] = runs[index].metrics[key] if key in ["hardware_cost","bus_segments_per_word"] \
				else int(totals.get(key,0))+int(runs[index].metrics[key])
	_expect(receipt.metrics==totals, label, "receipt aggregation differs from actual cases", issues)
	for kind: String in ["cpu","ram","bus"]:
		_expect(String(receipt.part_ids.get(StringName(kind),""))==String(input[kind]),
			label, "receipt lost the chosen " + kind + " identity", issues)


static func _validate_system_run(value: Variant, fixture: Dictionary, compute_count: int,
		label: String, issues: Array[String]) -> void:
	var stats: Dictionary = _trace_stats(value,label,issues,true)
	if stats.is_empty(): return
	_expect(value.passed and value.output_data==_integers(fixture.expected)
		and value.expected_output==_integers(fixture.expected), label, "official system outputs failed", issues)
	var count: int = fixture.input.size()
	for kind: String in ["read_request","ram_read","read_data","write_request","write_data","ram_write"]:
		_expect(_count(stats,kind)==count, label, "missing system memory operation: " + kind, issues)
	_expect(_count(stats,"compute")==compute_count, label, "wrong arithmetic operation count", issues)
	for event: Variant in stats.events:
		if event.kind not in [&"read_data",&"ram_write"]: continue
		var index: Variant = event.details.get("index")
		var expected: Array = fixture.input if event.kind==&"read_data" else fixture.expected
		if not index is int or index<0 or index>=expected.size():
			issues.append(label + ": invalid memory operation index")
		else:
			_expect(event.details.get("value")==expected[index], label, "memory operation has wrong byte value", issues)
	_expect(_metric(value.metrics,"memory_requests",label,issues)==count*2
		and _metric(value.metrics,"bytes_transferred",label,issues)==count*2,
		label, "request/byte counters differ from workload", issues)
	var cpu: int = _duration(stats,"compute")
	var ram: int = _duration(stats,"ram_read")+_duration(stats,"ram_write")
	var control: int = _duration(stats,"read_request")+_duration(stats,"write_request")
	var transfer: int = _duration(stats,"read_data")+_duration(stats,"write_data")
	_expect(_metric(value.metrics,"cpu_compute_cycles",label,issues)==cpu
		and _metric(value.metrics,"ram_service_cycles",label,issues)==ram
		and _metric(value.metrics,"bus_control_cycles",label,issues)==control
		and _metric(value.metrics,"bus_transfer_cycles",label,issues)==transfer
		and _metric(value.metrics,"cpu_wait_cycles",label,issues)==ram+control+transfer,
		label, "system phase counters differ from events", issues)
	_expect(_metric(value.metrics,"hardware_cost",label,issues)>0
		and _metric(value.metrics,"bus_segments_per_word",label,issues)>0
		and not value.program_signature.is_empty() and not value.topology_signature.is_empty(),
		label, "missing measured hardware or program identity", issues)


static func _validate_overlap(value: Variant, task: Dictionary, failure: String,
		label: String, issues: Array[String]) -> Dictionary:
	var stats: Dictionary = _trace_stats(value,label,issues,false,false)
	if stats.is_empty(): return {}
	_expect(value.metrics.get("error")==failure and value.passed==failure.is_empty(),
		label, "unexpected overlap success/error result", issues)
	var total: int = _metric(value.metrics,"total_cycles",label,issues)
	var busy: int = _metric(value.metrics,"compute_busy",label,issues)
	var transfer: int = _metric(value.metrics,"transfer_busy",label,issues)
	var overlap: int = _metric(value.metrics,"overlap",label,issues)
	_expect(total<=OverlapCore.LIMIT and _count(stats,"state")==total
		and _metric(value.metrics,"wait",label,issues)+busy==total
		and overlap<=mini(busy,transfer) and busy<=total and transfer<=total,
		label, "overlap timeline/state accounting differs", issues)
	_expect(_metric(value.metrics,"queue_wait",label,issues)<=total
		and _metric(value.metrics,"evictions",label,issues)==_count(stats,"evict"),
		label, "queue/eviction accounting differs", issues)
	for key: String in ["hits","misses","cost","error_line"]:
		_metric(value.metrics,key,label,issues)
	_expect(_metric(value.metrics,"cost",label,issues)<=int(task.get("budget",3)),
		label, "overlap hardware exceeded the declared budget", issues)
	var state_cycle: int = 0
	var output_index: int = 0
	var expected_sum: int = 0
	for number: Variant in task.values: expected_sum += int(number)*2+1
	for event: Variant in stats.events:
		if event.kind==&"state":
			state_cycle += 1
			_expect(event.cycle==state_cycle, label, "state event skipped or repeated a cycle", issues)
		elif event.kind==&"output":
			_expect(output_index<task.values.size(), label, "too many output events", issues)
			if output_index<task.values.size():
				_expect(event.details.get("batch")==output_index
					and event.details.get("value")==int(task.values[output_index])*2+1,
					label, "output order/value differs from declared batches", issues)
			output_index += 1
	if not failure.is_empty():
		_expect(_count(stats,"error")==1 and _count(stats,"output")==0 and _count(stats,"compute")==0
			and total==0 and value.metrics.get("outputs")==[],
			label, "intentional early failure performed successful work", issues)
		_expect(_count(stats,"request")==(1 if failure=="not_ready" else 0)
			and _count(stats,"transfer")==(1 if failure=="not_ready" else 0),
			label, "intentional early failure did not execute its expected prefix", issues)
		if not stats.events.is_empty():
			_expect(stats.events[-1].kind==&"error" and stats.events[-1].details.get("code")==failure,
				label, "failure trace lacks the expected terminal error", issues)
		return stats
	var work: int = int(task.get("work",0))
	var compute_duration: int = work
	for duration: Variant in task.compute: compute_duration += int(duration)
	_expect(_count(stats,"error")==0 and _count(stats,"output")==task.values.size()
		and _count(stats,"compute")==task.values.size()+(1 if work>0 else 0)
		and _duration(stats,"compute")==compute_duration and busy==compute_duration
		and transfer==_duration(stats,"transfer")
		and _count(stats,"transfer")>=task.values.size()
		and _count(stats,"request")==_count(stats,"transfer") and _count(stats,"ready")==_count(stats,"transfer"),
		label, "overlap work was incomplete or counters differ from events", issues)
	_expect(transfer==_count(stats,"transfer")*int(task.transfer),
		label, "transfers did not incur declared service duration", issues)
	_expect(value.result_value==expected_sum and value.expected_value==expected_sum
		and value.metrics.get("outputs")==range(task.values.size()), label, "overlap logical result is incorrect", issues)
	_expect(_metric(value.metrics,"error_line",label,issues)==0
		and total>0 and total<=int(task.get("target",OverlapCore.LIMIT)),
		label, "successful overlap exceeded its task target", issues)
	return stats


static func _validate_overlap_state(core: Variant, run: Variant, count: int,
		label: String, issues: Array[String]) -> void:
	if not core is OverlapCore or not run is TraceType:
		issues.append(label + ": missing final overlap simulator/trace")
		return
	_expect(core.trace==run and core.error.is_empty() and core.queue.is_empty()
		and core.transfer.is_empty() and core.compute.is_empty() and core.consumed==range(count)
		and core.cache.size()<=core.cache_size, label, "overlap final state did not settle/recover", issues)
	for value: Variant in core.buffers.values():
		_expect(value is Dictionary and value.get("state")=="empty" and value.get("batch")==-1,
			label, "overlap retained a busy buffer after success", issues)


static func _logical_work(task: Dictionary) -> Dictionary:
	var outputs: Array[int] = []
	var reads: Dictionary = {}
	var jobs: int = 0
	var count: int = 0
	for query: Dictionary in task.queries:
		var indices: Array = query.get("indices",[])
		if indices.is_empty(): indices = range(task.records.size())
		for _repeat: int in range(int(query.get("repeat",1))):
			jobs += 1
			var total: int = 0
			for raw_record: Variant in indices:
				var record: int = int(raw_record)
				for raw_field: Variant in query.fields:
					var field: int = int(raw_field)
					var number: int = int(task.records[record][field])
					var key: String = "%d:%d" % [record,field]
					reads[key] = int(reads.get(key,0))+1
					count += 1
					if query.kind=="sum": total += number
					else: outputs.append(number)
			if query.kind=="sum": outputs.append(total)
	return {"outputs":outputs,"reads":reads,"query_values":count,"jobs":jobs}


static func _validate_layout(value: Variant, task: Dictionary, failure: String,
		label: String, issues: Array[String]) -> Dictionary:
	if not value is LayoutRunType:
		issues.append(label + ": wrong layout trace type")
		return {}
	var stats: Dictionary = _trace_stats(value,label,issues)
	_expect(value.passed==failure.is_empty() and value.metrics.get("error")==failure,
		label, "unexpected layout success/error result", issues)
	var result_class: String = "correct_output" if failure.is_empty() else "space_limit" if failure=="space_limit" else "runtime_error"
	_expect(value.metrics.get("result_class")==result_class, label, "incorrect layout result class", issues)
	for stage: String in ["prepare","query","output"]:
		_expect(_metric(value.metrics,stage+"_cycles",label,issues)==int(stats.stages.get(stage,0)),
			label, "phase duration differs from events: " + stage, issues)
	_expect(_metric(value.metrics,"prepare_cycles",label,issues)+_metric(value.metrics,"query_cycles",label,issues)
		+_metric(value.metrics,"output_cycles",label,issues)==int(stats.duration),
		label, "layout phases do not reconcile", issues)
	_expect(_metric(value.metrics,"fills",label,issues)==_count(stats,"fill")
		and _metric(value.metrics,"evictions",label,issues)==_count(stats,"evict")
		and _metric(value.metrics,"hits",label,issues)+_count(stats,"fill")==_count(stats,"lookup")
		and _count(stats,"lookup")==_count(stats,"read")
		and _metric(value.metrics,"requests",label,issues)==_count(stats,"lookup")+_count(stats,"write"),
		label, "layout request/cache accounting differs", issues)
	_expect(_metric(value.metrics,"ram_read_bytes",label,issues)==_count(stats,"fill")*LayoutRecipeType.LINE_BYTES
		and _metric(value.metrics,"ram_write_bytes",label,issues)==_count(stats,"write")*LayoutRecipeType.WORD_BYTES,
		label, "layout traffic differs from actual memory operations", issues)
	for direction: String in ["read","write"]:
		_expect(_metric(value.metrics,"prepare_"+direction+"_bytes",label,issues)
			+_metric(value.metrics,"query_"+direction+"_bytes",label,issues)
			==_metric(value.metrics,"ram_"+direction+"_bytes",label,issues),
			label, "phase traffic does not reconcile", issues)
	var peak: int = _metric(value.metrics,"peak_extra_bytes",label,issues)
	_expect(peak<=int(task.get("scratch_limit",0)), label, "successful allocation exceeded scratch limit", issues)
	var logical: Dictionary = _logical_work(task)
	if not failure.is_empty():
		_expect(_count(stats,"error")==1 and _count(stats,"output")==0 and _count(stats,"compute")==0
			and _count(stats,"allocate")==0 and _count(stats,"write")==0,
			label, "early layout failure performed successful work", issues)
		if not stats.events.is_empty():
			_expect(stats.events[-1].kind==&"error" and stats.events[-1].details.get("error")==failure,
				label, "layout failure lacks expected terminal error", issues)
		if failure=="space_limit":
			_expect(_metric(value.metrics,"required_extra_bytes",label,issues)>int(task.scratch_limit)
				and value.expected_values==logical.outputs and value.output_values.size()==logical.outputs.size(),
				label, "allocation failure lost required size or logical workload", issues)
			_expect(peak==0 and value.result_value==0, label, "failed allocation claimed completed work", issues)
			for number: int in value.output_values:
				_expect(number==0, label, "failed allocation changed an output slot", issues)
		else:
			_expect(value.output_values.is_empty() and value.expected_values.is_empty()
				and value.source_map.is_empty(), label, "invalid recipe executed a workload", issues)
		return stats
	_expect(_count(stats,"error")==0 and value.output_values==logical.outputs and value.expected_values==logical.outputs
		and _count(stats,"compute")==int(logical.query_values) and _count(stats,"output")==logical.outputs.size(),
		label, "layout logical output or operation count differs", issues)
	var actual_reads: Dictionary = {}
	var output_index: int = 0
	var output_indices: Dictionary = {}
	var expected_sum: int = 0
	for number: int in logical.outputs: expected_sum += number
	for event: Variant in stats.events:
		if event.kind==&"compute":
			var record: Variant = event.details.get("record")
			var field: Variant = event.details.get("field")
			if not record is int or not field is int or record<0 or record>=task.records.size() or field<0 or field>=4:
				issues.append(label + ": query event has invalid logical coordinates")
				continue
			var key: String = "%d:%d" % [record,field]
			actual_reads[key] = int(actual_reads.get(key,0))+1
			_expect(event.value==int(task.records[record][field]), label, "query event consumed wrong logical value", issues)
		elif event.kind==&"output":
			var slot: Variant = event.details.get("output_index",output_index)
			if not slot is int or slot<0 or slot>=logical.outputs.size():
				issues.append(label + ": output event has invalid slot")
			else:
				_expect(not output_indices.has(slot) and event.value==logical.outputs[slot],
					label, "output event duplicated a slot or emitted wrong value", issues)
				output_indices[slot] = true
			output_index += 1
	_expect(actual_reads==logical.reads and value.result_value==expected_sum and value.expected_value==expected_sum,
		label, "query multiplicity or logical sums differ", issues)
	var cells: Variant = value.source_map.get("cells")
	_expect(cells is Array and cells.size()==task.records.size()*4,
		label, "source mapping lost records or fields", issues)
	_expect(value.cache_capacity_lines==LayoutCore.CACHE_LINES and not value.case_signature.is_empty()
		and not value.recipe_signature.is_empty(), label, "missing layout condition/design identity", issues)
	return stats


static func _validate_copy(run: Variant, stats: Dictionary, words: int, allocations: int,
		label: String, issues: Array[String]) -> void:
	_expect(_count(stats,"write")==words and _count(stats,"allocate")==allocations
		and _count(stats,"release")==allocations and run.scratch_maps.size()==allocations,
		label, "copy work or release count differs from chosen plan", issues)
	_expect(_count(stats,"read")==words+_count(stats,"compute"),
		label, "copied/query words did not each perform a memory read", issues)
	var cells: int = 0
	for mapping: Variant in run.scratch_maps:
		if not mapping is Dictionary or not mapping.get("cells") is Array:
			issues.append(label + ": malformed scratch mapping")
		else:
			cells += mapping.cells.size()
	_expect(cells==words, label, "scratch mappings differ from copied word count", issues)
	if words==0:
		_expect(_metric(run.metrics,"peak_extra_bytes",label,issues)==0, label, "source-only run allocated scratch", issues)


static func _validate_layout_public(input: Dictionary, report: Dictionary,
		label: String, issues: Array[String]) -> void:
	_expect(report.size()==input.levels.size()+1, label, "missing or extra layout workflow", issues)
	for raw_id: Variant in input.levels:
		var id: String = String(raw_id)
		var tasks: Array = LayoutCatalog.cases(id)
		var nested: Dictionary = _dictionary(report.get(id),label+"/"+id,issues)
		var runs: Array = _array(nested.get("runs"),tasks.size(),label+"/"+id,issues)
		_expect(nested.get("passed")==true, label+"/"+id, "official reference did not pass all targets", issues)
		var design: Dictionary = LayoutCatalog.reference_solution(id)
		for index: int in range(runs.size()):
			var item: String = label+"/"+id+"/%d" % index
			var stats: Dictionary = _validate_layout(runs[index],tasks[index],"",item,issues)
			if stats.is_empty(): continue
			_expect(runs[index].model_version==LayoutCore.MODEL_VERSION, item, "wrong official layout model identity", issues)
			_expect(runs[index].metrics.get("target_met")==true
				and (int(tasks[index].target_cycles)<=0 or int(runs[index].metrics.get("total_cycles",-1))<=int(tasks[index].target_cycles))
				and (int(tasks[index].target_bytes)<=0 or int(runs[index].metrics.get("ram_read_bytes",-1))
					+int(runs[index].metrics.get("ram_write_bytes",-1))<=int(tasks[index].target_bytes)),
				item, "official target was not met", issues)
			var chosen: Dictionary = design.get("orders",{}).get(tasks[index].name,design) if id=="relocation" else design
			var copied: bool = not bool(tasks[index].native_layout) and chosen.strategy!="direct"
			var allocations: int = 0
			if copied:
				allocations = 1 if chosen.strategy=="full" else ceili(float(tasks[index].records.size())/float(chosen.batch))
			_validate_copy(runs[index],stats,tasks[index].records.size()*chosen.copy_fields.size() if copied else 0,
				allocations,item,issues)
	var native: Dictionary = _dictionary(report.get("native64"),label+"/native64",issues)
	var native_runs: Array = _array(native.get("runs"),2,label+"/native64",issues)
	var task: Dictionary = _native_layout_task(input)
	for index: int in range(native_runs.size()):
		var stats: Dictionary = _validate_layout(native_runs[index],task,"",label+"/native64/%d" % index,issues)
		if not stats.is_empty():
			_expect(native_runs[index].model_version==LayoutCore.MODEL_VERSION, label, "wrong native layout model identity", issues)
			_validate_copy(native_runs[index],stats,0,0,label+"/native64",issues)
	if native_runs.size()==2:
		_validate_layout_state(native.get("final_simulator"),native_runs[1],task,label+"/native64",issues)


static func _validate_layout_state(core: Variant, run: Variant, task: Dictionary,
		label: String, issues: Array[String]) -> void:
	if not core is LayoutCore or not run is LayoutRunType:
		issues.append(label + ": missing final layout executor/trace")
		return
	_expect(core.trace==run and core.failure.is_empty() and core.current_copy.is_empty()
		and core.memory.size()==task.records.size()*4 and core.data==task.records
		and core.cache.size()<=LayoutCore.CACHE_LINES and core.scratch_end in [0,core.scratch_base]
		and core.clock_cycle==run.metrics.get("total_cycles"),
		label, "layout final state did not release scratch or recover", issues)
	for address: Variant in core.memory:
		_expect(address is int and address>=0 and address<core.scratch_base,
			label, "released scratch address remains in memory", issues)
	for line: int in core.cache:
		_expect(line*LayoutRecipeType.LINE_BYTES<core.scratch_base,
			label, "released scratch line remains in cache", issues)


static func _validate_scheduling_envelope(value: Variant, task: Dictionary, plan: Dictionary,
		failure: String, label: String, issues: Array[String]) -> void:
	var report: Dictionary = _dictionary(value,label,issues)
	_expect(report.get("valid")==true and report.get("error")==failure,
		label, "public scheduling envelope rejected a valid plan or returned wrong error", issues)
	var run: Variant = report.get("run")
	_validate_scheduling_run(run,task,plan,failure,true,label,issues)


static func _validate_scheduling_run(run: Variant, task: Dictionary, plan: Dictionary,
		failure: String, public_envelope: bool, label: String, issues: Array[String]) -> void:
	var stats: Dictionary = _validate_layout(run,task,failure,label,issues)
	if stats.is_empty(): return
	_expect(run.model_version==(Scheduling.MODEL_VERSION if public_envelope else LayoutCore.MODEL_VERSION),
		label, "incorrect public/raw executor model identity", issues)
	if public_envelope:
		_expect(run.case_signature==Scheduling.condition_id(task) and run.recipe_signature==Scheduling.plan_id(plan),
			label, "scheduling condition/plan identity is not current", issues)
	var logical: Dictionary = _logical_work(task)
	var count: int = int(logical.jobs)
	_expect(_metric(run.metrics,"job_count",label,issues)==count and run.events.size()<=Scheduling.MAX_TRACE_EVENTS,
		label, "missing jobs or trace bound exceeded", issues)
	var admissions: Array = _array(run.metrics.get("admission_cycles"),count,label+"/admissions",issues)
	var responses: Array = _array(run.metrics.get("response_cycles"),count,label+"/responses",issues)
	if admissions.size()!=count or responses.size()!=count: return
	var total: int = _metric(run.metrics,"total_cycles",label,issues)
	for index: int in range(count):
		if not admissions[index] is int or not responses[index] is int:
			issues.append(label + ": noninteger admission/response cycle")
			return
		if failure.is_empty():
			_expect(admissions[index]>=0 and responses[index]>admissions[index] and responses[index]<=total,
				label, "job never completed after admission", issues)
			_expect(admissions[index]==(0 if task.release=="batch" or index==0 else responses[index-1]),
				label, "job release rule was not respected", issues)
		else:
			_expect(responses[index]==-1 and admissions[index]==(0 if index==0 else -1),
				label, "allocation failure fabricated an admission/response", issues)
	_expect(_metric(run.metrics,"first_request_cycles",label,issues,-1)==responses[0],
		label, "first-request latency differs from first job response", issues)
	_expect(_count(stats,"request_admitted")==(count if failure.is_empty() else 1)
		and _count(stats,"response")==(count if failure.is_empty() else 0),
		label, "admission/response event count differs", issues)
	var admitted: Dictionary = {}
	var responded: Dictionary = {}
	for event: Variant in stats.events:
		if event.kind not in [&"request_admitted",&"response"]: continue
		var id: int = event.value
		if id<0 or id>=count:
			issues.append(label + ": event references an unknown job")
			continue
		var seen: Dictionary = admitted if event.kind==&"request_admitted" else responded
		var cycle: int = admissions[id] if event.kind==&"request_admitted" else responses[id]
		var detail: String = "admitted_cycle" if event.kind==&"request_admitted" else "response_cycle"
		_expect(not seen.has(id) and event.cycle==cycle and event.details.get(detail)==cycle
			and event.details.get("job_id")==id, label, "job event and recorded timing disagree", issues)
		seen[id] = true
	if failure.is_empty():
		var copied: bool = plan.copy_mode=="full"
		_validate_copy(run,stats,task.records.size()*plan.copy_fields.size() if copied else 0,
			1 if copied else 0,label,issues)


static func _validate_scheduling_reuse(input: Dictionary, report: Dictionary,
		label: String, issues: Array[String]) -> void:
	var failed_task: Dictionary = Scheduling.scenario("scan_serial")
	failed_task.scratch_limit = 0
	var copy_plan: Dictionary = Scheduling.starter_plan()
	copy_plan.copy_mode = "full"
	copy_plan.recipe = LayoutRecipeType.field_major()
	_validate_scheduling_envelope(report.get("allocation"),failed_task,copy_plan,"space_limit",label+"/allocation",issues)
	var invalid: Dictionary = _dictionary(report.get("invalid_serial_group"),label+"/invalid",issues)
	_expect(invalid.get("valid")==false and invalid.get("error")=="serial_group"
		and invalid.has("run") and invalid.run==null, label, "serial grouping did not reject before execution", issues)
	var task: Dictionary = _sparse_scheduling_task(input)
	var plan: Dictionary = _sparse_scheduling_plan(input)
	_validate_scheduling_envelope(report.get("public_sparse"),task,plan,"",label+"/public_sparse",issues)
	var runs: Array = _array(report.get("reused_runs"),4,label+"/reused",issues)
	if runs.size()!=4: return
	_validate_scheduling_run(runs[0],failed_task,copy_plan,"space_limit",false,label+"/reused0",issues)
	_validate_scheduling_run(runs[1],task,plan,"",false,label+"/reused1",issues)
	_validate_scheduling_run(runs[2],Scheduling.scenario("scan_serial"),Scheduling.starter_plan(),"",false,label+"/reused2",issues)
	_validate_scheduling_run(runs[3],task,plan,"",false,label+"/reused3",issues)
	_validate_recovery(runs[1],runs[3],label,issues)
	_validate_layout_state(report.get("final_executor"),runs[3],task,label,issues)
	var executor: Variant = report.get("final_executor")
	if executor is Scheduling.Executor:
		_expect(executor.active_job==-1 and executor.active_tile==-1 and executor.jobs.size()==int(_logical_work(task).jobs),
			label, "executor retained an active job/tile or old workload", issues)
		for job: Dictionary in executor.jobs:
			_expect(job.get("remaining")==0, label, "executor retained unfinished query values", issues)
	else:
		issues.append(label + ": missing final scheduling executor")


static func _validate_recovery(first: Variant, recovered: Variant,
		label: String, issues: Array[String]) -> void:
	if not (first is TraceType or first is SystemTraceType) or not (recovered is TraceType or recovered is SystemTraceType):
		issues.append(label + ": missing recovery traces")
		return
	_expect(first!=recovered and first.passed and recovered.passed and first.metrics==recovered.metrics
		and first.events.size()==recovered.events.size(), label, "reused simulator did not recover the original work", issues)
	if first is LayoutRunType and recovered is LayoutRunType:
		_expect(first.output_values==recovered.output_values, label, "layout recovery changed outputs", issues)
	elif first is SystemTraceType and recovered is SystemTraceType:
		_expect(first.output_data==recovered.output_data, label, "system recovery changed outputs", issues)
	elif first is TraceType and recovered is TraceType:
		_expect(first.result_value==recovered.result_value, label, "overlap recovery changed result", issues)
