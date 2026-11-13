extends Control
## Standalone presenter. The session owns drafts/history; the model owns results.
const Workspace = preload("res://experiments/layout_strategy/workspace.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
const Challenges = preload("res://experiments/layout_strategy/challenges.gd")
const ChallengeCode = preload("res://experiments/layout_strategy/challenge_code.gd")
const ChallengeWindow = preload("res://experiments/layout_strategy/challenge_window.gd")
const Explanation = preload("res://experiments/layout_strategy/explanation.gd")
var workspace = Workspace.new()
var session = workspace.session
var challenges = Challenges.new()
var notebook_path: String = ""
var challenge_path: String = ""
var legacy_notebook_path: String = ""
var legacy_challenge_path: String = ""
var english: bool = false
var _syncing: bool = false
var _owns_quit: bool = false
var _previous_auto_quit: bool = true
var _previous_minimum: Vector2i
var _last_focus: String = "Run"
var _exit_focus: WeakRef
var _exit_focus_id: String = "Run"
var _notice: String = ""
var _shown_entry: int = -1
var _kept_selection: Dictionary = {}
var _kept_rows: Array[Dictionary] = []
var _guard_action: String = "exit"
var _pending_remove: String = ""
var _pending_numeric: SpinBox
var _challenge_task: String = ""
var _challenge_focus: String = "Challenges"
var _challenge_settings_focus: String = "ChallengeSettings"
var _challenge_settings_pending: bool = false
var _challenge_verdict_key: String = ""
var _challenge_verdict: Dictionary = {}
var _explaining: bool = false
var _inspecting_comparison: bool = false
var _explanation_key: String = ""
var _explanation: Dictionary = {}
var _explanation_entries: Dictionary = {}
var _explanation_scope: Dictionary = {}
var _explanation_lens: int = 0
var _event_side: String = "selected"
var selected_event: int = -1
var interface: MarginContainer
var run_button: Button
var undo_button: Button
var redo_button: Button
var language_button: Button
var settings_button: Button
var exit_button: Button
var workload_choice: OptionButton
var workload_note: Label
var query_group: SpinBox
var record_tile: SpinBox
var group_note: Label
var tile_note: Label
var copy_mode: OptionButton
var field_buttons: Array[CheckBox] = []
var destination: OptionButton
var copy_note: Label
var status: Label
var tabs: TabContainer
var history_table: Tree
var measured_source: Label
var measured_plan: Label
var comparison_label: Label
var restore_button: Button
var baseline_button: Button
var explanation_button: Button
var challenge_button: Button
var challenge_summary: Label
var challenge_window: Window
var event_filter: OptionButton
var event_table: Tree
var event_source: Label
var event_detail: RichTextLabel
var evidence_page: VBoxContainer
var evidence_mode: OptionButton
var explanation_view: VBoxContainer
var explanation_heading: Label
var explanation_plans: Label
var explanation_context: Label
var explanation_lens: OptionButton
var explanation_table: Tree
var explanation_note: Label
var inspect_selected: Button
var inspect_baseline: Button
var raw_view: VBoxContainer
var event_navigation: HBoxContainer
var event_back: Button
var event_side_choice: OptionButton
var event_scope: Label
var public_detail: RichTextLabel
var storage_label: Label
var notebook_table: Tree
var notebook_name: LineEdit
var notebook_selected: Label
var notebook_note: Label
var notebook_restore: Button
var notebook_remove: Button
var notebook_keep: Button
var notebook_save: Button
var notebook_recover: Button
var goal_controls: VBoxContainer
var goal_objective: OptionButton
var first_cap: CheckBox
var first_limit: SpinBox
var copy_cap: CheckBox
var copy_limit: SpinBox
var goal_summary: Label
var exit_layer: CanvasLayer
var exit_overlay: ColorRect
var exit_question: Label
var exit_cancel: Button
var exit_confirm: Button
var exit_save: Button
var exit_target_retry: Button

static func isolated_profile(path: String) -> bool:
	return path.replace("\\","/").contains("/VonNeumannBottleneckChecks/")

func tr2(zh: String, en: String) -> String:
	return en if english else zh

func _ready() -> void:
	if not isolated_profile(OS.get_user_data_dir()):
		push_error("Layout scheduling lab requires scripts/run-experiment.py and an isolated QA profile.")
		get_tree().quit(1)
		return
	_previous_auto_quit = get_tree().auto_accept_quit
	_previous_minimum = get_window().min_size
	get_tree().auto_accept_quit = false
	_owns_quit = true
	add_to_group("candidate_quit_owners")
	theme = Theme.new()
	InstrumentTheme.apply_to(theme)
	theme.default_font_size = 15
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	english = get_node("/root/Localization").current_locale() == "en"
	workspace.setup(notebook_path,legacy_notebook_path)
	challenges.setup(challenge_path,legacy_challenge_path)
	_build()
	_build_exit_guard()
	call_deferred("_set_minimum_window")
	run_button.call_deferred("grab_focus")

func _set_minimum_window() -> void:
	get_window().min_size = Vector2i(960,640)

func _label(parent: Node, value: String, font_size: int = 15) -> Label:
	var control := Label.new()
	control.text = value
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size",font_size)
	parent.add_child(control)
	return control

func _button(parent: Node, value: String, action: Callable, id: String) -> Button:
	var control := Button.new()
	control.name = id
	control.text = value
	control.custom_minimum_size.y = 34
	control.pressed.connect(action)
	control.focus_entered.connect(func() -> void: _last_focus = id)
	parent.add_child(control)
	return control

func _choice(parent: Node, values: Array[String], id: String) -> OptionButton:
	var control := OptionButton.new()
	control.name = id
	control.custom_minimum_size.y = 32
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.fit_to_longest_item = false
	for value: String in values: control.add_item(value)
	control.focus_entered.connect(func() -> void: _last_focus = id)
	parent.add_child(control)
	return control

func _spin(parent: Node, caption: String, id: String, maximum: int) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var heading: Label = _label(row,caption)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var control := SpinBox.new()
	control.name = id
	control.min_value = 1
	control.max_value = maximum
	control.step = 1
	control.custom_minimum_size = Vector2(96,32)
	control.get_line_edit().focus_entered.connect(func() -> void: _last_focus = id)
	control.get_line_edit().text_changed.connect(func(_text: String) -> void:
		if not _syncing: _pending_numeric = control)
	row.add_child(control)
	return control

func _table(parent: Node, titles: Array[String], id: String) -> Tree:
	var control := Tree.new()
	control.name = id
	control.columns = titles.size()
	control.hide_root = true
	control.column_titles_visible = true
	control.select_mode = Tree.SELECT_ROW
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.focus_entered.connect(func() -> void: _last_focus = id)
	for column: int in titles.size():
		control.set_column_title(column,titles[column])
		control.set_column_custom_minimum_width(column,52)
		control.set_column_expand(column,true)
	parent.add_child(control)
	return control

func _reader(parent: Node, id: String, minimum_height: float = 0.0) -> RichTextLabel:
	var control := RichTextLabel.new()
	control.name = id
	control.selection_enabled = true
	control.focus_mode = Control.FOCUS_ALL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.y = minimum_height
	control.focus_entered.connect(func() -> void: _last_focus = id)
	parent.add_child(control)
	return control

func _build() -> void:
	_pending_numeric = null
	var previous_tab: int = tabs.current_tab if is_instance_valid(tabs) else 0
	var previous_filter: int = event_filter.selected if is_instance_valid(event_filter) else 0
	var previous_name: String = notebook_name.text if is_instance_valid(notebook_name) else ""
	if is_instance_valid(interface):
		remove_child(interface)
		interface.queue_free()
	field_buttons.clear()
	interface = MarginContainer.new()
	interface.name = "Interface"
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]:
		interface.add_theme_constant_override("margin_"+side,12)
	add_child(interface)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation",8)
	interface.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	var title: Label = _label(header,tr2("调度与复制", "Scheduling & copying"),22)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_button = _button(header,tr2("撤销","Undo"),undo,"Undo")
	redo_button = _button(header,tr2("重做","Redo"),redo,"Redo")
	run_button = _button(header,tr2("运行方案","Run plan"),run_current,"Run")
	run_button.tooltip_text = tr2("⌘/Ctrl+Enter：运行当前草稿","⌘/Ctrl+Enter: run the current draft")
	InstrumentTheme.primary(run_button)
	language_button = _button(header,"EN" if not english else "中文",toggle_language,"Language")
	settings_button = get_node("/root/WindowMode").settings_button()
	settings_button.custom_minimum_size = Vector2(64,34)
	settings_button.focus_entered.connect(func() -> void: _last_focus = str(settings_button.name))
	header.add_child(settings_button)
	exit_button = _button(header,tr2("退出","Exit"),request_quit,"Exit")
	storage_label = _label(page,"",13)
	storage_label.name = "WorkspaceStatus"
	var workload_row := HBoxContainer.new()
	page.add_child(workload_row)
	var workload_names: Array[String] = []
	for id: String in Model.SCENARIO_IDS:
		workload_names.append(ChallengeWindow.workload_text(id,english))
	workload_choice = _choice(workload_row,workload_names,"Workload")
	workload_choice.custom_minimum_size.x = 300
	workload_choice.size_flags_horizontal = Control.SIZE_FILL
	workload_choice.item_selected.connect(func(index: int) -> void: change_task(Model.SCENARIO_IDS[index]))
	workload_note = _label(workload_row,"",14)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	page.add_child(body)
	var editor_panel := PanelContainer.new()
	editor_panel.custom_minimum_size.x = 288
	editor_panel.add_theme_stylebox_override("panel",InstrumentTheme.panel(InstrumentTheme.SURFACE))
	body.add_child(editor_panel)
	var editor := VBoxContainer.new()
	editor.add_theme_constant_override("separation",4)
	editor_panel.add_child(editor)
	_label(editor,tr2("当前草稿","Current draft"),18)
	query_group = _spin(editor,tr2("一组查询数","Queries per group"),"QueryGroup",16)
	query_group.value_changed.connect(func(value: float) -> void: _edit_value("query_group",int(value)))
	group_note = _label(editor,"",13)
	record_tile = _spin(editor,tr2("每块记录数","Records per tile"),"RecordTile",64)
	record_tile.value_changed.connect(func(value: float) -> void: _edit_value("record_tile",int(value)))
	tile_note = _label(editor,"",13)
	var separator := HSeparator.new()
	editor.add_child(separator)
	_label(editor,tr2("真正复制的数据","Physical copy"),17)
	copy_mode = _choice(editor,[tr2("不复制 · 直接读取","No copy · read source"),tr2("保留一份副本","Retain a full copy")],"CopyMode")
	copy_mode.item_selected.connect(func(index: int) -> void: _edit_value("copy_mode","none" if index == 0 else "full"))
	var fields := GridContainer.new()
	fields.columns = 2
	editor.add_child(fields)
	for field: int in 4:
		var control := CheckBox.new()
		control.name = "CopyField"+str(field)
		control.text = field_name(field)
		control.tooltip_text = "F"+str(field)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.toggled.connect(func(on: bool) -> void: _edit_field(field,on))
		control.focus_entered.connect(func() -> void: _last_focus = "CopyField"+str(field))
		fields.add_child(control)
		field_buttons.append(control)
	destination = _choice(editor,[tr2("副本按记录排列","Copy: record-major"),tr2("副本按字段排列","Copy: field-major")],"Destination")
	destination.item_selected.connect(func(index: int) -> void:
		if index < 2: _edit_value("recipe",Recipe.record_major() if index == 0 else Recipe.field_major()))
	copy_note = _label(editor,"",13)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.add_child(spacer)
	status = _label(editor,"",14)
	status.name = "DraftStatus"
	status.custom_minimum_size.y = 42
	var comparison_column := VBoxContainer.new()
	comparison_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(comparison_column)
	_build_goal_controls(comparison_column)
	tabs = TabContainer.new()
	tabs.name = "Results"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	comparison_column.add_child(tabs)
	var comparison_page := VBoxContainer.new()
	comparison_page.name = tr2("比较","Compare")
	comparison_page.add_theme_constant_override("separation",6)
	tabs.add_child(comparison_page)
	measured_source = _label(comparison_page,"",14)
	measured_source.name = "MeasuredSource"
	history_table = _table(comparison_page,[
		tr2("运行","Run"),tr2("Q1周期","Q1 cycles"),tr2("总周期","Total"),
		"RAM B",tr2("复制 B","Copy B"),tr2("限制","Goal")],"History")
	history_table.item_selected.connect(_history_selected)
	measured_plan = _label(comparison_page,"",13)
	measured_plan.name = "MeasuredPlan"
	measured_plan.custom_minimum_size.y = 36
	var actions := HBoxContainer.new()
	comparison_page.add_child(actions)
	restore_button = _button(actions,tr2("恢复此方案","Restore plan"),restore_selected,"Restore")
	baseline_button = _button(actions,tr2("设为比较基准","Set comparison"),set_baseline,"SetBaseline")
	explanation_button = _button(actions,tr2("查看差异","Explain"),open_explanation,"Explain")
	challenge_button = _button(actions,tr2("挑战…","Challenges…"),open_challenges,"Challenges")
	comparison_label = _label(comparison_page,"",14)
	comparison_label.name = "Comparison"
	comparison_label.custom_minimum_size.y = 42
	challenge_summary = _label(comparison_page,"",13)
	challenge_summary.name = "ActiveChallenge"
	evidence_page = VBoxContainer.new()
	evidence_page.name = tr2("运行证据","Evidence")
	evidence_page.add_theme_constant_override("separation",6)
	tabs.add_child(evidence_page)
	evidence_mode = _choice(evidence_page,[tr2("原始事件","Raw events"),tr2("解释比较","Explain comparison")],"EvidenceMode")
	evidence_mode.select(1 if _explaining else 0)
	evidence_mode.item_selected.connect(func(index: int) -> void:
		_preserve_numeric_for_inspection()
		_explaining = index == 1
		_inspecting_comparison = false
		selected_event = -1
		_refresh_explanation()
		_refresh_events())
	_build_explanation()
	raw_view = VBoxContainer.new()
	raw_view.name = "RawEvidence"
	raw_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raw_view.add_theme_constant_override("separation",6)
	evidence_page.add_child(raw_view)
	event_navigation = HBoxContainer.new()
	raw_view.add_child(event_navigation)
	event_back = _button(event_navigation,tr2("返回差异","Back to comparison"),back_to_explanation,"BackToExplanation")
	event_side_choice = _choice(event_navigation,[],"EventSide")
	event_side_choice.item_selected.connect(func(index: int) -> void:
		_event_side = "selected" if index == 0 else "baseline"
		selected_event = -1
		_refresh_events())
	event_scope = _label(raw_view,"",13)
	event_source = _label(raw_view,"",14)
	event_filter = _choice(raw_view,[
		tr2("请求与响应","Requests & responses"),
		tr2("内存事件","Memory events"),
		tr2("全部事件","All events")],"EventFilter")
	event_filter.select(previous_filter)
	event_filter.item_selected.connect(func(_index: int) -> void: _refresh_events())
	event_table = _table(raw_view,[tr2("周期","Cycle"),tr2("事件","Event"),tr2("请求","Job"),tr2("地址","Addr"),"RAM B"],"Events")
	event_table.set_column_expand_ratio(1,2)
	event_table.item_selected.connect(_event_selected)
	event_detail = _reader(raw_view,"EventDetail",128)
	event_detail.size_flags_vertical = Control.SIZE_FILL
	var public_page := VBoxContainer.new()
	public_page.name = tr2("公开工作负载","Public workload")
	tabs.add_child(public_page)
	public_detail = _reader(public_page,"PublicData")
	_build_notebook()
	notebook_name.text = previous_name
	tabs.tab_changed.connect(func(_index: int) -> void: _refresh_goal_visibility())
	tabs.current_tab = previous_tab
	_refresh_goal_visibility()
	_shown_entry = -1
	refresh()

