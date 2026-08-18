class_name LogicCircuit
extends RefCounted

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicWireType = preload("res://src/circuit/logic_wire.gd")

var components: Dictionary[StringName, LogicComponent] = {}
var wires: Array[LogicWire] = []


func add_component(component: LogicComponent) -> bool:
	if component == null or component.id.is_empty() or components.has(component.id):
		return false
	components[component.id] = component
	return true


func get_component(component_id: StringName) -> LogicComponent:
	return components.get(component_id)


func remove_component(component_id: StringName) -> bool:
	if not components.has(component_id):
		return false
	for index: int in range(wires.size() - 1, -1, -1):
		var wire: LogicWire = wires[index]
		if wire.from_component == component_id or wire.to_component == component_id:
			wires.remove_at(index)
	components.erase(component_id)
	return true


func connection_error(
		from_component: StringName,
		from_port: int,
		to_component: StringName,
		to_port: int
	) -> String:
	return _diagnostic_fallback(connection_diagnostic(from_component, from_port, to_component, to_port))


func connection_diagnostic(
		from_component: StringName,
		from_port: int,
		to_component: StringName,
		to_port: int
	) -> Dictionary:
	var source: LogicComponent = components.get(from_component)
	var target: LogicComponent = components.get(to_component)
	if source == null or target == null:
		return _diagnostic(&"circuit.connection.endpoints_missing", [], "Both connection endpoints must exist.")
	if from_port < 0 or from_port >= source.output_count():
		return _diagnostic(&"circuit.connection.output_missing", [source.display_name, from_port], "%s has no output port %d.")
	if to_port < 0 or to_port >= target.input_count():
		return _diagnostic(&"circuit.connection.input_missing", [target.display_name, to_port], "%s has no input port %d.")
	var source_width: int = source.output_width(from_port)
	var target_width: int = target.input_width(to_port)
	if source_width != target_width:
		return _diagnostic(
			&"circuit.connection.width_mismatch",
			[source.display_name, source_width, target.display_name, target_width],
			"Width mismatch: %s outputs %d bit(s), but %s expects %d bit(s)."
		)
	for wire: LogicWire in wires:
		if wire.from_component == from_component and wire.from_port == from_port and wire.to_component == to_component and wire.to_port == to_port:
			return _diagnostic(&"circuit.connection.duplicate", [], "That wire already exists.")
	return {}


func connect_ports(
		from_component: StringName,
		from_port: int,
		to_component: StringName,
		to_port: int
	) -> String:
	return _diagnostic_fallback(connect_ports_detailed(from_component, from_port, to_component, to_port))


func connect_ports_detailed(
		from_component: StringName,
		from_port: int,
		to_component: StringName,
		to_port: int
	) -> Dictionary:
	var diagnostic: Dictionary = connection_diagnostic(from_component, from_port, to_component, to_port)
	if not diagnostic.is_empty():
		return diagnostic
	wires.append(LogicWireType.new(from_component, from_port, to_component, to_port))
	return {}


func disconnect_ports(
		from_component: StringName,
		from_port: int,
		to_component: StringName,
		to_port: int
	) -> bool:
	for index: int in range(wires.size() - 1, -1, -1):
		var wire: LogicWire = wires[index]
		if wire.from_component == from_component and wire.from_port == from_port and wire.to_component == to_component and wire.to_port == to_port:
			wires.remove_at(index)
			return true
	return false


func has_connection(
		from_component: StringName,
		from_port: int,
		to_component: StringName,
		to_port: int
	) -> bool:
	for wire: LogicWire in wires:
		if wire.from_component == from_component and wire.from_port == from_port and wire.to_component == to_component and wire.to_port == to_port:
			return true
	return false


func duplicate_circuit() -> LogicCircuit:
	var copy := LogicCircuit.new()
	for component_id: StringName in _sorted_component_ids():
		copy.add_component((components[component_id] as LogicComponent).duplicate_component())
	for wire: LogicWire in wires:
		copy.wires.append(wire.duplicate_wire())
	return copy


func canonical_signature() -> String:
	var component_data: Array[Dictionary] = []
	for component_id: StringName in _sorted_component_ids():
		component_data.append((components[component_id] as LogicComponent).to_dictionary())
	var sorted_wires: Array[LogicWire] = wires.duplicate()
	sorted_wires.sort_custom(func(left: LogicWire, right: LogicWire) -> bool: return left.canonical_id() < right.canonical_id())
	var wire_data: Array[Dictionary] = []
	for wire: LogicWire in sorted_wires:
		wire_data.append(wire.to_dictionary())
	return JSON.stringify({"components": component_data, "wires": wire_data})


func _sorted_component_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for component_id: StringName in components:
		ids.append(component_id)
	ids.sort()
	return ids


func _diagnostic(key: StringName, arguments: Array, fallback_template: String) -> Dictionary:
	return {"key": key, "args": arguments.duplicate(), "fallback": fallback_template}


func _diagnostic_fallback(diagnostic: Dictionary) -> String:
	if diagnostic.is_empty():
		return ""
	var fallback: String = diagnostic.get("fallback", "")
	var arguments: Array = diagnostic.get("args", [])
	return fallback if arguments.is_empty() else fallback % arguments
