extends Window
## Recomputed personal comparisons; this window never awards progression.
signal restore_requested(design: Dictionary)
signal challenge_requested(row: Dictionary, objective: String)
signal save_requested(title: String)
signal share_requested(row: Dictionary, objective: String)
signal import_requested(code: String)
signal import_target_requested(code: String)
signal clear_challenge_requested
signal share_target_requested
signal dismissed

const InstrumentStyle = preload("res://src/ui/instrument_theme.gd")
const Palette = preload("res://src/lab/lab_palette.gd")
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
var level_id: String = ""
var candidates: Array[Dictionary] = []
var rows: Array[Dictionary] = []
var objective: String = "cycles"
var table: Tree
var order: OptionButton
var restore_button: Button
var challenge_button: Button
var name_edit: LineEdit
var note: Label
var detail: Label
var close_button: Button
var selected_id: String = "current"
var share_button: Button
var import_button: Button
var target_code_button: Button
var clear_target_button: Button
var code_edit: TextEdit
var code_check_button: Button
var code_pin_button: Button
var code_back_button: Button
var code_copy_button: Button
var code_message: Label
var table_page: Control
var code_page: Control
var target_state: Dictionary = {}
var target_label: Label
var target_storage_note: Label
var _target_bar: HBoxContainer
var _save_button: Button
var _code_heading: Label
var _code_origin: Control
var _code_import: bool = false
var _setting_code: bool = false
var _observed_text: String = ""
var _requested_text: String = ""
var _preview_code: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	borderless = true
	var skin := Theme.new(); skin.default_font_size = 18; InstrumentStyle.apply_to(skin); theme = skin
	var surface := Panel.new(); surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel",InstrumentStyle.panel(Palette.TERM_PANEL,Palette.ACCENT)); add_child(surface)
	title = _l("我的方案榜", "My design rankings")
	min_size = Vector2i(760,420)
	size = Vector2i(1040,560)
	transient = true
	exclusive = true
	close_requested.connect(dismiss)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var heading: Label = _label(header,_l("同一任务 · 全部订单 · 实测方案", "Same task · all cases · measured designs"))
	heading.tooltip_text = _l("打开时重新测量。选择一种目标，保留不同取舍；通关仍需「运行全部订单」。",
		"Remeasured on opening. Choose an objective and keep different tradeoffs. Use Run all cases to complete the task.")
	close_button = _button(header,_l("关闭", "Close"),dismiss)
	close_button.name = "ScoreClose"
	table_page = VBoxContainer.new()
	table_page.name = "ScoreTablePage"
	table_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_page.add_theme_constant_override("separation",6)
	column.add_child(table_page)
	var controls := HBoxContainer.new()
	table_page.add_child(controls)
	order = OptionButton.new()
	order.name = "ScoreObjective"
	for text: String in [_l("更快 · 总周期", "Faster · total cycles"),_l("少搬运 · RAM 流量", "Less transfer · RAM bytes"),_l("小空间 · 临时峰值", "Less space · peak scratch")]:
		order.add_item(text)
	controls.add_child(order)
	order.item_selected.connect(func(index: int) -> void:
		objective = ["cycles","traffic","space"][index]
		rows = Board.rank_rows(rows,objective)
		_render_rows())
	name_edit = LineEdit.new()
	name_edit.name = "ScoreName"
	name_edit.placeholder_text = _l("给当前草稿另存一个名字", "Save current draft with a new name")
	name_edit.max_length = 40
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(name_edit)
	_save_button = _button(controls,_l("另存当前方案", "Save current design"),_request_save)
	name_edit.text_submitted.connect(func(_text: String) -> void: _request_save())
	_target_bar = HBoxContainer.new()
	table_page.add_child(_target_bar)
	target_label = _label(_target_bar,"")
	target_label.name = "ScoreTarget"
	target_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	target_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	target_code_button = _button(_target_bar,_l("目标挑战码", "Target code"),_share_target)
	target_code_button.name = "ScoreTargetCode"
	clear_target_button = _button(_target_bar,_l("清除目标", "Clear target"),func() -> void: clear_challenge_requested.emit())
	clear_target_button.name = "ScoreClearTarget"
	target_storage_note = _label(table_page,"")
	target_storage_note.name = "ScoreTargetStorage"
	table = Tree.new()
	table.name = "ScoreRows"
	table.columns = 6
	table.hide_root = true
	table.select_mode = Tree.SELECT_ROW
	table.column_titles_visible = true
	table.size_flags_vertical = Control.SIZE_FILL
	table.custom_minimum_size.y = 70
	var titles: Array[String] = [_l("名次","Rank"),_l("方案","Design"),_l("周期","Cycles"),_l("RAM / B","RAM / B"),_l("临时 / B","Scratch / B"),_l("资格","Status")]
	var widths: Array[int] = [46,170,84,92,92,150]
	for index: int in range(6):
		table.set_column_title(index,titles[index])
		table.set_column_expand(index,index == 1)
		table.set_column_custom_minimum_width(index,widths[index])
	table.add_theme_stylebox_override("selected",InstrumentStyle.panel(Color(Palette.ACCENT,0.18),Palette.ACCENT))
	table.add_theme_stylebox_override("selected_focus",InstrumentStyle.panel(Color(Palette.ACCENT,0.18),Palette.ACCENT))
	table_page.add_child(table)
	table.item_selected.connect(_selection_changed)
	detail = _label(table_page,"")
	detail.name = "ScoreDetail"
	var actions := HBoxContainer.new()
	table_page.add_child(actions)
	restore_button = _button(actions,_l("载入改进", "Continue improving"),_restore)
	restore_button.name = "ScoreRestore"
	challenge_button = _button(actions,_l("设为目标", "Set target"),_challenge)
	challenge_button.name = "ScoreChallenge"
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; actions.add_child(spacer)
	share_button = _button(actions,_l("分享挑战码", "Share code"),_share)
	share_button.name = "ScoreShare"
	import_button = _button(actions,_l("导入挑战码", "Import code"),_open_import)
	import_button.name = "ScoreImport"
	note = _label(table_page,_l("名次属于本机当前模式；通关请运行全部订单。", "Local mode rankings. Run all cases to complete the task."))
	note.name = "ScoreNote"
	_build_code_page(column)
	set_target_state(target_state)
	refresh(candidates)
	size_changed.connect(func() -> void: _fit_table.call_deferred())

