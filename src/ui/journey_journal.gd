class_name JourneyJournal
extends Control
## A derived view of existing records; opening it grants nothing and writes nothing.

const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const Handbook = preload("res://src/ui/terminology_handbook.gd")
const Reflection = preload("res://src/ui/theme_reflection.gd")
const CreationSession = preload("res://experiments/creation/session.gd")
const CandidateFiles = preload("res://experiments/candidate_session/files.gd")
const WorkFocus = preload("res://experiments/creation/work_focus.gd")
const LabState = preload("res://src/lab/lab_state.gd")

var rows: Array[Dictionary] = []
var regions: Array[int] = []
var selected_key: String = ""
var previous_focus: Control
var title_label: Label
var overview_label: Label
var scope_label: Label
var record_storage_label: Label
var region_selector: OptionButton
var task_tree: Tree
var detail: RichTextLabel
var enter_button: Button
var help_button: Button
var reflection_button: Button
var close_button: Button
var handbook: Handbook
var reflection_dialog: AcceptDialog
var saved_work_state: Dictionary = {}
var core_records: Dictionary = {}
var work_selector: OptionButton
var work_view_button: Button
var work_note: Label
var work_focus: Window
var work_frames: HBoxContainer


func _ready() -> void:
	name = "JourneyJournal"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1300
	var skin := Theme.new()
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	skin.default_font_size = 16
	theme = skin
	_build()
	Localization.locale_changed.connect(func(_locale: String) -> void:
		if visible: _refresh())
	hide()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color("08111a")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	preload("res://src/lab/lab_terminal_pages.gd").fit_page_margin(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	title_label = _label(header, 28)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button = _button(header, "JournalClose", close)
	preload("res://src/lab/lab_terminal_pages.gd").style_header(header,title_label,close_button)
	overview_label = _label(column, 18)
	scope_label = _label(column, 14)
	record_storage_label = _label(column, 14)
	record_storage_label.name = "JournalRecordStorage"
	record_storage_label.mouse_filter = Control.MOUSE_FILTER_PASS
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	var navigation := VBoxContainer.new()
	navigation.custom_minimum_size.x = 350
	content.add_child(navigation)
	region_selector = OptionButton.new()
	region_selector.name = "JournalRegion"
	region_selector.custom_minimum_size.y = 42
	region_selector.fit_to_longest_item = false
	region_selector.item_selected.connect(func(_index: int) -> void: _refresh_tasks())
	navigation.add_child(region_selector)
	task_tree = Tree.new()
	task_tree.name = "JournalTasks"
	task_tree.hide_root = true
	task_tree.add_theme_constant_override("v_separation", 10)
	for state: String in ["selected", "selected_focus"]:
		var selection := StyleBoxFlat.new(); selection.bg_color = Color("63c8cf", 0.55)
		selection.border_color = Color("63c8cf"); selection.border_width_left = 4
		task_tree.add_theme_stylebox_override(state, selection)
	task_tree.add_theme_color_override("font_selected_color", Color("e2ebef"))
	var tree_space := Control.new(); tree_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navigation.add_child(tree_space)
	tree_space.resized.connect(_fit_task_rows)
	task_tree.theme_changed.connect(func() -> void: _fit_task_rows.call_deferred())
	task_tree.item_selected.connect(func() -> void:
		var item: TreeItem = task_tree.get_selected()
		if item != null: show_task(str(item.get_metadata(0))))
	tree_space.add_child(task_tree)
	var record_frame := PanelContainer.new()
	record_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	record_frame.add_theme_stylebox_override("panel", preload("res://src/ui/instrument_theme.gd").surface(Color("16222b"), Color("33434e"), 4))
	content.add_child(record_frame)
	var scroll := ScrollContainer.new()
	scroll.name = "JournalDetailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	record_frame.add_child(scroll)
	detail = RichTextLabel.new()
	detail.name = "JournalRecord"
	detail.bbcode_enabled = false
	detail.fit_content = true
	detail.scroll_active = false
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("normal_font_size", 16)
	scroll.add_child(detail)
	var work_frame := PanelContainer.new()
	work_frame.add_theme_stylebox_override("panel", preload("res://src/ui/instrument_theme.gd").surface(Color("16222b"), Color("33434e"), 4))
	column.add_child(work_frame)
	var work_row := HBoxContainer.new()
	work_row.add_theme_constant_override("separation", 12)
	work_frame.add_child(work_row)
	var gallery := ScrollContainer.new(); gallery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	work_row.add_child(gallery)
	work_frames = HBoxContainer.new(); work_frames.add_theme_constant_override("separation", 12)
	gallery.add_child(work_frames)
	# The selector keeps snapshot identity; the visible frames select those same entries.
	work_selector = OptionButton.new()
	work_selector.name = "JournalSavedWorks"
	work_selector.fit_to_longest_item = false
	work_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_selector.item_selected.connect(func(_index: int) -> void: _refresh_work_note())
	work_row.add_child(work_selector)
	work_selector.hide()
	work_view_button = _button(work_row, "JournalViewWork", _open_work)
	work_note = _label(column, 14)
	work_note.name = "JournalWorkScope"
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 12)
	column.add_child(actions)
	enter_button = _button(actions, "JournalEnter", _enter_selected)
	# A scene change must wait until the terminal viewport finishes input dispatch.
	enter_button.pressed.disconnect(_enter_selected)
	enter_button.pressed.connect(_enter_selected, CONNECT_DEFERRED)
	help_button = _button(actions, "JournalHelp", _open_help)
	reflection_button = _button(actions, "JournalReflection", _open_reflection)
	var focus_order: Array[Control] = [region_selector, task_tree, work_view_button, enter_button, help_button, reflection_button, close_button]
	for index: int in range(focus_order.size()):
		focus_order[index].focus_next = focus_order[index].get_path_to(focus_order[(index + 1) % focus_order.size()])
		focus_order[index].focus_previous = focus_order[index].get_path_to(focus_order[(index - 1 + focus_order.size()) % focus_order.size()])
	handbook = Handbook.new()
	handbook.standalone_entry = false
	handbook.z_index = 1400
	add_child(handbook)