func _build_explanation() -> void:
	explanation_view = VBoxContainer.new()
	explanation_view.name = "ComparisonEvidence"
	explanation_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	explanation_view.add_theme_constant_override("separation",5)
	evidence_page.add_child(explanation_view)
	explanation_heading = _label(explanation_view,"",16)
	explanation_heading.name = "ExplanationHeading"
	explanation_plans = _label(explanation_view,"",13)
	explanation_plans.name = "ExplanationPlans"
	explanation_context = _label(explanation_view,"",12)
	explanation_context.name = "ExplanationContext"
	explanation_lens = _choice(explanation_view,[
		tr2("周期与RAM流量","Cycles & RAM traffic"),tr2("缓存读取","Cache reads"),
		tr2("请求时序","Request timing")],"ExplanationLens")
	explanation_lens.select(_explanation_lens)
	explanation_lens.item_selected.connect(func(index: int) -> void:
		_explanation_lens = index
		_explanation_scope = {}
		_render_explanation_rows())
	explanation_table = _table(explanation_view,[
		tr2("实测项目","Measured quantity"),tr2("所选","Selected"),
		tr2("基准","Baseline"),tr2("差值","Difference")],"ExplanationRows")
	explanation_table.custom_minimum_size.y = 112
	explanation_table.set_column_expand_ratio(0,2)
	explanation_table.item_selected.connect(_explanation_row_selected)
	explanation_note = _label(explanation_view,"",12)
	explanation_note.name = "ExplanationNote"
	var actions := HBoxContainer.new()
	explanation_view.add_child(actions)
	inspect_selected = _button(actions,tr2("查看所选事件","Selected events"),
		func() -> void: inspect_explanation("selected"),"InspectSelected")
	inspect_baseline = _button(actions,tr2("查看基准事件","Baseline events"),
		func() -> void: inspect_explanation("baseline"),"InspectBaseline")

func _phase_name(key: String) -> String:
	match key:
		"prepare": return tr2("准备","Preparation")
		"query": return tr2("查询","Query")
		"output": return tr2("输出","Output")
		"total": return tr2("总计","Total")
	return key

func open_explanation() -> void:
	if _modal_blocked() or (is_instance_valid(exit_overlay) and exit_overlay.visible): return
	_preserve_numeric_for_inspection()
	_explaining = true
	_inspecting_comparison = false
	evidence_mode.select(1)
	tabs.current_tab = 1
	_refresh_explanation()
	explanation_lens.grab_focus()

func back_to_explanation() -> void:
	if _modal_blocked() or (is_instance_valid(exit_overlay) and exit_overlay.visible): return
	_inspecting_comparison = false
	_refresh_explanation()
	explanation_table.grab_focus()

func _explanation_identity(entry: Dictionary) -> Array:
	return [entry.get("id",-1),entry.get("condition_id",""),
		entry.get("trace_id",""),entry.get("correct",false)]

func _refresh_explanation() -> void:
	if not is_instance_valid(explanation_view) or not is_instance_valid(raw_view): return
	var selected: Dictionary = session.selected_entry()
	var baseline: Dictionary = session.baseline_entry()
	var condition: String = Model.condition_id(session.task())
	var key: String = JSON.stringify([condition,_explanation_identity(selected),_explanation_identity(baseline)])
	if key != _explanation_key:
		_explanation_key = key
		_explanation = {}
		_explanation_entries = {"selected":selected,"baseline":baseline}
		_explanation_scope = {}
		_inspecting_comparison = false
		if _explaining: selected_event = -1
	_disable(explanation_button,selected.is_empty() or baseline.is_empty()
		or not selected.get("correct",false) or not baseline.get("correct",false)
		or selected.get("condition_id","") != condition or baseline.get("condition_id","") != condition)
	if _explaining and _explanation.is_empty():
		_explanation = Explanation.compare(selected,baseline,condition)
	var available: bool = bool(_explanation.get("ok",false))
	if _inspecting_comparison and not available: _inspecting_comparison = false
	explanation_view.visible = _explaining and not _inspecting_comparison
	raw_view.visible = not _explaining or _inspecting_comparison
	event_navigation.visible = _explaining and _inspecting_comparison
	event_scope.visible = event_navigation.visible
	if not _explaining: return
	explanation_heading.text = tr2("所选 #%d − 基准 #%d","Selected #%d − baseline #%d") % [
		int(selected.get("id",-1)),int(baseline.get("id",-1))]
	explanation_heading.tooltip_text = tr2("差值方向：所选减去基准。","Difference direction: selected minus baseline.")
	explanation_plans.text = tr2("所选：%s\n基准：%s","Selected: %s\nBaseline: %s") % [
		_plan_text(selected.plan).replace("\n"," · ") if selected.has("plan") else "—",
		_plan_text(baseline.plan).replace("\n"," · ") if baseline.has("plan") else "—"]
	explanation_context.text = (tr2("按总周期比较","Rank by total cycles") if session.goal().objective == "cycles"
		else tr2("按RAM流量比较","Rank by RAM bytes"))+" · "+_goal_text()
	for row: Dictionary in session.ranked_rows():
		if row.get("eligible",false): continue
		if int(row.id) == int(selected.get("id",-1)):
			explanation_context.text += tr2(" · 所选超限"," · selected outside goal")
		if int(row.id) == int(baseline.get("id",-1)):
			explanation_context.text += tr2(" · 基准超限"," · baseline outside goal")
	if not available:
		explanation_heading.text = tr2("比较证据不可用","Comparison evidence unavailable")
		explanation_context.text = tr2("需要两次完整、正确且属于当前条件的实测记录。仍可查看原始事件。",
			"Two complete, correct measurements in this condition are required. Raw events remain available.")
		explanation_context.tooltip_text = str(_explanation.get("reason",""))
	else:
		explanation_context.tooltip_text = tr2("同条件指纹：","Same condition: ")+condition
	explanation_lens.disabled = not available
	explanation_lens.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	_render_explanation_rows()
	if _inspecting_comparison: _refresh_events()

func _explanation_row(parent: TreeItem, title: String, selected: int, baseline: int, scope: Dictionary) -> void:
	var item: TreeItem = explanation_table.create_item(parent)
	item.set_text(0,title)
	item.set_text(1,str(selected))
	item.set_text(2,str(baseline))
	item.set_text(3,_signed(selected-baseline))
	item.set_metadata(0,scope.duplicate(true))
	for column: int in 4: item.set_tooltip_text(column,title)
	if _explanation_scope == scope: item.select(0)

