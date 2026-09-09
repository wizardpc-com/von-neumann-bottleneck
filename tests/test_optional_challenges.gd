extends SceneTree
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var buffer: Dictionary = Catalog.reference_solution("synthesis")
	var cache: Dictionary = {"board":Catalog.cache_board(),"program":Catalog.cache_program()}
	check(Catalog.executed_route(Catalog.evaluate("synthesis",buffer.board,buffer.program),buffer.board) == "buffer","Actual compute input must classify the buffer route")
	check(Catalog.executed_route(Catalog.evaluate("synthesis",cache.board,cache.program),cache.board) == "cache","Actual compute input must classify the cache route")
	var unused: Dictionary = cache.board.duplicate(true)
	unused.nodes.A = {"kind":"buffer"}
	check(Catalog.executed_route(Catalog.evaluate("synthesis",unused,cache.program),unused) == "cache","An idle buffer cannot earn the buffer route")
	check(Catalog.no_repeated_transfer(Catalog.evaluate("distance",cache.board,cache.program)),"Timely single-line prefetch uses each transfer once")
	check(not Catalog.no_repeated_transfer(Catalog.evaluate("distance",Catalog.seed("distance"),Catalog.starter("distance"))),"Eviction and refetch starter cannot earn the bonus")
	var state: Node = root.get_node("OverlapChapter")
	var previous: Dictionary = {"board":Catalog.buffer_board(2),"program":Catalog.buffer_program()}
	state.game_solutions["buffers"] = previous.duplicate(true)
	state.game_solutions["arrival"] = Catalog.reference_solution("arrival")
	root.get_node("LocalityChapter").game_completed[&"capstone"] = true
	check(state.copy_previous("backpressure"),"An unopened compatible task can start from the player's earlier solution")
	check(state.game_drafts.backpressure == previous and not state.game_solutions.has("backpressure"),"Copying keeps the source and does not copy completion")
	state.game_drafts.backpressure.program += "# own new attempt"
	check(state.game_solutions.buffers == previous and not state.copy_previous("backpressure"),"An existing destination is never silently overwritten")
	state.game_solutions["backpressure"] = previous
	state.game_solutions["prefetch"] = cache
	state.game_solutions["distance"] = cache
	check(state.record_pass("synthesis",buffer.board,buffer.program),"First valid route passes")
	check(not state.bonus_status("synthesis").complete,"One route is not two")
	check(state.record_pass("synthesis",cache.board,cache.program) and state.bonus_status("synthesis").complete,"Both passing player routes remain available")
	var snapshot: Dictionary = state.game_snapshot()
	state.restore_game(snapshot,true)
	check(state.bonus_status("synthesis").complete,"Restoration revalidates both stored routes")
	snapshot.routes.buffer.program = "consume A"
	state.restore_game(snapshot,true)
	check(not state.bonus_status("synthesis").complete,"An invalid archived route loses its badge after revalidation")
	var locality: Node = root.get_node("LocalityChapter")
	var design: Dictionary = {"source":preload("res://src/simulation/program_templates.gd").ROW_FIRST,"cache_lines":1,"passes":2,"blocks":1,"bypass":false}
	check(locality.qualifies_economical(design),"Actual 138-cycle cost-4 blocking route qualifies")
	design.passes = 1
	check(not locality.qualifies_economical(design),"Removing one required pass cannot earn economical badge")
	for failure: String in failures: push_error(failure)
	print("PASS: optional challenges, executed routes, safe copying and recovery" if failures.is_empty() else "FAIL: optional challenges")
	quit(0 if failures.is_empty() else 1)