func open() -> void:
	if PlaytestData._feedback_visible or get_viewport().gui_is_dragging(): return
	if not visible: previous_focus = get_viewport().gui_get_focus_owner()
	_refresh()
	show()
	preload("res://src/ui/ui_motion.gd").reveal(get_child(1))
	region_selector.grab_focus()


func close() -> void:
	if handbook.is_open(): handbook.close_handbook()
	if is_instance_valid(reflection_dialog): reflection_dialog.queue_free()
	if is_instance_valid(work_focus): work_focus.queue_free()
	hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	previous_focus = null


func _input(event: InputEvent) -> void:
	if not visible or PlaytestData._feedback_visible or not event is InputEventKey or not event.pressed or event.echo: return
	if is_instance_valid(reflection_dialog) and reflection_dialog.visible: return
	if is_instance_valid(work_focus) and work_focus.visible: return
	if event.keycode == KEY_ESCAPE:
		if handbook.is_open():
			handbook.close_handbook()
			help_button.grab_focus()
		else: close()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	rows = TaskNavigation.game_journey_tasks()
	core_records = PersonalRecords.snapshot(TaskNavigation.game_tasks())
	saved_work_state = CandidateFiles.read_session(CreationSession.launch_path(), CreationSession.decode)
	_refresh_works()
	title_label.text = _copy("旅程档案", "Journey journal")
	var done: int = 0
	for row: Dictionary in rows:
		if earned(row): done += 1
	var counts: Dictionary = LabState.progress_counts(rows)
	overview_label.text = _copy("已完成 %d / %d", "Completed %d / %d") % [done, counts.total]
	if counts.temporary > 0: overview_label.text += _copy(" · 临时探索 %d 项", " · %d temporary tasks") % counts.temporary
	scope_label.text = _copy("游戏模式档案 · 测试模式的临时成果不计入。", "Game archive · temporary Test results are excluded.")
	scope_label.visible = GameMode.is_test_mode()
	record_storage_label.text = record_storage_note(PersonalRecords.storage_status, _english())
	record_storage_label.visible = not record_storage_label.text.is_empty()
	record_storage_label.tooltip_text = PersonalRecords.last_error
	overview_label.tooltip_text = _copy("这里根据游戏模式已有记录事后回看，不是按时间补写的事件历史。候选内容取决于启动配置；测试者能进入不代表已完成。", "This view is derived from existing Game records, not a reconstructed event timeline. Candidate content follows this launch's settings; tester access never means earned completion.")
	overview_label.mouse_filter = Control.MOUSE_FILTER_PASS
	enter_button.text = _copy("在测试模式进入原任务", "Open original task in Test") if GameMode.is_test_mode() else _copy("进入原任务", "Open original task")
	help_button.text = _copy("回看规则手册", "Review rule handbook")
	reflection_button.text = _copy("回看已有主题里程碑", "Review existing milestones")
	close_button.text = _copy("返回 · Esc", "Back · Esc")
	var selected_region: int = -1
	if region_selector.selected >= 0: selected_region = int(region_selector.get_item_metadata(region_selector.selected))
	region_selector.clear()
	region_selector.add_item(_copy("全部区域", "All regions"))
	region_selector.set_item_metadata(0, -1)
	regions.clear()
	for row: Dictionary in rows:
		var region: int = int(row.region)
		if region in regions: continue
		regions.append(region)
		region_selector.add_item(region_title(row))
		region_selector.set_item_metadata(region_selector.item_count - 1, region)
		if region == selected_region: region_selector.select(region_selector.item_count - 1)
	_refresh_tasks()


