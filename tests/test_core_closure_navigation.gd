extends SceneTree
## Synthetic prerequisite recipes isolate real terminal Run→review navigation.
## This is controller evidence, not a complete campaign or native playthrough.
const OverlapCatalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
const LayoutCatalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Reflection = preload("res://src/ui/theme_reflection.gd")
const Intent = preload("res://experiments/candidate_session/navigation_intent.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func progress() -> Dictionary:
	var value: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	value.erase("saved_at_utc")
	return value
func prepare() -> void:
	var overlap: Node = root.get_node("OverlapChapter")
	var layout: Node = root.get_node("LayoutChapter")
	root.get_node("LocalityChapter").game_completed[&"capstone"] = true
	overlap.game_solutions.clear(); overlap.game_drafts.clear(); overlap.game_routes.clear(); overlap.game_distance_bonus.clear()
	layout.game_solutions.clear(); layout.game_drafts.clear(); layout.game_named.clear(); layout.game_bonuses.clear()
	for id: String in OverlapCatalog.IDS:
		if id != "synthesis": overlap.game_solutions[id] = OverlapCatalog.reference_solution(id)
	for id: String in LayoutCatalog.IDS:
		if id != "mixed": layout.game_solutions[id] = LayoutCatalog.reference_solution(id)
	Intent.pending_review = ""
	root.get_node("TaskNavigation").pending = ""
func reflection_keys() -> Array[StringName]:
	return Reflection.milestones({}, {}, {}, root.get_node("OverlapChapter").completed(), root.get_node("LayoutChapter").completed())

func open_task(key: String) -> Control:
	check(root.get_node("TaskNavigation").enter(key),"Registered terminal entry remains available: "+key)
	await settle()
	return current_scene
func inspect_hub(expected_joint: bool) -> void:
	await settle()
	check(current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn","Earned review action returns through ordinary Hub")
	var reflection: AcceptDialog = current_scene.get_node_or_null("ThemeReflection")
	check(reflection != null and reflection.visible,"Transient intent opens existing reflection without hunting for another button")
	check(Intent.pending_review.is_empty(),"Hub consumes transient review intent")
	check((&"theme.ending" in reflection_keys()) == expected_joint,"Existing joint ending still requires both terminal solutions")
	check((&"theme.other_path" in reflection_keys()) != expected_joint,"Single path keeps the other path open")
	if reflection != null: reflection.hide()

func complete_overlap() -> void:
	var solution: Dictionary = OverlapCatalog.reference_solution("synthesis")
	root.get_node("OverlapChapter").game_drafts.synthesis = solution.duplicate(true)
	var chapter: Control = await open_task("chapter_3/synthesis")
	check(not chapter.core_review_button.visible,"No timing review is offered for an unrun terminal draft")
	chapter._open_core_review()
	check(Intent.pending_review.is_empty(),"Programmatic unearned timing review also refuses intent")
	chapter._run_official()
	check(root.get_node("OverlapChapter").completed().has("synthesis"),"Actual terminal run earns its existing authoritative solution")
	check(chapter.completion.visible and chapter.completion.primary_action_button.visible,"First timing terminal success exposes review in actual success overlay")
	check(chapter.core_review_button.visible,"Timing review also remains in the chapter header")
	check(chapter.core_review_button.get_global_rect().end.x <= 1280 and chapter.core_review_button.get_global_rect().end.y <= 720,"Timing header review fits minimum viewport")
	var before: Dictionary = progress()
	chapter.completion.primary_action_button.pressed.emit()
	await inspect_hub(root.get_node("LayoutChapter").completed().has("mixed"))
	check(progress() == before,"Timing review transition preserves progress and flushed draft")

func complete_layout() -> void:
	root.get_node("LayoutChapter").game_drafts.mixed = LayoutCatalog.reference_solution("mixed")
	var chapter: Control = await open_task("chapter_4/mixed")
	check(not chapter.core_review_button.visible,"No placement review is offered for an unrun terminal draft")
	chapter._open_core_review()
	check(Intent.pending_review.is_empty(),"Programmatic unearned placement review also refuses intent")
	chapter._run_all()
	check(root.get_node("LayoutChapter").completed().has("mixed"),"Actual terminal orders earn their existing authoritative design")
	var result_button: Button = chapter.find_child("LayoutResultCoreReview",true,false)
	check(result_button != null and result_button.visible,"Placement success exposes review beside actual order results")
	check(chapter.core_review_button.visible,"Placement review also remains in the chapter header")
	check(chapter.core_review_button.get_global_rect().end.x <= 1280 and chapter.core_review_button.get_global_rect().end.y <= 720,"Placement header review fits minimum viewport")
	var before: Dictionary = progress()
	if result_button != null: result_button.pressed.emit()
	await inspect_hub(root.get_node("OverlapChapter").completed().has("synthesis"))
	check(progress() == before,"Placement review transition preserves progress and flushed draft")

func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"game")
	root.get_node("GlobalSave").configure_for_test("user://core-closure-save.json","user://core-closure-workbench.json")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for timing_first: bool in [true,false]:
			prepare()
			change_scene_to_file("res://src/campaign/task_tree.tscn"); await settle()
			check(current_scene.find_child("TaskTreeCoreReview",true,false) == null,"Fresh terminal drafts do not advertise earned closure")
			current_scene._open_core_review()
			check(Intent.pending_review.is_empty(),"Unearned tree review refuses intent")
			if timing_first: await complete_overlap()
			else: await complete_layout()
			change_scene_to_file("res://src/campaign/task_tree.tscn"); await settle()
			var tree_review: Button = current_scene.find_child("TaskTreeCoreReview",true,false)
			check(tree_review != null,"One terminal makes earned path review discoverable on return to tree")
			var before: Dictionary = progress()
			if tree_review != null: tree_review.pressed.emit()
			await inspect_hub(false)
			check(progress() == before,"Single-path tree review grants no other terminal")
			if timing_first: await complete_layout()
			else: await complete_overlap()
			change_scene_to_file("res://src/campaign/task_tree.tscn"); await settle()
			tree_review = current_scene.find_child("TaskTreeCoreReview",true,false)
			check(tree_review != null and tree_review.text == ("Review the core ending" if locale == "en" else "回看核心收束"),"Joint earned tree entry explicitly offers core ending")
			if tree_review != null:
				check(tree_review.get_global_rect().end.x <= 1280 and tree_review.get_global_rect().end.y <= 720,"Earned tree action fits minimum viewport")
				before = progress(); tree_review.pressed.emit(); await inspect_hub(true)
				check(progress() == before,"Joint review adds no save authority")
			# Existing earned solution survives a different, unrun draft on revisit.
			root.get_node("OverlapChapter").game_drafts.synthesis = {"board":OverlapCatalog.seed("synthesis"),"program":OverlapCatalog.starter("synthesis")}
			var timing: Control = await open_task("chapter_3/synthesis")
			check(timing.core_review_button.visible,"Dirty timing revisit retains earned review")
			timing._run_official()
			check(timing.core_review_button.visible,"Failed later timing run cannot hide stored achievement")
			before = progress(); timing.core_review_button.pressed.emit(); await inspect_hub(true)
			check(progress() == before,"Revisit review preserves edited timing draft")
			root.get_node("LayoutChapter").game_drafts.mixed = LayoutCatalog.starter_design()
			var placement: Control = await open_task("chapter_4/mixed")
			check(placement.core_review_button.visible,"Dirty placement revisit retains earned review")
			placement._run_all()
			check(placement.find_child("LayoutResultCoreReview",true,false) != null,"Failed later placement run retains review of stored achievement")
			before = progress(); placement.core_review_button.pressed.emit(); await inspect_hub(true)
			check(progress() == before,"Revisit review preserves edited placement draft")
	print("PASS: test_core_closure_navigation " if failures == 0 else "FAIL: test_core_closure_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
