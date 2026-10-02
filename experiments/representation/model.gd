extends RefCounted
## Isolated synchronous stored-asset model. Never reads UI, campaign or save state.
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
const VERSION = "representation-rle-v1"

static func encode(data: Array[int], codec: String) -> PackedByteArray:
	var out := PackedByteArray()
	if codec == "raw":
		for value: int in data: out.append(value)
		return out
	# Two-byte decoded length, followed by (count,value) byte pairs.
	out.append(data.size() & 255); out.append(data.size() >> 8)
	var i: int = 0
	while i < data.size():
		var count: int = 1
		while i + count < data.size() and data[i + count] == data[i] and count < 255: count += 1
		out.append(count); out.append(data[i]); i += count
	return out

static func decode(bytes: PackedByteArray, codec: String) -> Array[int]:
	var result: Array[int] = []
	if codec == "raw":
		for value: int in bytes: result.append(value)
		return result
	if bytes.size() < 2 or bytes.size() % 2 != 0: return []
	for i: int in range(2,bytes.size(),2):
		if bytes[i] == 0: return []
		for j: int in bytes[i]: result.append(bytes[i + 1])
	if result.size() != int(bytes[0]) + (int(bytes[1]) << 8): return []
	return result

static func data_set(varied: bool = false) -> Array[int]:
	var data: Array[int] = []
	for i: int in 64: data.append((i * 37 + 11) % 256 if varied else 5 + i / 16)
	return data

static func scenario(stage: int, order: int = 0) -> Dictionary:
	var addresses: Array[int] = []
	if stage == 2 and order == 1: addresses.assign([0,32])
	else:
		for i: int in 64: addresses.append(i)
	return {"data":data_set(stage == 1 and order == 2), "addresses":addresses,
		"bandwidth":8 if stage == 1 and order == 1 else 1,
		"decoder":1 if stage == 1 and order == 1 else (4 if stage == 2 else 8),
		"latency":4, "scratch_limit":64}

static func emit(trace: Trace, kind: StringName, duration: int, details: Dictionary) -> void:
	var cycle: int = int(trace.metrics.get("total_cycles",0))
	trace.add_event(Event.new(kind,cycle,duration,&"Storage" if kind == &"transfer" else &"CPU",&"CPU",int(details.get("address",-1)),-1,0,String(kind),0,[],details))
	trace.metrics.total_cycles = cycle + duration

static func run(spec: Dictionary, config: Dictionary) -> Trace:
	var trace := Trace.new()
	trace.test_name = VERSION
	trace.metrics = {"total_cycles":0,"transfer_cycles":0,"decode_cycles":0,"request_cycles":0,"consume_cycles":0,
		"stored_bytes":0,"traffic_bytes":0,"decoded_values":0,"decode_ops":0,"cache_hits":0,"cache_misses":0,
		"scratch_bytes":0,"error":"","outputs":[],"config":config.duplicate(true)}
	var codec: String = str(config.get("codec","raw"))
	var size: int = int(config.get("block",64))
	var capacity: int = int(config.get("cache",1))
	var data: Array[int] = []; data.assign(spec.data)
	if codec not in ["raw","rle"] or size not in [4,16,64] or capacity not in [1,2] or size * capacity > int(spec.scratch_limit):
		trace.metrics.error = "scratch_or_config"; return trace
	if int(spec.bandwidth) <= 0 or int(spec.decoder) <= 0 or int(spec.latency) < 0:
		trace.metrics.error = "machine"; return trace
	for value: int in data:
		if value < 0 or value > 255: trace.metrics.error = "byte_range"; return trace
	var blocks: Array[PackedByteArray] = []
	for start: int in range(0,data.size(),size):
		var values: Array[int] = []; values.assign(data.slice(start,mini(start+size,data.size())))
		var bytes: PackedByteArray = encode(values,codec)
		blocks.append(bytes)
		trace.metrics.stored_bytes += bytes.size() + (4 if codec == "rle" else 0)
	trace.metrics.scratch_bytes = size * capacity
	# LRU holds decoded blocks. A miss always transfers/decompresses the full block.
	var cache: Dictionary = {}; var lru: Array[int] = []
	var output: Array[int] = []; var expected: Array[int] = []
	for address: int in spec.addresses:
		if address < 0 or address >= data.size(): trace.metrics.error = "address"; return trace
		var block: int = address / size
		if not cache.has(block):
			trace.metrics.cache_misses += 1
			var bytes: PackedByteArray = blocks[block]
			var moved: int = bytes.size() + (4 if codec == "rle" else 0)
			var transfer: int = ceili(float(moved) / int(spec.bandwidth))
			var values: Array[int] = decode(bytes,codec)
			var ops: int = values.size() + (bytes.size()-2)/2 if codec == "rle" else 0
			var compute: int = ceili(float(ops) / int(spec.decoder))
			emit(trace,&"request",int(spec.latency),{"address":address,"block":block})
			emit(trace,&"transfer",transfer,{"address":address,"block":block,"bytes":moved,"encoded":Array(bytes)})
			if compute > 0: emit(trace,&"decode",compute,{"address":address,"block":block,"ops":ops,"decoded":values.duplicate()})
			trace.metrics.traffic_bytes += moved; trace.metrics.transfer_cycles += transfer
			trace.metrics.request_cycles += int(spec.latency); trace.metrics.decode_cycles += compute
			trace.metrics.decoded_values += values.size(); trace.metrics.decode_ops += ops
			if lru.size() >= capacity: cache.erase(lru.pop_front())
			cache[block] = values
		else: trace.metrics.cache_hits += 1
		lru.erase(block); lru.append(block)
		output.append(cache[block][address % size]); expected.append(data[address])
		emit(trace,&"consume",1,{"address":address,"value":output[-1]})
		trace.metrics.consume_cycles += 1
	trace.metrics.outputs = output
	trace.result_value = output.reduce(func(a: int,b: int) -> int: return a+b,0)
	trace.expected_value = expected.reduce(func(a: int,b: int) -> int: return a+b,0)
	trace.passed = output == expected
	return trace