func _refresh_tasks() -> void:
	task_tree.clear()
	var parent: TreeItem = task_tree.create_item()
	var selected: TreeItem
	var region: int = int(region_selector.get_item_metadata(region_selector.selected))
	for row: Dictionary in rows:
		if region >= 0 and int(row.region) != region: continue
		var item := task_tree.create_item(parent)
		item.set_custom_minimum_height(34)
		var mark: String = "✓ " if earned(row) else "○ "
		item.set_text(0, mark + str(row.title))
		item.set_metadata(0, str(row.key))
		item.set_tooltip_text(0, source_note(row))
		if selected == null or str(row.key) == selected_key: selected = item
	_fit_task_rows.call_deferred()
	if selected != null:
		selected.select(0)
		show_task(str(selected.get_metadata(0)))
	else:
		selected_key = ""
		detail.text = _copy("当前区域没有可确认的任务记录。", "No confirmed task records in this region.")
		enter_button.disabled = true


func _fit_task_rows() -> void:
	if task_tree == null or task_tree.get_parent() == null: return
	var space := task_tree.get_parent() as Control
	var panel: StyleBox = task_tree.get_theme_stylebox("panel")
	var margins: float = panel.get_minimum_size().y
	var row_height: float = 34.0 + task_tree.get_theme_constant("v_separation")
	var first: TreeItem = task_tree.get_root().get_first_child() if task_tree.get_root() != null else null
	if first != null and first.get_next() != null:
		var step: float = task_tree.get_item_area_rect(first.get_next()).position.y - task_tree.get_item_area_rect(first).position.y
		if step > 0: row_height = step
	task_tree.size = Vector2(space.size.x, maxf(row_height, floorf((space.size.y - margins) / row_height) * row_height) + margins)


