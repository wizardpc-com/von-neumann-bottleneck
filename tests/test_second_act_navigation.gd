extends SceneTree
const Region = preload("res://experiments/representation_region/region.gd")
const RepModel = preload("res://experiments/representation_region/model.gd")
class RegionProbe extends "res://experiments/representation_region/region.gd":
	var destinations: Array[String] = []
	func finish_leave() -> void: destinations.append(leave_scene)
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []; var start: int = 0
	for i: int in ends.size(): result.append({"start":start,"end":ends[i],"codec":codecs[i]}); start = ends[i]
	return result
func run() -> void:
	root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
	var core_before: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_before.erase("saved_at_utc")
	var scene := RegionProbe.new(); scene.candidate_journey = true; root.add_child(scene); await process_frame
	scene.completed = [true,true,true,true,true]
	scene.show_closure(); scene.request_service()
	check(not scene.has_node("RegionReview") and scene.destinations.is_empty(),"Flags without protected accepted recipes cannot open review or cross-stage continuation")
	var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for id: int in 5:
		scene.change_task(id); scene.edit_plan(plans[id]); scene.run_current()
	check(scene.representation_review_evidence().size() == 5,"Five independently measured tasks earn next-stage evidence")
	var supports: Dictionary = scene.support_plans.duplicate(true)
	for en: bool in [false,true]:
		scene.english = en; scene.show_closure(); await process_frame; await process_frame
		var review := scene.get_node("RegionReview") as AcceptDialog
		check(review.visible and review.find_child("ContinueServiceCandidate",true,false) != null,"Earned optional continuation is offered in both languages")
		check(review.size.x <= 1280 and review.size.y <= 720,"Earned review fits minimum logical window")
		check(review.find_child("RegionReviewContent",true,false).text.contains("不会自动") if not en else review.find_child("RegionReviewContent",true,false).text.contains("do not transfer"),"Review explains that plans do not transfer between models")
		review.hide()
	scene.persistent_session = true; scene.session_dirty = true
	scene.request_service(); await process_frame
	check(scene.has_node("UnsavedSessionDialog") and scene.get_node("UnsavedSessionDialog").visible,"Continuation respects existing unsaved guard")
	check(scene.destinations.is_empty(),"Dirty candidate never leaves before a Save or explicit Discard")
	scene.get_node("UnsavedSessionDialog").canceled.emit(); scene.get_node("UnsavedSessionDialog").hide()
	check(scene.destinations.is_empty() and scene.session_dirty,"Cancel preserves current workbench")
	scene.request_service(); scene.get_node("UnsavedSessionDialog").custom_action.emit(&"discard")
	check(scene.destinations == ["res://experiments/service_plan/lab.tscn"],"Explicit discard uses the service destination")
	check(scene.support_plans == supports,"Navigation never converts or alters protected representation plans")
	scene.session_dirty = false; scene.request_hub(); scene.request_quit()
	check(scene.destinations[-2] == "res://src/ui/prototype_hub.tscn" and scene.destinations[-1].is_empty(),"Home and Quit replace the earlier pending destination")
	scene.candidate_journey = false; scene.request_service()
	check(scene.destinations.size() == 3,"Ordinary experiment does not opt into a cross-domain journey")
	scene.persistent_session = false; scene.queue_free(); await process_frame
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var hub = load("res://src/ui/prototype_hub.tscn").instantiate(); hub.candidate_journey = true; root.add_child(hub); await process_frame
		check(hub.find_child("SavedSecondActReview",true,false) != null,"Saved combined review available at candidate hub")
		check(hub.candidate_review_paths().is_empty(),"Unbound QA/campaign directory cannot resolve candidate save authority")
		hub.show_candidate_review(); await process_frame
		check(hub.get_node("SavedJourneyReview").visible,"Unbound review gives a visible explanation")
		check(hub.find_child("SavedJourneyReviewContent",true,false).text.contains("未绑定") if locale == "zh_CN" else hub.find_child("SavedJourneyReviewContent",true,false).text.contains("not bound"),"No confirmed profile is not displayed as empty achievement")
		hub.queue_free(); await process_frame
	var core_after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); core_after.erase("saved_at_utc")
	check(core_after == core_before,"Candidate continuation and read-only review preserve core40 authority")
	print("PASS: test_second_act_navigation " if failures == 0 else "FAIL: test_second_act_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
