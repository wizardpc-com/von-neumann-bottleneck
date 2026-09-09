extends SceneTree
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")

var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var host: Control = load("res://src/overlap_chapter/overlap_chapter.tscn").instantiate()
	root.add_child(host)
	for _i: int in range(4): await process_frame
	_assert(host.map_view.level_buttons.size() == 6 and host.map_view.dependency_edges().size() == 6,"Chapter must expose the six-node fork and merge.")
	for id: String in Catalog.IDS:
		host._open_level(id)
		for _frame: int in range(5): await process_frame
		_assert(host.editor.text == Catalog.starter(id), "New level starts with the published starter, not a silently applied answer.")
		var original: String = JSON.stringify(host.board)
		host._advance_hint()
		await process_frame
		_assert(JSON.stringify(host.board) == original and host.hint_level==1, "H1 must remain separate from player topology.")
		host.hint_overlay.queue_free();host.hint_overlay=null
		var answer: Dictionary = Catalog.reference_solution(id)
		host.board = answer.board.duplicate(true)
		host._render_board(host.graph,host.board,false)
		host.editor.text = answer.program
		host._run_official()
		_assert(root.get_node("OverlapChapter").completed().has(id), "Official UI run must award real completed solutions: "+id)
		for _frame: int in range(5): await process_frame
		_assert(host.panels.trace.size.y <= host.workspace.size.y, "Timeline must fit the work area after metrics and event rows are populated.")
		host.completion.dismiss()
		var signature: String = host.trace.canonical_signature()
		host.scrub.value = 0
		_assert(signature==host.trace.canonical_signature(), "Timeline seeking must never recompute or change simulation.")
		if id=="buffers":
			host._delete_part(&"A")
			_assert(not host.board.nodes.has("A"), "Completion must retain editing.")
			host._undo()
			host._delete_part(&"A")
			host.armed="buffer"
			host.graph.component_drop_requested.emit("buffer",Vector2(450,250))
			_assert(host.armed.is_empty(),"A completed palette drag must be one-shot, not leave repeat placement armed.")
			host.armed="buffer"
			host.editor.grab_focus()
			await process_frame
			_assert(host.armed.is_empty(),"Typing focus must cancel component placement without changing the program.")
			host._undo()
			host._undo()
			_assert(host.board.nodes.has("A"), "Undo restores deleted buffer and its connections.")
	var state_script = load("res://src/overlap_chapter/overlap_state.gd")
	var save = state_script.new()
	root.add_child(save)
	var solutions: Dictionary = {}
	for id: String in Catalog.IDS: solutions[id] = Catalog.reference_solution(id)
	save.restore_game({"schema_version":1,"solutions":solutions,"drafts":solutions},true)

	_assert(save.game_solutions.size()==6,"Restart revalidates every saved solution and branch prerequisite.")
	solutions.arrival.program = "fetch A 0\nconsume A"
	save.restore_game({"schema_version":1,"solutions":solutions,"drafts":solutions},true)
	_assert(save.game_solutions.is_empty() and save.game_drafts.size()==6,"Invalid root cannot unlock descendants; preserve editable drafts.")
	_assert(not state_script.valid_solution_shape({"board":{"nodes":[],"wires":[]},"program":""}),"Malformed saved shapes are rejected without script exceptions.")
	save.queue_free()
	host.queue_free()
	await process_frame
	if failures.is_empty():print("PASS: Chapter 3 topology, hints, timeline, editable completion and revalidated persistence")
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
func _assert(condition: bool,message: String) -> void:
	if not condition: failures.append(message)
