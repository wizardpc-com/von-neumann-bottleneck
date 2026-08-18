class_name CampaignLevelDefinition
extends RefCounted

const ENTRY_TUTORIAL := &"tutorial"
const ENTRY_HALF_ADDER := &"half_adder"
const ENTRY_CIRCUIT := &"circuit"
const VALID_ENTRY_KINDS: Array[StringName] = [
	ENTRY_TUTORIAL, ENTRY_HALF_ADDER, ENTRY_CIRCUIT,
]

var id: StringName
var branch_id: StringName
var order: int
var title_key: StringName
var description_key: StringName
var dependencies: Array[StringName]
var entry_kind: StringName
var builder: Callable
var reward_names: Array[StringName]
var generated_rewards: Array[Dictionary]


func _init(
		p_id: StringName,
		p_branch_id: StringName,
		p_order: int,
		p_title_key: StringName,
		p_description_key: StringName = &"",
		p_dependencies: Array[StringName] = [],
		p_entry_kind: StringName = ENTRY_CIRCUIT,
		p_builder: Callable = Callable(),
		p_reward_names: Array[StringName] = [],
		p_generated_rewards: Array[Dictionary] = []
	) -> void:
	id = p_id
	branch_id = p_branch_id
	order = p_order
	title_key = p_title_key
	description_key = p_description_key
	dependencies = p_dependencies.duplicate()
	entry_kind = p_entry_kind
	builder = p_builder
	reward_names = p_reward_names.duplicate()
	generated_rewards = p_generated_rewards.duplicate(true)


func instantiate(library: Dictionary = {}) -> Dictionary:
	if entry_kind != ENTRY_CIRCUIT or not builder.is_valid():
		return {}
	var value: Variant = builder.call(library)
	if not value is Dictionary:
		push_error("Campaign level builder %s must return a Dictionary." % id)
		return {}
	var result: Dictionary = value
	result["id"] = id
	result["title_key"] = title_key
	if not description_key.is_empty():
		result["description_key"] = description_key
	return result


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("Campaign level id must not be empty.")
	if branch_id.is_empty():
		errors.append("Campaign level %s must belong to a branch." % id)
	if order < 0:
		errors.append("Campaign level %s must use a non-negative order." % id)
	if title_key.is_empty():
		errors.append("Campaign level %s must declare a title localization key." % id)
	if entry_kind not in VALID_ENTRY_KINDS:
		errors.append("Campaign level %s has unknown entry kind %s." % [id, entry_kind])
	if entry_kind == ENTRY_CIRCUIT and not builder.is_valid():
		errors.append("Circuit campaign level %s must declare a valid builder." % id)
	if entry_kind == ENTRY_CIRCUIT and description_key.is_empty():
		errors.append("Circuit campaign level %s must declare a description localization key." % id)
	var dependency_set: Dictionary[StringName, bool] = {}
	for dependency: StringName in dependencies:
		if dependency.is_empty():
			errors.append("Campaign level %s has an empty dependency id." % id)
		elif dependency == id:
			errors.append("Campaign level %s cannot depend on itself." % id)
		elif dependency_set.has(dependency):
			errors.append("Campaign level %s repeats dependency %s." % [id, dependency])
		dependency_set[dependency] = true
	var reward_set: Dictionary[StringName, bool] = {}
	for reward_name: StringName in reward_names:
		if reward_name.is_empty():
			errors.append("Campaign level %s has an empty reward name." % id)
		elif reward_set.has(reward_name):
			errors.append("Campaign level %s repeats reward %s." % [id, reward_name])
		reward_set[reward_name] = true
	var generated_set: Dictionary[StringName, bool] = {}
	for recipe: Dictionary in generated_rewards:
		var generated_name := StringName(recipe.get("name", &""))
		var behavior_kind := StringName(recipe.get("behavior_kind", &""))
		if generated_name.is_empty() or behavior_kind.is_empty():
			errors.append("Campaign level %s has an incomplete generated reward recipe." % id)
		elif generated_set.has(generated_name):
			errors.append(
				"Campaign level %s repeats generated reward recipe %s."
				% [id, generated_name]
			)
		elif not reward_set.has(generated_name):
			errors.append(
				"Campaign level %s generated reward %s must also appear in reward_names."
				% [id, generated_name]
			)
		generated_set[generated_name] = true
	return errors
