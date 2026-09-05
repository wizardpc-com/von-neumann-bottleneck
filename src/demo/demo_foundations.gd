class_name DemoFoundations
extends RefCounted

const Circuit = preload("res://src/circuit/logic_circuit.gd")
const Component = preload("res://src/circuit/logic_component.gd")
const Simulator = preload("res://src/circuit/prologue_simulator.gd")
const VERSION := "demo-foundations-v1"
const STANDARD_SOURCE := "standard-digital-v1"

static func component(id: String, kind: String, width: int = 4) -> LogicComponent:
	return Component.new(StringName(id), StringName(kind), id, StringName(id), kind in ["input", "output"], [], [], [], [], {"width": width, "origin": "standard", "source": STANDARD_SOURCE})


static func initial(id: String, stage: int = 0, prior: Dictionary = {}) -> Dictionary:
	var circuit := Circuit.new()
	if not prior.is_empty():
		circuit = restore(prior)
		if circuit == null:
			circuit = Circuit.new()
	if id == "dp_select":
		for entry: Array in [["A", "input", 4], ["B", "input", 4], ["SEL", "input", 1], ["MUX", "mux2_word", 4], ["OUT", "output", 4]]:
			circuit.add_component(component(entry[0], entry[1], entry[2]))
	else:
		if circuit.components.is_empty():
			for entry: Array in [["DATA", "input", 4], ["LOAD", "input", 1], ["REG", "register4", 4], ["Q", "output", 4]]:
				circuit.add_component(component(entry[0], entry[1], entry[2]))
		if stage >= 1:
			for entry: Array in [["ADDR", "input", 1], ["WRITE", "input", 1], ["RAM", "ram2x4", 4], ["MEM", "output", 4]]:
				if not circuit.components.has(StringName(entry[0])):
					circuit.add_component(component(entry[0], entry[1], entry[2]))
		if stage == 2:
			circuit.add_component(component("SOURCE", "mux2_word"))
			circuit.add_component(component("READ", "input", 1))
			# The next task replaces the direct DATA route with a visible source
			# selector. The previous accepted stage remains an independent snapshot.
			for wire: LogicWire in circuit.wires.duplicate():
				if (wire.to_component == &"REG" and wire.to_port == 0) or (wire.to_component == &"RAM" and wire.to_port == 1):
					circuit.disconnect_ports(wire.from_component, wire.from_port, wire.to_component, wire.to_port)
	return snapshot(circuit)


static func snapshot(circuit: LogicCircuit) -> Dictionary:
	return {"circuit": JSON.parse_string(circuit.canonical_signature()), "provenance": STANDARD_SOURCE}


static func restore(design: Dictionary) -> LogicCircuit:
	if design.get("provenance", "") != STANDARD_SOURCE or not design.get("circuit") is Dictionary:
		return null
	var data: Dictionary = design["circuit"]
	if not data.get("components") is Array or not data.get("wires") is Array or data["components"].size() > 32 or data["wires"].size() > 100:
		return null
	var result := Circuit.new()
	for entry: Variant in data["components"]:
		if not entry is Dictionary:
			return null
		for field: String in ["id", "kind", "display_name", "signal_name"]:
			if not entry.get(field) is String:
				return null
		if not entry.get("fixed_terminal") is bool or not entry.get("properties") is Dictionary:
			return null
		for field: String in ["input_port_names", "output_port_names", "input_port_widths", "output_port_widths"]:
			if not entry.get(field) is Array or entry[field].size() > 8:
				return null
			for item: Variant in entry[field]:
				if field.ends_with("names") and not item is String:
					return null
				if field.ends_with("widths") and not _valid_width(item):
					return null
		if not _valid_width(entry["properties"].get("width")):
			return null
		var restored := Component.from_dictionary(entry)
		if restored == null or restored.properties.get("source", "") != STANDARD_SOURCE or result.components.has(restored.id):
			return null
		result.add_component(restored)
	for entry: Variant in data["wires"]:
		if not entry is Dictionary:
			return null
		if not entry.get("from_component") is String or not entry.get("to_component") is String:
			return null
		for field: String in ["from_port", "to_port"]:
			if not entry.get(field) is int and not entry.get(field) is float:
				return null
			if entry[field] != int(entry[field]):
				return null
		if not result.connect_ports(StringName(entry.get("from_component", "")), int(entry.get("from_port", -1)), StringName(entry.get("to_component", "")), int(entry.get("to_port", -1))).is_empty():
			return null
	return result


