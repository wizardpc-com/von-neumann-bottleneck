extends RefCounted
## Constructed service queue. Pure model, actual serialized persistent bytes.
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
const OldState = preload("res://experiments/intelligent_workload/state_model.gd")
const Codec = preload("res://experiments/representation/model.gd")
const VERSION: String = "service-plan-v1"
const REPRESENTATIONS: Array[String] = ["raw64", "rle64", "raw8", "rle8"]
const SCRATCH_LIMIT: int = 512
const WEIGHTS: Array[float] = [0.83, -0.41, 0.17, 0.06, -0.29, 0.71, -0.13, 0.37]

static func initial(stream: int) -> Array[float]:
	var values: Array[float] = OldState.initial(stream)
	if stream < 2:
		for j: int in 8: values[j] = values[0]
	return values

static func input(stream: int, step: int) -> Array[float]:
	var values: Array[float] = OldState.input(stream, step)
	if stream < 2:
		for j: int in 8: values[j] = values[0]
	return values

static func rounded(value: float, representation: String) -> float:
	return roundf(clampf(value, -1.0, 1.0) * 127.0) / 127.0 if representation.ends_with("8") else value

static func pack(state: Array, representation: String) -> PackedByteArray:
	var raw := PackedByteArray()
	if representation.ends_with("64"):
		raw.resize(64)
		for j: int in 8: raw.encode_double(j * 8, float(state[j]))
	else:
		for value: float in state: raw.append(int(roundf(clampf(value, -1.0, 1.0) * 127.0)) & 255)
	if representation == "rle64":
		var out := PackedByteArray([8, 0]); var index: int = 0
		while index < 8:
			var count: int = 1; var word: PackedByteArray = raw.slice(index * 8, index * 8 + 8)
			while index + count < 8 and raw.slice((index + count) * 8, (index + count + 1) * 8) == word: count += 1
			out.append(count); out.append_array(word); index += count
		return out
	var values: Array[int] = []; values.assign(Array(raw))
	return Codec.encode(values, "rle" if representation.begins_with("rle") else "raw")

static func unpack(payload: PackedByteArray, representation: String) -> Array[float]:
	var raw := PackedByteArray()
	if representation == "rle64":
		if payload.size() < 11 or (payload.size() - 2) % 9 != 0 or payload[0] != 8 or payload[1] != 0: return []
		for index: int in range(2, payload.size(), 9):
			var count: int = payload[index]
			if count == 0 or raw.size() + count * 8 > 64: return []
			for n: int in count: raw.append_array(payload.slice(index + 1, index + 9))
	else:
		raw = PackedByteArray(Codec.decode(payload, "rle" if representation.begins_with("rle") else "raw"))
	var result: Array[float] = []
	if raw.size() != (64 if representation.ends_with("64") else 8): return result
	for j: int in 8:
		if representation.ends_with("64"): result.append(raw.decode_double(j * 8))
		else: result.append(float(int(raw[j]) - (256 if raw[j] > 127 else 0)) / 127.0)
	return result

static func record(payload: PackedByteArray) -> Array[int]:
	var values: Array[int] = [payload.size() & 255, payload.size() >> 8]
	values.append_array(Array(payload)); return values

static func codec_ops(payload: PackedByteArray, representation: String) -> int:
	if representation == "rle64": return 8 + 8 + (payload.size() - 2) / 9
	return 8 + (8 + (payload.size() - 2) / 2 if representation == "rle8" else 0)

static func reference_result() -> Dictionary:
	var states: Array = []; var outputs: Array[float] = []
	for stream: int in 4:
		var state: Array[float] = initial(stream)
		for step: int in 6:
			var values: Array[float] = input(stream, step); var score: float = 0.0
			for j: int in 8:
				state[j] = 0.65 * state[j] + 0.35 * values[j]; score += WEIGHTS[j] * state[j]
			outputs.append(score)
		states.append(state.duplicate())
	return {"outputs": outputs, "states": states}

