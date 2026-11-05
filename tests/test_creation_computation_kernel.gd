extends SceneTree
## Public boundaries stay strict while one validated operation reuses its kernel.
## The frozen old/new benchmark supplies independent complete differential evidence.
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func same(left: Variant, right: Variant) -> bool:
	return var_to_bytes(left) == var_to_bytes(right)


func rejected(result: Dictionary, error: String, label: String) -> void:
	check(not result.get("ok", false) and result.get("error") == error, label + ": " + error)


func account(result: Dictionary, label: String) -> void:
	var cycles: int = 0
	var operations: int = 0
	var bytes: int = 0
	for event: Dictionary in result.events:
		cycles += int(event.cycles)
		operations += int(event.ops)
		bytes += int(event.bytes)
	check(result.cost.total_cycles == cycles and result.cost.cpu_ops == operations
		and result.cost.transfer_bytes == bytes, label + ": all modeled work retained in events")


func decisions_match(events: Array, model: Dictionary, source: Array, first: int, phase: String, label: String) -> void:
	# Reconcile each actual operation's complete decision events with the strict
	# public predictor. Only undo presentation phase/index and resolved cache cost.
	var pending: Array = []
	var position: int = first
	for item: Dictionary in events:
		if item.phase != phase or item.kind not in ["rule_read", "fallback", "successor_select"]: continue
		var decision_event: Dictionary = item.duplicate(true)
		decision_event.phase = "predict"
		decision_event.cycles = 0
		decision_event.erase("index")
		if decision_event.has("requested_bytes"):
			decision_event.bytes = decision_event.requested_bytes
			decision_event.erase("requested_bytes")
			decision_event.erase("cache_hit")
		pending.append(decision_event)
		if item.kind != "successor_select": continue
		if position >= source.size():
			check(false, label + ": no prediction beyond output")
			return
		var public: Dictionary = Model.predict(model, source.slice(0, position))
		check(public.ok and same(pending, public.events), label + ": full public decision at " + str(position))
		pending = []
		position += 1
	check(position == source.size() and pending.is_empty(), label + ": every output decision completed")


func bounded_predictions(model: Dictionary, order: int) -> void:
	var symbols: Array = [0,1,0,2,0,1,3,3,2,0,2,1,0]
	var original: PackedByteArray = var_to_bytes([model, symbols])
	for end: int in range(symbols.size() + 1):
		var public: Dictionary = Model.predict(model, symbols.slice(0, end))
		var bounded: Dictionary = Model._predict_validated(model, symbols, end)
		check(public.ok and same(public, bounded), "order%d: bounded prefix matches every public field/event at%d" % [order, end])
		var different_future: Array = symbols.duplicate()
		for index: int in range(end, different_future.size()):
			different_future[index] = (int(different_future[index]) + 1) % 4
		check(same(bounded, Model._predict_validated(model, different_future, end)),
			"order%d: unrevealed suffix cannot affect decision at%d" % [order, end])
	check(var_to_bytes([model, symbols]) == original, "bounded calls leave validated model/source unchanged")
	var fallback: Dictionary = Model.predict(model, [3,3])
	check(fallback.ok and fallback.context.is_empty() and fallback.fallback == order,
		"unseen context falls back through every available order")
	if order == 2:
		var fallbacks: int = 0
		for event: Dictionary in fallback.events:
			if event.kind == "fallback": fallbacks += 1
		check(fallbacks == 2, "both failed context searches retain their fallback events")