static func _valid_width(value: Variant) -> bool:
	return (value is int or value is float) and (value == 1 or value == 4)


static func supply_valid(id: String, stage: int, circuit: LogicCircuit) -> bool:
	if circuit == null or id not in ["dp_select", "dp_store"] or stage < 0 or stage > (2 if id == "dp_store" else 0):
		return false
	var expected := restore(initial(id, stage))
	if circuit.components.size() != expected.components.size():
		return false
	for key: StringName in expected.components:
		if not circuit.components.has(key) or circuit.components[key].to_dictionary() != expected.components[key].to_dictionary():
			return false
	return true


static func sequences(id: String, stage: int) -> Array[Array]:
	var examples: Array[Array] = []
	if id == "dp_select":
		for a: int in range(16):
			for b: int in range(16):
				for select: int in range(2):
					examples.append([{"inputs": {"A": a, "B": b, "SEL": select}, "expected": {"OUT": a if select == 0 else b}}])
	else:
		for value: int in [0, 1, 5, 10, 15]:
			var other := 15 - value
			if stage == 0:
				examples.append([
					{"inputs": {"DATA": value, "LOAD": 1}, "expected": {"Q": value}},
					{"inputs": {"DATA": other, "LOAD": 0}, "expected": {"Q": value}},
					{"inputs": {"DATA": other, "LOAD": 1}, "expected": {"Q": other}},
				])
			elif stage == 1:
				examples.append([
					_step(value, 1, 0, 1, 0, {"Q": value, "MEM": value}),
					_step(other, 0, 1, 1, 0, {"Q": value, "MEM": other}),
					_step(3, 0, 0, 0, 0, {"Q": value, "MEM": value}),
					_step(7, 0, 1, 0, 0, {"Q": value, "MEM": other}),
				])
			else:
				examples.append([
					_step(value, 1, 0, 0, 0, {"Q": value}),
					_step(0, 0, 0, 1, 0, {"Q": value, "MEM": value}),
					_step(other, 1, 1, 0, 0, {"Q": other}),
					_step(0, 0, 1, 1, 0, {"MEM": other}),
					_step(0, 1, 0, 0, 1, {"Q": value, "MEM": value}),
					_step(0, 1, 1, 0, 1, {"Q": other, "MEM": other}),
				])
	return examples


static func _step(data: int, load_value: int, address: int, write: int, read: int, expected: Dictionary) -> Dictionary:
	return {"inputs": {"DATA": data, "LOAD": load_value, "ADDR": address, "WRITE": write, "READ": read}, "expected": expected}


static func run(id: String, stage: int, design: Dictionary) -> Dictionary:
	var circuit := restore(design)
	if not supply_valid(id, stage, circuit):
		return {"valid": false, "error": "demo.error.supply"}
	var examples := sequences(id, stage)
	var passed := true
	var first_failure: Dictionary = {}
	var signatures: Array[String] = []
	var displayed: Dictionary = {}
	for example: Array in examples:
		var steps: Array[Dictionary] = []
		steps.assign(example)
		var result := Simulator.new().run_sequence(circuit, steps)
		signatures.append(String(result["canonical_signature"]).sha256_text())
		if displayed.is_empty():
			displayed = result
		if not result["passed"]:
			passed = false
			if first_failure.is_empty():
				first_failure = result
	var identity := JSON.stringify([VERSION, id, stage, examples, "zero-state"]).sha256_text()
	return {"valid": true, "passed": passed, "complete": passed, "task": id, "stage": stage, "design": design.duplicate(true), "identity": identity, "signature": JSON.stringify([identity, signatures]).sha256_text(), "case_count": examples.size(), "sequence": displayed if passed else first_failure}
