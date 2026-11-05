extends SceneTree
## Pure public-API rejection contracts. No scene, profile or completion writes.
## The valid compatibility corpus is captured separately against the old runtime.

const Region = preload("res://experiments/representation_region/model.gd")
const Base = preload("res://experiments/representation/plan_model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Snapshot = preload("res://scripts/benchmarks/computation/snapshot.gd")
const ZERO_METRICS: Array[String] = [
	"total_cycles", "request_cycles", "transfer_cycles", "decode_cycles",
	"consume_cycles", "stored_bytes", "traffic_bytes", "decoded_values",
	"decode_ops", "cache_hits", "cache_misses", "evictions", "overfetch_values",
	"peak_cache_bytes",
]
const EMPTY_METRICS: Array[String] = ["outputs", "expected", "blocks", "accesses"]

var checks: int = 0
var failures: Array[String] = []
var rejected_cases: int = 0
var delegated_cases: int = 0
var valid_cases: int = 0


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
	return ok


func _signature(value: Variant) -> String:
	return Snapshot.canonical(value)


func _mixed_plan() -> Array[Dictionary]:
	return [
		{"start":0, "end":8, "codec":"raw"},
		{"start":8, "end":64, "codec":"rle"},
	]


func _check_rejected(spec: Dictionary, plan: Array, label: String) -> void:
	rejected_cases += 1
	var inputs: String = _signature({"spec":spec, "plan":plan})
	# This establishes that the fixture reaches the preparation-specific branch;
	# an unrelated Base failure must not satisfy the desired negative control.
	var service: SimulationTrace = Base.run(spec, plan)
	if not check(service.passed, label + ": actual Base service is otherwise legal"):
		return
	var trace: SimulationTrace = Region.run(spec, plan)
	check(not trace.passed and trace.test_name == "representation-region-v1"
		and trace.metrics.get("error") == "preparation_machine",
		label + ": exact failed Region identity and rejection reason")

	var metric_keys: Array[String] = ZERO_METRICS.duplicate()
	metric_keys.append_array(EMPTY_METRICS)
	metric_keys.append_array(["error", "spec", "plan"])
	check(trace.metrics.size() == metric_keys.size()
		and metric_keys.all(func(key: String) -> bool: return trace.metrics.has(key)),
		label + ": rejected metric key set stays complete and unchanged")

	var residual: Array[String] = []
	for key: String in ZERO_METRICS:
		var value: Variant = trace.metrics.get(key)
		if not value is int or value != 0:
			residual.append("%s=%s" % [key, str(value)])
	check(residual.is_empty(), label + ": no residual execution or storage metrics: "
		+ ", ".join(residual))
	var retained: Array[String] = []
	for key: String in EMPTY_METRICS:
		var value: Variant = trace.metrics.get(key)
		if not value is Array or not value.is_empty():
			retained.append(key)
	check(retained.is_empty(), label + ": no computed output, codec or cache rows: "
		+ ", ".join(retained))
	check(trace.events.is_empty() and trace.result_value == 0 and trace.expected_value == 0,
		label + ": no events or completed scalar result")

	var frozen: Dictionary = Snapshot.freeze(trace)
	var defaults: Dictionary = Snapshot.freeze(Trace.new())
	var actual_fields: Dictionary = frozen.fields.duplicate(true)
	var default_fields: Dictionary = defaults.fields.duplicate(true)
	actual_fields.erase("metrics")
	actual_fields.erase("test_name")
	default_fields.erase("metrics")
	default_fields.erase("test_name")
	check(frozen["@script"] == defaults["@script"] and actual_fields == default_fields,
		label + ": every remaining typed Trace field retains its fresh default")
	check(_signature({"spec":trace.metrics.get("spec"), "plan":trace.metrics.get("plan")}) == inputs,
		label + ": submitted provenance preserves complete values and types")
	check(_signature({"spec":spec, "plan":plan}) == inputs,
		label + ": the call does not mutate its submitted inputs")
	check(Snapshot.supported(frozen), label + ": complete rejected evidence is supported")
	var repeated: SimulationTrace = Region.run(spec, plan)
	check(_signature(trace) == _signature(repeated),
		label + ": fresh repetition preserves every typed result field")

	var completion_denied: bool = true
	for task: int in 5:
		var evidence: Array = []
		for order: Dictionary in Region.orders(task):
			evidence.append(trace)
		if Region.meets(task, evidence):
			completion_denied = false
	check(completion_denied, label + ": no task accepts rejected evidence")


func _invalid_parameters() -> void:
	# No JSON normalizer: float1.0 must remain a rejected float, not become int1.
	var invalid: Dictionary = {
		"online":[null, -1, 0, 1, 1.0, "true", [], {"nested":[1, {"value":"x"}]}],
		"clients":[null, -1, 0, 9, 1.0, 1.5, "1", true, [], {"nested":[1]}],
		"encoder":[null, -1, 0, 1.0, 1.5, "1", true, [], {"nested":[1]}],
	}
	for field: String in invalid:
		for online: bool in [false, true]:
			# Overwriting online with an invalid value makes the two starting
			# modes identical. Keep both modes for clients and encoder.
			if field == "online" and not online:
				continue
			var missing: Dictionary = Region.orders(3)[0].duplicate(true)
			missing.online = online
			missing.erase(field)
			_check_rejected(missing, Region.initial_plan(),
				"%s missing (online=%s)" % [field, online])
			var values: Array = invalid[field]
			for index: int in values.size():
				var spec: Dictionary = Region.orders(3)[0].duplicate(true)
				spec.online = online
				spec[field] = values[index]
				_check_rejected(spec, Region.initial_plan(),
					"%s case%d type%d (online=%s)" % [field, index, typeof(values[index]), online])


func _codecs_and_loads() -> void:
	var plans: Array = [
		Region.initial_plan(),
		[{"start":0, "end":64, "codec":"rle"}],
		_mixed_plan(),
	]
	for online: bool in [false, true]:
		for order: int in 2:
			for codec: int in plans.size():
				var spec: Dictionary = Region.orders(3)[order].duplicate(true)
				spec.online = online
				spec.encoder = 0
				_check_rejected(spec, plans[codec],
					"codec%d order%d encoder0 (online=%s, clients=%d)"
					% [codec, order, online, spec.clients])


func _base_rejection(spec: Dictionary, plan: Array, error: String, label: String) -> void:
	delegated_cases += 1
	# All wrapper parameters are also invalid. Base validation must still win
	# and its complete evidence must survive with only the Region identity.
	spec.online = "invalid"
	spec.clients = 0
	spec.encoder = 0
	var inputs: String = _signature({"spec":spec, "plan":plan})
	var expected: SimulationTrace = Base.run(spec, plan)
	if not check(not expected.passed and expected.metrics.get("error") == error,
			label + ": the real Base rejection is " + error):
		return
	expected.test_name = Region.VERSION
	var expected_signature: String = _signature(expected)
	var actual: SimulationTrace = Region.run(spec, plan)
	check(_signature(actual) == expected_signature,
		label + ": Region preserves the entire delegated Base failure and priority")
	check(_signature(expected) == expected_signature
		and _signature({"spec":spec, "plan":plan}) == inputs,
		label + ": delegation mutates neither retained Base result nor input")
	check(_signature(Region.run(spec, plan)) == expected_signature,
		label + ": repeated compound failure stays exact")
	if label == "later scratch block":
		check(actual.metrics.stored_bytes == 12 and actual.metrics.blocks.is_empty(),
			"Existing partial directory accounting on Base scratch rejection remains unchanged")


func _base_precedence() -> void:
	var spec: Dictionary = Region.orders(3)[0].duplicate(true)
	spec.erase("data")
	_base_rejection(spec, Region.initial_plan(), "data_schema", "missing data")
	spec = Region.orders(3)[0].duplicate(true)
	spec.data[0] = 256
	_base_rejection(spec, Region.initial_plan(), "byte_range", "invalid source byte")
	_base_rejection(Region.orders(3)[0], [], "block_count", "empty plan")
	_base_rejection(Region.orders(3)[0], [null], "block_schema", "malformed plan entry")
	_base_rejection(Region.orders(3)[0],
		[{"start":0.0, "end":64, "codec":"raw"}], "integer_boundary", "fractional boundary type")
	_base_rejection(Region.orders(3)[0],
		[{"start":0, "end":64, "codec":"zip"}], "codec", "unknown codec")
	spec = Region.orders(3)[0].duplicate(true)
	spec.bandwidth = 0
	_base_rejection(spec, Region.initial_plan(), "machine", "invalid base bandwidth")
	spec = Region.orders(3)[0].duplicate(true)
	spec.bandwidth = 1.0
	_base_rejection(spec, Region.initial_plan(), "machine", "float base bandwidth")
	spec = Region.orders(3)[0].duplicate(true)
	spec.addresses = [0, 64]
	_base_rejection(spec, Region.initial_plan(), "address", "out-of-range address")
	spec = Region.orders(3)[0].duplicate(true)
	spec.addresses = [0, 1.0]
	_base_rejection(spec, Region.initial_plan(), "address", "float address")
	spec = Region.orders(3)[0].duplicate(true)
	spec.scratch_limit = 8
	_base_rejection(spec,
		[{"start":0, "end":8, "codec":"raw"}, {"start":8, "end":64, "codec":"raw"}],
		"scratch", "later scratch block")


func _detached_evidence() -> void:
	var spec: Dictionary = Region.orders(3)[0].duplicate(true)
	spec.clients = 0
	spec["context"] = {"nested":[1, {"value":"submitted"}]}
	var plan: Array[Dictionary] = _mixed_plan()
	var retained: SimulationTrace = Region.run(spec, plan)
	var retained_signature: String = _signature(retained)
	spec.data[0] = 3
	spec.addresses.append(63)
	spec.context.nested[1].value = "caller changed"
	plan[0].end = 7
	check(_signature(retained) == retained_signature,
		"Rejected provenance owns nested source bytes, requests, metadata and plan")

	var other_spec: Dictionary = Region.orders(3)[0].duplicate(true)
	other_spec.encoder = 0
	other_spec["context"] = {"nested":[1, {"value":"other"}]}
	var other_plan: Array[Dictionary] = _mixed_plan()
	var other_inputs: String = _signature({"spec":other_spec, "plan":other_plan})
	var other: SimulationTrace = Region.run(other_spec, other_plan)
	other.metrics.spec.data[0] = 9
	other.metrics.spec.addresses.append(63)
	other.metrics.spec.context.nested[1].value = "result changed"
	other.metrics.plan[0].codec = "rle"
	check(_signature({"spec":other_spec, "plan":other_plan}) == other_inputs,
		"Mutating returned rejected provenance cannot edit the caller's input")
	check(_signature(retained) == retained_signature,
		"Different rejected results do not share nested mutable evidence")

	var valid: SimulationTrace = Region.run(Region.orders(3)[1], _mixed_plan())
	if not check(valid.passed and not valid.events.is_empty(),
			"Detachment probe actually performs a later successful eight-client service"):
		return
	valid.metrics.spec.data[0] = 2
	valid.metrics.blocks[0].values[0] = 1
	valid.events[0].details["review_mutation"] = true
	check(_signature(retained) == retained_signature,
		"Later successful execution and result edits leave earlier rejection immutable")


func _accepted_boundaries() -> void:
	for online: bool in [false, true]:
		for clients: int in [1, 8]:
			for encoder: int in [1, 8, 65536]:
				valid_cases += 1
				var spec: Dictionary = Region.orders(3)[0].duplicate(true)
				spec.online = online
				spec.clients = clients
				spec.encoder = encoder
				var plan: Array[Dictionary] = _mixed_plan()
				var before: String = _signature({"spec":spec, "plan":plan})
				var trace: SimulationTrace = Region.run(spec, plan)
				var label: String = "valid online=%s clients=%d encoder=%d" % [online, clients, encoder]
				if not check(trace.passed and trace.metrics.get("error") == "", label + ": accepted"):
					continue
				var expected: Array[int] = []
				for client: int in clients:
					for address: int in spec.addresses:
						expected.append(spec.data[address])
				check(trace.metrics.outputs == expected and trace.metrics.expected == expected
					and trace.result_value == 7 * clients and trace.expected_value == 7 * clients,
					label + ": complete independently ordered requested values")
				var cycles: int = 0
				for event: RefCounted in trace.events:
					cycles += event.duration
				check(cycles == trace.metrics.total_cycles and cycles > 0,
					label + ": valid work remains fully counted")
				check(_signature(Region.run(spec, plan)) == _signature(trace)
					and _signature({"spec":spec, "plan":plan}) == before,
					label + ": complete typed repetition and immutable inputs")


func run() -> void:
	_invalid_parameters()
	_codecs_and_loads()
	_base_precedence()
	_detached_evidence()
	_accepted_boundaries()
	print(("PASS: " if failures.is_empty() else "FAIL: ")
		+ "representation region rejections %d checks / %d failures"
		% [checks, failures.size()]
		+ " (%d rejected, %d delegated, %d valid boundary cases)"
		% [rejected_cases, delegated_cases, valid_cases])
	quit(0 if failures.is_empty() else 1)
