class_name SystemTopology
extends RefCounted

const PartSpecType = preload("res://src/system_lab/system_part_spec.gd")

const CPU_ID: StringName = &"CPU"
const BUS_ID: StringName = &"BUS"
const RAM_ID: StringName = &"RAM"

const REQUIRED_CONNECTIONS: Array[Dictionary] = [
	{"from": CPU_ID, "from_port": &"request_out", "to": BUS_ID, "to_port": &"cpu_request_in"},
	{"from": BUS_ID, "from_port": &"ram_request_out", "to": RAM_ID, "to_port": &"request_in"},
	{"from": CPU_ID, "from_port": &"write_out", "to": BUS_ID, "to_port": &"cpu_write_in"},
	{"from": BUS_ID, "from_port": &"ram_write_out", "to": RAM_ID, "to_port": &"write_in"},
	{"from": RAM_ID, "from_port": &"read_out", "to": BUS_ID, "to_port": &"ram_read_in"},
	{"from": BUS_ID, "from_port": &"cpu_read_out", "to": CPU_ID, "to_port": &"read_in"},
]

var parts: Dictionary[StringName, SystemPartSpec] = {}
var connections: Array[Dictionary] = []


func set_part(slot_id: StringName, part: SystemPartSpec) -> bool:
	var expected_kind: StringName = _expected_kind(slot_id)
	if part == null or expected_kind.is_empty() or part.kind != expected_kind:
		return false
	if not part.validation_errors().is_empty():
		return false
	parts[slot_id] = part.duplicate_spec()
	return true


func part(slot_id: StringName) -> SystemPartSpec:
	return parts.get(slot_id)


func connect_ports(
		from_id: StringName,
		from_port: StringName,
		to_id: StringName,
		to_port: StringName
	) -> bool:
	var candidate := {
		"from": from_id,
		"from_port": from_port,
		"to": to_id,
		"to_port": to_port,
	}
	if not _is_required_connection(candidate):
		return false
	var key: String = _connection_key(candidate)
	for existing: Dictionary in connections:
		if _connection_key(existing) == key:
			return false
		if existing.get("to") == to_id and existing.get("to_port") == to_port:
			return false
	connections.append(candidate)
	return true


func disconnect_ports(
		from_id: StringName,
		from_port: StringName,
		to_id: StringName,
		to_port: StringName
	) -> bool:
	var key: String = _connection_key({
		"from": from_id, "from_port": from_port,
		"to": to_id, "to_port": to_port,
	})
	for index: int in range(connections.size()):
		if _connection_key(connections[index]) == key:
			connections.remove_at(index)
			return true
	return false


func connect_required_routes() -> void:
	connections.clear()
	for route: Dictionary in REQUIRED_CONNECTIONS:
		connections.append(route.duplicate())


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for slot_id: StringName in [CPU_ID, BUS_ID, RAM_ID]:
		var selected: SystemPartSpec = parts.get(slot_id)
		if selected == null:
			errors.append("System topology is missing %s." % slot_id)
		elif selected.kind != _expected_kind(slot_id):
			errors.append("System topology slot %s contains the wrong part kind." % slot_id)
		else:
			errors.append_array(selected.validation_errors())
	var seen: Dictionary[String, bool] = {}
	for connection: Dictionary in connections:
		var key: String = _connection_key(connection)
		if seen.has(key):
			errors.append("System topology repeats connection %s." % key)
		elif not _is_required_connection(connection):
			errors.append("System topology contains unsupported connection %s." % key)
		seen[key] = true
	for required: Dictionary in REQUIRED_CONNECTIONS:
		var required_key: String = _connection_key(required)
		if not seen.has(required_key):
			errors.append("System topology is missing connection %s." % required_key)
	return errors


func is_valid() -> bool:
	return validation_errors().is_empty()


func duplicate_topology() -> SystemTopology:
	var copy := SystemTopology.new()
	for slot_id: StringName in parts:
		copy.parts[slot_id] = parts[slot_id].duplicate_spec()
	copy.connections = connections.duplicate(true)
	return copy


func canonical_signature() -> String:
	var part_data: Dictionary = {}
	for slot_id: StringName in [CPU_ID, BUS_ID, RAM_ID]:
		var selected: SystemPartSpec = parts.get(slot_id)
		part_data[String(slot_id)] = selected.canonical_signature() if selected != null else ""
	var connection_keys: Array[String] = []
	for connection: Dictionary in connections:
		connection_keys.append(_connection_key(connection))
	connection_keys.sort()
	return JSON.stringify({"parts": part_data, "connections": connection_keys})


func _expected_kind(slot_id: StringName) -> StringName:
	match slot_id:
		CPU_ID:
			return PartSpecType.KIND_CPU
		BUS_ID:
			return PartSpecType.KIND_BUS
		RAM_ID:
			return PartSpecType.KIND_RAM
	return &""


func _is_required_connection(candidate: Dictionary) -> bool:
	var key: String = _connection_key(candidate)
	for required: Dictionary in REQUIRED_CONNECTIONS:
		if _connection_key(required) == key:
			return true
	return false


func _connection_key(connection: Dictionary) -> String:
	return "%s:%s>%s:%s" % [
		String(connection.get("from", "")), String(connection.get("from_port", "")),
		String(connection.get("to", "")), String(connection.get("to_port", "")),
	]
