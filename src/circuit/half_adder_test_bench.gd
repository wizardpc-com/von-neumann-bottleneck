class_name HalfAdderTestBench
extends RefCounted

const CircuitSimulatorType = preload("res://src/circuit/circuit_simulator.gd")
const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")

const OFFICIAL_CASES: Array[Dictionary] = [
	{"A": false, "B": false, "SUM": false, "CARRY": false},
	{"A": false, "B": true, "SUM": true, "CARRY": false},
	{"A": true, "B": false, "SUM": true, "CARRY": false},
	{"A": true, "B": true, "SUM": false, "CARRY": true},
]

var simulator := CircuitSimulatorType.new()


func run_debug(circuit: LogicCircuit, a: bool, b: bool) -> CircuitTrace:
	return simulator.evaluate(circuit, {&"A": a, &"B": b})


func run_official(circuit: LogicCircuit) -> Dictionary:
	var case_results: Array[Dictionary] = []
	var all_passed: bool = true
	for official_case: Dictionary in OFFICIAL_CASES:
		var trace: CircuitTrace = run_debug(circuit, bool(official_case["A"]), bool(official_case["B"]))
		var actual_sum: Variant = trace.outputs.get(&"SUM", null)
		var actual_carry: Variant = trace.outputs.get(&"CARRY", null)
		var case_passed: bool = trace.is_valid() and actual_sum != null and actual_carry != null \
			and bool(actual_sum) == bool(official_case["SUM"]) \
			and bool(actual_carry) == bool(official_case["CARRY"])
		all_passed = all_passed and case_passed
		case_results.append({
			"A": bool(official_case["A"]),
			"B": bool(official_case["B"]),
			"expected_sum": bool(official_case["SUM"]),
			"expected_carry": bool(official_case["CARRY"]),
			"actual_sum": actual_sum,
			"actual_carry": actual_carry,
			"passed": case_passed,
			"trace": trace,
		})
	return {"passed": all_passed, "cases": case_results}