func _render_explanation_rows() -> void:
	var was_syncing: bool = _syncing
	_syncing = true
	explanation_table.clear()
	var tree_root: TreeItem = explanation_table.create_item()
	var available: bool = bool(_explanation.get("ok",false))
	if available:
		explanation_table.set_column_title(1,tr2("所选 #%d","Selected #%d") % int(_explanation.selected.id))
		explanation_table.set_column_title(2,tr2("基准 #%d","Baseline #%d") % int(_explanation.baseline.id))
		if _explanation_lens == 0:
			for phase: Dictionary in _explanation.phases:
				_explanation_row(tree_root,_phase_name(str(phase.key))+tr2(" · 周期"," · cycles"),
					int(phase.selected.cycles),int(phase.baseline.cycles),{"kind":"phase","key":phase.key,"metric":"cycles"})
				_explanation_row(tree_root,_phase_name(str(phase.key))+" · RAM B",
					int(phase.selected.ram_bytes),int(phase.baseline.ram_bytes),{"kind":"phase","key":phase.key,"metric":"ram_bytes"})
			_explanation_row(tree_root,tr2("已复制数据 B","Copied payload B"),
				int(_explanation.selected.copy_payload_bytes),int(_explanation.baseline.copy_payload_bytes),
				{"kind":"phase","key":"prepare","metric":"payload"})
			_explanation_row(tree_root,tr2("复制分配 B","Copy allocation B"),
				int(_explanation.selected.copy_allocated_bytes),int(_explanation.baseline.copy_allocated_bytes),
				{"kind":"phase","key":"prepare","metric":"allocation"})
		elif _explanation_lens == 1:
			for phase: Dictionary in _explanation.phases:
				if str(phase.key) == "output": continue
				for metric: String in ["lookups","hits","fills","writes","ram_read_bytes","ram_write_bytes"]:
					var labels: Dictionary = {
						"lookups":tr2("读查找","read lookups"),"hits":tr2("读命中","read hits"),
						"fills":tr2("读缺失","read misses"),"writes":tr2("写入次数","write count"),
						"ram_read_bytes":tr2("RAM读取 B","RAM read B"),
						"ram_write_bytes":tr2("RAM写入 B","RAM write B"),
					}
					_explanation_row(tree_root,_phase_name(str(phase.key))+" · "+str(labels[metric]),
						int(phase.selected[metric]),int(phase.baseline[metric]),{"kind":"phase","key":phase.key,"metric":metric})
		else:
			for job: Dictionary in _explanation.jobs:
				for metric: String in ["admission","completion","elapsed"]:
					var labels: Dictionary = {
						"admission":tr2("就绪周期","admission"),"completion":tr2("完成周期","completion"),
						"elapsed":tr2("等待至完成","elapsed cycles"),
					}
					_explanation_row(tree_root,"Q%d · %s" % [int(job.id)+1,str(labels[metric])],
						int(job.selected[metric]),int(job.baseline[metric]),{"kind":"job","id":int(job.id),"metric":metric})
		if explanation_table.get_selected() == null and tree_root.get_first_child() != null:
			tree_root.get_first_child().select(0)
		if explanation_table.get_selected() != null:
			explanation_table.scroll_to_item(explanation_table.get_selected())
	_syncing = was_syncing
	explanation_note.text = tr2("逐项实测差异，不把收益归因于单个设置。选择一行查看该阶段的原始事件。",
		"Measured differences, not causes assigned to a setting. Select a row to inspect its events.")
	if _explanation_lens == 2:
		explanation_note.text = tr2("等待至完成＝完成−就绪；包含准备与交替执行，不能相加当作总工作量。",
			"Elapsed = completion − admission, including preparation and interleaving. Do not sum it as work.")
	if not available: explanation_note.text = ""
	_disable(inspect_selected,not available)
	_disable(inspect_baseline,not available)
	_explanation_row_selected()

func _explanation_row_selected() -> void:
	if _syncing: return
	var item: TreeItem = explanation_table.get_selected()
	if item == null: return
	_explanation_scope = item.get_metadata(0).duplicate(true)

func _explanation_scope_name() -> String:
	if _explanation_scope.get("kind","") == "job": return "Q"+str(int(_explanation_scope.id)+1)
	return _phase_name(str(_explanation_scope.get("key","total")))

func _explanation_indices() -> Array:
	var summary: Dictionary = _explanation.get(_event_side,{})
	var rows: Array = summary.get("jobs",[]) if _explanation_scope.get("kind","") == "job" else summary.get("phases",[])
	for row: Dictionary in rows:
		if _explanation_scope.get("kind","") == "job" and int(row.id) == int(_explanation_scope.id):
			return row.event_indices
		if _explanation_scope.get("kind","") == "phase" and str(row.key) == str(_explanation_scope.key):
			return row.event_indices
	return []

func inspect_explanation(side: String) -> void:
	if _modal_blocked() or (is_instance_valid(exit_overlay) and exit_overlay.visible): return
	if not _explanation.get("ok",false) or side not in ["selected","baseline"]: return
	_preserve_numeric_for_inspection()
	_event_side = side
	_inspecting_comparison = true
	selected_event = -1
	event_filter.select(2)
	explanation_view.hide()
	raw_view.show()
	event_navigation.show()
	event_scope.show()
	_refresh_events()
	event_table.grab_focus()

func _event_entry() -> Dictionary:
	if _explaining and _inspecting_comparison:
		return _explanation_entries.get(_event_side,{})
	return session.selected_entry()

func _build_goal_controls(parent: Node) -> void:
	goal_controls = VBoxContainer.new()
	goal_controls.name = "ComparisonGoals"
	goal_controls.add_theme_constant_override("separation",5)
	parent.add_child(goal_controls)
	var top := HBoxContainer.new()
	goal_controls.add_child(top)
	goal_objective = _choice(top,[tr2("按总周期比较","Compare total cycles"),tr2("按RAM流量比较","Compare RAM bytes")],"GoalObjective")
	goal_objective.item_selected.connect(func(index: int) -> void:
		_edit_goal("objective","cycles" if index == 0 else "traffic"))
	var limits := HBoxContainer.new()
	limits.add_theme_constant_override("separation",6)
	goal_controls.add_child(limits)
	first_cap = _cap_toggle(limits,tr2("限制Q1","Limit Q1"),"FirstCap")
	first_limit = _cap_number(limits,"FirstLimit")
	first_limit.suffix = tr2("周期","cycles")
	copy_cap = _cap_toggle(limits,tr2("限制复制","Limit copy"),"CopyCap")
	copy_limit = _cap_number(limits,"CopyLimit")
	copy_limit.suffix = "B"
	first_cap.toggled.connect(func(on: bool) -> void:
		_edit_goal("first_limit",int(first_limit.value) if on else -1))
	copy_cap.toggled.connect(func(on: bool) -> void:
		_edit_goal("copy_limit",int(copy_limit.value) if on else -1))
	first_limit.value_changed.connect(func(value: float) -> void:
		if first_cap.button_pressed: _edit_goal("first_limit",int(value)))
	copy_limit.value_changed.connect(func(value: float) -> void:
		if copy_cap.button_pressed: _edit_goal("copy_limit",int(value)))

func _refresh_goal_visibility() -> void:
	goal_controls.visible = tabs.current_tab in [0,3]

func _build_notebook() -> void:
	var page := VBoxContainer.new()
	page.name = tr2("方案笔记","Notebook")
	page.add_theme_constant_override("separation",5)
	tabs.add_child(page)
	var top := HBoxContainer.new()
	page.add_child(top)
	notebook_save = _button(top,tr2("保存工作区","Save workspace"),save_workspace,"SaveWorkspace")
	goal_summary = _label(page,"",13)
	goal_summary.name = "GoalSummary"
	notebook_table = _table(page,[
		tr2("方案","Plan"),"Q1",tr2("总计","Total"),"RAM B",tr2("复制 B","Copy B"),tr2("名次/限制","Rank/goal")],"KeptPlans")
	notebook_table.custom_minimum_size.y = 80
	notebook_table.set_column_expand_ratio(0,2)
	notebook_table.set_column_custom_minimum_width(0,110)
	notebook_table.set_column_custom_minimum_width(5,90)
	notebook_table.item_selected.connect(_kept_selected)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	notebook_restore = _button(actions,tr2("载入改进","Continue improving"),restore_kept,"RestoreKept")
	notebook_remove = _button(actions,tr2("移除保留","Remove kept plan"),request_remove_kept,"RemoveKept")
	notebook_selected = _label(page,"",13)
	notebook_selected.name = "KeptSelection"
	var keep_row := HBoxContainer.new()
	page.add_child(keep_row)
	notebook_name = LineEdit.new()
	notebook_name.name = "NotebookName"
	notebook_name.max_length = 40
	notebook_name.placeholder_text = tr2("给所选运行起名","Name the selected run")
	notebook_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notebook_name.focus_entered.connect(func() -> void: _last_focus = "NotebookName")
	notebook_name.text_changed.connect(func(_text: String) -> void: _refresh_notebook_actions())
	notebook_name.text_submitted.connect(func(_text: String) -> void: keep_selected())
	keep_row.add_child(notebook_name)
	notebook_keep = _button(keep_row,tr2("保留所选方案","Keep selected plan"),keep_selected,"KeepSelected")
	var footer := HBoxContainer.new()
	page.add_child(footer)
	notebook_note = _label(footer,"",13)
	notebook_note.name = "NotebookStorage"
	notebook_recover = _button(footer,tr2("恢复写入","Recover writer"),recover_writer,"RecoverWriter")
	notebook_recover.tooltip_text = tr2("只恢复已经停止的写入窗口；之后仍需保存。","Recover only a stopped writer; save separately afterward.")

func _cap_toggle(parent: Node, text: String, id: String) -> CheckBox:
	var control := CheckBox.new()
	control.name = id
	control.text = text
	control.tooltip_text = tr2("未勾选表示不限；上限包含相等值。","Unchecked means no cap; equality is allowed.")
	control.focus_entered.connect(func() -> void: _last_focus = id)
	parent.add_child(control)
	return control

func _cap_number(parent: Node, id: String) -> SpinBox:
	var control := SpinBox.new()
	control.name = id
	control.min_value = 0
	control.max_value = Goals.MAX_LIMIT
	control.step = 1
	control.custom_minimum_size = Vector2(118,32)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.get_line_edit().focus_entered.connect(func() -> void: _last_focus = id)
	control.get_line_edit().text_changed.connect(func(_text: String) -> void:
		if not _syncing: _pending_numeric = control)
	parent.add_child(control)
	return control

func _edit_goal(key: String, value: Variant) -> void:
	if _syncing: return
	var next: Dictionary = session.goal()
	next[key] = value
	if session.set_goal(next): refresh()

func field_name(field: int) -> String:
	return [tr2("温度","Temperature"),tr2("编号","ID"),tr2("电量","Battery"),tr2("告警","Alarm")][field] if field >= 0 and field < 4 else "—"

