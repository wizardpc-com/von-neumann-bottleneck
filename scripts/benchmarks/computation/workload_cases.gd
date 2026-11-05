extends RefCounted
## Pure benchmark inputs and public model calls. No timing, files, UI or autoloads.
## The runner snapshots every result/property, including every original event.
const Representation = preload("res://experiments/representation/model.gd")
const Partition = preload("res://experiments/representation/plan_model.gd")
const Region = preload("res://experiments/representation_region/model.gd")
const Linear = preload("res://experiments/intelligent_workload/model.gd")
const Persistent = preload("res://experiments/intelligent_workload/state_model.gd")
const Prediction = preload("res://experiments/prediction/model.gd")
const AddressCatalog = preload("res://experiments/prediction/catalog.gd")
const Service = preload("res://experiments/service_plan/model.gd")
const StateReplay = preload("res://experiments/service_plan/state_replay.gd")
const Creation = preload("res://experiments/creation/model.gd")
const CreationCodec = preload("res://experiments/creation/codec.gd")
const CreationCatalog = preload("res://experiments/creation/catalog.gd")
const CreationSession = preload("res://experiments/creation/session.gd")
const Conditions = preload("res://experiments/creation/condition_examples.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")


static func cases() -> Array[Dictionary]:
	var cases_out: Array[Dictionary] = []
	cases_out.append(_case("representation_fixed", "representation",
		"Original uniform RAW/RLE storage and decoded-cache paths on public dense/sparse orders.",
		{"operation":"representation", "runs":[
			{"spec":Representation.scenario(1, 2), "config":{"codec":"raw", "block":16, "cache":2}},
			{"spec":Representation.scenario(2, 0), "config":{"codec":"rle", "block":16, "cache":2}},
			{"spec":Representation.scenario(2, 1), "config":{"codec":"rle", "block":4, "cache":1}}]}))
	var mixed: Array[Dictionary] = [
		{"start":0, "end":16, "codec":"rle"},
		{"start":16, "end":48, "codec":"raw"},
		{"start":48, "end":64, "codec":"rle"}]
	var quarters: Array[Dictionary] = []
	for index: int in 4:
		quarters.append({"start":index * 16, "end":(index + 1) * 16, "codec":"raw"})
	var revisit: Dictionary = Partition.orders(1)[0].duplicate(true)
	var addresses: Array[int] = []
	for repeat_index: int in 32:
		addresses.append_array([0, 16, 0, 48, 0, 16])
	revisit.addresses = addresses
	cases_out.append(_case("representation_partition_revisits", "representation",
		"Public 64-byte mixed scan plus a legal 192-access LRU/reload stress; four full traces.",
		{"operation":"partition", "orders":[Partition.orders(0)[0], revisit], "plans":[mixed, quarters]}))
	cases_out.append(_case("representation_online_clients", "representation_region",
		"Public prepare-once short read and eight independent cold scans, RAW and mixed plans.",
		{"operation":"region", "task":3, "orders":Region.orders(3), "plans":[
			Region.initial_plan(),
			[{"start":0, "end":8, "codec":"raw"}, {"start":8, "end":64, "codec":"rle"}]]}))
	cases_out.append(_case("linear_precision_batch", "intelligent_workload",
		"All 32 public samples with exact reload, 8-bit reuse/batch and coarse precision.",
		{"operation":"linear", "configs":[
			{"bits":32, "batch":1, "reuse":false},
			{"bits":8, "batch":8, "reuse":true},
			{"bits":2, "batch":4, "reuse":true}]}))
	cases_out.append(_case("persistent_context", "intelligent_workload",
		"24 ordered requests: dirty eviction/flush, paired quantization and resident exact states.",
		{"operation":"persistent", "configs":[
			{"state_bits":32, "weight_bits":32, "slots":1, "batch":1, "order":"round_robin", "reuse":true},
			{"state_bits":8, "weight_bits":8, "slots":2, "batch":2, "order":"paired", "reuse":false},
			{"state_bits":32, "weight_bits":32, "slots":4, "batch":1, "order":"round_robin", "reuse":true}]}))
	var long_addresses: Array[int] = []
	for index: int in 64:
		long_addresses.append((index % 16) * 4)
	cases_out.append(_case("address_prediction", "prediction",
		"Public Off/stride/pollution paths, queued fallback and a legal 64-demand stream.",
		{"operation":"prediction", "runs":[
			{"spec":AddressCatalog.scenario(0), "policy":_policy("off")},
			{"spec":AddressCatalog.scenario(0), "policy":_policy("stride")},
			{"spec":AddressCatalog.scenario(2), "policy":_policy("stride")},
			{"spec":AddressCatalog.scenario(1), "policy":_policy("two_stride", 2, 1, 2)},
			{"spec":{"name":"queued-fallback", "addresses":[0,8,4], "compute_gap":0, "cache_slots":2}, "policy":_policy("stride")},
			{"spec":{"name":"bounded-64-demands", "addresses":long_addresses, "compute_gap":0, "cache_slots":1}, "policy":_policy("stride")}]}))
	cases_out.append(_case("service_baseline_replay", "service_plan",
		"Public one-slot RAW64 baseline plus every recorded state-replay frame.",
		{"operation":"service_replay", "plan":Service.initial_plan()}))
	var lossless: Dictionary = Service.initial_plan()
	lossless.slots = 4
	lossless.representations = ["rle64", "rle64", "raw64", "raw64"]
	var approximate: Dictionary = Service.initial_plan()
	approximate.slots = 4
	approximate.representations = ["rle8", "rle8", "raw8", "raw8"]
	cases_out.append(_case("service_representations", "service_plan",
		"Legal exact grouped, mixed lossless, approximate plans and all four physical codecs.",
		{"operation":"service", "plans":[_grouped_service(), lossless, approximate]}))
	cases_out.append(_case("creation_public_transport", "creation",
		"Public 1536-symbol C3 source through packed RAW and predictive receiver-only restoration.",
		{"operation":"creation_transport", "examples":[CreationCatalog.sample(0)],
			"order":2, "source":CreationCatalog.source(0),
			"machine":Conditions.machine(1), "codecs":["raw", "predictive"]}))
	cases_out.append(_case("creation_generation_stress", "creation",
		"64/1024 max, 1024/4096 weighted feedback from a public varied training prefix.",
		{"operation":"creation_generate", "examples":[CreationCatalog.source(1).slice(0, 256)],
			"order":2, "machine":Creation.default_machine(), "initial":[0,1],
			"requests":[{"length":64, "seed":17, "sampler":"max"},
				{"length":1024, "seed":987, "sampler":"weighted"},
				{"length":1024, "seed":987, "sampler":"max"},
				{"length":4096, "seed":987, "sampler":"weighted"}]}))
	var profile: Dictionary = CreationSession.fresh()
	profile.draft.examples = [CreationCatalog.sample(5)]
	profile.draft.order = 2
	cases_out.append(_case("creation_committed_session", "creation",
		"Fresh in-memory C/P/G, failed early transitions, complete check-v2 and pure profile decode.",
		{"operation":"creation_session", "profile":profile,
			"source":CreationCatalog.source(2), "prediction_kind":"check-v2"}))
	var invalid_region: Dictionary = Region.orders(3)[0].duplicate(true)
	invalid_region.clients = 0
	var invalid_partition: Dictionary = Partition.orders(0)[0].duplicate(true)
	invalid_partition.addresses = [0,64]
	var invalid_service: Dictionary = Service.initial_plan()
	invalid_service.groups[0][0] = 1
	cases_out.append(_case("workload_rejections", "workload_boundaries",
		"Actual invalid input/resource/dependency paths and corrupted packet; no fabricated results.",
		{"operation":"rejections", "region_spec":invalid_region,
			"partition_spec":invalid_partition, "service_plan":invalid_service,
			"examples":[CreationCatalog.sample(0)], "machine":Creation.default_machine()}))
	return cases_out


