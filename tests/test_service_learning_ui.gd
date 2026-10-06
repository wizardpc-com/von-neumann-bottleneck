extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Q = preload("res://experiments/service_plan/quality_evidence.gd")
const EP = preload("res://experiments/service_plan/event_presenter.gd")
const M = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
	var scene := Lab.new(); root.add_child(scene); await process_frame
	check(scene.find_child("ServiceIntroduction",true,false) != null,"Introduction is available before any measurement")
	check(scene.history.is_empty() and scene.selected_history == -1,"Introduction needs no trial or unlock")
	scene.show_briefing(); await process_frame
	var intro := scene.get_node("ServiceBriefing") as AcceptDialog
	check(intro.visible and intro.get_node("BriefingPages").get_tab_count() == 3,"Three optional operation/rule pages open")
	intro.hide()
	scene.run_current(); await process_frame
	var measured: Dictionary = scene.history[0].duplicate(true)
	var signature: String = scene.active_trace.canonical_signature()
	var replay = scene.state_replay
	check(not replay.frames.is_empty(),"Actual measured trace populates state replay")
	replay.show_source_index(10)
	var first_index: int = replay.current_source_index
	check(first_index >= 0 and first_index <= 10,"Recorded event selection projects the latest prefix only")
	replay.find_child("StateNext",true,false).pressed.emit(); await process_frame
	check(scene.selected_event_index == replay.current_source_index,"Stepping replay selects the corresponding trace event")
	check(scene.tree.get_selected().get_index() == replay.current_source_index,"Event inspector follows actual replay source")
	var selected: int = replay.current_source_index
	var draft: Dictionary = scene.plan.duplicate(true); draft.slots = 2; scene.edit(draft,0)
	check(scene.state_source.text.contains("草稿") and scene.history[0] == measured,"State view explicitly retains measured source when draft changes")
	check(scene.active_trace.canonical_signature() == signature,"State display/stepping never reruns or mutates simulation")
	for en: bool in [false,true]:
		scene.english = en; scene.build(); scene.evidence_tabs.current_tab = 5
		await process_frame; await process_frame
		check(scene.state_replay.current_source_index == selected,"Language rebuild preserves recorded prefix position")
		check(scene.state_source.text.contains("Draft") if en else scene.state_source.text.contains("草稿"),"Bilingual source note distinguishes edited draft")
		check(scene.evidence_tabs.get_global_rect().end.y <= 721,"State evidence tab fits minimum logical height")
		check(scene.find_child("QualityEvidence",true,false).get_global_rect().end.x <= 1281,"Quality evidence remains reachable at minimum bilingual width")
		check(scene.find_child("StateEnd",true,false).get_global_rect().end.x <= 1281,"Replay controls fit minimum logical width")
		scene.show_briefing(); await process_frame; await process_frame
		intro = scene.get_node("ServiceBriefing")
		check(intro.size.x <= 1280 and intro.size.y <= 720,"Reopenable briefing fits minimum window")
		check(intro.get_node("BriefingPages").size.x <= 700,"Briefing uses bounded pages")
		intro.hide()
	scene.run_current(); await process_frame
	check(scene.state_replay.current_source_index == 0,"New measurement starts at its own initial event")
	scene.select_run(0); await process_frame
	check(scene.history[0] == measured,"Switching records keeps immutable evidence")
	var invalid: Dictionary = scene.plan.duplicate(true); invalid.groups = [[1]]
	scene.edit(invalid,0); scene.run_current(); await process_frame
	check(scene.state_replay.frames.is_empty(),"Rejected plan supplies no state journey measurement")
	check(scene.support_plans.is_empty(),"Replay and briefing grant no progression supports")
	var approximate: Dictionary = M.initial_plan(); approximate.slots = 4; approximate.representations = ["raw8","raw8","raw8","raw8"]
	scene.task = 1; scene.edit(approximate,0); scene.run_current(); await process_frame
	var quality_record: Dictionary = scene.history[scene.selected_history].duplicate(true)
	var quality_before: String = JSON.stringify(quality_record)
	var witness: Dictionary = Q.build(quality_record.metrics,quality_record.events)
	check(witness.score.error == quality_record.metrics.max_error and witness.state.error == quality_record.metrics.max_state_error,"Quality witnesses match actual authoritative maxima")
	var request: int = int(witness.score.request_id)
	check(witness.score.actual == quality_record.metrics.outputs[request] and witness.score.reference == quality_record.metrics.reference.outputs[request],"Score witness identifies actual recorded request and reference")
	var stream: int = int(witness.state.stream); var coordinate: int = int(witness.state.coordinate)
	check(witness.state.actual == quality_record.metrics.final_states[stream][coordinate] and witness.state.reference == quality_record.metrics.reference.states[stream][coordinate],"State witness identifies recorded stream and coordinate")
	check(Q.build(quality_record.metrics).score.request_id == request,"Metric-only failure identity matches event witness deterministically")
	var exact_draft: Dictionary = M.initial_plan(); exact_draft.slots = 4
	for en: bool in [false,true]:
		scene.english = en; scene.build(); await process_frame
		check(scene.measured_feedback(quality_record.metrics,1).contains(Q.identity(witness.score,true)) and scene.measured_feedback(quality_record.metrics,1).contains(Q.identity(witness.state,false)),"Bilingual precision failure identifies responsible request and final-state coordinate")
		scene.show_quality_evidence(); await process_frame
		var review := scene.get_node("MeasuredQualityReview") as AcceptDialog
		var content := review.get_node("QualityContent") as RichTextLabel
		check(content.text.contains(Q.identity(witness.score,true)) and content.text.contains(Q.identity(witness.state,false)) and content.text.contains(String.num_scientific(1e-9)),"Bilingual quality detail shows witnesses and public tolerance")
		check(content.text.contains(String.num_scientific(witness.score.error)) and content.text.contains(String.num_scientific(witness.state.error)),"Nonzero errors remain explicit in scientific notation")
		check(review.size.x <= 1280 and review.size.y <= 720,"Quality detail stays bounded in both languages")
		review.hide()
		var returned: Dictionary = quality_record.events[int(witness.score.source_index)]
		var explanation: String = EP.summary(returned,en)
		check(explanation.contains(String.num_scientific(returned.details.score)) and explanation.contains(String.num_scientific(returned.details.reference)) and explanation.contains(String.num_scientific(returned.details.error)),"Readable returned event exposes actual score reference and error")
		check(EP.summary({"kind":"output","details":{"request_id":0,"stream":0}},en).contains("not recorded" if en else "未记录"),"Missing output values remain unknown instead of fabricated zero")
		scene.edit(exact_draft,0)
		check(Q.build(scene.history[scene.selected_history].metrics,scene.history[scene.selected_history].events) == witness,"Unrun exact draft cannot replace approximate measurement evidence")
		check(JSON.stringify(scene.history[scene.selected_history]) == quality_before,"Quality display and draft edits retain immutable record")
	scene.run_current(); await process_frame
	var exact_record: Dictionary = scene.history[scene.selected_history]
	check(M.accepted(exact_record.metrics,1),"Exact-quality fixture really meets original prompt-service contract")
	var exact_witness: Dictionary = Q.build(exact_record.metrics,exact_record.events)
	check(exact_witness.score.error == 0.0 and exact_witness.state.error == 0.0,"Exact accepted measurement retains zero-error evidence")
	check(Q.text(exact_witness,1e-9,true).contains("Within limit") and not Q.text(exact_witness,1e-9,true).contains("Over limit"),"Exact success detail does not invent a quality failure")
	check(Q.build({"error":"stream_dependency"},[]).is_empty(),"Rejected measurement cannot create quality witnesses")
	scene.queue_free(); await process_frame
	print("PASS: test_service_learning_ui " if failures == 0 else "FAIL: test_service_learning_ui ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
