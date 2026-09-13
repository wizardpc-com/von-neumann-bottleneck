extends Node

signal progression_changed
signal persistent_state_changed

const Workspace = preload("res://src/save/chapter_workspace.gd")
var game_workspaces: Dictionary = {}
var test_workspaces: Dictionary = {}
var game_observations: Dictionary = {}
var _workspace_fingerprint: String = ""

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

var economical_design: Dictionary = {}

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
	while entries.size() > RECEIPT_LIMIT:
		entries.remove_at(_discardable_receipt(entries))
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
		persistent_state_changed.emit()
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
		"workspaces": game_workspaces.duplicate(true),
		"observations": game_observations.duplicate(true),
		"first_experiment_observed":game_capstone_first_experiment_observed,
		"completed_levels": _completed_level_ids(game_completed),
		"economical_design": economical_design.duplicate(true),
	}


func restore_game(snapshot: Dictionary, chapter_ready: bool) -> void:
	game_workspaces = Workspace.bounded_workspaces(snapshot.get("workspaces",{}),LocalityLevelCatalogType.new().level_ids())
	game_observations = {}
	game_completed.clear()
	economical_design.clear()
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
		if game_completed.has(&"capstone") and qualifies_economical(snapshot.get("economical_design",{})):
			economical_design = snapshot.economical_design.duplicate(true)
	if chapter_ready:
		_restore_observations(snapshot.get("observations",{}))
		var restored_catalog := LocalityLevelCatalogType.new()
		game_capstone_first_experiment_observed = bool(snapshot.get("first_experiment_observed",false)) and restored_catalog.capstone_baseline_seen(game_receipts.get(&"capstone",[])) and restored_catalog.capstone_modified_experiment_seen(game_receipts.get(&"capstone",[]))
	progression_changed.emit()


func reset_game_progress() -> void:
	game_workspaces.clear()
	game_observations.clear()
	game_completed.clear()
	economical_design.clear()
	game_receipts.clear()
	game_capstone_first_experiment_observed = false
	progression_changed.emit()
	persistent_state_changed.emit()


func reset_test_progress() -> void:
	test_workspaces.clear()
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


func retain_economical(source: String,cache_lines: int,passes: int,blocks: int,bypass: bool) -> void:
	if GameMode.is_test_mode(): return
	var design: Dictionary = {"source":source,"cache_lines":cache_lines,"passes":passes,"blocks":blocks,"bypass":bypass}
	if qualifies_economical(design):
		economical_design = design
		persistent_state_changed.emit()

func qualifies_economical(value: Variant) -> bool:
	if not value is Dictionary or not value.get("source") is String or value.source.length()>16000: return false
	if value.get("cache_lines") != 1 or value.get("passes") != 2 or value.get("blocks") not in [0,1,2,4] or value.get("bypass") != false: return false
	var core := preload("res://src/simulation/simulation_core.gd").new()
	var program = preload("res://src/simulation/dsl_parser.gd").parse(value.source)
	if not program.is_valid(): return false
	var trace: SimulationTrace = core.run_workload(program,core.official_data_copy(),1,"Economical recovery",2,int(value.blocks),false)
	return trace.passed and int(trace.metrics.get("total_cycles",99999)) <= 145 and int(trace.metrics.get("hardware_cost",99999)) <= 4


func workspace_version() -> String:
	if _workspace_fingerprint.is_empty():
		_workspace_fingerprint = Workspace.fingerprint(["res://src/locality_chapter/locality_level_catalog.gd", "res://src/simulation/simulation_core.gd", "res://src/simulation/dsl_parser.gd", "res://src/simulation/program_templates.gd", "res://src/content/locality/locality_content_manifest.gd"])
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


func _discardable_receipt(entries: Array) -> int:
	var catalog := LocalityLevelCatalogType.new()
	for index: int in range(1,entries.size()-1):
		var item: Variant=entries[index]
		var pinned: bool=catalog._is_capstone_baseline_receipt(item)
		for id: StringName in catalog.level_ids(): pinned = pinned or catalog.is_qualifying_paired_baseline(id,item)
		if not pinned: return index
	return 1

func _replay_observation(id: StringName, recipe: Dictionary) -> Variant:
	if recipe.get("version","") != workspace_version(): return null
	var source: Variant=recipe.get("source","")
	if not source is String or source.length()>16000: return null
	if recipe.get("cache_lines") not in [0,1,2,4] or recipe.get("passes") not in [1,2] or recipe.get("blocks") not in [0,1,2,4] or not recipe.get("bypass") is bool: return null
	var program = preload("res://src/simulation/dsl_parser.gd").parse(source)
	if not program.is_valid(): return null
	var core = preload("res://src/simulation/simulation_core.gd").new()
	var data: Array[int]=core.official_data_copy()
	var trace: SimulationTrace=core.run_workload(program,data,int(recipe.cache_lines),"Restored observation",int(recipe.passes),int(recipe.blocks),recipe.bypass)
	if not trace.passed: return null
	var receipt = preload("res://src/locality_chapter/locality_run_receipt.gd").new()
	receipt.populate(id,trace,program.traversal_pattern(),data,int(recipe.passes),int(recipe.blocks),recipe.bypass)
	return receipt


func _retain_observation(id: StringName, recipe: Dictionary, receipt: Variant) -> void:
	if GameMode.is_test_mode() or not receipt.passed: return
	var saved: Dictionary=Workspace.encode(recipe)
	saved["version"]=workspace_version()
	var catalog := LocalityLevelCatalogType.new()
	saved["checkpoint"]=catalog._is_capstone_baseline_receipt(receipt) or catalog.is_qualifying_paired_baseline(id,receipt)
	var entries: Array=game_observations.get(String(id),[])
	if saved in entries: return
	entries.append(saved)
	while entries.size()>Workspace.MAX_RECEIPTS:
		var victim: int=1
		for index: int in range(1,entries.size()-1):
			if not entries[index].get("checkpoint",false): victim=index; break
		entries.remove_at(victim)
	game_observations[String(id)]=entries
	persistent_state_changed.emit()

func _restore_observations(value: Variant) -> void:
	if not value is Dictionary: return
	var catalog := LocalityLevelCatalogType.new()
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
