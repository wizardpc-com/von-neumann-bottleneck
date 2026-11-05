extends SceneTree

const Circuit = preload("res://src/circuit/logic_circuit.gd")
const Component = preload("res://src/circuit/logic_component.gd")
const Simulator = preload("res://src/circuit/prologue_simulator.gd")
const Value = preload("res://src/circuit/digital_value.gd")
const Snapshot = preload("res://scripts/benchmarks/computation/snapshot.gd")

var simulator := Simulator.new()
var checks: int = 0
var failures: Array[String] = []
var run_entered: bool = false
var run_finished: bool = false


func _init() -> void:
	call_deferred("_run")


func _process(_delta: float) -> bool:
	if run_entered and not run_finished:
		push_error("Prologue failure-recovery test aborted before its final verdict.")
		quit(1)
	return false


func _run() -> void:
	run_entered = true
	_test_register_whole_and_incremental()
	_test_first_and_repeated_failures()
	_test_wrong_expectation_still_advances()
	_test_output_carried_latch(false)
	_test_output_carried_latch(true)
	_test_settled_latch_error_retains_carry()
	_test_post_commit_failure_keeps_storage()
	run_finished = true
	print(("PASS: " if failures.is_empty() else "FAIL: ")
		+ "prologue failure recovery checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_register_whole_and_incremental() -> void:
	var circuit: LogicCircuit = _register_circuit()
	var steps: Array[Dictionary] = [
		_register_step(3, 3, 1, 3),
		_register_step(5, 6, 1, 3),
		_register_step(0, 0, 0, 3),
	]
	var inputs_before: Variant = _snapshot(steps)
	var circuit_before: Variant = _snapshot(circuit)
	var whole: Dictionary = simulator.run_sequence(circuit, steps)
	_check_step_validity(whole, [true, false, true], "whole write/conflict/HOLD")
	_check(not bool(whole.passed), "A recovered sequence still records its earlier failed step.")
	var failed_result: PrologueSimulationResult = _result_at(whole, 1)
	if failed_result != null:
		_check_error(failed_result, &"circuit.error.short_circuit", "whole conflict")
		_check_word(failed_result.external_inputs.get(&"A"), 4, 5, "failed stimulus A")
		_check_word(failed_result.external_inputs.get(&"B"), 4, 6, "failed stimulus B")
		_check_word(failed_result.output_values.get("A_IN:o0"), 4, 5, "failed observed driver A")
		_check_word(failed_result.output_values.get("B_IN:o0"), 4, 6, "failed observed driver B")
		_check(failed_result.input_value(&"REG", 0, 4).is_conflict(),
			"The failed observation retains the actual conflicting register input.")
		_check(not failed_result.events.is_empty(), "The failed observation retains its actual events.")
	_check(_boundaries(whole, 1) == 0, "A pre-commit driver conflict emits no storage boundary.")
	_check(_boundaries(whole, 0) == 1 and _boundaries(whole, 2) == 1,
		"WRITE and recovered HOLD each retain the actual register boundary.")
	_check_register(whole, 3, "whole recovered storage")
	_check_final_word(whole, &"OUT", 4, 3, "whole recovered OUT")
	_check_valid_final_carry(whole, "whole recovered continuation")
	_check(_snapshot(whole) == _snapshot(simulator.run_sequence(circuit, steps)),
		"Repeating the recovery sequence preserves all captured fields and events.")

	var written: Dictionary = _one(circuit, steps[0])
	var written_before: Variant = _snapshot(written)
	var failed: Dictionary = _one(circuit, steps[1], written)
	_check_step_validity(failed, [false], "incremental conflict")
	_check(_same_values(failed.prior_outputs, written.prior_outputs),
		"Failure returns the last valid output map as continuation seed.")
	_check(failed.runtime_state == written.runtime_state,
		"A pre-commit conflict preserves the incoming stored register.")
	_check(_same_values(failed.initial_prior_outputs, written.prior_outputs),
		"The failure receipt retains its actual incoming continuation seed.")
	var failed_before: Variant = _snapshot(failed)
	var recovered: Dictionary = _one(circuit, steps[2], failed)
	_check(bool(recovered.passed), "Correcting both drivers recovers without resetting the register.")
	_check_register(recovered, 3, "incremental recovered storage")
	_check_final_word(recovered, &"OUT", 4, 3, "incremental recovered OUT")
	_check(recovered.runtime_state == whole.runtime_state
		and _same_values(recovered.prior_outputs, whole.prior_outputs),
		"Whole and incremental execution end with the same storage and continuation values.")
	_check(_snapshot(written) == written_before, "Later calls do not mutate the retained valid receipt.")
	_check(_snapshot(failed) == failed_before, "Recovery does not rewrite the retained failed observation.")
	_check(_snapshot(steps) == inputs_before and _snapshot(circuit) == circuit_before,
		"Recovery does not mutate authored steps or topology.")

	# Returned continuation, failed observation and other calls must not share
	# mutable DigitalValues or stored-state dictionaries.
	var recovered_before: Variant = _snapshot(recovered)
	var failed_carry: Dictionary = failed.prior_outputs
	var carry_a: DigitalValue = failed_carry.get("A_IN:o0")
	_check(carry_a != null, "The failed continuation retains the previous A driver.")
	if carry_a != null:
		carry_a.value = 15
	var retained_failure: PrologueSimulationResult = failed.final_result
	_check_word(retained_failure.output_values.get("A_IN:o0"), 4, 5,
		"Editing returned carry cannot overwrite the failed driver observation")
	var failed_registers: Dictionary = failed.runtime_state.get("registers", {})
	failed_registers[&"REG"] = 9
	_check(int((retained_failure.runtime_state.get("registers", {}) as Dictionary).get(&"REG", -1)) == 3,
		"Editing returned runtime state cannot overwrite the failed evaluation snapshot.")
	if not retained_failure.events.is_empty():
		retained_failure.events[0].value.value = 14
	_check(_snapshot(written) == written_before and _snapshot(recovered) == recovered_before,
		"Mutating one returned receipt leaves earlier and later retained receipts detached.")


func _test_first_and_repeated_failures() -> void:
	var circuit: LogicCircuit = _register_circuit()
	var first_bad: Dictionary = _register_step(5, 6, 1, 0)
	var second_bad: Dictionary = _register_step(9, 10, 1, 0)
	var first: Dictionary = _one(circuit, first_bad)
	_check_step_validity(first, [false], "first call fails")
	_check((first.prior_outputs as Dictionary).is_empty(),
		"Failure before any valid step retains the empty incoming output seed.")
	_check((first.runtime_state as Dictionary).is_empty(),
		"Failure before any valid step does not create or commit storage.")
	var first_before: Variant = _snapshot(first)
	var second: Dictionary = _one(circuit, second_bad, first)
	_check_step_validity(second, [false], "second call fails")
	_check((second.prior_outputs as Dictionary).is_empty(),
		"Repeated failure still retains the incoming empty seed.")
	var second_result: PrologueSimulationResult = _result_at(second, 0)
	if second_result != null:
		_check_word(second_result.external_inputs.get(&"A"), 4, 9, "new repeated-failure stimulus")
		_check_word(second_result.output_values.get("A_IN:o0"), 4, 9,
			"Repeated failure observes the new drivers, not the previous failed map")
	var write: Dictionary = _one(circuit, _register_step(3, 3, 1, 3), second)
	var hold: Dictionary = _one(circuit, _register_step(0, 0, 0, 3), write)
	_check(bool(write.passed) and bool(hold.passed),
		"A valid WRITE and HOLD recover after two failures with no earlier success.")
	_check_register(hold, 3, "storage after initial failures")
	_check(_snapshot(first) == first_before, "Subsequent attempts preserve the first failure receipt.")
	var steps: Array[Dictionary] = [
		first_bad, second_bad, _register_step(3, 3, 1, 3), _register_step(0, 0, 0, 3),
	]
	var whole: Dictionary = simulator.run_sequence(circuit, steps)
	_check_step_validity(whole, [false, false, true, true], "whole initial failures")
	_check(not bool(whole.passed), "Initial failures remain in the aggregate verdict after recovery.")
	_check(whole.runtime_state == hold.runtime_state
		and _same_values(whole.prior_outputs, hold.prior_outputs),
		"Initial repeated failures agree between whole and continued execution.")


func _test_wrong_expectation_still_advances() -> void:
	var circuit: LogicCircuit = _register_circuit()
	var initial: Dictionary = _one(circuit, _register_step(3, 3, 1, 3))
	var wrong: Dictionary = _one(circuit, _register_step(7, 7, 1, 9), initial)
	_check_step_validity(wrong, [true], "valid write with wrong expected answer")
	_check(not bool(wrong.passed) and not bool(wrong.steps[0].passed),
		"A wrong expected answer remains a failed comparison.")
	_check(not bool(wrong.steps[0].comparisons[0].passed),
		"The failed expected-answer comparison is retained.")
	_check_register(wrong, 7, "valid mismatching write commits actual data")
	_check_final_word(wrong, &"OUT", 4, 7, "valid mismatching write observation")
	_check_valid_final_carry(wrong, "comparison failure still advances continuation")
	_check_word(wrong.prior_outputs.get("A_IN:o0"), 4, 7, "actual write driver in continuation")
	var held: Dictionary = _one(circuit, _register_step(0, 0, 0, 7), wrong)
	_check(bool(held.passed), "The next HOLD sees a valid write even when its expected answer was wrong.")
	_check_register(held, 7, "held comparison-failed write")
	var steps: Array[Dictionary] = [_register_step(7, 7, 1, 9), _register_step(0, 0, 0, 7)]
	var whole: Dictionary = simulator.run_sequence(circuit, steps)
	_check_step_validity(whole, [true, true], "wrong expectation whole sequence")
	_check(not bool(whole.passed) and bool(whole.steps[1].passed),
		"Accumulated comparison failure neither clears storage nor blocks later success.")
	_check_valid_final_carry(whole, "aggregate comparison failure still advances continuation")


func _test_output_carried_latch(raw: bool) -> void:
	var label: String = "raw feedback latch" if raw else "sealed latch"
	var circuit: LogicCircuit = _latch_circuit(raw)
	var setup: Array[Dictionary] = [
		_latch_step(0, 1, 0, 0, 0),
		_latch_step(1, 0, 0, 0, 1),
	]
	var written: Dictionary = simulator.run_sequence(circuit, setup, raw)
	_check(bool(written.passed), label + " establishes Q=1 through real RESET then SET.")
	var written_before: Variant = _snapshot(written)
	var bad: Dictionary = _latch_step(0, 0, 5, 6, 1)
	var failed: Dictionary = _one(circuit, bad, written, raw)
	_check_step_validity(failed, [false], label + " independent guard conflict")
	var failed_result: PrologueSimulationResult = _result_at(failed, 0)
	if failed_result != null:
		_check_error(failed_result, &"circuit.error.short_circuit", label + " guard conflict")
	_check(_same_values(failed.prior_outputs, written.prior_outputs),
		label + " retains every last-valid output, including feedback memory.")
	_check(failed.runtime_state == written.runtime_state,
		label + " pre-commit conflict does not change runtime storage.")
	_check(_boundaries(failed, 0) == 0, label + " conflict emits no successful state boundary.")
	var failed_before: Variant = _snapshot(failed)
	var hold_step: Dictionary = _latch_step(0, 0, 0, 0, 1)
	var held: Dictionary = _one(circuit, hold_step, failed, raw)
	_check(bool(held.passed), label + " corrects the guard and HOLDs without resetting feedback.")
	_check_final_word(held, &"Q", 1, 1, label + " retained Q")
	_check_final_word(held, &"NQ", 1, 0, label + " retained NQ")
	_check(_boundaries(held, 0) == (2 if raw else 1),
		label + " recovered HOLD emits its real state boundaries.")
	_check(_snapshot(written) == written_before and _snapshot(failed) == failed_before,
		label + " later HOLD does not mutate either retained receipt.")
	var all_steps: Array[Dictionary] = setup.duplicate(true)
	all_steps.append(bad)
	all_steps.append(hold_step)
	var whole: Dictionary = simulator.run_sequence(circuit, all_steps, raw)
	_check_step_validity(whole, [true, true, false, true], label + " whole sequence")
	_check(not bool(whole.passed), label + " aggregate still exposes the guard failure.")
	_check(whole.runtime_state == held.runtime_state
		and _same_values(whole.prior_outputs, held.prior_outputs),
		label + " whole and incremental continuation agree.")


func _test_settled_latch_error_retains_carry() -> void:
	var circuit: LogicCircuit = _latch_circuit(false)
	var written: Dictionary = _one(circuit, _latch_step(1, 0, 0, 0, 1))
	var failed: Dictionary = _one(circuit, _latch_step(1, 1, 0, 0, 1), written)
	var result: PrologueSimulationResult = _result_at(failed, 0)
	if result != null:
		_check(result.settled and not result.is_valid(),
			"Stable SET=RESET=1 remains a settled but electrically invalid sealed latch.")
		_check_error(result, &"circuit.error.invalid_latch_state", "settled sealed-latch error")
		_check_word(result.external_inputs.get(&"R"), 1, 1, "invalid latch observation retains RESET")
	_check(_same_values(failed.prior_outputs, written.prior_outputs),
		"Settling alone cannot authorize publishing an invalid latch's output map.")
	_check(_boundaries(failed, 0) == 0, "A settled invalid latch emits no successful state boundary.")
	var held: Dictionary = _one(circuit, _latch_step(0, 0, 0, 0, 1), failed)
	_check(bool(held.passed), "The sealed latch can HOLD its last valid state after invalid SET/RESET.")
	_check_final_word(held, &"Q", 1, 1, "sealed latch after invalid SET/RESET")


func _test_post_commit_failure_keeps_storage() -> void:
	# This distinct path intentionally retains the existing nontransactional
	# storage contract: a valid pre-commit evaluation writes1, then the new
	# register output conflicts with a separate zero-valued guard driver.
	var circuit := Circuit.new()
	_add(circuit, &"D_IN", &"input", &"D")
	_add(circuit, &"LOAD_IN", &"input", &"LOAD")
	_add(circuit, &"GUARD_IN", &"input", &"GUARD")
	_add(circuit, &"REG", &"register1")
	_add(circuit, &"OUT", &"output", &"OUT")
	_add(circuit, &"GUARD_OUT", &"output", &"CHECK")
	_wire(circuit, &"D_IN", &"REG")
	_wire(circuit, &"LOAD_IN", &"REG", 1)
	_wire(circuit, &"REG", &"OUT")
	_wire(circuit, &"REG", &"GUARD_OUT")
	_wire(circuit, &"GUARD_IN", &"GUARD_OUT")
	var write_zero: Dictionary = {"inputs": {&"D": 0, &"LOAD": 1, &"GUARD": 0}, "expected": {&"OUT": 0}}
	var write_one: Dictionary = {"inputs": {&"D": 1, &"LOAD": 1, &"GUARD": 0}, "expected": {&"OUT": 1}}
	var hold_one: Dictionary = {"inputs": {&"D": 0, &"LOAD": 0, &"GUARD": 1}, "expected": {&"OUT": 1}}
	var written: Dictionary = _one(circuit, write_zero)
	_check(bool(written.passed), "The post-commit fixture begins with compatible zero-valued drivers.")
	var before: PrologueSimulationResult = simulator.evaluate(
		circuit, write_one.inputs, written.prior_outputs, written.runtime_state)
	_check(before.is_valid(), "The deliberate post-commit conflict is valid before storage changes.")
	var failed: Dictionary = _one(circuit, write_one, written)
	_check_step_validity(failed, [false], "post-commit conflict")
	_check_register(failed, 1, "post-commit failure does not roll storage back")
	_check(_boundaries(failed, 0) == 1, "The failed post-commit observation retains its completed write boundary.")
	_check(_same_values(failed.prior_outputs, written.prior_outputs),
		"Even post-commit failure retains the incoming last-valid output seed.")
	var result: PrologueSimulationResult = _result_at(failed, 0)
	if result != null:
		_check_error(result, &"circuit.error.short_circuit", "post-commit guard conflict")
		_check_word(result.output_values.get("REG:o0"), 1, 1, "failed observation contains committed register1")
		_check(int((result.runtime_state.get("registers", {}) as Dictionary).get(&"REG", -1)) == 1,
			"The failed post-commit evaluation records the actually committed storage.")
	var failed_before: Variant = _snapshot(failed)
	var held: Dictionary = _one(circuit, hold_one, failed)
	_check(bool(held.passed), "Correcting the guard recovers with committed storage rather than rollback.")
	_check_final_word(held, &"OUT", 1, 1, "post-commit recovery OUT")
	_check(_snapshot(failed) == failed_before, "Post-commit recovery leaves the failed receipt unchanged.")
	var steps: Array[Dictionary] = [write_zero, write_one, hold_one]
	var whole: Dictionary = simulator.run_sequence(circuit, steps)
	_check_step_validity(whole, [true, false, true], "whole post-commit sequence")
	_check(not bool(whole.passed) and whole.runtime_state == held.runtime_state,
		"Whole post-commit recovery preserves both the failure and final committed state.")


func _one(circuit: LogicCircuit, step: Dictionary, previous: Dictionary = {}, feedback: bool = false) -> Dictionary:
	var steps: Array[Dictionary] = [step]
	return simulator.run_sequence(circuit, steps, feedback,
		previous.get("runtime_state", {}), previous.get("prior_outputs", {}))


func _register_step(a: int, b: int, load_value: int, expected: int) -> Dictionary:
	return {"inputs": {&"A": a, &"B": b, &"LOAD": load_value}, "expected": {&"OUT": expected}}


func _latch_step(set_value: int, reset_value: int, a: int, b: int, q: int) -> Dictionary:
	return {"inputs": {&"S": set_value, &"R": reset_value, &"A": a, &"B": b},
		"expected": {&"Q": q, &"NQ": 1 - q}}


func _register_circuit() -> LogicCircuit:
	var circuit := Circuit.new()
	_add(circuit, &"A_IN", &"input", &"A", 4)
	_add(circuit, &"B_IN", &"input", &"B", 4)
	_add(circuit, &"LOAD_IN", &"input", &"LOAD")
	_add(circuit, &"REG", &"register4")
	_add(circuit, &"OUT", &"output", &"OUT", 4)
	_wire(circuit, &"A_IN", &"REG")
	_wire(circuit, &"B_IN", &"REG")
	_wire(circuit, &"LOAD_IN", &"REG", 1)
	_wire(circuit, &"REG", &"OUT")
	return circuit


func _latch_circuit(raw: bool) -> LogicCircuit:
	var circuit := Circuit.new()
	_add(circuit, &"S_IN", &"input", &"S")
	_add(circuit, &"R_IN", &"input", &"R")
	_add(circuit, &"Q_OUT", &"output", &"Q")
	_add(circuit, &"NQ_OUT", &"output", &"NQ")
	if raw:
		_add(circuit, &"NOR_Q", &"nor")
		_add(circuit, &"NOR_NQ", &"nor")
		_wire(circuit, &"R_IN", &"NOR_Q")
		_wire(circuit, &"NOR_NQ", &"NOR_Q", 1)
		_wire(circuit, &"S_IN", &"NOR_NQ")
		_wire(circuit, &"NOR_Q", &"NOR_NQ", 1)
		_wire(circuit, &"NOR_Q", &"Q_OUT")
		_wire(circuit, &"NOR_NQ", &"NQ_OUT")
	else:
		_add(circuit, &"LATCH", &"sr_latch")
		_wire(circuit, &"S_IN", &"LATCH")
		_wire(circuit, &"R_IN", &"LATCH", 1)
		_wire(circuit, &"LATCH", &"Q_OUT")
		_wire(circuit, &"LATCH", &"NQ_OUT", 0, 1)
	_add(circuit, &"A_IN", &"input", &"A", 4)
	_add(circuit, &"B_IN", &"input", &"B", 4)
	_add(circuit, &"GUARD_OUT", &"output", &"GUARD", 4)
	_wire(circuit, &"A_IN", &"GUARD_OUT")
	_wire(circuit, &"B_IN", &"GUARD_OUT")
	return circuit


func _add(circuit: LogicCircuit, id: StringName, kind: StringName, signal_name: StringName = &"", width: int = 1) -> void:
	var properties: Dictionary = {}
	if kind in [&"input", &"output"]:
		properties["width"] = width
	_check(circuit.add_component(Component.new(id, kind, String(id), signal_name,
		kind in [&"input", &"output"], [], [], [], [], properties)), "Add fixture component " + String(id))


func _wire(circuit: LogicCircuit, source: StringName, target: StringName, target_port: int = 0, source_port: int = 0) -> void:
	_check(circuit.connect_ports(source, source_port, target, target_port).is_empty(),
		"Connect fixture wire %s:%d -> %s:%d" % [source, source_port, target, target_port])


func _result_at(report: Dictionary, index: int) -> PrologueSimulationResult:
	var steps: Array = report.get("steps", [])
	if index < 0 or index >= steps.size():
		_check(false, "Missing result at sequence step " + str(index))
		return null
	var result: PrologueSimulationResult = steps[index].get("result") as PrologueSimulationResult
	_check(result != null, "Step " + str(index) + " retains its actual evaluation object.")
	return result


func _check_step_validity(report: Dictionary, expected: Array[bool], context: String) -> void:
	var steps: Array = report.get("steps", [])
	_check(steps.size() == expected.size(), context + ": exact step count.")
	for index: int in mini(steps.size(), expected.size()):
		var result: PrologueSimulationResult = _result_at(report, index)
		if result != null:
			_check(result.is_valid() == expected[index], context + ": electrical validity at step " + str(index))


func _check_error(result: PrologueSimulationResult, expected: StringName, context: String) -> void:
	_check(result.error_specs.size() == 1, context + ": exactly one electrical diagnostic.")
	if result.error_specs.size() == 1:
		_check(StringName(result.error_specs[0].get("key", &"")) == expected, context + ": exact diagnostic key.")


func _check_word(actual: Variant, width: int, value: int, context: String) -> void:
	_check(actual is DigitalValue, context + ": actual digital value exists.")
	if actual is DigitalValue:
		_check((actual as DigitalValue).equals(Value.known(width, value)), context + ": width/state/value match.")


func _check_final_word(report: Dictionary, output: StringName, width: int, value: int, context: String) -> void:
	var result: PrologueSimulationResult = report.get("final_result") as PrologueSimulationResult
	_check(result != null, context + ": final evaluation exists.")
	if result != null:
		_check_word(result.observed_values.get(output), width, value, context)


func _check_register(report: Dictionary, expected: int, context: String) -> void:
	var state: Dictionary = report.get("runtime_state", {})
	var registers: Dictionary = state.get("registers", {})
	_check(int(registers.get(&"REG", -1)) == expected, context + ": actual stored word.")


func _check_valid_final_carry(report: Dictionary, context: String) -> void:
	var result: PrologueSimulationResult = report.get("final_result") as PrologueSimulationResult
	_check(result != null and result.is_valid(), context + ": final electrical evaluation is valid.")
	if result != null:
		_check(_same_values(report.get("prior_outputs", {}), result.output_values),
			context + ": valid observed outputs become continuation.")


func _same_values(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for key: Variant in left:
		if not right.has(key) or not (left[key] is DigitalValue) or not (right[key] is DigitalValue):
			return false
		if not (left[key] as DigitalValue).equals(right[key] as DigitalValue):
			return false
	return true


func _boundaries(report: Dictionary, step_index: int) -> int:
	var count: int = 0
	for event: PrologueEvent in report.get("events", []):
		if event.kind == &"state_transition" and event.sequence_step == step_index:
			count += 1
	return count


func _snapshot(value: Variant) -> Variant:
	var frozen: Variant = Snapshot.freeze(value)
	_check(Snapshot.supported(frozen), "Retained evidence has a complete supported snapshot.")
	return frozen


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