func _build_code_page(parent: Control) -> void:
	code_page = VBoxContainer.new()
	code_page.name = "ScoreCodePage"
	code_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_page.add_theme_constant_override("separation",8)
	parent.add_child(code_page)
	_code_heading = _label(code_page,"")
	code_edit = TextEdit.new()
	code_edit.name = "ScoreCode"
	code_edit.custom_minimum_size.y = 112
	code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	code_edit.add_theme_color_override("font_readonly_color",Color("d8e7f2"))
	code_edit.add_theme_color_override("font_selected_color",Color("f2f7fb"))
	code_edit.add_theme_color_override("selection_color",Color("25445a"))
	code_edit.placeholder_text = _l("在这里粘贴挑战码，再点「检查」。", "Paste a challenge code here, then choose Check.")
	code_page.add_child(code_edit)
	code_edit.text_changed.connect(_code_changed)
	code_edit.gui_input.connect(_code_editor_input)
	code_message = _label(code_page,"")
	code_message.name = "ScoreCodeMessage"
	var actions := HFlowContainer.new()
	code_page.add_child(actions)
	code_check_button = _button(actions,_l("检查", "Check"),_check_import)
	code_check_button.name = "ScoreCodeCheck"
	code_pin_button = _button(actions,_l("设为目标", "Set target"),_pin_import)
	code_pin_button.name = "ScoreCodePin"
	code_copy_button = _button(actions,_l("复制", "Copy"),_copy_code)
	code_copy_button.name = "ScoreCodeCopy"
	code_back_button = _button(actions,_l("返回方案榜", "Back to rankings"),_back_to_table)
	code_back_button.name = "ScoreCodeBack"
	code_page.hide()

func refresh(value: Array[Dictionary]) -> void:
	candidates = value.duplicate(true)
	if not is_instance_valid(table): return
	table_page.show()
	code_page.hide()
	rows = Board.build_rows(level_id,candidates,objective)
	_render_rows()

