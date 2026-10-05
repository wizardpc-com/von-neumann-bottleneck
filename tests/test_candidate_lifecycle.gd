extends SceneTree
const Rep = preload("res://experiments/representation_region/session_store.gd")
const Service = preload("res://experiments/service_plan/session_store.gd")
const RM = preload("res://experiments/representation_region/model.gd")
const SM = preload("res://experiments/service_plan/model.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func raw_write(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(raw); file.close()
func saved_bytes(paths: Array[String]) -> Dictionary:
	var originals: Dictionary = {}
	for path: String in paths: originals[path] = FileAccess.get_file_as_string(path)
	return originals
func process_args(path: String, operation: String) -> PackedStringArray:
	return ["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/fixtures/candidate_lease_process.gd","--","--lease-path="+path,"--operation="+operation]
func run() -> void:
	# Conservative native-query parsing is verified even on non-Mac test hosts.
	var uuid: String = "12345678-abcd-4abc-8def-123456789abc"
	check(Lease._macos_boot_context(uuid.to_upper()+"\n") == "macos:"+uuid,"Mac boot identity normalizes native UUID output")
	for unknown: String in ["","kern.bootsessionuuid: "+uuid,"1234-abcd","00000000-0000-0000-0000-000000000000",uuid+"\npermission denied"]:
		check(Lease._macos_boot_context(unknown).is_empty(),"Unknown/malformed Mac boot output refuses identity")
	check(Lease._macos_snapshot_stopped(0," 11\n 22\n",33,11),"Successful native PID snapshot can prove absence")
	check(not Lease._macos_snapshot_stopped(0," 11\n 22\n",22,11),"Live/reused PID remains protected")
	for unknown: String in ["","22\n","11\nps: permission denied\n","11\n+22\n","11\n22 33\n"]:
		check(not Lease._macos_snapshot_stopped(0,unknown,33,11),"Incomplete/malformed native PID snapshot refuses recovery")
	check(not Lease._macos_snapshot_stopped(1,"11\n",33,11),"Native command failure never means stopped")
	var drafts: Array = []
	for i: int in 5: drafts.append(RM.initial_plan())
	var rep_raw: String = Rep.encode(0,drafts,[])
	var service_raw: String = Service.encode(0,SM.initial_plan(),[])
	for store: Script in [Rep,Service]:
		var raw: String = rep_raw if store == Rep else service_raw
		var legacy: Dictionary = JSON.parse_string(raw); legacy.schema = 1; legacy.erase("supports")
		check(store.decode(JSON.stringify(legacy)).ok,"Schema1 remains readable without granting completion")
		for first: bool in [true,false]:
			for stage: String in ["temporary","validated","archived","backed_up","installed"]:
				var path: String = "user://"+("rep" if store == Rep else "service")+str(first)+stage+".json"
				var expected: String = ""
				if not first:
					raw_write(path,JSON.stringify(legacy)); expected = JSON.stringify(legacy).sha256_text()
					raw_write(path+".bak",raw) # Existing backup must survive too.
				check(store.write_session(raw,path,expected,null,stage) == ERR_BUSY,"Inject interruption after " + stage)
				var state: Dictionary = store.read_session(path)
				check(not state.get("empty",false),"Interrupted install never appears as new profile")
				if stage == "installed":
					check(state.ok,"Installed snapshot is readable after interruption")
				else:
					check(state.get("error") == "recovery" and not state.choices.is_empty(),"Interrupted install offers explicit valid candidates")
					var paths: Array[String] = store.Files.transaction_paths(path)
					var originals := saved_bytes(paths)
					check(store.write_session(raw,path,expected) == ERR_INVALID_DATA,"No implicit overwrite while recovery pending")
					var source: String = state.choices[-1].path
					check(store.recover_session(source,state.fingerprint,path) == OK,"Chosen snapshot recovers")
					for original: String in originals:
						var archived: String = (path+".snapshots").path_join(str(originals[original]).sha256_text()+".json")
						check(FileAccess.get_file_as_string(archived) == originals[original],"Every interrupted original retained byte-for-byte")
					state = store.read_session(path)
					check(state.ok,"Recovered profile readable")
				check(store.write_session(raw,path,state.digest) == OK,"Save again after recovery/installed interruption")
		var partial_path: String = "user://partial-archive-"+("rep" if store == Rep else "service")+".json"
		raw_write(partial_path,JSON.stringify(legacy)); raw_write(partial_path+".tmp.interrupted",raw)
		DirAccess.make_dir_absolute(partial_path+".snapshots")
		var damaged_target: String = (partial_path+".snapshots").path_join(JSON.stringify(legacy).sha256_text()+".json")
		raw_write(damaged_target,"partial copy")
		var interrupted: Dictionary = store.read_session(partial_path)
		check(store.recover_session(partial_path+".tmp.interrupted",interrupted.fingerprint,partial_path) == OK,"Partial hash-named snapshot cannot strand valid recovery")
		check(FileAccess.get_file_as_string(damaged_target) == JSON.stringify(legacy),"Valid original archived despite interrupted old copy")
		var retained_damage: bool = false
		for name: String in DirAccess.get_files_at(partial_path+".snapshots"):
			if name.contains(".damaged-") and FileAccess.get_file_as_string((partial_path+".snapshots").path_join(name)) == "partial copy": retained_damage = true
		check(retained_damage,"Damaged archive itself retained for inspection")
		var path: String = "user://corrupt"+("rep" if store == Rep else "service")+".json"
		raw_write(path,"{broken"); raw_write(path+".bak",raw)
		var state: Dictionary = store.read_session(path)
		check(state.get("error") == "recovery" and state.choices.size() == 1,"Corrupt main exposes valid backup")
		var old_fingerprint: String = state.fingerprint
		raw_write(path,"{changed")
		check(store.recover_session(path+".bak",old_fingerprint,path) == ERR_ALREADY_IN_USE,"Recovery refuses changed disk state")
		state = store.read_session(path)
		check(store.recover_session(path+".bak",state.fingerprint,path) == OK,"Explicit corrupt-main recovery")
		check(FileAccess.get_file_as_string((path+".snapshots").path_join("{changed".sha256_text()+".json")) == "{changed","Corrupt original remains inspectable")
		var future: Dictionary = JSON.parse_string(raw); future.schema = 999
		raw_write(path,JSON.stringify(future)); raw_write(path+".bak",raw)
		check(store.read_session(path).get("error") == "version","Future main never bypassed with backup")
		check(store.recover_session(path+".bak",store.Files.fingerprint(path),path) != OK,"Future main recovery refused")
		check(store.write_session(raw,path) != OK and FileAccess.get_file_as_string(path) == JSON.stringify(future),"Future original unchanged")
		var unknown: Dictionary = JSON.parse_string(raw); unknown.erase("supports"); unknown["new_evidence"] = []
		raw_write(path,JSON.stringify(unknown))
		check(store.read_session(path).get("error") == "schema","Unknown replacement field is protected schema, not recoverable corruption")
		check(store.recover_session(path+".bak",store.Files.fingerprint(path),path) != OK,"Unknown-field main cannot be bypassed via old backup")
	# Same-process and independent-process exclusion cover the entire lease lifetime.
	var path: String = ProjectSettings.globalize_path("user://concurrent.json")
	var lease = Lease.new(path); var second = Lease.new(path)
	check(lease.held and not second.held,"Only one lease in a process")
	var native_recovery: bool = not Lease.local_context().is_empty()
	if OS.get_name() == "macOS": native_recovery = native_recovery and not Lease._macos_process_pids().is_empty()
	check(Service.write_session(service_raw,"user://other-domain.json") == ERR_ALREADY_IN_USE,"Lease covers the whole profile across candidate domains")
	check(Rep.write_session(rep_raw,path) == ERR_ALREADY_IN_USE,"Every public writer requires ownership")
	check(Rep.write_session(rep_raw,path,"",lease) == OK,"Owned writer can install")
	var output: Array = []
	check(OS.execute(OS.get_executable_path(),process_args(path,"probe"),output,true) == 2,"Independent process refused while owner lives")
	check(Lease.stopped_owner(path).is_empty(),"Live sibling/current PID is never stale")
	lease.release()
	check(OS.execute(OS.get_executable_path(),process_args(path,"probe"),output,true) == 0,"Independent process succeeds after release")
	var pid: int = OS.create_process(OS.get_executable_path(),process_args(path,"hold"))
	var deadline: int = Time.get_ticks_msec()+10000
	while not FileAccess.file_exists(path+".ready") and Time.get_ticks_msec() < deadline: await create_timer(0.05).timeout
	check(FileAccess.file_exists(path+".ready"),"Independent holder became ready")
	check(not Lease.new(path).held and Lease.stopped_owner(path).is_empty(),"Live independent writer cannot be stolen")
	var owner_path: String = Lease.lock_path(path).path_join("owner.json")
	var live_owner: String = FileAccess.get_file_as_string(owner_path)
	check(OS.execute(OS.get_executable_path(),process_args(path,"stale-probe"),output,true) == 0,"A live sibling writer is never reported stopped")
	check(FileAccess.get_file_as_string(owner_path) == live_owner,"Read-only sibling query retains owner bytes")
	check(OS.kill(pid) == OK,"Abruptly stop isolated writer fixture")
	check(not Lease.new(path).held,"Crash does not silently discard lock")
	if native_recovery:
		deadline = Time.get_ticks_msec()+10000
		while Lease.stopped_owner(path).is_empty() and Time.get_ticks_msec() < deadline: await create_timer(0.05).timeout
		check(not Lease.stopped_owner(path).is_empty(),"Native query confirms abrupt holder has stopped")
		var original_owner: String = FileAccess.get_file_as_string(owner_path)
		var owner: Dictionary = JSON.parse_string(original_owner)
		for context: String in ["","foreign-boot-or-pid-namespace"]:
			var foreign_owner: Dictionary = owner.duplicate(true); foreign_owner.context = context
			raw_write(owner_path,JSON.stringify(foreign_owner))
			check(Lease.stopped_owner(path).is_empty(),"Foreign/missing boot/process context cannot be guessed stale")
		var legacy_owner: Dictionary = owner.duplicate(true); legacy_owner.erase("context")
		raw_write(owner_path,JSON.stringify(legacy_owner))
		check(Lease.stopped_owner(path).is_empty(),"Older owner without local identity remains protected")
		var reused_owner: Dictionary = owner.duplicate(true); reused_owner.pid = OS.get_process_id()
		raw_write(owner_path,JSON.stringify(reused_owner))
		check(Lease.stopped_owner(path).is_empty(),"Stopped-owner record with a currently live PID cannot be reclaimed")
		var malformed_owner: Dictionary = owner.duplicate(true); malformed_owner.token = "invalid-token"
		raw_write(owner_path,JSON.stringify(malformed_owner))
		check(Lease.stopped_owner(path).is_empty(),"Malformed owner token remains protected")
		raw_write(owner_path,original_owner)
		var token: String = Lease.stopped_owner(path)
		check(Lease.recover_and_acquire(path,"00000000000000000000000000000000").error == ERR_ALREADY_IN_USE,"Recovery refuses a stale displayed token")
		check(FileAccess.get_file_as_string(owner_path) == original_owner,"Refused recovery preserves exact owner record")
		var race_args: PackedStringArray = process_args(path,"race"); race_args.append("--token="+token)
		var racers: Array[int] = [OS.create_process(OS.get_executable_path(),race_args),OS.create_process(OS.get_executable_path(),race_args)]
		raw_write(path+".go","start")
		deadline = Time.get_ticks_msec()+10000
		for racer: int in racers:
			while not FileAccess.file_exists(path+".result."+str(racer)) and Time.get_ticks_msec() < deadline: await create_timer(0.05).timeout
		var winners: int = 0
		for racer: int in racers:
			if FileAccess.file_exists(path+".result."+str(racer)) and FileAccess.get_file_as_string(path+".result."+str(racer)) == "held":
				winners += 1; OS.kill(racer)
		check(winners == 1,"Two independent recovery claimants produce exactly one held writer")
		deadline = Time.get_ticks_msec()+10000
		while Lease.stopped_owner(path).is_empty() and Time.get_ticks_msec() < deadline: await create_timer(0.05).timeout
		check(OS.execute(OS.get_executable_path(),process_args(path,"recover"),output,true) == 0,"Explicit stopped-owner recovery in another process")
		check(FileAccess.get_file_as_string((Lease.lock_path(path)+".abandoned-"+token).path_join("owner.json")) == original_owner,"Reclamation archives exact interrupted owner bytes")
		check(FileAccess.get_file_as_string(path) == rep_raw,"Ownership recovery never changes save bytes")
	else:
		check(Lease.stopped_owner(path).is_empty(),"Unavailable native identity/query conservatively refuses recovery")
		check(FileAccess.get_file_as_string(owner_path) == live_owner,"Unavailable native recovery retains interrupted owner bytes")
		check(FileAccess.get_file_as_string(path) == rep_raw,"Unavailable native recovery retains save bytes")
		print("SKIP: native stopped-owner recovery/race — host identity or process query unavailable; refusal verified")
	# Gate makes competing recovery/acquisition conservative.
	check(DirAccess.make_dir_absolute(Lease.lock_path(path)+".recovering") == OK,"Create isolated recovery-in-progress gate")
	check(not Lease.new(path).held,"No new writer while recovery gate exists")
	DirAccess.remove_absolute(Lease.lock_path(path)+".recovering")
	print("PASS: test_candidate_lifecycle " if failures == 0 else "FAIL: test_candidate_lifecycle ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
