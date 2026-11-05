extends RefCounted
## Deterministic public-API fixtures for Boolean and word/state circuit kernels.
## cases() freezes authored inputs; run_case() rebuilds every mutable object.

const Circuit = preload("res://src/circuit/logic_circuit.gd")
const Component = preload("res://src/circuit/logic_component.gd")
const Wire = preload("res://src/circuit/logic_wire.gd")
const BooleanSimulator = preload("res://src/circuit/circuit_simulator.gd")
const BooleanAnalyzer = preload("res://src/circuit/circuit_analyzer.gd")
const HalfAdderBench = preload("res://src/circuit/half_adder_test_bench.gd")
const PrologueSimulatorType = preload("res://src/circuit/prologue_simulator.gd")
const Value = preload("res://src/circuit/digital_value.gd")
const Catalog = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
const Reusable = preload("res://src/circuit/reusable_component.gd")


static func cases() -> Array[Dictionary]:
	var half_adder: LogicCircuit = _half_adder()
	var authored: Dictionary = _authored_fixtures(half_adder)
	var result: Array[Dictionary] = [
		_spec("circuit.boolean.official", "circuit.boolean",
			"Four official Half Adder cases; four active gates and an unused spare.",
			{"mode": "half_adder", "circuit": _encode_circuit(half_adder)}),
		_spec("circuit.boolean.stress", "circuit.boolean",
			"128 NOT gates, 64 zero-delay junctions and 32 observers; complete live state and trace.",
			{"mode": "boolean", "circuit": _encode_circuit(_stress_circuit(128, 64, 32)),
				"inputs": {"SOURCE": true}}),
		_spec("circuit.boolean.diagnostics", "circuit.boolean",
			"Equal/conflicting/missing drivers, cycle, duplicate wire, invalid endpoint/port and no observer.",
			{"mode": "group", "members": _boolean_diagnostics()}),
	]
	for level_id: String in ["full_adder", "alu", "latch", "register", "ram", "cpu", "load_store"]:
		var input: Dictionary = (authored[level_id] as Dictionary).duplicate(true)
		if level_id == "register":
			input["mode"] = "sequence_continuation"
		result.append(_spec("circuit.prologue." + level_id, "circuit.prologue",
			"Current authored %s sequence%s; complete results, state and events." % [
				level_id,
				" plus one-step continuation" if level_id == "register" else "",
			], input))
	result.append(_spec("circuit.prologue.stress", "circuit.prologue",
		"32 NOT gates, 32 zero-delay junctions and 16 observers; bounded fixed-point settling.",
		{"mode": "prologue", "circuit": _encode_circuit(_stress_circuit(32, 32, 16)),
			"inputs": {"SOURCE": 1}}))
	result.append(_spec("circuit.prologue.diagnostics", "circuit.prologue",
		"Width/duplicate/cycle/oscillation/timeout errors, latch boundaries, missing stimuli, state recovery and DigitalValue resolution.",
		{"mode": "group", "members": _prologue_diagnostics(authored)}))
	return result


static func run_case(spec: Dictionary) -> Variant:
	return _run_payload(spec.get("input", {}))


static func validate_case(spec: Dictionary, result: Variant) -> Array[String]:
	var issues: Array[String] = []
	_validate_payload(spec.get("input", {}), result, String(spec.get("id", "")), issues)
	return issues


static func _expect(condition: bool, message: String, issues: Array[String]) -> void:
	if not condition:
		issues.append(message)


static func _validate_payload(input: Dictionary, result: Variant,
		context: String, issues: Array[String]) -> void:
	var mode: String = String(input.get("mode", ""))
	if mode == "group":
		if not result is Dictionary or not result.get("members") is Array:
			issues.append(context + ": missing grouped results")
			return
		var members: Array = input.get("members", [])
		var actual: Array = result["members"]
		_expect(actual.size() == members.size(), context + ": incomplete group", issues)
		for index: int in mini(actual.size(), members.size()):
			var member: Dictionary = members[index]
			if not actual[index] is Dictionary:
				issues.append(context + ": malformed member")
				continue
			_expect(actual[index].get("name") == member["name"],
				context + ": member order/name changed", issues)
			_validate_payload(member, actual[index].get("result"),
				context + "/" + String(member["name"]), issues)
	elif mode == "half_adder":
		_validate_half_adder(result, context, issues)
	elif mode == "boolean":
		_validate_boolean(input, result, context, issues)
	elif mode == "prologue":
		_validate_prologue(input, result, context, issues)
	elif mode == "sequence":
		_validate_sequence(input, result, [], context, issues)
	elif mode == "sequence_continuation":
		_validate_continuation(input, result, context, issues)
	elif mode == "digital_values":
		_validate_digital_values(input, result, context, issues)
	else:
		issues.append(context + ": no outcome validator for mode " + mode)


