extends SceneTree
const Retry = preload("res://experiments/candidate_session/writer_retry.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const Rep = preload("res://experiments/representation_region/session_store.gd")
const Service = preload("res://experiments/service_plan/session_store.gd")
const RepModel = preload("res://experiments/representation_region/model.gd")
const ServiceModel = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func write_raw(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"QA fixture can be written")
	if file != null: file.store_string(raw); file.close()
func inventory(directory: String) -> Dictionary:
	var result: Dictionary = {}
	for name: String in DirAccess.get_files_at(directory): result[directory.path_join(name)] = FileAccess.get_file_as_bytes(directory.path_join(name))
	for name: String in DirAccess.get_directories_at(directory):
		result[directory.path_join(name)+"/"] = true
		result.merge(inventory(directory.path_join(name)))
	return result
func fixture_path(base: String, name: String) -> String:
	var directory: String = base.path_join(name)
	check(DirAccess.make_dir_recursive_absolute(directory) == OK,"QA fixture directory is isolated")
	return directory.path_join("session.json")
func refusal(result: Dictionary, reason: String, message: String) -> void:
	check(not result.ok and result.reason == reason and result.lease == null,message)
func check_released(path: String) -> void:
	var probe: RefCounted = Lease.new(path)
	check(probe.held,"Rejected retry releases its newly acquired ownership")
	probe.release()

func run() -> void:
	var base: String = "user://writer-retry-"+Crypto.new().generate_random_bytes(8).hex_encode()
	var drafts: Array = []
	for task: int in 5: drafts.append(RepModel.initial_plan())
	for store: Script in [Rep,Service]:
		var domain: String = "representation" if store == Rep else "service"
		var domain_base: String = base.path_join(domain)
		var raw: String = store.encode(0,drafts,[]) if store == Rep else store.encode(0,ServiceModel.initial_plan(),[])
		var changed_raw: String = store.encode(1,drafts,[]) if store == Rep else store.encode(1,ServiceModel.initial_plan(),[])
		var reader: Callable = store.read_session
		var path: String = fixture_path(domain_base,"normal-release")
		write_raw(path,raw)
		var owner: RefCounted = Lease.new(path)
		check(owner.held,"First candidate owns the isolated profile")
		var before: Dictionary = inventory(domain_base)
		refusal(Retry.attempt(path,raw.sha256_text(),reader),"busy","Live owner refuses retry")
		check(inventory(domain_base) == before,"Busy refusal preserves save and owner bytes")
		owner.release()
		before = inventory(domain_base)
		var acquired: Dictionary = Retry.attempt(path,raw.sha256_text(),reader)
		check(acquired.ok and acquired.reason.is_empty() and acquired.lease != null and acquired.lease.owns(path),"Normal release permits explicit retry with unchanged saved digest")
		check(not Lease.new(path).held,"Successful retry retains exclusive ownership for its caller")
		if acquired.lease != null: acquired.lease.release()
		check(inventory(domain_base) == before,"Normal retry changes no saved or archived bytes")
		# Simulate A saving a newer readable version before releasing normally.
		owner = Lease.new(path)
		check(store.write_session(changed_raw,path,raw.sha256_text(),owner) == OK,"Original owner can install its newer valid snapshot")
		owner.release(); before = inventory(domain_base)
		refusal(Retry.attempt(path,raw.sha256_text(),reader),"changed","Retry cannot adopt a changed digest to overwrite newer work")
		check(inventory(domain_base) == before,"Changed refusal leaves main/backup/archives byte-exact")
		check_released(path)
		for error: String in ["recovery","version","schema"]:
			path = fixture_path(domain_base,error)
			if error == "recovery":
				write_raw(path,raw); write_raw(path+".tmp.interrupted",raw)
			else:
				var unknown: Dictionary = JSON.parse_string(raw)
				if error == "version": unknown.schema = 999
				else: unknown["future_field"] = true
				write_raw(path,JSON.stringify(unknown)); write_raw(path+".bak",raw)
			check(store.read_session(path).get("error") == error,"Actual store exposes protected "+error+" condition")
			before = inventory(domain_base)
			refusal(Retry.attempt(path,raw.sha256_text(),reader),"unreadable","Retry refuses unsafe "+error+" condition")
			check(inventory(domain_base) == before,"Unsafe retry never recovers, selects a backup or alters source bytes")
			check_released(path)
		path = fixture_path(domain_base,"empty")
		var empty: Dictionary = Retry.attempt(path,"",reader)
		check(empty.ok and empty.lease != null and empty.lease.owns(path),"Actual store accepts an absent profile with its empty digest")
		check(not FileAccess.file_exists(path),"Empty retry does not create a save")
		if empty.lease != null: empty.lease.release()
		refusal(Retry.attempt(path,raw.sha256_text(),reader),"changed","A disappeared prior save cannot be treated as the expected snapshot")
		check_released(path)
		for malformed: Variant in [null,{}, {"ok":true}, {"ok":true,"digest":""}, {"ok":true,"digest":42}, {"ok":true,"digest":"not-a-hash"}, {"ok":"true","digest":raw.sha256_text()}]:
			var malformed_reader: Callable = func(_path: String) -> Variant: return malformed
			refusal(Retry.attempt(path,"",malformed_reader),"unreadable","Malformed reader result never grants ownership")
			check_released(path)
	print("PASS: test_candidate_writer_retry " if failures == 0 else "FAIL: test_candidate_writer_retry ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
