extends RefCounted
## Receiver authority is the versioned packet alone.
const Model = preload("res://experiments/creation/model.gd")
const HEADER_BYTES: int = 20
const CHECKSUM_BYTES: int = 32
const VERSION: int = 1

static func encode(symbols: Array, model: Dictionary, machine: Dictionary, codec: String = "predictive") -> Dictionary:
	var error: String = Model.symbols_error(symbols)
	if error.is_empty(): error = Model.machine_error(machine)
	if codec not in ["raw", "predictive"]: error = "codec"
	if error.is_empty() and codec == "predictive": error = Model.validate(model)
	if not error.is_empty(): return {"ok": false, "error": error}
	var model_bytes: PackedByteArray = Model.canonical_bytes(model) if codec == "predictive" else PackedByteArray()
	var writer: Dictionary = {"data": PackedByteArray(), "bits": 0}
	var events: Array = []
	var mismatches: int = 0
	var start: int = mini(int(model.order), symbols.size()) if codec == "predictive" else symbols.size()
	if codec == "predictive": events.append(Model.event("encode", "model_load", model_bytes.size(), model_bytes.size(), {"model_id": Model.identity(model)}))
	for index: int in symbols.size():
		var symbol: int = symbols[index]
		events.append(Model.event("encode", "input_read", 1, 1, {"index": index, "symbol": symbol}))
		var before_bytes: int = writer.data.size()
		if index < start:
			_write(writer, symbol, 2)
			events.append(Model.event("encode", "literal_write", 2, writer.data.size() - before_bytes, {"index": index, "symbol": symbol}))
		else:
			var decision: Dictionary = Model.predict(model, symbols.slice(0, index))
			for item: Dictionary in decision.events:
				item.phase = "encode"
				item.index = index
				events.append(item)
			var matched: bool = decision.symbol == symbol
			_write(writer, 1 if matched else 0, 1)
			if not matched:
				_write(writer, symbol, 2)
				mismatches += 1
			events.append(Model.event("encode", "residual_write", 2 if matched else 4, writer.data.size() - before_bytes, {"index": index, "predicted": decision.symbol, "actual": symbol, "match": matched, "context": decision.context.duplicate()}))
	var packet := PackedByteArray([67, 80, 71, 49, VERSION, 0 if codec == "raw" else 1, 4, 0])
	_u32(packet, symbols.size())
	_u32(packet, model_bytes.size())
	_u32(packet, writer.bits)
	packet.append_array(model_bytes)
	packet.append_array(writer.data)
	events.append(Model.event("encode", "packet_assemble", HEADER_BYTES + model_bytes.size() + writer.data.size(), HEADER_BYTES, {"payload_bits": writer.bits}))
	var checksum: PackedByteArray = Model.digest(packet)
	events.append(Model.event("encode", "integrity_write", packet.size() + CHECKSUM_BYTES, CHECKSUM_BYTES))
	packet.append_array(checksum)
	var rows_count: int = model.rows.size() if codec == "predictive" else 0
	var peak: int = symbols.size() + model_bytes.size() + packet.size() + writer.data.size() + (int(model.order) if codec == "predictive" else 0) + mini(machine.cache_rows, rows_count) * 11
	if peak > machine.memory_bytes: return {"ok": false, "error": "memory_limit", "required_bytes": peak}
	events.append(Model.event("transfer", "packet_transfer", 0, packet.size(), {"packet_bytes": packet.size(), "codec": codec}))
	var metrics: Dictionary = {"codec": codec, "packet_bytes": packet.size(), "header_bytes": HEADER_BYTES, "checksum_bytes": CHECKSUM_BYTES, "model_bytes": model_bytes.size(), "payload_bits": int(writer.bits), "payload_bytes": writer.data.size(), "padding_bits": writer.data.size() * 8 - writer.bits, "mismatches": mismatches, "raw_symbol_bits": symbols.size() * 2, "seed_symbols": start if codec == "predictive" else 0}
	return {"ok": true, "packet": packet, "events": events, "cost": Model.summarize(events, machine, peak), "metrics": metrics, "error": ""}