func _job_count(task: Dictionary) -> int:
	var count: int = 0
	for query: Dictionary in task.queries: count += int(query.get("repeat",1))
	return count

func _disable(control: BaseButton, value: bool) -> void:
	control.disabled = value
	control.focus_mode = Control.FOCUS_NONE if value else Control.FOCUS_ALL

func refresh() -> void:
	_syncing = true
	var task: Dictionary = session.task()
	var plan: Dictionary = session.draft()
	var serial: bool = task.release == "serial"
	workload_choice.select(Model.SCENARIO_IDS.find(session.task_id))
	workload_note.text = tr2("%d条记录 · %d份请求 · 复制上限%d B","%d records · %d jobs · copy limit %d B") % [task.records.size(),_job_count(task),int(task.scratch_limit)]
	# Retained unfinished drafts can be invalid for their task. Display the exact
	# input until the player repairs it; a smaller workload must not hide a clamp.
	var invalid_group: bool = int(plan.query_group) != 1 if serial else int(plan.query_group) > _job_count(task)
	query_group.max_value = maxi(_job_count(task),int(plan.query_group))
	query_group.set_value_no_signal(int(plan.query_group))
	query_group.editable = not serial or invalid_group
	query_group.get_line_edit().focus_mode = Control.FOCUS_ALL if query_group.editable else Control.FOCUS_NONE
	if serial:
		group_note.text = tr2("逐次请求要求每组1份；请修正保留草稿。","Serial requests need group size 1; correct the retained draft.") if invalid_group else tr2(
			"前一份响应后，下一份请求才就绪。","Ready after the prior response.")
	else:
		group_note.text = tr2("每组最多%d份；请修正保留草稿。","At most %d jobs per group; correct the retained draft.") % _job_count(task) if invalid_group else tr2(
			"按块交替执行同组已就绪查询。","Run grouped queries tile by tile.")
	record_tile.max_value = maxi(task.records.size(),int(plan.record_tile))
	record_tile.set_value_no_signal(int(plan.record_tile))
	var tiling: bool = not serial and not invalid_group and int(plan.query_group) > 1
	record_tile.editable = tiling
	record_tile.get_line_edit().focus_mode = Control.FOCUS_ALL if tiling else Control.FOCUS_NONE
	tile_note.text = tr2("当前分组无效；查询切块暂不生效。","The group is invalid; query tiling is inactive.") if invalid_group else tr2(
		"单份顺序查询没有切块收益。","No reordering for one query.") if not tiling else tr2("块越小，查询交替越频繁。","Smaller tiles alternate queries sooner.")
	copy_mode.select(0 if plan.copy_mode == "none" else 1)
	var copying: bool = plan.copy_mode == "full"
	for field: int in 4:
		field_buttons[field].set_pressed_no_signal(plan.copy_fields.has(field))
		_disable(field_buttons[field],not copying)
	destination.clear()
	destination.add_item(tr2("副本按记录排列","Copy: record-major"))
	destination.add_item(tr2("副本按字段排列","Copy: field-major"))
	if plan.recipe == Recipe.record_major(): destination.select(0)
	elif plan.recipe == Recipe.field_major(): destination.select(1)
	else:
		destination.add_item(tr2("保留的自定义布局","Retained custom layout"))
		destination.select(2)
	_disable(destination,not copying or plan.copy_fields.size() <= 1)
	copy_note.text = tr2("先复制，再查询；空间仅计副本。","Copy first, then query. Space counts only the copy.") if copying else tr2("源按记录排列；保留暂未生效的复制选择。","Record-major source; copy choices retained.")
	_disable(undo_button,not session.can_undo())
	_disable(redo_button,not session.can_redo())
	_syncing = false
	_refresh_history()
	_refresh_notebook()
	public_detail.text = _public_text(task)

func _edit_value(key: String, value: Variant) -> void:
	if _syncing: return
	var next: Dictionary = session.draft()
	next[key] = value
	_notice = ""
	if not session.edit(next) and next != session.draft():
		_notice = tr2("没有应用无效的编辑。","The invalid edit was not applied.")
	refresh()

func _edit_field(field: int, enabled: bool) -> void:
	if _syncing: return
	var next: Dictionary = session.draft()
	if enabled and not next.copy_fields.has(field): next.copy_fields.append(field)
	if not enabled: next.copy_fields.erase(field)
	if next.copy_fields.is_empty() and next.copy_mode == "full":
		_notice = tr2("复制时至少选择一个字段。","Select at least one field to copy.")
	else:
		_notice = ""
		session.edit(next)
	refresh()

func change_task(id: String) -> void:
	_pending_numeric = null
	if session.change_task(id):
		if is_instance_valid(challenge_window) and challenge_window.visible:
			challenge_window.dismiss()
		_notice = ""
		selected_event = -1
		_shown_entry = -1
		refresh()

func undo() -> void:
	if session.undo():
		_notice = ""
		refresh()

func redo() -> void:
	if session.redo():
		_notice = ""
		refresh()

func run_current() -> void:
	if _modal_blocked() or (is_instance_valid(exit_overlay) and exit_overlay.visible): return
	_commit_numeric_editor()
	var result: Dictionary = session.run_current()
	_notice = "" if result.get("valid",false) else tr2("未运行：","Not run: ")+_error_text(str(result.get("error","")))
	selected_event = -1
	refresh()

func restore_selected() -> void:
	if session.restore_selected():
		_notice = tr2("已恢复；可一次撤销。","Restored; one Undo returns your draft.")
		refresh()

func set_baseline() -> void:
	var selected: Dictionary = session.selected_entry()
	if not selected.is_empty() and session.set_baseline(int(selected.id)): _refresh_history()

func _history_selected() -> void:
	if _syncing: return
	var item: TreeItem = history_table.get_selected()
	if item != null and session.select(int(item.get_metadata(0))):
		selected_event = -1
		# Keep the emitting TreeItem alive until Godot finishes its selection.
		# Inspecting a row changes details/actions, not the history row list.
		_refresh_history(false)
		_refresh_notebook_actions()

func _metric(metrics: Dictionary, key: String) -> String:
	var value: int = int(metrics.get(key,-1))
	return "—" if value < 0 else str(value)

func _refresh_history(rebuild_rows: bool = true) -> void:
	_syncing = true
	history_table.set_column_title(5,tr2("总计名次","Total rank") if session.goal().objective == "cycles" else tr2("RAM名次","RAM rank"))
	var selected: Dictionary = session.selected_entry()
	var selected_id: int = int(selected.get("id",-1))
	if rebuild_rows:
		history_table.clear()
		var tree_root: TreeItem = history_table.create_item()
		for row: Dictionary in session.ranked_rows():
			var item: TreeItem = history_table.create_item(tree_root)
			var metrics: Dictionary = row.metrics
			item.set_metadata(0,int(row.id))
			item.set_text(0,("#%d *" if int(row.id) == session.baseline_id() else "#%d") % int(row.id))
			item.set_text(1,_metric(metrics,"first_request_cycles"))
			item.set_text(2,_metric(metrics,"total_cycles"))
			item.set_text(3,str(int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes)))
			item.set_text(4,str(int(metrics.peak_extra_bytes)))
			item.set_text(5,_rank_text(row))
			for column: int in 6: item.set_tooltip_text(column,_plan_text(row.plan))
			item.set_tooltip_text(5,_goal_text()+"\n"+tr2("名次仅比较本次运行；相同目标值并列。","Ranks compare recent runs only; equal objective values tie."))
			if int(row.id) == selected_id: item.select(0)
	_syncing = false
	_disable(restore_button,selected.is_empty() or selected.get("plan",{}) == session.draft())
	_disable(baseline_button,selected.is_empty() or not selected.get("correct",false) or selected_id == session.baseline_id())
	if selected.is_empty():
		measured_source.text = tr2("尚无实测结果。运行当前草稿开始比较。","No measurements yet. Run the draft to begin comparing.")
		measured_plan.text = ""
	else:
		measured_source.text = tr2("运行 #%d · 历史快照，当前草稿已不同","Run #%d · historical snapshot; draft differs") % selected_id if session.is_stale() else tr2("运行 #%d · 与当前草稿一致","Run #%d · matches the current draft") % selected_id
		measured_plan.text = _plan_text(selected.plan)
	if not _notice.is_empty():
		status.text = _notice
	elif selected.is_empty():
		status.text = tr2("草稿尚未测量。","Draft has not been measured.")
	elif session.is_stale():
		status.text = tr2("草稿与所选运行不同。","Draft differs from the selected run.")
	else:
		status.text = tr2("草稿对应所选实测结果。","Draft matches the selected measurement.")
	_refresh_comparison()
	_refresh_challenge()
	_refresh_explanation()
	if selected_id != _shown_entry:
		_shown_entry = selected_id
		_refresh_events()

func _rank_text(row: Dictionary) -> String:
	if row.get("eligible",false): return "#"+str(row.rank)
	if not row.get("correct",false): return _error_text(str(row.get("metrics",{}).get("error","")))
	var exclusions: Array = row.get("exclusions",[])
	if exclusions.has("first") and exclusions.has("copy"): return tr2("Q1/复制超限","Q1/copy over")
	if exclusions.has("first"): return tr2("Q1超限","Q1 over")
	if exclusions.has("copy"): return tr2("复制超限","Copy over")
	return tr2("不可比较","Unavailable")

func _goal_text() -> String:
	var goal: Dictionary = session.goal()
	var first: String = tr2("Q1不限","Q1: no cap") if int(goal.first_limit) < 0 else "Q1 ≤ "+str(goal.first_limit)+tr2("周期"," cycles")
	var copy: String = tr2("复制不限","Copy: no cap") if int(goal.copy_limit) < 0 else tr2("复制","Copy")+" ≤ "+str(goal.copy_limit)+" B"
	return first+" · "+copy

func _refresh_notebook(rebuild_rows: bool = true) -> void:
	_syncing = true
	var goal: Dictionary = session.goal()
	goal_objective.select(0 if goal.objective == "cycles" else 1)
	first_cap.set_pressed_no_signal(int(goal.first_limit) >= 0)
	copy_cap.set_pressed_no_signal(int(goal.copy_limit) >= 0)
	for pair: Array in [[first_limit,int(goal.first_limit)],[copy_limit,int(goal.copy_limit)]]:
		var control: SpinBox = pair[0]
		var limit: int = pair[1]
		control.set_value_no_signal(limit if limit >= 0 else Goals.MAX_LIMIT)
		control.editable = limit >= 0
		control.get_line_edit().focus_mode = Control.FOCUS_ALL if limit >= 0 else Control.FOCUS_NONE
	goal_summary.text = _goal_text()+" · "+tr2("只比较本条件的保留方案","Only kept plans in this condition")
	_kept_rows = workspace.kept_rows()
	if rebuild_rows:
		notebook_table.clear()
		var tree_root: TreeItem = notebook_table.create_item()
		var selected_name: String = str(_kept_selection.get(session.task_id,""))
		for row: Dictionary in _kept_rows:
			var item: TreeItem = notebook_table.create_item(tree_root)
			item.set_metadata(0,row.name)
			item.set_text(0,row.name)
			item.set_tooltip_text(0,row.name+"\n"+_plan_text(row.plan))
			item.set_text(1,_metric(row.metrics,"first_request_cycles"))
			item.set_text(2,_metric(row.metrics,"total_cycles"))
			item.set_text(3,str(int(row.metrics.ram_read_bytes)+int(row.metrics.ram_write_bytes)))
			item.set_text(4,str(int(row.metrics.peak_extra_bytes)))
			item.set_text(5,_rank_text(row))
			item.set_tooltip_text(5,tr2("本机从配方复测；相同目标值并列。","Locally remeasured from the recipe; equal objective values tie."))
			if row.name == selected_name: item.select(0)
	_syncing = false
	_refresh_notebook_actions()
	_refresh_storage()

