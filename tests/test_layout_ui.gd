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
		check(host.panels.memory.visible and not host.panels.mission.visible,"entry exposes the address stage "+id)
		check(not host.panels.tools.get_rect().intersects(host.panels.memory.get_rect()),"tools leave address stage unobscured "+id)
		if id == "fields":
			var previous: Dictionary = {"target_met":true,"total_cycles":100,"peak_extra_bytes":8,"ram_read_bytes":64,"ram_write_bytes":16}
			var changed: Dictionary = previous.duplicate()
			changed.total_cycles = 90
			check(host._comparison_not_worse(previous,changed),"strict gain with no regression permits improvement")
			changed.peak_extra_bytes = 9
			check(not host._comparison_not_worse(previous,changed),"faster with higher scratch is neutral")
			changed = previous.duplicate(); changed.target_met = false
			check(not host._comparison_not_worse(previous,changed),"formal regression prevents improvement")
			changed = previous.duplicate(); changed.ram_write_bytes = 17
			check(not host._comparison_not_worse(previous,changed),"RAM regression prevents improvement")
			check(not host.panels.tools.has_node("WindowHeader"),"docked tool surface exposes no false window controls")
			host._toggle("tools")
			check(host.panels.tools.visible,"active side tab stays selected on repeated activation")
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
			host._run_all()
			var first_metrics: Label = host.results.get_node("LayoutCaseHeadline0")
			check(not first_metrics.text.contains("RAM") and not first_metrics.text.contains("比上次") and not first_metrics.text.contains("Since last"),"case headline keeps order and status without repeating traffic")
		host.design = C.reference_solution(id)
		host._changed()
		await process_frame
		host._run_all()
		check(host.runs.size() == 2,"both public orders "+id)
		check(root.get_node("LayoutChapter").completed().has(id),"reference passes current targets "+id)
		if id == "fields":
			var compared: Label = host.results.get_node("LayoutCaseMetrics0")
			check(compared.text.contains("比上次完整运行") or compared.text.contains("Since last complete run"),"single layout change compares complete measurements under the same case")
		var before: String = JSON.stringify(host.design)
		host._hint_advance(); host._hint_advance(); host._hint_advance()
		check(JSON.stringify(host.design) == before,"read-only Hint cannot change draft "+id)
		host.hint_layer.hide()
		host._move_group(0,host._current().recipe.groups.size())
		host._undo(false)
		check(JSON.stringify(host.design) == before,"group edit undo restores exact design "+id)
		if id == "mixed":
			var summary: Label = host.results.get_node("LayoutOptionalGoals")
			check(summary.text.contains("1300") and summary.text.contains("16"),"mixed result exposes both optional measured budgets")
			var prior: Dictionary = host.comparable_runs.duplicate()
			var bonuses: Dictionary = root.get_node("LayoutChapter").test_bonuses.duplicate(true)
			host.design.strategy = "batch"; host.design.batch = 64; host.design.copy_fields = [0,1,2,3]
			host._changed(); host._run_all()
			summary = host.results.get_node("LayoutOptionalGoals")
			check(not host.runs[0].passed and host.comparable_runs == prior,"incomplete space-limited attempts retain the last complete comparison")
			check(summary.text.contains("未完成") or summary.text.contains("must finish"),"incomplete totals cannot count as optional improvements")
			check(root.get_node("LayoutChapter").test_bonuses == bonuses,"a failed experiment preserves already earned optional goals")
			if not bonuses.is_empty(): check(summary.text.contains("已获得") or summary.text.contains("Earned"),"historical optional achievements remain visibly earned after failure")
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
