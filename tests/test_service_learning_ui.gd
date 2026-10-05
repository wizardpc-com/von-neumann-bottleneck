extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
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
	scene.queue_free(); await process_frame
	print("PASS: test_service_learning_ui " if failures == 0 else "FAIL: test_service_learning_ui ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