func operation_evidence(model: Dictionary, order: int, machine: Dictionary) -> void:
	var source: Array = [3,3,0,1,0,2,0,1,0,2,1,0,3,2,1,0]
	for sampler: String in ["max", "weighted"]:
		var result: Dictionary = Model.generate(model, [3,3], 48, 987, sampler, machine)
		check(result.ok, "order%d/%s: actual generation succeeds" % [order, sampler])
		if not result.ok: continue
		check(same(result, Model.generate(model, [3,3], 48, 987, sampler, machine)),
			"same seed and model retain complete deterministic generation evidence")
		account(result, "generation")
		decisions_match(result.events, model, result.output, 2, "generate", "generation")
		var feedback: int = 0
		var samples: int = 0
		var draws: int = 0
		for event: Dictionary in result.events:
			if event.kind == "feedback_write":
				check(event.index == feedback + 2 and event.symbol == result.output[event.index],
					"feedback writes actual generated symbol in causal order")
				feedback += 1
			if event.kind == "sample": samples += 1
			if event.kind == "sample_draw": draws += 1
		check(feedback == 46 and samples == (46 if sampler == "weighted" else 0),
			"every generated output retains its sampler and feedback operation")
		check(draws >= samples if sampler == "weighted" else draws == 0,
			"weighted PRNG draws retained; max mode consumes none")
		check(result.model_id == Model.identity(model) and result.recipe.model_id == result.model_id,
			"reused generation identity equals public canonical identity")
	for codec: String in ["raw", "predictive"]:
		var result: Dictionary = Codec.run_transport(source, model, machine, codec)
		check(result.ok and result.lossless and result.output == source, "actual " + codec + " packet restores exact source")
		if not result.ok: continue
		check(same(result, Codec.run_transport(source, model, machine, codec)), "complete " + codec + " transport is deterministic")
		account(result, codec + " transport")
		account(result.encode, codec + " encoding")
		account(result.decode, codec + " decoding")
		if codec == "predictive":
			decisions_match(result.encode.events, model, source, mini(order, source.size()), "encode", "encoder")
			decisions_match(result.decode.events, result.decode.model, source, mini(order, source.size()), "decode", "receiver")
			check(Model.canonical_bytes(result.decode.model) == Model.canonical_bytes(model),
				"packet-only restored model has exactly canonical carried bytes")
			for part: Dictionary in [result.encode, result.decode]:
				for event: Dictionary in part.events:
					if event.kind == "model_load":
						check(event.model_id == Model.identity(model), "local packet/model digest preserves original model-load identity")


func strict_public_boundaries(model: Dictionary, machine: Dictionary) -> void:
	var prefix: Array = []
	prefix.resize(512)
	prefix.fill(0)
	prefix[0] = 9
	rejected(Model.predict(model, prefix), "symbol", "public prediction checks old history outside last two symbols")
	rejected(Model.generate(model, prefix, 513, 17, "max", machine), "symbol", "generation checks entire supplied seed")
	rejected(Codec.encode(prefix, model, machine), "symbol", "encoder checks entire supplied source")
	prefix[0] = 0.0
	rejected(Model.predict(model, prefix), "symbol", "integral float is not an alphabet integer")
	prefix[0] = 0
	prefix.resize(Model.MAX_LENGTH + 1)
	prefix.fill(0)
	rejected(Model.predict(model, prefix), "sequence_limit", "public prediction enforces full history bound")
	rejected(Model.generate(model, prefix, 12, 17, "max", machine), "sequence_limit", "seed limit precedes output-bound rejection")
	rejected(Codec.encode(prefix, model, machine), "sequence_limit", "encoder enforces complete source bound")
	prefix.resize(Model.MAX_LENGTH)
	check(Model.predict(model, prefix).ok, "public prediction accepts exactly the declared history limit")
	var mutations: Array[Dictionary] = []
	var bad: Dictionary = model.duplicate(true)
	bad.rows[0].counts[0] = -1
	mutations.append({"model":bad, "error":"count"})
	bad = model.duplicate(true)
	bad.examples[0][0] = (int(bad.examples[0][0]) + 1) % 4
	mutations.append({"model":bad, "error":"source_digest"})
	bad = model.duplicate(true)
	bad.rows[0].counts[0] = 1.0
	mutations.append({"model":bad, "error":"count"})
	bad = model.duplicate(true)
	bad.future_field = true
	mutations.append({"model":bad, "error":"model_field"})
	bad = model.duplicate(true)
	bad.parent = Model.identity(model)
	mutations.append({"model":bad, "error":"model_parent_self"})
	for mutation: Dictionary in mutations:
		rejected(Model.predict(mutation.model, [0,1]), mutation.error, "predict revalidates changed model")
		rejected(Model.generate(mutation.model, [0,1], 32, 17, "max", machine), mutation.error, "generate revalidates changed model")
		rejected(Codec.encode([0,1,0,2], mutation.model, machine), mutation.error, "predictive encode revalidates changed model")
		check(Codec.encode([0,1], mutation.model, machine, "raw").ok, "RAW remains independent of unused predictive model")
	var bad_model: Dictionary = mutations[0].model
	rejected(Model.predict(bad_model, [9]), "count", "predict preserves model-before-prefix error precedence")
	rejected(Model.generate(bad_model, [9], 32, 17, "max", machine), "count", "generate preserves model-before-seed precedence")
	rejected(Codec.encode([9], bad_model, machine), "symbol", "encode preserves source-before-model precedence")
	rejected(Codec.encode([9], bad_model, machine, "unknown"), "codec", "unknown codec preserves existing error precedence")
	var wrong_machine: Dictionary = machine.duplicate(true)
	wrong_machine.cache_rows = 1.0
	rejected(Codec.decode(PackedByteArray(), wrong_machine), "machine_schema", "receiver validates machine before packet")
	check(Model.predict(model, [0,1]).ok and Model.generate(model, [0,1], 32, 17, "max", machine).ok,
		"failed caller inputs do not poison subsequent valid operations")