static func run_case(spec: Dictionary) -> Variant:
	# JSON stores integer-valued numbers as floats. Rebuild fresh integer input
	# recursively; fractional values stay fractional and are never silently clamped.
	var input: Dictionary = _integer_input(spec.input)
	match str(input.operation):
		"representation":
			var runs: Array = []
			for run: Dictionary in input.runs:
				var source: Dictionary = _representation_spec(run.spec)
				runs.append(Representation.run(source, run.config.duplicate(true)))
			return runs
		"partition", "region":
			var results: Array = []
			for raw_plan: Array in input.plans:
				var plan: Array[Dictionary] = _plan(raw_plan)
				var traces: Array = []
				for raw_spec: Dictionary in input.orders:
					var source: Dictionary = _representation_spec(raw_spec)
					traces.append(Region.run(source, plan) if input.operation == "region" else Partition.run(source, plan))
				var result: Dictionary = {"plan":plan.duplicate(true), "traces":traces}
				if input.operation == "region":
					result["accepted"] = Region.meets(int(input.task), traces)
				results.append(result)
			return results
		"linear":
			var traces: Array = []
			for config: Dictionary in input.configs:
				traces.append(Linear.run(config.duplicate(true)))
			return traces
		"persistent":
			var traces: Array = []
			for config: Dictionary in input.configs:
				traces.append(Persistent.run(config.duplicate(true)))
			return traces
		"prediction":
			var traces: Array = []
			for run: Dictionary in input.runs:
				var source: Dictionary = run.spec.duplicate(true)
				source.addresses = _ints(source.addresses)
				traces.append(Prediction.run(source, run.policy.duplicate(true)))
			return traces
		"service_replay":
			var trace: RefCounted = Service.run(input.plan.duplicate(true))
			var events: Array = []
			for event: RefCounted in trace.events:
				events.append(event.to_dictionary())
			return {"trace":trace, "frames":StateReplay.build(events)}
		"service":
			var traces: Array = []
			for plan: Dictionary in input.plans:
				traces.append(Service.run(plan.duplicate(true)))
			var codecs: Array = []
			for representation: String in Service.REPRESENTATIONS:
				for stream: int in 4:
					var values: Array[float] = Service.initial(stream)
					for index: int in values.size():
						values[index] = Service.rounded(values[index], representation)
					var packet: PackedByteArray = Service.pack(values, representation)
					codecs.append({"representation":representation, "stream":stream,
						"input":values, "packet":packet, "record":Service.record(packet),
						"decoded":Service.unpack(packet, representation)})
			return {"traces":traces, "codecs":codecs}
		"creation_transport":
			var learned: Dictionary = Creation.learn(input.examples, int(input.order), input.machine)
			if not learned.ok:
				return {"learned":learned}
			var transports: Array = []
			for codec: String in input.codecs:
				transports.append(CreationCodec.run_transport(input.source, learned.model, input.machine, codec))
			return {"learned":learned, "transports":transports}
		"creation_generate":
			var learned: Dictionary = Creation.learn(input.examples, int(input.order), input.machine)
			if not learned.ok:
				return {"learned":learned}
			var generated: Array = []
			for request: Dictionary in input.requests:
				generated.append(Creation.generate(learned.model, input.initial,
					int(request.length), int(request.seed), str(request.sampler), input.machine))
			return {"learned":learned, "generated":generated}
		"creation_session":
			return _creation_session(input)
		"rejections":
			return _rejections(input)
	return {"adapter_error":"unknown_operation"}


