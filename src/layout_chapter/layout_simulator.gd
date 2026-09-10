class_name LayoutSimulator
extends RefCounted
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Run = preload("res://src/layout_chapter/layout_run.gd")
const MODEL_VERSION: String = "layout-memory-1"
const CACHE_LINES: int = 2
const READ_LOOKUP: int = 1
const FILL_CYCLES: int = 16
const WRITE_CYCLES: int = 9
var trace: LayoutRun
var memory: Dictionary = {}
var cache: Array[int] = []
var allocated_end: int = 0
var scratch_base: int = 0
var scratch_end: int = 0
var stage: String = "query"
var failure: String = ""
var clock_cycle: int = 0
var data: Array = []
var copied_fields: Array[int] = []
var current_copy: Dictionary = {}
var output_slots: Array[Dictionary] = []

func run(task: Dictionary, design: Dictionary) -> LayoutRun:
	trace = Run.new()
	trace.cache_capacity_lines = CACHE_LINES
	trace.model_version = MODEL_VERSION
	trace.case_signature = JSON.stringify(task).sha256_text()
	trace.test_name = str(task.get("name","case"))
	trace.metrics = {"total_cycles":0,"prepare_cycles":0,"query_cycles":0,"output_cycles":0,
		"ram_read_bytes":0,"ram_write_bytes":0,"prepare_read_bytes":0,"prepare_write_bytes":0,
		"query_read_bytes":0,"query_write_bytes":0,"requests":0,"fills":0,"hits":0,"evictions":0,
		"peak_extra_bytes":0,"error":"","result_class":"invalid_design"}
	memory.clear(); cache.clear(); copied_fields.clear(); output_slots.clear()
	allocated_end = 0; scratch_base = 0; scratch_end = 0; clock_cycle = 0; failure = ""; stage = "query"
	current_copy = {}
	var validation: String = validate_task(task)
	if not validation.is_empty(): _fail(validation); return _finish()
	validation = validate_design(design, bool(task.get("native_layout",true)))
	if not validation.is_empty(): _fail(validation); return _finish()
	trace.recipe_signature = design_signature(design)
	data = task.records
	var count: int = data.size()
	var native_layout: bool = bool(task.get("native_layout",true))
	var source_recipe: Dictionary = design.recipe if native_layout else Recipe.record_major()
	trace.source_map = Recipe.mapping(source_recipe,count)
	allocated_end = int(trace.source_map.bytes)
	for cell: Dictionary in trace.source_map.cells:
		memory[int(cell.address)] = int(data[int(cell.record)][int(cell.field)])
	scratch_base = Recipe.align_line(allocated_end+Recipe.LINE_BYTES)
	_prepare_outputs(task.queries)
	trace.expected_values = expected(task)
	var strategy: String = str(design.get("strategy","direct"))
	if not native_layout and strategy != "direct":
		for field: Variant in design.get("copy_fields",[]): copied_fields.append(int(field))
		var batch: int = count if strategy == "full" else int(design.get("batch",1))
		for first: int in range(0,count,batch):
			var length: int = mini(batch,count-first)
			_prepare_copy(design.recipe, first,length,int(task.get("scratch_limit",0)))
			if not failure.is_empty(): break
			_query_batch(task.queries,first,length)
			_release_copy()
			if not failure.is_empty(): break
	else:
		_query_batch(task.queries,0,count)
	if failure.is_empty():
		stage = "output"
		for value: int in trace.output_values: _event(&"output",1,-1,-1,-1,value,0,&"COMPUTE",&"OUTPUT")
	return _finish()

static func design_signature(design: Dictionary) -> String:
	return JSON.stringify({"model":MODEL_VERSION,"design":normalized_design(design)}).sha256_text()

static func normalized_design(design: Dictionary) -> Dictionary:
	var copy: Array[int] = []
	for field: Variant in design.get("copy_fields",[0]): copy.append(int(field))
	return {"recipe":Recipe.normalized(design.recipe),"strategy":str(design.get("strategy","direct")),"copy_fields":copy,"batch":int(design.get("batch",4))}

