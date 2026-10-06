extends SceneTree
## Rendered QA only: known-answer model receipts, never human-play or core progress evidence.
const Review = preload("res://experiments/candidate_session/journey_review.gd")
const Presentation = preload("res://experiments/candidate_session/completion_presentation.gd")
const Service = preload("res://experiments/service_plan/model.gd")
var output: String
func _init() -> void: call_deferred("run")
func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []; var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":ends[i],"codec":codecs[i]}); start = ends[i]
	return result
func receipt() -> Dictionary:
	var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	var rep: Array = []
	for i: int in plans.size(): rep.append({"task":i,"plan":plans[i]})
	var grouped: Dictionary = Service.initial_plan(); grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	var prompt: Dictionary = Service.initial_plan(); prompt.slots = 4
	var final: Dictionary = prompt.duplicate(true); final.representations = ["rle64","rle64","raw64","raw64"]
	return Review.evaluate({"ok":true,"runs":[],"supports":rep},{"ok":true,"runs":[],"supports":[{"task":0,"plan":grouped},{"task":1,"plan":prompt},{"task":2,"plan":final}]})
func capture(name: String) -> void:
	root.mode = Window.MODE_WINDOWED
	await create_timer(1.0).timeout
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	await create_timer(0.4).timeout
	for i: int in 8: await process_frame
	RenderingServer.force_draw(false)
	var image: Image = root.get_texture().get_image()
	if image.get_size() != Vector2i(1280,720):
		push_error("Unexpected capture size: "+str(image.get_size())); quit(1); return
	var error: Error = image.save_png(output.path_join(name+".png"))
	if error != OK: push_error("Capture failed: "+name); quit(1)
func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Use an imported isolated QA copy/profile"); quit(1); return
	output = ProjectSettings.globalize_path("res://.godot/completion-captures")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var review: Dictionary = receipt()
	if not review.complete: push_error("Known-answer receipt did not qualify"); quit(1); return
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var hub = load("res://src/ui/prototype_hub.tscn").instantiate(); hub.candidate_journey = true; root.add_child(hub)
		await capture(locale+"-hub")
		hub._show_completion_bridge(); await capture(locale+"-bridge"); hub.get_node("CompletionBridge").hide()
		hub.show_completion_story(); await capture(locale+"-fresh-story")
		# Inject a detached, actually evaluated QA receipt into presentation only.
		# No saved-file claim: this capture is explicitly a model-backed presentation fixture.
		hub.completion_story_pages = Presentation.pages(review,locale == "en")
		hub.completion_story_page = 1; hub._refresh_completion_story(); await capture(locale+"-earned-representation-fixture")
		hub.completion_story_page = 3; hub._refresh_completion_story(); await capture(locale+"-earned-ending-fixture")
		hub.queue_free(); await process_frame
		var lab = load("res://experiments/service_plan/lab.gd").new(); lab.english = locale == "en"; root.add_child(lab)
		lab.run_current(); await capture(locale+"-service-baseline")
		lab.show_specification(); await capture(locale+"-service-specification"); lab.get_node("ServiceSpecificationReview").hide()
		lab.show_measured_bill(); await capture(locale+"-service-bill"); lab.get_node("MeasuredBillReview").hide()
		lab.queue_free(); await process_frame
	print("PASS: bilingual1280x720 rendered completion views; known-answer fixture only; no native/novice claim. "+output)
	quit(0)
