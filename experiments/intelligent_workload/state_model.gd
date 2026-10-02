extends RefCounted
## Persistent numerical context with explicit finite residency and backing writes.
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
const Linear = preload("res://experiments/intelligent_workload/model.gd")
const STREAMS: int = 4
const STEPS: int = 6
const WIDTH: int = 8
const SCRATCH_LIMIT: int = 256

static func initial(stream: int) -> Array[float]:
	var result: Array[float] = []
	for j: int in WIDTH: result.append(float((stream * 5 + j * 3) % 13 - 6) / 12.0)
	return result

static func input(stream: int, step: int) -> Array[float]:
	var result: Array[float] = []
	for j: int in WIDTH:
		result.append(float(((stream + 2) * (j * 7 + 5) + step * (j + 3) * 11) % 31 - 15) / 15.0)
	return result

static func quantize(value: float, bits: int) -> float:
	if bits == 32: return value
	var grid: int = (1 << (bits - 1)) - 1
	return roundf(clampf(value, -1.0, 1.0) * grid) / grid

static func update(state: Array, values: Array, bits: int) -> Array[float]:
	var result: Array[float] = []
	for j: int in WIDTH: result.append(quantize(0.65 * float(state[j]) + 0.35 * float(values[j]), bits))
	return result

static func schedule(order: String) -> Array[int]:
	var result: Array[int] = []
	if order == "grouped":
		for stream: int in STREAMS:
			for step: int in STEPS: result.append(stream * STEPS + step)
	elif order == "paired":
		for pair: int in 2:
			for step: int in STEPS:
				for offset: int in 2: result.append((pair * 2 + offset) * STEPS + step)
	else:
		for step: int in STEPS:
			for stream: int in STREAMS: result.append(stream * STEPS + step)
	return result

static func reference_result() -> Dictionary:
	var states: Array = []; var outputs: Array[float] = []
	for stream: int in STREAMS:
		var state: Array = initial(stream)
		for step: int in STEPS:
			state = update(state, input(stream, step), 32)
			outputs.append(Linear.score(state, Linear.WEIGHTS))
		states.append(state)
	return {"outputs": outputs, "states": states}

static func emit(trace: Trace, kind: StringName, duration: int, details: Dictionary) -> void:
	trace.add_event(Event.new(kind, int(trace.metrics.total_cycles), duration, &"", &"", -1, -1, 0, "", 0, [], details))
	trace.metrics.total_cycles += duration
	if kind == &"compute": trace.metrics.compute_cycles += duration
	elif kind == &"commit": trace.metrics.commit_cycles += duration

static func transfer(trace: Trace, kind: StringName, bytes: int, details: Dictionary, setup: bool = true) -> void:
	if setup:
		emit(trace, &"request", 4, {"operation": String(kind), "bytes": bytes})
		trace.metrics.request_cycles += 4
	var cycles: int = ceili(float(bytes) / 4.0)
	var evidence: Dictionary = details.duplicate(true); evidence.bytes = bytes
	emit(trace, kind, cycles, evidence)
	trace.metrics.transfer_cycles += cycles
	trace.metrics.traffic_bytes += bytes

static func write_state(trace: Trace, store: Array, stream: int, state: Array, bytes: int, reason: String) -> void:
	transfer(trace, &"state_write", bytes, {"stream": stream, "state": state, "reason": reason})
	store[stream] = state.duplicate()
	trace.metrics.state_writes += 1
	trace.metrics.state_write_bytes += bytes
	if reason == "flush": trace.metrics.flush_writes += 1

static func accepted(metrics: Dictionary, prompt: bool = false) -> bool:
	return str(metrics.error).is_empty() and int(metrics.total_cycles) <= 1040 and int(metrics.peak_bytes) <= 200 and float(metrics.max_error) <= 0.02 and float(metrics.max_state_error) <= 0.02 and (not prompt or int(metrics.all_streams_first_cycle) <= 240)