func ownership_and_memory(model: Dictionary, machine: Dictionary) -> void:
	var initial: Array = [0,1]
	var first: Dictionary = Model.generate(model, initial, 64, 71, "weighted", machine)
	check(first.ok, "ownership fixture generates")
	if not first.ok: return
	var frozen: PackedByteArray = var_to_bytes(first)
	var changed: Dictionary = model.duplicate(true)
	changed.rows[0].counts[0] += 1
	check(Model.validate(changed).is_empty(), "different valid model is not silently rejected")
	var second: Dictionary = Model.generate(changed, [2,3], 65, 72, "weighted", machine)
	check(second.ok and second.model_id != first.model_id, "later valid model gets fresh canonical identity")
	if second.ok:
		second.recipe.model.rows[0].counts[0] += 1
		second.events[0].model_id = "edited returned observation"
	initial[0] = 3
	check(var_to_bytes(first) == frozen, "later runs and returned/input edits cannot mutate retained complete result")
	var prefix: Array = [0,1]
	var untouched: PackedByteArray = var_to_bytes([model, prefix])
	var decision: Dictionary = Model.predict(model, prefix)
	decision.counts[0] += 1
	decision.context.append(3)
	for event: Dictionary in decision.events:
		if event.has("context"): event.context.append(3)
	check(var_to_bytes([model, prefix]) == untouched, "public prediction results own contexts/counts independently")
	var bounded: Dictionary = machine.duplicate(true)
	bounded.memory_bytes = int(first.cost.peak_bytes)
	var exact: Dictionary = Model.generate(model, [0,1], 64, 71, "weighted", bounded)
	check(exact.ok and same(exact.output, first.output) and same(exact.events, first.events) and exact.cost == first.cost,
		"exact modeled memory bound preserves full output/events/cost")
	bounded.memory_bytes -= 1
	var failed: Dictionary = Model.generate(model, [0,1], 64, 71, "weighted", bounded)
	rejected(failed, "memory_limit", "one byte below generation peak is rejected before kernel")
	check(failed.get("required_bytes") == first.cost.peak_bytes, "memory rejection retains exact required-byte evidence")


func reseal(packet: PackedByteArray) -> PackedByteArray:
	var body: PackedByteArray = packet.slice(0, packet.size() - Codec.CHECKSUM_BYTES)
	body.append_array(Model.digest(body))
	return body


