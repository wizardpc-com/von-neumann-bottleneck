extends RefCounted
## Frozen, sample-derived rules. UI and unrevealed targets are not information inputs.
const VERSION: int = 1
const MAX_LENGTH: int = 4096
const MAX_EXAMPLES: int = 16
const MAX_COUNT: int = 65535
const PRNG_VERSION: String = "park-miller-v1"

static func default_machine() -> Dictionary:
	return {"cpu_ops_per_cycle": 4, "bytes_per_cycle": 4, "request_cycles": 2, "memory_bytes": 8192, "cache_rows": 4}

static func machine_error(machine: Dictionary) -> String:
	if machine.size() != 5: return "machine_schema"
	for key: String in ["cpu_ops_per_cycle", "bytes_per_cycle", "request_cycles", "memory_bytes", "cache_rows"]:
		if not machine.get(key) is int: return "machine_schema"
	if machine.cpu_ops_per_cycle < 1 or machine.cpu_ops_per_cycle > 64 or machine.bytes_per_cycle < 1 or machine.bytes_per_cycle > 64: return "machine_throughput"
	if machine.request_cycles < 0 or machine.request_cycles > 64 or machine.memory_bytes < 64 or machine.memory_bytes > 65536 or machine.cache_rows < 0 or machine.cache_rows > 21: return "machine_bounds"
	return ""

static func symbols_error(symbols: Array) -> String:
	if symbols.size() > MAX_LENGTH: return "sequence_limit"
	for symbol: Variant in symbols:
		if not symbol is int or symbol < 0 or symbol > 3: return "symbol"
	return ""

static func event(phase: String, kind: String, ops: int = 0, bytes: int = 0, detail: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"phase": phase, "kind": kind, "ops": ops, "bytes": bytes, "cycles": 0}
	result.merge(detail)
	return result

static func summarize(events: Array, machine: Dictionary, peak_bytes: int) -> Dictionary:
	var cost: Dictionary = {"total_cycles": 0, "cpu_ops": 0, "transfer_bytes": 0, "peak_bytes": peak_bytes}
	if not machine_error(machine).is_empty(): return cost
	var resident: Array = []
	var phase_ops: Dictionary = {}
	for item: Dictionary in events:
		if item.kind == "model_load": resident.clear()
		var bytes: int = int(item.get("requested_bytes", item.bytes))
		if item.kind == "rule_read":
			item.requested_bytes = bytes
			var row: String = str(item.row)
			item.cache_hit = row in resident
			if item.cache_hit:
				bytes = 0
				resident.erase(row)
			if machine.cache_rows > 0:
				resident.append(row)
				if resident.size() > machine.cache_rows: resident.pop_front()
		item.bytes = bytes
		var before_ops: int = int(phase_ops.get(item.phase, 0))
		phase_ops[item.phase] = before_ops + item.ops
		item.cycles = ceili(float(before_ops + item.ops) / float(machine.cpu_ops_per_cycle)) - ceili(float(before_ops) / float(machine.cpu_ops_per_cycle))
		if bytes > 0: item.cycles += ceili(float(bytes) / float(machine.bytes_per_cycle)) + machine.request_cycles
		cost.total_cycles += item.cycles
		cost.cpu_ops += item.ops
		cost.transfer_bytes += bytes
	return cost

static func learn(examples: Array, order: int, machine: Dictionary, parent: String = "") -> Dictionary:
	var error: String = machine_error(machine)
	if not error.is_empty(): return {"ok": false, "error": error}
	if not parent.is_empty() and not _is_digest(parent): return {"ok": false, "error": "model_parent"}
	if order < 0 or order > 2 or examples.is_empty() or examples.size() > MAX_EXAMPLES: return {"ok": false, "error": "training_bounds"}
	var table: Dictionary = {}
	var events: Array = []
	var example_bytes: int = 0
	for example_index: int in examples.size():
		var example: Variant = examples[example_index]
		if not example is Array: return {"ok": false, "error": "example_schema"}
		error = symbols_error(example)
		if not error.is_empty(): return {"ok": false, "error": error}
		example_bytes += example.size()
		for index: int in example.size():
			var symbol: int = example[index]
			events.append(event("prepare", "sample_read", 1, 1, {"example": example_index, "index": index, "symbol": symbol}))
			for size: int in range(mini(order, index) + 1):
				var context: Array = example.slice(index - size, index)
				var key: String = _key(context)
				if not table.has(key): table[key] = {"context": context, "counts": [0, 0, 0, 0]}
				var before: int = table[key].counts[symbol]
				if before >= MAX_COUNT: return {"ok": false, "error": "count_overflow"}
				table[key].counts[symbol] = before + 1
				events.append(event("prepare", "count_update", 2, 4, {"context": context.duplicate(), "symbol": symbol, "before": before, "after": before + 1}))
	var keys: Array = table.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return a.length() < b.length() or (a.length() == b.length() and a < b))
	var rows: Array = []
	for key: String in keys: rows.append(table[key])
	var model: Dictionary = {"version": VERSION, "order": order, "rows": rows, "source_digest": JSON.stringify(examples).sha256_text(), "examples": examples.duplicate(true), "parent": parent}
	if parent == digest(_serialize(model)).hex_encode(): model.parent = ""
	var packed: PackedByteArray = canonical_bytes(model)
	var peak: int = packed.size() + example_bytes + order + mini(machine.cache_rows, rows.size()) * 11
	if peak > machine.memory_bytes: return {"ok": false, "error": "memory_limit", "required_bytes": peak}
	events.append(event("prepare", "model_write", packed.size(), packed.size(), {"model_id": identity(model)}))
	return {"ok": true, "model": model, "events": events, "cost": summarize(events, machine, peak), "error": ""}