static func _validate_errors(errors: Array, specs: Array, expected: String,
		context: String, issues: Array[String]) -> void:
	var keys: Array[String] = []
	for spec: Variant in specs:
		if not spec is Dictionary:
			issues.append(context + ": malformed structured error")
			continue
		keys.append(String(spec.get("key", "")))
	var wanted: Array[String] = []
	if not expected.is_empty(): wanted.append(expected)
	_expect(keys == wanted and errors.size() == wanted.size(),
		context + ": unexpected error contract " + str(keys), issues)


static func _validate_half_adder(result: Variant, context: String, issues: Array[String]) -> void:
	if not result is Dictionary or not result.get("cases") is Array:
		issues.append(context + ": missing official case results")
		return
	var cases_result: Array = result["cases"]
	_expect(result.get("passed") == true and cases_result.size() == 4,
		context + ": all four truth-table cases must pass", issues)
	for index: int in mini(cases_result.size(), 4):
		if not cases_result[index] is Dictionary:
			issues.append(context + ": malformed truth-table case")
			continue
		var item: Dictionary = cases_result[index]
		var a: bool = index >= 2
		var b: bool = index % 2 == 1
		var trace: Variant = item.get("trace")
		_expect(item.get("A") == a and item.get("B") == b
			and item.get("passed") == true
			and item.get("expected_sum") == (a != b) and item.get("actual_sum") == (a != b)
			and item.get("expected_carry") == (a and b) and item.get("actual_carry") == (a and b),
			context + ": incorrect truth-table output at " + str(index), issues)
		if not trace is CircuitTrace:
			issues.append(context + ": missing complete official trace")
			continue
		_validate_errors(trace.errors, trace.error_specs, "", context, issues)
		_expect(trace.outputs == {&"SUM": a != b, &"CARRY": a and b}
			and not trace.events.is_empty() and trace.metrics.get("gate_count") == 4,
			context + ": official case did not execute four active gates", issues)


static func _validate_boolean(input: Dictionary, result: Variant,
		context: String, issues: Array[String]) -> void:
	if not result is Dictionary or not result.get("live") is CircuitLiveState \
			or not result.get("trace") is CircuitTrace:
		issues.append(context + ": missing live analysis or complete trace")
		return
	var live: CircuitLiveState = result["live"]
	var trace: CircuitTrace = result["trace"]
	var name: String = String(input.get("name", ""))
	var expected_errors: Dictionary = {
		"conflict": "circuit.error.short_circuit", "missing": "circuit.error.input_missing",
		"cycle": "circuit.error.circular_dependency", "duplicate": "circuit.error.duplicate_wire",
		"endpoint": "circuit.error.wire_endpoint_missing", "port": "circuit.error.wire_port_invalid",
		"no_observer": "circuit.error.no_observer",
	}
	var expected: String = expected_errors.get(name, "")
	var live_error: String = "" if name in ["missing", "no_observer"] else expected
	_validate_errors(live.errors, live.error_specs, live_error, context + "/live", issues)
	_validate_errors(trace.errors, trace.error_specs, expected, context + "/trace", issues)
	_expect(live.is_valid() == live_error.is_empty() and trace.is_valid() == expected.is_empty(),
		context + ": validity differs from expected diagnostics", issues)
	if not expected.is_empty():
		_expect(trace.events.is_empty() and trace.outputs.is_empty(),
			context + ": rejected Boolean circuit produced successful work", issues)
		return
	var circuit: LogicCircuit = _decode_circuit(input["circuit"])
	var gates: int = 0
	var observers: int = 0
	for component: LogicComponent in circuit.components.values():
		if component.is_basic_gate():
			gates += 1
		if component.is_observer():
			observers += 1
			_expect(trace.outputs.get(component.signal_name) == true,
				context + ": observer failed to receive high", issues)
	_expect(trace.outputs.size() == observers and live.observed_states.size() == observers
		and live.evaluation_order.size() == circuit.components.size()
		and live.valid_wires.size() == circuit.wires.size()
		and live.wire_states.size() == circuit.wires.size()
		and trace.metrics.get("gate_count") == gates
		and trace.metrics.get("wire_count") == circuit.wires.size()
		and trace.events.size() >= gates + observers + circuit.wires.size(),
		context + ": declared circuit work was not fully executed", issues)