func strict_receiver(model: Dictionary, machine: Dictionary) -> void:
	var source: Array = [3,3,0,1,0,2,3]
	var encoded: Dictionary = Codec.encode(source, model, machine)
	check(encoded.ok, "receiver boundary fixture encoded")
	if not encoded.ok: return
	var original: Dictionary = Codec.decode(encoded.packet, machine)
	check(original.ok and original.output == source, "original packet independently decodes")
	var damaged: PackedByteArray = encoded.packet.duplicate()
	damaged[-1] = damaged[-1] ^ 1
	rejected(Codec.decode(damaged, machine), "packet_integrity", "receiver still checks packet integrity")
	damaged = encoded.packet.duplicate()
	# The first canonical row is empty context, followed by four uint16 counts.
	for index: int in range(Codec.HEADER_BYTES + 41, Codec.HEADER_BYTES + 49):
		damaged[index] = 0
	rejected(Codec.decode(reseal(damaged), machine), "empty_row", "valid checksum cannot bypass carried-model validation")
	damaged = encoded.packet.duplicate()
	damaged[Codec.HEADER_BYTES + 5] = 3
	rejected(Codec.decode(reseal(damaged), machine), "model_header", "unknown carried context order remains rejected")
	var raw: Dictionary = Codec.encode([3], {}, machine, "raw")
	check(raw.ok, "RAW receiver fixture encoded without any external model")
	if raw.ok:
		damaged = raw.packet.duplicate()
		damaged[Codec.HEADER_BYTES] = damaged[Codec.HEADER_BYTES] | 1
		rejected(Codec.decode(reseal(damaged), machine), "packet_padding", "resealed unused bits are still rejected")
	var old_count: int = int(model.rows[0].counts[0])
	model.rows[0].counts[0] = -1
	check(same(original, Codec.decode(encoded.packet, machine)), "failed decodes and external model edits cannot change packet-only receiver")
	model.rows[0].counts[0] = old_count
	var exact_machine: Dictionary = machine.duplicate(true)
	exact_machine.memory_bytes = int(original.cost.peak_bytes)
	var exact: Dictionary = Codec.decode(encoded.packet, exact_machine)
	check(exact.ok and same(exact, original), "receiver accepts its exact modeled peak without changed evidence")
	exact_machine.memory_bytes -= 1
	rejected(Codec.decode(encoded.packet, exact_machine), "memory_limit", "receiver checks memory before trusted prediction loop")


func run() -> void:
	var machine: Dictionary = Model.default_machine()
	var examples: Array = [[0,1,0,2,0,1,0,2], [1,0,2,0,1,0,2,0]]
	var last_model: Dictionary = {}
	for order: int in 3:
		var learned: Dictionary = Model.learn(examples, order, machine)
		check(learned.ok, "actual order%d model learns" % order)
		if not learned.ok: continue
		bounded_predictions(learned.model, order)
		operation_evidence(learned.model, order, machine)
		last_model = learned.model
	var tied: Dictionary = Model.learn([[0], [1]], 0, machine)
	check(tied.ok and Model.predict(tied.model, [3]).symbol == 0, "equal counts retain smallest-symbol tie rule")
	var empty: Dictionary = Model.learn([[]], 2, machine)
	check(empty.ok, "valid empty-example model retains uniform fallback")
	if empty.ok:
		var uniform: Dictionary = Model.predict(empty.model, [3,2])
		check(uniform.ok and uniform.counts == [1,1,1,1] and uniform.symbol == 0 and uniform.fallback == 3,
			"no learned rows preserves all-order uniform fallback")
		check(same(uniform, Model._predict_validated(empty.model, [3,2,1], 2)), "uniform helper ignores unobserved suffix")
	if not last_model.is_empty():
		strict_public_boundaries(last_model, machine)
		ownership_and_memory(last_model, machine)
		strict_receiver(last_model, machine)
		for capacity: int in [0,1,21]:
			var cache_machine: Dictionary = machine.duplicate(true)
			cache_machine.cache_rows = capacity
			operation_evidence(last_model, 2, cache_machine)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "creation computation kernel %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