static func _creation_session(input: Dictionary) -> Dictionary:
	# Constructing Session does not acquire a lease or access a profile. Never
	# call open/save/close here: this is a fresh in-memory state-machine workflow.
	var session := CreationSession.new()
	session.data = input.profile.duplicate(true)
	var steps: Array = []
	steps.append({"operation":"early_generate_mode", "result":session.set_mode("generate")})
	var trained: Dictionary = session.train()
	steps.append({"operation":"learn", "result":trained})
	if not trained.ok:
		return {"steps":steps, "final_state":session}
	steps.append({"operation":"transport", "result":session.transport(input.source, "predictive")})
	session.complete("C1_restore")
	steps.append({"operation":"predict_mode", "result":session.set_mode("predict")})
	var begun: Dictionary = session.begin_prediction(str(input.prediction_kind))
	steps.append({"operation":"begin_prediction", "result":begun})
	if not begun.ok:
		return {"steps":steps, "final_state":session}
	steps.append({"operation":"reveal_without_commit", "result":session.reveal_prediction()})
	for index: int in int(session.prediction.total):
		steps.append({"operation":"commit", "result":session.commit_prediction()})
		if index == 0:
			steps.append({"operation":"duplicate_commit", "result":session.commit_prediction()})
		steps.append({"operation":"reveal", "result":session.reveal_prediction()})
	session.complete("P1_commit")
	session.complete("P3_check")
	steps.append({"operation":"prediction_evidence", "result":session.prediction_evidence()})
	steps.append({"operation":"generate_mode", "result":session.set_mode("generate")})
	steps.append({"operation":"generate", "result":session.generate()})
	session.complete("G1_feedback")
	# Decode is a pure reader/validator, including its actual replays. Keep its
	# complete return and the full in-memory Session, not just a checksum or score.
	var decoded: Dictionary = CreationSession.decode(JSON.stringify(session.data))
	return {"steps":steps, "decoded_profile":decoded, "final_state":session}


static func _rejections(input: Dictionary) -> Dictionary:
	var learned: Dictionary = Creation.learn(input.examples, 2, input.machine)
	var outputs: Dictionary = {
		"region":Region.run(_representation_spec(input.region_spec), Region.initial_plan()),
		"partition":Partition.run(_representation_spec(input.partition_spec), Partition.initial_plan()),
		"linear":Linear.run({"batch":3}),
		"persistent":Persistent.run({"state_bits":32, "weight_bits":32, "slots":4, "batch":4}),
		"prediction":Prediction.run({"name":"unaligned", "addresses":[1],
			"compute_gap":8, "cache_slots":2}, _policy("off")),
		"service":Service.run(input.service_plan.duplicate(true)), "learned":learned}
	if not learned.ok:
		return outputs
	var encoded: Dictionary = CreationCodec.encode([0,1,0,2], learned.model, input.machine)
	outputs["encoded"] = encoded
	if encoded.ok:
		var damaged: PackedByteArray = encoded.packet.duplicate()
		damaged[damaged.size() - 1] = damaged[damaged.size() - 1] ^ 1
		outputs["damaged_packet"] = damaged
		outputs["decode_damaged"] = CreationCodec.decode(damaged, input.machine)
		outputs["decode_original"] = CreationCodec.decode(encoded.packet, input.machine)
	var limited: Dictionary = input.machine.duplicate(true)
	limited.memory_bytes = 64
	outputs["generation_memory"] = Creation.generate(learned.model, [0,1], 64, 17, "max", limited)
	outputs["generation_seed_only"] = Creation.generate(learned.model, [0,1], 2, 17, "max", input.machine)
	var invalid_model: Dictionary = learned.model.duplicate(true)
	invalid_model.rows[0].counts[0] = -1
	outputs["invalid_model"] = Creation.predict(invalid_model, [0,1])
	return outputs


