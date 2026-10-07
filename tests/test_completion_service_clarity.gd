extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
const NavigationIntent = preload("res://experiments/candidate_session/navigation_intent.gd")
class DeferredLeaveProbe extends "res://experiments/service_plan/lab.gd":
	var destinations: Array[bool] = []
	func _finish_hub_leave(review_journey: bool) -> void: destinations.append(review_journey)
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
	check(scene.next_button.disabled and scene.event_raw_button.disabled,"No-data actions cannot offer progression or raw events")
	check(scene.response_chart.frames.is_empty() and scene.summary.text.contains("历史"),"Entry explains continuous history and the player's draft without inventing a state snapshot")
	scene.continue_service(); check(scene.task == 0,"Calling Next before earning support does not navigate")
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
	var witness: Dictionary = scene.response_chart.witness_snapshot()
	check(scene.response_chart.playback_cycle == 362 and witness.event.kind == "output" and witness.event.details.stream == 3,"First real run shows the recorded moment of D's latest first response")
	check(witness.residents[3].present and witness.residents[3].dirty and not witness.residents[0].present,"Overview projects actual resident and dirty history at that response, rather than final state")
	check(scene.response_chart.current_source_index() == witness.source_index and int(witness.source_index) < scene.history[0].events.size()-1,"Overview's marked time remains traceable to an intermediate source event")
	scene.response_chart.playback_cycle = 88
	witness = scene.response_chart.witness_snapshot()
	check(witness.responses.is_empty() and witness.residents[0].present,"Just before A's real output completes, its updated history is resident but no response has returned")
	scene.response_chart.playback_cycle = 362
	scene.response_step.pressed.emit()
	witness = scene.response_chart.witness_snapshot()
	check(scene.response_chart.playback_cycle == 89 and witness.event.details.stream == 0 and witness.residents[0].present,"Existing Step synchronizes A's first response with the actual A history location")
	scene.find_child("ShowStateJourney",true,false).pressed.emit()
	check(scene.state_replay.current_source_index == scene.response_chart.current_source_index() and scene.selected_event_index == scene.response_chart.current_source_index(),"History detail opens the exact overview event rather than the beginning or final state")
	scene.evidence_tabs.current_tab = 0; scene.select_run(0)
	var verdict_before: String = scene.measured_verdict.text
	scene.notice_key = "saved"; scene.status.text = scene.session_notice()
	check(scene.measured_verdict.text == verdict_before and scene.measured_verdict.text.contains("未达标"),"Save notice cannot replace selected measurement verdict")
	scene.select_run(0)
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
		for id: String in ["DraftSource","MeasuredVerdict","ServiceNext","MeasuredBill","ShowStateJourney","ServiceSpecification","Run","PublicData","ResponseChart","ResponsePlay","ResponseStep"]:
			var node := scene.find_child(id,true,false) as Control
			check(node.is_visible_in_tree() and node.get_global_rect().end.x <= 1280 and node.get_global_rect().end.y <= 720,"Primary and detail controls fit bilingual minimum viewport: "+id+" "+str(node.get_global_rect()))
		scene.find_child("ShowStateJourney",true,false).pressed.emit(); await process_frame
		check(scene.evidence_tabs.current_tab == 5 and not scene.state_replay.frames.is_empty(),"Direct history-location action opens selected recorded state evidence")
		scene.state_replay.find_child("StateEnd",true,false).pressed.emit(); await process_frame
		check(not scene.event_raw_button.disabled,"Selecting a real recorded event enables complete JSON evidence")
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
	check(scene.response_chart.frames.is_empty() and scene.response_chart.witness_snapshot().is_empty() and scene.response_chart.current_source_index() == -1,"Rejected measurement also clears the combined history and response snapshot")
	check(scene.event_raw_button.disabled and scene.measured_verdict.text.contains("Not executed"),"Rejected measurement has no raw event action or passing verdict")
	check(scene.history.size() == 2 and scene.support_plans.is_empty(),"Reading details neither reruns nor awards a successful plan")
	scene.get_node("MeasuredBillReview").hide()
	var grouped: Dictionary = Model.initial_plan(); grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	scene.edit(grouped,0); scene.run_current()
	check(not scene.next_button.disabled and scene.measured_verdict.text.contains("successful plan retained"),"Protected successful Task1 enables explicit next action")
	scene.select_run(0)
	check(not scene.next_button.disabled and scene.measured_verdict.text.contains("Limits unmet"),"Selected failed alternative does not erase earned continuation")
	scene.next_button.pressed.emit(); await process_frame
	check(scene.task == 1 and scene.unlocked == 1,"Next follows the earned task without awarding further progress")
	scene.select_run(scene.history.size()-1)
	var transfer_record: String = JSON.stringify(scene.history[-1])
	var transfer_metrics: Dictionary = scene.history[-1].metrics
	check(transfer_metrics.total_cycles <= 1420 and transfer_metrics.all_streams_first_cycle > 320,"Real contract1 support provides a fast overall but late-first-response counterexample")
	for en: bool in [false,true]:
		scene.english = en; scene.build(); await process_frame
		var bridge: String = scene.response_chart.contract_caption()
		check(bridge.contains(str(transfer_metrics.total_cycles)) and bridge.contains(str(transfer_metrics.all_streams_first_cycle)) and bridge.contains("320") and bridge.contains("timely" if en else "及时"),"Contract2 explains total completion versus individual response using the same actual record")
		check(JSON.stringify(scene.history[-1]) == transfer_record and not scene.support_plans.has(1),"Reading the response bridge cannot rerun or earn contract2")
	var exact: Dictionary = Model.initial_plan(); exact.slots = 4
	exact.representations = ["rle64","rle64","raw64","raw64"]
	scene.edit(exact,0); scene.run_current(); scene.next_button.pressed.emit(); await process_frame
	check(scene.task == 2 and scene.next_button.disabled and not scene.support_plans.has(2),"Compatible Task2 record cannot grant Task3 support by inspection")
	check(scene.measured_verdict.text.contains("Limits met") and scene.measured_verdict.text.contains("No Task3"),"Verdict distinguishes compatible old measurement from unearned contract")
	scene.continue_service(); check(not scene.has_node("ServiceReview"),"Direct continuation refuses unearned closure")
	scene.edit(exact,0); scene.run_current()
	check(scene.has_service_closure(),"Three actually accepted plans earn service closure")
	check(not scene.next_button.disabled,"Three protected plans enable review action")
	var supports: Dictionary = scene.support_plans.duplicate(true)
	var draft: Dictionary = scene.plan.duplicate(true)
	var history_before: String = JSON.stringify(scene.history)
	scene.candidate_journey = true; scene.persistent_session = true; scene.session_dirty = true
	NavigationIntent.pending_review = ""
	scene.show_closure(); await process_frame
	var journey_button := scene.get_node("ServiceReview").find_child("ServiceToJourney",true,false) as Button
	check(journey_button != null,"Earned service review exposes journey continuation")
	journey_button.pressed.emit(); await process_frame
	var guard := scene.get_node("UnsavedServiceDialog") as ConfirmationDialog
	check(guard.visible and scene.leave_to_hub and scene.session_dirty,"Closure continuation uses existing unsaved-Home guard")
	check(not scene.get_node("ServiceReview").visible and scene.leave_to_journey and NavigationIntent.pending_review.is_empty(),"Dirty journey request retains hidden earned review and delays shared navigation intent")
	guard.get_cancel_button().pressed.emit(); await process_frame
	check(not guard.visible and scene.is_inside_tree() and scene.session_dirty,"Cancel retains the unsaved service workbench")
	check(scene.get_node("ServiceReview").visible and not scene.leave_to_journey and NavigationIntent.pending_review.is_empty(),"Cancel preserves review and clears only local pending destination")
	journey_button.pressed.emit(); await process_frame
	scene.save_blocked = true; guard.confirmed.emit(); await process_frame
	check(scene.session_dirty and scene.get_node("ServiceReview").visible and not guard.visible and not scene.leave_to_journey and NavigationIntent.pending_review.is_empty(),"Blocked save restores review without publishing journey intent or stacking dialogs")
	guard.get_cancel_button().pressed.emit(); await process_frame
	scene.save_blocked = false
	scene.get_node("ServiceReview").hide(); scene.request_hub(); await process_frame
	check(guard.visible and not scene.leave_to_journey and NavigationIntent.pending_review.is_empty(),"Ordinary Home clears earlier closure intent while still guarding unsaved work")
	guard.get_cancel_button().pressed.emit(); await process_frame
	check(not scene.get_node("ServiceReview").visible,"Cancel of ordinary Home does not unexpectedly reopen earned review")
	check(scene.support_plans == supports and scene.plan == draft and JSON.stringify(scene.history) == history_before,"Canceled journey continuation preserves supports, draft and measured history")
	scene.persistent_session = false
	scene.queue_free(); await process_frame
	var leave_probe := DeferredLeaveProbe.new(); root.add_child(leave_probe); await process_frame
	NavigationIntent.pending_review = ""
	leave_probe.request_hub(true)
	check(leave_probe.destinations.is_empty() and NavigationIntent.pending_review.is_empty(),"Confirmed departure queues scene replacement and does not publish intent in Window callback")
	leave_probe.leave_to_journey = false
	await process_frame
	check(leave_probe.destinations == [true],"Deferred departure preserves the confirmed journey destination")
	leave_probe.request_hub()
	check(leave_probe.destinations == [true],"Ordinary Home also leaves after its callback completes")
	await process_frame
	check(leave_probe.destinations == [true,false],"Deferred ordinary Home keeps its separate destination")
	leave_probe.queue_free(); await process_frame
	var localization: Node = root.get_node_or_null("Localization")
	if localization != null:
		var locale_before: String = str(localization.call("current_locale"))
		localization.call("set_locale","en")
		var locale_probe := Lab.new(); root.add_child(locale_probe); await process_frame
		check(locale_probe.english,"Service entering from English shared interface retains the language")
		locale_probe.language_button.pressed.emit(); await process_frame
		check(not locale_probe.english and str(localization.call("current_locale")) == "zh_CN","Service language action updates shared stage language")
		locale_probe.queue_free(); await process_frame
		localization.call("set_locale",locale_before)
	print("PASS: test_completion_service_clarity " if failures == 0 else "FAIL: test_completion_service_clarity ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
