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
		_assert(host.panels.toolbox.visible and not host.panels.program.visible, "Entry shows available parts without opening all instruction tools: "+id)
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
			var old_board: Dictionary = host.board.duplicate(true)
			var original_wire: Array = host.board.wires[0]
			var wire_info: Dictionary = {"from_node":original_wire[0],"from_port":original_wire[1],"to_node":original_wire[2],"to_port":original_wire[3]}
			var history_size: int = host.undo_stack.size()
			host._move_wire_endpoint(wire_info,&"missing_node",0)
			_assert(host.board==old_board and host.undo_stack.size()==history_size,"Rejected endpoint drag keeps the original wire and history.")
			var destination: StringName = &"B" if original_wire[2]=="A" else &"A"
			host._move_wire_endpoint(wire_info,destination,int(original_wire[3]))
			_assert(host.undo_stack.size()==history_size+1,"Endpoint move is one edit transaction.")
			host._undo()
			_assert(host.board==old_board,"One undo restores the complete endpoint move.")
			for frame: int in range(5): await process_frame
			var buffer: GraphNode = host.graph.get_node("A")
			_assert(host.graph._node_at(host.graph.displayed_node_rect(buffer).get_center()) == &"A", "Full-card modules must support body selection and erasing, not become empty marquee space.")
			for panel: Control in host.panels.values(): panel.hide()
			var start: Vector2 = buffer.position_offset
			var pointer: Vector2 = host.graph.get_global_transform_with_canvas() * host.graph.displayed_node_rect(buffer).get_center()
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = pointer
			_assert(host._handle_body_drag(press), "Card-body press must begin an editable move.")
			var motion := InputEventMouseMotion.new()
			motion.position = pointer + Vector2(120,80)
			host._handle_body_drag(motion)
			host._save_draft()
			_assert(Vector2(host.board.nodes.A.x,host.board.nodes.A.y).is_equal_approx(start), "Autosave must not commit a still-held gesture into its undo baseline.")
			var release := InputEventMouseButton.new()
			release.button_index = MOUSE_BUTTON_LEFT; release.position = motion.position
			host._handle_body_drag(release)
			_assert(not buffer.position_offset.is_equal_approx(start), "Captured Mac motion with an omitted button mask must still move the pressed card.")
			host._undo()
			_assert(host.graph.get_node("A").position_offset.is_equal_approx(start), "One undo restores the whole body move.")
			host._handle_body_drag(press)
			host._handle_body_drag(motion)
			host.armed = "buffer"
			root.focus_exited.emit()
			_assert(host.body_drag.is_empty() and host.armed.is_empty(), "Window focus loss must cancel both a held move and armed placement.")
			_assert(host.graph.get_node("A").position_offset.is_equal_approx(start), "Focus cancellation restores the uncommitted card position.")
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
	await _test_copy_previous(host)
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

func _test_copy_previous(host: Control) -> void:
	var state: Node = root.get_node("OverlapChapter")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for id: String in ["backpressure", "distance"]:
			host._show_map()
			state.test_drafts.erase(id)
			host._open_level(id)
			await process_frame
			_assert(not host.copy_previous_button.disabled and not host.copy_previous_note.visible, "Copy starts enabled for a compatible solution with no draft: "+id)
			host._run_official()
			_assert(host.copy_previous_button.disabled and host.copy_previous_note.visible, "Running the starter immediately disables copy with a reason: "+id)
			var saved: Dictionary = state.drafts()[id].duplicate(true)
			var program: String = host.editor.text
			var live_board: Dictionary = host.board.duplicate(true)
			for repeat: int in range(2): host.copy_previous_button.pressed.emit()
			_assert(state.drafts()[id] == saved and host.editor.text == program and host.board == live_board, "Repeated stale copy actions cannot overwrite an existing draft: "+id)
			_assert(host.status.text == host.copy_previous_note.text and not host.status.text.begins_with("overlap."), "Refused copy reports a localized reason: "+id)
			host._show_map()
			state.test_drafts.erase(id)
			host._open_level(id)
			await process_frame
			host._delete_part(&"A" if id == "backpressure" else &"CACHE")
			live_board = host.board.duplicate(true)
			host.copy_previous_button.pressed.emit()
			_assert(host.copy_previous_button.disabled and host.board == live_board and not state.drafts().has(id), "Unsaved hardware edits are protected before autosave: "+id)
			host.editor.text += "\n# unsaved edit"
			host._changed(false)
			host.copy_previous_button.pressed.emit()
			_assert(host.copy_previous_button.disabled and host.editor.text.ends_with("# unsaved edit") and not state.drafts().has(id), "Unsaved edits are protected before autosave: "+id)
			host._show_map()
			state.test_drafts.erase(id)
			host._open_level(id)
			await process_frame
			var source: String = "buffers" if id == "backpressure" else "prefetch"
			var previous: Dictionary = state.completed()[source].duplicate(true)
			state.test_solutions.erase(source)
			host.copy_previous_button.pressed.emit()
			_assert(host.copy_previous_button.disabled and not state.drafts().has(id) and host.status.text == host.copy_previous_note.text, "Missing previous solution produces honest refusal feedback: "+id)
			state.test_solutions[source] = previous
			host._refresh_copy_previous()
			host.copy_previous_button.pressed.emit()
			await process_frame
			_assert(host.editor.text == previous.program and state.drafts()[id].program == previous.program, "Valid copy installs the player's previous program: "+id)
			_assert(host.copy_previous_button.disabled and state.completed()[source] == previous and host.board.nodes.keys() == previous.board.nodes.keys() and host.board.wires == previous.board.wires, "Successful copy disables repeat copy and preserves source: "+id)
			host._open_level("arrival")
			_assert(host.copy_previous_button == null, "Navigating to an unrelated node drops stale controls")
			host._open_level(id)
			_assert(host.copy_previous_button.disabled and host.copy_previous_note.visible, "Reopening saved task preserves disabled state: "+id)