static func _validate_prologue(input: Dictionary, result: Variant,
		context: String, issues: Array[String]) -> void:
	if not result is PrologueSimulationResult:
		issues.append(context + ": missing complete prologue result")
		return
	var name: String = String(input.get("name", ""))
	var expected_errors: Dictionary = {
		"width": "circuit.connection.width_mismatch", "duplicate": "circuit.error.duplicate_wire",
		"conflict": "circuit.error.short_circuit", "cycle": "circuit.error.circular_dependency",
		"oscillation": "circuit.error.temporal_oscillation", "timeout": "circuit.error.temporal_timeout",
		"sealed_latch_invalid": "circuit.error.invalid_latch_state",
		"raw_latch_disallowed": "circuit.error.circular_dependency",
	}
	var expected: String = expected_errors.get(name, "")
	_validate_errors(result.errors, result.error_specs, expected, context, issues)
	_expect(result.is_valid() == expected.is_empty(), context + ": wrong prologue validity", issues)
	if not expected.is_empty():
		if name in ["oscillation", "timeout"]:
			_expect(not result.events.is_empty() and not result.output_values.is_empty(),
				context + ": temporal failure did not execute settling work", issues)
		return
	_expect(result.settled and result.settle_ticks > 0 and not result.events.is_empty(),
		context + ": successful evaluation omitted settling work", issues)
	var expected_outputs: Dictionary = {}
	if name == "missing_driver":
		# Current word-circuit contract resolves a known driver plus high-Z.
		expected_outputs = {&"OUT": 3}
	elif name == "raw_latch_both_high":
		# Raw NOR feedback currently settles here; only sealed SRLatch rejects S=R=1.
		expected_outputs = {&"Q": 0, &"NQ": 0}
	else:
		var circuit: LogicCircuit = _decode_circuit(input["circuit"])
		var gates: int = 0
		for component: LogicComponent in circuit.components.values():
			if component.is_basic_gate():
				gates += 1
			if component.is_observer():
				expected_outputs[component.signal_name] = 1
		_expect(result.settle_ticks > 1 and result.settle_ticks <= PrologueSimulatorType.MAX_SETTLE_TICKS
			and result.wire_values.size() == circuit.wires.size()
			and result.events.size() >= gates + expected_outputs.size(),
			context + ": bounded stress did not execute declared propagation", issues)
	_expect(result.observed_values.size() == expected_outputs.size(),
		context + ": wrong observer count", issues)
	for key: Variant in expected_outputs:
		var width: int = 4 if name == "missing_driver" else 1
		_expect_value(result.observed_values.get(key), width, int(expected_outputs[key]), 0,
			context + "/output/" + String(key), issues)


static func _validate_sequence(input: Dictionary, result: Variant, failed_steps: Array[int],
		context: String, issues: Array[String]) -> void:
	if not result is Dictionary or not result.get("steps") is Array \
			or not result.get("events") is Array:
		issues.append(context + ": missing complete sequence")
		return
	var authored: Array = input.get("steps", [])
	var steps: Array = result["steps"]
	_expect(not authored.is_empty() and steps.size() == authored.size()
		and result.get("passed") == failed_steps.is_empty(),
		context + ": sequence count or pass status is wrong", issues)
	_expect(not result["events"].is_empty() and result.get("runtime_state") is Dictionary
		and result.get("prior_outputs") is Dictionary,
		context + ": omitted events or final state", issues)
	var circuit: LogicCircuit = _decode_circuit(input["circuit"])
	var widths: Dictionary = {}
	var last_valid_outputs: Dictionary = result.get("initial_prior_outputs", {})
	var stateful: bool = bool(input.get("allow_feedback", false))
	for component: LogicComponent in circuit.components.values():
		if component.is_observer():
			widths[component.signal_name] = component.input_width(0)
		if component.kind in [&"sr_latch", &"register1", &"register4", &"ram2x4"]:
			stateful = true
	for index: int in mini(steps.size(), authored.size()):
		if not steps[index] is Dictionary or not steps[index].get("result") is PrologueSimulationResult:
			issues.append(context + ": missing result for step " + str(index))
			continue
		var item: Dictionary = steps[index]
		var value: PrologueSimulationResult = item["result"]
		if value.is_valid():
			last_valid_outputs = value.output_values
		var should_pass: bool = index not in failed_steps
		var step_context: String = context + "/step/" + str(index)
		_expect(item.get("index") == index and item.get("passed") == should_pass
			and value.is_valid() == should_pass,
			step_context + ": expected " + ("success" if should_pass else "deliberate failure"), issues)
		_validate_errors(value.errors, value.error_specs,
			"" if should_pass else "circuit.error.short_circuit", step_context, issues)
		var source: Dictionary = authored[index]
		_expect(item.get("inputs") == _named_integers(source.get("inputs", {}))
			and item.get("expected") == _named_integers(source.get("expected", {})),
			step_context + ": changed authored stimuli or expected values", issues)
		_expect(not value.events.is_empty(), step_context + ": omitted evaluation events", issues)
		if not should_pass:
			continue
		var comparisons: Variant = item.get("comparisons")
		var expected: Dictionary = source.get("expected", {})
		if not comparisons is Array or comparisons.size() != expected.size():
			issues.append(step_context + ": missing output comparisons")
		else:
			for comparison: Variant in comparisons:
				_expect(comparison is Dictionary and comparison.get("passed") == true,
					step_context + ": unsuccessful output comparison", issues)
		for key: Variant in expected:
			var output_name := StringName(key)
			_expect_value(value.observed_values.get(output_name), int(widths.get(output_name, 1)),
				int(expected[key]), 0, step_context + "/" + String(key), issues)
	if stateful:
		var boundaries: int = 0
		for event: Variant in result["events"]:
			if event is PrologueEvent and event.kind == &"state_transition":
				boundaries += 1
		_expect(boundaries >= authored.size() - failed_steps.size(),
			context + ": missing successful state boundaries", issues)
	if not steps.is_empty() and steps[-1] is Dictionary \
			and steps[-1].get("result") is PrologueSimulationResult:
		var last: PrologueSimulationResult = steps[-1]["result"]
		_expect(result.get("final_result") is PrologueSimulationResult
			and _same_step_result(last, result["final_result"])
			and _same_committed_state(result.get("runtime_state", {}), last.runtime_state)
			and _same_value_maps(result.get("prior_outputs", {}), last_valid_outputs),
			context + ": final observation/state or last-valid output carry is wrong", issues)