static func decode(packet: PackedByteArray, machine: Dictionary) -> Dictionary:
	var error: String = Model.machine_error(machine)
	if not error.is_empty(): return {"ok": false, "error": error}
	if packet.size() < HEADER_BYTES + CHECKSUM_BYTES or packet.size() > 13000: return {"ok": false, "error": "packet_length"}
	if packet.slice(0, 4) != PackedByteArray([67, 80, 71, 49]) or packet[4] != VERSION or packet[5] > 1 or packet[6] != 4 or packet[7] != 0: return {"ok": false, "error": "packet_header"}
	var body: PackedByteArray = packet.slice(0, packet.size() - CHECKSUM_BYTES)
	if Model.digest(body) != packet.slice(packet.size() - CHECKSUM_BYTES): return {"ok": false, "error": "packet_integrity"}
	var length: int = _read_u32(packet, 8)
	var model_size: int = _read_u32(packet, 12)
	var payload_bits: int = _read_u32(packet, 16)
	var predictive: bool = packet[5] == 1
	if length > Model.MAX_LENGTH or model_size > 280 or payload_bits > length * 3 + 4: return {"ok": false, "error": "packet_bounds"}
	var payload_size: int = ceili(float(payload_bits) / 8.0)
	if HEADER_BYTES + model_size + payload_size != body.size(): return {"ok": false, "error": "packet_lengths"}
	if (predictive and model_size < 40) or (not predictive and (model_size != 0 or payload_bits != length * 2)): return {"ok": false, "error": "packet_model"}
	var model: Dictionary = {}
	if predictive:
		var restored: Dictionary = Model.from_bytes(packet.slice(HEADER_BYTES, HEADER_BYTES + model_size))
		if not restored.ok: return restored
		model = restored.model
	var payload: PackedByteArray = packet.slice(HEADER_BYTES + model_size, body.size())
	if payload_bits % 8 != 0 and not payload.is_empty():
		var unused_mask: int = (1 << (8 - payload_bits % 8)) - 1
		if (int(payload[payload.size() - 1]) & unused_mask) != 0: return {"ok": false, "error": "packet_padding"}
	var peak: int = packet.size() + model_size + length + payload.size() + (int(model.order) if predictive else 0) + mini(machine.cache_rows, model.get("rows", []).size()) * 11
	if peak > machine.memory_bytes: return {"ok": false, "error": "memory_limit", "required_bytes": peak}
	var reader: Dictionary = {"data": payload, "cursor": 0, "limit": payload_bits}
	var events: Array = [Model.event("decode", "packet_validate", packet.size(), HEADER_BYTES + CHECKSUM_BYTES)]
	if predictive: events.append(Model.event("decode", "model_load", model_size, model_size, {"model_id": Model.identity(model)}))
	var output: Array = []
	var start: int = mini(int(model.order), length) if predictive else length
	for index: int in length:
		var symbol: int = -1
		if index < start:
			symbol = _read(reader, 2)
			events.append(Model.event("decode", "literal_read", 2, 0, {"index": index, "symbol": symbol}))
		else:
			var decision: Dictionary = Model.predict(model, output)
			for item: Dictionary in decision.events:
				item.phase = "decode"
				item.index = index
				events.append(item)
			var flag: int = _read(reader, 1)
			if flag < 0: return {"ok": false, "error": "payload_truncated"}
			symbol = decision.symbol if flag == 1 else _read(reader, 2)
			events.append(Model.event("decode", "residual_read", 1 if flag == 1 else 3, 0, {"index": index, "predicted": decision.symbol, "symbol": symbol, "match": flag == 1, "context": decision.context.duplicate()}))
		if symbol < 0: return {"ok": false, "error": "payload_truncated"}
		output.append(symbol)
		events.append(Model.event("output", "recovered_write", 1 + (int(model.order) if predictive else 0), 1, {"index": index, "symbol": symbol}))
	if reader.cursor != payload_bits: return {"ok": false, "error": "payload_trailing"}
	return {"ok": true, "output": output, "model": model, "events": events, "cost": Model.summarize(events, machine, peak), "error": ""}

static func run_transport(symbols: Array, model: Dictionary, machine: Dictionary, codec: String = "predictive") -> Dictionary:
	var encoded: Dictionary = encode(symbols, model, machine, codec)
	if not encoded.ok: return encoded
	var decoded: Dictionary = decode(encoded.packet, machine)
	if not decoded.ok: return decoded
	var events: Array = encoded.events.duplicate(true)
	# Reception is a separate cold machine, so retain separately resolved caches/cycles.
	events.append_array(decoded.events.duplicate(true))
	var cost: Dictionary = {"total_cycles": encoded.cost.total_cycles + decoded.cost.total_cycles, "cpu_ops": encoded.cost.cpu_ops + decoded.cost.cpu_ops, "transfer_bytes": encoded.cost.transfer_bytes + decoded.cost.transfer_bytes, "peak_bytes": maxi(encoded.cost.peak_bytes, decoded.cost.peak_bytes)}
	return {"ok": true, "packet": encoded.packet, "output": decoded.output, "lossless": decoded.output == symbols, "model_id": Model.identity(model) if codec == "predictive" else "", "events": events, "cost": cost, "metrics": encoded.metrics, "encode": encoded, "decode": decoded, "error": ""}

static func _write(writer: Dictionary, value: int, width: int) -> void:
	for shift: int in range(width - 1, -1, -1):
		if writer.bits % 8 == 0: writer.data.append(0)
		var offset: int = writer.bits / 8
		writer.data[offset] = int(writer.data[offset]) | (((value >> shift) & 1) << (7 - writer.bits % 8))
		writer.bits += 1

static func _read(reader: Dictionary, width: int) -> int:
	if reader.cursor + width > reader.limit: return -1
	var result: int = 0
	for index: int in width:
		result = (result << 1) | ((int(reader.data[reader.cursor / 8]) >> (7 - reader.cursor % 8)) & 1)
		reader.cursor += 1
	return result

static func _u32(bytes: PackedByteArray, value: int) -> void:
	for offset: int in 4: bytes.append((value >> (offset * 8)) & 255)

static func _read_u32(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)