static func run(config: Dictionary) -> Trace:
	var trace := Trace.new(); trace.test_name = "persistent-context-v1"
	trace.metrics = {"config": config.duplicate(true), "error": "", "total_cycles": 0, "traffic_bytes": 0,
		"request_cycles": 0, "transfer_cycles": 0, "compute_cycles": 0, "commit_cycles": 0,
		"peak_bytes": 0, "reserved_bytes": 0, "state_reads": 0, "state_writes": 0, "state_read_bytes": 0,
		"state_write_bytes": 0, "state_hits": 0, "evictions": 0, "flush_writes": 0,
		"weight_reads": 0, "first_result_cycle": 0, "all_streams_first_cycle": 0,
		"outputs": [], "reference": [], "final_states": [], "reference_states": [],
		"response_cycles": [], "first_stream_cycles": [], "max_error": 0.0, "mae": 0.0,
		"max_state_error": 0.0, "agreement": 0, "samples": STREAMS * STEPS}
	for key: String in ["state_bits", "weight_bits", "slots", "batch"]:
		if config.has(key) and typeof(config[key]) != TYPE_INT:
			trace.metrics.error = "config"; return trace
	if (config.has("order") and typeof(config.order) != TYPE_STRING) or (config.has("reuse") and typeof(config.reuse) != TYPE_BOOL):
		trace.metrics.error = "config"; return trace
	var state_bits: int = int(config.get("state_bits", 32)); var weight_bits: int = int(config.get("weight_bits", 32))
	var slots: int = int(config.get("slots", 1)); var batch: int = int(config.get("batch", 1))
	var order: String = str(config.get("order", "round_robin")); var reuse: bool = bool(config.get("reuse", true))
	if state_bits not in [32, 8, 4, 2] or weight_bits not in [32, 8, 4, 2] or slots not in [1, 2, 4] or batch not in [1, 2, 4] or order not in ["round_robin", "paired", "grouped"]:
		trace.metrics.error = "config"; return trace
	var state_bytes: int = ceili(float(WIDTH * state_bits) / 8.0)
	var weight_bytes: int = 32 if weight_bits == 32 else 4 + ceili(float(WIDTH * weight_bits) / 8.0)
	var workspace: int = weight_bytes + batch * 36
	trace.metrics.reserved_bytes = workspace + slots * state_bytes
	trace.metrics.state_bytes = state_bytes; trace.metrics.weight_bytes = weight_bytes
	trace.metrics.backing_state_bytes = STREAMS * state_bytes
	if int(trace.metrics.reserved_bytes) > SCRATCH_LIMIT:
		trace.metrics.error = "scratch_limit"; return trace
	var ref: Dictionary = reference_result(); var params: Array[float] = Linear.weights(weight_bits)
	trace.metrics.reference = ref.outputs.duplicate(); trace.metrics.reference_states = ref.states.duplicate(true)
	var outputs: Array = []; outputs.resize(STREAMS * STEPS)
	var responses: Array = []; responses.resize(STREAMS * STEPS)
	var firsts: Array[int] = [0, 0, 0, 0]
	var store: Array = []; var resident: Dictionary = {}; var dirty: Dictionary = {}; var lru: Array[int] = []
	for stream: int in STREAMS:
		var state: Array[float] = []
		for value: float in initial(stream): state.append(quantize(value, state_bits))
		store.append(state)
	emit(trace, &"initial_store", 0, {"states": store, "weights": params, "reference_weights": Linear.WEIGHTS, "state_bytes": state_bytes})
	var queue: Array[int] = schedule(order); var weight_loaded: bool = false
	for start: int in range(0, queue.size(), batch):
		var requests: Array = queue.slice(start, start + batch)
		var moved_weights: int = 0 if reuse and weight_loaded else weight_bytes
		transfer(trace, &"batch_read", batch * 32 + moved_weights, {"request_ids": requests, "input_bytes": batch * 32, "weight_bytes": moved_weights})
		if moved_weights > 0: trace.metrics.weight_reads += 1
		weight_loaded = true
		var pending: Array[Dictionary] = []
		for request_id: int in requests:
			var stream: int = request_id / STEPS; var step: int = request_id % STEPS
			if not resident.has(stream):
				if resident.size() == slots:
					var victim: int = lru.pop_front()
					if dirty.has(victim): write_state(trace, store, victim, resident[victim], state_bytes, "eviction")
					resident.erase(victim); dirty.erase(victim); trace.metrics.evictions += 1
					emit(trace, &"eviction", 0, {"stream": victim, "next_stream": stream, "resident": lru})
				transfer(trace, &"state_read", state_bytes, {"stream": stream, "state": store[stream]})
				resident[stream] = store[stream].duplicate(); trace.metrics.state_reads += 1; trace.metrics.state_read_bytes += state_bytes
			else:
				trace.metrics.state_hits += 1
				emit(trace, &"state_hit", 0, {"stream": stream, "state": resident[stream]})
			lru.erase(stream); lru.append(stream)
			trace.metrics.peak_bytes = maxi(int(trace.metrics.peak_bytes), workspace + resident.size() * state_bytes)
			var before: Array = resident[stream].duplicate(); var values: Array[float] = input(stream, step)
			var after: Array[float] = update(before, values, state_bits)
			var value: float = Linear.score(after, params); var expected: float = ref.outputs[request_id]
			resident[stream] = after; dirty[stream] = true; outputs[request_id] = value
			emit(trace, &"compute", 24, {"request_id": request_id, "stream": stream, "step": step, "input": values, "before": before, "after": after, "weights": params, "operations": 24, "operation_unit": "weighted_accumulation_with_state_rounding", "resident_lru": lru})
			pending.append({"request_id": request_id, "stream": stream, "score": value, "reference": expected, "absolute_error": absf(value - expected)})
		for evidence: Dictionary in pending:
			emit(trace, &"commit", 1, evidence)
			transfer(trace, &"output", 4, evidence, false)
			var stream: int = int(evidence.stream); var request_id: int = int(evidence.request_id)
			responses[request_id] = trace.metrics.total_cycles
			if firsts[stream] == 0: firsts[stream] = int(trace.metrics.total_cycles)
			if int(trace.metrics.first_result_cycle) == 0: trace.metrics.first_result_cycle = trace.metrics.total_cycles
			trace.metrics.max_error = maxf(float(trace.metrics.max_error), float(evidence.absolute_error))
			trace.metrics.mae += float(evidence.absolute_error) / (STREAMS * STEPS)
			trace.metrics.agreement += int((float(evidence.score) >= 0) == (float(evidence.reference) >= 0))
	emit(trace, &"flush_begin", 0, {"dirty_streams": lru})
	for stream: int in lru:
		if dirty.has(stream): write_state(trace, store, stream, resident[stream], state_bytes, "flush")
	trace.metrics.final_states = store.duplicate(true); trace.metrics.outputs = outputs
	trace.metrics.response_cycles = responses; trace.metrics.first_stream_cycles = firsts
	trace.metrics.all_streams_first_cycle = firsts.max()
	for stream: int in STREAMS:
		for j: int in WIDTH:
			trace.metrics.max_state_error = maxf(float(trace.metrics.max_state_error), absf(float(store[stream][j]) - float(ref.states[stream][j])))
	emit(trace, &"final_store", 0, {"states": store, "reference_states": ref.states, "max_state_error": trace.metrics.max_state_error})
	trace.passed = true; trace.result_value = trace.metrics.agreement; trace.expected_value = STREAMS * STEPS
	return trace
