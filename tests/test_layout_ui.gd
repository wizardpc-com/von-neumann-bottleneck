extends SceneTree
var failures: Array[String] = []
const C = preload("res://src/layout_chapter/layout_catalog.gd")
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var mode: Node = root.get_node("GameMode")
	mode.set_mode(&"test")
	var nav: Node = root.get_node("TaskNavigation")
	for id: String in C.IDS:
		nav.pending = "chapter_4/"+id
		var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
		root.add_child(host)
		for frame: int in range(5): await process_frame
		check(host.level == id and host.panels.tools.visible,"ordinary host route and visible tools "+id)
		if id == "fields":
			var localization: Node = root.get_node("Localization")
			var original_locale: String = localization.current_locale()
			for locale: String in ["zh_CN", "en"]:
				localization.set_locale(locale)
				var sum_text: String = host._query_summary({"kind":"sum", "fields":[0,3], "repeat":8})
				var list_text: String = host._query_summary({"kind":"records", "fields":[0,1], "indices":[0,7], "repeat":2})
				var once_text: String = host._query_summary({"kind":"records", "fields":[0], "indices":[1]})
				check(not once_text.contains("重复") and not once_text.contains("repeat"), "one ordinary query does not add a redundant repeat instruction " + locale)
				check(not sum_text.contains("×") and not list_text.contains(" + "), "query repetition is not drawn as multiplication and ordered outputs are not sums " + locale)
				check(sum_text.contains("8") and list_text.contains("#0") and list_text.contains("#7"), "query summary preserves public repetition and record identities " + locale)
				check(sum_text.contains("求和字段" if locale == "zh_CN" else "Fields to sum") and list_text.contains("依次输出字段" if locale == "zh_CN" else "Output fields in order"), "different query actions stay explicit " + locale)
			localization.set_locale(original_locale)
		host.design = C.reference_solution(id)
		host._changed()
		await process_frame
		host._run_all()
		check(host.runs.size() == 2,"both public orders "+id)
		check(root.get_node("LayoutChapter").completed().has(id),"reference passes current targets "+id)
		var before: String = JSON.stringify(host.design)
		host._hint_advance(); host._hint_advance(); host._hint_advance()
		check(JSON.stringify(host.design) == before,"read-only Hint cannot change draft "+id)
		host.hint_layer.hide()
		host._move_group(0,host._current().recipe.groups.size())
		host._undo(false)
		check(JSON.stringify(host.design) == before,"group edit undo restores exact design "+id)
		await process_frame
		host.queue_free()
		for frame: int in range(3): await process_frame
	var state: Node = root.get_node("LayoutChapter")
	check(state.save_named("fields","two words",C.reference_solution("fields")),"named schemes save")
	check(state.named().fields.has("two words"),"named schemes retain title")
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(C.reference_solution("fields")))
	var normalized: Dictionary = state.normalize(serialized)
	check(normalized.recipe.groups[0].fields.has(0),"restored field IDs support integer drag lookup")
	normalized.recipe.groups[0].fields.erase(0)
	check(normalized.recipe.groups[0].fields.size()==3,"restored integer field can actually be removed")
	var snapshot: Dictionary = {"schema_version":1,"drafts":{"fields":serialized},"named":{"fields":{"my layout":serialized}},"solutions":{"fields":serialized}}
	state.restore_game(JSON.parse_string(JSON.stringify(snapshot)),true)
	check(state.game_solutions.has("fields") and state.game_named.fields.has("my layout"),"JSON roundtrip revalidates completion and preserves named drafts")
	for issue: String in failures: push_error(issue)
	print("PASS: layout six hosts, gates, targets, undo and independent hints" if failures.is_empty() else "FAIL: layout UI")
	quit(0 if failures.is_empty() else 1)