static func initial_plan() -> Dictionary:
	var groups: Array = []
	for step: int in 6:
		for stream: int in 4: groups.append([stream * 6 + step])
	return {"groups": groups, "representations": ["raw64", "raw64", "raw64", "raw64"], "slots": 1}

static func split(plan: Dictionary, index: int, boundary: int) -> Dictionary:
	var next: Dictionary = plan.duplicate(true)
	if index >= 0 and index < next.groups.size() and boundary > 0 and boundary < next.groups[index].size():
		var group: Array = next.groups[index]
		next.groups[index] = group.slice(0, boundary); next.groups.insert(index + 1, group.slice(boundary))
	return next

static func merge(plan: Dictionary, index: int) -> Dictionary:
	var next: Dictionary = plan.duplicate(true)
	if index >= 0 and index + 1 < next.groups.size():
		next.groups[index].append_array(next.groups[index + 1]); next.groups.remove_at(index + 1)
	return next

static func move(plan: Dictionary, index: int, offset: int) -> Dictionary:
	var next: Dictionary = plan.duplicate(true); var target: int = index + offset
	if index >= 0 and index < next.groups.size() and target >= 0 and target < next.groups.size():
		var group: Array = next.groups[index]; next.groups.remove_at(index); next.groups.insert(target, group)
	return next

static func represent(plan: Dictionary, stream: int, representation: String) -> Dictionary:
	var next: Dictionary = plan.duplicate(true)
	if stream >= 0 and stream < 4 and representation in REPRESENTATIONS: next.representations[stream] = representation
	return next

static func validate(plan: Dictionary) -> String:
	if not plan.get("groups") is Array or not plan.get("representations") is Array or not plan.get("slots") is int: return "plan_schema"
	if plan.slots < 1 or plan.slots > 4 or plan.representations.size() != 4 or plan.groups.is_empty(): return "plan_schema"
	var max_buffer: int = 0
	for representation: Variant in plan.representations:
		if not representation is String or representation not in REPRESENTATIONS: return "representation"
		max_buffer = maxi(max_buffer, (76 if representation == "rle64" else (66 if representation == "raw64" else (20 if representation == "rle8" else 10))))
	var steps: Array[int] = [0, 0, 0, 0]; var count: int = 0; var largest: int = 0
	for group: Variant in plan.groups:
		if not group is Array or group.is_empty(): return "group_schema"
		largest = maxi(largest, group.size())
		for id: Variant in group:
			if not id is int or id < 0 or id >= 24: return "request_id"
			var stream: int = id / 6; var step: int = id % 6
			if step != steps[stream]: return "stream_dependency"
			steps[stream] += 1; count += 1
	if count != 24 or steps != [6, 6, 6, 6]: return "exact_requests"
	if 64 + largest * 72 + plan.slots * 64 + max_buffer > SCRATCH_LIMIT: return "scratch_limit"
	return ""

static func emit(trace: Trace, kind: StringName, duration: int, details: Dictionary) -> void:
	trace.add_event(Event.new(kind, int(trace.metrics.total_cycles), duration, &"", &"", -1, -1, 0, "", 0, [], details))
	trace.metrics.total_cycles += duration
	if kind == &"compute": trace.metrics.compute_cycles += duration
	elif kind == &"commit": trace.metrics.commit_cycles += duration
	elif kind in [&"encode", &"decode", &"quantize"]: trace.metrics.codec_cycles += duration

static func transfer(trace: Trace, kind: StringName, bytes: int, details: Dictionary, setup: bool = true) -> void:
	if setup:
		emit(trace, &"request", 4, {"operation": String(kind), "bytes": bytes}); trace.metrics.request_cycles += 4
	var evidence: Dictionary = details.duplicate(true); evidence.bytes = bytes
	var cycles: int = ceili(float(bytes) / 4.0)
	emit(trace, kind, cycles, evidence); trace.metrics.transfer_cycles += cycles; trace.metrics.traffic_bytes += bytes

