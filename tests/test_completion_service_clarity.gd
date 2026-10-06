extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var scene := Lab.new(); root.add_child(scene); await process_frame
	check(scene.bill_button.disabled and scene.history.is_empty(),"Unrun draft has no measured bill")
	scene.show_measured_bill()
	check(not scene.has_node("MeasuredBillReview"),"Bill action cannot invent a record")
	scene.show_specification(); await process_frame
	var specification := scene.get_node("ServiceSpecificationReview") as AcceptDialog
	check(specification.visible and specification.get_node("ReviewContent").text.contains("512B") and specification.get_node("ReviewContent").text.contains("600B") and specification.get_node("ReviewContent").text.contains("1e-9"),"Full specification is available before running with original capacity, traffic and quality limits")
	specification.hide()
	scene.run_current(); await process_frame
	var original: String = JSON.stringify(scene.history[0])
	check(scene.summary.text.contains("2204") and scene.summary.text.contains("3168") and scene.summary.text.contains("266"),"Compact overview retains baseline time traffic and peak evidence")
	check(not scene.summary.text.contains("请求") and not scene.summary.text.contains("[89"),"Detailed bill and response array do not repeat on overview")
	check(scene.status.text.contains("784") and scene.status.text.contains("2568"),"Exact unmet constraints remain visible")
	check(scene.response_chart.first_responses == [89,180,271,362],"Who waits remains based on actual baseline first responses")
	var edited: Dictionary = Model.initial_plan(); edited.slots = 4
	scene.edit(edited,0)
	check(scene.draft_source.text.contains("4状态槽") and scene.measured_source.text.contains("1状态槽"),"Draft and selected measured plan show independent slot counts")
	for en: bool in [false,true]:
		scene.english = en; scene.build(); scene.hint_open = true; scene.refresh_mission()
		await process_frame; await process_frame
		check(not scene.mission.text.contains("512") and scene.mission.text.contains("600B"),"Main mission keeps current contract; shared rules move to specification")
		check(scene.measured_source.text.contains("Draft") if en else scene.measured_source.text.contains("草稿"),"Edited draft never masquerades as measured source")
		scene.show_measured_bill(); await process_frame; await process_frame
		var review := scene.get_node("MeasuredBillReview") as AcceptDialog
		var text: String = review.get_node("ReviewContent").text
		check(text.contains("2204") and text.contains("3168") and text.contains("[89, 180, 271, 362]"),"Complete bill retains baseline costs and all response coordinates")
		check(text.contains("flush") and text.contains("264") and text.contains("576") and text.contains("784") and text.contains("2568"),"Complete bill retains final archive, compute cost, flush and precise failure feedback")
		check(text.contains("Draft") if en else text.contains("草稿"),"Bill explicitly identifies selected measured plan after draft edits")
		check(review.size.x <= 1280 and review.size.y <= 720,"Bill dialog fits minimum bilingual viewport")
		review.hide()
		scene.show_specification(); await process_frame
		specification = scene.get_node("ServiceSpecificationReview")
		check(specification.get_node("ReviewContent").text.contains("512B") and specification.get_node("ReviewContent").text.contains("350B"),"Hidden shared rules and task peak budget remain discoverable")
		specification.hide()
		for id: String in ["DraftSource","MeasuredBill","ShowStateJourney","ServiceSpecification","Run","PublicData"]:
			var node := scene.find_child(id,true,false) as Control
			check(node.is_visible_in_tree() and node.get_global_rect().end.x <= 1280 and node.get_global_rect().end.y <= 720,"Primary and detail controls fit bilingual minimum viewport: "+id)
		scene.find_child("ShowStateJourney",true,false).pressed.emit(); await process_frame
		check(scene.evidence_tabs.current_tab == 5 and not scene.state_replay.frames.is_empty(),"Direct history-location action opens selected recorded state evidence")
		scene.evidence_tabs.current_tab = 0
		check(JSON.stringify(scene.history[0]) == original,"Detail access and localization retain immutable measurement")
	scene.undo()
	check(scene.plan.slots == 1 and not scene.measured_source.text.contains("Draft differs"),"Undo restores draft identity without a new measurement")
	var invalid: Dictionary = Model.move(Model.initial_plan(),4,-4)
	scene.edit(invalid,0); scene.run_current(); await process_frame
	scene.show_measured_bill(); await process_frame
	var rejected: String = scene.get_node("MeasuredBillReview").get_node("ReviewContent").text
	check(rejected.contains("A1") and rejected.contains("A0") and rejected.contains("no measured"),"Rejected bill exposes actual dependency failure without zero-cost measurements")
	check(scene.response_chart.first_responses.is_empty() and scene.state_replay.frames.is_empty(),"Rejected record clears response and state evidence")
	check(scene.history.size() == 2 and scene.support_plans.is_empty(),"Reading details neither reruns nor awards a successful plan")
	scene.get_node("MeasuredBillReview").hide()
	var grouped: Dictionary = Model.initial_plan(); grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	scene.edit(grouped,0); scene.run_current(); scene.change_task(1)
	var exact: Dictionary = Model.initial_plan(); exact.slots = 4
	scene.edit(exact,0); scene.run_current(); scene.change_task(2)
	exact.representations = ["rle64","rle64","raw64","raw64"]
	scene.edit(exact,0); scene.run_current()
	check(scene.has_service_closure(),"Three actually accepted plans earn service closure")
	var supports: Dictionary = scene.support_plans.duplicate(true)
	var draft: Dictionary = scene.plan.duplicate(true)
	var history_before: String = JSON.stringify(scene.history)
	scene.candidate_journey = true; scene.persistent_session = true; scene.session_dirty = true
	scene.show_closure(); await process_frame
	var journey_button := scene.get_node("ServiceReview").find_child("ServiceToJourney",true,false) as Button
	check(journey_button != null,"Earned service review exposes journey continuation")
	journey_button.pressed.emit(); await process_frame
	var guard := scene.get_node("UnsavedServiceDialog") as ConfirmationDialog
	check(guard.visible and scene.leave_to_hub and scene.session_dirty,"Closure continuation uses existing unsaved-Home guard")
	guard.get_cancel_button().pressed.emit(); await process_frame
	check(not guard.visible and scene.is_inside_tree() and scene.session_dirty,"Cancel retains the unsaved service workbench")
	check(scene.support_plans == supports and scene.plan == draft and JSON.stringify(scene.history) == history_before,"Canceled journey continuation preserves supports, draft and measured history")
	scene.persistent_session = false
	scene.queue_free(); await process_frame
	print("PASS: test_completion_service_clarity " if failures == 0 else "FAIL: test_completion_service_clarity ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
