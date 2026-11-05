extends Control
## Standalone presenter. The session owns drafts/history; the model owns results.
const Session = preload("res://experiments/layout_strategy/session.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
var session = Session.new()
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
var event_filter: OptionButton
var event_table: Tree
var event_source: Label
var event_detail: RichTextLabel
var public_detail: RichTextLabel
var exit_layer: CanvasLayer
var exit_overlay: ColorRect
var exit_question: Label
var exit_cancel: Button
var exit_confirm: Button

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
	var previous_tab: int = tabs.current_tab if is_instance_valid(tabs) else 0
	var previous_filter: int = event_filter.selected if is_instance_valid(event_filter) else 0
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
	var scope: Label = _label(page,tr2("独立实验 · 草稿与比较仅保留在本次窗口中", "Independent experiment · Drafts and comparisons last for this window only"),13)
	scope.add_theme_color_override("font_color",Color("a5b6be"))
	var workload_row := HBoxContainer.new()
	page.add_child(workload_row)
	workload_choice = _choice(workload_row,[
		tr2("温度扫描 · 全部就绪","Temperature scans · all ready"),
		tr2("温度扫描 · 逐次请求","Temperature scans · serial"),
		tr2("混合查询 · 全部就绪","Mixed queries · all ready"),
		tr2("混合查询 · 逐次请求","Mixed queries · serial")],"Workload")
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
	tabs = TabContainer.new()
	tabs.name = "Results"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	var comparison_page := VBoxContainer.new()
	comparison_page.name = tr2("比较","Compare")
	comparison_page.add_theme_constant_override("separation",6)
	tabs.add_child(comparison_page)
	measured_source = _label(comparison_page,"",14)
	measured_source.name = "MeasuredSource"
	history_table = _table(comparison_page,[
		tr2("运行","Run"),tr2("Q1周期","Q1 cycles"),tr2("总周期","Total"),
		"RAM B",tr2("复制 B","Copy B"),tr2("结果","Result")],"History")
	history_table.item_selected.connect(_history_selected)
	measured_plan = _label(comparison_page,"",13)
	measured_plan.name = "MeasuredPlan"
	measured_plan.custom_minimum_size.y = 36
	var actions := HBoxContainer.new()
	comparison_page.add_child(actions)
	restore_button = _button(actions,tr2("恢复此方案","Restore plan"),restore_selected,"Restore")
	baseline_button = _button(actions,tr2("设为比较基准","Set comparison"),set_baseline,"SetBaseline")
	comparison_label = _label(comparison_page,"",14)
	comparison_label.name = "Comparison"
	comparison_label.custom_minimum_size.y = 42
	var evidence_page := VBoxContainer.new()
	evidence_page.name = tr2("运行证据","Evidence")
	evidence_page.add_theme_constant_override("separation",6)
	tabs.add_child(evidence_page)
	event_source = _label(evidence_page,"",14)
	event_filter = _choice(evidence_page,[
		tr2("请求与响应","Requests & responses"),
		tr2("内存搬运","Memory transfers"),
		tr2("全部事件","All events")],"EventFilter")
	event_filter.select(previous_filter)
	event_filter.item_selected.connect(func(_index: int) -> void: _refresh_events())
	event_table = _table(evidence_page,[tr2("周期","Cycle"),tr2("事件","Event"),tr2("请求","Job"),tr2("地址","Addr"),"B"],"Events")
	event_table.set_column_expand_ratio(1,2)
	event_table.item_selected.connect(_event_selected)
	event_detail = _reader(evidence_page,"EventDetail",128)
	event_detail.size_flags_vertical = Control.SIZE_FILL
	var public_page := VBoxContainer.new()
	public_page.name = tr2("公开工作负载","Public workload")
	tabs.add_child(public_page)
	public_detail = _reader(public_page,"PublicData")
	tabs.current_tab = previous_tab
	_shown_entry = -1
	refresh()

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
	query_group.max_value = _job_count(task)
	query_group.set_value_no_signal(int(plan.query_group))
	query_group.editable = not serial
	query_group.get_line_edit().focus_mode = Control.FOCUS_NONE if serial else Control.FOCUS_ALL
	group_note.text = tr2("前一份响应后，下一份请求才就绪。","Ready after the prior response.") if serial else tr2("按块交替执行同组已就绪查询。","Run grouped queries tile by tile.")
	record_tile.max_value = maxi(task.records.size(),int(plan.record_tile))
	record_tile.set_value_no_signal(int(plan.record_tile))
	var tiling: bool = int(plan.query_group) > 1
	record_tile.editable = tiling
	record_tile.get_line_edit().focus_mode = Control.FOCUS_ALL if tiling else Control.FOCUS_NONE
	tile_note.text = tr2("单份顺序查询没有切块收益。","No reordering for one query.") if not tiling else tr2("块越小，查询交替越频繁。","Smaller tiles alternate queries sooner.")
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
	if session.change_task(id):
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

func _metric(metrics: Dictionary, key: String) -> String:
	var value: int = int(metrics.get(key,-1))
	return "—" if value < 0 else str(value)

func _refresh_history(rebuild_rows: bool = true) -> void:
	_syncing = true
	var selected: Dictionary = session.selected_entry()
	var selected_id: int = int(selected.get("id",-1))
	if rebuild_rows:
		history_table.clear()
		var tree_root: TreeItem = history_table.create_item()
		for row: Dictionary in session.rows():
			var item: TreeItem = history_table.create_item(tree_root)
			var metrics: Dictionary = row.metrics
			item.set_metadata(0,int(row.id))
			item.set_text(0,("#%d *" if int(row.id) == session.baseline_id() else "#%d") % int(row.id))
			item.set_text(1,_metric(metrics,"first_request_cycles"))
			item.set_text(2,_metric(metrics,"total_cycles"))
			item.set_text(3,str(int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes)))
			item.set_text(4,str(int(metrics.peak_extra_bytes)))
			item.set_text(5,tr2("正确","Correct") if row.correct else _error_text(str(metrics.get("error",""))))
			for column: int in 6: item.set_tooltip_text(column,_plan_text(row.plan))
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
	status.text = _notice if not _notice.is_empty() else tr2("草稿尚未测量。","Draft has not been measured.") if session.is_stale() else tr2("草稿对应所选实测结果。","Draft matches the selected measurement.")
	_refresh_comparison()
	if selected_id != _shown_entry:
		_shown_entry = selected_id
		_refresh_events()

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
	var entry: Dictionary = session.selected_entry()
	event_table.clear()
	var tree_root: TreeItem = event_table.create_item()
	if entry.is_empty():
		event_source.text = tr2("运行后可检查每份请求和实际搬运。","Run a plan to inspect its requests and actual transfers.")
		event_detail.text = ""
		return
	event_source.text = tr2("运行 #%d · 原始事件；读取所选快照","Run #%d · actual events from the selected snapshot") % int(entry.id)
	var first: TreeItem
	for index: int in entry.events.size():
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
		item.set_text(4,str(int(event.details.get("bytes",0))))
		if index == selected_event: item.select(0)
	if event_table.get_selected() == null and first != null: first.select(0)
	_event_selected()