func _selected_kept_row() -> Dictionary:
	var name: String = str(_kept_selection.get(session.task_id,""))
	for row: Dictionary in _kept_rows:
		if row.name == name: return row
	return {}

func _refresh_notebook_actions() -> void:
	if not is_instance_valid(notebook_keep): return
	var selected: Dictionary = session.selected_entry()
	var kept: Dictionary = _selected_kept_row()
	_disable(notebook_keep,selected.is_empty() or not selected.get("correct",false) or notebook_name.text.strip_edges().is_empty())
	_disable(notebook_remove,kept.is_empty())
	_disable(notebook_restore,kept.is_empty() or kept.get("plan",{}) == session.draft())
	notebook_selected.text = tr2("先运行方案，再保留所选的实测配方。","Run a plan, then keep its measured recipe.") if selected.is_empty() else tr2(
		"保留运行 #%d 的配方%s","Keep run #%d's recipe%s") % [
			int(selected.id),tr2("；当前草稿不同。","; the draft differs.") if session.is_stale() else tr2("。",".")]
	notebook_selected.tooltip_text = tr2("选择保留方案会重新测量；不会载入草稿。","Selecting a kept plan remeasures it without replacing the draft.")

func _kept_selected() -> void:
	if _syncing: return
	var item: TreeItem = notebook_table.get_selected()
	if item == null: return
	var name: String = str(item.get_metadata(0))
	if workspace.inspect_kept(name):
		_kept_selection[session.task_id] = name
		selected_event = -1
		# Do not delete the TreeItem that is still emitting its selection signal.
		_refresh_history()
		_refresh_notebook(false)

func keep_selected() -> void:
	if notebook_keep.disabled: return
	var name: String = notebook_name.text.strip_edges()
	var selected_plan: Dictionary = session.selected_entry().plan
	var kept: bool = workspace.keep_selected(name)
	var proposed: bool = false
	for row: Dictionary in workspace.kept_rows():
		if row.name == name and row.plan == selected_plan: proposed = true
	if kept or proposed:
		_kept_selection[session.task_id] = name
		notebook_name.clear()
	refresh()

func restore_kept() -> void:
	var row: Dictionary = _selected_kept_row()
	if row.is_empty() or not workspace.inspect_kept(str(row.name)): return
	restore_selected()
	refresh()
	tabs.current_tab = 0
	run_button.grab_focus()

func save_workspace() -> bool:
	var saved: bool = workspace.save()
	_refresh_storage()
	return saved

func recover_writer() -> void:
	workspace.recover_writer()
	_refresh_storage()

func _storage_text() -> String:
	var reason: String = workspace.storage_reason
	if workspace.storage_status == "read_only":
		var protected_text: String = tr2("上一版笔记受保护；没有载入或改写原记录。","The earlier notebook is protected; its records were not loaded or rewritten.") if workspace.origin == "legacy" else tr2(
			"笔记本受保护；当前修改尚未写入。","The notebook is protected; current changes are not saved.")
		if reason == "changed":
			protected_text = tr2("上一版笔记已改变；原记录受保护，当前修改未写入。","The earlier notebook changed; the original is protected and changes are unsaved.") if workspace.origin == "legacy" else tr2(
				"磁盘版本已改变；原文件受保护，当前修改尚未写入。","The disk version changed; it is protected. Current changes are not saved.")
		return protected_text+" "+tr2("当前探索是临时的。","Exploration is temporary.")
	match reason:
		"name": return tr2("名称需为1至40个非控制字符。","Use a name of 1–40 non-control characters.")
		"full": return tr2("本条件已保留8个方案，请先移除一个。","This condition already has 8 kept plans. Remove one first.")
		"duplicate": return tr2("名称已存在，请换一个新名字。","That name is already kept. Choose a new one.")
		"no_selection", "incomplete": return tr2("先选择一次完整正确的运行。","Select a complete, correct run first.")
		"busy": return tr2("写入被其他窗口占用；当前修改仍在内存。","Another window owns writing; changes remain in memory.")
		"changed": return tr2("磁盘版本已改变；原文件受保护，当前修改尚未写入。","The disk version changed; it is protected. Current changes are not saved.")
		"stale", "version": return tr2("笔记本版本或条件不兼容；原文件保留，当前探索是临时的。","The notebook version or conditions are incompatible. The original is kept; exploration is temporary.")
		"format", "size", "read": return tr2("笔记本无法安全读取；原文件保留，当前探索是临时的。","The notebook cannot be read safely. The original is kept; exploration is temporary.")
	if workspace.storage_status == "write_failed":
		return tr2("写入失败；当前修改仍在内存，点「保存工作区」重试。","Writing failed. Changes remain in memory; choose Save workspace to retry.")
	if workspace.copy_pending:
		return tr2("已载入上一版笔记。保存会创建独立副本；原记录保留。","Earlier notebook loaded. Save creates a separate copy; the original remains.")
	if not workspace.has_saved_workspace():
		return tr2("新工作区尚未保存；草稿、个人条件和命名方案需显式保存。","This new workspace has not been saved. Save drafts, personal goals and named plans explicitly.")
	return tr2("草稿、个人条件和方案需显式保存；历史与撤销仅本次。","Save drafts, personal goals and plans explicitly. History and Undo last for this session.") if workspace.is_dirty() else tr2(
		"工作区已保存；运行历史、比较基准与撤销仅本次。","Workspace saved. Run history, comparison and Undo last for this session.")

func _refresh_storage() -> void:
	var storage_protected: bool = workspace.storage_status != "ready"
	var dirty: bool = workspace.is_dirty()
	var state: String = tr2("新工作区","New workspace")
	if storage_protected:
		state = tr2("上一版笔记受保护","Earlier notebook protected") if workspace.origin == "legacy" and workspace.storage_status == "read_only" else tr2("存储受保护","Storage protected")
	elif workspace.copy_pending:
		state = tr2("上一版笔记 · 副本未保存","Earlier notebook · copy unsaved")
	elif dirty:
		state = tr2("未保存修改","Unsaved changes")
	elif workspace.has_saved_workspace():
		state = tr2("工作区已保存","Workspace saved")
	storage_label.text = tr2("独立实验 · %s · 在「方案笔记」显式保存","Independent experiment · %s · Save explicitly in Notebook") % state
	storage_label.add_theme_color_override("font_color",Color("f0c674") if storage_protected or dirty else Color("a5b6be"))
	storage_label.tooltip_text = _storage_text()+"\n"+ProjectSettings.globalize_path(workspace.store.storage_path)
	notebook_note.text = _storage_text()
	notebook_recover.visible = workspace.storage_reason == "busy"
	notebook_recover.focus_mode = Control.FOCUS_ALL if notebook_recover.visible else Control.FOCUS_NONE
	notebook_save.text = tr2("重试保存","Retry save") if workspace.storage_status == "write_failed" else tr2("保存工作区","Save workspace")
	if is_instance_valid(exit_overlay) and exit_overlay.visible: _translate_exit_guard()

func _signed(value: int) -> String:
	return ("+" if value > 0 else "")+str(value)

func _refresh_comparison() -> void:
	var comparison: Dictionary = session.comparison()
	if comparison.is_empty():
		comparison_label.text = tr2("选择一次正确运行作为比较基准。Q1始终指第一份提交的请求。","Choose a correct run as the comparison. Q1 always means the first submitted request.")
		return
	var verdicts: Dictionary = {
		"better":tr2("各项不劣","No metric worse"),"worse":tr2("各项不优","No metric better"),
		"tied":tr2("四项相同","All four equal"),"tradeoff":tr2("存在取舍","Tradeoff"),
	}
	comparison_label.text = tr2("对比 #%d：%s\nQ1 %s周期 · 总计 %s周期 · RAM %s B · 复制 %s B","vs #%d: %s\nQ1 %s cycles · total %s cycles · RAM %s B · copy %s B") % [
		session.baseline_id(),verdicts[comparison.kind],_signed(int(comparison.first)),_signed(int(comparison.cycles)),
		_signed(int(comparison.traffic)),_signed(int(comparison.peak))]
	var selected_id: int = int(session.selected_entry().get("id",-1))
	for row: Dictionary in session.ranked_rows():
		if row.eligible: continue
		if int(row.id) == selected_id:
			comparison_label.text += tr2("\n所选运行不满足当前限制。","\nThe selected run is outside the current goal.")
		elif int(row.id) == session.baseline_id():
			comparison_label.text += tr2("\n比较基准不满足当前限制。","\nThe comparison baseline is outside the current goal.")

func _challenge_storage_text(target: Dictionary) -> String:
	if challenges.storage_status == "read_only":
		var reason: String = tr2("挑战文件无法安全读取；原文件保留。","The target file cannot be read safely; the original is preserved.")
		if challenges.storage_reason == "changed":
			reason = tr2("挑战文件已被外部改变；磁盘内容受保护。","The target file changed externally; the disk contents are protected.")
		elif challenges.storage_reason == "version":
			reason = tr2("挑战文件版本不受支持；原文件受保护。","The target file version is unsupported; the original is protected.")
		if challenges.origin == "legacy":
			reason = tr2("上一版挑战受保护；原记录没有改写。","Earlier targets are protected; the originals were not rewritten.")+"\n"+reason
		if bool(target.get("pending",false)):
			reason += "\n"+(tr2("清除尚未保存，仅在本次会话生效。","Removal is unsaved and applies only to this session.") if str(target.get("code","")).is_empty() else tr2(
				"当前目标仅本次有效，可复制目标代码保留。","The current target is temporary; copy its code to keep it."))
		else:
			reason += "\n"+tr2("当前会话仍可预览；重试不能解除文件保护。","Preview remains available; retry cannot remove file protection.")
		return reason
	if challenges.copy_pending and challenges.storage_status == "ready":
		return tr2("已载入上一版挑战；可用目标已复测。新副本尚未保存，原记录保留。",
			"Earlier targets loaded; valid targets remeasured. The new copy is unsaved; the original remains.")
	if bool(target.get("pending",false)):
		if str(target.get("code","")).is_empty():
			return tr2("清除目标尚未保存；旧目标仍在磁盘。请在挑战窗口重试。",
				"Target removal is not saved; the old target remains on disk. Retry in Challenges.")
		return tr2("此目标暂时有效；保存尚未成功。请在挑战窗口重试。",
			"This target is temporary; saving has not succeeded. Retry in Challenges.")
	if challenges.storage_status == "write_failed":
		return tr2("挑战保存失败；待保存修改仍在内存。","Target saving failed; pending changes remain in memory.")+" ["+challenges.storage_reason+"]"
	if challenges.is_dirty():
		return tr2("其他工作负载的挑战修改尚未保存。","Target changes for another workload are not saved.")
	if bool(target.get("saved",false)):
		return tr2("挑战已独立保存；重新打开时复测。","Target saved separately; remeasured when reopened.")
	return tr2("挑战与方案笔记分别保存。","Targets and Notebook save separately.")