static func validate(model: Dictionary) -> String:
	for key: Variant in model:
		if key not in ["version", "order", "rows", "source_digest", "examples", "parent"]: return "model_field"
	if not model.get("version") is int or model.version != VERSION or not model.get("order") is int or not model.get("rows") is Array or not model.get("source_digest") is String or not model.get("examples") is Array or not model.get("parent") is String: return "model_schema"
	if model.order < 0 or model.order > 2 or model.rows.size() > 21 or not _is_digest(model.source_digest): return "model_bounds"
	if not model.parent.is_empty() and not _is_digest(model.parent): return "model_parent"
	if model.has("examples"):
		if not model.examples is Array or model.examples.size() > MAX_EXAMPLES: return "example_schema"
		if not model.examples.is_empty():
			for example: Variant in model.examples:
				if not example is Array or not symbols_error(example).is_empty(): return "example_schema"
			if JSON.stringify(model.examples).sha256_text() != model.source_digest: return "source_digest"
	var previous: String = ""
	var previous_size: int = -1
	for row: Variant in model.rows:
		if not row is Dictionary or not row.get("context") is Array or not row.get("counts") is Array or row.counts.size() != 4: return "row_schema"
		for key: Variant in row:
			if key not in ["context", "counts"]: return "row_field"
		if row.context.size() > model.order or not symbols_error(row.context).is_empty(): return "context"
		var key: String = _key(row.context)
		if row.context.size() < previous_size or (row.context.size() == previous_size and key <= previous): return "row_order"
		var total: int = 0
		for count: Variant in row.counts:
			if not count is int or count < 0 or count > MAX_COUNT: return "count"
			total += count
		if total == 0: return "empty_row"
		previous = key
		previous_size = row.context.size()
	if model.parent == digest(_serialize(model)).hex_encode(): return "model_parent_self"
	return ""

static func canonical_bytes(model: Dictionary) -> PackedByteArray:
	if not validate(model).is_empty(): return PackedByteArray()
	return _serialize(model)

static func _serialize(model: Dictionary) -> PackedByteArray:
	var out := PackedByteArray([67, 80, 77, 49, VERSION, model.order, model.rows.size(), 0])
	out.append_array(model.source_digest.hex_decode())
	for row: Dictionary in model.rows:
		out.append(row.context.size())
		for symbol: int in row.context: out.append(symbol)
		for count: int in row.counts:
			out.append(count & 255)
			out.append((count >> 8) & 255)
	return out

