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
	var workspace: HSplitContainer = scene.find_child("WorkspaceSplit",true,false)
	check(workspace != null and workspace.split_offset == 40,"Evidence pane is not collapsed by a fixed oversized offset")
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
	check(scene.history_list.is_selected(0),"Selected record is also selected in the visible history list")
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
	check(scene.recorded_plan_label.text.contains("与草稿一致"),"Recorded source is labeled before inspecting its cache")
	scene.edit_plan(Model.represent(scene.plan,0,"rle"))
	check(scene.recorded_plan_label.text.contains("与当前草稿不同"),"Editing highlights that evidence belongs to the old plan")
	var cache_view: Dictionary = player.cache_evidence()
	check(cache_view.cache_before.used_bytes == 0 and cache_view.cache_after.used_bytes == 64,"Consumption shows actual before/after decoded cache occupancy")
	cache_view.cache_after.used_bytes = 1
	check(player.cache_evidence().cache_after.used_bytes == 64,"Cache visualization returns defensive evidence copies")
	player.seek(0)
	check(not player.cache_evidence().has("cache_after"),"Request without an after snapshot does not invent one")
	player.configure([],false); player.toggle_play(); player.step()
	check(player.cache_evidence().is_empty(),"Empty recording has no speculative cache state")
	check(not player.playing and player.current == -1,"Empty recordings cannot fabricate events")
	scene.change_task(2)
	scene.plan = Model.represent(Model.initial_plan(),0,"rle")
	scene.run_current()
	check(scene.order_choice.selected == 1,"A new failed comparison opens the first unmet order")
	check(scene.order_choice.get_item_text(0).begins_with("[达标]"),"Successful order remains individually identifiable")
	check(scene.order_choice.get_item_text(1).begins_with("[未达标]"),"Unmet order is visibly named")
	check(not scene.completed[2],"Showing a successful sub-order never completes the task")
	for i: int in scene.trace_player.recorded_events.size():
		if scene.trace_player.recorded_events[i].kind == "consume":
			scene.trace_player.seek(i)
			check(scene.trace_player.cache_evidence().cache_after.used_bytes == 0,"Oversized decoded block is not drawn as retained")
			break
	scene.queue_free(); await process_frame
	print("PASS: test_representation_visual " if failures == 0 else "FAIL: test_representation_visual ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