func _challenge_verdict_text(target: Dictionary, selected: Dictionary) -> String:
	if not target.get("active",false): return ""
	var key: String = session.task_id+"|"+str(target.get("code",""))+"|"+str(selected.get("id",-1))+"|"+str(selected.get("trace_id",""))
	if key != _challenge_verdict_key:
		_challenge_verdict_key = key
		_challenge_verdict = challenges.compare(session.task_id,selected)
	var verdict: String = str(_challenge_verdict.get("status","unavailable"))
	var prefix: String = tr2("所选运行：","Selected run: ")
	match verdict:
		"outside":
			var exclusions: Array = _challenge_verdict.get("exclusions",[])
			return prefix+tr2("超出挑战限制","outside challenge limits")+(
				" (Q1 / "+tr2("复制","copy")+")" if exclusions.has("first") and exclusions.has("copy") else
				" (Q1)" if exclusions.has("first") else " ("+tr2("复制","copy")+")" if exclusions.has("copy") else "")
		"tied": return prefix+tr2("持平","tied")
		"improved","behind":
			var objective: String = str(target.inspection.envelope.goal.objective)
			var unit: String = tr2("周期"," cycles") if objective == "cycles" else " B"
			return prefix+(tr2("已改进","improved") if verdict == "improved" else tr2("尚未达到","behind"))+" · "+_signed(int(_challenge_verdict.get("delta",0)))+unit
	return prefix+tr2("运行正确完整的方案后比较","run a complete, correct plan to compare")

func _refresh_challenge() -> void:
	if not is_instance_valid(challenge_summary): return
	var target: Dictionary = challenges.target(session.task_id)
	var selected: Dictionary = session.selected_entry()
	var has_code: bool = not str(target.get("code","")).is_empty()
	var active: bool = bool(target.get("active",false))
	var target_text: String = tr2("尚未接纳挑战；可输入代码并预览。","No accepted challenge. Enter a code to preview.")
	if not ChallengeCode.starter_goal(session.task_id).is_empty():
		target_text = tr2("尚未接纳挑战；可预览代码或试试当前入门挑战。","No accepted challenge. Preview a code or try this workload's starter.")
	if active:
		var retained: String = tr2("挑战已保存 · ","Saved target · ") if target.get("saved",false) else tr2(
			"上一版目标 · 副本未保存 · ","Earlier target · copy unsaved · ") if challenges.copy_pending and challenges.storage_status == "ready" else tr2("临时挑战 · ","Temporary target · ")
		target_text = retained+ChallengeWindow.inspection_text(target.inspection,english)+"\n"+_challenge_verdict_text(target,selected)
	elif has_code:
		target_text = ChallengeWindow.reason_text(str(target.get("inspection",{}).get("reason","stale")),english)
	var storage_text: String = _challenge_storage_text(target)
	challenge_summary.visible = has_code or challenges.is_dirty() or challenges.storage_status != "ready"
	challenge_summary.text = target_text if has_code else storage_text
	challenge_summary.tooltip_text = storage_text
	var selected_text: String = tr2("先运行方案，再分享所选实测结果。","Run a plan before sharing its selected measurement.")
	if not selected.is_empty():
		selected_text = tr2("分享所选运行 #%d%s","Share selected run #%d%s") % [
			int(selected.id),tr2("；草稿另有修改。","; the draft differs.") if session.is_stale() else ""]
		selected_text += "\n"+ChallengeWindow.goal_text(session.goal(),english)
	if is_instance_valid(challenge_window):
		challenge_window.set_context({
			"workload":ChallengeWindow.workload_text(session.task_id,english),
			"starter_task":session.task_id,"copy_pending":challenges.copy_pending,
			"active":active,"has_code":has_code,"pending":bool(target.get("pending",false)),
			"dirty":challenges.is_dirty(),"protected":challenges.storage_status != "ready",
			"retryable":challenges.storage_status != "read_only",
			"busy":challenges.storage_reason == "busy","target_text":target_text,
			"storage_text":storage_text,"selected_text":selected_text,
			"selected_valid":bool(selected.get("correct",false)),
		})

func open_challenges() -> void:
	if _modal_blocked() or (is_instance_valid(exit_overlay) and exit_overlay.visible): return
	_challenge_task = session.task_id
	_challenge_focus = "Challenges"
	if not is_instance_valid(challenge_window):
		challenge_window = ChallengeWindow.new()
		challenge_window.name = "ReplayChallenges"
		challenge_window.english = english
		challenge_window.theme = theme
		add_child(challenge_window)
		challenge_window.share_requested.connect(_share_challenge)
		challenge_window.preview_requested.connect(_preview_challenge)
		challenge_window.accept_requested.connect(_accept_challenge)
		challenge_window.target_code_requested.connect(_show_target_code)
		challenge_window.inspect_requested.connect(_inspect_target)
		challenge_window.restore_requested.connect(_restore_target)
		challenge_window.clear_requested.connect(_clear_target)
		challenge_window.retry_requested.connect(retry_challenge_save)
		challenge_window.recover_requested.connect(_recover_challenge_writer)
		challenge_window.starter_requested.connect(_starter_challenge)
		challenge_window.settings_requested.connect(_challenge_settings)
		challenge_window.dismissed.connect(_challenge_dismissed)
	challenge_window.translate(english)
	_refresh_challenge()
	challenge_window.back()
	challenge_window.popup_centered(Vector2i(820,580))
	challenge_window.call_deferred("restore_focus","ImportChallenge")

func _challenge_context_valid() -> bool:
	return is_instance_valid(challenge_window) and challenge_window.visible and _challenge_task == session.task_id

func _share_challenge(reply: bool) -> void:
	if not _challenge_context_valid(): return
	var selected: Dictionary = session.selected_entry()
	if selected.is_empty() or not selected.get("correct",false): return
	var goal: Dictionary = session.goal()
	if reply:
		var target: Dictionary = challenges.target(_challenge_task)
		if not target.get("active",false): return
		goal = target.inspection.envelope.goal.duplicate(true)
	var result: Dictionary = ChallengeCode.create(_challenge_task,selected.plan,goal)
	challenge_window.show_code(str(result.get("code","")),result)

func _preview_challenge(code: String) -> void:
	if not _challenge_context_valid(): return
	var result: Dictionary = challenges.preview(code,_challenge_task)
	if result.get("reason","") == "task":
		var decoded: Dictionary = ChallengeCode.decode(code)
		if decoded.get("ok",false): result["foreign_task"] = str(decoded.envelope.task)
	challenge_window.show_preview(result)

func _accept_challenge(code: String) -> void:
	if not _challenge_context_valid(): return
	var result: Dictionary = challenges.accept(code,_challenge_task)
	if result.get("accepted",false):
		_challenge_verdict_key = ""
		challenge_window.back()
		_refresh_challenge()
		_refresh_storage()
	else:
		challenge_window.show_message(ChallengeWindow.reason_text(str(result.get("reason","format")),english))

func _show_target_code() -> void:
	if not _challenge_context_valid(): return
	var target: Dictionary = challenges.target(_challenge_task)
	if str(target.get("code","")).is_empty(): return
	challenge_window.show_code(target.code,target.get("inspection",{}))

func _starter_challenge(task_id: String) -> void:
	if not _challenge_context_valid() or task_id != _challenge_task or ChallengeCode.starter_goal(task_id).is_empty(): return
	var result: Dictionary = ChallengeCode.starter(task_id)
	if result.get("ok",false): challenge_window.show_starter(result.code)
	else: challenge_window.show_code("",result)

func _inspect_target() -> void:
	if not _challenge_context_valid(): return
	var target: Dictionary = challenges.target(_challenge_task)
	if not target.get("active",false): return
	session.replay(target.inspection.entry.plan)
	selected_event = -1
	refresh()
	tabs.current_tab = 1
	_challenge_focus = "Events"
	challenge_window.dismiss()

func _restore_target() -> void:
	if not _challenge_context_valid(): return
	var target: Dictionary = challenges.target(_challenge_task)
	if not target.get("active",false): return
	if session.edit(target.inspection.entry.plan):
		_notice = tr2("已恢复目标方案；可一次撤销。","Target recipe restored; one Undo returns your draft.")
	refresh()
	tabs.current_tab = 0
	_challenge_focus = "Run"
	challenge_window.dismiss()

func _clear_target() -> void:
	if not _challenge_context_valid(): return
	challenges.clear(_challenge_task)
	_challenge_verdict_key = ""
	_refresh_challenge()
	_refresh_storage()

func retry_challenge_save() -> void:
	challenges.retry()
	_refresh_challenge()
	_refresh_storage()
	if is_instance_valid(exit_overlay) and exit_overlay.visible and not challenges.is_dirty():
		exit_cancel.grab_focus()

func _recover_challenge_writer() -> void:
	if not _challenge_context_valid(): return
	challenges.recover_writer()
	_refresh_challenge()

func _challenge_dismissed() -> void:
	if _challenge_settings_pending: return
	call_deferred("_restore_focus",_challenge_focus)

func _challenge_settings() -> void:
	if not _challenge_context_valid(): return
	_challenge_settings_focus = challenge_window.focus_id()
	_challenge_settings_pending = true
	challenge_window.hide()
	get_node("/root/WindowMode").open_settings()
	call_deferred("_resume_challenge_settings")

func _resume_challenge_settings() -> void:
	# Locale changes replace the Settings layer. Wait for its replacement before
	# deciding that the user has returned; keep the same code editor and preview.
	await get_tree().process_frame
	await get_tree().process_frame
	if not _challenge_settings_pending or not is_instance_valid(challenge_window): return
	var mode: Node = get_node("/root/WindowMode")
	if is_instance_valid(mode.settings_layer):
		var resume: Callable = _resume_challenge_settings
		if not mode.settings_layer.tree_exited.is_connected(resume):
			mode.settings_layer.tree_exited.connect(resume,CONNECT_ONE_SHOT)
		return
	_challenge_settings_pending = false
	if is_instance_valid(exit_overlay) and exit_overlay.visible: return
	challenge_window.popup_centered(challenge_window.size)
	challenge_window.call_deferred("restore_focus",_challenge_settings_focus)

func _plan_text(plan: Dictionary) -> String:
	var copy_text: String = tr2("不复制","no copy")
	if plan.copy_mode == "full":
		var fields: PackedStringArray = []
		for field: int in plan.copy_fields: fields.append(field_name(field))
		var layout: String = tr2("字段排列","field-major") if plan.recipe == Recipe.field_major() else tr2("记录排列","record-major") if plan.recipe == Recipe.record_major() else tr2("自定义布局","custom layout")
		copy_text = tr2("复制 %s · %s","copy %s · %s") % ["/".join(fields),layout]
	return tr2("每组%d份查询 · 每块%d条记录\n%s","%d queries/group · %d records/tile\n%s") % [int(plan.query_group),int(plan.record_tile),copy_text]

