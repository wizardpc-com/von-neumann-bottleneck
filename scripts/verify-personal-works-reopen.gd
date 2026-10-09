extends SceneTree
## Independent-process QA readback; never target a real player-data directory.
const Session = preload("res://experiments/creation/session.gd")
const Focus = preload("res://experiments/creation/work_focus.gd")
var folder: String = ""
var failures: Array[String] = []
var checks: int = 0
var report: Dictionary = {"evidence_kind":"independent-process-session-readback", "checks":0, "failures":[]}
var session: RefCounted
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> bool:
	checks += 1
	if not value: failures.append(message); push_error(message)
	return value
func finish() -> void:
	report.checks=checks; report.failures=failures
	if not folder.is_empty():
		var file := FileAccess.open(folder.path_join("reopen-report.json"),FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(report,"\t")); file.close()
		else: push_error("Cannot write reopen-report.json"); failures.append("report_write")
	if session != null: session.close()
	print("PASS: personal works independent reopen %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
func read_json(name: String) -> Variant:
	var path: String = folder.path_join(name)
	if not check(FileAccess.file_exists(path),"Evidence export exists: "+name): return null
	return Session._integers(JSON.parse_string(FileAccess.get_file_as_string(path)))
func settle() -> void:
	for frame: int in 3: await process_frame
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): folder=argument.trim_prefix("--evidence-dir=")
	if not check(not folder.is_empty(),"Explicit evidence directory supplied"): finish(); return
	var a: Variant = read_json("work-A.json")
	var b: Variant = read_json("work-B.json")
	var exported: Variant = read_json("session.json")
	if not check(a is Dictionary and b is Dictionary and exported is Dictionary,"Exports parse as complete snapshots"): finish(); return
	var decoded: Dictionary = Session.decode(JSON.stringify(exported))
	if not check(decoded.get("ok",false),"Frozen exported session validates"): finish(); return
	session=Session.new()
	var opened: Dictionary = session.open(Session.launch_path())
	if not check(opened.get("ok",false) and opened.get("writable",false) and not opened.get("empty",false),"Saved QA profile reopens independently with writer lease"): finish(); return
	report.profile=session.path
	if not check(session.data==decoded.data,"Independent profile matches frozen exported session"): finish(); return
	if not check(session.data.works.size()==2 and session.data.works[0]==a and session.data.works[1]==b,"Saved A/B recipes and symbols exactly match exports"): finish(); return
	var originals: Array = session.data.works.duplicate(true)
	var before_data: String = JSON.stringify(session.data)
	var before_disk: String = FileAccess.get_file_as_string(session.path)
	var provenance: Dictionary = session.design_provenance()
	report.design_provenance=provenance.duplicate(true)
	check(provenance.get("source","")=="controlled-design-v1" and provenance.get("observation",false) and provenance.get("observed_change",false),"Saved controlled-design provenance is revalidated")
	for index: int in 2:
		var replay: Dictionary = session.replay_work(index)
		check(replay.get("ok",false) and replay.get("matches",false),"Saved recipe replay matches protected work "+str(index))
		var view = Focus.new(); view.configure(originals[index],true,replay); root.add_child(view); await settle()
		view.mapping_choice.select(1); view.static_overview=true; view.sync_presentation()
		check(view.canvas.output==originals[index].output and view.canvas.viewing_mapping=="light-shapes-v1" and view.work==originals[index],"Old mapping remains available on reopened immutable snapshot")
		view.dismiss(); await settle()
	check(JSON.stringify(session.data)==before_data and FileAccess.get_file_as_string(session.path)==before_disk,"Static viewing and replay preserve reopened session and file bytes")
	var forked: Dictionary = session.fork_work(1)
	if not check(forked.get("ok",false),"Saved B forks into an editable recipe draft"): finish(); return
	var generated: Dictionary = session.generate()
	if not check(generated.get("ok",false) and generated.get("output",[])==b.output,"Unchanged child recipe regenerates the exact parent symbols"): finish(); return
	var saved: Dictionary = session.save_work("独立重开 · B 的下一份 / Reopened B child")
	if not check(saved.get("ok",false),"Generated child saves as a distinct named work"): finish(); return
	check(session.data.works.size()==3 and session.data.works[0]==originals[0] and session.data.works[1]==originals[1] and session.data.works[2].parent==b.id,"Child save preserves both originals and records actual parent lineage")
	check(session.data.works[2].id!=b.id and session.replay_work(2).get("matches",false),"New child has distinct identity and a replayable full recipe")
	report.child=session.data.works[2].duplicate(true)
	report.original_ids=[a.id,b.id]
	finish()
