extends RefCounted
## Editable byte partitions; no scene, timing, progression or save dependencies.
const Codec = preload("res://experiments/representation/model.gd")
const Cache = preload("res://experiments/representation/decoded_cache.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const VERSION: String = "representation-plan-v1"
const MAX_BLOCKS: int = 8

static func asset() -> Array[int]:
	var values: Array[int] = []
	for i: int in 64:
		values.append(5 if i < 16 else (8 if i >= 48 else (i * 37 + 11) % 256))
	return values

static func initial_plan() -> Array[Dictionary]:
	return [{"start":0,"end":64,"codec":"raw"}]

static func validate(plan: Array, data: Array) -> String:
	if plan.is_empty() or plan.size() > MAX_BLOCKS: return "block_count"
	var cursor: int = 0
	for entry: Variant in plan:
		if not entry is Dictionary: return "block_schema"
		var block: Dictionary = entry
		for key: String in ["start","end","codec"]:
			if not block.has(key): return "block_schema"
		if not block.start is int or not block.end is int: return "integer_boundary"
		if int(block.start) != cursor or int(block.end) <= cursor or int(block.end) > data.size(): return "exact_coverage"
		if not block.codec is String or str(block.codec) not in ["raw","rle"]: return "codec"
		cursor = int(block.end)
	if cursor != data.size(): return "exact_coverage"
	for value: Variant in data:
		if not value is int or int(value) < 0 or int(value) > 255: return "byte_range"
	return ""

static func split(plan: Array[Dictionary], index: int, address: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = plan.duplicate(true)
	if index < 0 or index >= result.size() or result.size() >= MAX_BLOCKS: return result
	var old: Dictionary = result[index]
	if address <= int(old.start) or address >= int(old.end): return result
	result[index] = {"start":old.start,"end":address,"codec":old.codec}
	result.insert(index + 1,{"start":address,"end":old.end,"codec":old.codec})
	return result

static func merge(plan: Array[Dictionary], index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = plan.duplicate(true)
	if index < 0 or index + 1 >= result.size(): return result
	result[index].end = result[index + 1].end
	result.remove_at(index + 1)
	return result

static func represent(plan: Array[Dictionary], index: int, codec: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = plan.duplicate(true)
	if index >= 0 and index < result.size() and codec in ["raw","rle"]: result[index].codec = codec
	return result

static func orders(task: int) -> Array[Dictionary]:
	var scan: Array[int] = []
	for i: int in 64: scan.append(i)
	var hot: Array[int] = [0,63,0,63,0,63]
	var full: Dictionary = {"name":"scan","data":asset(),"addresses":scan,"bandwidth":1,"decoder":8,"latency":4,"cache_bytes":64,"scratch_limit":64}
	var sparse: Dictionary = {"name":"hotspots","data":asset(),"addresses":hot,"bandwidth":1,"decoder":8,"latency":4,"cache_bytes":32,"scratch_limit":64}
	if task == 0: return [full]
	if task == 1: return [sparse]
	return [full,sparse]

static func block_evidence(data: Array[int], plan: Array[Dictionary]) -> Array[Dictionary]:
	var encoded: Array[Dictionary] = []
	for block: Dictionary in plan:
		var values: Array[int] = []; values.assign(data.slice(int(block.start),int(block.end)))
		var bytes: PackedByteArray = Codec.encode(values,str(block.codec))
		var metadata: int = 4 # Explicit boundary directory for every variable-sized block.
		encoded.append({"start":block.start,"end":block.end,"codec":block.codec,"values":values,"encoded":Array(bytes),"payload_bytes":bytes.size(),"metadata_bytes":metadata,"directory":[int(block.start)&255,int(block.start)>>8,int(block.end)&255,int(block.end)>>8],"stored_bytes":bytes.size()+metadata})
	return encoded

static func run(spec: Dictionary, plan: Array) -> Trace:
	var trace := Trace.new()
	trace.test_name = VERSION
	trace.metrics = {"total_cycles":0,"request_cycles":0,"transfer_cycles":0,"decode_cycles":0,"consume_cycles":0,"stored_bytes":0,"traffic_bytes":0,"decoded_values":0,"decode_ops":0,"cache_hits":0,"cache_misses":0,"evictions":0,"overfetch_values":0,"peak_cache_bytes":0,"outputs":[],"expected":[],"error":"","plan":plan.duplicate(true),"spec":spec.duplicate(true),"blocks":[],"accesses":[]}
	var data: Array[int] = []
	if not spec.get("data",null) is Array: trace.metrics.error = "data_schema"; return trace
	var error: String = validate(plan,spec.data)
	if not error.is_empty(): trace.metrics.error = error; return trace
	data.assign(spec.data)
	for field: String in ["bandwidth","decoder","latency","cache_bytes","scratch_limit"]:
		if not spec.get(field,null) is int: trace.metrics.error = "machine"; return trace
	if spec.bandwidth <= 0 or spec.decoder <= 0 or spec.latency < 0 or spec.cache_bytes < 0 or spec.scratch_limit <= 0: trace.metrics.error = "machine"; return trace
	if not spec.get("addresses",null) is Array: trace.metrics.error = "address"; return trace
	for address: Variant in spec.addresses:
		if not address is int or int(address) < 0 or int(address) >= data.size(): trace.metrics.error = "address"; return trace
	var typed_plan: Array[Dictionary] = []; typed_plan.assign(plan)
	var blocks: Array[Dictionary] = block_evidence(data,typed_plan)
	for block: Dictionary in blocks:
		if int(block.end)-int(block.start) > int(spec.scratch_limit): trace.metrics.error = "scratch"; return trace
		trace.metrics.stored_bytes += int(block.stored_bytes)
	trace.metrics.blocks = blocks.duplicate(true)
	var cache := Cache.new()
	cache.configure(MAX_BLOCKS,int(spec.cache_bytes))
	var loaded_addresses: Dictionary = {}; var requested_addresses: Dictionary = {}
	var outputs: Array[int] = []; var expected: Array[int] = []
	for address: int in spec.addresses:
		var index: int = 0
		while address >= int(blocks[index].end): index += 1
		var block: Dictionary = blocks[index]
		var hit: bool = cache.has(index)
		var before: Dictionary = cache.snapshot()
		var values: Array[int] = []
		var evicted: Array[int] = []
		if hit:
			trace.metrics.cache_hits += 1
			values = cache.fetch(index)
		else:
			trace.metrics.cache_misses += 1
			var bytes := PackedByteArray(block.encoded)
			values = Codec.decode(bytes,str(block.codec))
			if values != block.values: trace.metrics.error = "decode"; return trace
			var ops: int = values.size() + (bytes.size()-2)/2 if block.codec == "rle" else 0
			var transfer: int = ceili(float(block.stored_bytes)/int(spec.bandwidth))
			var decode_time: int = ceili(float(ops)/int(spec.decoder))
			var evidence: Dictionary = {"address":address,"block":index,"range":[block.start,block.end],"codec":block.codec,"cache_before":before}
			Codec.emit(trace,&"request",int(spec.latency),evidence)
			var moved: Dictionary = evidence.duplicate(true)
			moved.merge({"bytes":block.stored_bytes,"payload_bytes":block.payload_bytes,"metadata_bytes":block.metadata_bytes,"directory":block.directory,"encoded":block.encoded})
			Codec.emit(trace,&"transfer",transfer,moved)
			if decode_time > 0:
				var decoded: Dictionary = evidence.duplicate(true); decoded.merge({"ops":ops,"decoded":values.duplicate()})
				Codec.emit(trace,&"decode",decode_time,decoded)
			trace.metrics.request_cycles += int(spec.latency); trace.metrics.transfer_cycles += transfer
			trace.metrics.decode_cycles += decode_time; trace.metrics.traffic_bytes += int(block.stored_bytes)
			trace.metrics.decoded_values += values.size(); trace.metrics.decode_ops += ops
			evicted = cache.put(index,values,values.size())
			trace.metrics.evictions += evicted.size()
			for loaded: int in range(int(block.start),int(block.end)): loaded_addresses[loaded] = true
		requested_addresses[address] = true
		outputs.append(values[address-int(block.start)]); expected.append(data[address])
		var after: Dictionary = cache.snapshot()
		trace.metrics.peak_cache_bytes = maxi(int(trace.metrics.peak_cache_bytes),int(after.used_bytes))
		var access: Dictionary = {"address":address,"block":index,"hit":hit,"evicted":evicted,"cache_before":before,"cache_after":after,"cached":cache.has(index),"value":outputs[-1]}
		trace.metrics.accesses.append(access.duplicate(true))
		Codec.emit(trace,&"consume",1,access)
		trace.metrics.consume_cycles += 1
	for address: int in loaded_addresses:
		if not requested_addresses.has(address): trace.metrics.overfetch_values += 1
	trace.metrics.outputs = outputs; trace.metrics.expected = expected
	trace.result_value = outputs.reduce(func(a: int,b: int) -> int: return a+b,0)
	trace.expected_value = expected.reduce(func(a: int,b: int) -> int: return a+b,0)
	trace.passed = outputs == expected
	return trace

static func meets(task: int, traces: Array) -> bool:
	if task < 0 or task > 2: return false
	var required: int = 2 if task == 2 else 1
	if traces.size() != required: return false
	var authored: Array[Dictionary] = orders(task)
	for i: int in traces.size():
		var trace: Trace = traces[i]
		if not trace.passed: return false
		var m: Dictionary = trace.metrics
		if m.get("spec",{}) != authored[i]: return false
		if i > 0 and m.get("plan",[]) != traces[0].metrics.get("plan",[]): return false
		var scan: bool = task == 0 or task == 2 and i == 0
		if scan and (int(m.total_cycles)>136 or int(m.stored_bytes)>60): return false
		if not scan and (int(m.total_cycles)>36 or int(m.traffic_bytes)>16 or int(m.stored_bytes)>(60 if task == 2 else 68)): return false
	return true
