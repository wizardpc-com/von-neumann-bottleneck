extends Node

signal progression_changed

const RECEIPT_LIMIT := 12

const CONCEPT_REQUIREMENTS: Dictionary[StringName, StringName] = {
	&"cpu_wait": &"system:cpu_speed",
	&"controlled_comparison": &"system:cpu_speed",
	&"bottleneck": &"system:bottleneck",
	&"cache": &"nearby_storage",
	&"hit": &"nearby_storage",
	&"miss": &"nearby_storage",
	&"locality": &"access_order",
	&"working_set": &"working_set",
	&"blocking": &"blocking",
}

var game_completed: Dictionary[StringName, bool] = {}
var test_completed: Dictionary[StringName, bool] = {}
var game_receipts: Dictionary[StringName, Array] = {}
var test_receipts: Dictionary[StringName, Array] = {}
var game_capstone_first_experiment_observed: bool = false
var test_capstone_first_experiment_observed: bool = false


func completed_levels() -> Dictionary:
	return test_completed if GameMode.is_test_mode() else game_completed


func receipt_store() -> Dictionary[StringName, Array]:
	return test_receipts if GameMode.is_test_mode() else game_receipts


func receipts_for(level_id: StringName) -> Array:
	return (receipt_store().get(level_id, []) as Array).duplicate()


func record_receipt(level_id: StringName, receipt: Variant) -> void:
	if level_id.is_empty() or receipt == null:
		return
	var store: Dictionary[StringName, Array] = receipt_store()
	var entries: Array = store.get(level_id, [])
	var signature: String = receipt.canonical_signature()
	for existing: Variant in entries:
		if existing != null and existing.canonical_signature() == signature:
			return
	entries.append(receipt)
	while entries.size() > RECEIPT_LIMIT:
		entries.pop_front()
	store[level_id] = entries
	progression_changed.emit()


func capstone_first_experiment_observed() -> bool:
	return test_capstone_first_experiment_observed if GameMode.is_test_mode() else game_capstone_first_experiment_observed


func mark_capstone_first_experiment_observed() -> void:
	if capstone_first_experiment_observed():
		return
	if GameMode.is_test_mode():
		test_capstone_first_experiment_observed = true
	else:
		game_capstone_first_experiment_observed = true
	progression_changed.emit()


func mark_completed(level_id: StringName) -> void:
	if level_id.is_empty() or bool(completed_levels().get(level_id, false)):
		return
	completed_levels()[level_id] = true
	progression_changed.emit()


func chapter_unlocked() -> bool:
	return GameMode.is_test_mode() or bool(SystemChapter.completed_levels().get(&"bottleneck", false))


func concept_unlocked(concept_id: StringName) -> bool:
	var requirement: StringName = CONCEPT_REQUIREMENTS.get(concept_id, &"")
	if requirement.is_empty():
		return false
	var requirement_text := String(requirement)
	if requirement_text.begins_with("system:"):
		return bool(SystemChapter.completed_levels().get(StringName(requirement_text.trim_prefix("system:")), false))
	return bool(completed_levels().get(requirement, false))


func reset_test_progress() -> void:
	test_completed.clear()
	test_receipts.clear()
	test_capstone_first_experiment_observed = false
	progression_changed.emit()
