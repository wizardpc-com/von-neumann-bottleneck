extends SceneTree
const Board = preload("res://experiments/representation_region/byte_board.gd")
const Player = preload("res://experiments/representation_region/trace_player.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var failures: int = 0
var checks: int = 0
var chosen: int = -1
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	var board = Board.new(); root.add_child(board); board.size = Vector2(530,128)
	var data: Array[int] = Model.asset(0)
	var plan: Array[Dictionary] = Model.split(Model.initial_plan(),0,17)
	board.configure(data,plan,0)
	board.block_selected.connect(func(index: int) -> void: chosen = index)
	await process_frame
	for i: int in 64:
		check(board.address_at(board.cell_rect(i).get_center()) == i,"Address-to-cell mapping is exact")
		check(Rect2(Vector2.ZERO,board.size).encloses(board.cell_rect(i)),"Byte fits the narrow editor")
	check(board.address_at(Vector2(-1,0)) == -1,"Outside input rejected")
	check(board.block_at(16) == 0 and board.block_at(17) == 1,"Non-row-aligned partition respected")
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.position = board.cell_rect(20).get_center()
	board._gui_input(event); check(chosen == 1,"Byte click selects corresponding partition")
	check(plan[0].end == 17 and data == Model.asset(0),"View does not mutate authored bytes or draft")
	data[0] = 255; plan[0].end = 15
	check(board.values[0] != 255 and board.partitions[0].end == 17,"Board owns a defensive copy")
	var requests: Array = [20,43,20,43,20,43]
	board.set_requests(requests); requests.clear()
	check(board.request_counts == {20:3,43:3},"Public request repetitions are exact and independently owned")
	board.set_requests([]); check(board.request_counts.is_empty(),"No-request mode clears old markers")
	board.queue_free(); await process_frame
	var scene = load("res://experiments/representation_region/region.tscn").instantiate(); root.add_child(scene); await process_frame
	check(scene.byte_boards.size() == 1 and scene.byte_boards[0].values == Model.asset(0),"Single asset view shows actual task bytes")
	scene.change_task(4); await process_frame
	check(scene.byte_boards.size() == 2,"Cross-asset task shows both public assets")
	check(scene.byte_boards[0].values != scene.byte_boards[1].values,"Different assets are not silently reused")
	scene.preview_order = 2; scene.refresh_request_preview()
	check(scene.byte_boards[0].request_counts.is_empty(),"Asset B request preview does not mark Asset A")
	check(scene.byte_boards[1].request_counts == {4:3,59:3},"Paired task marks the correct asset only")
	scene.change_task(1); scene.preview_order = 1; scene.refresh_request_preview()
	check(scene.byte_boards[0].request_counts == {20:3,43:3},"Hotspots expose public request locations without solving partitions")
	check(scene.history.is_empty(),"Request preview does not fabricate a run")
	scene.change_task(0); scene.run_current(); await process_frame
	var signature: String = scene.history[0].traces[0].canonical_signature()
	var player = scene.trace_player
	check(player.current == -1 and not player.playing,"Recorded playback starts paused")
	player.step()
	check(player.current == 0,"Step visits the actual first event")
	var original_kind: String = str(scene.history[0].traces[0].events[0].kind)
	check(player.recorded_events[0].kind == original_kind,"Playback event is copied from Trace")
	player.toggle_play(); player._process(1.0)
	check(player.current == 1,"Playback advances recorded event order")
	ProjectSettings.set_setting("game/reduced_motion",true)
	player.step(); player.queue_redraw(); await process_frame
	check(not player.playing and player.current == 2,"Static stepping remains usable with reduced motion")
	ProjectSettings.set_setting("game/reduced_motion",false)
	check(scene.history[0].traces[0].canonical_signature() == signature,"Animation never mutates simulation evidence")
	player.configure([],false); player.toggle_play(); player.step()
	check(not player.playing and player.current == -1,"Empty recordings cannot fabricate events")
	scene.queue_free(); await process_frame
	print("PASS: test_representation_visual " if failures == 0 else "FAIL: test_representation_visual ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
