extends Node

signal progression_changed
signal persistent_state_changed

const Workspace = preload("res://src/save/chapter_workspace.gd")
var game_workspaces: Dictionary = {}
var test_workspaces: Dictionary = {}
var game_observations: Dictionary = {}
var _workspace_fingerprint: String = ""

const SystemLevelCatalogType = preload("res://src/system_lab/system_level_catalog.gd")

var application_designs: Dictionary = {}

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
		application_designs.clear()
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
	application_designs.clear()
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


func record_receipt(level_id: StringName, receipt: Variant, recipe: Dictionary = {}) -> void:
	if level_id.is_empty() or receipt == null:
		return
	if not recipe.is_empty(): _retain_observation(level_id,recipe,receipt)
	var store: Dictionary[StringName, Array] = receipt_store()
	var entries: Array = store.get(level_id, [])
	var signature: String = receipt.canonical_signature()
	for existing: Variant in entries:
		if existing != null and existing.canonical_signature() == signature:
			return
	entries.append(receipt)
	while entries.size()>Workspace.MAX_RECEIPTS:
		var victim: int=1
		for index: int in range(1,entries.size()-1):
			if not entries[index].get("checkpoint",false): victim=index; break
		entries.remove_at(victim)
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
		"workspaces": game_workspaces.duplicate(true),
		"observations": game_observations.duplicate(true),
		"prologue_ready": prologue_ready,
		"cpu_source_signature": cpu_source_signature,
		"ram_source_signature": ram_source_signature,
		"completed_levels": _completed_level_ids(game_completed),
		"application_designs": application_designs.duplicate(true),
	}


func restore_game(snapshot: Dictionary, component_library: Dictionary, hardware_gate_ready: bool) -> void:
	game_workspaces = Workspace.bounded_workspaces(snapshot.get("workspaces",{}),SystemLevelCatalogType.new().level_ids())
	game_observations = {}
	prologue_ready = false
	cpu_source_signature = "reference-cpu4"
	ram_source_signature = "reference-ram2x4"
	game_completed.clear()
	game_receipts.clear()
	application_designs.clear()
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
				if level_id in [&"read_once",&"two_orders"]:
					_restore_application(level_id,snapshot.get("application_designs",{}),catalog)
					continue
				if bool(requested.get(level_id, false)) and catalog.is_unlocked(
					level_id, game_completed, prologue_ready, false
				):
					game_completed[level_id] = true
	if prologue_ready: _restore_observations(snapshot.get("observations",{}))
	progression_changed.emit()


func reset_game_progress() -> void:
	game_workspaces.clear()
	game_observations.clear()
	prologue_ready = false
	cpu_source_signature = "reference-cpu4"
	ram_source_signature = "reference-ram2x4"
	game_completed.clear()
	game_receipts.clear()
	application_designs.clear()
	progression_changed.emit()
	persistent_state_changed.emit()


func reset_test_progress() -> void:
	test_workspaces.clear()
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


func retain_application(id: StringName,source: String,parts: Dictionary,receipt: Variant) -> void:
	if GameMode.is_test_mode() or id not in [&"read_once",&"two_orders"]: return
	var catalog := SystemLevelCatalogType.new(cpu_source_signature,ram_source_signature)
	if int(catalog.completion_status(id,[receipt]).get("progress",0)) == 0: return
	var variant: String = "move" if source == catalog.PROGRAM_COPY else "compute" if id == &"two_orders" else "read"
	if not application_designs.has(String(id)): application_designs[String(id)] = {}
	application_designs[String(id)][variant] = {"source":source,"parts":parts.duplicate()}
	persistent_state_changed.emit()

func _restore_application(id: StringName,saved: Variant,catalog: SystemLevelCatalog) -> void:
	if not saved is Dictionary or not saved.get(String(id),{}) is Dictionary: return
	if not catalog.is_unlocked(id,game_completed,prologue_ready): return
	for value: Variant in saved.get(String(id),{}).values():
		if not value is Dictionary or not value.get("source") is String or not value.get("parts") is Dictionary: continue
		var receipt: SystemRunReceipt = catalog.replay_application(id,value.source,value.parts)
		if int(catalog.completion_status(id,[receipt]).get("progress",0)) == 0: continue
		var variant: String = "move" if value.source == catalog.PROGRAM_COPY else "compute" if id == &"two_orders" else "read"
		if not application_designs.has(String(id)): application_designs[String(id)] = {}
		application_designs[String(id)][variant] = value.duplicate(true)
		if not game_receipts.has(id): game_receipts[id] = []
		game_receipts[id].append(receipt)
	if catalog.completion_status(id,game_receipts.get(id,[])).complete: game_completed[id] = true


