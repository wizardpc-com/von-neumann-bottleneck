extends SceneTree
const Creation = preload("res://src/campaign/creation_tasks.gd")
const Session = preload("res://experiments/creation/session.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func run() -> void:
	var core: Node = root.get_node("GlobalSave")
	var before: Dictionary = core._save_snapshot(); before.erase("saved_at_utc")
	var had_flag: bool = ProjectSettings.has_setting("candidate/creation_enabled")
	var flag: Variant = ProjectSettings.get_setting("candidate/creation_enabled",false)
	ProjectSettings.set_setting("candidate/creation_enabled",false)
	var nav: Node = root.get_node("TaskNavigation")
	var previous_pending: String = nav.pending
	var previous_selected: String = nav.selected
	var second_act: bool = nav.candidate_journey_enabled()
	var old: Array[Dictionary] = nav.journey_tasks()
	var original_count: int = 51 if second_act else 40
	check(nav.tasks().size() == 40 and old.size() == original_count,"Real opt-in state preserves the original forty tasks and optional eleven second-act tasks")
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	var combined: Array[Dictionary] = nav.journey_tasks()
	check(combined.size() == original_count+9 and combined.slice(0,original_count) == old,"Creation opt-in appends nine candidates without changing the real previous journey metadata")
	var added: Array[Dictionary] = Creation.build(false)
	for index: int in added.size():
		check(added[index].unlocked and added[index].dependencies.is_empty() and not added[index].recommended_from.is_empty(),"New recommendation remains guidance rather than a hidden prerequisite")
		check(Creation.index_for(Creation.key_for(index)) == index and nav.candidate_key("creation",index) == added[index].key,"Task mapping retains the exact new unit identity")
	check(Creation.index_for("creation/C1_restore/extra") == -1 and Creation.key_for(-1).is_empty(),"Malformed or out-of-range route cannot masquerade as a valid candidate")
	var session := Session.new()
	check(session.open().ok and session.data.supports.is_empty(),"Navigation fixture starts in its own empty candidate profile")
	check(session.train().ok and session.transport([0,1,0,2],"predictive").lossless,"Completed navigation evidence comes from a real learned model and packet")
	session.complete("C1_restore"); check(session.save() == OK,"Actual support is explicitly saved")
	session.close()
	var saved_rows: Array[Dictionary] = Creation.build(false)
	check(saved_rows[0].completed and not saved_rows[1].completed and saved_rows[0].progress_source == "saved","Map reads actual saved C1 support without granting neighboring task completion")
	var route: String = Creation.key_for(5)
	nav.pending = route; check(nav.take_pending("creation") == 5 and nav.pending.is_empty(),"Candidate consumes the selected unit once")
	var raw: String = FileAccess.get_file_as_string(Session.default_path())
	var unknown: Dictionary = JSON.parse_string(raw); unknown.future_content = {}
	var unknown_raw: String = JSON.stringify(unknown)
	var file := FileAccess.open(Session.default_path(),FileAccess.WRITE); file.store_string(unknown_raw); file.close()
	var refused: Array[Dictionary] = Creation.build(false)
	check(not refused[0].completed and refused[0].evidence_status == "unavailable" and FileAccess.get_file_as_string(Session.default_path()) == unknown_raw,"Read-only navigation never erases unknown fields or fabricates completion from an unreadable save")
	var after: Dictionary = core._save_snapshot(); after.erase("saved_at_utc")
	check(before == after and nav.tasks().size() == 40,"Candidate navigation and support reading never change GlobalSave authority")
	ProjectSettings.set_setting("candidate/creation_enabled",flag if had_flag else null)
	nav.pending = previous_pending; nav.selected = previous_selected
	print("PASS: creation navigation %d checks; real journey %d -> %d" % [checks,original_count,combined.size()] if failures.is_empty() else "FAIL: creation navigation "+str(failures))
	quit(0 if failures.is_empty() else 1)
