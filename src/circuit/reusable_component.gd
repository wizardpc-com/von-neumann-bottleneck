class_name ReusableComponent
extends RefCounted

const LogicComponentType = preload("res://src/circuit/logic_component.gd")

var component_name: StringName = &""
var behavior_kind: StringName = &""
var source_level: StringName = &""
var input_ports: Array[StringName] = []
var output_ports: Array[StringName] = []
var input_widths: Array[int] = []
var output_widths: Array[int] = []
var circuit_snapshot: LogicCircuit
var source_signature: String = ""
var generated_from: Array[String] = []
var metadata: Dictionary = {}


func _init(
		p_component_name: StringName = &"",
		p_behavior_kind: StringName = &"",
		p_source_level: StringName = &"",
		p_source_circuit: LogicCircuit = null,
		p_generated_from: Array[String] = [],
		p_metadata: Dictionary = {}
	) -> void:
	component_name = p_component_name
	behavior_kind = p_behavior_kind
	source_level = p_source_level
	generated_from = p_generated_from.duplicate()
	metadata = p_metadata.duplicate(true)
	var prototype := LogicComponentType.new(&"PROTOTYPE", behavior_kind, String(component_name))
	input_ports = prototype.input_port_names.duplicate()
	output_ports = prototype.output_port_names.duplicate()
	input_widths = prototype.input_port_widths.duplicate()
	output_widths = prototype.output_port_widths.duplicate()
	if p_source_circuit != null:
		circuit_snapshot = p_source_circuit.duplicate_circuit()
		source_signature = circuit_snapshot.canonical_signature()
	elif not generated_from.is_empty():
		source_signature = JSON.stringify({
			"generated_component": String(component_name),
			"behavior_kind": String(behavior_kind),
			"generated_from": generated_from,
			"metadata": metadata,
		})


func is_ready() -> bool:
	return not component_name.is_empty() and not behavior_kind.is_empty() and not source_signature.is_empty()


func is_generated_wrapper() -> bool:
	return circuit_snapshot == null and not generated_from.is_empty()


func instantiate(component_id: StringName, p_display_name: String = "") -> LogicComponent:
	if not is_ready():
		return null
	return LogicComponentType.new(
		component_id,
		behavior_kind,
		p_display_name if not p_display_name.is_empty() else String(component_name),
		&"",
		false,
		input_ports,
		output_ports,
		input_widths,
		output_widths,
		{
			"library_name": String(component_name),
			"source_signature": source_signature,
			"generated": is_generated_wrapper(),
		}
	)


func duplicate_component_definition() -> ReusableComponent:
	var copy := ReusableComponent.new()
	copy.component_name = component_name
	copy.behavior_kind = behavior_kind
	copy.source_level = source_level
	copy.input_ports = input_ports.duplicate()
	copy.output_ports = output_ports.duplicate()
	copy.input_widths = input_widths.duplicate()
	copy.output_widths = output_widths.duplicate()
	copy.circuit_snapshot = circuit_snapshot.duplicate_circuit() if circuit_snapshot != null else null
	copy.source_signature = source_signature
	copy.generated_from = generated_from.duplicate()
	copy.metadata = metadata.duplicate(true)
	return copy


func canonical_signature() -> String:
	return JSON.stringify({
		"component_name": String(component_name),
		"behavior_kind": String(behavior_kind),
		"source_level": String(source_level),
		"input_ports": input_ports.map(func(port_name: StringName) -> String: return String(port_name)),
		"output_ports": output_ports.map(func(port_name: StringName) -> String: return String(port_name)),
		"input_widths": input_widths,
		"output_widths": output_widths,
		"source_signature": source_signature,
		"generated_from": generated_from,
		"metadata": metadata,
	})
