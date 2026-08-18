class_name PrologueLevelCatalog
extends RefCounted

const CampaignContentRegistryType = preload("res://src/content/campaign_content_registry.gd")
const PrologueContentManifestType = preload("res://src/content/prologue/prologue_content_manifest.gd")

var _registry
var _content_valid := false


func _init() -> void:
	_registry = CampaignContentRegistryType.new()
	PrologueContentManifestType.new().register_into(_registry)
	var errors: PackedStringArray = _registry.validation_errors()
	_content_valid = errors.is_empty()
	for error: String in errors:
		push_error("Invalid prologue content: %s" % error)


func level_ids() -> Array[StringName]:
	return _registry.level_ids() if _content_valid else []


func branch_ids() -> Array[StringName]:
	return _registry.branch_ids() if _content_valid else []


func level_ids_for_branch(branch_id: StringName) -> Array[StringName]:
	return _registry.level_ids_for_branch(branch_id) if _content_valid else []


func branch_title_key(branch_id: StringName) -> StringName:
	var definition = _registry.branch(branch_id)
	return definition.title_key if definition != null else &"hardware.prologue.unknown"


func title_key(level_id: StringName) -> StringName:
	var definition = _registry.level(level_id)
	return definition.title_key if definition != null else &"hardware.prologue.unknown"


func entry_kind(level_id: StringName) -> StringName:
	var definition = _registry.level(level_id)
	return definition.entry_kind if definition != null else &""


func dependencies(level_id: StringName) -> Array[StringName]:
	return _registry.dependencies(level_id)


func is_unlocked(level_id: StringName, completed: Dictionary) -> bool:
	return _content_valid and _registry.is_unlocked(level_id, completed)


func reward_names(level_id: StringName) -> Array[StringName]:
	return _registry.reward_names(level_id)


func generated_rewards(level_id: StringName) -> Array[Dictionary]:
	return _registry.generated_rewards(level_id)


func dependent_level_ids(changed_level_id: StringName) -> Array[StringName]:
	return _registry.dependent_level_ids(changed_level_id)


func localization_keys() -> Array[StringName]:
	return _registry.localization_keys()


func validation_errors() -> PackedStringArray:
	return _registry.validation_errors()


func definition(level_id: StringName, library: Dictionary = {}) -> Dictionary:
	if not _content_valid:
		return {}
	var level_definition = _registry.level(level_id)
	return level_definition.instantiate(library) if level_definition != null else {}


func reference_circuit(level_id: StringName, library: Dictionary = {}) -> LogicCircuit:
	var level: Dictionary = definition(level_id, library)
	if level.is_empty() or not bool(level.get("available", true)):
		return null
	var circuit := LogicCircuit.new()
	for component: LogicComponent in level.get("components", []):
		circuit.add_component(component.duplicate_component())
	for wire: Dictionary in level.get("reference_wires", []):
		var diagnostic: Dictionary = circuit.connect_ports_detailed(
			wire["from"], int(wire.get("from_port", 0)),
			wire["to"], int(wire.get("to_port", 0))
		)
		if not diagnostic.is_empty():
			push_error("Reference wire rejected for %s: %s" % [level_id, diagnostic])
			return null
	return circuit