func show_task(key: String) -> void:
	selected_key = key
	var row: Dictionary = selected_task()
	enter_button.disabled = row.is_empty() or not _current_task_available(key)
	help_button.text = _copy("回看规则手册", "Review rule handbook") if str(row.get("domain", "")) in ["hardware_foundations", "chapter_1", "chapter_2", "chapter_3", "chapter_4"] else _copy("查看通用术语（非当前任务规则）", "General terms (not this task's rules)")
	if row.is_empty():
		detail.text = _copy("未知任务身份；没有生成完成记录或文明片段。", "Unknown task identity; no completion record or fiction was created.")
		return
	var context: Dictionary = Catalog.task_context(StringName(row.domain), StringName(row.id), _english())
	var paragraphs: Array[String] = [region_title(row) + " · " + str(row.title), source_note(row)]
	paragraphs.append(_copy("现在做什么", "What to do") + "\n" + str(context.get("action", row.body)))
	if not str(context.get("verify", "")).is_empty(): paragraphs.append(_copy("如何确认", "How to verify") + "\n" + str(context.verify))
	if earned(row):
		var completion: String = str(context.get("completion", ""))
		if not completion.is_empty(): paragraphs.append(_copy("这份完成记录支持的能力回顾", "Capability supported by this completion") + "\n" + completion)
	var connection: String = str(context.get("connection", ""))
	if not connection.is_empty(): paragraphs.append(_copy("与下一段的联系", "Connection to what follows") + "\n" + connection)
	var fragment: String = civilization_fragment(row)
	if not fragment.is_empty(): paragraphs.append(_copy("文明片段 · 虚构候选／事后回顾", "Civilization fragment · Fiction candidate / retrospective") + "\n" + fragment)
	var record: Dictionary = _record_for_task(str(row.key))
	var kind: String = str(record.get("record_kind", "none"))
	var measured: Dictionary = record.get("best", {})
	if kind == "replayed" and not measured.is_empty():
		var heading: String = _copy("已保存方案 · 当前模型复测", "Saved design · remeasured with the current model")
		if str(row.domain) == "chapter_4":
			heading += _copy("\n已达标最快方案；周期与 RAM 读写为两单合计，临时空间取峰值。", "\nFastest saved passing design; cycles and RAM reads/writes sum both cases, scratch uses the maximum.")
		elif str(row.domain) == "chapter_2":
			heading += _copy("\n当前官方工作量中的最快正确实验；不代表已经满足全部任务目标。", "\nFastest saved correct experiment for the current official workload; task targets may remain unmet.")
		_append_record(paragraphs, row, measured, heading)
	var historical: Dictionary = record.get("historical_best", {})
	if not historical.is_empty():
		_append_record(paragraphs, row, historical,
			_copy("已有本地成绩（历史回顾，不与当前草稿作同条件比较）", "Existing local result (historical review, not a matched comparison with the current draft)"))
	if str(row.domain) == "creation": paragraphs.append(work_summary())
	detail.tooltip_text = _copy("来源：", "Source: ") + str(row.key) + " · " + str(row.get("progress_source", "campaign")) + " / " + str(row.get("evidence_status", "saved campaign completion"))
	detail.text = "\n\n".join(paragraphs)


func selected_task() -> Dictionary:
	for row: Dictionary in rows:
		if str(row.key) == selected_key: return row
	return {}


func _record_for_task(key: String) -> Dictionary:
	for row: Dictionary in core_records.get("tasks", []):
		if str(row.key) == key: return row
	return {}


static func record_storage_note(status: String, english: bool) -> String:
	match status:
		"read_only":
			return "Personal records are read-only. The original file is preserved; new results cannot be saved." if english else "个人成绩档案只读。原文件已保留，新成绩暂不写入。"
		"write_failed":
			return "Personal records could not be saved. This update has not reached disk." if english else "个人成绩保存失败。本次更新尚未写入磁盘。"
	return ""


func _append_record(paragraphs: Array[String], task: Dictionary, record: Dictionary, heading: String) -> void:
	var metric_lines: Array[String] = []
	for metric: String in task.get("record_metrics", []):
		var source: String = metric
		if metric == "passed_cases" and not record.has(metric) and record.has("case_count"): source = "case_count"
		if metric == "cycles" and not record.has(metric) and record.has("total_cycles"): source = "total_cycles"
		if metric == "cost" and not record.has(metric) and record.has("hardware_cost"): source = "hardware_cost"
		if not record.has(source): continue
		var label: String = metric
		var unit: String = ""
		match metric:
			"passed_cases": label = _copy("通过样例", "Passed cases")
			"cycles": label = _copy("总周期", "Total cycles")
			"cost": label = _copy("硬件成本", "Hardware cost")
			"ram_read_bytes": label = _copy("RAM 读取", "RAM reads"); unit = " B"
			"ram_write_bytes": label = _copy("RAM 写入", "RAM writes"); unit = " B"
			"peak_extra_bytes": label = _copy("临时空间峰值", "Peak scratch"); unit = " B"
		metric_lines.append(label + ": " + str(record[source]) + unit)
	if metric_lines.is_empty(): return
	var provenance: Array[String] = []
	for field: String in ["condition_id", "case_set_version", "model_version", "ruleset_version", "build_version", "source_commit", "build_commit"]:
		if record.has(field): provenance.append(field + ": " + str(record[field]))
	paragraphs.append(heading + "\n" + " · ".join(metric_lines) + ("\n" + " · ".join(provenance) if not provenance.is_empty() else ""))


