extends SceneTree
## Authored signal fixtures verify navigation; optional captures prove renderer/focus geometry.
## They do not establish viewport clicks, native input or unaided player discovery.
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

func settle() -> void:
	for frame: int in 6: await process_frame

func capture(name: String) -> void:
	if "--closure-recovery-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var picture: Image = root.get_texture().get_image()
	var folder: String = "res://.godot/closure-recovery-captures"
	DirAccess.make_dir_recursive_absolute(folder)
	check(picture != null and picture.get_size() == Vector2i(1280,720),"Actual closure recovery capture is 1280 by 720")
	check(picture != null and picture.save_png(folder.path_join(name+".png")) == OK,"Rendered closure recovery: "+name)

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			check(argument == "--capture-size=1280x720","Closure recovery capture supports the minimum 1280x720 viewport")
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var old_path: String = Store.PATH
	Store.PATH = "user://representation-closure-navigation.json"
	var scene = load("res://experiments/representation_region/region.tscn").instantiate()
	scene.persistent_session = true; scene.candidate_journey = true
	root.add_child(scene); await process_frame; await process_frame
	# Autoload startup may restore presentation size; enforce capture geometry afterward.
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout
	await settle()
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
	scene.save_blocked = false
	for english: bool in [false,true]:
		# A stale digest reaches write_session's actual refusal and rebuilds the UI.
		# The earlier blocked-save case returns before that branch.
		scene.english = english; scene.build(); await settle()
		control(scene,"CompletedRegionReview").pressed.emit(); await process_frame
		review = scene.get_node("RegionReview") as AcceptDialog
		var previous_review_id: int = review.get_instance_id()
		var saved_version: String = scene.session_version
		var disk_before: Dictionary = Store.read_session()
		check(disk_before.ok and scene.writer_lease.owns(Store.PATH),"Real write-failure fixture has a readable isolated profile and writer ownership")
		scene.session_version = "stale-closure-digest"
		review.custom_action.emit(&"service"); await process_frame
		guard = scene.get_node("UnsavedSessionDialog") as ConfirmationDialog
		guard.hide(); guard.confirmed.emit(); await settle()
		var rebuilt_review := scene.get_node_or_null("RegionReview") as AcceptDialog
		check(rebuilt_review != null and rebuilt_review.visible and rebuilt_review.get_instance_id() != previous_review_id,"Actual write refusal reconstructs the originating earned review after the UI rebuild")
		if rebuilt_review != null:
			var focused: Control = rebuilt_review.gui_get_focus_owner()
			check(focused != null and rebuilt_review.is_ancestor_of(focused),"Reconstructed review receives keyboard focus")
			var continuation: Button = control(scene,"ContinueServiceCandidate")
			check(continuation != null,"Reconstructed review retains its Service continuation")
			var review_rect := Rect2(Vector2(rebuilt_review.position),Vector2(rebuilt_review.size))
			check(root.get_visible_rect().encloses(review_rect),"Reconstructed review fits the actual viewport")
			if continuation != null:
				check(Rect2(Vector2.ZERO,Vector2(rebuilt_review.size)).encloses(continuation.get_global_rect()),"Service continuation fits the reconstructed review")
			await capture("reconstructed-review-"+("en" if english else "zh_CN"))
		check(scene.is_inside_tree() and root.get_node_or_null("ServicePlanLab") == null and not scene.leave_from_review and scene.leave_scene.is_empty(),"Actual save failure cancels navigation and retains the Representation host")
		check(scene.session_dirty and scene.plan == draft and scene.support_plans == supports and scene.history.size() == history_before,"Actual save failure preserves the dirty draft, protected plans and recorded evidence")
		check(Store.read_session() == disk_before,"Actual write refusal leaves the isolated disk profile unchanged")
		# The rebuilt continuation must still open exactly one ordinary departure guard.
		if rebuilt_review != null:
			rebuilt_review.custom_action.emit(&"service"); await process_frame
			guard = scene.get_node("UnsavedSessionDialog") as ConfirmationDialog
			check(guard.visible and scene.leave_from_review and scene.leave_scene == "res://experiments/service_plan/lab.tscn","Reconstructed Service action retains its source and guarded destination")
			guard.hide(); guard.canceled.emit(); await process_frame
			check(rebuilt_review.visible and not scene.leave_from_review and scene.leave_scene.is_empty(),"Cancel returns to the reconstructed review")
		scene.session_version = saved_version
	scene.save_session()
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
