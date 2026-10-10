extends SceneTree
## Profile routing uses real saved evidence in the runner's isolated player directory.
const Session = preload("res://experiments/creation/session.gd")
const Creation = preload("res://src/campaign/creation_tasks.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func run() -> void:
	var named_path: String = "user://creation-profile-navigation/named.json"
	var same_path: String = "user://creation-profile-navigation/same.json"
	var default_args: PackedStringArray = ["--creation-profile="]
	var named_args: PackedStringArray = ["--creation-profile="+named_path]
	check(Session.launch_path(default_args) == Session.default_path(),"Empty profile keeps the existing default path")
	check(Session.launch_path(["--creation-profile=earlier",named_args[0]]) == named_path,"Last profile argument retains existing launch semantics")
	var default_session := Session.new()
	check(default_session.open(Session.default_path()).get("writable",false),"Default fixture is independently writable")
	check(default_session.data.supports.is_empty() and default_session.save() == OK,"Default fixture saves without completion evidence")
	default_session.close()
	var default_bytes: String = FileAccess.get_file_as_string(Session.default_path())
	var named_session := Session.new()
	check(named_session.open(Session.launch_path(named_args)).get("writable",false),"Named fixture opens the selected launch profile")
	check(named_session.train().ok and named_session.transport([0,1,0,2],"predictive").lossless,"Named completion derives from an actual learned model and predictive packet")
	named_session.complete("C1_restore")
	check(named_session.save() == OK,"Named evidence persists in its selected profile")
	named_session.close()
	if ("--creation-profile="+named_path) in OS.get_cmdline_user_args():
		check(Creation.build(false)[0].completed,"Actual launch arguments select named completion in the map")
		root.get_node("TaskNavigation").pending = ""
		var workbench = load("res://experiments/creation/workbench.tscn").instantiate()
		root.add_child(workbench); await process_frame; await process_frame
		check(workbench.session.path == named_path and workbench.session.data.supports.has("C1_restore"),"Actual workbench launch reads the same named profile as the map")
		workbench.queue_free(); await process_frame; await process_frame
	var named_rows: Array[Dictionary] = Creation.build(false,named_args)
	check(named_rows[0].completed and not named_rows[1].completed,"Named map reads its own actual C1 evidence")
	var default_rows: Array[Dictionary] = Creation.build(false,default_args)
	check(not default_rows[0].completed,"Returning to default does not reuse named completion")
	check(FileAccess.get_file_as_string(Session.default_path()) == default_bytes,"Named navigation never modifies the default profile")
	var copied := FileAccess.open(same_path,FileAccess.WRITE)
	check(copied != null,"Identical-content second profile can be created")
	if copied != null:
		copied.store_string(FileAccess.get_file_as_string(named_path)); copied.close()
	Creation.build(false,named_args)
	var same_rows: Array[Dictionary] = Creation.build(false,["--creation-profile="+same_path])
	check(FileAccess.get_sha256(named_path) == FileAccess.get_sha256(same_path),"Cache isolation fixture has identical profile bytes")
	check(same_rows[0].completed and Creation.cached_path == same_path,"Identical profile bytes still switch cache identity to the selected path")
	check(not Creation.build(false,default_args)[0].completed,"Switching profiles repeatedly retains independent default evidence")
	print("PASS: creation profile navigation %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
