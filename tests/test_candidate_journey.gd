extends SceneTree
const Context = preload("res://experiments/candidate_session/context.gd")
const Rep = preload("res://experiments/representation_region/session_store.gd")
const Service = preload("res://experiments/service_plan/session_store.gd")
var failures: int = 0
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	var base := "/synthetic/VonNeumannBottleneckCandidates/representation/QA"
	check(Context.resolve_path("representation","representation","QA",base) == "user://representation-session.json","Existing representation profile keeps original file")
	check(Context.resolve_path("service","representation","QA",base) == "/synthetic/VonNeumannBottleneckCandidates/service/QA/service-session.json","Cross-domain entry uses original sibling service profile")
	check(Context.resolve_path("representation","service","QA",base.replace("representation","service")) == base + "/representation-session.json","Reverse entry resolves same representation profile")
	check(Context.resolve_path("service","representation","../real",base) == "user://service-session.json","Unsafe profile never traverses a path")
	check(Context.resolve_path("service","representation","QA","/synthetic/campaign") == "user://service-session.json","Unbound campaign path cannot become sibling authority")
	check(Rep.PATH == "user://representation-session.json" and Service.PATH == "user://service-session.json","Ordinary tests and standalone defaults retain existing paths")
	check(Context.configured_journey_for(true,"representation","QA",base),"Packaged journey opts in only with a bound candidate profile")
	check(Context.configured_journey_for(true,"service","QA",base.replace("representation","service")),"Service-primary bound package resolves its sibling safely")
	check(not Context.configured_journey_for(false,"representation","QA",base),"Default package/source startup remains opt-in")
	check(not Context.configured_journey_for("true","representation","QA",base),"Wrong setting type cannot enable persistence")
	check(not Context.configured_journey_for(true,"representation","../real",base),"Unsafe packaged profile cannot grant save authority")
	check(not Context.configured_journey_for(true,"representation","QA","/synthetic/campaign"),"Campaign directory refuses automatic candidate persistence")
	var save: Node = root.get_node("GlobalSave")
	var before: Dictionary = save._save_snapshot(); before.erase("saved_at_utc")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var hub = load("res://src/ui/prototype_hub.tscn").instantiate(); hub.candidate_journey = true
		root.add_child(hub); await process_frame; await process_frame
		check(hub.find_child("EnterRepresentationCandidate",true,false) != null,"Representation candidate entry exists in " + locale)
		check(hub.find_child("EnterServiceCandidate",true,false) != null,"Service candidate entry exists in " + locale)
		check(not hub.find_child("EnterServiceCandidate",true,false).text.is_empty(),"Localized service entry is understandable")
		hub.queue_free(); await process_frame
	var normal = load("res://src/ui/prototype_hub.tscn").instantiate(); root.add_child(normal); await process_frame
	check(normal.find_child("EnterServiceCandidate",true,false) == null,"Ordinary core hub remains opt-in")
	normal.queue_free(); await process_frame
	var after: Dictionary = save._save_snapshot(); after.erase("saved_at_utc")
	check(before == after,"Candidate entry presentation grants no core40 progress")
	print("PASS: test_candidate_journey " if failures == 0 else "FAIL: test_candidate_journey ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
