extends SceneTree
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var lease: RefCounted
func _init() -> void: call_deferred("run")
func run() -> void:
	var path: String = ""; var operation: String = ""; var expected: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--lease-path="): path = arg.trim_prefix("--lease-path=")
		if arg.begins_with("--operation="): operation = arg.trim_prefix("--operation=")
		if arg.begins_with("--token="): expected = arg.trim_prefix("--token=")
	if operation == "stale-probe":
		# The holder is a sibling, not a child of this querying process.
		quit(0 if Lease.stopped_owner(path).is_empty() else 3); return
	if operation == "race":
		while not FileAccess.file_exists(path+".go"): await create_timer(0.01).timeout
		var result: Dictionary = Lease.recover_and_acquire(path,expected)
		if result.error == OK: lease = result.lease
		var report := FileAccess.open(path+".result."+str(OS.get_process_id()),FileAccess.WRITE)
		report.store_string("held" if lease != null and lease.held else "refused"); report.close()
		if lease == null or not lease.held: quit(2); return
		await create_timer(60).timeout
		lease.release(); quit(4); return
	if operation == "recover":
		var token: String = Lease.stopped_owner(path)
		if token.is_empty(): quit(3); return
		var result: Dictionary = Lease.recover_and_acquire(path,token)
		if result.error != OK: quit(3); return
		lease = result.lease
	else: lease = Lease.new(path)
	if not lease.held: quit(2); return
	if operation != "hold": lease.release(); quit(0); return
	var ready := FileAccess.open(path + ".ready",FileAccess.WRITE)
	ready.store_string(str(OS.get_process_id())); ready.close()
	# Parent kills this fixture to test real process interruption and stale ownership.
	await create_timer(60).timeout
	lease.release(); quit(4)
