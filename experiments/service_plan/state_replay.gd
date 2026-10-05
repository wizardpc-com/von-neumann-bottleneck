extends RefCounted
## Pure projection of recorded event prefixes. Never runs the model or decodes bytes.
const STREAMS: int = 4
const REQUESTS: int = 24
const DECODED_BYTES: int = 64

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= low and value <= high

static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func state_valid(value: Variant) -> bool:
	if not value is Array or value.size() != 8: return false
	for coordinate: Variant in value:
		if not number(coordinate): return false
	return true

static func cell(stream: int, is_backing: bool = false) -> Dictionary:
	var result := {"stream":stream,"present":false,"state":[],"dirty":false,"bytes":0,"last_request":-1}
	if is_backing: result.encoded = PackedByteArray()
	return result

static func cells(is_backing: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stream: int in STREAMS: result.append(cell(stream,is_backing))
	return result

static func transfer_payload(details: Dictionary) -> Dictionary:
	# Model state transfers record a two-byte little-endian directory, then payload.
	var encoded: Variant = details.get("encoded")
	if not encoded is Array and not encoded is PackedByteArray: return {"ok":false}
	if encoded.size() < 3 or not integer(details.get("bytes"),3,65537) or int(details.bytes) != encoded.size(): return {"ok":false}
	var bytes := PackedByteArray()
	for byte: Variant in encoded:
		if not integer(byte,0,255): return {"ok":false}
		bytes.append(int(byte))
	if int(bytes[0])+int(bytes[1])*256 != bytes.size()-2: return {"ok":false}
	return {"ok":true,"encoded":bytes.slice(2)}

static func identity_valid(details: Dictionary) -> bool:
	if details.has("stream") and not integer(details.stream,0,STREAMS-1): return false
	if details.has("request_id"):
		if not integer(details.request_id,0,REQUESTS-1): return false
		if details.has("stream") and int(details.stream) != int(details.request_id)/6: return false
	if details.has("step"):
		if not integer(details.step,0,5): return false
		if details.has("request_id") and int(details.step) != int(details.request_id)%6: return false
	for field: String in ["lru","dirty_streams","request_ids"]:
		if not details.has(field): continue
		if not details[field] is Array: return false
		for value: Variant in details[field]:
			if not integer(value,0,REQUESTS-1 if field == "request_ids" else STREAMS-1): return false
	return true

static func build(events: Array) -> Array[Dictionary]:
	var frames: Array[Dictionary] = []
	var residents: Array[Dictionary] = cells(false)
	var backing: Array[Dictionary] = cells(true)
	var responses: Array[Dictionary] = []
	var read_bytes: int = 0
	var write_bytes: int = 0
	for source_index: int in events.size():
		var source: Variant = events[source_index]
		# Reject the entire projection, rather than presenting a partial invalid run.
		if not source is Dictionary or not source.get("kind") is String or str(source.kind).is_empty() or not source.get("details") is Dictionary: return []
		var event: Dictionary = source.duplicate(true)
		var d: Dictionary = event.details
		var kind: String = event.kind
		if not identity_valid(d): return []
		var stream: int = int(d.get("stream",-1))
		if kind in ["state_read","decode","state_hit","compute","encode","state_write","eviction","output","commit"] and stream < 0: return []
		match kind:
			"initial_store", "final_store":
				if not d.get("records") is Array or d.records.size() != STREAMS: return []
				if kind == "final_store" and (not d.get("states") is Array or d.states.size() != STREAMS): return []
				for id: int in STREAMS:
					if not d.records[id] is PackedByteArray or d.records[id].is_empty(): return []
					if kind == "final_store" and not state_valid(d.states[id]): return []
					backing[id].present = true
					backing[id].encoded = d.records[id].duplicate()
					backing[id].bytes = d.records[id].size()+2
					backing[id].state = d.states[id].duplicate(true) if kind == "final_store" else []
					backing[id].dirty = false
			"state_read", "state_write":
				var payload: Dictionary = transfer_payload(d)
				if not payload.ok: return []
				if kind == "state_write" and not state_valid(d.get("state")): return []
				if kind == "state_read":
					read_bytes += int(d.bytes)
					if backing[stream].encoded != payload.encoded: backing[stream].state = []
				else:
					write_bytes += int(d.bytes)
					backing[stream].state = d.state.duplicate(true)
					backing[stream].last_request = residents[stream].last_request
					residents[stream].dirty = false # Write completes; eviction is a later event.
				backing[stream].present = true
				backing[stream].encoded = payload.encoded.duplicate()
				backing[stream].bytes = int(d.bytes)
			"decode":
				if not state_valid(d.get("state")): return []
				residents[stream].present = true
				residents[stream].state = d.state.duplicate(true)
				residents[stream].bytes = DECODED_BYTES
				residents[stream].dirty = false
				residents[stream].last_request = backing[stream].last_request
			"state_hit":
				residents[stream].present = true
				residents[stream].bytes = DECODED_BYTES
			"compute":
				if not integer(d.get("request_id"),0,REQUESTS-1) or not state_valid(d.get("before")) or not state_valid(d.get("after")): return []
				residents[stream].present = true
				residents[stream].state = d.after.duplicate(true)
				residents[stream].bytes = DECODED_BYTES
				residents[stream].dirty = true
				residents[stream].last_request = int(d.request_id)
			"eviction":
				residents[stream] = cell(stream)
			"output":
				if not integer(d.get("request_id"),0,REQUESTS-1) or not number(d.get("score")) or not number(d.get("error")) or d.error < 0: return []
				responses.append({"request_id":int(d.request_id),"stream":stream,"score":d.score,"error":d.error})
		frames.append({"source_index":source_index,"event":event,"residents":residents.duplicate(true),"backing":backing.duplicate(true),"responses":responses.duplicate(true),"state_read_bytes":read_bytes,"state_write_bytes":write_bytes})
	return frames
