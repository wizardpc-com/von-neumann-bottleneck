extends SceneTree
## Native capture: -- --workbench-capture --capture-size=1280x720 (existing deterministic window path).
## Fixed operations stay usable while authored assets and recorded evidence grow.
const Model = preload("res://experiments/representation_region/model.gd")
class WorkbenchProbe extends "res://experiments/representation_region/region.gd":
	var departures: int = 0
	func finish_leave() -> void: departures += 1

var checks: int = 0
var failures: int = 0
var capture: bool = false
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func fit_scene(scene: Control, dimensions: Vector2i) -> void:
	# Probe.new() needs the same root geometry as region.tscn. Apply it after ready,
	# when display preferences have had a chance to restore their own window mode.
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.grow_horizontal = Control.GROW_DIRECTION_BOTH
	scene.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.mode = Window.MODE_WINDOWED
	if capture: await create_timer(1.0).timeout
	root.size = dimensions; root.content_scale_size = dimensions
	if capture: await create_timer(0.4).timeout
	await settle()
	check(root.get_visible_rect().size.is_equal_approx(Vector2(dimensions)),"Viewport uses the requested logical workbench size")
	check(scene.get_global_rect().is_equal_approx(root.get_visible_rect()),"Probe root matches the full-rect workbench scene and viewport")
func button(scene: Node, id: String) -> Button: return scene.find_child(id,true,false) as Button
func fixed_controls(scene: Control, context: String) -> Dictionary:
	var rects: Dictionary = {}
	var viewport: Rect2 = root.get_visible_rect()
	check(scene.get_global_rect().is_equal_approx(viewport),context+": entire workbench matches the viewport")
	for id: String in ["Blocks","SplitAt","Split","Merge","Raw","RLE","Undo","Redo","Run","SaveSession","DraftSummary","FeedbackScroll"]:
		var control := scene.find_child(id,true,false) as Control
		check(control != null and control.is_visible_in_tree(),context+": fixed operation is present: "+id)
		if control == null: continue
		var rect: Rect2 = control.get_global_rect(); rects[id] = rect
		check(rect.size.x > 0 and rect.size.y > 0 and viewport.encloses(rect),context+": fixed control fits viewport: "+id+" "+str(rect))
		var parent: Node = control.get_parent()
		var in_scroll: bool = false
		while parent != null and parent != scene:
			if parent is ScrollContainer: in_scroll = true
			parent = parent.get_parent()
		check(not in_scroll,context+": key operation is outside reading scroll containers: "+id)
		if control is Button:
			check(control.size.y >= 38 and not control.clip_text,context+": operation is readable and usable: "+id)
	for id: String in ["Run","SaveSession","Split","Merge","Raw","RLE","Undo","Redo"]:
		for other: String in ["Run","SaveSession","Split","Merge","Raw","RLE","Undo","Redo"]:
			if id >= other or not rects.has(id) or not rects.has(other): continue
			check(not (rects[id] as Rect2).intersects(rects[other]),context+": actions do not overlap: "+id+"/"+other)
	return rects
func check_unchanged_rects(before: Dictionary, after: Dictionary, context: String) -> void:
	for id: String in before:
		check(after.has(id) and (before[id] as Rect2).is_equal_approx(after[id]),context+": reading scrolls do not move fixed operations: "+id)
