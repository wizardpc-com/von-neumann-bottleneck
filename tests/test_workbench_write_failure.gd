extends SceneTree
const Store = preload("res://src/hardware_foundations/circuit_workbench_store.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func run() -> void:
	var directory: String = "user://workbench-write-failure-"+str(Time.get_ticks_usec())
	check(DirAccess.make_dir_recursive_absolute(directory)==OK,"Fixture directory opens")
	var path: String = directory.path_join("boards.json")
	var store = Store.new(path)
	var seed: Dictionary = {"schema_version":1,"components":[{"id":"A","kind":"input"}],"layout":{"A":{"x":10,"y":20}},"wires":[]}
	store.ensure_default(&"game",&"tutorial",seed)
	check(store.create_workbench(&"game",&"tutorial","Alternate",seed)==&"","Initial named board is persisted")
	check(store.switch_workbench(&"game",&"tutorial","default"),"Initial selection is persisted")
	var saved: String = FileAccess.get_file_as_string(path)
	var before: Dictionary = store.manifest_snapshot()
	# A directory occupying the temporary file path reliably injects real I/O failure.
	check(DirAccess.make_dir_absolute(path+Store.TEMP_SUFFIX)==OK,"Block temporary file creation")
	check(store.create_workbench(&"game",&"tutorial","Lost board",seed)==&"write_failed","Creation reports an actual write failure")
	check(not store.last_error.is_empty() and store.manifest_snapshot()==before,"Failed creation retains prior names, active selection and board contents")
	check(store.create_workbench(&"test",&"new_level","Lost namespace",seed)==&"write_failed","Creation in a new namespace reports failure")
	check(store.manifest_snapshot()==before,"Failed creation removes newly introduced namespace and level")
	check(not store.switch_workbench(&"game",&"tutorial","Alternate"),"Switch reports an actual write failure")
	check(store.active_name(&"game",&"tutorial")=="default" and store.manifest_snapshot()==before,"Failed switch keeps the UI/store selection coherent")
	check(FileAccess.get_file_as_string(path)==saved,"Real failed writes leave saved player boards untouched")
	check(DirAccess.remove_absolute(path+Store.TEMP_SUFFIX)==OK,"Remove failure injection")
	var changed: Dictionary = seed.duplicate(true)
	changed.wires = [{"from":"A","from_port":0,"to":"OUT","to_port":0}]
	check(store.save_active(&"game",&"tutorial",changed),"Saving after failed switch still targets original active board")
	# Disk JSON represents numeric values as floats; compare the same serialized form.
	var restarted = Store.new(path)
	check(restarted.active_name(&"game",&"tutorial")=="default" and restarted.active_snapshot(&"game",&"tutorial")==JSON.parse_string(JSON.stringify(changed)),"Restart restores original selection and subsequent edits")
	check(restarted.workbench_snapshot(&"game",&"tutorial","Alternate")==JSON.parse_string(JSON.stringify(seed)),"Failed switch cannot redirect edits into another saved board")
	check(store.create_workbench(&"game",&"tutorial","Recovered",seed)==&"" and store.last_error.is_empty(),"Creation succeeds once storage is writable again")
	var readonly_before: Dictionary = store.manifest_snapshot()
	store.disk_write_allowed = false
	check(store.create_workbench(&"game",&"tutorial","Read-only ghost",seed)==&"write_failed","Read-only creation cannot claim success")
	check(not store.switch_workbench(&"game",&"tutorial","default") and not store.last_error.is_empty(),"Read-only switch reports a useful storage error")
	check(store.manifest_snapshot()==readonly_before,"Read-only failures preserve all player boards")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("PASS: workbench write failure %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
