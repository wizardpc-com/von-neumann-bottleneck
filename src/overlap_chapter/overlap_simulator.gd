class_name OverlapSimulator
extends RefCounted

const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
const LIMIT := 4096
const DATA := 8
const CONTROL := 1

var trace: SimulationTrace
var cycle: int
var task: Dictionary
var hardware: Dictionary
var buffers: Dictionary
var cache: Array[int]
var queue: Array[Dictionary]
var transfer: Dictionary
var compute: Dictionary
var consumed: Array[int]
var requested: Dictionary
var error: String
var line_number: int
var work_done: int
var cache_size: int


func run(source: String, board: Dictionary, workload: Dictionary) -> SimulationTrace:
	trace = Trace.new()
	trace.program_source = source
	task = workload.duplicate(true)
	hardware = board.duplicate(true)
	buffers = {}
	cache = []
	queue = []
	transfer = {}
	compute = {}
	consumed = []
	requested = {}
	cycle = 0
	work_done = 0
	error = ""
	line_number = 0
	cache_size = 0
	trace.metrics = {"total_cycles": 0, "compute_busy": 0, "transfer_busy": 0,
		"overlap": 0, "wait": 0, "hits": 0, "misses": 0, "evictions": 0,
		"queue_wait": 0, "cost": 0, "error": "", "error_line": 0}
	var nodes: Dictionary = hardware.get("nodes", {})
	if nodes.size() > 8 or not nodes.has("TRANSFER") or not nodes.has("COMPUTE"):
		_fail("machine")
	for id: String in nodes:
		var kind: String = String(nodes[id].get("kind", ""))
		if kind == "buffer":
			buffers[id] = {"state": "empty", "batch": -1}
			trace.metrics.cost += 1
		elif kind == "cache":
			cache_size += int(nodes[id].get("capacity", 1))
			trace.metrics.cost += int(nodes[id].get("capacity", 1))
		elif not ((id == "TRANSFER" and kind == "transfer") or (id == "COMPUTE" and kind == "compute")):
			_fail("machine")
	if cache_size < 0 or cache_size > 3 or int(trace.metrics.cost) > int(task.get("budget", 3)):
		_fail("budget")
	if source.length() > 16000:
		_fail("program_limit")
	var lines: PackedStringArray = source.split("\n")
	for raw: String in lines:
		if not error.is_empty(): break
		line_number += 1
		var code: String = raw.get_slice("#", 0).strip_edges().replace("\t", " ")
		if code.is_empty(): continue
		var words: PackedStringArray = code.split(" ", false)
		var command: String = words[0].to_lower()
		if command not in task.get("commands", []):
			_fail("command")
			break
		match command:
			"fetch":
				if words.size() != 3 or not words[2].is_valid_int(): _fail("syntax")
				else: _fetch(words[1].to_upper(), int(words[2]))
			"ready", "free", "consume":
				if words.size() != 2: _fail("syntax")
				elif command == "consume": _consume(words[1].to_upper())
				else: _wait_buffer(words[1].to_upper(), command == "free")
			"idle":
				if words.size() != 1: _fail("syntax")
				else:
					while not compute.is_empty() and error.is_empty(): _tick()
			"tick", "work":
				if words.size() != 2 or not words[1].is_valid_int() or int(words[1]) < 1 or int(words[1]) > 128:
					_fail("syntax")
				elif command == "tick":
					for _i: int in range(int(words[1])): _tick()
				elif not compute.is_empty(): _fail("compute_busy")
				else:
					compute = {"end": cycle + int(words[1]), "buffer": "", "batch": -1}
					_event(&"compute", int(words[1]), "COMPUTE", "COMPUTE", {"batch": -1})
					work_done += int(words[1])
					while not compute.is_empty() and error.is_empty(): _tick()
			"prefetch", "read":
				if words.size() != 2 or not words[1].is_valid_int(): _fail("syntax")
				elif command == "prefetch": _prefetch(int(words[1]))
				else: _read(int(words[1]))
			_: _fail("command")
	if error.is_empty():
		while (not compute.is_empty() or not transfer.is_empty() or not queue.is_empty()) and error.is_empty(): _tick()
	if error.is_empty() and (consumed.size() != (task.get("values", []) as Array).size() or work_done != int(task.get("work", 0))):
		_fail("incomplete")
	trace.expected_value = 0
	for value: int in task.get("values", []): trace.expected_value += value * 2 + 1
	trace.metrics.total_cycles = cycle
	trace.metrics.wait = cycle - int(trace.metrics.compute_busy)
	trace.metrics.error = error
	trace.metrics.error_line = line_number if not error.is_empty() else 0
	trace.metrics.outputs = consumed.duplicate()
	trace.passed = error.is_empty() and trace.result_value == trace.expected_value
	return trace