func set_target_state(value: Dictionary) -> void:
	target_state = value.duplicate(true)
	if not is_instance_valid(target_label): return
	var previous_focus: Control = gui_get_focus_owner()
	var state: String = str(target_state.get("state","none"))
	_target_bar.visible = state != "none"
	var caption: String = str(target_state.get("title",""))
	if state == "active":
		var metric: String = str(target_state.get("objective","cycles"))
		var row: Dictionary = target_state.get("row",{})
		var key: String = "peak" if metric == "space" else metric
		target_label.text = _l("目标：%s · %s %d", "Target: %s · %s %d") % [caption,_objective_name(metric),int(row.get(key,0))]
	else:
		target_label.text = _l("已保留的目标：%s · 条件已变", "Kept target: %s · conditions changed") % caption
	target_label.tooltip_text = target_label.text
	target_code_button.disabled = str(target_state.get("code","")).is_empty()
	target_storage_note.text = str(target_state.get("storage_message",""))
	target_storage_note.visible = not target_storage_note.text.is_empty()
	code_pin_button.text = _l("替换目标","Replace target") if state != "none" else _l("设为目标","Set target")
	_refresh_focus_loop()
	if state == "none" and table_page.visible and previous_focus in [target_code_button,clear_target_button]:
		import_button.grab_focus()
	_fit_table.call_deferred()

func _fit_table() -> void:
	var header: Control = close_button.get_parent()
	var overhead: float = table_page.get_combined_minimum_size().y - table.custom_minimum_size.y + header.get_combined_minimum_size().y + 32
	# Keep actions visible at the minimum window size, using table scrolling as needed.
	table.custom_minimum_size.y = minf(40 * clampi(rows.size(),5,8) + 40,maxf(70,size.y-overhead))

func _render_rows() -> void:
	_fit_table.call_deferred()
	table.clear()
	var tree_root: TreeItem = table.create_item()
	var selected: TreeItem
	for row: Dictionary in rows:
		var item: TreeItem = table.create_item(tree_root)
		item.set_metadata(0,row.id)
		item.set_text(0,str(row.rank) if row.eligible else "—")
		item.set_text(1,row.title)
		item.set_tooltip_text(1,row.title)
		for pair: Array in [[2,"cycles"],[3,"traffic"],[4,"peak"]]:
			item.set_text(pair[0],str(row[pair[1]]) if row.correct else "—")
			item.set_text_alignment(pair[0],HORIZONTAL_ALIGNMENT_RIGHT)
		item.set_text(5,_l("达标","Target met") if row.eligible else _l("未达标","Target unmet") if row.correct else _l("未完成","Incomplete"))
		item.set_tooltip_text(5,_l("全部订单输出正确且达标","All cases correct and within targets") if row.eligible else _l("输出正确，尚未满足全部任务要求","Correct output; some task targets remain unmet") if row.correct else _l("尚未正确完成全部订单","Not all cases completed correctly"))
		item.set_custom_color(5,Palette.GOOD if row.eligible else Palette.QUIT)
		item.set_custom_bg_color(5,Color(Palette.GOOD if row.eligible else Palette.QUIT,0.12))
		item.set_custom_minimum_height(40)
		if row.id in ["current","challenge"]:
			item.set_custom_color(1,Palette.ACCENT if row.id == "current" else Palette.SIGNAL_ON)
			item.set_custom_bg_color(1,Color(Palette.ACCENT if row.id == "current" else Palette.SIGNAL_ON,0.08))
		if str(row.id) == selected_id: selected = item
	if selected == null and not rows.is_empty(): selected = tree_root.get_first_child()
	if selected != null: selected.select(0)
	_selection_changed()

func selected_row() -> Dictionary:
	var item: TreeItem = table.get_selected()
	if item == null: return {}
	for row: Dictionary in rows:
		if row.id == item.get_metadata(0): return row
	return {}

