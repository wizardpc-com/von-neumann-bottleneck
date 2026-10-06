extends SceneTree
const RM = preload("res://experiments/representation_region/model.gd")
const SM = preload("res://experiments/service_plan/model.gd")
const RS = preload("res://experiments/representation_region/session_store.gd")
const SS = preload("res://experiments/service_plan/session_store.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func partition(bounds: Array, codecs: Array) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []; var start: int = 0
	for i: int in bounds.size():
		plan.append({"start":start,"end":bounds[i],"codec":codecs[i]}); start = int(bounds[i])
	return plan
func run() -> void:
	var nav: Node = root.get_node("TaskNavigation")
	check(nav.tasks().size() == 40,"Original core catalog is independent of protected candidate evidence")
	var candidate_hub = load("res://src/ui/prototype_hub.tscn").instantiate(); candidate_hub.candidate_journey = true
	root.add_child(candidate_hub); current_scene = candidate_hub; await process_frame
	check(candidate_hub.find_child("RecommendedJourneyAction",true,false) != null,"Opt-in Hub exposes the unified journey action")
	var browse := candidate_hub.find_child("HubBrowseJourney",true,false) as Button
	check(browse != null,"Core and candidate journeys share the map entry")
	if browse != null: browse.pressed.emit()
	for frame: int in 4: await process_frame
	check(current_scene != null and current_scene.scene_file_path == nav.MAP_SCENE,"Unified entry reaches the real task tree")
	check(current_scene.get("rows").size() == (51 if nav.candidate_journey_enabled() else 40),"Candidate rows retain the actual opt-in boundary")
	current_scene.queue_free(); current_scene = null; await process_frame
	var solutions: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	var scene = load("res://experiments/representation_region/region.tscn").instantiate(); scene.persistent_session = true; root.add_child(scene); await process_frame
	for task: int in 5:
		scene.change_task(task); scene.edit_plan(solutions[task]); scene.run_current()
	check(not scene.completed.has(false) and scene.support_plans.size() == 5,"Five tasks protect current-model successful plans")
	scene.show_closure(); await process_frame
	check(scene.has_node("RegionReview") and scene.get_node("RegionReview").visible,"Five-task journey has a reachable region closure")
	check(scene.get_node("RegionReview").find_child("RegionReviewContent",true,false).text.contains("周期"),"Region closure presents re-evaluated successful-plan costs")
	scene.get_node("RegionReview").hide()
	var old_review: int = scene.get_node("RegionReview").get_instance_id()
	scene.show_closure(); await process_frame
	check(scene.get_node("RegionReview").get_instance_id() != old_review,"Region review rebuilds from current protected evidence each time")
	scene.get_node("RegionReview").hide()
	var support_copy: Dictionary = scene.support_plans.duplicate(true)
	scene.edit_plan(RM.initial_plan())
	for i: int in 105: scene.run_current()
	check(scene.history.size() == 100 and scene.history.all(func(row: Dictionary) -> bool: return not row.accepted),"History cap evicts all success records")
	check(scene.support_plans == support_copy,"Exploration and draft edits do not mutate protected evidence")
	scene.save_session(); check(not scene.session_dirty,"Long session saves")
	scene.queue_free(); await process_frame; await process_frame
	scene = load("res://experiments/representation_region/region.tscn").instantiate(); scene.persistent_session = true; root.add_child(scene); await process_frame
	check(not scene.completed.has(false) and scene.support_plans == support_copy,"Reload recomputes all five completions despite failed recent history")
	check(scene.plan == RM.initial_plan(),"Failed/exploratory draft preserved independently")
	scene.edit_plan(solutions[4]); scene.request_hub(); await process_frame
	check(scene.get_node("UnsavedSessionDialog").visible and scene.leave_to_hub,"Returning home protects unsaved exploration")
	scene.get_node("UnsavedSessionDialog").hide(); scene.get_node("UnsavedSessionDialog").canceled.emit()
	check(scene.session_dirty,"Cancel return-home keeps unsaved work")
	for task: int in 5:
		scene.change_task(task); scene.restore_support()
		check(scene.plan == solutions[task],"Protected support remains recoverable for task"+str(task))
	check(scene.support_plans == support_copy,"Recovering a support into draft never mutates the original")
	scene.queue_free(); await process_frame; await process_frame
	# Structurally legal support fields are not completion authority.
	var fake: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RS.PATH)); fake.runs = []
	for support: Dictionary in fake.supports: support.plan = RM.initial_plan()
	var file := FileAccess.open(RS.PATH,FileAccess.WRITE); file.store_string(JSON.stringify(fake)); file.close()
	scene = load("res://experiments/representation_region/region.tscn").instantiate(); scene.persistent_session = true; root.add_child(scene); await process_frame
	check(scene.support_plans.is_empty() and not scene.completed.has(true),"Unsuccessful support is recomputed and grants nothing")
	scene.queue_free(); await process_frame; await process_frame
	var first: Dictionary = SM.initial_plan(); first.groups = []
	for i: int in 24: first.groups.append([i])
	var second: Dictionary = SM.initial_plan(); second.slots = 4
	var third: Dictionary = second.duplicate(true); third.representations = ["rle64","rle64","raw64","raw64"]
	var service_plans: Array = [first,second,third]
	var lab = load("res://experiments/service_plan/lab.tscn").instantiate(); lab.persistent_session = true; root.add_child(lab); await process_frame
	for task: int in 3:
		lab.change_task(task); lab.edit(service_plans[task],0); lab.run_current()
	check(lab.unlocked == 2 and lab.support_plans.size() == 3,"Three accepted contracts protect independent plans")
	var supports: Dictionary = lab.support_plans.duplicate(true)
	var unfinished: Dictionary = SM.move(SM.initial_plan(),4,-4); lab.edit(unfinished,0)
	for i: int in 85: lab.run_current()
	check(lab.history.size() == 80 and lab.history.all(func(row: Dictionary) -> bool: return not str(row.metrics.error).is_empty()),"Service history cap evicts all successful evidence")
	check(lab.support_plans == supports,"Unfinished edits never mutate service support")
	lab.save_session(); check(not lab.session_dirty,"Service long session saved")
	lab.queue_free(); await process_frame; await process_frame
	lab = load("res://experiments/service_plan/lab.tscn").instantiate(); lab.persistent_session = true; root.add_child(lab); await process_frame
	check(lab.unlocked == 2 and lab.task == 2 and lab.support_plans == supports,"Service unlocks and selection survive history eviction/restart")
	check(lab.plan == unfinished,"Unfinished service draft survives independently")
	for task: int in 3:
		lab.change_task(task); lab.restore_support(); check(lab.plan == service_plans[task],"Recover protected service plan"+str(task))
	lab.queue_free(); await process_frame; await process_frame
	# A failed in-window save refreshes recovery choices without resetting live work.
	var candidate = load("res://experiments/service_plan/lab.tscn").instantiate(); candidate.persistent_session = true; root.add_child(candidate); await process_frame
	candidate.edit(second,0)
	var draft_before: Dictionary = candidate.plan.duplicate(true)
	var runs_before: Array = candidate.history.duplicate(true)
	var interrupted_raw: String = SS.encode(candidate.task,candidate.plan,[],candidate.support_records())
	check(SS.write_session(interrupted_raw,SS.PATH,candidate.session_version,candidate.writer_lease,"temporary") == ERR_BUSY,"Inject failed install while scene keeps its lease")
	candidate.save_session(); await process_frame
	check(candidate.session_dirty and candidate.plan == draft_before and candidate.history == runs_before,"Failed save keeps unsaved draft and measured history")
	check(candidate.find_child("RecoverSnapshot",true,false) != null,"Failed save exposes snapshot recovery in the current window")
	candidate.find_child("RecoverSnapshot",true,false).pressed.emit(); await process_frame
	check(candidate.has_node("ReplaceUnsavedRecovery") and candidate.get_node("ReplaceUnsavedRecovery").visible,"Recovery asks before replacing unsaved window work")
	candidate.get_node("ReplaceUnsavedRecovery").canceled.emit(); await process_frame
	check(candidate.plan == draft_before and candidate.session_dirty,"Cancelling recovery preserves unsaved exploration")
	candidate.queue_free(); await process_frame; await process_frame
	print("PASS: test_candidate_supports " if failures == 0 else "FAIL: test_candidate_supports ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
