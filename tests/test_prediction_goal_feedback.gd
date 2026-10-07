extends SceneTree
## Real session histories must explain the existing goals without adding gates.
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func measure(lab: Control,rule_index: int,repetitions: int = 1,pause: int = 0) -> void:
	(lab.find_child("Rule",true,false) as OptionButton).select(rule_index)
	(lab.find_child("Confidence",true,false) as OptionButton).select(repetitions-1)
	(lab.find_child("Cooldown",true,false) as OptionButton).select(0 if pause == 0 else 1)
	lab.call("edit_policy"); lab.call("run_current")
func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var original_auto_quit: bool = auto_accept_quit
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot(); before.erase("saved_at_utc")
	for en: bool in [false,true]:
		var lab = load("res://experiments/prediction/lab.tscn").instantiate()
		root.add_child(lab); await settle()
		lab.english = en; lab.build(); await settle()
		var progress: Dictionary = lab.evidence_progress(0)
		check(not progress.baseline and not progress.gain,"An empty session claims no evidence")
		check(not lab.progress_text().contains("failure" if en else "失败") and not lab.progress_text().contains("pollution" if en else "污染"),"Investigation1 never asks for failure evidence")
		lab.step_current()
		check(not lab.evidence_progress(0).baseline and not lab.goal_met(0),"A revealed prefix is not a completed baseline")
		check(not lab.progress_text().contains("150"),"Progress does not disclose hidden final costs")
		lab.run_current()
		progress = lab.evidence_progress(0)
		check(progress.baseline and not progress.gain and not lab.goal_met(0),"Recorded Off baseline advances only its own evidence condition")
		check(lab.progress_text().contains("Off baseline: recorded" if en else "关闭猜测基线：已记录") and lab.progress_text().contains("Useful and faster: pending" if en else "有用且更快：待记录"),"Feedback distinguishes the recorded baseline and missing useful gain")
		measure(lab,1)
		progress = lab.evidence_progress(0)
		check(progress.gain and not progress.failure and lab.goal_met(0),"A real faster useful run completes Investigation1 without failure")
		check(lab.status.text == lab.progress_text() and lab.status.text.contains("objective met" if en else "目标已满足"),"Visible status presents actual earned evidence")
		var first_signature: String = lab.history[0].trace.canonical_signature()

		lab.change_task(1); await settle()
		check(lab.purpose_text().contains("non-Off" if en else "非关闭") and lab.mission_text().contains("Off does not count" if en else "关闭猜测不算"),"Investigation2 states its existing non-Off requirement in both specifications")
		check(not lab.evidence_progress(1).baseline and not lab.goal_met(1),"Earlier investigation receipts cannot count toward this task")
		measure(lab,1)
		progress = lab.evidence_progress(1)
		check(progress.failure and not progress.safe,"Actual changing-stream waste is recorded as failure, not safe revision")
		check(lab.progress_text().contains("Slower with waste/pollution: recorded" if en else "更慢且有浪费/污染：已记录"),"Failure advances the public evidence progress")
		measure(lab,0)
		check(not lab.evidence_progress(1).safe and not lab.goal_met(1),"Off cannot satisfy the safe revision even at baseline cost")
		check(lab.progress_text().contains("Non-Off, no slower than baseline: pending" if en else "非关闭且不慢于基线：待记录"),"Feedback explains the precise missing condition after Off")
		measure(lab,1,2,2)
		check(lab.evidence_progress(1).safe and lab.goal_met(1),"A measured safe changing-stream revision completes the existing goal")

		lab.change_task(2); await settle()
		check(lab.purpose_text().contains("non-Off" if en else "非关闭") and lab.mission_text().contains("Off does not count" if en else "关闭猜测不算"),"Investigation3 explicitly excludes Off as the safe revision")
		measure(lab,0); measure(lab,1)
		progress = lab.evidence_progress(2)
		check(int(progress.rule_count) == 2 and progress.failure and not progress.safe and not lab.goal_met(2),"Two real rules including Off do not erase the missing safe revision")
		check(lab.progress_text().contains("Different rules: 2" if en else "不同规则：2种") and lab.progress_text().contains("Non-Off, no slower than baseline: pending" if en else "非关闭且不慢于基线：待记录"),"Feedback reports actual rule variety and remaining safe evidence")
		measure(lab,2)
		var final_record: Dictionary = lab.history.back()
		check(int(final_record.trace.metrics.prediction_bytes) == 0 and lab.goal_met(2),"A non-Off rule with no emitted predictions can still be the genuine no-slower solution")
		check(int(lab.evidence_progress(2).rule_count) == 3,"Feedback counts actual rules rather than a fabricated cap")
		lab.select_run(0)
		check(lab.goal_met(2) and lab.status.text == lab.progress_text(),"Reviewing a different task's record never changes the current task's earned progress")
		check(lab.history[0].trace.canonical_signature() == first_signature,"Feedback and record review preserve the original measured trace")
		lab.queue_free(); await settle()
		check(auto_accept_quit == original_auto_quit,"Feedback test restores existing departure handling")
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); after.erase("saved_at_utc")
	check(after == before,"Session feedback grants no persistent campaign authority")
	print("PASS: test_prediction_goal_feedback " if failures == 0 else "FAIL: test_prediction_goal_feedback ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
