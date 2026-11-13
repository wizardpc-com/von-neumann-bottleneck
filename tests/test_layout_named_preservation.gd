extends SceneTree
const C = preload("res://src/layout_chapter/layout_catalog.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func settle() -> void:
	for frame: int in 5: await process_frame
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(1); return
	root.get_node("GameMode").set_mode(&"test")
	var state: Node = root.get_node("LayoutChapter")
	var original: Dictionary = C.starter_design()
	var different: Dictionary = C.reference_solution("fields")
	check(original != different,"Fixture recipes differ")
	check(state.save_named("fields","State copy",original),"First named copy succeeds")
	check(not state.save_named("fields","State copy",different),"Different recipe cannot replace an existing named copy")
	check(state.named().fields["State copy"] == state.normalize(original),"Rejected overwrite preserves exact original")
	check(state.save_named("fields","State copy",JSON.parse_string(JSON.stringify(original))),"Normalized identical copy can retry")
	root.get_node("GameMode").set_mode(&"game")
	var persistence_requests: Array[int] = [0]
	var observe: Callable = func() -> void: persistence_requests[0] += 1
	state.persistent_state_changed.connect(observe)
	check(state.save_named("fields","Game copy",original),"Game copy requests persistence")
	check(not state.save_named("fields","Game copy",different),"Game copy rejects a different recipe")
	check(state.save_named("fields","Game copy",original),"Game copy permits identical save retry")
	check(persistence_requests[0] == 2,"Only initial save and identical retry request persistence")
	check(state.named().fields["Game copy"] == state.normalize(original),"Game original remains exact")
	state.persistent_state_changed.disconnect(observe)
	root.get_node("GameMode").set_mode(&"test")
	check(not state.named().fields.has("Game copy"),"Game named copy remains separate from Test")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.get_node("TaskNavigation").pending = "chapter_4/fields"
		var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
		root.add_child(host)
		await settle()
		host.design = original.duplicate(true)
		host.scheme_name.text = "UI copy "+locale
		host._save_named()
		await settle()
		host.design = different.duplicate(true)
		host.scheme_name.text = "UI copy "+locale
		host._save_named()
		await settle()
		check(state.named().fields["UI copy "+locale] == state.normalize(original),"Ordinary save preserves named copy "+locale)
		check(host.status.text.contains("新") if locale == "zh_CN" else host.status.text.contains("new"),"Conflict explains choosing a new name "+locale)
		check(host.scheme_name.text == "UI copy "+locale,"Rejected save retains typed name "+locale)
		check(host.design == different,"Rejected save preserves current draft "+locale)
		host.queue_free()
		await settle()
	for issue: String in failures: push_error(issue)
	print("PASS: named layout preservation" if failures.is_empty() else "FAIL: named layout preservation")
	quit(0 if failures.is_empty() else 1)