static func from_bytes(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < 40 or bytes.slice(0, 4) != PackedByteArray([67, 80, 77, 49]) or bytes[4] != VERSION or bytes[5] > 2 or bytes[6] > 21 or bytes[7] != 0: return {"ok": false, "error": "model_header"}
	var rows: Array = []
	var cursor: int = 40
	for index: int in bytes[6]:
		if cursor >= bytes.size(): return {"ok": false, "error": "model_truncated"}
		var size: int = bytes[cursor]
		cursor += 1
		if size > bytes[5] or cursor + size + 8 > bytes.size(): return {"ok": false, "error": "model_truncated"}
		var context: Array = []
		for offset: int in size: context.append(int(bytes[cursor + offset]))
		cursor += size
		var counts: Array = []
		for offset: int in 4: counts.append(int(bytes[cursor + offset * 2]) | (int(bytes[cursor + offset * 2 + 1]) << 8))
		cursor += 8
		rows.append({"context": context, "counts": counts})
	if cursor != bytes.size(): return {"ok": false, "error": "model_trailing"}
	var model: Dictionary = {"version": VERSION, "order": int(bytes[5]), "rows": rows, "source_digest": bytes.slice(8, 40).hex_encode(), "examples": [], "parent": ""}
	var error: String = validate(model)
	if not error.is_empty(): return {"ok": false, "error": error}
	return {"ok": true, "model": model, "error": ""}

static func identity(model: Dictionary) -> String:
	var packed: PackedByteArray = canonical_bytes(model)
	return digest(packed).hex_encode() if not packed.is_empty() else ""

static func digest(bytes: PackedByteArray) -> PackedByteArray:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish()

static func predict(model: Dictionary, prefix: Array) -> Dictionary:
	var error: String = validate(model)
	if not error.is_empty(): return {"ok": false, "error": error}
	error = symbols_error(prefix)
	if not error.is_empty(): return {"ok": false, "error": error}
	var events: Array = []
	var available: int = mini(model.order, prefix.size())
	for size: int in range(available, -1, -1):
		var context: Array = prefix.slice(prefix.size() - size)
		for row: Dictionary in model.rows:
			events.append(event("predict", "rule_read", 1 + row.context.size(), 9 + row.context.size(), {"row": _key(row.context), "context": row.context.duplicate(), "lookup_context": context.duplicate()}))
			if row.context != context: continue
			var symbol: int = 0
			for candidate: int in range(1, 4):
				if row.counts[candidate] > row.counts[symbol]: symbol = candidate
			events.append(event("predict", "successor_select", 4, 0, {"context": context.duplicate(), "counts": row.counts.duplicate(), "symbol": symbol, "fallback": available - size}))
			return {"ok": true, "symbol": symbol, "counts": row.counts.duplicate(), "context": context, "fallback": available - size, "events": events, "error": ""}
		events.append(event("predict", "fallback", 1, 0, {"context": context.duplicate(), "reason": "unseen_context"}))
	events.append(event("predict", "successor_select", 4, 0, {"counts": [1, 1, 1, 1], "symbol": 0, "reason": "uniform_default"}))
	return {"ok": true, "symbol": 0, "counts": [1, 1, 1, 1], "context": [], "fallback": available + 1, "events": events, "error": ""}

static func generate(model: Dictionary, initial: Array, length: int, seed: int, sampler: String, machine: Dictionary) -> Dictionary:
	var error: String = validate(model)
	if error.is_empty(): error = symbols_error(initial)
	if error.is_empty(): error = machine_error(machine)
	if not error.is_empty(): return {"ok": false, "error": error}
	if length <= initial.size() or length > MAX_LENGTH or length < 1 or sampler not in ["weighted", "max"]: return {"ok": false, "error": "generation_bounds"}
	var packed: PackedByteArray = canonical_bytes(model)
	var peak: int = packed.size() + length + model.order + mini(machine.cache_rows, model.rows.size()) * 11
	if peak > machine.memory_bytes: return {"ok": false, "error": "memory_limit", "required_bytes": peak}
	var output: Array = initial.duplicate()
	var events: Array = [event("generate", "model_load", packed.size(), packed.size(), {"model_id": identity(model)})]
	for index: int in initial.size(): events.append(event("output", "seed_write", 1, 1, {"index": index, "symbol": initial[index]}))
	var state: int = ((seed % 2147483646) + 2147483646) % 2147483646 + 1
	while output.size() < length:
		var decision: Dictionary = predict(model, output)
		for item: Dictionary in decision.events:
			item.phase = "generate"
			events.append(item)
		var symbol: int = decision.symbol
		var before: int = state
		if sampler == "weighted":
			var total: int = 0
			for count: int in decision.counts: total += count
			var limit: int = 2147483646 - (2147483646 % total)
			state = (state * 16807) % 2147483647
			events.append(event("generate", "sample_draw", 3, 0, {"state_before": before, "state_after": state, "rejected": state - 1 >= limit}))
			while state - 1 >= limit:
				before = state
				state = (state * 16807) % 2147483647
				events.append(event("generate", "sample_draw", 3, 0, {"state_before": before, "state_after": state, "rejected": state - 1 >= limit}))
			var draw: int = (state - 1) % total
			var cumulative: int = 0
			for candidate: int in 4:
				cumulative += decision.counts[candidate]
				if draw < cumulative:
					symbol = candidate
					break
			events.append(event("generate", "sample", 4, 0, {"state_after": state, "draw": draw, "counts": decision.counts.duplicate(), "symbol": symbol}))
		output.append(symbol)
		events.append(event("output", "feedback_write", 1 + model.order, 1, {"index": output.size() - 1, "symbol": symbol, "context": output.slice(maxi(0, output.size() - model.order)), "before_context": decision.context.duplicate(), "counts": decision.counts.duplicate(), "sampler": sampler}))
	var recipe: Dictionary = {"version": VERSION, "model": model.duplicate(true), "model_id": identity(model), "machine": machine.duplicate(true), "initial": initial.duplicate(), "length": length, "seed": seed, "sampler": sampler, "sampler_version": "integer-counts-v1", "prng_version": PRNG_VERSION}
	return {"ok": true, "output": output, "events": events, "cost": summarize(events, machine, peak), "recipe": recipe, "model_id": identity(model), "error": ""}

static func _key(context: Array) -> String:
	var key: String = ""
	for symbol: int in context: key += str(symbol)
	return key

static func _is_digest(value: String) -> bool:
	if value.length() != 64: return false
	for index: int in value.length():
		if value[index] not in "0123456789abcdef": return false
	return true