func _fetch(id: String, batch: int) -> void:
	if not buffers.has(id) or not _batch_valid(batch):
		_fail("buffer_or_batch")
		return
	if not _link("TRANSFER", 0, id, 0) or not _link(id, 2, "TRANSFER", 0):
		_fail("transfer_route")
		return
	if buffers[id].state != "empty":
		_fail("overwrite")
		return
	if requested.has(batch):
		_fail("duplicate")
		return
	requested[batch] = true
	buffers[id] = {"state": "filling", "batch": batch}
	_enqueue({"buffer": id, "batch": batch})


func _wait_buffer(id: String, empty: bool) -> void:
	if not buffers.has(id):
		_fail("buffer_or_batch")
		return
	if not (_link(id, 2, "TRANSFER", 0) if empty else _link(id, 1, "COMPUTE", 1)):
		_fail("control_route")
		return
	var wanted: String = "empty" if empty else "ready"
	while buffers[id].state != wanted and error.is_empty():
		if transfer.is_empty() and compute.is_empty() and queue.is_empty():
			_fail("deadlock")
			return
		_tick()


func _consume(id: String) -> void:
	if not buffers.has(id) or not _link(id, 0, "COMPUTE", 0):
		_fail("compute_route")
		return
	if buffers[id].state != "ready":
		_fail("not_ready")
		return
	if _start_compute(int(buffers[id].batch), id): buffers[id].state = "in_use"


func _start_compute(batch: int, id: String) -> bool:
	if not compute.is_empty():
		_fail("compute_busy")
		return false
	if batch != consumed.size():
		_fail("order")
		return false
	var duration: int = int(task.compute[batch])
	compute = {"end": cycle + duration, "buffer": id, "batch": batch}
	if not id.is_empty(): buffers[id].state = "in_use"
	_event(&"compute", duration, id if not id.is_empty() else "CACHE", "COMPUTE", {"batch": batch})
	return true


func _cache_connected() -> bool:
	var count: int = 0
	for id: String in hardware.get("nodes", {}):
		if hardware.nodes[id].get("kind", "") == "cache":
			count += 1
			if not _link("TRANSFER", 0, id, 0) or not _link(id, 0, "COMPUTE", 0): return false
	return count == 1 and cache_size > 0


func _prefetch(batch: int) -> void:
	if not _cache_connected() or not _batch_valid(batch):
		_fail("cache_route")
		return
	if cache.has(batch) or _pending(batch): return
	_enqueue({"buffer": "", "batch": batch})


func _read(batch: int) -> void:
	if not _cache_connected() or not _batch_valid(batch):
		_fail("cache_route")
		return
	if not compute.is_empty():
		_fail("compute_busy")
		return
	if cache.has(batch): trace.metrics.hits += 1
	else:
		trace.metrics.misses += 1
		_prefetch(batch)
		while not cache.has(batch) and error.is_empty():
			if not _pending(batch):
				_prefetch(batch)
			_tick()
	if not error.is_empty(): return
	cache.erase(batch)
	cache.append(batch) # Deterministic LRU: demand use and fills update recency.
	_start_compute(batch, "")