static func validate_case(spec: Dictionary, result: Variant) -> Array[String]:
	# Untimed semantic checks reject a reproducible failure/empty workflow. Exact
	# result/cost/state/event parity remains the independent runner's responsibility.
	var errors: Array[String] = []
	var input: Dictionary = _integer_input(spec.input)
	match str(input.operation):
		"representation":
			var rows: Array = _array(result, input.runs.size(), errors, "runs")
			for index: int in mini(rows.size(), input.runs.size()):
				_representation_result(rows[index], input.runs[index].spec, 1, errors, "runs/%d" % index)
		"partition", "region":
			var rows: Array = _array(result, input.plans.size(), errors, "plans")
			for index: int in mini(rows.size(), input.plans.size()):
				var path: String = "plans/%d" % index
				var row: Dictionary = _dictionary(rows[index], errors, path)
				_expect(row.get("plan") == input.plans[index], errors, path + ": actual plan retained")
				var traces: Array = _array(row.get("traces"), input.orders.size(), errors, path + "/traces")
				for order: int in mini(traces.size(), input.orders.size()):
					var clients: int = int(input.orders[order].clients) if input.operation == "region" else 1
					_representation_result(traces[order], input.orders[order], clients, errors, path + "/%d" % order)
				if input.operation == "region":
					# Existing public task3 tests establish RAW fails both-goal
					# acceptance and the 0..8 RAW / 8..64 RLE plan succeeds.
					_expect(row.get("accepted") is bool and row.accepted == (index == 1),
						errors, path + ": public preparation/service acceptance")
		"linear":
			var traces: Array = _array(result, input.configs.size(), errors, "linear")
			for index: int in mini(traces.size(), input.configs.size()):
				var path: String = "linear/%d" % index
				var metrics: Dictionary = _successful_trace(traces[index], 32, "output", errors, path)
				if metrics.is_empty(): continue
				_expect(metrics.get("config") == input.configs[index], errors, path + ": actual config retained")
				_array(metrics.get("reference"), 32, errors, path + "/reference")
				if int(input.configs[index].bits) == 32:
					_expect(metrics.get("outputs") == metrics.get("reference"), errors, path + ": exact mode reference")
		"persistent":
			var traces: Array = _array(result, input.configs.size(), errors, "persistent")
			for index: int in mini(traces.size(), input.configs.size()):
				var path: String = "persistent/%d" % index
				var metrics: Dictionary = _state_result(traces[index], errors, path)
				if metrics.is_empty(): continue
				_expect(metrics.get("config") == input.configs[index], errors, path + ": actual config retained")
				_array(metrics.get("reference"), 24, errors, path + "/reference")
				_states(metrics.get("reference_states"), errors, path + "/reference_states")
				if int(input.configs[index].state_bits) == 32 and int(input.configs[index].weight_bits) == 32:
					_expect(metrics.get("outputs") == metrics.get("reference"), errors, path + ": exact scores")
					_expect(metrics.get("final_states") == metrics.get("reference_states"), errors, path + ": exact states")
		"prediction":
			var traces: Array = _array(result, input.runs.size(), errors, "prediction")
			for index: int in mini(traces.size(), input.runs.size()):
				var path: String = "prediction/%d" % index
				var addresses: Array = input.runs[index].spec.addresses
				var metrics: Dictionary = _successful_trace(traces[index], addresses.size(), "demand", errors, path)
				if metrics.is_empty(): continue
				var expected: Array[int] = []
				for address: int in addresses: expected.append(AddressCatalog.value_at(address))
				_expect(metrics.get("outputs") == expected, errors, path + ": every demanded value restored")
				_array(metrics.get("accesses"), addresses.size(), errors, path + "/accesses")
				_array(metrics.get("decisions"), addresses.size(), errors, path + "/decisions")
				_expect(_positive(metrics.get("baseline_cycles")), errors, path + ": actual Off baseline")
				_expect(_count(traces[index].events, "prediction") == addresses.size(), errors, path + ": every policy observation")
		"service_replay":
			var row: Dictionary = _dictionary(result, errors, "service_replay")
			var trace: Variant = row.get("trace")
			var metrics: Dictionary = _state_result(trace, errors, "service_replay/trace")
			if not metrics.is_empty():
				var frames: Array = _array(row.get("frames"), trace.events.size(), errors, "service_replay/frames")
				for index: int in frames.size():
					var frame: Dictionary = _dictionary(frames[index], errors, "frames/%d" % index)
					_expect(frame.get("source_index") == index, errors, "frames/%d: source index" % index)
					if index < trace.events.size():
						_expect(frame.get("event") == trace.events[index].to_dictionary(), errors, "frames/%d: original event" % index)
				if not frames.is_empty():
					var last: Dictionary = _dictionary(frames.back(), errors, "frames/final")
					_array(last.get("responses"), 24, errors, "frames/final/responses")
					_expect(last.get("state_read_bytes") == metrics.get("state_read_bytes"), errors, "frames: all state reads")
					_expect(last.get("state_write_bytes") == metrics.get("state_write_bytes"), errors, "frames: all state writes")
					var backing: Array = _array(last.get("backing"), 4, errors, "frames/final/backing")
					var states: Array = metrics.get("final_states", [])
					for stream: int in mini(backing.size(), states.size()):
						var cell: Dictionary = _dictionary(backing[stream], errors, "backing/%d" % stream)
						_expect(cell.get("state") == states[stream], errors, "backing/%d: restored final state" % stream)
		"service":
			var row: Dictionary = _dictionary(result, errors, "service")
			var traces: Array = _array(row.get("traces"), input.plans.size(), errors, "service/traces")
			for index: int in mini(traces.size(), input.plans.size()):
				var metrics: Dictionary = _state_result(traces[index], errors, "service/%d" % index)
				if not metrics.is_empty():
					_expect(metrics.get("plan") == input.plans[index], errors, "service/%d: actual plan retained" % index)
			var codecs: Array = _array(row.get("codecs"), Service.REPRESENTATIONS.size() * 4, errors, "service/codecs")
			for index: int in codecs.size():
				var path: String = "codecs/%d" % index
				var codec: Dictionary = _dictionary(codecs[index], errors, path)
				if index < Service.REPRESENTATIONS.size() * 4:
					_expect(codec.get("representation") == Service.REPRESENTATIONS[index / 4] and codec.get("stream") == index % 4,
						errors, path + ": intended codec and stream")
				var values: Array = _array(codec.get("input"), 8, errors, path + "/input")
				var decoded: Array = _array(codec.get("decoded"), 8, errors, path + "/decoded")
				_expect(decoded == values, errors, path + ": real byte roundtrip")
				var packet: Variant = codec.get("packet")
				if _expect(packet is PackedByteArray and not packet.is_empty(), errors, path + ": actual encoded bytes"):
					var record: Array = _array(codec.get("record"), packet.size() + 2, errors, path + "/record")
					if record.size() >= 2:
						_expect(record[0] + record[1] * 256 == packet.size() and record.slice(2) == Array(packet),
							errors, path + ": physical record length and payload")
		"creation_transport", "creation_generate":
			var row: Dictionary = _dictionary(result, errors, "creation")
			var learned: Dictionary = _dictionary(row.get("learned"), errors, "learned")
			_learning_result(learned, input.examples, int(input.order), input.machine, errors, "learned")
			if input.operation == "creation_transport":
				var transports: Array = _array(row.get("transports"), input.codecs.size(), errors, "transports")
				for index: int in mini(transports.size(), input.codecs.size()):
					_transport_result(transports[index], input.source, str(input.codecs[index]), input.machine, errors, "transport/%d" % index)
			else:
				var generated: Array = _array(row.get("generated"), input.requests.size(), errors, "generated")
				for index: int in mini(generated.size(), input.requests.size()):
					_generation_result(generated[index], input.initial, input.requests[index], input.machine, errors, "generated/%d" % index)
		"creation_session":
			_session_result(input, result, errors)
		"rejections":
			_rejection_results(input, result, errors)
		_:
			errors.append("Unknown workload operation: " + str(input.operation))
	return errors


