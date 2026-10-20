extends Control
const Canvas = preload("res://src/campaign/task_tree_canvas.gd")
const ObservatoryType = preload("res://src/ui/journey_observatory.gd")
const JournalType = preload("res://src/ui/journey_journal.gd")
const Naming = preload("res://src/campaign/journey_naming.gd")
var journey_observatory: Control
var journey_journal: Control
var canvas: Control
var details: Label
var enter_button: Button
var search: LineEdit
var rows: Array[Dictionary] = []
var selected: Dictionary = {}
var detail_title: Label
var detail_kind: Label
var detail_status: Label
var detail_scroll: ScrollContainer
var detail_panel: PanelContainer
var detail_view: VBoxContainer
var list_view: VBoxContainer
var list_rows: VBoxContainer
var list_title: Label
var list_summary: Label
var list_count: Label
var list_empty: Label
var list_scroll: ScrollContainer
var list_button: Button
var detail_button: Button
var region_choice: OptionButton
var prerequisite_rows: VBoxContainer
var prerequisite_heading: Label
var eligibility_heading: Label
var eligibility_note: Label
var eligibility_rows: VBoxContainer
var recommendation_rows: VBoxContainer
var recommendation_heading: Label
var current_region: int = -1
var creation_route: HBoxContainer
var journey_scope: Label