func _current_task_available(key: String) -> bool:
	for task: Dictionary in TaskNavigation.journey_tasks():
		if str(task.key) == key: return bool(task.get("unlocked", false))
	return false


func source_note(row: Dictionary) -> String:
	if str(row.get("domain", "")) == "prediction" or str(row.get("progress_source", "")) == "session": return _copy("临时地址预测探索；不生成持久完成或文明片段。", "Temporary address-prediction investigation; no persistent completion or fiction.")
	if str(row.get("evidence_status", "")) in ["unavailable", "readonly", "read_only", "invalid"]: return _copy("保存证据不可确认或只读；不补造已完成历史。", "Saved evidence is unavailable or read-only; no completed history is invented.")
	if earned(row): return _copy("✓ 已有完成记录；重开仅回看，不重复授予。", "✓ Existing completion; reopening only reviews it and grants nothing again.")
	return _copy("○ 尚未完成；可进入与否沿用原任务规则。", "○ Not completed; access follows the original task rules.")


static func earned(row: Dictionary) -> bool:
	return bool(row.get("completed", false)) and str(row.get("domain", "")) != "prediction" and str(row.get("progress_source", "")) != "session" and str(row.get("evidence_status", "")) not in ["unavailable", "readonly", "read_only", "invalid"]


func civilization_fragment(row: Dictionary) -> String:
	if not earned(row): return ""
	match int(row.get("region", -1)):
		0: return _copy("这处档案把一条亲手接通的路径，画成了远处的一点光。光是叙事映射，不是另一台机器的测量。", "The archive pictures a path you connected as a distant light. The light is a narrative mapping, not a measurement of another machine.")
		1, 2, 3, 4: return _copy("旧档案的一页只留下一个问题：等待、位置与安排改变时，哪些可能性会重新出现？这里不把游戏周期换算成现实文明的能耗。", "An old archive page leaves a question: when waiting, placement and arrangement change, what becomes possible again? Game cycles are not converted into a civilization's real energy use.")
		5, 6: return _copy("这页候选故事记下承载与服务的选择。它由现有达标记录开启，没有补写过去何时发生过这些事。", "This candidate story reflects choices of representation and service. Existing accepted records reveal it; it invents no date when those events occurred.")
		8, 9, 10: return _copy("档案留出一页给实际产生的信息与作品。它们的来路仍是原模型、样例和配方，不是对意识或通用智能的证明。", "The archive leaves a page for actual information and works. Their provenance remains the original model, samples and recipe, not proof of consciousness or general intelligence.")
	return ""


func work_summary() -> String:
	var works: Array = _saved_works()
	var heading: String = _copy("已保存作品（只读原快照）", "Saved works (original snapshots, read-only)")
	if not saved_work_state.get("ok", false): heading += _copy("\n证据无法确认；只读可恢复作品不授予完成。", "\nEvidence is unconfirmed; readable recovery works grant no completion.")
	if works.is_empty(): return heading + _copy("\n没有可确认的已保存作品。", "\nNo confirmed saved works.")
	var lines: Array[String] = [heading]
	for work: Dictionary in works:
		lines.append(str(work.get("name", _copy("未命名作品", "Untitled work"))) + " · " + str(work.get("id", "")).left(12))
	return "\n".join(lines)


