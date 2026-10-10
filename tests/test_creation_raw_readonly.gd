extends SceneTree
const Session = preload("res://experiments/creation/session.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func run() -> void:
	var maker = Session.new()
	check(maker.open("user://raw-readonly/source.json").ok, "Create isolated synthetic source")
	check(maker.train().ok and maker.transport([0,1,0,2],"predictive").ok and maker.set_mode("predict").ok and maker.begin_prediction().ok, "Earn valid model and prediction")
	while not maker.prediction.finished:
		maker.commit_prediction(); maker.reveal_prediction()
	check(maker.set_mode("generate").ok and maker.generate().ok, "Generate protected work")
	check(maker.save_work("Protected legacy work").ok, "Save protected work")
	var legacy: Dictionary = maker.data.duplicate(true)
	maker.transport([0,1,0,2],"raw")
	legacy.supports.C1_restore = maker._transport_runs[-1].duplicate(true)
	var raw: String = JSON.stringify(legacy)
	var path: String = "user://raw-readonly/legacy.json"
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(raw); file.close()
	var decoded: Dictionary = Session.decode(raw)
	check(not decoded.ok and decoded.get("reason","") == "raw_restore_evidence" and decoded.readonly_works.size() == 1, "Valid old work is exposed read-only without legitimizing RAW evidence")
	var reader = Session.new()
	var opened: Dictionary = reader.open(path)
	check(opened.ok and opened.readonly and not opened.writable and opened.error == "raw_restore_readonly", "Open explains legacy RAW restriction")
	check(reader.data.works.size() == 1 and reader.replay_work(0).get("matches",false), "Protected work snapshot and recipe remain inspectable")
	check(reader.data.supports.is_empty() and not reader.set_mode("predict").ok, "False support and restored permissions are not carried forward")
	check(reader.save() != OK and FileAccess.get_file_as_string(path) == raw, "Save cannot overwrite original legacy profile")
	check(not FileAccess.file_exists(path+".bak"), "Read-only open creates no replacement backup")
	var damaged: Dictionary = legacy.duplicate(true)
	damaged.works[0].output[0] = (int(damaged.works[0].output[0])+1)%4
	var rejected: Dictionary = Session.decode(JSON.stringify(damaged))
	check(not rejected.ok and not rejected.has("readonly_works"), "Invalid work is not rescued as trusted read-only content")
	reader.close(); maker.close()
	print("PASS: creation RAW read-only %d checks" % checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