func workspace_version() -> String:
	if _workspace_fingerprint.is_empty():
		_workspace_fingerprint = Workspace.fingerprint(["res://src/system_lab/system_level_catalog.gd", "res://src/system_lab/system_simulation_core.gd", "res://src/system_lab/system_dsl_parser.gd", "res://src/system_lab/system_topology.gd"])
	return _workspace_fingerprint

func workspace_for(id: StringName) -> Dictionary:
	var store: Dictionary = test_workspaces if GameMode.is_test_mode() else game_workspaces
	var saved: Dictionary = store.get(String(id),{}).duplicate(true)
	if not saved.is_empty() and saved.get("version","") != workspace_version():
		return {"draft_source":saved.get("draft_source",""),"stale":true}
	return saved

func retain_workspace(id: StringName, value: Dictionary, mode: StringName = &"") -> void:
	if id.is_empty(): return
	var in_test: bool = mode == &"test" if not mode.is_empty() else GameMode.is_test_mode()
	var store: Dictionary = test_workspaces if in_test else game_workspaces
	var saved: Dictionary = Workspace.encode(value)
	saved["version"] = workspace_version()
	var previous: Dictionary = store.get(String(id),{})
	if previous.get("version",workspace_version()) != workspace_version():
		saved["previous_version"] = previous
	elif previous.has("previous_version"):
		saved["previous_version"] = previous.previous_version
	if saved == previous: return
	store[String(id)] = saved
	if not in_test: persistent_state_changed.emit()


func _replay_observation(id: StringName, recipe: Dictionary) -> Variant:
	if recipe.get("version","") != workspace_version() or recipe.get("cpu","") != cpu_source_signature or recipe.get("ram","") != ram_source_signature: return null
	if not recipe.get("source") is String or not recipe.get("parts") is Dictionary: return null
	var catalog := SystemLevelCatalogType.new(cpu_source_signature,ram_source_signature)
	var receipt: SystemRunReceipt=catalog.replay_observation(id,recipe.source,recipe.parts)
	return receipt if receipt.all_passed else null


func _retain_observation(id: StringName, recipe: Dictionary, receipt: Variant) -> void:
	if GameMode.is_test_mode() or not receipt.all_passed: return
	var saved: Dictionary=Workspace.encode(recipe)
	saved["version"]=workspace_version()
	saved["cpu"]=cpu_source_signature
	saved["ram"]=ram_source_signature
	var catalog := SystemLevelCatalogType.new(cpu_source_signature,ram_source_signature)
	saved["checkpoint"]=catalog.completion_status(id,[receipt]).get("progress",0)>0
	var entries: Array=game_observations.get(String(id),[])
	if saved in entries: return
	entries.append(saved)
	while entries.size()>Workspace.MAX_RECEIPTS: entries.remove_at(1)
	game_observations[String(id)]=entries
	persistent_state_changed.emit()

func _restore_observations(value: Variant) -> void:
	if not value is Dictionary: return
	var catalog := SystemLevelCatalogType.new()
	for id: StringName in catalog.level_ids():
		var entries: Variant=value.get(String(id),[])
		if not entries is Array: continue
		for recipe: Variant in entries.slice(0,Workspace.MAX_RECEIPTS):
			if not recipe is Dictionary or JSON.stringify(recipe).length()>20000: continue
			recipe=Workspace.encode(recipe)
			var receipt: Variant=_replay_observation(id,recipe)
			if receipt == null: continue
			if not game_receipts.has(id): game_receipts[id]=[]
			var duplicate: bool=false
			for existing: Variant in game_receipts[id]: duplicate=duplicate or existing.canonical_signature()==receipt.canonical_signature()
			if not duplicate: game_receipts[id].append(receipt)
			if not game_observations.has(String(id)): game_observations[String(id)]=[]
			game_observations[String(id)].append(recipe.duplicate(true))