func _error_text(error: String) -> String:
	match error:
		"space_limit": return tr2("空间不足","No space")
		"serial_group": return tr2("逐次请求只能每组1份","Serial requests require group size 1")
		"query_group": return tr2("查询组大小无效","Invalid query group")
		"record_tile": return tr2("记录块大小无效","Invalid record tile")
		"copy_fields": return tr2("复制字段无效","Invalid copy fields")
		"": return tr2("结果不符","Output mismatch")
	return tr2("无效：","Invalid: ")+error

func _event_name(kind: String) -> String:
	var names: Dictionary = {
		"request_admitted":tr2("请求就绪","Admitted"),"response":tr2("响应","Response"),
		"lookup":tr2("查找","Lookup"),"fill":tr2("装入","Fill"),"read":tr2("读取","Read"),
		"write":tr2("写入","Write"),"evict":tr2("淘汰","Evict"),"compute":tr2("计算","Compute"),
		"output":tr2("输出","Output"),"allocate":tr2("分配","Allocate"),"release":tr2("释放","Release"),
		"error":tr2("错误","Error"),
	}
	return str(names.get(kind,kind))

func _refresh_events() -> void:
	var entry: Dictionary = _event_entry()
	event_table.clear()
	var tree_root: TreeItem = event_table.create_item()
	if entry.is_empty():
		event_source.text = tr2("运行后可检查每份请求和实际搬运。","Run a plan to inspect its requests and actual transfers.")
		event_detail.text = ""
		return
	var paired: bool = _explaining and _inspecting_comparison
	if paired:
		event_side_choice.clear()
		event_side_choice.add_item(tr2("所选 #%d","Selected #%d") % int(_explanation.selected.id))
		event_side_choice.add_item(tr2("基准 #%d","Baseline #%d") % int(_explanation.baseline.id))
		event_side_choice.select(0 if _event_side == "selected" else 1)
		event_scope.text = _explanation_scope_name()+tr2(" · 此范围的原始事件，RAM B仅计装入与写入。",
			" · original events in this scope; RAM B counts only fills and writes.")
		event_source.text = (tr2("所选运行 #%d","Selected run #%d") if _event_side == "selected" else tr2(
			"基准运行 #%d","Baseline run #%d")) % int(entry.id)
	else:
		event_source.text = tr2("运行 #%d · 原始事件；读取所选快照","Run #%d · actual events from the selected snapshot") % int(entry.id)
	var indices: Array = _explanation_indices() if paired else range(entry.events.size())
	var first: TreeItem
	for index: int in indices:
		var event: Dictionary = entry.events[index]
		var kind: String = str(event.kind)
		if event_filter.selected == 0 and kind not in ["request_admitted","response","error"]: continue
		if event_filter.selected == 1 and kind not in ["fill","write","evict","allocate","release","error"]: continue
		var item: TreeItem = event_table.create_item(tree_root)
		if first == null: first = item
		item.set_metadata(0,index)
		item.set_text(0,str(event.cycle))
		item.set_text(1,_event_name(kind))
		item.set_text(2,"Q"+str(int(event.details.job_id)+1) if event.details.has("job_id") else "—")
		item.set_text(3,str(event.address) if int(event.address) >= 0 else "—")
		item.set_text(4,str(int(event.details.get("bytes",0))) if kind in ["fill","write"] else "0")
		if index == selected_event: item.select(0)
	if event_table.get_selected() == null and first != null: first.select(0)
	_event_selected()

func _event_selected() -> void:
	var item: TreeItem = event_table.get_selected()
	var entry: Dictionary = _event_entry()
	if item == null or entry.is_empty():
		event_detail.text = tr2("此筛选下没有事件。","No events in this filter.")
		return
	selected_event = int(item.get_metadata(0))
	var event: Dictionary = entry.events[selected_event]
	var details: Dictionary = event.details
	var job: String = "Q"+str(int(details.job_id)+1) if details.has("job_id") else tr2("准备/整理","Preparation")
	var lines: PackedStringArray = [
		tr2("事件%d · %s · %s","Event %d · %s · %s") % [selected_event+1,_event_name(str(event.kind)),job],
		tr2("周期 %d → %d · %s → %s","Cycle %d → %d · %s → %s") % [int(event.cycle),int(event.cycle)+int(event.duration),event.source,event.target],
		tr2("地址 %s · 数值 %s · 事件字节 %s","Address %s · value %s · event bytes %s") % [str(event.address),str(event.value),str(details.get("bytes",0))],
	]
	if str(event.kind) == "response":
		var first_output: int = int(details.get("output_first",0))
		var output_count: int = int(details.get("output_count",0))
		lines.append(tr2("实际响应：","Actual response: ")+str(entry.outputs.slice(first_output,first_output+output_count)))
	if str(event.kind) == "error":
		lines.append(_error_text(str(entry.metrics.get("error",""))))
		if entry.metrics.has("required_extra_bytes"):
			lines.append(tr2("所需复制空间：%d B；上限：%d B","Required copy space: %d B; limit: %d B") % [int(entry.metrics.required_extra_bytes),int(session.task().scratch_limit)])
	lines.append(JSON.stringify(details,"  ",true))
	event_detail.text = "\n".join(lines)

func _public_text(task: Dictionary) -> String:
	var lines: PackedStringArray = [
		tr2("公开请求顺序","Public request order"),
		tr2("Q1是第一份提交的请求，不是任意最早完成的请求。","Q1 is the first submitted request, not whichever response finishes first."),
		tr2("全部请求在周期0就绪。","All requests are ready at cycle 0.") if task.release == "batch" else tr2("Q1在周期0就绪；之后每份请求必须等待前一份响应。","Q1 is ready at cycle 0; each later request waits for the preceding response."),
		tr2("源数据不可变，可预先复制；尚未就绪的查询不可执行。","Immutable source data may be copied ahead; a query cannot execute before admission."),
		"",
	]
	var job: int = 1
	for query: Dictionary in task.queries:
		var fields: PackedStringArray = []
		for field: int in query.fields: fields.append(field_name(field))
		var indices: Array = query.get("indices",[])
		var domain: String = tr2("全部记录","all records") if indices.is_empty() else tr2("记录","records ")+str(indices)
		for repetition: int in int(query.get("repeat",1)):
			lines.append("Q%d · %s · %s · %s" % [job,tr2("求和","sum") if query.kind == "sum" else tr2("逐值返回","return values"),"/".join(fields),domain])
			job += 1
	lines.append("")
	lines.append(tr2("内存与成本","Memory and costs"))
	lines.append(tr2("源按记录排列；缓存%d行，每行%d B，LRU。每字%d B。","Record-major source; %d cache lines of %d B, LRU. %d B per word.") % [Simulator.CACHE_LINES,Recipe.LINE_BYTES,Recipe.WORD_BYTES])
	lines.append(tr2("读查找%d周期；缺失装入%d周期/%d B；写入%d周期/%d B。","Read lookup %d cycles; missing fill %d cycles/%d B; write %d cycles/%d B.") % [Simulator.READ_LOOKUP,Simulator.FILL_CYCLES,Recipe.LINE_BYTES,Simulator.WRITE_CYCLES,Recipe.WORD_BYTES])
	lines.append(tr2("每个查询值计算1周期；每个输出值输出1周期。响应在该请求最后一个输出完成时产生。","Each queried value costs 1 compute cycle; each emitted value costs 1 output cycle. A response follows that job's last completed output."))
	lines.append(tr2("复制空间上限%d B；不是整个程序的总内存，未计累加器和输出槽。","Copy space limit %d B; this is not total program memory. Accumulators and output slots are not counted.") % int(task.scratch_limit))
	lines.append("")
	lines.append(tr2("源记录 · 下标从0开始","Source records · indices start at 0"))
	lines.append(tr2("下标 | 温度 | 编号 | 电量 | 告警","Index | Temperature | ID | Battery | Alarm"))
	for index: int in task.records.size():
		lines.append("%d | %s" % [index,str(task.records[index])])
	lines.append("")
	lines.append(Model.MODEL_VERSION)
	lines.append(tr2("条件指纹：","Condition: ")+Model.condition_id(task))
	return "\n".join(lines)

func toggle_language() -> void:
	get_node("/root/Localization").set_locale("zh_CN" if english else "en")
	reload_localized_scene()

func reload_localized_scene() -> Error:
	var numeric_state: Dictionary = _capture_pending_numeric()
	var focus_id: String = _last_focus
	# Rebuilding must not turn unsubmitted text into an edit on focus loss.
	_preserve_numeric_for_inspection()
	english = get_node("/root/Localization").current_locale() == "en"
	_notice = ""
	_build()
	_restore_pending_numeric(numeric_state)
	if is_instance_valid(challenge_window): challenge_window.translate(english)
	_translate_exit_guard()
	call_deferred("_restore_focus",focus_id)
	call_deferred("_restore_pending_numeric_after_layout",numeric_state,_pending_numeric)
	return OK

func _restore_focus(id: String) -> void:
	var target: Control
	if is_instance_valid(exit_overlay) and exit_overlay.visible:
		target = exit_layer.find_child(id,true,false) as Control
		if target not in [exit_cancel,exit_save,exit_confirm,exit_target_retry]: target = exit_cancel
	else:
		target = interface.find_child(id,true,false) as Control
	if target is SpinBox: target = target.get_line_edit()
	if target == null or not target.is_visible_in_tree() or target.focus_mode == Control.FOCUS_NONE:
		target = run_button
	if not is_instance_valid(get_node("/root/WindowMode").settings_layer) and not _feedback_visible():
		if is_instance_valid(challenge_window) and challenge_window.visible: return
		target.grab_focus()

func _feedback_visible() -> bool:
	var moments: Node = get_node("/root/PlaytestMoments")
	var offline: Node = get_node("/root/OfflineFeedback")
	return moments.panel.visible or offline.backdrop.visible or bool(offline.busy)

func _modal_blocked() -> bool:
	if _challenge_settings_pending: return true
	if is_instance_valid(get_node("/root/WindowMode").settings_layer) or _feedback_visible(): return true
	var modal: Window = get_window().get_last_exclusive_window()
	return modal != null and modal != get_window() and modal.visible

func _numeric_editor(focused: Control) -> SpinBox:
	for control: SpinBox in [query_group,record_tile,first_limit,copy_limit]:
		if is_instance_valid(control) and control.editable and focused == control.get_line_edit():
			return control
	return null

func _capture_pending_numeric() -> Dictionary:
	var control: SpinBox = _numeric_editor(get_viewport().gui_get_focus_owner())
	if control == null and is_instance_valid(_pending_numeric) and _pending_numeric.editable:
		control = _pending_numeric
	if control == null: return {}
	var editor: LineEdit = control.get_line_edit()
	return {"id":str(control.name),"text":editor.text,"caret":editor.caret_column,
		"selection_start":editor.get_selection_from_column() if editor.has_selection() else -1,
		"selection_end":editor.get_selection_to_column() if editor.has_selection() else -1}