static func _same_committed_state(committed: Dictionary, evaluated: Dictionary) -> bool:
	# A graph with only output-carried latches has no post-commit evaluation.
	# Its first commit initializes these empty storage maps after the result.
	var normalized: Dictionary = evaluated.duplicate(true)
	for key: String in ["ram","registers","tiny_computers"]:
		if not normalized.has(key): normalized[key] = {}
	return committed == normalized


static func _validate_continuation(input: Dictionary, result: Variant,
		context: String, issues: Array[String]) -> void:
	if not result is Dictionary or not result.get("continued_steps") is Array:
		issues.append(context + ": missing continuation workflow")
		return
	# A failed stimulus must not commit storage; the next valid HOLD must recover.
	# Do not accept repeated stale-input errors as a successful recovery benchmark.
	var failed_steps: Array[int] = []
	if input.get("name") == "failed_step_state_recovery": failed_steps.append(1)
	var whole: Variant = result.get("whole_sequence")
	_validate_sequence(input, whole, failed_steps, context + "/whole", issues)
	var authored: Array = input.get("steps", [])
	var continued: Array = result["continued_steps"]
	_expect(continued.size() == authored.size(), context + ": incomplete continuation", issues)
	var prior_state: Dictionary = {}
	var prior_outputs: Dictionary = {}
	var continued_events: Array = []
	for index: int in mini(continued.size(), authored.size()):
		var one_input: Dictionary = input.duplicate(true)
		one_input["steps"] = [authored[index]]
		var one_failure: Array[int] = []
		if index in failed_steps: one_failure.append(0)
		var step_context: String = context + "/continued/" + str(index)
		var report: Variant = continued[index]
		_validate_sequence(one_input, report, one_failure, step_context, issues)
		if not report is Dictionary:
			continue
		_expect(report.get("initial_runtime_state") == prior_state
			and _same_value_maps(report.get("initial_prior_outputs", {}), prior_outputs),
			step_context + ": state handoff was not preserved", issues)
		if index in failed_steps:
			_expect(report.get("runtime_state") == prior_state
				and _same_value_maps(report.get("prior_outputs", {}), prior_outputs),
				step_context + ": failed pre-commit step changed storage or valid output carry", issues)
		if report.get("runtime_state") is Dictionary:
			prior_state = report["runtime_state"]
		if report.get("prior_outputs") is Dictionary:
			prior_outputs = report["prior_outputs"]
		if report.get("events") is Array:
			continued_events.append_array(report["events"])
		if whole is Dictionary and whole.get("steps") is Array and index < whole["steps"].size() \
				and report.get("steps") is Array and report["steps"].size() == 1 \
				and whole["steps"][index] is Dictionary and report["steps"][0] is Dictionary:
			_expect(_same_step_result(whole["steps"][index].get("result"), report["steps"][0].get("result")),
				step_context + ": incremental step changed computed state/events", issues)
	if whole is Dictionary:
		_expect(result.get("runtime_state") == prior_state and whole.get("runtime_state") == prior_state
			and _same_value_maps(result.get("prior_outputs", {}), prior_outputs)
			and _same_value_maps(whole.get("prior_outputs", {}), prior_outputs)
			and _same_events(whole.get("events", []), continued_events),
			context + ": continued sequence differs beyond time/step coordinates", issues)


