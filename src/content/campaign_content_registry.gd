class_name CampaignContentRegistry
extends RefCounted

const CampaignBranchDefinitionType = preload("res://src/content/campaign_branch_definition.gd")
const CampaignLevelDefinitionType = preload("res://src/content/campaign_level_definition.gd")

var _branches: Dictionary = {}
var _levels: Dictionary = {}
var _providers: Array[RefCounted] = []
var _registration_errors := PackedStringArray()


func retain_provider(provider: RefCounted) -> void:
	if provider != null and provider not in _providers:
		_providers.append(provider)


func register_branch(definition) -> bool:
	if definition == null:
		_registration_errors.append("Cannot register a null campaign branch.")
		return false
	if _branches.has(definition.id):
		_registration_errors.append("Duplicate campaign branch id: %s." % definition.id)
		return false
	_branches[definition.id] = definition
	return true


func register_level(definition) -> bool:
	if definition == null:
		_registration_errors.append("Cannot register a null campaign level.")
		return false
	if _levels.has(definition.id):
		_registration_errors.append("Duplicate campaign level id: %s." % definition.id)
		return false
	_levels[definition.id] = definition
	return true


func branch(branch_id: StringName):
	return _branches.get(branch_id)


func level(level_id: StringName):
	return _levels.get(level_id)


func branch_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for branch_id: StringName in _branches:
		ids.append(branch_id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var left = _branches[a]
		var right = _branches[b]
		if left.order != right.order:
			return left.order < right.order
		return String(a) < String(b)
	)
	return ids


func level_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	var included: Dictionary[StringName, bool] = {}
	for branch_id: StringName in branch_ids():
		for level_id: StringName in level_ids_for_branch(branch_id):
			ids.append(level_id)
			included[level_id] = true
	var orphan_ids: Array[StringName] = []
	for level_id: StringName in _levels:
		if not included.has(level_id):
			orphan_ids.append(level_id)
	orphan_ids.sort()
	ids.append_array(orphan_ids)
	return ids


func level_ids_for_branch(branch_id: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for level_id: StringName in _levels:
		var definition = _levels[level_id]
		if definition.branch_id == branch_id:
			ids.append(level_id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var left = _levels[a]
		var right = _levels[b]
		if left.order != right.order:
			return left.order < right.order
		return String(a) < String(b)
	)
	return ids


func dependencies(level_id: StringName) -> Array[StringName]:
	var definition = level(level_id)
	var result: Array[StringName] = []
	if definition != null:
		for dependency: StringName in definition.dependencies:
			result.append(dependency)
	return result


func is_unlocked(level_id: StringName, completed: Dictionary) -> bool:
	if not _levels.has(level_id) or not validation_errors().is_empty():
		return false
	for dependency: StringName in dependencies(level_id):
		if not bool(completed.get(dependency, false)):
			return false
	return true


func reward_names(level_id: StringName) -> Array[StringName]:
	var definition = level(level_id)
	return definition.reward_names.duplicate() if definition != null else []


func generated_rewards(level_id: StringName) -> Array[Dictionary]:
	var definition = level(level_id)
	return definition.generated_rewards.duplicate(true) if definition != null else []


func dependent_level_ids(changed_level_id: StringName) -> Array[StringName]:
	if not _levels.has(changed_level_id):
		return []
	var affected: Dictionary[StringName, bool] = {changed_level_id: true}
	var changed := true
	var ordered_ids := level_ids()
	while changed:
		changed = false
		for candidate: StringName in ordered_ids:
			if affected.has(candidate):
				continue
			for dependency: StringName in dependencies(candidate):
				if affected.has(dependency):
					affected[candidate] = true
					changed = true
					break
	var result: Array[StringName] = []
	for level_id: StringName in ordered_ids:
		if level_id != changed_level_id and affected.has(level_id):
			result.append(level_id)
	return result


func localization_keys() -> Array[StringName]:
	var seen: Dictionary[StringName, bool] = {}
	for branch_id: StringName in branch_ids():
		var branch_definition = branch(branch_id)
		seen[branch_definition.title_key] = true
	for level_id: StringName in level_ids():
		var level_definition = level(level_id)
		seen[level_definition.title_key] = true
		if not level_definition.description_key.is_empty():
			seen[level_definition.description_key] = true
	var keys: Array[StringName] = []
	for key: StringName in seen:
		keys.append(key)
	keys.sort()
	return keys


func validation_errors() -> PackedStringArray:
	var errors := _registration_errors.duplicate()
	for branch_id: StringName in branch_ids():
		var branch_definition = branch(branch_id)
		errors.append_array(branch_definition.validation_errors())
	for level_id: StringName in level_ids():
		var level_definition = level(level_id)
		errors.append_array(level_definition.validation_errors())
		if not _branches.has(level_definition.branch_id):
			errors.append(
				"Campaign level %s references unknown branch %s."
				% [level_id, level_definition.branch_id]
			)
		for dependency: StringName in level_definition.dependencies:
			if not _levels.has(dependency):
				errors.append(
					"Campaign level %s references unknown dependency %s."
					% [level_id, dependency]
				)
	_validate_reward_ownership(errors)
	_validate_dependency_cycles(errors)
	return errors


func _validate_reward_ownership(errors: PackedStringArray) -> void:
	var owners: Dictionary[StringName, StringName] = {}
	for level_id: StringName in level_ids():
		for reward_name: StringName in reward_names(level_id):
			if owners.has(reward_name):
				errors.append(
					"Campaign reward %s is owned by both %s and %s."
					% [reward_name, owners[reward_name], level_id]
				)
			else:
				owners[reward_name] = level_id


func _validate_dependency_cycles(errors: PackedStringArray) -> void:
	var indegree: Dictionary[StringName, int] = {}
	for level_id: StringName in level_ids():
		indegree[level_id] = 0
		for dependency: StringName in dependencies(level_id):
			if _levels.has(dependency):
				indegree[level_id] += 1
	var ready: Array[StringName] = []
	for level_id: StringName in level_ids():
		if indegree[level_id] == 0:
			ready.append(level_id)
	ready.sort()
	var visited := 0
	while not ready.is_empty():
		var current: StringName = ready.pop_front()
		visited += 1
		for candidate: StringName in level_ids():
			if current not in dependencies(candidate):
				continue
			indegree[candidate] -= 1
			if indegree[candidate] == 0:
				ready.append(candidate)
				ready.sort()
	if visited != _levels.size():
		errors.append("Campaign dependency graph contains a cycle.")