static func _representation_result(value: Variant, spec: Dictionary, clients: int, errors: Array[String], path: String) -> void:
	var expected: Array[int] = []
	for client: int in clients:
		for address: int in spec.addresses: expected.append(int(spec.data[address]))
	var metrics: Dictionary = _successful_trace(value, expected.size(), "consume", errors, path)
	if metrics.is_empty(): return
	_expect(metrics.get("outputs") == expected, errors, path + ": independent ordered source values")
	_expect(value.result_value == value.expected_value, errors, path + ": complete exact result")
	if metrics.has("accesses"): _array(metrics.accesses, expected.size(), errors, path + "/accesses")
	if spec.has("clients"):
		var per_client: Array[int] = []
		per_client.resize(clients)
		for event: RefCounted in value.events:
			if event.kind != &"consume": continue
			var client: Variant = event.details.get("client")
			if _expect(client is int and client >= 0 and client < clients, errors, path + ": client event identity"):
				per_client[client] += 1
		for count: int in per_client:
			_expect(count == spec.addresses.size(), errors, path + ": every cold client completed")


static func _state_result(value: Variant, errors: Array[String], path: String) -> Dictionary:
	var metrics: Dictionary = _successful_trace(value, 24, "output", errors, path)
	if metrics.is_empty(): return metrics
	_states(metrics.get("final_states"), errors, path + "/final_states")
	var responses: Array = _array(metrics.get("response_cycles"), 24, errors, path + "/response_cycles")
	for response: Variant in responses:
		_expect(_positive(response) and response <= metrics.total_cycles, errors, path + ": real completed response")
	_expect(_count(value.events, "compute") == 24 and _count(value.events, "commit") == 24,
		errors, path + ": every request computed and committed")
	_expect(_count(value.events, "initial_store") == 1 and _count(value.events, "final_store") == 1,
		errors, path + ": initial and flushed final backing states")
	var seen: Dictionary = {}
	for event: RefCounted in value.events:
		if event.kind != &"output": continue
		var id: Variant = event.details.get("request_id")
		if not _expect(id is int and id >= 0 and id < 24 and not seen.has(id), errors, path + ": unique response identity"): continue
		seen[id] = true
		if metrics.outputs.size() == 24:
			_expect(event.details.get("score") == metrics.outputs[id], errors, path + ": response contains computed score")
	return metrics