static func _same_value_maps(left: Variant, right: Variant) -> bool:
	if not left is Dictionary or not right is Dictionary or left.size() != right.size():
		return false
	for key: Variant in left:
		if not left[key] is DigitalValue or not right.get(key) is DigitalValue \
				or not (left[key] as DigitalValue).equals(right[key]):
			return false
	return true


static func _same_events(left: Variant, right: Variant) -> bool:
	if not left is Array or not right is Array or left.size() != right.size():
		return false
	for index: int in left.size():
		if not left[index] is PrologueEvent or not right[index] is PrologueEvent:
			return false
		var before: Dictionary = left[index].to_dictionary()
		var after: Dictionary = right[index].to_dictionary()
		for field: String in ["tick", "visual_step", "sequence_step"]:
			before.erase(field)
			after.erase(field)
		if before != after:
			return false
	return true


static func _same_step_result(left: Variant, right: Variant) -> bool:
	if not left is PrologueSimulationResult or not right is PrologueSimulationResult:
		return false
	for field: String in ["external_inputs", "input_values", "output_values", "wire_values", "observed_values"]:
		if not _same_value_maps(left.get(field), right.get(field)):
			return false
	return left.topology_signature == right.topology_signature and left.runtime_state == right.runtime_state \
		and left.errors == right.errors and left.error_specs == right.error_specs \
		and left.settled == right.settled and left.settle_ticks == right.settle_ticks \
		and _same_events(left.events, right.events)


static func _expect_value(actual: Variant, width: int, value: int, state: int,
		context: String, issues: Array[String]) -> void:
	var mask: int = (1 << width) - 1
	_expect(actual is DigitalValue and actual.width == width and actual.state == state
		and actual.value == (value & mask if state == 0 else 0),
		context + ": incorrect word value, width or resolution state", issues)


static func _validate_digital_values(input: Dictionary, result: Variant,
		context: String, issues: Array[String]) -> void:
	if not result is Array:
		issues.append(context + ": missing DigitalValue outcomes")
		return
	var widths: Array = input.get("widths", [])
	var values: Array = input.get("values", [])
	_expect(result.size() == widths.size() * values.size(), context + ": incomplete value matrix", issues)
	for index: int in mini(result.size(), widths.size() * values.size()):
		if not result[index] is Dictionary:
			issues.append(context + ": malformed value outcome")
			continue
		var width: int = int(widths[index / values.size()])
		var value: int = int(values[index % values.size()])
		var item: Dictionary = result[index]
		_expect(item.get("width") == width and item.get("input") == value,
			context + ": reordered or changed value stimulus", issues)
		for key: String in ["known", "from_variant", "equal"]:
			_expect_value(item.get(key), width, value, 0, context + "/" + key, issues)
		_expect_value(item.get("empty"), width, 0, 0, context + "/empty", issues)
		_expect_value(item.get("high_z"), width, 0, 1, context + "/high_z", issues)
		for key: String in ["conflict", "invalid_width"]:
			_expect_value(item.get(key), width, 0, 2, context + "/" + key, issues)


static func _run_payload(input: Dictionary) -> Variant:
	var mode: String = String(input.get("mode", ""))
	if mode == "group":
		var members: Array[Dictionary] = []
		for raw_member: Variant in input.get("members", []):
			var member: Dictionary = raw_member
			members.append({"name": String(member["name"]), "result": _run_payload(member)})
		return {"members": members}
	if mode == "digital_values":
		return _digital_values(input)
	var circuit: LogicCircuit = _decode_circuit(input.get("circuit", {}))
	match mode:
		"half_adder":
			return HalfAdderBench.new().run_official(circuit)
		"boolean":
			var inputs: Dictionary[StringName, bool] = {}
			for key: Variant in input.get("inputs", {}):
				inputs[StringName(key)] = bool(input["inputs"][key])
			return {
				"live": BooleanAnalyzer.new().analyze(circuit, inputs),
				"trace": BooleanSimulator.new().evaluate(circuit, inputs),
			}
		"prologue":
			return PrologueSimulatorType.new().evaluate(
				circuit, _named_integers(input.get("inputs", {})), {}, {},
				bool(input.get("allow_feedback", false))
			)
		"sequence", "sequence_continuation":
			var steps: Array[Dictionary] = _decode_steps(input.get("steps", []))
			var allow_feedback: bool = bool(input.get("allow_feedback", false))
			var simulator := PrologueSimulatorType.new()
			var whole: Dictionary = simulator.run_sequence(circuit, steps, allow_feedback)
			if mode == "sequence":
				return whole
			var runtime_state: Dictionary = {}
			var prior_outputs: Dictionary = {}
			var reports: Array[Dictionary] = []
			for step: Dictionary in steps:
				var one_step: Array[Dictionary] = [step.duplicate(true)]
				var report: Dictionary = simulator.run_sequence(
					circuit, one_step, allow_feedback, runtime_state, prior_outputs
				)
				reports.append(report)
				runtime_state = report["runtime_state"]
				prior_outputs = report["prior_outputs"]
			return {
				"whole_sequence": whole, "continued_steps": reports,
				"runtime_state": runtime_state, "prior_outputs": prior_outputs,
			}
	return null


