extends SceneTree
const Session = preload("res://experiments/creation/session.gd")
const Model = preload("res://experiments/creation/model.gd")
const SAVE_PATH := "user://creation-restart/session.json"
const EXPECTED_PATH := "user://creation-restart/expected.json"
var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func write_text(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"QA fixture can write isolated evidence")
	if file != null: file.store_string(raw); file.close()

func run() -> void:
	var phase: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--creation-phase="): phase = argument.get_slice("=",1)
	var session := Session.new()
	var opened: Dictionary = session.open(SAVE_PATH)
	check(opened.ok and opened.get("writable",false),"Fresh process owns its isolated candidate profile")
	if not opened.ok: finish(phase); return
	if phase == "write":
		check(opened.empty,"Writer starts with a genuinely empty profile")
		session.data.draft.examples = [[0,1,0,1,0,1,0,1,0,1,0,1]]
		session.data.draft.initial = [0]
		session.data.draft.length = 24
		session.data.draft.sampler = "max"
		check(session.train().ok,"Writer learns an actual selected example")
		check(session.transport([0,1,0,1,0,1],"predictive").lossless,"Writer performs actual packet recovery")
		session.complete("C1_restore")
		check(session.set_mode("predict").ok and session.begin_prediction("check").ok,"Same recovered model enters frozen checking")
		while not session.prediction.finished:
			check(session.commit_prediction().ok and session.reveal_prediction().ok,"Writer commits before each reveal")
		session.complete("P3_check")
		check(session.set_mode("generate").ok and session.generate().ok,"Checked model changes to output feedback")
		var kept: Dictionary = session.save_work("QA alternating light")
		check(kept.ok,"Writer explicitly keeps and saves a generated work")
		check(session.data.supports.has("G2_intent") and session.data.supports.has("G3_keep"),"One confirmed work completes G2 and G3 before process exit")
		if kept.ok:
			write_text(EXPECTED_PATH,JSON.stringify({"id":kept.work.id,"output":kept.work.output,"recipe":kept.work.recipe}))
		print("CALIBRATION restart original=",session.data.works[0].output," model=",Model.identity(session.data.model))
	elif phase in ["fork","read"]:
		var expected: Dictionary = Session._integers(JSON.parse_string(FileAccess.get_file_as_string(EXPECTED_PATH)))
		var played: Dictionary = session.play_work(0)
		check(played.ok and played.output == expected.output and played.work.recipe == expected.recipe and played.work.id == expected.id,"Fresh reader retains the exact original output, full recipe and identity")
		var replay: Dictionary = session.replay_work(0)
		check(replay.ok and replay.matches,"Fresh process regenerates from complete saved recipe")
		var selected: Dictionary = session.data.works[-1]
		check(session.data.supports.has("G2_intent") and session.data.supports.G2_intent.output == selected.output and session.data.supports.G2_intent.recipe == selected.recipe and session.data.supports.has("G3_keep"),"Independent restart retains completion for the latest actually chosen work")
		if phase == "fork":
			check(session.fork_work(0).ok,"Reader forks compatible actual saved work")
			session.data.draft.initial = [1]
			session.mark_dirty()
			check(session.generate().ok,"Fork performs a new output-feedback run")
			var kept: Dictionary = session.save_work("QA phase-shifted light")
			check(kept.ok and kept.work.parent == expected.id and kept.work.output != expected.output,"Fork saves a visibly different child with its actual parent")
			check(session.play_work(0).output == expected.output,"Keeping the fork does not modify the original snapshot")
		else:
			check(session.data.works.size() == 2 and session.data.works[1].parent == expected.id and session.replay_work(1).matches,"Third process retains and regenerates the saved fork")
			var original: String = FileAccess.get_file_as_string(SAVE_PATH)
			var future: Dictionary = JSON.parse_string(original); future.version = 2
			var future_raw: String = JSON.stringify(future)
			write_text(SAVE_PATH,future_raw)
			session.mark_dirty()
			check(session.save() != OK and FileAccess.get_file_as_string(SAVE_PATH) == future_raw,"Future main refuses writes despite a readable older backup")
			check(session.play_work(0).output == expected.output,"Refused future write leaves the original in-memory work available")
	else: check(false,"Unknown restart fixture phase")
	session.close()
	finish(phase)

func finish(phase: String) -> void:
	print("PASS: creation restart "+phase if failures.is_empty() else "FAIL: creation restart "+str(failures))
	quit(0 if failures.is_empty() else 1)