func _event_selected() -> void:
	var item: TreeItem = event_table.get_selected()
	var entry: Dictionary = session.selected_entry()
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
		tr2("地址 %s · 数值 %s · 字节 %s","Address %s · value %s · bytes %s") % [str(event.address),str(event.value),str(details.get("bytes",0))],
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
	var focus_id: String = _last_focus
	english = get_node("/root/Localization").current_locale() == "en"
	_notice = ""
	_build()
	_translate_exit_guard()
	call_deferred("_restore_focus",focus_id)
	return OK

func _restore_focus(id: String) -> void:
	var target: Control
	if is_instance_valid(exit_overlay) and exit_overlay.visible:
		target = exit_layer.find_child(id,true,false) as Control
		if target not in [exit_cancel,exit_confirm]: target = exit_cancel
	else:
		target = interface.find_child(id,true,false) as Control
	if target is SpinBox: target = target.get_line_edit()
	if target == null or not target.is_visible_in_tree() or target.focus_mode == Control.FOCUS_NONE:
		target = run_button
	if not is_instance_valid(get_node("/root/WindowMode").settings_layer) and not _feedback_visible():
		target.grab_focus()

func _feedback_visible() -> bool:
	var moments: Node = get_node("/root/PlaytestMoments")
	var offline: Node = get_node("/root/OfflineFeedback")
	return moments.panel.visible or offline.backdrop.visible or bool(offline.busy)

func _modal_blocked() -> bool:
	if is_instance_valid(get_node("/root/WindowMode").settings_layer) or _feedback_visible(): return true
	var modal: Window = get_window().get_last_exclusive_window()
	return modal != null and modal != get_window() and modal.visible

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
	elif event.is_command_or_control_pressed() and event.keycode == KEY_ENTER:
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
	exit_confirm = _button(actions,"",_confirm_quit,"DiscardAndExit")
	exit_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_cancel.focus_next = exit_cancel.get_path_to(exit_confirm)
	exit_cancel.focus_previous = exit_cancel.get_path_to(exit_confirm)
	exit_confirm.focus_next = exit_confirm.get_path_to(exit_cancel)
	exit_confirm.focus_previous = exit_confirm.get_path_to(exit_cancel)
	_translate_exit_guard()
	exit_overlay.hide()

func _translate_exit_guard() -> void:
	if not is_instance_valid(exit_question): return
	exit_question.text = tr2("退出后，本窗口的草稿和实测历史会丢失。","Leaving discards this window's drafts and measured history.")
	exit_cancel.text = tr2("继续探索","Keep exploring")
	exit_confirm.text = tr2("丢弃并退出","Discard and exit")

func request_quit() -> void:
	if not _owns_quit: return
	if not session.has_work():
		get_tree().quit()
		return
	if exit_overlay.visible: return
	var focused: Control = get_viewport().gui_get_focus_owner()
	_exit_focus = weakref(focused) if focused != null else null
	_exit_focus_id = _last_focus
	exit_overlay.show()
	exit_cancel.grab_focus()

func cancel_quit() -> void:
	exit_overlay.hide()
	var target: Control = _exit_focus.get_ref() as Control if _exit_focus != null else null
	if target != null and target.is_visible_in_tree(): target.grab_focus()
	else: _restore_focus(_exit_focus_id)
	_exit_focus = null
	_exit_focus_id = "Run"

func _confirm_quit() -> void:
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _owns_quit: request_quit()

func _exit_tree() -> void:
	if _owns_quit:
		get_tree().auto_accept_quit = _previous_auto_quit
		get_window().min_size = _previous_minimum
