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
	scene.change_task(3)
	scene.plan = Model.initial_plan(); scene.refresh_plan(); scene.run_current()
	var prepare_index: int = scene.selected_run
	var prepare_signature: String = scene.history[prepare_index].traces[0].canonical_signature()
	var comparison_root: TreeItem = scene.order_comparison.get_root()
	check(comparison_root.get_child_count() == 2,"Preparation comparison exposes both independent orders together")
	for i: int in 2:
		var measured: Dictionary = scene.history[prepare_index].traces[i].metrics
		var compared: TreeItem = comparison_root.get_child(i)
		check(compared.get_text(1) == str(measured.preparation_cycles) and compared.get_text(2) == str(measured.service_cycles),"Comparison uses authoritative preparation and service costs")
		check(compared.get_text(3) == str(measured.stored_bytes),"Actual storage includes retained source rather than logical representation")
	scene.order_choice.select(0); scene.show_trace(0)
	check(scene.result.text.contains("实际空间 68B") and scene.result.text.contains("保留源64B"),"RAW preparation shows actual source-plus-directory storage")
	check(not scene.trace_details_group.visible,"Event and cost details start collapsed")
	var toggle: Button = scene.find_child("ToggleTraceDetails",true,false)
	toggle.pressed.emit()
	check(scene.trace_details_group.visible and scene.metric_details.text.contains("准备读0B / 写4B"),"Expanded preparation detail exposes exact read/write evidence")
	check(scene.history[prepare_index].traces[0].canonical_signature() == prepare_signature,"Expanding details leaves the immutable recording unchanged")
	scene.english = true; scene.build()
	check(scene.result.text.contains("Actual storage") and scene.metric_details.text.contains("Logical representation"),"Preparation metrics and scope are bilingual")
	check(scene.trace_details_group.visible,"Detail expansion survives a locale rebuild")
	scene.change_task(4)
	scene.plan = Model.represent(Model.initial_plan(),0,"rle"); scene.refresh_plan(); scene.run_current()
	var paired_index: int = scene.selected_run
	var paired_signature: String = scene.history[paired_index].traces[0].canonical_signature()
	check(scene.draft_label.text.contains("Asset A") and scene.draft_label.text.contains("Asset B"),"Draft storage compares both assets under the same plan")
	comparison_root = scene.order_comparison.get_root()
	check(comparison_root.get_child_count() == 2,"Cross-asset recorded comparison keeps both asset orders visible")
	for i: int in 2:
		var measured: Dictionary = scene.history[paired_index].traces[i].metrics
		var compared: TreeItem = comparison_root.get_child(i)
		check(compared.get_text(0).contains(measured.spec.name),"Comparison identifies the actual asset order")
		check(compared.get_text(3) == str(measured.stored_bytes) and compared.get_text(4) == str(measured.traffic_bytes),"Cross-asset costs come from each distinct Trace")
	comparison_root.get_child(1).select(0); scene.order_comparison.item_selected.emit()
	check(scene.order_choice.selected == 1 and scene.visible_trace == scene.history[paired_index].traces[1],"Choosing Asset B comparison opens its own recorded Trace")
	check(scene.result.text.contains("Asset B revisits"),"Selected primary costs name the compared asset order")
	scene.edit_plan(Model.represent(scene.plan,0,"raw"))
	check(scene.recorded_plan_label.text.contains("immutable measured evidence") and scene.recorded_plan_label.text.contains("differs from current draft"),"Record authority and changed draft remain explicit in English")
	check(scene.history[paired_index].traces[0].canonical_signature() == paired_signature,"Draft changes preserve paired measured evidence")
	scene.select_run(paired_index)
	check(scene.order_choice.selected == 0 and scene.order_choice.get_item_text(0).contains("Unmet"),"Reopening a failed recording selects the first unmet order")
	# Real preparation records stay comparable across visits to another task.
	scene.change_task(3)
	scene.edit_plan(Model.represent(Model.split(Model.initial_plan(),0,8),1,"rle"))
	scene.run_current()
	var revised_index: int = scene.selected_run
	var revised: Dictionary = scene.history[revised_index].traces[0].metrics
	var earlier: Dictionary = scene.history[prepare_index].traces[0].metrics
	var found: Dictionary = scene.prior_comparable_trace(revised_index,revised.spec)
	check(int(found.get("run_index",-1)) == prepare_index and found.get("trace") == scene.history[prepare_index].traces[0],"Comparison finds the preceding same-task/order recording across an intervening asset task")
	scene.show_trace(0)
	check(scene.metric_details.text.contains("run #%d → #%d" % [prepare_index+1,revised_index+1]),"Comparison names both immutable source recordings")
	check(scene.metric_details.text.contains("prepare%+d, serve%+d, total%+d cycles" % [int(revised.preparation_cycles)-int(earlier.preparation_cycles),int(revised.service_cycles)-int(earlier.service_cycles),int(revised.total_cycles)-int(earlier.total_cycles)]),"Preparation/service/total deltas use actual measured costs")
	check(scene.metric_details.text.contains("Actual storage%+dB · service traffic%+dB · all-phase traffic%+dB" % [int(revised.stored_bytes)-int(earlier.stored_bytes),int(revised.traffic_bytes)-int(earlier.traffic_bytes),int(revised.total_traffic_bytes)-int(earlier.total_traffic_bytes)]),"Storage/service/all-phase traffic deltas keep their distinct scopes")
	scene.select_run(prepare_index); scene.show_trace(0)
	check(scene.prior_comparable_trace(prepare_index,earlier.spec).is_empty(),"Selecting an older first recording never uses a future matching recording")
	check(scene.metric_details.text.contains("No earlier same-task, same-spec"),"Absent earlier comparison is explicit in English")
	check(scene.prior_comparable_trace(-1,earlier.spec).is_empty() and scene.prior_comparable_trace(scene.history.size(),earlier.spec).is_empty(),"Invalid recording indices cannot inspect unrelated history")
	var altered_spec: Dictionary = earlier.spec.duplicate(true); altered_spec.latency += 1
	check(scene.prior_comparable_trace(revised_index,altered_spec).is_empty(),"Same order name with a different machine is not comparable")
	# A recorded changed machine and a differently tagged task must be skipped.
	var changed_traces: Array = []
	for spec: Dictionary in Model.orders(3):
		var changed: Dictionary = spec.duplicate(true); changed.latency += 1
		changed_traces.append(Model.run(changed,scene.plan))
	scene.history.append({"task":3,"plan":scene.plan.duplicate(true),"traces":changed_traces,"accepted":false})
	scene.history.append({"task":4,"plan":scene.plan.duplicate(true),"traces":scene.history[revised_index].traces.duplicate(),"accepted":false})
	var signatures: Array[String] = []
	for record: Dictionary in scene.history:
		for trace: RefCounted in record.traces: signatures.append(trace.canonical_signature())
	scene.run_current()
	var latest_index: int = scene.selected_run
	found = scene.prior_comparable_trace(latest_index,revised.spec)
	check(int(found.get("run_index",-1)) == revised_index,"Nearest earlier match skips changed complete specs and different task IDs")
	scene.english = false; scene.build(); scene.show_trace(0)
	check(scene.metric_details.text.contains("比较来源：记录#%d → #%d" % [revised_index+1,latest_index+1]) and scene.metric_details.text.contains("全阶段搬运"),"Chinese comparison exposes source identity and all cost scopes")
	scene.select_run(prepare_index); scene.show_trace(0)
	check(scene.metric_details.text.contains("暂无更早的同任务、同规格"),"Absent earlier comparison is explicit in Chinese")
	var cursor: int = 0
	for record_index: int in latest_index:
		for trace: RefCounted in scene.history[record_index].traces:
			check(trace.canonical_signature() == signatures[cursor],"History comparison and locale rebuilding do not mutate any recorded Trace")
			cursor += 1
	check(scene.history[prepare_index].traces[0].canonical_signature() == prepare_signature and scene.history[paired_index].traces[0].canonical_signature() == paired_signature,"Original preparation and cross-asset evidence remain intact")
	scene.queue_free(); await process_frame
	print("PASS: test_representation_visual " if failures == 0 else "FAIL: test_representation_visual ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