static func _spec(id: String, subsystem: String, description: String, input: Dictionary) -> Dictionary:
	return {"id": id, "subsystem": subsystem, "description": description, "input": input}


static func _encode_circuit(circuit: LogicCircuit) -> Dictionary:
	var components: Array[Dictionary] = []
	var ids: Array[StringName] = []
	for component_id: StringName in circuit.components:
		ids.append(component_id)
	ids.sort()
	for component_id: StringName in ids:
		components.append(circuit.components[component_id].to_dictionary().duplicate(true))
	var wires: Array[Dictionary] = []
	for wire: LogicWire in circuit.wires:
		wires.append(wire.to_dictionary())
	return {"components": components, "wires": wires}


static func _decode_circuit(data: Dictionary) -> LogicCircuit:
	var circuit := Circuit.new()
	for raw_component: Variant in data.get("components", []):
		# This public constructor restores typed ports and integral properties.
		circuit.add_component(Component.from_dictionary(raw_component))
	for raw_wire: Variant in data.get("wires", []):
		var wire: Dictionary = raw_wire
		# Preserve malformed fixture wires too: validation belongs to the kernel.
		circuit.wires.append(Wire.new(
			StringName(wire.get("from_component", "")), int(wire.get("from_port", 0)),
			StringName(wire.get("to_component", "")), int(wire.get("to_port", 0))
		))
	return circuit