func _selection_changed() -> void:
	var row: Dictionary = selected_row()
	restore_button.disabled = row.is_empty() or row.id == "current"
	challenge_button.disabled = row.is_empty() or not row.eligible
	challenge_button.text = _l("保留目标","Keep target") if row.get("id","") == "challenge" else _l("设为目标","Set target")
	challenge_button.tooltip_text = _l("保留原挑战目标并重试保存；排序选择不会改变它。","Keep the original target and retry saving; the sort selection does not change it.") if row.get("id","") == "challenge" else ""
	share_button.disabled = row.is_empty() or not row.eligible
	if row.is_empty():
		detail.text = ""
		_refresh_focus_loop()
		return
	selected_id = row.id
	detail.text = _l("周期、RAM 为两单合计；临时空间取峰值；仅全部达标参与排名。",
		"Two-case cycle/RAM totals · maximum scratch · all cases must pass.")
	detail.tooltip_text = _l("相同数值并列。先满足每单的时间、流量与空间要求，再比较名次。",
		"Equal values share a rank. Meet every case's time, traffic and space limits before ranking.")
	_refresh_focus_loop()

func _restore() -> void:
	var row: Dictionary = selected_row()
	if row.is_empty() or row.id == "current": return
	hide()
	restore_requested.emit(row.design.duplicate(true))

func _challenge() -> void:
	var row: Dictionary = selected_row()
	if row.is_empty() or not row.eligible: return
	hide()
	challenge_requested.emit(row.duplicate(true),objective)

func _request_save() -> void:
	save_requested.emit(name_edit.text.strip_edges())

func _share() -> void:
	var row: Dictionary = selected_row()
	if row.is_empty() or not row.eligible: return
	_code_origin = share_button
	share_requested.emit(row.duplicate(true),objective)

func _share_target() -> void:
	_code_origin = target_code_button
	share_target_requested.emit()

func show_code(code: String, message: String) -> void:
	_code_import = false
	_preview_code = ""
	_requested_text = ""
	_setting_code = true
	code_edit.editable = false
	code_edit.text = code
	_observed_text = code
	_setting_code = false
	code_edit.clear_undo_history()
	_code_heading.text = _l("分享挑战码 · 只含配方与比较条件", "Share challenge code · recipe and comparison conditions")
	code_message.text = message
	code_check_button.hide()
	code_pin_button.hide()
	code_copy_button.show()
	code_copy_button.disabled = code.is_empty()
	table_page.hide()
	code_page.show()
	_refresh_focus_loop()
	code_edit.grab_focus()
	code_edit.select_all()

func _open_import() -> void:
	_code_origin = import_button
	_code_import = true
	_preview_code = ""
	_requested_text = ""
	_setting_code = true
	code_edit.editable = true
	code_edit.text = ""
	_observed_text = ""
	_setting_code = false
	code_edit.clear_undo_history()
	_code_heading.text = _l("导入挑战码 · 检查后预览本机实测目标", "Import challenge code · check to preview a locally measured target")
	code_message.text = _l("检查和设目标会保留当前草稿。载入方案后可以撤销。", "Checking and setting a target keep your draft. Loading a design can be undone.")
	code_check_button.show()
	code_check_button.disabled = true
	code_pin_button.show()
	code_pin_button.disabled = true
	code_copy_button.hide()
	table_page.hide()
	code_page.show()
	_refresh_focus_loop()
	code_edit.grab_focus()

func _code_changed() -> void:
	if _setting_code or not _code_import: return
	if _observed_text == code_edit.text: return
	_observed_text = code_edit.text
	_preview_code = ""
	_requested_text = ""
	code_pin_button.disabled = true
	code_check_button.disabled = code_edit.text.strip_edges().is_empty()
	code_message.text = _l("文字已改变；请检查后再设为目标。", "Code changed; check it before setting a target.")
	_refresh_focus_loop()

func _check_import() -> void:
	if not _code_import or not code_page.visible or code_edit.text.strip_edges().is_empty(): return
	_preview_code = ""
	code_pin_button.disabled = true
	_requested_text = code_edit.text
	_observed_text = code_edit.text
	code_check_button.disabled = false
	_refresh_focus_loop()
	import_requested.emit(_requested_text)

