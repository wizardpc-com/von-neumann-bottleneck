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
				# The full matrix is headless; rendering samples the densest two-asset task.
				if capture and task_index != 4: continue
				var scene := WorkbenchProbe.new(); root.add_child(scene); await settle()
				# Show persistent controls without claiming a disk profile or acquiring a writer.
				scene.persistent_session = true; scene.candidate_journey = true
				scene.build()
				scene.change_task(task_index); await settle()
				await fit_scene(scene,dimensions)
				check(scene.trace_player.english == scene.english and scene.trace_player.recorded_events.is_empty(),"Fresh empty replay uses the workbench language without inventing events")
				check(button(scene,"Run").get_theme_color("font_focus_color") == Color("071823") and button(scene,"SaveSession").get_theme_color("font_focus_color") == Color("071823"),"Primary keyboard focus keeps dark text on its bright surface")
				var context: String = locale+"-T%d-%dx%d" % [task_index+1,dimensions.x,dimensions.y]
				var capture_case: bool = capture and dimensions == Vector2i(1280,720) and task_index == 4
				if capture_case:
					button(scene,"Run").grab_focus(); await settle()
					await screenshot("representation-"+locale+"-initial",dimensions)
				var original_rects: Dictionary = fixed_controls(scene,context+"-initial")
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
					await screenshot("representation-"+locale+"-assets",dimensions)
				button(scene,"Run").grab_focus(); button(scene,"Run").pressed.emit(); await settle()
				check(scene.history.size() == 1,context+": fixed Run produces one actual measurement")
				var original_plan: Array = scene.history[0].plan.duplicate(true)
				var signature: String = scene.history[0].traces[0].canonical_signature()
				scene.split_at.value = 18; button(scene,"Split").pressed.emit(); button(scene,"RLE").pressed.emit(); await settle()
				check(scene.plan != original_plan and scene.history[0].plan == original_plan and scene.history[0].traces[0].canonical_signature() == signature,context+": fixed edit operations alter the draft and preserve old evidence")
				button(scene,"Run").pressed.emit(); await settle()
				check(scene.history.size() == 2 and scene.history[1].plan == scene.plan,context+": rerun measures the edited draft without replacing the first run")
				for order: int in scene.history[1].traces.size():
					check(scene.history[1].traces[order].canonical_signature() == Model.run(Model.orders(task_index)[order],scene.plan).canonical_signature(),context+": displayed record is the deterministic model result for its order")
				scene.select_run(0)
				check(scene.recorded_plan_label.text.contains("differs") if locale == "en" else scene.recorded_plan_label.text.contains("不同"),context+": selecting old evidence identifies its difference from the draft")
				var measured_rects: Dictionary = fixed_controls(scene,context+"-measured")
				button(scene,"ToggleTraceDetails").pressed.emit()
				(scene.find_child("ToggleDesignShelf",true,false) as Button).button_pressed = true
				evidence.scroll_vertical = int(evidence.get_v_scroll_bar().max_value); await settle()
				check_unchanged_rects(measured_rects,fixed_controls(scene,context+"-evidence"),context+"-evidence")
				check(scene.history[0].traces[0].canonical_signature() == signature,context+": expanded details and collection do not mutate the recorded trace")
				if capture_case:
					scene.select_run(1); evidence.scroll_vertical = 0; await settle()
					await screenshot("representation-"+locale+"-measured",dimensions)
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
		await settle()
		check(earned.representation_review_evidence().size() == 5,"Earned layout fixture revalidates five protected successful recipes")
		fixed_controls(earned,locale+"-earned")
		var review := button(earned,"CompletedRegionReview")
		check(review.is_visible_in_tree() and not review.disabled and root.get_visible_rect().encloses(review.get_global_rect()),locale+": earned review is visibly reachable at actual logical1280x720")
		check(not (review.get_parent() is ScrollContainer) and review.get_parent().name == "RepresentationEvidence",locale+": earned next-step action stays above scrollable evidence")
		var scroll := earned.find_child("EvidenceScroll",true,false) as ScrollContainer
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value); await settle()
		check(root.get_visible_rect().encloses(review.get_global_rect()),locale+": deep evidence reading retains the earned action")
		review.grab_focus(); review.pressed.emit(); await settle()
		var dialog := earned.get_node("RegionReview") as AcceptDialog
		check(dialog.visible and earned.find_child("ContinueServiceCandidate",true,false) != null,locale+": fixed earned action opens real results and the guarded next step")
		dialog.hide(); earned.queue_free(); await settle()
	localization.set_locale(original_locale)
	var campaign_after: Dictionary = campaign._save_snapshot(); campaign_after.erase("saved_at_utc")
	check(campaign_before == campaign_after,"Presentation and operations grant no core progress")
	print("PASS: test_representation_workbench_presentation " if failures == 0 else "FAIL: test_representation_workbench_presentation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
