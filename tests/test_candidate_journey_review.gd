extends SceneTree
const Review = preload("res://experiments/candidate_session/journey_review.gd")
const RepModel = preload("res://experiments/representation_region/model.gd")
const ServiceModel = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []; var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":int(ends[i]),"codec":codecs[i]}); start = int(ends[i])
	return result
func write_raw(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(raw); file.close()
func inventory(path: String) -> Dictionary:
	var result: Dictionary = {}
	for name: String in DirAccess.get_files_at(path): result[path.path_join(name)] = FileAccess.get_file_as_bytes(path.path_join(name))
	for name: String in DirAccess.get_directories_at(path):
		result[path.path_join(name)+"/"] = true
		result.merge(inventory(path.path_join(name)))
	return result

func run() -> void:
	var base: String = "user://journey-review-"+Crypto.new().generate_random_bytes(8).hex_encode()
	var rep_path: String = base.path_join("representation/representation-session.json")
	var service_path: String = base.path_join("service/service-session.json")
	var missing: Dictionary = Review.read_pair(rep_path,service_path)
	check(missing.representation.status == "empty" and missing.service.status == "empty" and not missing.complete,"Absent domains remain empty without granting a review")
	check(not DirAccess.dir_exists_absolute(base),"Reading missing domains creates no profile directory")
	var rep_plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	var grouped: Dictionary = ServiceModel.initial_plan(); grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	var prompt: Dictionary = ServiceModel.initial_plan(); prompt.slots = 4
	var final: Dictionary = prompt.duplicate(true); final.representations = ["rle64","rle64","raw64","raw64"]
	var service_plans: Array = [grouped,prompt,final]
	var rep_supports: Array = []; var service_supports: Array = []
	for task: int in range(4,-1,-1): rep_supports.append({"task":task,"plan":rep_plans[task]})
	for task: int in range(2,-1,-1): service_supports.append({"task":task,"plan":service_plans[task]})
	var rep_saved := {"ok":true,"runs":[],"supports":rep_supports}
	var service_saved := {"ok":true,"runs":[],"supports":service_supports}
	var input_copy: Dictionary = {"representation":rep_saved.duplicate(true),"service":service_saved.duplicate(true)}
	var complete: Dictionary = Review.evaluate(rep_saved,service_saved)
	check(complete.complete and complete.representation.status == "complete" and complete.service.status == "complete","Actual five-plus-three saved plans earn combined review")
	check(complete.representation.completed == [0,1,2,3,4] and complete.service.completed == [0,1,2],"Completed IDs are independently measured and sorted")
	for task: int in 5:
		var row: Dictionary = complete.representation.evidence[task]
		check(row.task == task and row.metrics.size() == RepModel.orders(task).size(),"Representation evidence covers every authored order")
		for order: int in row.metrics.size(): check(row.metrics[order] == RepModel.run(RepModel.orders(task)[order],rep_plans[task]).metrics,"Representation review retains actual measured metrics")
	for task: int in 3: check(complete.service.evidence[task].metrics == ServiceModel.run(service_plans[task]).metrics,"Service review retains actual measured metrics")
	check(rep_saved == input_copy.representation and service_saved == input_copy.service,"Evaluation leaves all source recipes untouched")
	complete.service.evidence[0].metrics.plan.slots = 4
	complete.representation.evidence[0].metrics[0].plan[0].codec = "raw"
	check(rep_saved == input_copy.representation and service_saved == input_copy.service,"Returned evidence is independent of saved recipes")
	var legacy_rep := {"ok":true,"runs":rep_supports,"supports":[]}
	var legacy_service := {"ok":true,"runs":service_supports,"supports":[]}
	check(Review.evaluate(legacy_rep,legacy_service).complete,"Legacy retained successes revalidate without protected supports")
	var failed_rep: Array = []; var failed_service: Array = []
	for task: int in 5: failed_rep.append({"task":task,"plan":RepModel.initial_plan()})
	for task: int in 3: failed_service.append({"task":task,"plan":ServiceModel.initial_plan()})
	var failed: Dictionary = Review.evaluate({"ok":true,"supports":failed_rep,"runs":[]},{"ok":true,"supports":failed_service,"runs":[]})
	check(failed.representation.status == "partial" and failed.service.status == "partial" and failed.representation.completed.is_empty() and failed.service.completed.is_empty(),"Structurally legal unsuccessful supports grant nothing")
	check(Review.evaluate({"ok":true,"supports":failed_rep,"runs":rep_supports},{"ok":true,"supports":failed_service,"runs":service_supports}).complete,"Failed supports cannot hide independently successful retained runs")
	var forged := {"ok":true,"supports":[],"runs":[],"completed":[0,1,2,3,4],"unlocked":5,"task":4,"drafts":rep_plans,"draft":final}
	check(not Review.evaluate(forged,forged).complete,"Drafts/task/unlocked/completed flags are never completion evidence")
	var partial: Dictionary = Review.evaluate({"ok":true,"supports":[rep_supports[0]],"runs":[]},service_saved)
	check(partial.representation.completed == [4] and not partial.complete,"Each task is checked independently without inventing prerequisites")
	for error: String in ["version","recovery","schema","read"]:
		var blocked: Dictionary = Review.evaluate({"ok":false,"error":error},service_saved)
		check(blocked.representation.status == "unavailable" and blocked.representation.error == error and not blocked.complete,"Blocked domain is unavailable rather than fresh/partial: "+error)
	for invalid: Dictionary in [{},{"ok":true},{"ok":true,"runs":42},{"ok":true,"runs":[{"task":5,"plan":rep_plans[0]}]},{"ok":true,"runs":[{"task":0,"plan":[]}]}]:
		check(Review.evaluate(invalid,service_saved).representation.status == "unavailable","Malformed decoded results do not claim a readable profile")
	var stable: Dictionary = Review.evaluate(rep_saved,service_saved)
	var digest := {"representation":"rep-digest","service":"service-digest"}
	var before := {"representation":"a","service":"b"}
	var after := {"representation":"a","service":"changed"}
	var changed: Dictionary = Review.finish_snapshot(stable,digest,before,after)
	check(not changed.complete and changed.representation.error == "snapshot_changed" and changed.service.status == "unavailable","Either changed fingerprint invalidates the combined snapshot")
	check(changed.fingerprints == after and changed.digests == digest,"Snapshot receipt retains its fingerprints and read digests")
	# Test fixtures alone create/write directories. The reader never owns a lease.
	DirAccess.make_dir_recursive_absolute(rep_path.get_base_dir()); DirAccess.make_dir_recursive_absolute(service_path.get_base_dir())
	var rep_store: Script = load("res://experiments/representation_region/session_store.gd")
	var service_store: Script = load("res://experiments/service_plan/session_store.gd")
	var rep_raw: String = rep_store.encode(4,rep_plans,[],rep_supports)
	var service_raw: String = service_store.encode(2,final,[],service_supports)
	write_raw(rep_path,rep_raw); write_raw(service_path,service_raw)
	DirAccess.make_dir_absolute(rep_path.get_base_dir().path_join(".candidate-writer"))
	write_raw(rep_path.get_base_dir().path_join(".candidate-writer/owner.json"),"external-owner-do-not-touch")
	var disk_before: Dictionary = inventory(base)
	var disk: Dictionary = Review.read_pair(rep_path,service_path)
	check(disk.complete and disk.digests.representation == rep_raw.sha256_text() and disk.digests.service == service_raw.sha256_text(),"Read-only pair uses explicit paths and verified digests")
	check(inventory(base) == disk_before,"Reading complete profiles creates no locks/archives and changes no bytes")
	var legacy: Dictionary = JSON.parse_string(rep_raw); legacy.schema = 1; legacy.erase("supports"); legacy.runs = rep_supports
	write_raw(rep_path,JSON.stringify(legacy))
	check(Review.read_pair(rep_path,service_path).complete,"Actual schema1 bytes retain accepted legacy recipes")
	var future: Dictionary = JSON.parse_string(rep_raw); future.schema = 999
	write_raw(rep_path,JSON.stringify(future)); write_raw(rep_path+".bak",rep_raw)
	disk_before = inventory(base); disk = Review.read_pair(rep_path,service_path)
	check(disk.representation.status == "unavailable" and disk.representation.error == "version" and not disk.complete,"Future main cannot be bypassed by an older readable backup")
	check(inventory(base) == disk_before,"Future refusal preserves all main/backup/owner bytes")
	DirAccess.remove_absolute(rep_path) # Fixture creates the missing-main interruption.
	disk_before = inventory(base); disk = Review.read_pair(rep_path,service_path)
	check(disk.representation.status == "unavailable" and disk.representation.error == "recovery","Missing main with backup remains explicit recovery")
	check(inventory(base) == disk_before,"Review never selects a backup or repairs an interrupted profile")
	print("PASS: test_candidate_journey_review " if failures == 0 else "FAIL: test_candidate_journey_review ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
