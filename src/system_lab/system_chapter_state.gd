extends Node

signal progression_changed
signal persistent_state_changed

const SystemLevelCatalogType = preload("res://src/system_lab/system_level_catalog.gd")

var prologue_ready: bool = false
var cpu_source_signature: String = "reference-cpu4"
var ram_source_signature: String = "reference-ram2x4"
var game_completed: Dictionary[StringName, bool] = {}
var test_completed: Dictionary[StringName, bool] = {}
var game_receipts: Dictionary[StringName, Array] = {}
var test_receipts: Dictionary[StringName, Array] = {}


func capture_prologue(component_library: Dictionary) -> bool:
	if GameMode.is_test_mode():
		return false
	var signatures: Dictionary = _prologue_signatures(component_library)
	if signatures.is_empty():
		return false
	var next_cpu_signature: String = String(signatures["cpu"])
	var next_ram_signature: String = String(signatures["ram"])
	if prologue_ready and (next_cpu_signature != cpu_source_signature or next_ram_signature != ram_source_signature):
		game_completed.clear()
		game_receipts.clear()
	cpu_source_signature = next_cpu_signature
	ram_source_signature = next_ram_signature
	prologue_ready = true
	progression_changed.emit()
	persistent_state_changed.emit()
	return true


func invalidate_prologue() -> void:
	if GameMode.is_test_mode():
		return
	prologue_ready = false
	game_completed.clear()
	game_receipts.clear()
	progression_changed.emit()
	persistent_state_changed.emit()


func current_cpu_source_signature() -> String:
	return "test-mode-cpu4" if GameMode.is_test_mode() else cpu_source_signature


func current_ram_source_signature() -> String:
	return "test-mode-ram2x4" if GameMode.is_test_mode() else ram_source_signature


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
	store[level_id] = entries
	progression_changed.emit()


func mark_completed(level_id: StringName) -> void:
	if level_id.is_empty() or bool(completed_levels().get(level_id, false)):
		return
	completed_levels()[level_id] = true
	progression_changed.emit()
	if not GameMode.is_test_mode():
		persistent_state_changed.emit()


func game_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"prologue_ready": prologue_ready,
		"cpu_source_signature": cpu_source_signature,
		"ram_source_signature": ram_source_signature,
		"completed_levels": _completed_level_ids(game_completed),
	}


func restore_game(snapshot: Dictionary, component_library: Dictionary, hardware_gate_ready: bool) -> void:
	prologue_ready = false
	cpu_source_signature = "reference-cpu4"
	ram_source_signature = "reference-ram2x4"
	game_completed.clear()
	game_receipts.clear()
	if hardware_gate_ready and int(snapshot.get("schema_version", 0)) == 1:
		var signatures: Dictionary = _prologue_signatures(component_library)
		if (
			not signatures.is_empty()
			and bool(snapshot.get("prologue_ready", false))
			and String(snapshot.get("cpu_source_signature", "")) == String(signatures["cpu"])
			and String(snapshot.get("ram_source_signature", "")) == String(signatures["ram"])
		):
			cpu_source_signature = String(signatures["cpu"])
			ram_source_signature = String(signatures["ram"])
			prologue_ready = true
			var requested: Dictionary[StringName, bool] = _level_set(snapshot.get("completed_levels", []))
			var catalog := SystemLevelCatalogType.new(cpu_source_signature, ram_source_signature)
			for level_id: StringName in catalog.level_ids():
				if bool(requested.get(level_id, false)) and catalog.is_unlocked(
					level_id, game_completed, prologue_ready, false
				):
					game_completed[level_id] = true
	progression_changed.emit()


func reset_game_progress() -> void:
	prologue_ready = false
	cpu_source_signature = "reference-cpu4"
	ram_source_signature = "reference-ram2x4"
	game_completed.clear()
	game_receipts.clear()
	progression_changed.emit()
	persistent_state_changed.emit()


func reset_test_progress() -> void:
	test_completed.clear()
	test_receipts.clear()
	progression_changed.emit()


func _prologue_signatures(component_library: Dictionary) -> Dictionary:
	var cpu_sources: Array[String] = []
	for component_name: StringName in [&"TinyComputer", &"ALU4", &"Register4"]:
		var definition = component_library.get(component_name)
		if definition == null or String(definition.source_signature).is_empty():
			return {}
		cpu_sources.append(String(definition.source_signature))
	var ram_definition = component_library.get(&"RAM2x4")
	if ram_definition == null or String(ram_definition.source_signature).is_empty():
		return {}
	cpu_sources.sort()
	return {
		"cpu": "|".join(cpu_sources).sha256_text(),
		"ram": String(ram_definition.source_signature),
	}


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