func show_import_result(result: Dictionary) -> void:
	if not _code_import or not code_page.visible or _requested_text.is_empty() or code_edit.text != _requested_text: return
	var accepted: bool = bool(result.get("ok",false)) and not str(result.get("code","")).is_empty()
	_preview_code = str(result.get("code","")) if accepted else ""
	code_pin_button.disabled = not accepted
	code_message.text = str(result.get("message",""))
	if accepted:
		var row: Dictionary = result.get("row",{})
		code_message.text += "\n" + _l("%s · %d 周期 · RAM %d B · 临时峰值 %d B", "%s · %d cycles · RAM %d B · peak scratch %d B") % [
			_objective_name(str(result.get("objective","cycles"))),int(row.get("cycles",0)),int(row.get("traffic",0)),int(row.get("peak",0))]
	_refresh_focus_loop()

func _pin_import() -> void:
	if not _code_import or not code_page.visible or code_pin_button.disabled or _preview_code.is_empty() or code_edit.text != _requested_text: return
	import_target_requested.emit(_preview_code)

func _copy_code() -> void:
	if code_copy_button.disabled or code_edit.text.is_empty(): return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		code_edit.grab_focus()
		code_edit.select_all()
		code_message.text = _l("请选择文字手动复制。", "Select the text and copy it manually.")
		return
	DisplayServer.clipboard_set(code_edit.text)
	code_edit.select_all()
	code_message.text = _l("已复制。也可以选中文字手动复制。", "Copied. You can also select the text and copy it manually.")

func _back_to_table() -> void:
	code_page.hide()
	table_page.show()
	_preview_code = ""
	code_pin_button.disabled = true
	_refresh_focus_loop()
	if is_instance_valid(_code_origin) and _code_origin.is_visible_in_tree() and not (_code_origin is BaseButton and _code_origin.disabled):
		_code_origin.grab_focus()
	else:
		import_button.grab_focus()

func _code_editor_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		code_edit.accept_event()
		_back_to_table()
	elif event.keycode == KEY_TAB and not event.is_command_or_control_pressed() and not event.alt_pressed:
		code_edit.accept_event()
		var path: NodePath = code_edit.focus_previous if event.shift_pressed else code_edit.focus_next
		var next: Control = code_edit.get_node_or_null(path) as Control
		if is_instance_valid(next): next.grab_focus()

func _refresh_focus_loop() -> void:
	if not is_instance_valid(code_back_button): return
	var choices: Array[Control] = [close_button]
	if code_page.visible:
		choices.append_array([code_edit,code_check_button,code_pin_button,code_copy_button,code_back_button])
	else:
		choices.append_array([order,name_edit,_save_button])
		if _target_bar.visible: choices.append_array([target_code_button,clear_target_button])
		choices.append_array([table,restore_button,challenge_button,share_button,import_button])
	var controls: Array[Control] = []
	for control: Control in choices:
		var enabled: bool = control.visible and not (control is BaseButton and control.disabled)
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		if enabled: controls.append(control)
	for index: int in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index+controls.size()-1)%controls.size()])

func _objective_name(value: String) -> String:
	return _l("临时空间","Scratch") if value == "space" else _l("RAM 流量","RAM traffic") if value == "traffic" else _l("总周期","Total cycles")

func dismiss() -> void:
	hide()
	dismissed.emit()

func _input(event: InputEvent) -> void:
	# Like the existing review popup, this Window owns a separate viewport.
	# Route ordinary feedback here and close it before the code/table Escape.
	if not visible or not has_focus() or not event is InputEventKey or not event.pressed or event.echo: return
	var feedback: Node = get_node_or_null("/root/OfflineFeedback")
	var moments: Node = get_node_or_null("/root/PlaytestMoments")
	if event.keycode == KEY_F8:
		if moments != null and (feedback == null or not feedback.enabled()):
			moments.toggle()
			set_input_as_handled()
		return
	if event.keycode != KEY_ESCAPE: return
	if feedback != null and feedback.backdrop.visible and feedback.panel.get_viewport() == self:
		set_input_as_handled()
		feedback.close_panel()
	elif moments != null and moments.panel.visible and moments.panel.get_viewport() == self:
		set_input_as_handled()
		moments.close()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		set_input_as_handled()
		if code_page.visible: _back_to_table()
		else: dismiss()

func _label(parent: Node, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 32
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _l(zh: String, en: String) -> String:
	return zh if TranslationServer.get_locale().begins_with("zh") else en