func _saved_works() -> Array:
	return saved_work_state.get("data", {}).get("works", []) if saved_work_state.get("ok", false) else saved_work_state.get("readonly_works", [])


func _refresh_works(selected_id: String = "") -> void:
	if selected_id.is_empty() and work_selector.selected >= 0:
		selected_id = str(work_selector.get_item_metadata(work_selector.selected))
	work_selector.clear()
	var recovery: bool = not saved_work_state.get("ok", false)
	for work: Dictionary in _saved_works():
		var prefix: String = _copy("只读恢复 · ", "Read-only recovery · ") if recovery else _copy("已保存 · ", "Saved · ")
		work_selector.add_item(prefix + str(work.get("name", _copy("未命名作品", "Untitled work"))) + " · " + str(work.id).left(12))
		work_selector.set_item_metadata(work_selector.item_count - 1, str(work.id))
		if str(work.id) == selected_id: work_selector.select(work_selector.item_count - 1)
	work_selector.disabled = work_selector.item_count == 0
	work_view_button.disabled = work_selector.disabled
	work_view_button.text = _copy("查看原快照", "View saved snapshot")
	if work_selector.disabled:
		work_selector.add_item(_copy("没有可查看的已保存作品", "No saved work is available"))
	for child: Node in work_frames.get_children():
		work_frames.remove_child(child); child.queue_free()
	var works: Array = _saved_works()
	for index: int in (3 if works.is_empty() else works.size()):
		var frame := Button.new(); frame.custom_minimum_size = Vector2(176, 100)
		frame.clip_text = true; frame.alignment = HORIZONTAL_ALIGNMENT_CENTER
		frame.disabled = works.is_empty()
		var box := preload("res://src/ui/instrument_theme.gd").surface(Color("111a21"), Color("33434e"), 2)
		box.set_border_width_all(2)
		for state: String in ["normal", "disabled"]: frame.add_theme_stylebox_override(state, box)
		work_frames.add_child(frame)
		if works.is_empty(): continue
		var work: Dictionary = works[index]
		frame.tooltip_text = str(work.get("name", _copy("未命名作品", "Untitled work")))
		var caption := Label.new(); caption.text = frame.tooltip_text
		caption.position = Vector2(8, 76); caption.size = Vector2(160, 22)
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.add_theme_font_size_override("font_size", 13)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(caption)
		var preview := preload("res://src/ui/saved_content_preview.gd").new()
		frame.add_child(preview); preview.position = Vector2(8, 6)
		preview.english = _english(); preview.configure_work(work, not recovery)
		frame.pressed.connect(func() -> void:
			work_selector.select(index)
			_refresh_work_note())
	var targets: Array[Control] = [task_tree]
	if not works.is_empty():
		for frame: Node in work_frames.get_children(): targets.append(frame as Control)
	targets.append(work_view_button)
	for index: int in targets.size() - 1:
		targets[index].focus_next = targets[index].get_path_to(targets[index + 1])
		targets[index + 1].focus_previous = targets[index + 1].get_path_to(targets[index])
	_refresh_work_note()


func _refresh_work_note() -> void:
	for index: int in work_frames.get_child_count():
		var frame := work_frames.get_child(index) as Button
		var selected: bool = not work_selector.disabled and index == work_selector.selected
		var box := frame.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		box.border_color = (task_tree.get_theme_stylebox("selected") as StyleBoxFlat).border_color if selected else (frame.get_theme_stylebox("disabled") as StyleBoxFlat).border_color
		frame.add_theme_stylebox_override("normal", box)
	if work_view_button.disabled:
		work_note.text = Localization.text(&"a3.works.empty")
	elif not saved_work_state.get("ok", false):
		work_note.text = _copy("只读恢复快照 · 原支持证据不可确认；不授予完成，也没有生成回放证据。", "Read-only recovery snapshot · support evidence is unconfirmed; no completion or generation replay is supplied.")
	else:
		work_note.text = _copy("只看原输出、配方与来源 · 此入口没有生成回放证据，也不分叉修改。", "Review the saved output, recipe and source · no generation replay or editable fork is supplied here.")


