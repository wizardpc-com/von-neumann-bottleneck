extends Node
signal progression_changed
signal persistent_state_changed
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
var game_distance_bonus: Dictionary = {}
var game_routes: Dictionary = {}
var test_routes: Dictionary = {}
var game_solutions: Dictionary = {}
var game_drafts: Dictionary = {}
var test_solutions: Dictionary = {}
var test_drafts: Dictionary = {}

func chapter_unlocked() -> bool:
	return GameMode.is_test_mode() or bool(LocalityChapter.completed_levels().get(&"capstone", false))

func completed() -> Dictionary:
	return test_solutions if GameMode.is_test_mode() else game_solutions

func drafts() -> Dictionary:
	return test_drafts if GameMode.is_test_mode() else game_drafts

func store_draft(id: String, board: Dictionary, program: String) -> void:
	if not Catalog.IDS.has(id): return
	drafts()[id] = {"board": board.duplicate(true), "program": program}
	if not GameMode.is_test_mode(): persistent_state_changed.emit()

func record_pass(id: String, board: Dictionary, program: String) -> bool:
	if not Catalog.unlocked(id, completed(), chapter_unlocked(), GameMode.is_test_mode()): return false
	var report: Dictionary = Catalog.evaluate(id,board,program)
	if not report.passed: return false
	if id == "distance" and not GameMode.is_test_mode() and Catalog.no_repeated_transfer(report):
		game_distance_bonus = {"board":board.duplicate(true),"program":program}
	if id == "synthesis":
		var route: String = Catalog.executed_route(report,board)
		if not route.is_empty():
			(game_routes if not GameMode.is_test_mode() else test_routes)[route] = {"board":board.duplicate(true),"program":program}
	completed()[id] = {"board": board.duplicate(true), "program": program}
	progression_changed.emit()
	if not GameMode.is_test_mode(): persistent_state_changed.emit()
	return true

func game_snapshot() -> Dictionary:
	return {"schema_version": 1, "solutions": game_solutions.duplicate(true), "drafts": game_drafts.duplicate(true), "routes":game_routes.duplicate(true),"distance_bonus":game_distance_bonus.duplicate(true)}

func restore_game(snapshot: Dictionary, ready: bool) -> void:
	game_solutions.clear()
	game_routes.clear()
	game_distance_bonus.clear()
	game_drafts.clear()
	if int(snapshot.get("schema_version", 0)) == 1:
		for field: String in ["solutions", "drafts"]:
			if not snapshot.get(field) is Dictionary: continue
			for id: String in Catalog.IDS:
				var value: Variant = snapshot[field].get(id)
				if not valid_solution_shape(value): continue
				var normalized: Dictionary = value.duplicate(true)
				for wire: Array in normalized.board.wires:
					wire[1] = int(wire[1])
					wire[3] = int(wire[3])
				if field == "drafts": game_drafts[id] = normalized
				elif Catalog.unlocked(id, game_solutions, ready) and Catalog.evaluate(id, value.board, value.program).passed:
					game_solutions[id] = normalized
	if game_solutions.has("distance"):
		for value: Variant in [snapshot.get("distance_bonus",{}),game_solutions.distance]:
			if valid_solution_shape(value) and Catalog.no_repeated_transfer(Catalog.evaluate("distance",value.board,value.program)):
				game_distance_bonus = value.duplicate(true)
	if game_solutions.has("synthesis"):
		var candidates: Array = [game_solutions.synthesis]
		if snapshot.get("routes") is Dictionary: candidates.append_array(snapshot.routes.values())
		for value: Variant in candidates:
			if not valid_solution_shape(value): continue
			var route: String = Catalog.executed_route(Catalog.evaluate("synthesis",value.board,value.program),value.board)
			if not route.is_empty(): game_routes[route] = value.duplicate(true)
	progression_changed.emit()

static func valid_solution_shape(value: Variant) -> bool:
	if not value is Dictionary or not value.get("board") is Dictionary or not value.get("program") is String: return false
	if value.program.length() > 16000: return false
	var board: Dictionary = value.board
	if not board.get("nodes") is Dictionary or not board.get("wires") is Array: return false
	if board.nodes.size() > 8 or board.wires.size() > 40: return false
	for id: Variant in board.nodes:
		if typeof(id) not in [TYPE_STRING, TYPE_STRING_NAME] or String(id).is_empty() or String(id).length() > 24: return false
		if String(id).validate_node_name() != String(id): return false
		var node: Variant = board.nodes[id]
		if not node is Dictionary or not node.get("kind") is String: return false
		for field: String in ["x", "y", "capacity"]:
			if node.has(field) and typeof(node[field]) not in [TYPE_INT, TYPE_FLOAT]: return false
			if node.has(field) and (not is_finite(float(node[field])) or absf(float(node[field])) > 100000): return false
	for wire: Variant in board.wires:
		if not wire is Array or wire.size() != 4: return false
		if not wire[0] is String or not wire[2] is String: return false
		if typeof(wire[1]) not in [TYPE_INT, TYPE_FLOAT] or typeof(wire[3]) not in [TYPE_INT, TYPE_FLOAT]: return false
		if not board.nodes.has(wire[0]) or not board.nodes.has(wire[2]): return false
		for index: int in [1,3]:
			if not is_finite(float(wire[index])) or float(wire[index]) != float(int(wire[index])) or int(wire[index]) < 0 or int(wire[index]) > 2: return false
	return true


func bonus_status(id: String) -> Dictionary:
	if id == "synthesis":
		var routes: Dictionary = test_routes if GameMode.is_test_mode() else game_routes
		return {"complete":routes.has("buffer") and routes.has("cache"),"count":routes.size()}
	if id == "distance" and not GameMode.is_test_mode() and not game_distance_bonus.is_empty(): return {"complete":true}
	if id == "distance" and completed().has(id):
		var value: Dictionary = completed()[id]
		return {"complete":Catalog.no_repeated_transfer(Catalog.evaluate(id,value.board,value.program))}
	return {"complete":false}

func copy_previous(id: String) -> bool:
	var source: String = {"backpressure":"buffers","distance":"prefetch"}.get(id,"")
	if source.is_empty() or not completed().has(source) or drafts().has(id): return false
	if not Catalog.unlocked(id,completed(),chapter_unlocked(),GameMode.is_test_mode()): return false
	var value: Dictionary = completed()[source]
	store_draft(id,value.board,value.program)
	return true