static func _session_result(input: Dictionary, result: Variant, errors: Array[String]) -> void:
	var row: Dictionary = _dictionary(result, errors, "session")
	# Public check-v2 has 24 symbols, with two initially visible symbols.
	var count: int = 22
	var operations: Array[String] = ["early_generate_mode", "learn", "transport", "predict_mode", "begin_prediction", "reveal_without_commit"]
	for index: int in count:
		operations.append("commit")
		if index == 0: operations.append("duplicate_commit")
		operations.append("reveal")
	operations.append_array(["prediction_evidence", "generate_mode", "generate"])
	var steps: Array = _array(row.get("steps"), operations.size(), errors, "session/steps")
	var rejected: Dictionary = {"early_generate_mode":"predict_first", "reveal_without_commit":"commit_first", "duplicate_commit":"prediction_state"}
	var revealed: int = 0
	var generation: Dictionary = {}
	var draft: Dictionary = input.profile.draft
	for index: int in mini(steps.size(), operations.size()):
		var path: String = "session/steps/%d" % index
		var step: Dictionary = _dictionary(steps[index], errors, path)
		var operation: String = operations[index]
		_expect(step.get("operation") == operation, errors, path + ": intended transition")
		var outcome: Dictionary = _dictionary(step.get("result"), errors, path + "/result")
		if rejected.has(operation):
			_rejected(outcome, str(rejected[operation]), errors, path)
			continue
		if operation != "prediction_evidence" and not _ok(outcome, errors, path): continue
		match operation:
			"learn":
				_learning_result(outcome, draft.examples, int(draft.order), draft.machine, errors, path)
			"transport":
				_transport_result(outcome, input.source, "predictive", draft.machine, errors, path)
			"begin_prediction":
				var state: Dictionary = _dictionary(outcome.get("state"), errors, path + "/state")
				_expect(state.get("total") == count and state.get("kind") == input.prediction_kind,
					errors, path + ": complete public check selected")
			"commit":
				var events: Array = _array(outcome.get("events"), -1, errors, path + "/events")
				_expect(_count(events, "successor_select") == 1, errors, path + ": one committed prediction")
			"reveal":
				var evidence: Dictionary = _dictionary(outcome.get("row"), errors, path + "/row")
				_expect(evidence.get("index") == revealed + 2, errors, path + ": next causal reveal")
				revealed += 1
				_expect(outcome.get("finished") is bool and outcome.finished == (revealed == count), errors, path + ": finish only after final reveal")
			"prediction_evidence":
				_creation_evidence(outcome, draft.machine, errors, path)
				var events: Array = _array(outcome.get("events"), -1, errors, path + "/events")
				_expect(_count(events, "reveal") == count and _count(events, "successor_select") == count,
					errors, path + ": complete committed/revealed evidence")
			"generate":
				generation = outcome
				_generation_result(outcome, draft.initial, draft, draft.machine, errors, path)
	_expect(revealed == count, errors, "session: every reveal executed")
	var decoded: Dictionary = _dictionary(row.get("decoded_profile"), errors, "session/decoded_profile")
	_ok(decoded, errors, "session/decoded_profile")
	var state: Variant = row.get("final_state")
	if not _expect(state is CreationSession, errors, "session: actual final Session"): return
	_expect(state.path.is_empty() and state.lease == null and not state._readable_profile,
		errors, "session: in-memory workflow has no file lease")
	_expect(state.data.mode == "generate" and state.prediction.get("finished") == true,
		errors, "session: successful prediction unlocks generation")
	_expect(state.prediction.get("pending") == {}, errors, "session: no uncommitted final prediction")
	_array(state.prediction.get("rows"), count, errors, "session/final_rows")
	_array(state.prediction.get("prefix"), count + 2, errors, "session/final_prefix")
	_expect(state.data.seen_checks == ["check-v2"], errors, "session: exposed check tracked")
	_expect(state.data.supports.size() == 4, errors, "session: four actual completion receipts")
	for id: String in ["C1_restore", "P1_commit", "P3_check", "G1_feedback"]:
		_expect(state.data.supports.has(id), errors, "session: completion " + id)
	_expect(decoded.get("data") == state.data and decoded.get("task") == state.data.task,
		errors, "session: pure decode accepts and preserves complete profile")
	if not generation.is_empty():
		_expect(state.generated.get("output") == generation.get("output") and state.generated.get("recipe") == generation.get("recipe"),
			errors, "session: generated result retained")


static func _rejection_results(input: Dictionary, result: Variant, errors: Array[String]) -> void:
	var row: Dictionary = _dictionary(result, errors, "rejections")
	var contracts: Dictionary = {"region":"preparation_machine", "partition":"address", "linear":"config",
		"persistent":"scratch_limit", "prediction":"invalid_address", "service":"stream_dependency"}
	for key: String in contracts:
		var trace: Variant = row.get(key)
		if not _expect(trace is Trace, errors, key + ": actual rejected Trace"): continue
		_expect(not trace.passed and trace.metrics.get("error") == contracts[key], errors, key + ": intended rejection")
		_expect(trace.events.is_empty() and trace.metrics.get("total_cycles") == 0, errors, key + ": no executed trace")
		# Region currently retains some service metrics after preparation rejection.
		# Do not rewrite that documented baseline behavior in an adapter.
	var learned: Dictionary = _dictionary(row.get("learned"), errors, "rejections/learned")
	_learning_result(learned, input.examples, 2, input.machine, errors, "rejections/learned")
	var encoded: Dictionary = _dictionary(row.get("encoded"), errors, "rejections/encoded")
	if _ok(encoded, errors, "rejections/encoded"):
		_creation_evidence(encoded, input.machine, errors, "rejections/encoded")
		_expect(_count(encoded.get("events", []), "input_read") == 4, errors, "rejections: valid packet encoded first")
		var packet: Variant = encoded.get("packet")
		var damaged: Variant = row.get("damaged_packet")
		_expect(packet is PackedByteArray and damaged is PackedByteArray and packet.size() == damaged.size()
			and packet != damaged, errors, "rejections: actual packet corruption")
	_rejected(row.get("decode_damaged"), "packet_integrity", errors, "rejections/decode_damaged")
	_rejected(row.get("generation_memory"), "memory_limit", errors, "rejections/generation_memory")
	_rejected(row.get("generation_seed_only"), "generation_bounds", errors, "rejections/generation_seed_only")
	_rejected(row.get("invalid_model"), "count", errors, "rejections/invalid_model")
	var decoded: Dictionary = _dictionary(row.get("decode_original"), errors, "rejections/decode_original")
	if _ok(decoded, errors, "rejections/decode_original"):
		_creation_evidence(decoded, input.machine, errors, "rejections/decode_original")
		_expect(decoded.get("output") == [0,1,0,2], errors, "rejections: original packet still restores after damaged attempt")
		_expect(_count(decoded.get("events", []), "recovered_write") == 4, errors, "rejections: all original symbols recovered")