func _restore_pending_numeric(saved: Dictionary) -> void:
	if saved.is_empty(): return
	var control := interface.find_child(str(saved.id),true,false) as SpinBox
	if control == null or not control.editable: return
	control.get_line_edit().text = str(saved.text)
	_pending_numeric = control
	_restore_pending_numeric_selection(saved)

func _restore_pending_numeric_after_layout(saved: Dictionary, control: SpinBox) -> void:
	# Visible SpinBoxes format their committed value during deferred layout.
	# Restore the pending text afterward, only onto this rebuild's live control.
	if saved.is_empty() or not is_instance_valid(control) or _pending_numeric != control: return
	if not is_instance_valid(interface) or not interface.is_ancestor_of(control): return
	control.get_line_edit().text = str(saved.text)
	_restore_pending_numeric_selection(saved)

func _restore_pending_numeric_selection(saved: Dictionary) -> void:
	if saved.is_empty() or not is_instance_valid(_pending_numeric): return
	if str(_pending_numeric.name) != str(saved.id): return
	var editor: LineEdit = _pending_numeric.get_line_edit()
	editor.caret_column = int(saved.caret)
	if int(saved.selection_start) >= 0:
		editor.select(int(saved.selection_start),int(saved.selection_end))
	else: editor.deselect()

func _preserve_numeric_for_inspection() -> void:
	var control: SpinBox = _numeric_editor(get_viewport().gui_get_focus_owner())
	if control == null: return
	var saved: Dictionary = _capture_pending_numeric()
	var typed: String = control.get_line_edit().text
	var committed: float = control.value
	var pending: SpinBox = _pending_numeric
	var was_syncing: bool = _syncing
	# SpinBox applies text on focus loss. Inspection must preserve the draft and
	# the pending text, while an explicit later Run still applies it once.
	_syncing = true
	control.get_line_edit().text = str(committed)
	control.get_line_edit().release_focus()
	control.set_value_no_signal(committed)
	# Restore after SpinBox has processed its deferred focus-loss application.
	control.get_line_edit().set_deferred("text",typed)
	_syncing = was_syncing
	_pending_numeric = pending
	call_deferred("_restore_pending_numeric_selection",saved)

func _inspection_hit(position: Vector2) -> bool:
	for control: Control in [language_button,explanation_button,history_table,evidence_page,public_detail]:
		if is_instance_valid(control) and control.is_visible_in_tree() and control.get_global_rect().has_point(position):
			return true
	var bar: TabBar = tabs.get_tab_bar()
	var local_position: Vector2 = bar.get_global_transform().affine_inverse()*position
	return bar.get_tab_rect(1).has_point(local_position) or bar.get_tab_rect(2).has_point(local_position)

func _commit_numeric_editor() -> void:
	var control: SpinBox = _numeric_editor(get_viewport().gui_get_focus_owner())
	if control == null and is_instance_valid(_pending_numeric) and _pending_numeric.editable:
		control = _pending_numeric
	_pending_numeric = null
	if control != null: control.apply()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _modal_blocked() and not (is_instance_valid(exit_overlay) and exit_overlay.visible) and _inspection_hit(event.position):
			_preserve_numeric_for_inspection()
	if not event is InputEventKey or not event.pressed or event.echo or _modal_blocked(): return
	if is_instance_valid(exit_overlay) and exit_overlay.visible: return
	if not event.is_command_or_control_pressed() or event.keycode not in [KEY_ENTER,KEY_KP_ENTER]: return
	if _numeric_editor(get_viewport().gui_get_focus_owner()) == null: return
	# Only these four SpinBox editors opt into commit-and-run. Other text fields
	# retain Enter and text Undo; handled input cannot also trigger a second run.
	get_viewport().set_input_as_handled()
	run_current()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _modal_blocked(): return
	if is_instance_valid(exit_overlay) and exit_overlay.visible:
		if event.keycode == KEY_ESCAPE:
			cancel_quit()
			get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		request_quit()
		get_viewport().set_input_as_handled()
		return
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit: return
	if event.is_command_or_control_pressed() and event.keycode == KEY_Z:
		if event.shift_pressed: redo()
		else: undo()
		get_viewport().set_input_as_handled()
	elif event.ctrl_pressed and event.keycode == KEY_Y:
		redo()
		get_viewport().set_input_as_handled()
	elif event.is_command_or_control_pressed() and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:
		run_current()
		get_viewport().set_input_as_handled()

func _build_exit_guard() -> void:
	exit_layer = CanvasLayer.new()
	exit_layer.layer = 90
	add_child(exit_layer)
	exit_overlay = ColorRect.new()
	exit_overlay.name = "ExitGuard"
	exit_overlay.color = Color(0.02,0.04,0.06,0.88)
	exit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_layer.add_child(exit_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	exit_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 480
	panel.add_theme_stylebox_override("panel",InstrumentTheme.panel(InstrumentTheme.SURFACE))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	exit_question = _label(column,"",17)
	exit_question.custom_minimum_size = Vector2(450,60)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	exit_cancel = _button(actions,"",cancel_quit,"KeepExploring")
	exit_save = _button(actions,"",save_and_exit,"SaveAndExit")
	exit_confirm = _button(actions,"",_confirm_quit,"DiscardAndExit")
	exit_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_target_retry = _button(column,"",retry_challenge_save,"ExitRetryTarget")
	_translate_exit_guard()
	exit_overlay.hide()

func _translate_exit_guard() -> void:
	if not is_instance_valid(exit_question): return
	var dirty: bool = workspace.is_dirty()
	var saved: bool = workspace.has_saved_workspace()
	var target_dirty: bool = challenges.is_dirty()
	exit_save.visible = _guard_action == "exit" and (dirty or not saved)
	exit_save.focus_mode = Control.FOCUS_ALL if exit_save.visible else Control.FOCUS_NONE
	exit_save.text = tr2("保存笔记","Save notebook") if target_dirty else tr2("保存并退出","Save and exit")
	exit_target_retry.visible = _guard_action == "exit" and target_dirty and challenges.storage_status != "read_only"
	exit_target_retry.focus_mode = Control.FOCUS_ALL if exit_target_retry.visible else Control.FOCUS_NONE
	exit_target_retry.text = tr2("保存挑战副本","Save target copy") if challenges.copy_pending and challenges.storage_status == "ready" else tr2("重试挑战保存","Retry target save")
	if _guard_action == "remove":
		exit_question.text = tr2("移除保留方案「%s」？\n当前草稿和本次运行仍会保留；此操作会保存工作区。","Remove kept plan “%s”?\nThe current draft and recent runs stay. This action saves the workspace.") % _pending_remove
		exit_cancel.text = tr2("取消","Cancel")
		exit_confirm.text = tr2("移除并保存","Remove and save")
	else:
		if workspace.copy_pending and workspace.storage_status == "ready":
			exit_question.text = tr2("上一版笔记已载入，新副本尚未保存。退出会丢弃本次修改，原记录仍保留。","Earlier notebook loaded; the new copy is unsaved. Leaving discards session changes; the original remains.")
		elif dirty:
			exit_question.text = tr2("工作区有未保存修改。退出会丢弃这些修改，以及本次运行历史、比较基准与撤销。","The workspace has unsaved changes. Leaving discards them, along with recent runs, the comparison and Undo.")
		elif saved:
			exit_question.text = tr2("已保存的草稿、个人条件和方案会保留。退出只结束本次运行历史、比较基准与撤销。","Saved drafts, personal goals and kept plans remain. Leaving ends this session's run history, comparison and Undo.")
		else:
			exit_question.text = tr2("此工作区尚未保存。退出会结束本次运行历史、比较基准与撤销。","This workspace has not been saved. Leaving ends this session's run history, comparison and Undo.")
		if workspace.storage_status != "ready": exit_question.text += "\n"+_storage_text()
		if target_dirty:
			exit_question.text += "\n"+(tr2("挑战副本尚未保存。保存笔记不会保存挑战；原挑战记录仍保留。",
				"The target copy is unsaved. Saving Notebook does not save targets; the original targets remain.") if challenges.copy_pending and challenges.storage_status == "ready" else tr2(
				"挑战修改尚未保存。保存笔记不会保存挑战；退出会丢弃待保存的挑战修改。",
				"Target changes are not saved. Saving Notebook does not save targets; leaving discards those pending changes."))
			if challenges.storage_status == "read_only":
				exit_question.text += "\n"+_challenge_storage_text(challenges.target(session.task_id))
		exit_cancel.text = tr2("继续探索","Keep exploring")
		exit_confirm.text = tr2("丢弃并退出","Discard and exit") if dirty or target_dirty else tr2("退出","Exit")
	var controls: Array[Control] = [exit_cancel]
	if exit_save.visible: controls.append(exit_save)
	controls.append(exit_confirm)
	if exit_target_retry.visible: controls.append(exit_target_retry)
	for index: int in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index+controls.size()-1)%controls.size()])

func request_quit() -> void:
	if not _owns_quit: return
	# SpinBox text can still be pending in an otherwise pristine workspace.
	# Submit it before deciding whether there is work to guard or save.
	_commit_numeric_editor()
	if not session.has_work() and not workspace.is_dirty() and not challenges.is_dirty():
		_finish_quit()
		return
	if exit_overlay.visible: return
	_guard_action = "exit"
	_show_guard()

func request_remove_kept() -> void:
	var row: Dictionary = _selected_kept_row()
	if row.is_empty() or exit_overlay.visible: return
	_guard_action = "remove"
	_pending_remove = str(row.name)
	_show_guard()

func _show_guard() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	_exit_focus = weakref(focused) if focused != null else null
	_exit_focus_id = _last_focus
	_translate_exit_guard()
	exit_overlay.show()
	exit_cancel.grab_focus()

func cancel_quit() -> void:
	exit_overlay.hide()
	var target: Control = _exit_focus.get_ref() as Control if _exit_focus != null else null
	if target != null and target.is_visible_in_tree(): target.grab_focus()
	else: _restore_focus(_exit_focus_id)
	_exit_focus = null
	_exit_focus_id = "Run"
	_guard_action = "exit"
	_pending_remove = ""

func _confirm_quit() -> void:
	if _guard_action == "remove":
		workspace.remove_kept(_pending_remove)
		_kept_selection.erase(session.task_id)
		exit_overlay.hide()
		_guard_action = "exit"
		_pending_remove = ""
		_exit_focus = null
		_exit_focus_id = "Run"
		refresh()
		notebook_name.grab_focus()
		return
	_finish_quit()

func save_and_exit() -> void:
	if workspace.save():
		if challenges.is_dirty():
			_refresh_storage()
			if exit_target_retry.visible: exit_target_retry.grab_focus()
			else: exit_cancel.grab_focus()
		else:
			_finish_quit()
	else:
		_refresh_storage()
		exit_save.grab_focus()

func _finish_quit() -> void:
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _owns_quit: request_quit()

func _exit_tree() -> void:
	if _owns_quit:
		get_tree().auto_accept_quit = _previous_auto_quit
		get_window().min_size = _previous_minimum