static func _named_integers(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in source:
		result[StringName(key)] = int(source[key])
	return result


static func _decode_steps(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_step: Variant in source:
		var step: Dictionary = raw_step
		result.append({
			"inputs": _named_integers(step.get("inputs", {})),
			"expected": _named_integers(step.get("expected", {})),
			"label_key": StringName(step.get("label_key", "")),
		})
	return result


static func _encode_steps(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_step: Variant in source:
		var step: Dictionary = raw_step
		var inputs: Dictionary = {}
		var expected: Dictionary = {}
		for key: Variant in step.get("inputs", {}):
			inputs[String(key)] = int(step["inputs"][key])
		for key: Variant in step.get("expected", {}):
			expected[String(key)] = int(step["expected"][key])
		result.append({
			"inputs": inputs, "expected": expected,
			"label_key": String(step.get("label_key", "")),
		})
	return result


static func _authored_fixtures(half_adder: LogicCircuit) -> Dictionary:
	var catalog := Catalog.new()
	var library: Dictionary = {
		&"HalfAdder": Reusable.new(&"HalfAdder", &"half_adder", &"half_adder", half_adder),
	}
	var result: Dictionary = {}
	for level_id: StringName in [
		&"full_adder", &"alu", &"latch", &"register", &"ram", &"cpu", &"load_store",
	]:
		var definition: Dictionary = catalog.definition(level_id, library)
		var circuit: LogicCircuit = catalog.reference_circuit(level_id, library)
		result[String(level_id)] = {
			"mode": "sequence", "circuit": _encode_circuit(circuit),
			"steps": _encode_steps(definition.get("official_steps", [])),
			"allow_feedback": bool(definition.get("allow_feedback", false)),
		}
		var seal_name := StringName(definition.get("seal_name", &""))
		if seal_name.is_empty():
			continue
		var sealed := Reusable.new(
			seal_name, StringName(definition["seal_kind"]), level_id, circuit
		)
		library[seal_name] = sealed
		if level_id == &"alu" or level_id == &"register":
			var generated_name: StringName = &"ALU4" if level_id == &"alu" else &"Register4"
			var generated_kind: StringName = &"alu4" if level_id == &"alu" else &"register4"
			var provenance: Array[String] = [sealed.source_signature]
			library[generated_name] = Reusable.new(
				generated_name, generated_kind, level_id, null, provenance,
				{"auto_expanded_bits": 4}
			)
	return result


static func _add(circuit: LogicCircuit, id: StringName, kind: StringName,
		signal_name: StringName = &"", width: int = 1) -> void:
	circuit.add_component(Component.new(
		id, kind, String(id), signal_name, kind in [&"input", &"output"],
		[], [], [], [], {"width": width} if width != 1 else {}
	))


static func _wire(circuit: LogicCircuit, source: StringName, target: StringName,
		to_port: int = 0, from_port: int = 0) -> void:
	circuit.wires.append(Wire.new(source, from_port, target, to_port))


static func _half_adder() -> LogicCircuit:
	# Same four-gate topology and unused spare as test_circuit_simulation.
	var circuit := Circuit.new()
	_add(circuit, &"A_IN", &"input", &"A")
	_add(circuit, &"B_IN", &"input", &"B")
	_add(circuit, &"SUM_OUT", &"output", &"SUM")
	_add(circuit, &"CARRY_OUT", &"output", &"CARRY")
	for entry: Array in [
		[&"AND_CARRY", &"and"], [&"OR_SUM", &"or"], [&"NOT_CARRY", &"not"],
		[&"AND_SUM", &"and"], [&"SPARE_OR", &"or"],
	]:
		_add(circuit, entry[0], entry[1])
	_wire(circuit, &"A_IN", &"AND_CARRY")
	_wire(circuit, &"B_IN", &"AND_CARRY", 1)
	_wire(circuit, &"A_IN", &"OR_SUM")
	_wire(circuit, &"B_IN", &"OR_SUM", 1)
	_wire(circuit, &"AND_CARRY", &"NOT_CARRY")
	_wire(circuit, &"OR_SUM", &"AND_SUM")
	_wire(circuit, &"NOT_CARRY", &"AND_SUM", 1)
	_wire(circuit, &"AND_SUM", &"SUM_OUT")
	_wire(circuit, &"AND_CARRY", &"CARRY_OUT")
	return circuit


static func _stress_circuit(gates: int, junctions: int, observers: int) -> LogicCircuit:
	var circuit := Circuit.new()
	_add(circuit, &"SOURCE", &"input", &"SOURCE")
	var prior: StringName = &"SOURCE"
	for index: int in range(gates + junctions):
		var id := StringName("N%03d" % index)
		_add(circuit, id, &"not" if index < gates else &"junction")
		_wire(circuit, prior, id)
		prior = id
	for index: int in range(observers):
		# Sinks sort first, exercising the analyzer's full recursive path.
		var id := StringName("A_OUT%03d" % index)
		_add(circuit, id, &"output", id)
		_wire(circuit, prior, id)
	return circuit


static func _driver_circuit(width: int = 1) -> LogicCircuit:
	var circuit := Circuit.new()
	_add(circuit, &"A_IN", &"input", &"A", width)
	_add(circuit, &"B_IN", &"input", &"B", width)
	_add(circuit, &"OUT", &"output", &"OUT", width)
	_wire(circuit, &"A_IN", &"OUT")
	_wire(circuit, &"B_IN", &"OUT")
	return circuit


static func _boolean_diagnostics() -> Array[Dictionary]:
	var shared: Dictionary = _encode_circuit(_driver_circuit())
	var cycle := Circuit.new()
	_add(cycle, &"NOT_A", &"not")
	_add(cycle, &"NOT_B", &"not")
	_add(cycle, &"OUT", &"output", &"OUT")
	_wire(cycle, &"NOT_A", &"NOT_B")
	_wire(cycle, &"NOT_B", &"NOT_A")
	_wire(cycle, &"NOT_B", &"OUT")
	var duplicate: Dictionary = shared.duplicate(true)
	(duplicate["wires"] as Array).append(duplicate["wires"][0].duplicate(true))
	var endpoint: Dictionary = shared.duplicate(true)
	endpoint["wires"][0]["from_component"] = "MISSING"
	var port: Dictionary = shared.duplicate(true)
	port["wires"][0]["from_port"] = 7
	var no_observer := Circuit.new()
	_add(no_observer, &"UNUSED", &"not")
	return [
		{"name": "equal", "mode": "boolean", "circuit": shared, "inputs": {"A": true, "B": true}},
		{"name": "conflict", "mode": "boolean", "circuit": shared, "inputs": {"A": false, "B": true}},
		{"name": "missing", "mode": "boolean", "circuit": shared, "inputs": {"A": true}},
		{"name": "cycle", "mode": "boolean", "circuit": _encode_circuit(cycle), "inputs": {}},
		{"name": "duplicate", "mode": "boolean", "circuit": duplicate, "inputs": {"A": true, "B": true}},
		{"name": "endpoint", "mode": "boolean", "circuit": endpoint, "inputs": {"A": true, "B": true}},
		{"name": "port", "mode": "boolean", "circuit": port, "inputs": {"A": true, "B": true}},
		{"name": "no_observer", "mode": "boolean", "circuit": _encode_circuit(no_observer), "inputs": {}},
	]


static func _prologue_diagnostics(authored: Dictionary) -> Array[Dictionary]:
	var width_mismatch := Circuit.new()
	_add(width_mismatch, &"WORD", &"input", &"WORD", 4)
	_add(width_mismatch, &"OUT", &"output", &"OUT")
	_wire(width_mismatch, &"WORD", &"OUT")
	var shared: Dictionary = _encode_circuit(_driver_circuit(4))
	var duplicate: Dictionary = shared.duplicate(true)
	(duplicate["wires"] as Array).append(duplicate["wires"][0].duplicate(true))
	var oscillator := Circuit.new()
	_add(oscillator, &"NOT", &"not")
	_add(oscillator, &"OUT", &"output", &"OUT")
	_wire(oscillator, &"NOT", &"NOT")
	_wire(oscillator, &"NOT", &"OUT")
	var sealed_latch := Circuit.new()
	_add(sealed_latch, &"S_IN", &"input", &"S")
	_add(sealed_latch, &"R_IN", &"input", &"R")
	_add(sealed_latch, &"LATCH", &"sr_latch")
	_add(sealed_latch, &"OUT", &"output", &"OUT")
	_wire(sealed_latch, &"S_IN", &"LATCH")
	_wire(sealed_latch, &"R_IN", &"LATCH", 1)
	_wire(sealed_latch, &"LATCH", &"OUT")
	var register := Circuit.new()
	_add(register, &"A_IN", &"input", &"A", 4)
	_add(register, &"B_IN", &"input", &"B", 4)
	_add(register, &"LOAD_IN", &"input", &"LOAD")
	_add(register, &"REG", &"register4")
	_add(register, &"OUT", &"output", &"OUT", 4)
	_wire(register, &"A_IN", &"REG")
	_wire(register, &"B_IN", &"REG")
	_wire(register, &"LOAD_IN", &"REG", 1)
	_wire(register, &"REG", &"OUT")
	var raw_latch: Dictionary = authored["latch"]["circuit"]
	return [
		{"name": "width", "mode": "prologue", "circuit": _encode_circuit(width_mismatch), "inputs": {"WORD": 3}},
		{"name": "duplicate", "mode": "prologue", "circuit": duplicate, "inputs": {"A": 3, "B": 3}},
		{"name": "conflict", "mode": "prologue", "circuit": shared, "inputs": {"A": 3, "B": 12}},
		{"name": "missing_driver", "mode": "prologue", "circuit": shared, "inputs": {"A": 3}},
		{"name": "cycle", "mode": "prologue", "circuit": _encode_circuit(oscillator), "inputs": {}},
		{"name": "oscillation", "mode": "prologue", "circuit": _encode_circuit(oscillator),
			"inputs": {}, "allow_feedback": true},
		{"name": "timeout", "mode": "prologue", "circuit": _encode_circuit(_stress_circuit(65, 0, 1)),
			"inputs": {"SOURCE": 1}},
		{"name": "sealed_latch_invalid", "mode": "prologue",
			"circuit": _encode_circuit(sealed_latch), "inputs": {"S": 1, "R": 1}},
		{"name": "raw_latch_both_high", "mode": "prologue", "circuit": raw_latch,
			"inputs": {"S": 1, "R": 1}, "allow_feedback": true},
		{"name": "raw_latch_disallowed", "mode": "prologue", "circuit": raw_latch,
			"inputs": {"S": 0, "R": 1}},
		{"name": "failed_step_state_recovery", "mode": "sequence_continuation",
			"circuit": _encode_circuit(register), "steps": [
				{"inputs": {"A": 3, "B": 3, "LOAD": 1}, "expected": {"OUT": 3}},
				{"inputs": {"A": 5, "B": 6, "LOAD": 1}, "expected": {"OUT": 3}},
				{"inputs": {"A": 0, "B": 0, "LOAD": 0}, "expected": {"OUT": 3}},
			]},
		{"name": "digital_values", "mode": "digital_values", "widths": [1, 4, 32],
			"values": [-1, 0, 1, 15, 16, 4294967295]},
	]


static func _digital_values(input: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_width: Variant in input.get("widths", []):
		var width: int = int(raw_width)
		for raw_value: Variant in input.get("values", []):
			var value: int = int(raw_value)
			var known: DigitalValue = Value.known(width, value)
			var equal: Array[DigitalValue] = [known, known.duplicate_value(), Value.high_z(width)]
			var conflict: Array[DigitalValue] = [known, Value.known(width, value ^ 1)]
			var high_z: Array[DigitalValue] = [Value.high_z(width)]
			var invalid_width: Array[DigitalValue] = [Value.known(4 if width == 1 else 1, value)]
			var empty: Array[DigitalValue] = []
			result.append({
				"width": width, "input": value, "known": known,
				"from_variant": Value.from_variant(width, value),
				"equal": Value.resolve(equal, width), "conflict": Value.resolve(conflict, width),
				"high_z": Value.resolve(high_z, width), "empty": Value.resolve(empty, width),
				"invalid_width": Value.resolve(invalid_width, width),
			})
	return result