func _ready() -> void:
	var skin := Theme.new()
	skin.default_font_size = 20
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	theme = skin
	var background := preload("res://src/ui/technical_backdrop.gd").new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var home := _button(header,"tree.home",func() -> void:
		TaskNavigation.from_tree = false
		get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	home.text = "← 实验室" if Localization.current_locale() != "en" else "← Laboratory"
	var title := Label.new()
	title.text = "旅程地图" if Localization.current_locale() != "en" else "Journey map"
	preload("res://src/ui/workbench_chrome.gd").title(title)
	header.add_child(title)
	header.add_child(PlaytestMoments.make_button())
	header.add_child(WindowMode.settings_button())
	search = LineEdit.new()
	search.placeholder_text = _t("search")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(search)
	_button(header,"tree.locate",func() -> void: canvas.locate(TaskNavigation.selected))
	_button(header,"tree.overview",func() -> void: canvas.overview())
	var navigation := HFlowContainer.new(); navigation.name = "JourneyRegionNavigation"
	navigation.add_theme_constant_override("h_separation",12); navigation.add_theme_constant_override("v_separation",6); column.add_child(navigation)
	var section_label := Label.new(); section_label.text = "章节" if Localization.current_locale() != "en" else "Chapter"
	section_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER; navigation.add_child(section_label)
	region_choice = OptionButton.new(); region_choice.name = "JourneyRegionChoice"
	region_choice.custom_minimum_size = Vector2(300,42); navigation.add_child(region_choice)
	var legend := Label.new(); legend.name = "JourneyConnectionLegend"
	legend.text = "实线：前置  ·  虚线：推荐，无新增门槛" if Localization.current_locale() != "en" else "Solid: prerequisite · Dashed: recommendation, no new gate"
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.size_flags_vertical = Control.SIZE_SHRINK_CENTER; legend.add_theme_font_size_override("font_size",14); navigation.add_child(legend)
	var observatory := Button.new(); observatory.name = "OpenJourneyObservatory"
	observatory.text = "观察站" if Localization.current_locale() != "en" else "Observatory"
	observatory.custom_minimum_size.y = 42; navigation.add_child(observatory)
	# The laboratory now carries the journey board; the read-only 3D prototype stays reachable from code only.
	if preload("res://src/lab/lab_features.gd").lab_home(): observatory.hide()
	observatory.pressed.connect(_open_observatory)
	var journal := Button.new(); journal.name = "OpenJourneyJournal"
	journal.text = "成长档案" if Localization.current_locale() != "en" else "Journal"
	journal.custom_minimum_size.y = 42; navigation.add_child(journal)
	journal.pressed.connect(_open_journey_journal)
	creation_route = HBoxContainer.new(); creation_route.name = "CreationRouteShortcuts"
	creation_route.add_theme_constant_override("separation",6); column.add_child(creation_route)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	canvas = Canvas.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(canvas)
	detail_panel=PanelContainer.new(); detail_panel.name="TaskDetailsPanel"
	detail_panel.custom_minimum_size.x=350
	body.add_child(detail_panel)
	var side := VBoxContainer.new(); side.add_theme_constant_override("separation",14)
	detail_panel.add_child(side)
	var view_buttons := HBoxContainer.new(); view_buttons.add_theme_constant_override("separation",8); side.add_child(view_buttons)
	list_button=Button.new(); list_button.name="JourneyTaskListButton"; list_button.text="章节任务" if Localization.current_locale() != "en" else "Chapter tasks"
	list_button.custom_minimum_size.y=42; list_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; list_button.toggle_mode=true
	list_button.pressed.connect(_show_list); view_buttons.add_child(list_button)
	detail_button=Button.new(); detail_button.name="JourneyTaskDetailButton"; detail_button.text="任务详情" if Localization.current_locale() != "en" else "Task details"
	detail_button.custom_minimum_size.y=42; detail_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; detail_button.toggle_mode=true
	detail_button.pressed.connect(_show_detail); view_buttons.add_child(detail_button)
	list_view=VBoxContainer.new(); list_view.name="JourneyTaskList"; list_view.add_theme_constant_override("separation",8)
	list_view.size_flags_vertical=Control.SIZE_EXPAND_FILL; side.add_child(list_view)
	list_title=Label.new(); list_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	list_title.add_theme_font_size_override("font_size",23); list_view.add_child(list_title)
	list_count=Label.new(); list_count.add_theme_font_size_override("font_size",16); list_view.add_child(list_count)
	list_summary=Label.new(); list_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	list_summary.add_theme_font_size_override("font_size",16); list_view.add_child(list_summary)
	list_scroll=ScrollContainer.new(); list_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; list_scroll.follow_focus=true; list_view.add_child(list_scroll)
	list_rows=VBoxContainer.new(); list_rows.name="JourneyTaskRows"; list_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list_rows.add_theme_constant_override("separation",6); list_scroll.add_child(list_rows)
	list_empty=Label.new(); list_empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; list_view.add_child(list_empty)
	detail_view=VBoxContainer.new(); detail_view.name="JourneyTaskDetail"; detail_view.add_theme_constant_override("separation",12)
	detail_view.size_flags_vertical=Control.SIZE_EXPAND_FILL; side.add_child(detail_view)
	detail_kind=Label.new(); detail_kind.add_theme_font_size_override("font_size",18); detail_view.add_child(detail_kind)
	detail_title=Label.new(); detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_title.add_theme_font_size_override("font_size",28); detail_view.add_child(detail_title)
	detail_status=Label.new(); detail_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_view.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	detail_scroll=scroll; scroll.follow_focus=true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_view.add_child(scroll)
	var detail_sections := VBoxContainer.new(); detail_sections.add_theme_constant_override("separation",10)
	detail_sections.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(detail_sections)
	var goal_heading := Label.new(); goal_heading.text="目标" if Localization.current_locale() != "en" else "Goal"
	goal_heading.add_theme_font_size_override("font_size",18); detail_sections.add_child(goal_heading)
	details = Label.new()
	details.custom_minimum_size.x = 300
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_sections.add_child(details)
	prerequisite_heading=Label.new(); prerequisite_heading.text="前置任务" if Localization.current_locale() != "en" else "Prerequisites"
	prerequisite_heading.add_theme_font_size_override("font_size",18); detail_sections.add_child(prerequisite_heading)
	prerequisite_rows=VBoxContainer.new(); prerequisite_rows.add_theme_constant_override("separation",5); detail_sections.add_child(prerequisite_rows)
	eligibility_heading=Label.new(); eligibility_heading.text="进入资格" if Localization.current_locale() != "en" else "Access condition"
	eligibility_heading.add_theme_font_size_override("font_size",18); detail_sections.add_child(eligibility_heading)
	eligibility_note=Label.new(); eligibility_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; detail_sections.add_child(eligibility_note)
	eligibility_rows=VBoxContainer.new(); detail_sections.add_child(eligibility_rows)
	recommendation_heading=Label.new(); recommendation_heading.text="推荐联系 · 不作为前置" if Localization.current_locale() != "en" else "Recommended connections · not prerequisites"
	recommendation_heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	recommendation_heading.add_theme_font_size_override("font_size",18); detail_sections.add_child(recommendation_heading)
	recommendation_rows=VBoxContainer.new(); recommendation_rows.add_theme_constant_override("separation",5); detail_sections.add_child(recommendation_rows)
	detail_view.add_child(detail_status)
	enter_button = _button(detail_view,"tree.enter",func() -> void:
		if not selected.is_empty(): TaskNavigation.enter(selected.key))
	var timing_done: bool = OverlapChapter.completed().has("synthesis")
	var placement_done: bool = LayoutChapter.completed().has("mixed")
	if timing_done or placement_done:
		var review := Button.new()
		review.name = "TaskTreeCoreReview"
		var english: bool = Localization.current_locale() == "en"
		review.text = ("回看核心收束" if not english else "Review the core ending") if timing_done and placement_done else ("回看路径成果与下一路" if not english else "Review this path and what comes next")
		review.custom_minimum_size.y = 42
		review.pressed.connect(_open_core_review)
		detail_view.add_child(review)
	var records := Button.new(); records.text="核心任务记录" if Localization.current_locale() != "en" else "Core task records"
	records.custom_minimum_size.y=42; detail_view.add_child(records)
	records.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/playtest/personal_records_view.tscn"))
	var opinion := Button.new(); opinion.text="评价所选任务" if TranslationServer.get_locale().begins_with("zh") else "Feedback on selected task"
	opinion.custom_minimum_size.y=42; detail_view.add_child(opinion)
	opinion.pressed.connect(func() -> void:
		if not selected.is_empty(): PlaytestMoments.open_for_task(selected.key.get_slice("/",0),selected.id))
	var help := Label.new()
	journey_scope = help; help.name = "JourneyScope"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size",14)
	help.text = _t("controls")
	help.add_theme_color_override("font_color",Color("8fa3ad"))
	column.add_child(help)
	rows = TaskNavigation.journey_tasks()
	_apply_naming()
	_build_route_shortcuts()
	PlaytestData.record_map_action(&"map_open","")
	for task: Dictionary in rows:
		if task.unlocked: PlaytestData.record_map_action(&"eligible",task.key)
	canvas.configure(rows)
	region_choice.add_item("整个旅程" if Localization.current_locale() != "en" else "Whole journey")
	region_choice.set_item_metadata(0,-1)
	var seen_regions: Array[int] = []
	for task: Dictionary in rows:
		if int(task.region) in seen_regions: continue
		seen_regions.append(int(task.region))
		region_choice.add_item(_region_title(int(task.region)))
		region_choice.set_item_metadata(region_choice.item_count-1,int(task.region))
	region_choice.item_selected.connect(func(index: int) -> void:
		_choose_region(int(region_choice.get_item_metadata(index))))
	canvas.task_selected.connect(func(key: String) -> void:
		PlaytestData.record_map_action(&"detail_view",key)
		_select(key))
	search.text_changed.connect(_on_search_changed)
	search.text_submitted.connect(func(_value: String) -> void:
		var matches: Array[String] = canvas.matching_keys()
		if not matches.is_empty(): _select_and_locate(matches[0]))
	_select(TaskNavigation.selected)
	_show_list()

# Map, list and headings share one scheme: chapters 序章 → 第一章 …, tasks
# 序章·名称 / 1-1 名称 / 1-4-1 名称. Keys and progress are unchanged.
func _apply_naming() -> void:
	var numbering: Dictionary = Naming.numbers(rows)
	for task: Dictionary in rows:
		task["raw_title"] = str(task.title)
		task["number"] = str(numbering.get(str(task.key), ""))
		task["title"] = Naming.task_label(task, numbering)
		task["region_title"] = Naming.chapter_title(int(task.region), str(task.get("region_title", Localization.text(StringName("tree.region." + str(task.region))))))

func _open_observatory() -> void:
	if not is_instance_valid(journey_observatory):
		journey_observatory = ObservatoryType.new(); add_child(journey_observatory)
		journey_observatory.tree_requested.connect(func(key: String) -> void: _select_and_locate(key))
	journey_observatory.open()

func _open_journey_journal() -> void:
	if not is_instance_valid(journey_journal):
		journey_journal = JournalType.new(); add_child(journey_journal)
	journey_journal.open()

# One chip per region, left to right in journey order, with real progress.
# Later chapters (compression, prediction, creation) are visible from the start.
func _build_route_shortcuts() -> void:
	_clear_rows(creation_route)
	var english: bool = Localization.current_locale() == "en"
	var regions: Array[int] = []
	for task: Dictionary in rows:
		if int(task.region) in regions: continue
		var region: int = int(task.region)
		regions.append(region)
		var done: int = 0; var total: int = 0
		for other: Dictionary in rows:
			if int(other.region) != region: continue
			total += 1
			if other.completed: done += 1
		var button := Button.new()
		button.name = ("CreationRegion" if task.domain == "creation" else "JourneyRegion")+str(region)
		button.text = Naming.chapter_ordinal(region) + "\n" + _short_region(region) + "  " + str(done) + "/" + str(total)
		button.custom_minimum_size = Vector2(0, 40)
		button.add_theme_constant_override("line_spacing", -2)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override("font_size",13 if not english else 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("region",region)
		button.tooltip_text = _region_title(region) + "\n" + _region_summary(region)
		if done > 0:
			button.add_theme_color_override("font_color",Color("ffd27a") if done == total else Color("8fd3dc"))
		button.pressed.connect(func() -> void:
			_choose_region(region)
			for index: int in region_choice.item_count:
				if int(region_choice.get_item_metadata(index)) == region: region_choice.select(index)
			list_button.grab_focus())
		creation_route.add_child(button)
	creation_route.visible = not regions.is_empty()
	var available: int = 0
	for task: Dictionary in rows:
		if task.unlocked: available += 1
	var finished: int = 0
	for task: Dictionary in rows:
		if task.completed: finished += 1
	journey_scope.text = ("已完成 %d / %d · 可进入 %d" if not english else "Completed %d / %d · open %d") % [finished,rows.size(),available]
	journey_scope.text += "  ·  "+_t("controls")

func _open_core_review() -> void:
	if not OverlapChapter.completed().has("synthesis") and not LayoutChapter.completed().has("mixed"): return
	TaskNavigation.from_tree = false
	preload("res://experiments/candidate_session/navigation_intent.gd").pending_review = "core"
	get_tree().call_deferred("change_scene_to_file","res://src/ui/prototype_hub.tscn")

func _select(key: String) -> void:
	for task: Dictionary in rows:
		if task.key != key: continue
		selected = task
		TaskNavigation.selected = key
		current_region=int(task.region)
		for index: int in region_choice.item_count:
			if int(region_choice.get_item_metadata(index)) == current_region:
				region_choice.select(index)
				break
		var accent: Color = canvas._color(task.region)
		var frame: StyleBoxFlat = InstrumentTheme.surface(Color("132330"),Color(accent,0.4),8)
		frame.content_margin_left=18; frame.content_margin_right=18
		frame.content_margin_top=18; frame.content_margin_bottom=18
		detail_panel.add_theme_stylebox_override("panel",frame)
		detail_title.text=task.title
		detail_kind.text=_task_kind(task)
		detail_kind.add_theme_color_override("font_color",accent)
		detail_status.text=("✓ " if task.completed else "● " if task.unlocked else "○ ")+_t("completed" if task.completed else "available" if task.unlocked else "locked")
		if str(task.get("evidence_status","")) == "unavailable":
			detail_status.text += (" · 成果待确认；进入可用工作台检查存档提示。" if Localization.current_locale() != "en" else " · Saved work unconfirmed; inspect the available workbench's save notice.")
		elif str(task.get("progress_source","")) == "session": detail_status.text = "可选临时探索；离开后不保留。" if Localization.current_locale() != "en" else "Optional temporary exploration; not retained after leaving."
		elif task.has("progress_source") and task.completed: detail_status.text += " · "+("已保存方案重新验收" if Localization.current_locale() != "en" else "saved plan revalidated")
		detail_status.add_theme_color_override("font_color",accent if task.unlocked else Color("acb9cb"))
		var text: String = task.body
		if task.key == "chapter_2/capstone":
			text += "\n\n"+("✓ " if not LocalityChapter.economical_design.is_empty() else "◇ ")+Localization.text(&"bonus.economical")
		elif task.key in ["chapter_3/distance","chapter_3/synthesis"]:
			text += "\n\n"+("✓ " if OverlapChapter.bonus_status(task.id).complete else "◇ ")+Localization.text(StringName("overlap.bonus."+task.id))
		details.text = text
		_clear_rows(prerequisite_rows)
		prerequisite_heading.visible = not task.dependencies.is_empty()
		prerequisite_rows.visible = not task.dependencies.is_empty()
		for dependency: String in task.dependencies:
			var prerequisite: Dictionary = _find_task(dependency)
			if not prerequisite.is_empty(): _task_link(prerequisite_rows,prerequisite)
		var note: String = str(task.get("eligibility_note",""))
		eligibility_heading.visible = not note.is_empty()
		eligibility_note.visible = not note.is_empty()
		eligibility_note.text = note
		_clear_rows(eligibility_rows)
		if task.domain == "service" and not task.unlocked and int(task.get("task_index",0)) > 0:
			var previous: Array = task.get("recommended_from",[])
			if not previous.is_empty():
				var prior_contract: Dictionary = _find_task(str(previous[0]))
				if not prior_contract.is_empty(): _task_link(eligibility_rows,prior_contract,"查看前一份合同：" if Localization.current_locale() != "en" else "View earlier contract: ")
		eligibility_rows.visible = eligibility_rows.get_child_count() > 0
		_clear_rows(recommendation_rows)
		var recommended: Array = task.get("recommended_from",[])
		recommendation_heading.visible = not recommended.is_empty()
		recommendation_rows.visible = not recommended.is_empty()
		for key_from: String in recommended:
			var related: Dictionary = _find_task(key_from)
			if not related.is_empty(): _task_link(recommendation_rows,related)
		detail_scroll.scroll_vertical=0
		InstrumentTheme.primary(enter_button,accent)
		enter_button.disabled = not task.unlocked
		_show_detail()
		canvas.queue_redraw()
		return

func _task_kind(task: Dictionary) -> String:
	if task.domain == "creation": return "创作路线" if Localization.current_locale() != "en" else "Creation route"
	if task.domain == "prediction": return "可选地址预测 · 不阻挡主线" if Localization.current_locale() != "en" else "Optional address prediction · no main-route gate"
	if task.domain in ["representation","service"]: return "第二幕任务" if Localization.current_locale() != "en" else "Second-act task"
	return _t("optional" if task.optional else "main")

func _find_task(key: String) -> Dictionary:
	for task: Dictionary in rows:
		if task.key == key: return task
	return {}

func _clear_rows(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _task_link(container: Node,task: Dictionary,prefix: String = "") -> void:
	var button := Button.new()
	button.text = prefix+("✓ " if task.completed else "○ ")+str(task.title)
	button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y=42
	button.set_meta("task_key",task.key)
	var key: String=task.key
	button.pressed.connect(func() -> void: _select_and_locate(key))
	container.add_child(button)

func _show_list() -> void:
	_refresh_task_list()
	list_view.show()
	detail_view.hide()
	list_button.button_pressed=true
	detail_button.button_pressed=false

func _show_detail() -> void:
	list_view.hide()
	detail_view.show()
	list_button.button_pressed=false
	detail_button.button_pressed=true

func _choose_region(region: int) -> void:
	current_region=region
	search.clear()
	canvas.set_search("")
	if region < 0: canvas.overview()
	else: canvas.focus_region(region)
	_show_list()

func _on_search_changed(value: String) -> void:
	canvas.set_search(value)
	if not value.strip_edges().is_empty(): _show_list()
	elif list_view.visible: _refresh_task_list()

func _region_title(region: int) -> String:
	if region < 0: return "整个旅程" if Localization.current_locale() != "en" else "Whole journey"
	for task: Dictionary in rows:
		if int(task.region) == region: return str(task.get("region_title",Localization.text(StringName("tree.region."+str(region)))))
	return "Chapter "+str(region)

func _region_summary(region: int) -> String:
	var english: bool = Localization.current_locale() == "en"
	match region:
		-1: return "选择章节查看完整任务；实线是前置，虚线只是推荐。" if not english else "Choose a chapter to read its tasks. Solid lines gate access; dashed lines only suggest a route."
		0: return "核心旅程 · 从接线开始，亲手造出可复用的机器部件。" if not english else "Core journey · Build reusable machine parts, starting with wiring."
		1: return "核心旅程 · 用自己的机器发现等待与搬运。" if not english else "Core journey · Use your machine to discover waiting and transfer."
		2: return "核心旅程 · 调整数据的远近与复用方式。" if not english else "Core journey · Arrange data proximity and reuse."
		3,4: return "核心旅程 · 时序与布局是两条并行的路，都走完后在收束处一起回看。" if not english else "Core journey · Timing and placement are parallel paths; review both at the ending."
		5: return "第二幕 · 换一种方式写下信息，让同样的内容占得更少、取得更快。" if not english else "Second act · Write information differently so the same content takes less space and less time."
		6: return "第二幕 · 让保存下来的方案，去服务后来的请求。" if not english else "Second act · Let your saved plans serve the requests that come later."
		7: return "地址预测 · 根据有限的历史猜下一次要去哪里，并承担猜错的代价。" if not english else "Address prediction · Guess where the next access goes from limited history, and pay for wrong guesses."
		8: return "压缩 · 找到规律，让长记录变短，还能原样复原。" if not english else "Compression · Find the pattern so a long record becomes short and still restores exactly."
		9: return "内容预测 · 用学到的规律，预测下一格还没到达的内容。" if not english else "Content prediction · Use the learned pattern to predict the cell that has not arrived yet."
		10: return "创造 · 把输出接回输入，按自己的意图留下一段作品。" if not english else "Creation · Feed the output back in and leave a piece shaped by your own intent."
	return ""

func _refresh_task_list() -> void:
	if list_rows == null: return
	_clear_rows(list_rows)
	var query: String = search.text.strip_edges()
	var matched: Array[String] = []
	if not query.is_empty(): matched=canvas.matching_keys()
	var shown: Array[Dictionary] = []
	for task: Dictionary in rows:
		if not query.is_empty():
			if task.key in matched: shown.append(task)
		elif current_region < 0 or int(task.region) == current_region: shown.append(task)
	var completed: int = 0
	for task: Dictionary in shown:
		if task.completed: completed += 1
	list_title.text = (("搜索结果" if Localization.current_locale() != "en" else "Search results") if not query.is_empty() else _region_title(current_region))
	list_count.text = ("%d 项匹配" % shown.size() if not query.is_empty() else "%d/%d 已完成" % [completed,shown.size()]) if Localization.current_locale() != "en" else ("%d matches" % shown.size() if not query.is_empty() else "%d/%d completed" % [completed,shown.size()])
	list_summary.text = ("点选结果查看任务并定位地图。" if Localization.current_locale() != "en" else "Select a result to inspect and locate it on the map.") if not query.is_empty() else _region_summary(current_region)
	list_empty.text = "没有匹配任务。" if Localization.current_locale() != "en" else "No matching tasks."
	list_empty.visible = shown.is_empty()
	for task: Dictionary in shown:
		var button := Button.new()
		button.text = ("✓ " if task.completed else "● " if task.unlocked else "○ ")+str(task.title)+"\n"+_task_status(task)
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y=72
		button.set_meta("task_key",task.key)
		var key: String=task.key
		button.pressed.connect(func() -> void: _select_and_locate(key))
		list_rows.add_child(button)
	list_scroll.scroll_vertical=0

func _task_status(task: Dictionary) -> String:
	var state: String = _t("completed" if task.completed else "available" if task.unlocked else "locked")
	if str(task.get("evidence_status","")) == "unavailable": state += " · 成果待确认" if Localization.current_locale() != "en" else " · work unconfirmed"
	if str(task.get("progress_source","")) == "session": state += " · 仅本次会话" if Localization.current_locale() != "en" else " · session only"
	return state

func _select_and_locate(key: String) -> void:
	_select(key)
	if selected.is_empty() or selected.key != key: return
	canvas.locate(key)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		TaskNavigation.from_tree = false
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")

func _button(parent: Node,key: String,action: Callable) -> Button:
	var button := Button.new()
	button.text = Localization.text(StringName(key))
	button.custom_minimum_size.y = 46
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _t(key: String) -> String: return Localization.text(StringName("tree."+key))


func _short_region(region: int) -> String:
	var english: bool = Localization.current_locale() == "en"
	var zh: Array[String] = ["构造", "等待", "就近", "在途", "布局", "表示", "服务", "地址预测", "压缩", "内容预测", "创造"]
	var en: Array[String] = ["Build", "Waiting", "Nearby", "In flight", "Layout", "Representation", "Service", "Address", "Compression", "Content", "Creation"]
	if region < 0 or region >= zh.size(): return _region_title(region)
	return en[region] if english else zh[region]

