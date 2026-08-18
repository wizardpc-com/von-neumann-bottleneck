class_name ReusableHalfAdder
extends RefCounted

const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const HalfAdderTestBenchType = preload("res://src/circuit/half_adder_test_bench.gd")

var component_name: StringName = &"HalfAdder"
var input_ports: Array[StringName] = [&"A", &"B"]
var output_ports: Array[StringName] = [&"SUM", &"CARRY"]
var circuit_snapshot: LogicCircuit
var source_signature: String = ""


func _init(source_circuit: LogicCircuit = null) -> void:
	if source_circuit != null:
		circuit_snapshot = source_circuit.duplicate_circuit()
		source_signature = circuit_snapshot.canonical_signature()


func is_ready() -> bool:
	return circuit_snapshot != null and not source_signature.is_empty()


func evaluate(a: bool, b: bool) -> CircuitTrace:
	if not is_ready():
		return null
	var bench := HalfAdderTestBenchType.new()
	return bench.run_debug(circuit_snapshot, a, b)


func canonical_signature() -> String:
	return JSON.stringify({
		"component_name": String(component_name),
		"input_ports": input_ports.map(func(port: StringName) -> String: return String(port)),
		"output_ports": output_ports.map(func(port: StringName) -> String: return String(port)),
		"source_signature": source_signature,
	})
