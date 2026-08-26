extends Node

signal progression_changed
signal persistent_state_changed

const LocalityLevelCatalogType = preload("res://src/locality_chapter/locality_level_catalog.gd")

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
	if not GameMode.is_test_mode():
		persistent_state_changed.emit()


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


func game_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"completed_levels": _completed_level_ids(game_completed),
	}


func restore_game(snapshot: Dictionary, chapter_ready: bool) -> void:
	game_completed.clear()
	game_receipts.clear()
	game_capstone_first_experiment_observed = false
	if chapter_ready and int(snapshot.get("schema_version", 0)) == 1:
		var requested: Dictionary[StringName, bool] = _level_set(snapshot.get("completed_levels", []))
		var catalog := LocalityLevelCatalogType.new()
		for level_id: StringName in catalog.level_ids():
			if bool(requested.get(level_id, false)) and catalog.is_unlocked(
				level_id, game_completed, true, false
			):
				game_completed[level_id] = true
	progression_changed.emit()


func reset_game_progress() -> void:
	game_completed.clear()
	game_receipts.clear()
	game_capstone_first_experiment_observed = false
	progression_changed.emit()
	persistent_state_changed.emit()


func reset_test_progress() -> void:
	test_completed.clear()
	test_receipts.clear()
	test_capstone_first_experiment_observed = false
	progression_changed.emit()


func _completed_level_ids(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for level_id: StringName in source:
		if bool(source[level_id]):
			result.append(String(level_id))
	result.sort()
	return result


func _level_set(source: Variant) -> Dictionary[StringName, bool]:
	var result: Dictionary[StringName, bool] = {}
	if source is Array:
		for level_id: Variant in source:
			result[StringName(level_id)] = true
	return result