func check_costs(scene: WorkbenchProbe, context: String) -> void:
	var chart: Control = scene.find_child("MeasuredOrderCosts",true,false)
	var source := scene.find_child("MeasuredCostSource",true,false) as Label
	check(chart != null and source != null,context+": selected measured costs have a visible source and breakdown")
	if chart == null or source == null: return
	check(chart.get_parent().name == "RepresentationEvidence" and source.get_parent() == chart.get_parent(),context+": measured cost breakdown remains outside deep evidence scrolling")
	check(root.get_visible_rect().encloses(chart.get_global_rect()) and root.get_visible_rect().encloses(source.get_global_rect()),context+": compact costs and source fit the actual viewport")
	check(chart.size.y <= 140,context+": cost overview preserves evidence reading space")
	if scene.selected_run < 0:
		check(chart.measurements.is_empty(),context+": unrun draft has no fabricated zero-cost measurement")
		check(chart.english == scene.english and chart.selected_order == -1,context+": typed empty presentation is configured in the actual workbench language")
		return
	var record: Dictionary = scene.history[scene.selected_run]
	check(chart.measurements.size() == record.traces.size(),context+": all independent orders appear, without an invented combined score")
	for index: int in chart.measurements.size():
		var m: Dictionary = chart.measurements[index].metrics
		check(m == record.traces[index].metrics,context+": costs belong to the selected immutable trace, including its own asset and client count")
		var font: Font = chart.get_theme_font("font","Label")
		var equation: String = ("Prepare %d + serve %d = %d cycles" if scene.english else "准备%d + 服务%d = 总计%d周期") % [m.preparation_cycles,m.service_cycles,m.total_cycles]
		var bytes: String = ("Stored %dB · service traffic %dB" if scene.english else "空间%dB · 服务搬运%dB") % [m.stored_bytes,m.traffic_bytes]
		check(font.get_string_size(equation,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x <= chart.size.x-20 and font.get_string_size(bytes,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x <= chart.size.x-20,context+": complete costs fit their separate lines without clipping")
		if int(record.task) == 3:
			check(m.spec.online and m.preparation_cycles > 0 and m.source_storage_bytes == 64 and int(m.spec.clients) == (1 if index == 0 else 8),context+": preparation has one actual bill per order and retains64B source, with distinct client counts")
		elif int(record.task) == 4:
			check(m.spec.data == Model.orders(4)[index].data,context+": each asset keeps its own bytes and result under the shared plan")
func escape() -> void:
	var event := InputEventKey.new(); event.keycode = KEY_ESCAPE; event.physical_keycode = KEY_ESCAPE; event.pressed = true
	root.push_input(event,true); await process_frame
	event = InputEventKey.new(); event.keycode = KEY_ESCAPE; event.physical_keycode = KEY_ESCAPE
	root.push_input(event,true); await process_frame
func screenshot(name: String, size: Vector2i) -> void:
	if not capture: return
	RenderingServer.force_draw(false); await process_frame
	var image: Image = root.get_texture().get_image()
	check(image != null and image.get_size() == size,name+": actual capture dimensions match")
	if image == null: return
	var folder: String = "res://.godot/workbench-captures"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,name+": capture directory available")
	check(image.save_png(folder.path_join(name+".png")) == OK,name+": rendered frame saved")
func run() -> void:
	capture = "--workbench-capture" in OS.get_cmdline_user_args()
	if capture and DisplayServer.get_name() == "headless":
		check(false,"--workbench-capture requires rendering; ordinary headless runs do not capture")
		capture = false
	var localization: Node = root.get_node("Localization")
	var original_locale: String = localization.current_locale()
	var campaign: Node = root.get_node("GlobalSave")
	var campaign_before: Dictionary = campaign._save_snapshot(); campaign_before.erase("saved_at_utc")
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1600,900)]:
		if capture and dimensions != Vector2i(1280,720): continue
		root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
		await settle()
		for locale: String in ["zh_CN","en"]:
			localization.set_locale(locale)
			for task_index: int in 5:
				# Render both preparation and cross-asset use, with actual measured runs.
				if capture and task_index not in [3,4]: continue
				var scene := WorkbenchProbe.new(); root.add_child(scene); await settle()
				# Show persistent controls without claiming a disk profile or acquiring a writer.
				scene.persistent_session = true; scene.candidate_journey = true
				scene.build()
				scene.change_task(task_index); await settle()
				await fit_scene(scene,dimensions)
				check(scene.trace_player.english == scene.english and scene.trace_player.recorded_events.is_empty(),"Fresh empty replay uses the workbench language without inventing events")
				check(button(scene,"Run").get_theme_color("font_focus_color") == Color("071823") and button(scene,"SaveSession").get_theme_color("font_focus_color") == Color("071823"),"Primary keyboard focus keeps dark text on its bright surface")
				var context: String = locale+"-T%d-%dx%d" % [task_index+1,dimensions.x,dimensions.y]
				var capture_case: bool = capture and dimensions == Vector2i(1280,720) and task_index in [3,4]
				var capture_prefix: String = "representation-"+locale+("-prepare" if task_index == 3 else "")
				if capture_case:
					button(scene,"Run").grab_focus(); await settle()
					await screenshot(capture_prefix+"-initial",dimensions)
				var original_rects: Dictionary = fixed_controls(scene,context+"-initial")
				check_costs(scene,context+"-initial")
				check(scene.find_child("TaskPurpose",true,false) != null,context+": task purpose has its own visual hierarchy in the existing reading area")
				var reading := scene.find_child("EditorScroll",true,false) as ScrollContainer
				var evidence := scene.find_child("EvidenceScroll",true,false) as ScrollContainer
				check(reading.follow_focus and evidence.follow_focus,context+": keyboard reading follows focus in both columns")
				check(reading.size.x >= 530 and evidence.size.x >= 430,context+": existing usable column widths retained")
				check(scene.mission.get_parent().name == "TaskAssetReading" and scene.byte_boards.size() == (2 if task_index == 4 else 1),context+": full task and authored assets remain in the reading region")
				button(scene,"ToggleAssetList").pressed.emit(); await settle()
				reading.scroll_vertical = int(reading.get_v_scroll_bar().max_value); await settle()
				check(reading.scroll_vertical > 0 and (scene.find_child("Asset",true,false) as Control).visible,context+": expanded authored bytes are available through independent scrolling")
				check_unchanged_rects(original_rects,fixed_controls(scene,context+"-assets"),context+"-assets")
				if capture_case:
					button(scene,"SaveSession").grab_focus(); await settle()
					await screenshot(capture_prefix+"-assets",dimensions)
				button(scene,"Run").grab_focus(); button(scene,"Run").pressed.emit(); await settle()
				check(scene.history.size() == 1,context+": fixed Run produces one actual measurement")
				check_costs(scene,context+"-first-run")
				if not scene.history[0].accepted:
					check(scene.status.text.contains("above") if scene.english else scene.status.text.contains("顶部"),context+": unmet run directs the player to its actual cost evidence without giving a plan")
				var original_plan: Array = scene.history[0].plan.duplicate(true)
				var signature: String = scene.history[0].traces[0].canonical_signature()
				scene.split_at.value = 18; button(scene,"Split").pressed.emit(); button(scene,"RLE").pressed.emit(); await settle()
				check(scene.plan != original_plan and scene.history[0].plan == original_plan and scene.history[0].traces[0].canonical_signature() == signature,context+": fixed edit operations alter the draft and preserve old evidence")
				button(scene,"Run").pressed.emit(); await settle()
				check(scene.history.size() == 2 and scene.history[1].plan == scene.plan,context+": rerun measures the edited draft without replacing the first run")
				for order: int in scene.history[1].traces.size():
					check(scene.history[1].traces[order].canonical_signature() == Model.run(Model.orders(task_index)[order],scene.plan).canonical_signature(),context+": displayed record is the deterministic model result for its order")
				scene.select_run(0)
				check_costs(scene,context+"-old-record")
				check(scene.cost_source.text.contains("differs") if scene.english else scene.cost_source.text.contains("不同"),context+": fixed cost source identifies old evidence after draft edits")
				check(scene.recorded_plan_label.text.contains("differs") if locale == "en" else scene.recorded_plan_label.text.contains("不同"),context+": selecting old evidence identifies its difference from the draft")
				var measured_rects: Dictionary = fixed_controls(scene,context+"-measured")
				button(scene,"ToggleTraceDetails").pressed.emit()
				(scene.find_child("ToggleDesignShelf",true,false) as Button).button_pressed = true
				evidence.scroll_vertical = int(evidence.get_v_scroll_bar().max_value); await settle()
				check_unchanged_rects(measured_rects,fixed_controls(scene,context+"-evidence"),context+"-evidence")
				check_costs(scene,context+"-deep-evidence")
				check(scene.history[0].traces[0].canonical_signature() == signature,context+": expanded details and collection do not mutate the recorded trace")
				if capture_case:
					scene.select_run(1); evidence.scroll_vertical = 0; await settle()
					await screenshot(capture_prefix+"-measured",dimensions)
				# Long writer failure text must remain readable without changing action geometry.
				scene.save_blocked = true
				scene.status.text = ("写入被阻止；已有方案保留，请检查恢复信息。" if locale != "en" else "Writing is blocked; saved plans are preserved. Inspect recovery details. ").repeat(30)
				await settle()
				check_unchanged_rects(measured_rects,fixed_controls(scene,context+"-blocked"),context+"-blocked")
				var feedback := scene.find_child("FeedbackScroll",true,false) as ScrollContainer
				check(feedback.get_v_scroll_bar().max_value > feedback.size.y,context+": long recovery text remains scrollable in bounded feedback")
				scene.request_hub(); await settle()
				var guard := scene.get_node("UnsavedSessionDialog") as ConfirmationDialog
				guard.get_cancel_button().pressed.emit(); await settle()
				check(scene.departures == 0 and scene.session_dirty and scene.plan != original_plan,context+": Cancel map departure preserves edits")
				scene.request_hub(); await settle(); guard.get_ok_button().pressed.emit(); await settle()
				check(scene.departures == 0 and scene.session_dirty and not scene.leave_to_hub,context+": blocked Save cannot leave the fixed workbench")
				scene.queue_free(); await settle()
	# Actual accepted recipes reproduce the earned presentation state. Flags alone
	# cannot open it, and the scene/viewport use the same explicit logical dimensions.
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var earned_plans: Array = [
		[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}],
		[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":24,"codec":"rle"},{"start":24,"end":40,"codec":"raw"},{"start":40,"end":48,"codec":"rle"},{"start":48,"end":64,"codec":"rle"}],
		[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":48,"codec":"rle"},{"start":48,"end":64,"codec":"rle"}],
		[{"start":0,"end":8,"codec":"raw"},{"start":8,"end":64,"codec":"rle"}],
		[{"start":0,"end":18,"codec":"rle"},{"start":18,"end":46,"codec":"raw"},{"start":46,"end":64,"codec":"rle"}]]
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		var earned := WorkbenchProbe.new(); root.add_child(earned); await settle()
		await fit_scene(earned,Vector2i(1280,720))
		earned.persistent_session = true; earned.candidate_journey = true
		earned.build()
		for index: int in 5:
			earned.change_task(index)
			var accepted: Array[Dictionary] = []; accepted.assign(earned_plans[index])
			earned.edit_plan(accepted); earned.run_current()
			if capture and index == 3:
				await settle(); await screenshot("representation-"+locale+"-prepare-earned",Vector2i(1280,720))
		await settle()
		check(earned.representation_review_evidence().size() == 5,"Earned layout fixture revalidates five protected successful recipes")
		fixed_controls(earned,locale+"-earned")
		check_costs(earned,locale+"-earned")
		await screenshot("representation-"+locale+"-cross-asset-earned",Vector2i(1280,720))
		var review := button(earned,"CompletedRegionReview")
		check(review.is_visible_in_tree() and not review.disabled and root.get_visible_rect().encloses(review.get_global_rect()),locale+": earned review is visibly reachable at actual logical1280x720")
		check(not (review.get_parent() is ScrollContainer) and review.get_parent().name == "RepresentationEvidence",locale+": earned next-step action stays above scrollable evidence")
		var scroll := earned.find_child("EvidenceScroll",true,false) as ScrollContainer
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value); await settle()
		check(root.get_visible_rect().encloses(review.get_global_rect()),locale+": deep evidence reading retains the earned action")
		review.grab_focus(); review.pressed.emit(); await settle()
		var dialog := earned.get_node("RegionReview") as AcceptDialog
		check(dialog.visible and earned.find_child("ContinueServiceCandidate",true,false) != null,locale+": fixed earned action opens real results and the guarded next step")
		var outcomes: Array[Dictionary] = earned.representation_review_evidence()
		for index: int in 5:
			var outcome: Node = dialog.find_child("RegionOutcome"+str(index),true,false)
			check(outcome != null,locale+": earned review presents each real task outcome before reflection")
			if outcome == null: continue
			for order: int in outcomes[index].metrics.size():
				var measured := outcome.find_child("RegionOutcomeMetrics"+str(order),true,false) as Label
				var m: Dictionary = outcomes[index].metrics[order]
				check(measured != null and measured.text.contains(str(m.preparation_cycles)) and measured.text.contains(str(m.service_cycles)) and measured.text.contains(str(m.stored_bytes)),locale+": review separates actual preparation, service and storage per order")
		var review_scroll := dialog.find_child("RegionReviewScroll",true,false) as ScrollContainer
		check(dialog.find_child("RegionReviewAchievements",true,false).get_index() < dialog.find_child("RegionReviewContent",true,false).get_index(),locale+": achievements precede the warm independent ending and service bridge")
		await screenshot("representation-"+locale+"-closure-results",Vector2i(1280,720))
		review_scroll.scroll_vertical = int(review_scroll.get_v_scroll_bar().max_value); await settle()
		await screenshot("representation-"+locale+"-closure-next",Vector2i(1280,720))
		dialog.hide(); earned.queue_free(); await settle()
	localization.set_locale(original_locale)
	var campaign_after: Dictionary = campaign._save_snapshot(); campaign_after.erase("saved_at_utc")
	check(campaign_before == campaign_after,"Presentation and operations grant no core progress")
	print("PASS: test_representation_workbench_presentation " if failures == 0 else "FAIL: test_representation_workbench_presentation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
