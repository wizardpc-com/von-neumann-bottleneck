extends SceneTree
const Store = preload("res://src/playtest/playtest_data.gd")
class ClockStore extends PlaytestDataStore:
	var clock_ms: int = 100
	func _now_ms() -> int: return clock_ms

var failures: Array[String] = []
func _init() -> void:
	var directory: String = "res://.godot/visit_test_"+str(Time.get_ticks_usec())
	var recorder := ClockStore.new()
	recorder.configure_for_storage(directory)
	recorder.start_session()
	recorder.source_kind = "agent_native"
	recorder.level_started(&"chapter_3",&"arrival")
	var visit: String = recorder.current_visit_id
	recorder.clock_ms += 1000
	recorder._change_focus(false)
	recorder.clock_ms += 9000
	recorder._change_focus(true)
	recorder.clock_ms += 500
	recorder.set_feedback_visible(true)
	recorder.clock_ms += 700
	var moment: int = recorder.mark_moment(&"understood")
	recorder.set_feedback_visible(false)
	recorder.record_official_run(&"chapter_3",&"arrival",false,{"result_class":"correct_but_slow","cases":[{"passed":true,"metrics":{"total_cycles":30},"nested":{"program_source":"PRIVATE"}}]})
	recorder.record_official_run(&"chapter_3",&"arrival",true)
	recorder.level_completed(&"chapter_3",&"arrival")
	_check(recorder.current_visit_id == visit and recorder._active_level_key == "chapter_3/arrival","Completion must preserve the current visit.")
	recorder.clock_ms += 300
	recorder.record_official_run(&"chapter_3",&"arrival",true)
	recorder.level_completed(&"chapter_3",&"arrival")
	recorder.level_exited(&"chapter_3",&"arrival")
	recorder.set_exit_reason(&"other_task")
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(recorder.export_current_session()))
	var summary: Dictionary = document.level_summaries[0]
	_check(summary.foreground_ms == 1800 and summary.background_ms == 9000 and summary.feedback_ms == 700,"Only foreground activity should count as active play; background and feedback stay separate.")
	_check(summary.visits == 1 and summary.retries == 1 and summary.completion_count == 1 and summary.post_completion_runs == 1,"Success repeats must not inflate retries, visits or completions.")
	_check(moment > 0 and recorder.current_visit_id.is_empty(),"Moment is durable and exiting clears the active visit ID.")
	var case_found: bool = false
	for event: Dictionary in document.events:
		if event.event == "case_outcome": case_found = not event.payload.run_id.is_empty() and event.payload.metrics.total_cycles == 30 and not event.payload.nested.has("program_source")
		if event.event == "exit_reason": _check(event.visit_id == visit,"Exit feedback must refer to the visit just left.")
	_check(case_found,"Per-case outcomes must bind to a real run.")
	recorder.end_session(); recorder.free()
	var feedback := ClockStore.new()
	feedback.configure_for_storage(directory+"_feedback")
	feedback.telemetry_enabled = false
	feedback.start_session()
	feedback.level_started(&"chapter_1",&"read_once")
	_check(feedback.mark_moment(&"stuck")>0,"Voluntary feedback must work while automatic telemetry is off.")
	_check(feedback.submit_level_feedback(&"chapter_1",&"read_once",0,4,0),"A single optional rating must be accepted.")
	_check(feedback.submit_chapter_feedback(&"chapter_1",&"",&"","one note","",0),"Note-only chapter feedback must be accepted.")
	_check(feedback.submit_demo_feedback(0,0,&"","","one note",0),"Note-only whole-game feedback must be accepted.")
	_check(not feedback.submit_level_feedback(&"chapter_1",&"read_once",0,0,0),"An empty form should not manufacture feedback.")
	document = JSON.parse_string(FileAccess.get_file_as_string(feedback.export_current_session()))
	for event: Dictionary in document.events:
		_check(event.event not in ["level_start","visit_time","official_run"],"Telemetry off must not collect automatic gameplay.")
		if event.event == "level_feedback": _check(event.payload.fun == null and event.payload.clarity == 4,"Missing ratings must be null, not zero scores.")
	feedback.end_session(); feedback.free()
	var old := ClockStore.new(); old.configure_for_storage(directory+"_crash"); old.start_session()
	old.level_started(&"chapter_1",&"read_once"); old.clock_ms += 800; old._flush_time_segment()
	var recovered := ClockStore.new(); recovered.configure_for_storage(directory+"_crash"); recovered.start_session()
	_check(recovered._active_level_key.is_empty(),"A resumed process must close interrupted visits, never subtract unrelated monotonic clocks.")
	var interrupted: bool = false
	for event: Dictionary in recovered._events:
		if event.event == "level_exit": interrupted = event.payload.get("duration_unknown",false)
	_check(interrupted,"Unknown interruption gaps must be explicit.")
	old.free(); recovered.end_session(); recovered.free()
	if failures.is_empty(): print("PASS: monotonic visits, focus, milestones, cases, optional feedback and interrupted sessions"); quit(0)
	else:
		for failure: String in failures: push_error(failure)
		quit(1)
func _check(condition: bool,message: String) -> void:
	if not condition: failures.append(message)