static func _learning_result(value: Dictionary, examples: Array, order: int, machine: Dictionary, errors: Array[String], path: String) -> void:
	if not _ok(value, errors, path): return
	_creation_evidence(value, machine, errors, path)
	var model: Dictionary = _dictionary(value.get("model"), errors, path + "/model")
	_expect(Creation.validate(model).is_empty(), errors, path + ": valid learned model")
	_expect(model.get("examples") == examples and model.get("order") == order, errors, path + ": intended training inputs")
	var samples: int = 0
	var updates: int = 0
	for example: Array in examples:
		samples += example.size()
		for index: int in example.size(): updates += mini(order, index) + 1
	var events: Array = _array(value.get("events"), -1, errors, path + "/events")
	_expect(_count(events, "sample_read") == samples and _count(events, "count_update") == updates,
		errors, path + ": all samples and context updates processed")
	_expect(_count(events, "model_write") == 1, errors, path + ": learned model emitted")


static func _transport_result(value: Variant, source: Array, codec: String, machine: Dictionary, errors: Array[String], path: String) -> void:
	var row: Dictionary = _dictionary(value, errors, path)
	if not _ok(row, errors, path): return
	_creation_evidence(row, machine, errors, path)
	_expect(row.get("lossless") is bool and row.lossless and row.get("output") == source, errors, path + ": exact source restored")
	var encoded: Dictionary = _dictionary(row.get("encode"), errors, path + "/encode")
	var decoded: Dictionary = _dictionary(row.get("decode"), errors, path + "/decode")
	if _ok(encoded, errors, path + "/encode"):
		_creation_evidence(encoded, machine, errors, path + "/encode")
	if _ok(decoded, errors, path + "/decode"):
		_creation_evidence(decoded, machine, errors, path + "/decode")
	_expect(decoded.get("output") == source, errors, path + ": receiver output complete")
	var packet: Variant = row.get("packet")
	_expect(packet is PackedByteArray and packet.size() >= CreationCodec.HEADER_BYTES + CreationCodec.CHECKSUM_BYTES
		and packet == encoded.get("packet"), errors, path + ": actual complete transmitted packet")
	var metrics: Dictionary = _dictionary(row.get("metrics"), errors, path + "/metrics")
	_expect(metrics.get("codec") == codec and metrics == encoded.get("metrics"), errors, path + ": intended codec metrics")
	var events: Array = _array(row.get("events"), -1, errors, path + "/events")
	_expect(_count(events, "input_read") == source.size() and _count(events, "recovered_write") == source.size(),
		errors, path + ": every source/read-back symbol")
	_expect(_count(events, "packet_transfer") == 1 and _count(events, "packet_validate") == 1,
		errors, path + ": packet delivered and validated")


static func _generation_result(value: Variant, initial: Array, request: Dictionary, machine: Dictionary, errors: Array[String], path: String) -> void:
	var row: Dictionary = _dictionary(value, errors, path)
	if not _ok(row, errors, path): return
	_creation_evidence(row, machine, errors, path)
	var output: Array = _array(row.get("output"), int(request.length), errors, path + "/output")
	_expect(output.slice(0, initial.size()) == initial and Creation.symbols_error(output).is_empty(),
		errors, path + ": valid complete feedback sequence with original seed")
	var recipe: Dictionary = _dictionary(row.get("recipe"), errors, path + "/recipe")
	for key: String in ["length", "seed", "sampler"]:
		_expect(recipe.get(key) == request[key], errors, path + ": exact requested " + key)
	_expect(recipe.get("initial") == initial and recipe.get("machine") == machine, errors, path + ": seed and machine recipe")
	var events: Array = _array(row.get("events"), -1, errors, path + "/events")
	var generated: int = int(request.length) - initial.size()
	_expect(_count(events, "seed_write") == initial.size() and _count(events, "feedback_write") == generated,
		errors, path + ": every seed and generated output written")
	_expect(_count(events, "successor_select") == generated, errors, path + ": every next-symbol prediction")
	var samples: int = generated if request.sampler == "weighted" else 0
	_expect(_count(events, "sample") == samples, errors, path + ": intended deterministic sampler")
	_expect(_count(events, "sample_draw") >= samples if samples > 0 else _count(events, "sample_draw") == 0,
		errors, path + ": actual PRNG draws only for weighted sampling")