static func validate_design(design: Dictionary, native_layout: bool) -> String:
	if not design.get("recipe") is Dictionary: return "groups"
	var problem: String = Recipe.error(design.recipe)
	if not problem.is_empty(): return problem
	var strategy: String = str(design.get("strategy","direct"))
	if strategy not in ["direct","full","batch"] or (native_layout and strategy != "direct"): return "strategy"
	if not Recipe._integer(design.get("batch",4)) or int(design.get("batch",4))<1 or int(design.get("batch",4))>64: return "batch"
	if not design.get("copy_fields",[0]) is Array or design.get("copy_fields",[0]).size()>4: return "copy_fields"
	var all_fields: Array[int] = []
	for field: Variant in design.get("copy_fields",[0]):
		if not Recipe._integer(field) or int(field)<0 or int(field)>=4 or all_fields.has(int(field)): return "copy_fields"
		all_fields.append(int(field))
	if strategy != "direct":
		if not design.get("copy_fields") is Array or design.copy_fields.is_empty(): return "copy_fields"
		var used: Array[int] = []
		for field: Variant in design.copy_fields:
			if not Recipe._integer(field) or int(field)<0 or int(field)>=4 or used.has(int(field)): return "copy_fields"
			used.append(int(field))
		if strategy == "batch" and (not Recipe._integer(design.get("batch")) or int(design.batch)<1 or int(design.batch)>64): return "batch"
	return ""

static func validate_task(task: Dictionary) -> String:
	if not task.get("records") is Array or task.records.is_empty() or task.records.size()>64: return "records"
	for record: Variant in task.records:
		if not record is Array or record.size()!=4: return "records"
		for value: Variant in record:
			if not Recipe._integer(value) or int(value)<0 or int(value)>100000: return "value"
	if not task.get("queries") is Array or task.queries.is_empty() or task.queries.size()>8: return "queries"
	for query: Variant in task.queries:
		if not query is Dictionary or query.get("kind") not in ["sum","records"] or not query.get("fields") is Array or query.fields.is_empty() or query.fields.size()>4: return "queries"
		for field: Variant in query.fields:
			if not Recipe._integer(field) or int(field)<0 or int(field)>=4: return "queries"
		if not Recipe._integer(query.get("repeat",1)) or int(query.get("repeat",1))<1 or int(query.get("repeat",1))>16: return "queries"
		if not query.get("indices",[]) is Array or query.get("indices",[]).size()>64: return "queries"
		for index: Variant in query.get("indices",[]):
			if not Recipe._integer(index) or int(index)<0 or int(index)>=task.records.size(): return "indices"
	return ""

## Logical oracle: no physical addresses or recipe involved.
static func expected(task: Dictionary) -> Array[int]:
	var result: Array[int] = []
	for query: Dictionary in task.queries:
		var indices: Array = query.get("indices",[])
		if indices.is_empty(): indices = range(task.records.size())
		for repetition: int in range(int(query.get("repeat",1))):
			var total: int = 0
			for record: int in indices:
				for field: int in query.fields:
					var value: int = int(task.records[record][field])
					if query.kind == "sum": total += value
					else: result.append(value)
			if query.kind == "sum": result.append(total)
	return result

func _prepare_outputs(queries: Array) -> void:
	for query: Dictionary in queries:
		var indices: Array = query.get("indices",[])
		if indices.is_empty(): indices = range(data.size())
		var slots: Array[int] = []
		for repetition: int in range(int(query.get("repeat",1))):
			slots.append(trace.output_values.size())
			var length: int = 1 if query.kind == "sum" else indices.size()*query.fields.size()
			for item: int in range(length): trace.output_values.append(0)
		output_slots.append({"indices":indices,"slots":slots})

func _prepare_copy(recipe: Dictionary, first: int, count: int, limit: int) -> void:
	stage = "prepare"
	current_copy = Recipe.mapping(recipe,count,scratch_base,copied_fields)
	current_copy["first_record"] = first
	scratch_end = scratch_base+int(current_copy.bytes)
	if int(current_copy.bytes)>limit:
		trace.metrics["required_extra_bytes"] = int(current_copy.bytes)
		_fail("space_limit")
		return
	trace.metrics.peak_extra_bytes = maxi(int(trace.metrics.peak_extra_bytes),int(current_copy.bytes))
	trace.scratch_maps.append(current_copy.duplicate(true))
	_event(&"allocate",0,scratch_base,first,-1,0,int(current_copy.bytes),&"MEMORY",&"SCRATCH")
	# Read source in public record/field order; writes follow the chosen destination mapping.
	for record: int in range(first,first+count):
		for field: int in copied_fields:
			var source: int = int(trace.source_map.addresses[record*4+field])
			var value: int = _read(source,record,field)
			var target: int = int(current_copy.addresses[(record-first)*4+field])
			_write(target,value,record,field)