func _pending(batch: int) -> bool:
	if not transfer.is_empty() and transfer.buffer == "" and int(transfer.batch) == batch: return true
	for request: Dictionary in queue:
		if request.buffer == "" and int(request.batch) == batch: return true
	return false


func _enqueue(request: Dictionary) -> void:
	_event(&"request", 0, "COMPUTE", "TRANSFER", request)
	# Capacity includes the active request. A full queue blocks the issuing controller.
	while queue.size() + (0 if transfer.is_empty() else 1) >= 2 and error.is_empty():
		trace.metrics.queue_wait += 1
		_tick()
	if not error.is_empty(): return
	queue.append(request.duplicate())
	_begin_transfer()


func _begin_transfer() -> void:
	if not transfer.is_empty() or queue.is_empty(): return
	transfer = queue.pop_front()
	transfer.end = cycle + int(task.transfer)
	_event(&"transfer", int(task.transfer), "TRANSFER", String(transfer.buffer) if transfer.buffer != "" else "CACHE", {"batch": transfer.batch})


func _tick() -> void:
	if not error.is_empty(): return
	if cycle >= LIMIT:
		_fail("limit")
		return
	var moving: bool = not transfer.is_empty()
	var computing: bool = not compute.is_empty()
	trace.metrics.transfer_busy += 1 if moving else 0
	trace.metrics.compute_busy += 1 if computing else 0
	trace.metrics.overlap += 1 if moving and computing else 0
	cycle += 1
	# Deterministic simultaneous boundary: transfer completion, compute completion,
	# then the next FIFO transfer begins. UI never participates in this ordering.
	if not transfer.is_empty() and int(transfer.end) == cycle:
		var batch: int = int(transfer.batch)
		if transfer.buffer == "":
			cache.erase(batch)
			if cache.size() >= cache_size:
				var evicted: int = cache.pop_front()
				trace.metrics.evictions += 1
				_event(&"evict", 0, "CACHE", "CACHE", {"batch": evicted})
			cache.append(batch)
		else: buffers[transfer.buffer].state = "ready"
		_event(&"ready", 0, "TRANSFER", String(transfer.buffer) if transfer.buffer != "" else "CACHE", {"batch": batch})
		transfer = {}
	if not compute.is_empty() and int(compute.end) == cycle:
		var batch: int = int(compute.batch)
		if batch >= 0:
			consumed.append(batch)
			trace.result_value += int(task.values[batch]) * 2 + 1
			_event(&"output", 0, "COMPUTE", "OUT", {"batch": batch, "value": int(task.values[batch]) * 2 + 1})
		if compute.buffer != "": buffers[compute.buffer] = {"state": "empty", "batch": -1}
		compute = {}
	_begin_transfer()
	_event(&"state",0,"","",{})


func _batch_valid(batch: int) -> bool:
	return batch >= 0 and batch < (task.get("values", []) as Array).size()


func _link(from: String, output: int, to: String, input: int) -> bool:
	for wire: Array in hardware.get("wires", []):
		if wire.size() == 4 and String(wire[0]) == from and int(wire[1]) == output and String(wire[2]) == to and int(wire[3]) == input: return true
	return false


func _event(kind: StringName, duration: int, from: String, to: String, details: Dictionary) -> void:
	var evidence: Dictionary = details.duplicate(true)
	evidence["buffers"] = buffers.duplicate(true)
	evidence["cache"] = cache.duplicate()
	evidence["active_compute"] = int(compute.get("batch",-2))
	evidence["active_transfer"] = int(transfer.get("batch",-2))
	trace.add_event(Event.new(kind, cycle, duration, StringName(from), StringName(to), -1, -1, 0, "", line_number, [], evidence))


func _fail(code: String) -> void:
	if error.is_empty():
		error = code
		_event(&"error", 0, "COMPUTE", "", {"code": code})
