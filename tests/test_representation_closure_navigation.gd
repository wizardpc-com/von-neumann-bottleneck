extends SceneTree
## Authored fixtures verify closure navigation, not unaided player discovery.
const Store = preload("res://experiments/representation_region/session_store.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":int(ends[i]),"codec":codecs[i]}); start = int(ends[i])
	return result
func control(scene: Node, handle: String) -> Button:
	return scene.find_child(handle,true,false) as Button

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var old_path: String = Store.PATH
	Store.PATH = "user://representation-closure-navigation.json"
	var scene = load("res://experiments/representation_region/region.tscn").instantiate()
	scene.persistent_session = true; scene.candidate_journey = true
	root.add_child(scene); await process_frame; await process_frame
	check(not control(scene,"CompletedRegionReview").visible,"Fresh drafts have no earned review action")
	# A marker alone must not turn the new action into an achievement.
	scene.completed.assign([true,true,true,true,true]); scene.refresh_tasks()
	check(not control(scene,"CompletedRegionReview").visible and control(scene,"RegionClosure").disabled,"Completion flags without protected recipes grant no review")
	scene.completed.assign([false,false,false,false,false])
	var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for task: int in 5:
		scene.change_task(task); scene.edit_plan(plans[task]); scene.run_current()
		check(control(scene,"CompletedRegionReview").visible == (task == 4),"Action appears only after all five measured successes")
	var history_before: int = scene.history.size()
	var supports: Dictionary = scene.support_plans.duplicate(true)
	var draft: Array = scene.plan.duplicate(true)
	check(scene.session_dirty,"Completing the region does not silently save")
	for english: bool in [false,true]:
		scene.english = english; scene.build(); await process_frame; await process_frame
		var action: Button = control(scene,"CompletedRegionReview")
		check(action.visible and action.get_global_rect().end.x <= 1281,"Bilingual earned action fits minimum width")
		action.pressed.emit(); await process_frame
		var review := scene.get_node("RegionReview") as AcceptDialog
		check(review.visible and control(scene,"ContinueServiceCandidate") != null,"Earned action opens actual results and next-stage choice")
		check(scene.history.size() == history_before and scene.support_plans == supports and scene.plan == draft and scene.session_dirty,"Review preserves draft, evidence, protected results and dirty state")
		review.custom_action.emit(&"service"); await process_frame
		var guard := scene.get_node("UnsavedSessionDialog") as ConfirmationDialog
		check(guard.visible and scene.leave_scene == "res://experiments/service_plan/lab.tscn","Next stage uses the existing unsaved-work guard")
		guard.hide(); guard.canceled.emit(); await process_frame
		check(review.visible and scene.plan == draft and scene.session_dirty,"Cancel returns to the earned review with exploration intact")
		check(not scene.leave_from_review and scene.leave_scene.is_empty(),"Canceled review departure clears only transient navigation intent")
		check(guard.get_signal_connection_list("canceled").size() == 1 and guard.get_signal_connection_list("confirmed").size() == 1,"Repeated review requests retain one centralized handler per guard signal")
		review.hide()
	# Saving failure cannot erase the place from which the player chose to continue.
	control(scene,"CompletedRegionReview").pressed.emit(); await process_frame
	var review := scene.get_node("RegionReview") as AcceptDialog
	review.custom_action.emit(&"service"); await process_frame
	scene.save_blocked = true
	var guard := scene.get_node("UnsavedSessionDialog") as ConfirmationDialog
	guard.hide(); guard.confirmed.emit(); await process_frame
	check(scene.session_dirty and review.visible and scene.plan == draft,"Failed Save keeps the review and unsaved plan available")
	check(not scene.leave_from_review and scene.leave_scene.is_empty(),"Save failure clears the canceled destination")
	check(guard.get_signal_connection_list("canceled").size() == 1 and guard.get_signal_connection_list("confirmed").size() == 1,"Save failure adds no stale counterpart callbacks")
	scene.save_blocked = false; scene.save_session()
	check(not scene.session_dirty and Store.read_session().supports.size() == 5,"Explicit Save alone persists all earned plans")
	scene.queue_free(); await process_frame; await process_frame
	var reopened = load("res://experiments/representation_region/region.tscn").instantiate()
	reopened.persistent_session = true; reopened.candidate_journey = true; root.add_child(reopened)
	await process_frame; await process_frame
	check(control(reopened,"CompletedRegionReview").visible and not reopened.session_dirty,"Restart retains the earned action without adding a dirty change")
	check(reopened.representation_review_evidence().size() == 5,"Restart revalidates all protected recipes")
	reopened.queue_free(); await process_frame; await process_frame
	Store.PATH = old_path
	print("PASS: test_representation_closure_navigation " if failures == 0 else "FAIL: test_representation_closure_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