static func peak(trace: Trace, resident_count: int, temporary: int, workspace: int) -> void:
	trace.metrics.peak_bytes = maxi(trace.metrics.peak_bytes, workspace + resident_count * 64 + temporary)

static func write_state(trace: Trace, store: Array, stream: int, state: Array, representation: String, reason: String, residents: int, workspace: int) -> void:
	var payload: PackedByteArray = pack(state, representation); var ops: int = codec_ops(payload, representation)
	peak(trace, residents, payload.size() + 2, workspace)
	var evidence: Dictionary = {"stream": stream, "state": state.duplicate(), "representation": representation, "encoded": record(payload), "reason": reason, "ops": ops, "previous_bytes": store[stream].size() + 2}
	emit(trace, &"encode", ceili(float(ops) / 8.0), evidence)
	transfer(trace, &"state_write", payload.size() + 2, evidence)
	store[stream] = payload; trace.metrics.state_writes += 1; trace.metrics.state_write_bytes += payload.size() + 2
	if reason == "flush": trace.metrics.flush_writes += 1

static func accepted(metrics: Dictionary, task: int) -> bool:
	if task < 0 or task > 2 or not str(metrics.error).is_empty(): return false
	if task == 0: return metrics.peak_bytes <= 350 and metrics.total_cycles <= 1420 and metrics.state_read_bytes + metrics.state_write_bytes <= 600 and metrics.max_error <= 0.000000001 and metrics.max_state_error <= 0.000000001
	if task == 1: return metrics.total_cycles <= 1420 and metrics.all_streams_first_cycle <= 320 and metrics.max_error <= 0.000000001 and metrics.max_state_error <= 0.000000001
	return metrics.total_cycles <= 1420 and metrics.all_streams_first_cycle <= 320 and metrics.state_read_bytes + metrics.state_write_bytes <= 320 and metrics.max_error <= 0.02 and metrics.max_state_error <= 0.02