static func _creation_evidence(value: Dictionary, machine: Dictionary, errors: Array[String], path: String) -> void:
	var events: Array = _array(value.get("events"), -1, errors, path + "/events")
	_expect(not events.is_empty(), errors, path + ": nonempty actual events")
	var cost: Dictionary = _dictionary(value.get("cost"), errors, path + "/cost")
	var sums: Dictionary = {"cycles":0, "ops":0, "bytes":0}
	for index: int in events.size():
		var event: Dictionary = _dictionary(events[index], errors, path + "/events/%d" % index)
		_expect(event.get("kind") is String and not event.kind.is_empty(), errors, path + ": event kind")
		for field: String in sums:
			var amount: Variant = event.get(field)
			if _expect(amount is int and amount >= 0, errors, path + ": nonnegative event " + field):
				sums[field] += amount
	for field: String in ["total_cycles", "cpu_ops", "transfer_bytes", "peak_bytes"]:
		_expect(cost.get(field) is int and cost[field] >= 0, errors, path + ": nonnegative cost " + field)
	_expect(cost.get("total_cycles") == sums.cycles and cost.get("cpu_ops") == sums.ops and cost.get("transfer_bytes") == sums.bytes,
		errors, path + ": complete events reconcile with cost")
	_expect(_positive(cost.get("total_cycles")) and _positive(cost.get("peak_bytes"))
		and cost.peak_bytes <= int(machine.memory_bytes), errors, path + ": real work within machine memory")


static func _successful_trace(value: Variant, output_count: int, output_kind: String, errors: Array[String], path: String) -> Dictionary:
	if not _expect(value is Trace, errors, path + ": actual SimulationTrace"): return {}
	var metrics: Dictionary = value.metrics
	if not _expect(value.passed and metrics.get("error") is String and metrics.error.is_empty(),
		errors, path + ": successful model execution"): return {}
	if not _expect(metrics.get("outputs") is Array, errors, path + ": output array"): return {}
	var outputs: Array = _array(metrics.outputs, output_count, errors, path + "/outputs")
	for output: Variant in outputs:
		_expect(_number(output), errors, path + ": finite output value")
	if not _expect(_positive(metrics.get("total_cycles")) and not value.events.is_empty(), errors, path + ": actual work and events"): return {}
	for event: Variant in value.events:
		if not _expect(event is Event and event.cycle >= 0 and event.duration >= 0, errors, path + ": valid original event"): return {}
	_expect(_count(value.events, output_kind) == output_count, errors, path + ": complete " + output_kind + " events")
	return metrics


static func _states(value: Variant, errors: Array[String], path: String) -> void:
	var states: Array = _array(value, 4, errors, path)
	for index: int in states.size():
		var state: Array = _array(states[index], 8, errors, path + "/%d" % index)
		for coordinate: Variant in state:
			_expect(_number(coordinate), errors, path + ": finite persisted coordinate")


static func _ok(value: Dictionary, errors: Array[String], path: String) -> bool:
	return _expect(value.get("ok") is bool and value.ok
		and (not value.has("error") or (value.error is String and value.error.is_empty())),
		errors, path + ": successful API outcome")


static func _rejected(value: Variant, error: String, errors: Array[String], path: String) -> void:
	var row: Dictionary = _dictionary(value, errors, path)
	_expect(row.get("ok") is bool and not row.ok and row.get("error") == error, errors, path + ": expected " + error)


static func _array(value: Variant, expected_size: int, errors: Array[String], path: String) -> Array:
	if not _expect(value is Array, errors, path + ": array result"): return []
	if expected_size >= 0:
		_expect(value.size() == expected_size, errors, path + ": expected %d entries" % expected_size)
	return value


static func _dictionary(value: Variant, errors: Array[String], path: String) -> Dictionary:
	if not _expect(value is Dictionary, errors, path + ": dictionary result"): return {}
	return value


static func _expect(condition: bool, errors: Array[String], message: String) -> bool:
	if not condition: errors.append(message)
	return condition


static func _count(events: Variant, kind: String) -> int:
	if not events is Array: return -1
	var count: int = 0
	for event: Variant in events:
		if event is Event and str(event.kind) == kind: count += 1
		elif event is Dictionary and event.get("kind") == kind: count += 1
	return count


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _positive(value: Variant) -> bool:
	return _number(value) and value > 0


static func _case(id: String, subsystem: String, description: String, input: Dictionary) -> Dictionary:
	return {"id":id, "subsystem":subsystem, "description":description, "input":input}


static func _policy(rule: String, confidence: int = 1, lookahead: int = 1, cooldown: int = 0) -> Dictionary:
	return {"rule":rule, "confidence":confidence, "lookahead":lookahead, "cooldown":cooldown}


static func _grouped_service() -> Dictionary:
	var plan: Dictionary = Service.initial_plan()
	plan.groups = []
	for stream: int in 4:
		for step: int in 6:
			plan.groups.append([stream * 6 + step])
	return plan


static func _ints(value: Array) -> Array[int]:
	var result: Array[int] = []
	for number: Variant in value:
		result.append(int(number))
	return result


static func _plan(value: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for block: Dictionary in value:
		result.append({"start":int(block.start), "end":int(block.end), "codec":str(block.codec)})
	return result


static func _representation_spec(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	result.data = _ints(value.data)
	result.addresses = _ints(value.addresses)
	return result


static func _integer_input(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floor(value) and abs(value) < 9007199254740992.0:
		return int(value)
	if value is Array:
		var result: Array = []
		for child: Variant in value:
			result.append(_integer_input(child))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[key] = _integer_input(value[key])
		return result
	return value
