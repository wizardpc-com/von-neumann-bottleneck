extends Node
signal progression_changed
signal persistent_state_changed
const C = preload("res://src/layout_chapter/layout_catalog.gd")
const S = preload("res://src/layout_chapter/layout_simulator.gd")
var game_solutions: Dictionary = {}
var game_drafts: Dictionary = {}
var game_named: Dictionary = {}
var test_solutions: Dictionary = {}
var test_drafts: Dictionary = {}
var test_named: Dictionary = {}

func chapter_unlocked() -> bool:
	return GameMode.is_test_mode() or bool(LocalityChapter.completed_levels().get(&"capstone",false))
func completed() -> Dictionary: return test_solutions if GameMode.is_test_mode() else game_solutions
func drafts() -> Dictionary: return test_drafts if GameMode.is_test_mode() else game_drafts
func named() -> Dictionary: return test_named if GameMode.is_test_mode() else game_named
func store_draft(id: String, design: Dictionary) -> bool:
	if not valid(id,design): return false
	drafts()[id] = normalize(design)
	_changed()
	return true
func save_named(id: String, title: String, design: Dictionary) -> bool:
	if title.strip_edges().is_empty() or title.length()>40 or not valid(id,design): return false
	if not named().has(id): named()[id] = {}
	if named()[id].size()>=24 and not named()[id].has(title): return false
	named()[id][title] = normalize(design)
	_changed()
	return true
func record_pass(id: String, design: Dictionary) -> bool:
	if not C.unlocked(id,completed(),chapter_unlocked(),GameMode.is_test_mode()) or not valid(id,design): return false
	var report: Dictionary = C.evaluate(id,design)
	if not report.passed: return false
	# Keep the best real total, re-evaluating saved designs with the same model.
	if not completed().has(id) or cost(report)<cost(C.evaluate(id,completed()[id])): completed()[id] = normalize(design)
	progression_changed.emit()
	_changed()
	return true
static func cost(report: Dictionary) -> int:
	var total: int = 0
	for run: LayoutRun in report.runs: total += int(run.metrics.total_cycles)
	return total
static func valid(id: String, value: Variant) -> bool:
	if id not in C.IDS or not value is Dictionary: return false
	if JSON.stringify(value).length()>12000: return false
	if not S.validate_design(value,id in ["fields","records","hot_cold"]).is_empty(): return false
	if id == "relocation" and value.has("orders"):
		if not value.orders is Dictionary or value.orders.size()>2: return false
		for key: Variant in value.orders:
			if key not in ["A","B"] or not value.orders[key] is Dictionary or not S.validate_design(value.orders[key],false).is_empty(): return false
	return true
static func normalize(value: Dictionary) -> Dictionary:
	var result: Dictionary = S.normalized_design(value)
	if value.has("orders"):
		result["orders"] = {}
		for key: String in value.orders: result.orders[key] = S.normalized_design(value.orders[key])
	return result
func game_snapshot() -> Dictionary:
	return {"schema_version":1,"model_version":S.MODEL_VERSION,"solutions":game_solutions.duplicate(true),"drafts":game_drafts.duplicate(true),"named":game_named.duplicate(true)}
func restore_game(snapshot: Dictionary, ready: bool) -> void:
	game_solutions.clear(); game_drafts.clear(); game_named.clear()
	if int(snapshot.get("schema_version",0)) == 1:
		for id: String in C.IDS:
			var draft: Variant = snapshot.get("drafts",{}).get(id) if snapshot.get("drafts",{}) is Dictionary else null
			if valid(id,draft): game_drafts[id] = normalize(draft)
			var solution: Variant = snapshot.get("solutions",{}).get(id) if snapshot.get("solutions",{}) is Dictionary else null
			if valid(id,solution) and C.unlocked(id,game_solutions,ready) and C.evaluate(id,solution).passed: game_solutions[id] = normalize(solution)
			var saved: Variant = snapshot.get("named",{}).get(id,{}) if snapshot.get("named",{}) is Dictionary else {}
			if saved is Dictionary:
				for title: Variant in saved:
					if not title is String or title.is_empty() or title.length()>40 or not valid(id,saved[title]): continue
					if not game_named.has(id): game_named[id] = {}
					if game_named[id].size()<24: game_named[id][title] = normalize(saved[title])
	progression_changed.emit()
func _changed() -> void:
	if not GameMode.is_test_mode(): persistent_state_changed.emit()