static func run(plan: Dictionary) -> Trace:
	var trace := Trace.new(); trace.test_name = VERSION
	trace.metrics = {"plan": plan.duplicate(true), "error": validate(plan), "total_cycles": 0, "traffic_bytes": 0, "request_cycles": 0, "transfer_cycles": 0, "compute_cycles": 0, "commit_cycles": 0, "codec_cycles": 0, "peak_bytes": 0, "state_reads": 0, "state_writes": 0, "state_read_bytes": 0, "state_write_bytes": 0, "state_hits": 0, "evictions": 0, "flush_writes": 0, "outputs": [], "final_states": [], "first_stream_cycles": [0, 0, 0, 0], "response_cycles": [], "max_error": 0.0, "max_state_error": 0.0, "all_streams_first_cycle": 0, "initial_backing_bytes": 0, "final_backing_bytes": 0}
	if not trace.metrics.error.is_empty(): return trace
	var largest: int = 0
	for group: Array in plan.groups: largest = maxi(largest, group.size())
	var workspace: int = 64 + largest * 72
	trace.metrics.workspace_bytes = workspace
	var store: Array = []; var resident: Dictionary = {}; var lru: Array[int] = []; var dirty: Dictionary = {}
	var outputs: Array = []; outputs.resize(24); var responses: Array = []; responses.resize(24)
	for stream: int in 4:
		var values: Array[float] = initial(stream)
		for j: int in 8: values[j] = rounded(values[j], plan.representations[stream])
		var payload: PackedByteArray = pack(values, plan.representations[stream]); store.append(payload)
		trace.metrics.initial_backing_bytes += payload.size() + 2
	emit(trace, &"initial_store", 0, {"records": store.duplicate(true), "representations": plan.representations.duplicate(), "weights": WEIGHTS})
	transfer(trace, &"weight_read", 64, {"weights": WEIGHTS})
	var ref: Dictionary = reference_result(); trace.metrics.reference = ref.duplicate(true)
	for group_index: int in plan.groups.size():
		var group: Array = plan.groups[group_index]
		transfer(trace, &"group_read", group.size() * 64, {"group": group_index, "request_ids": group.duplicate()})
		var pending: Array[Dictionary] = []
		for request_id: int in group:
			var stream: int = request_id / 6; var step: int = request_id % 6; var representation: String = plan.representations[stream]
			if not resident.has(stream):
				if resident.size() == plan.slots:
					var victim: int = lru.pop_front()
					if dirty.has(victim): write_state(trace, store, victim, resident[victim], plan.representations[victim], "eviction", resident.size(), workspace)
					resident.erase(victim); dirty.erase(victim); trace.metrics.evictions += 1
					emit(trace, &"eviction", 0, {"stream": victim, "lru": lru})
				var payload: PackedByteArray = store[stream]
				transfer(trace, &"state_read", payload.size() + 2, {"stream": stream, "representation": representation, "encoded": record(payload)})
				var state: Array[float] = unpack(payload, representation)
				if state.size() != 8: trace.metrics.error = "decode"; return trace
				resident[stream] = state; peak(trace, resident.size(), payload.size() + 2, workspace)
				var ops: int = codec_ops(payload, representation)
				emit(trace, &"decode", ceili(float(ops) / 8.0), {"stream": stream, "state": state, "ops": ops})
				trace.metrics.state_reads += 1; trace.metrics.state_read_bytes += payload.size() + 2
			else:
				trace.metrics.state_hits += 1; emit(trace, &"state_hit", 0, {"stream": stream})
			lru.erase(stream); lru.append(stream)
			var before: Array = resident[stream].duplicate(); var after: Array[float] = []; var values: Array[float] = input(stream, step); var score: float = 0.0
			for j: int in 8:
				after.append(rounded(0.65 * float(before[j]) + 0.35 * values[j], representation)); score += WEIGHTS[j] * after[j]
			if representation.ends_with("8"): emit(trace, &"quantize", 1, {"request_id": request_id, "ops": 8})
			resident[stream] = after; dirty[stream] = true; outputs[request_id] = score
			emit(trace, &"compute", 24, {"request_id": request_id, "stream": stream, "step": step, "before": before, "after": after, "input": values, "lru": lru, "representation": representation})
			pending.append({"request_id": request_id, "stream": stream, "score": score, "reference": ref.outputs[request_id], "error": absf(score - ref.outputs[request_id])})
		for evidence: Dictionary in pending:
			emit(trace, &"commit", 1, evidence); transfer(trace, &"output", 8, evidence, false)
			responses[evidence.request_id] = trace.metrics.total_cycles
			if trace.metrics.first_stream_cycles[evidence.stream] == 0: trace.metrics.first_stream_cycles[evidence.stream] = trace.metrics.total_cycles
			trace.metrics.max_error = maxf(trace.metrics.max_error, evidence.error)
	emit(trace, &"flush_begin", 0, {"dirty_streams": lru.duplicate()})
	for stream: int in lru:
		if dirty.has(stream): write_state(trace, store, stream, resident[stream], plan.representations[stream], "flush", resident.size(), workspace)
	var final_states: Array = []
	for stream: int in 4:
		var state: Array[float] = unpack(store[stream], plan.representations[stream]); final_states.append(state)
		trace.metrics.final_backing_bytes += store[stream].size() + 2
		for j: int in 8: trace.metrics.max_state_error = maxf(trace.metrics.max_state_error, absf(state[j] - ref.states[stream][j]))
	trace.metrics.final_states = final_states; trace.metrics.outputs = outputs; trace.metrics.response_cycles = responses
	trace.metrics.all_streams_first_cycle = trace.metrics.first_stream_cycles.max()
	emit(trace, &"final_store", 0, {"records": store.duplicate(true), "states": final_states})
	trace.passed = true; return trace