func _query_batch(queries: Array, first: int, count: int) -> void:
	stage = "query"
	for query_index: int in range(queries.size()):
		var query: Dictionary = queries[query_index]
		var slots: Dictionary = output_slots[query_index]
		for repetition: int in range(slots.slots.size()):
			for index: int in range(slots.indices.size()):
				var record: int = int(slots.indices[index])
				if record<first or record>=first+count: continue
				for field_index: int in range(query.fields.size()):
					var field: int = int(query.fields[field_index])
					var address: int = int(trace.source_map.addresses[record*4+field])
					if not current_copy.is_empty() and copied_fields.has(field): address = int(current_copy.addresses[(record-first)*4+field])
					var value: int = _read(address,record,field)
					if not failure.is_empty(): return
					_event(&"compute",1,address,record,field,value,0,&"CACHE",&"COMPUTE")
					var slot: int = int(slots.slots[repetition])
					if query.kind == "sum": trace.output_values[slot] += value
					else: trace.output_values[slot+index*query.fields.size()+field_index] = value

func _release_copy() -> void:
	if current_copy.is_empty(): return
	for key: Variant in memory.keys():
		if int(key)>=scratch_base: memory.erase(key)
	for line: int in cache.duplicate():
		if line*Recipe.LINE_BYTES>=scratch_base: cache.erase(line)
	_event(&"release",0,scratch_base,int(current_copy.first_record),-1,0,int(current_copy.bytes),&"SCRATCH",&"MEMORY")
	current_copy = {}; scratch_end = scratch_base

func _read(address: int, record: int, field: int) -> int:
	if not failure.is_empty(): return 0
	if address<0 or address%4 != 0 or (address>=allocated_end and (address<scratch_base or address>=scratch_end)): _fail("bounds"); return 0
	if not memory.has(address): _fail("uninitialized"); return 0
	trace.metrics.requests += 1
	var line: int = address/Recipe.LINE_BYTES
	_event(&"lookup",READ_LOOKUP,address,record,field,0,0,&"COMPUTE",&"CACHE")
	if cache.has(line):
		trace.metrics.hits += 1
		cache.erase(line)
	else:
		trace.metrics.fills += 1
		trace.metrics.ram_read_bytes += Recipe.LINE_BYTES
		trace.metrics[stage+"_read_bytes"] += Recipe.LINE_BYTES
		if cache.size()>=CACHE_LINES:
			var victim: int = cache.pop_front()
			trace.metrics.evictions += 1
			_event(&"evict",0,victim*Recipe.LINE_BYTES,-1,-1,0,Recipe.LINE_BYTES,&"CACHE",&"MEMORY")
		_event(&"fill",FILL_CYCLES,line*Recipe.LINE_BYTES,record,field,0,Recipe.LINE_BYTES,&"MEMORY",&"CACHE")
	cache.append(line)
	var value: int = int(memory[address])
	_event(&"read",0,address,record,field,value,Recipe.WORD_BYTES,&"CACHE",&"COMPUTE")
	return value

func _write(address: int, value: int, record: int, field: int) -> void:
	if not failure.is_empty(): return
	if address<scratch_base or address>=scratch_end or address%4 != 0: _fail("write_bounds"); return
	memory[address] = value
	trace.metrics.requests += 1
	trace.metrics.ram_write_bytes += Recipe.WORD_BYTES
	trace.metrics[stage+"_write_bytes"] += Recipe.WORD_BYTES
	# Cache stores line identities; values always come from the authoritative memory.
	var line: int = address/Recipe.LINE_BYTES
	if cache.has(line): cache.erase(line); cache.append(line)
	_event(&"write",WRITE_CYCLES,address,record,field,value,Recipe.WORD_BYTES,&"COMPUTE",&"MEMORY")

func _event(kind: StringName, duration: int, address: int, record: int, field: int, value: int, bytes: int, from: StringName, to: StringName) -> void:
	var event := SimulationEvent.new(kind,clock_cycle,duration,from,to,address,
		int(address/Recipe.LINE_BYTES) if address>=0 else -1,value,"",0,[],
		{"stage":stage,"record":record,"field":field,"bytes":bytes})
	trace.add_event(event)
	clock_cycle += duration
	trace.metrics[stage+"_cycles"] += duration

func _fail(reason: String) -> void:
	if not failure.is_empty(): return
	failure = reason
	_event(&"error",0,-1,-1,-1,0,0,&"COMPUTE",&"OUTPUT")
	trace.events[-1].details["error"] = reason

func _finish() -> LayoutRun:
	trace.metrics.total_cycles = clock_cycle
	trace.metrics.error = failure
	trace.result_value = 0; trace.expected_value = 0
	for value: int in trace.output_values: trace.result_value += value
	for value: int in trace.expected_values: trace.expected_value += value
	trace.passed = failure.is_empty() and trace.output_values == trace.expected_values
	trace.metrics.result_class = "correct_output" if trace.passed else "space_limit" if failure == "space_limit" else "runtime_error" if not failure.is_empty() else "wrong_output"
	return trace
