class_name PlayerContentState
extends RefCounted

const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")

signal persistent_state_changed

var component_library: Dictionary = {}
var completed_levels: Dictionary = {}


func mark_completed(level_id: StringName) -> void:
	if level_id.is_empty() or bool(completed_levels.get(level_id, false)):
		return
	completed_levels[level_id] = true
	persistent_state_changed.emit()


func install_reusable(level_id: StringName, reusable, catalog) -> Array[StringName]:
	if reusable == null or reusable.component_name.is_empty() or not reusable.is_ready():
		push_error("Cannot install an empty reusable component for level %s." % level_id)
		return []
	var declared_rewards: Array[StringName] = catalog.reward_names(level_id)
	if reusable.component_name not in declared_rewards:
		push_error(
			"Level %s did not declare reusable reward %s."
			% [level_id, reusable.component_name]
		)
		return []
	var invalidated: Array[StringName] = []
	var previous = component_library.get(reusable.component_name)
	if previous != null and previous.source_signature != reusable.source_signature:
		invalidated = _invalidate_dependents(level_id, catalog)
	component_library[reusable.component_name] = reusable
	for recipe: Dictionary in catalog.generated_rewards(level_id):
		var generated_name := StringName(recipe.get("name", &""))
		component_library[generated_name] = ReusableComponentType.new(
			generated_name,
			StringName(recipe.get("behavior_kind", &"")),
			level_id,
			null,
			[reusable.source_signature],
			(recipe.get("properties", {}) as Dictionary).duplicate(true)
		)
	completed_levels[level_id] = true
	persistent_state_changed.emit()
	return invalidated


func invalidate_dependents(changed_level_id: StringName, catalog) -> Array[StringName]:
	var invalidated: Array[StringName] = _invalidate_dependents(changed_level_id, catalog)
	persistent_state_changed.emit()
	return invalidated


func _invalidate_dependents(changed_level_id: StringName, catalog) -> Array[StringName]:
	var invalidated: Array[StringName] = catalog.dependent_level_ids(changed_level_id)
	for level_id: StringName in invalidated:
		completed_levels.erase(level_id)
		for reward_name: StringName in catalog.reward_names(level_id):
			component_library.erase(reward_name)
	return invalidated


func canonical_signature() -> String:
	var completed: Array[String] = []
	for level_id: StringName in completed_levels:
		if bool(completed_levels[level_id]):
			completed.append(String(level_id))
	completed.sort()
	var designs: Dictionary = {}
	var names: Array[StringName] = []
	for component_name: StringName in component_library:
		names.append(component_name)
	names.sort()
	for component_name: StringName in names:
		var definition = component_library[component_name]
		designs[String(component_name)] = definition.canonical_signature()
	return JSON.stringify({
		"completed_levels": completed,
		"component_library": designs,
	})


func manifest_snapshot() -> Dictionary:
	var completed: Array[String] = []
	for level_id: StringName in completed_levels:
		if bool(completed_levels[level_id]):
			completed.append(String(level_id))
	completed.sort()
	var designs: Array[Dictionary] = []
	var names: Array[StringName] = []
	for component_name: StringName in component_library:
		names.append(component_name)
	names.sort()
	for component_name: StringName in names:
		var definition = component_library[component_name]
		designs.append({
			"component_name": String(component_name),
			"behavior_kind": String(definition.behavior_kind),
			"source_level": String(definition.source_level),
			"source_signature": definition.source_signature,
			"generated_from": definition.generated_from.duplicate(),
			"metadata": definition.metadata.duplicate(true),
		})
	return {
		"schema_version": 1,
		"completed_levels": completed,
		"designs": designs,
	}