func _open_work() -> void:
	if PlaytestData._feedback_visible or get_node("/root/OfflineFeedback").busy: return
	if is_instance_valid(work_focus):
		work_focus.popup()
		return
	if work_selector.disabled or work_selector.selected < 0: return
	var selected_id: String = str(work_selector.get_item_metadata(work_selector.selected))
	# Resolve against disk again, so an obsolete list never opens an old snapshot.
	saved_work_state = CandidateFiles.read_session(CreationSession.launch_path(), CreationSession.decode)
	_refresh_works(selected_id)
	for work: Dictionary in _saved_works():
		if str(work.id) != selected_id: continue
		var exhibit := WorkFocus.new()
		exhibit.name = "JournalWorkFocus"
		exhibit.theme = theme
		exhibit.reduced_motion = bool(ProjectSettings.get_setting("game/reduced_motion", false))
		exhibit.configure(work.duplicate(true), _english(), {})
		work_focus = exhibit
		exhibit.request_feedback.connect(_open_work_feedback)
		exhibit.tree_exited.connect(_work_closed, CONNECT_ONE_SHOT)
		add_child(exhibit)
		exhibit.fork_button.disabled = true
		exhibit.close_button.text = _copy("返回旅程档案", "Back to journal")
		if not saved_work_state.get("ok", false):
			exhibit.title = _copy("只读恢复作品 · 原快照", "Read-only recovered work · original snapshot")
		var provenance: Label = exhibit.make_label(work_note.text, exhibit.closing_label.get_parent(), 13)
		provenance.name = "JournalWorkProvenance"
		exhibit.popup_centered_clamped(Vector2i(1080, 620), 0.92)
		return
	work_note.text = _copy("作品或保存证据已经变化；请重新选择，档案保持打开。", "The work or its saved evidence has changed. Select it again; the journal stays open.")


func _open_work_feedback() -> void:
	if not is_instance_valid(work_focus): return
	work_focus.call("pause_playback")
	get_node("/root/PlaytestMoments").toggle()


func _work_closed() -> void:
	work_focus = null
	if visible and not PlaytestData._feedback_visible and not work_view_button.disabled:
		work_view_button.grab_focus()


func region_title(row: Dictionary) -> String:
	return str(row.region_title) if row.has("region_title") else Localization.text(StringName(row.get("region_title_key", "tree.region." + str(row.region))))


func _enter_selected() -> void:
	var key: String = selected_key
	for row: Dictionary in TaskNavigation.journey_tasks():
		if str(row.key) == key and bool(row.get("unlocked", false)):
			if TaskNavigation.enter(key):
				close()
				return
			break
	_refresh()
	detail.text += "\n\n" + _copy("任务身份、进入条件或工作台已变化；档案保持打开，请检查当前任务。", "Task identity, access or workbench changed; the journal stays open. Inspect the current task.")


func _open_help() -> void:
	var row: Dictionary = selected_task()
	if row.is_empty(): return
	var chapter: String = {"hardware_foundations":"hardware", "chapter_1":"system", "chapter_2":"locality", "chapter_3":"overlap", "chapter_4":"layout"}.get(str(row.domain), "")
	handbook.set_lesson(chapter, str(row.id) if not chapter.is_empty() else "")
	if chapter.is_empty():
		handbook.context_lesson = &""
		handbook.recommended_toggle.set_pressed_no_signal(false)
	handbook.open_handbook()


func _open_reflection() -> void:
	if is_instance_valid(reflection_dialog): reflection_dialog.queue_free()
	reflection_dialog = Reflection.new()
	add_child(reflection_dialog)
	reflection_dialog.configure(Reflection.milestones(GlobalSave.game_player_content.completed_levels,
		SystemChapter.game_completed, LocalityChapter.game_completed, OverlapChapter.game_solutions, LayoutChapter.game_solutions), Localization.text)
	reflection_dialog.popup_centered(Vector2i(650, 480))


func _english() -> bool:
	return Localization.current_locale() == "en"


func _copy(zh: String, en: String) -> String:
	return en if _english() else zh


func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size",16)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
