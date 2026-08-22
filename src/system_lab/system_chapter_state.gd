extends Node

signal progression_changed

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
	var cpu_sources: Array[String] = []
	for component_name: StringName in [&"TinyComputer", &"ALU4", &"Register4"]:
		var definition = component_library.get(component_name)
		if definition != null and not String(definition.source_signature).is_empty():
			cpu_sources.append(String(definition.source_signature))
	var ram_definition = component_library.get(&"RAM2x4")
	if cpu_sources.size() != 3 or ram_definition == null:
		return false
	cpu_sources.sort()
	var next_cpu_signature: String = "|".join(cpu_sources).sha256_text()
	var next_ram_signature: String = String(ram_definition.source_signature)
	if prologue_ready and (next_cpu_signature != cpu_source_signature or next_ram_signature != ram_source_signature):
		game_completed.clear()
		game_receipts.clear()
	cpu_source_signature = next_cpu_signature
	ram_source_signature = next_ram_signature
	prologue_ready = true
	progression_changed.emit()
	return true


func invalidate_prologue() -> void:
	if GameMode.is_test_mode():
		return
	prologue_ready = false
	game_completed.clear()
	game_receipts.clear()
	progression_changed.emit()


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
	if level_id.is_empty():
		return
	completed_levels()[level_id] = true
	progression_changed.emit()


func reset_test_progress() -> void:
	test_completed.clear()
	test_receipts.clear()
	progression_changed.emit()
