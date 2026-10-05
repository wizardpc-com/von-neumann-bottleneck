extends SceneTree
const Model = preload("res://experiments/service_plan/model.gd")
const View = preload("res://experiments/service_plan/state_replay_view.gd")
var checks: int = 0
var failures: int = 0
var signals_seen: Array[int] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func text_in(node: Node) -> String:
	var result: String = node.text if node is Label else ""
	for child: Node in node.get_children(): result += "\n"+text_in(child)
	return result
func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var host := VBoxContainer.new(); host.position = Vector2(440,180); host.size = Vector2(820,510); root.add_child(host)
	var view := View.new(); host.add_child(view)
	view.frame_changed.connect(func(index: int) -> void: signals_seen.append(index))
	await process_frame
	view.configure({})
	check(view.current_source_index == -1 and view.frames.is_empty(),"Unperformed draft produces no state measurement")
	for id: String in ["StateStart","StatePrevious","StateNext","StateEnd"]:
		check(view.find_child(id,true,false).disabled,"Empty replay navigation disabled")
	var trace: RefCounted = Model.run(Model.initial_plan())
	var events: Array[Dictionary] = []
	for event: RefCounted in trace.events: events.append(event.to_dictionary().duplicate(true))
	var record: Dictionary = {"metrics":trace.metrics.duplicate(true),"events":events,"task":0}
	var before: String = JSON.stringify(record)
	for en: bool in [false,true]:
		view.configure(record,en)
		await process_frame; await process_frame
		check(view.frames.size() == events.size() and view.current_source_index == 0,"Replay opens first recorded frame")
		check(signals_seen.is_empty(),"Configure does not emit a selection feedback loop")
		check(view.source_caption.text.contains("raw64") and view.source_caption.text.contains("24"),"Replay identifies the measured plan, independent of drafts")
		check(text_in(view.state_content).contains("66 B") and not text_in(view.state_content).contains(JSON.stringify(Model.initial(0))),"Initial backing bytes are visible without decoding invented numerical state")
		for button: Button in view.step_buttons:
			var bounds: Rect2 = button.get_global_rect()
			check(bounds.position.x >= 0 and bounds.end.x <= 1280 and bounds.end.y <= 720,"Bilingual replay buttons fit minimum viewport")
		var scroll := view.get_node("StateScroll") as ScrollContainer
		check(scroll.get_global_rect().end.x <= 1280 and scroll.get_global_rect().end.y <= 720,"Bilingual replay scrolling stays bounded")
		view.show_source_index(events.size()+100)
		check(view.current_source_index == events.size()-1 and signals_seen.is_empty(),"Source selection clamps to nearest preceding frame without signal")
		check(text_in(view.state_content).contains("A5") and text_in(view.state_content).contains("D5"),"Final replay retains returned request identities")
		var last: Dictionary = view.frames.back()
		check(last.state_read_bytes == trace.metrics.state_read_bytes and last.state_write_bytes == trace.metrics.state_write_bytes,"Final cumulative traffic matches measurement")
		view.find_child("StateStart",true,false).pressed.emit()
		check(view.current_source_index == 0 and signals_seen == [0],"Start button emits actual selected source")
		view.find_child("StateNext",true,false).pressed.emit()
		check(view.current_source_index == 1 and signals_seen == [0,1],"Next steps one real recorded event")
		view.find_child("StatePrevious",true,false).pressed.emit()
		check(view.current_source_index == 0 and view.find_child("StatePrevious",true,false).disabled,"Previous stops at first valid frame")
		view.find_child("StateEnd",true,false).pressed.emit()
		check(view.current_source_index == events.size()-1 and view.find_child("StateNext",true,false).disabled,"End stops at final valid frame")
		var compute_index: int = -1
		for index: int in events.size():
			if str(events[index].kind) == "compute": compute_index = index; break
		view.show_source_index(compute_index)
		check(text_in(view.state_content).contains(JSON.stringify(events[compute_index].details.before)) and text_in(view.state_content).contains(JSON.stringify(events[compute_index].details.after)),"Actual recorded before and after states are shown")
		check(view.event_caption.text.contains(str(events[compute_index].cycle)),"Replay event timing comes from selected recorded event")
		check(JSON.stringify(record) == before,"View navigation and localization preserve immutable source")
		signals_seen.clear()
	ProjectSettings.set_setting("game/reduced_motion",true)
	view.configure(record,true)
	view.find_child("StateNext",true,false).pressed.emit()
	check(view.current_source_index == 1 and not view.is_processing(),"Static stepping remains safe under reduced motion")
	ProjectSettings.set_setting("game/reduced_motion",false)
	for invalid: Dictionary in [{},{"metrics":{"error":"stream_dependency","plan":Model.initial_plan()},"events":events},{"metrics":record.metrics,"events":[]},{"metrics":record.metrics,"events":[{"kind":"decode","details":{"stream":99},"cycle":0,"duration":1}]}]:
		view.configure(invalid,true)
		check(view.frames.is_empty() and view.current_source_index == -1 and view.state_content.get_child_count() == 0,"Invalid or empty records clear previous state without invented measurement")
	check(JSON.stringify(record) == before,"Invalid reset does not modify prior copied measurement")
	host.queue_free(); await process_frame
	print("PASS: test_service_state_replay_view " if failures == 0 else "FAIL: test_service_state_replay_view ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
