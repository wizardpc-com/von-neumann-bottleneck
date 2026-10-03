extends RefCounted
const Base = preload("res://experiments/representation/plan_model.gd")
const Catalog = preload("res://experiments/representation_region/catalog.gd")
const Codec = preload("res://experiments/representation/model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const VERSION: String = "representation-region-v1"
const MAX_BLOCKS: int = 8
static func asset(task: int = 0) -> Array[int]: return Catalog.orders(task)[0].data
static func initial_plan() -> Array[Dictionary]: return Base.initial_plan()
static func split(plan: Array[Dictionary], index: int, address: int) -> Array[Dictionary]: return Base.split(plan,index,address)
static func merge(plan: Array[Dictionary], index: int) -> Array[Dictionary]: return Base.merge(plan,index)
static func represent(plan: Array[Dictionary], index: int, codec: String) -> Array[Dictionary]: return Base.represent(plan,index,codec)
static func block_evidence(data: Array[int], plan: Array[Dictionary]) -> Array[Dictionary]: return Base.block_evidence(data,plan)
static func orders(task: int) -> Array[Dictionary]: return Catalog.orders(task)
static func run(spec: Dictionary, plan: Array) -> Trace:
	var service: Trace = Base.run(spec,plan)
	service.test_name = VERSION
	if not service.passed: return service
	if not spec.get("online",null) is bool or not spec.get("clients",null) is int or not spec.get("encoder",null) is int or spec.clients < 1 or spec.clients > 8 or spec.encoder < 1:
		service.passed = false; service.metrics.error = "preparation_machine"; service.events.clear(); service.metrics.total_cycles = 0; return service
	var trace := Trace.new(); trace.test_name = VERSION
	trace.metrics = service.metrics.duplicate(true)
	for key: String in ["total_cycles","request_cycles","transfer_cycles","decode_cycles","consume_cycles","traffic_bytes","decoded_values","decode_ops","cache_hits","cache_misses","evictions"]: trace.metrics[key] = 0
	trace.metrics.outputs = []; trace.metrics.expected = []; trace.metrics.accesses = []
	trace.metrics.merge({"preparation_cycles":0,"source_read_bytes":0,"prepared_write_bytes":0,"encode_ops":0,"encode_cycles":0,"service_cycles":0,"source_storage_bytes":64 if spec.online else 0,"representation_bytes":service.metrics.stored_bytes,"peak_preparation_bytes":0})
	if spec.online:
		for index: int in trace.metrics.blocks.size():
			var block: Dictionary = trace.metrics.blocks[index]
			var d: Dictionary = {"block":index,"address":block.start,"range":[block.start,block.end],"codec":block.codec,"directory":block.directory}
			if block.codec == "rle":
				Codec.emit(trace,&"prepare_source_request",int(spec.latency),d)
				var source: Dictionary = d.duplicate(true); source.merge({"bytes":block.values.size(),"values":block.values})
				Codec.emit(trace,&"prepare_source_read",ceili(float(block.values.size())/spec.bandwidth),source)
				var ops: int = block.values.size() + (block.encoded.size()-2)/2
				var encoded: Dictionary = d.duplicate(true); encoded.merge({"ops":ops,"encoded":block.encoded,"values":block.values})
				var cycles: int = ceili(float(ops)/spec.encoder)
				Codec.emit(trace,&"encode",cycles,encoded)
				trace.metrics.source_read_bytes += block.values.size(); trace.metrics.encode_ops += ops; trace.metrics.encode_cycles += cycles
			var written: Dictionary = d.duplicate(true)
			written.merge({"bytes":block.stored_bytes if block.codec == "rle" else 4,"encoded":block.encoded if block.codec == "rle" else [],"source_reference":block.codec == "raw"})
			Codec.emit(trace,&"prepare_write_request",int(spec.latency),d)
			Codec.emit(trace,&"prepare_write",ceili(float(written.bytes)/spec.bandwidth),written)
			trace.metrics.prepared_write_bytes += int(written.bytes)
	if spec.online: trace.metrics.stored_bytes = 64 + int(trace.metrics.prepared_write_bytes)
	trace.metrics.peak_preparation_bytes = trace.metrics.stored_bytes if spec.online else 0
	trace.metrics.preparation_cycles = trace.metrics.total_cycles
	for client: int in spec.clients:
		var current: Trace = service if client == 0 else Base.run(spec,plan)
		for event: RefCounted in current.events:
			var d: Dictionary = event.details.duplicate(true); d.client = client
			Codec.emit(trace,event.kind,event.duration,d)
		for key: String in ["request_cycles","transfer_cycles","decode_cycles","consume_cycles","traffic_bytes","decoded_values","decode_ops","cache_hits","cache_misses","evictions"]: trace.metrics[key] += int(current.metrics[key])
		trace.metrics.outputs.append_array(current.metrics.outputs); trace.metrics.expected.append_array(current.metrics.expected)
		for entry: Dictionary in current.metrics.accesses:
			var copied: Dictionary = entry.duplicate(true); copied.client = client; trace.metrics.accesses.append(copied)
	trace.metrics.service_cycles = int(trace.metrics.total_cycles)-int(trace.metrics.preparation_cycles)
	trace.metrics.total_traffic_bytes = int(trace.metrics.source_read_bytes)+int(trace.metrics.prepared_write_bytes)+int(trace.metrics.traffic_bytes)
	trace.passed = trace.metrics.outputs == trace.metrics.expected
	trace.result_value = trace.metrics.outputs.reduce(func(a: int,b: int) -> int: return a+b,0)
	trace.expected_value = trace.result_value
	return trace
static func meets(task: int, traces: Array) -> bool:
	var authored: Array[Dictionary] = orders(task)
	if authored.is_empty() or traces.size() != authored.size(): return false
	for i: int in traces.size():
		if not traces[i] is Trace: return false
		var trace: Trace = traces[i]
		if not trace.passed or trace.metrics.spec != authored[i]: return false
		if i > 0 and trace.metrics.plan != traces[0].metrics.plan: return false
		for key: String in Catalog.goals(task)[i]:
			if int(trace.metrics[key]) > int(Catalog.goals(task)[i][key]): return false
	return true
