extends Window
## Presentation only. Codes, measurements and retained targets belong to the host.
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
signal share_requested(reply: bool)
signal preview_requested(code: String)
signal accept_requested(code: String)
signal target_code_requested
signal inspect_requested
signal restore_requested
signal clear_requested
signal retry_requested
signal recover_requested
signal starter_requested(task_id: String)
signal settings_requested
signal dismissed

var english: bool = false
var context: Dictionary = {}
var main_scroll: ScrollContainer
var main_page: VBoxContainer
var code_page: VBoxContainer
var heading: Label
var target_label: Label
var storage_label: Label
var selected_label: Label
var scope_label: Label
var close_button: Button
var settings_button: Button
var inspect_button: Button
var restore_button: Button
var target_code_button: Button
var clear_button: Button
var retry_button: Button
var recover_button: Button
var share_button: Button
var reply_button: Button
var import_button: Button
var starter_button: Button
var code_heading: Label
var code_edit: TextEdit
var code_message: Label
var check_button: Button
var accept_button: Button
var copy_button: Button
var back_button: Button
var _importing: bool = false
var _setting_text: bool = false
var _requested_text: String = ""
var _preview: Dictionary = {}
var _display_result: Dictionary = {}
var _message: String = ""
var _origin: String = "ImportChallenge"
var _labels: Array[Dictionary] = []

func tr2(zh: String, en: String) -> String:
	return en if english else zh

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	transient = true
	exclusive = true
	min_size = Vector2i(720,540)
	size = Vector2i(820,580)
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
	heading = _label(header,"",19)
	settings_button = _button(header,"设置","Settings",func() -> void: settings_requested.emit(),"ChallengeSettings")
	close_button = _button(header,"关闭","Close",dismiss,"ChallengeClose")
	main_scroll = ScrollContainer.new()
	main_scroll.name = "ChallengeScroll"
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(main_scroll)
	main_page = VBoxContainer.new()
	main_page.name = "ChallengeMain"
	main_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_page.add_theme_constant_override("separation",8)
	main_scroll.add_child(main_page)
	target_label = _label(main_page,"",15)
	target_label.name = "ChallengeTarget"
	storage_label = _label(main_page,"",13)
	storage_label.name = "ChallengeStorage"
	var target_actions := HBoxContainer.new()
	main_page.add_child(target_actions)
	inspect_button = _button(target_actions,"查看运行证据","Inspect evidence",func() -> void: inspect_requested.emit(),"InspectTarget")
	restore_button = _button(target_actions,"恢复目标方案","Restore target",func() -> void: restore_requested.emit(),"RestoreTarget")
	target_code_button = _button(target_actions,"目标代码","Target code",func() -> void:
		_origin = "TargetCode"
		target_code_requested.emit(),"TargetCode")
	clear_button = _button(target_actions,"清除目标","Clear target",func() -> void: clear_requested.emit(),"ClearTarget")
	var storage_actions := HBoxContainer.new()
	main_page.add_child(storage_actions)
	retry_button = _button(storage_actions,"重试挑战保存","Retry target save",func() -> void: retry_requested.emit(),"RetryTarget")
	recover_button = _button(storage_actions,"恢复写入","Recover writer",func() -> void: recover_requested.emit(),"RecoverTargetWriter")
	main_page.add_child(HSeparator.new())
	selected_label = _label(main_page,"",14)
	selected_label.name = "ChallengeSelected"
	var share_actions := HBoxContainer.new()
	main_page.add_child(share_actions)
	share_button = _button(share_actions,"按个人条件分享","Share with personal goal",func() -> void:
		_origin = "ShareChallenge"
		share_requested.emit(false),"ShareChallenge")
	reply_button = _button(share_actions,"按挑战条件应战","Share attempt with target goal",func() -> void:
		_origin = "ReplyChallenge"
		share_requested.emit(true),"ReplyChallenge")
	import_button = _button(main_page,"输入挑战码…","Enter challenge code…",open_import,"ImportChallenge")
	starter_button = _button(main_page,"试试当前工作负载的挑战","Try this workload's starter",func() -> void:
		var task_id: String = str(context.get("starter_task",""))
		if Code.starter_goal(task_id).is_empty(): return
		_origin = "CurrentStarter"
		starter_requested.emit(task_id),"CurrentStarter")
	scope_label = _label(main_page,"",13)
	scope_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scope_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_build_code(column)
	translate(english)
	set_context(context)

func _build_code(parent: Control) -> void:
	code_page = VBoxContainer.new()
	code_page.name = "ChallengeCodePage"
	code_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_page.add_theme_constant_override("separation",8)
	parent.add_child(code_page)
	code_heading = _label(code_page,"",15)
	code_edit = TextEdit.new()
	code_edit.name = "ChallengeCode"
	code_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	code_edit.custom_minimum_size.y = 120
	code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_edit.add_theme_color_override("font_readonly_color",Color("d8e7f2"))
	code_edit.add_theme_color_override("font_selected_color",Color("f2f7fb"))
	code_edit.add_theme_color_override("selection_color",Color("25445a"))
	code_edit.text_changed.connect(_code_changed)
	code_edit.gui_input.connect(_editor_input)
	code_page.add_child(code_edit)
	code_message = _label(code_page,"",14)
	code_message.name = "ChallengePreview"
	code_message.custom_minimum_size.y = 80
	var actions := HBoxContainer.new()
	code_page.add_child(actions)
	check_button = _button(actions,"预览并复测","Preview and measure",_check,"CheckChallenge")
	accept_button = _button(actions,"接纳目标","Accept target",_accept,"AcceptChallenge")
	copy_button = _button(actions,"复制代码","Copy code",_copy,"CopyChallenge")
	back_button = _button(actions,"返回","Back",back,"ChallengeBack")
	code_page.hide()

func _label(parent: Node, text: String, font_size: int) -> Label:
	var control := Label.new()
	control.text = text
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size",font_size)
	parent.add_child(control)
	return control

func _button(parent: Node, zh: String, en: String, action: Callable, id: String) -> Button:
	var control := Button.new()
	control.name = id
	control.custom_minimum_size.y = 34
	control.text = tr2(zh,en)
	control.pressed.connect(action)
	parent.add_child(control)
	_labels.append({"control":control,"zh":zh,"en":en})
	return control

func translate(value: bool) -> void:
	english = value
	title = tr2("同条件挑战","Same-condition challenges")
	if not is_instance_valid(heading): return
	for item: Dictionary in _labels: item.control.text = tr2(item.zh,item.en)
	scope_label.text = tr2("代码只包含方案和条件；本机重新计算。接纳不会载入草稿或改变个人条件。挑战与方案笔记分别保存。",
		"Codes carry a recipe and conditions; this machine remeasures them. Accepting keeps your draft and personal goal. Targets and Notebook save separately.")
	recover_button.tooltip_text = tr2("仅恢复已停止的写入窗口；之后仍需显式重试。","Recover only a stopped writer; retry saving separately.")
	_render_context()
	_render_code()

func set_context(value: Dictionary) -> void:
	context = value.duplicate(true)
	if is_instance_valid(target_label): _render_context()

func _render_context() -> void:
	heading.text = str(context.get("workload",""))
	target_label.text = str(context.get("target_text",tr2("尚未接纳挑战。","No accepted challenge.")))
	storage_label.text = str(context.get("storage_text",""))
	storage_label.add_theme_color_override("font_color",Color("f0c674") if context.get("pending",false) or context.get("protected",false) else Color("a5b6be"))
	selected_label.text = str(context.get("selected_text",tr2("先运行方案，再分享所选实测结果。","Run a plan before sharing its selected measurement.")))
	var active: bool = context.get("active",false)
	inspect_button.disabled = not active
	restore_button.disabled = not active
	target_code_button.disabled = not context.get("has_code",false)
	clear_button.disabled = not context.get("has_code",false)
	share_button.disabled = not context.get("selected_valid",false)
	reply_button.disabled = not active or not context.get("selected_valid",false)
	retry_button.visible = context.get("dirty",false) and context.get("retryable",true)
	retry_button.text = tr2("保存挑战副本","Save target copy") if context.get("copy_pending",false) and not context.get("protected",false) else tr2("重试挑战保存","Retry target save")
	recover_button.visible = context.get("busy",false)
	starter_button.visible = not Code.starter_goal(str(context.get("starter_task",""))).is_empty()
	accept_button.text = tr2("替换目标","Replace target") if context.get("has_code",false) else tr2("接纳目标","Accept target")
	_refresh_focus()

func open_import() -> void:
	_origin = "ImportChallenge"
	_start_code("",true)

func show_starter(code: String) -> void:
	_start_code(code,true)
	_check()

func show_code(code: String, result: Dictionary = {}) -> void:
	_start_code(code,false)
	_display_result = result.duplicate(true)
	_render_code()
	code_edit.select_all()

func _start_code(text: String, importing: bool) -> void:
	_importing = importing
	_preview.clear()
	_display_result.clear()
	_requested_text = ""
	_message = ""
	_setting_text = true
	code_edit.text = text
	code_edit.editable = importing
	code_edit.clear_undo_history()
	_setting_text = false
	main_page.hide()
	main_scroll.hide()
	code_page.show()
	_render_code()
	code_edit.grab_focus()

func _code_changed() -> void:
	if _setting_text or not _importing: return
	_preview.clear()
	_display_result.clear()
	_requested_text = ""
	_message = ""
	_render_code()

func _check() -> void:
	if not _importing or code_edit.text.strip_edges().is_empty(): return
	_preview.clear()
	_requested_text = code_edit.text
	_display_result.clear()
	_render_code()
	preview_requested.emit(_requested_text)

func show_preview(result: Dictionary) -> void:
	if not _importing or not code_page.visible or _requested_text.is_empty() or code_edit.text != _requested_text: return
	_display_result = result.duplicate(true)
	_preview = result.duplicate(true) if result.get("ok",false) else {}
	_render_code()

func _accept() -> void:
	if not _importing or _preview.is_empty() or code_edit.text != _requested_text: return
	accept_requested.emit(str(_preview.get("code","")))

func _render_code() -> void:
	if not is_instance_valid(code_edit): return
	code_heading.text = tr2("输入代码；先预览，再明确接纳。","Enter a code; preview it, then explicitly accept.") if _importing else tr2(
		"分享当前所选的实测方案与固定条件。","Share the selected measured recipe with fixed conditions.")
	check_button.visible = _importing
	accept_button.visible = _importing
	copy_button.visible = not _importing
	check_button.disabled = code_edit.text.strip_edges().is_empty()
	accept_button.disabled = _preview.is_empty() or code_edit.text != _requested_text
	copy_button.disabled = code_edit.text.is_empty()
	if not _message.is_empty():
		code_message.text = _message
	elif _display_result.get("ok",false):
		code_message.text = inspection_text(_display_result,english)
	elif not _display_result.is_empty():
		code_message.text = str(_display_result.get("message",reason_text(str(_display_result.get("reason","format")),english)))
		if _display_result.has("foreign_task"):
			code_message.text += "\n"+workload_text(str(_display_result.foreign_task),english)
	else:
		code_message.text = tr2("预览不会改变草稿、撤销、个人条件或方案笔记。修改代码后必须重新预览。",
			"Preview keeps your draft, Undo, personal goal and Notebook. Edited codes require a fresh preview.") if _importing else tr2(
			"保留的代码；只有当前模型能够复测的目标才参与比较。","Retained code; only targets remeasured by the current model participate in comparisons.")
	_refresh_focus()

func show_message(value: String) -> void:
	_message = value
	_render_code()

func _copy() -> void:
	if copy_button.disabled: return
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(code_edit.text)
		_message = tr2("已复制完整挑战码。","Copied the complete challenge code.")
	else:
		_message = tr2("请选择代码手动复制。","Select the code and copy it manually.")
	code_edit.grab_focus()
	code_edit.select_all()
	_render_code()

func back() -> void:
	code_page.hide()
	main_scroll.show()
	main_page.show()
	_preview.clear()
	_refresh_focus()
	restore_focus(_origin)

func focus_id() -> String:
	var focused: Control = gui_get_focus_owner()
	return str(focused.name) if focused != null else "ChallengeClose"

func restore_focus(id: String) -> void:
	var control: Control = find_child(id,true,false) as Control
	if control == null or not control.is_visible_in_tree() or (control is BaseButton and control.disabled):
		control = code_edit if code_page.visible else close_button
	control.grab_focus()

func _refresh_focus() -> void:
	if not is_instance_valid(back_button): return
	var choices: Array[Control] = [settings_button,close_button]
	if code_page.visible:
		choices.append_array([code_edit,check_button,accept_button,copy_button,back_button])
	else:
		choices.append_array([inspect_button,restore_button,target_code_button,clear_button,retry_button,recover_button,
			share_button,reply_button,import_button,starter_button])
	var controls: Array[Control] = []
	for control: Control in choices:
		var enabled: bool = control.visible and not (control is BaseButton and control.disabled)
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		if enabled: controls.append(control)
	for index: int in controls.size():
		controls[index].focus_next = controls[index].get_path_to(controls[(index+1)%controls.size()])
		controls[index].focus_previous = controls[index].get_path_to(controls[(index+controls.size()-1)%controls.size()])
	var focused: Control = gui_get_focus_owner()
	if visible and focused != null and is_ancestor_of(focused) and focused not in controls and not _feedback_visible():
		restore_focus("ChallengeCode" if code_page.visible else "ImportChallenge")

func _feedback_visible() -> bool:
	var moments: Node = get_node_or_null("/root/PlaytestMoments")
	var offline: Node = get_node_or_null("/root/OfflineFeedback")
	return (moments != null and moments.panel.visible) or (offline != null and (offline.backdrop.visible or bool(offline.busy)))

func _editor_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _feedback_visible(): return
	if event.keycode == KEY_TAB and not event.is_command_or_control_pressed() and not event.alt_pressed:
		code_edit.accept_event()
		var path: NodePath = code_edit.focus_previous if event.shift_pressed else code_edit.focus_next
		var next: Control = code_edit.get_node_or_null(path) as Control
		if next != null: next.grab_focus()
	elif event.keycode == KEY_ESCAPE:
		code_edit.accept_event()
		back()

func _input(event: InputEvent) -> void:
	if not visible or not has_focus() or not event is InputEventKey or not event.pressed or event.echo: return
	var moments: Node = get_node_or_null("/root/PlaytestMoments")
	var offline: Node = get_node_or_null("/root/OfflineFeedback")
	if event.keycode == KEY_F8:
		if moments != null and (offline == null or not offline.enabled()):
			set_input_as_handled()
			moments.toggle()
		return
	if event.keycode == KEY_ESCAPE and _feedback_visible():
		set_input_as_handled()
		if offline != null and offline.backdrop.visible: offline.close_panel()
		elif moments != null and moments.panel.visible: moments.close()
		return
	if _feedback_visible(): return
	if event.keycode == KEY_F10 or (OS.get_name() == "macOS" and event.keycode == KEY_COMMA and event.meta_pressed):
		set_input_as_handled()
		settings_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _feedback_visible(): return
	if event.keycode == KEY_ESCAPE:
		set_input_as_handled()
		if code_page.visible: back()
		else: dismiss()

func dismiss() -> void:
	hide()
	dismissed.emit()

static func _l(zh: String, en: String, use_english: bool) -> String:
	return en if use_english else zh

static func workload_text(task_id: String, use_english: bool) -> String:
	match task_id:
		"scan_batch": return _l("温度扫描 · 全部就绪","Temperature scans · all ready",use_english)
		"scan_serial": return _l("温度扫描 · 逐次请求","Temperature scans · serial",use_english)
		"mixed_batch": return _l("混合查询 · 全部就绪","Mixed queries · all ready",use_english)
		"mixed_serial": return _l("混合查询 · 逐次请求","Mixed queries · serial",use_english)
		"scan_pair_serial": return _l("两次温度 · 逐次请求","Two temperature scans · serial",use_english)
		"split_fields_serial": return _l("温度后告警 · 逐次请求","Temperature then alarm · serial",use_english)
	return task_id

static func goal_text(goal: Dictionary, use_english: bool) -> String:
	var objective: String = _l("总周期","total cycles",use_english) if goal.get("objective","cycles") == "cycles" else _l("RAM流量","RAM traffic",use_english)
	var first: String = _l("Q1不限","Q1: no cap",use_english) if int(goal.get("first_limit",-1)) < 0 else "Q1 ≤ %d" % int(goal.first_limit)+_l("周期"," cycles",use_english)
	var copy: String = _l("复制不限","Copy: no cap",use_english) if int(goal.get("copy_limit",-1)) < 0 else _l("复制","Copy",use_english)+" ≤ %d B" % int(goal.copy_limit)
	return _l("比较","Compare ",use_english)+objective+" · "+first+" · "+copy

static func metrics_text(metrics: Dictionary, use_english: bool) -> String:
	return _l("Q1 %d周期 · 总计 %d周期 · RAM %d B · 复制 %d B","Q1 %d cycles · total %d cycles · RAM %d B · copy %d B",use_english) % [
		int(metrics.get("first_request_cycles",-1)),int(metrics.get("total_cycles",-1)),
		int(metrics.get("ram_read_bytes",0))+int(metrics.get("ram_write_bytes",0)),int(metrics.get("peak_extra_bytes",0))]

static func inspection_text(result: Dictionary, use_english: bool) -> String:
	return goal_text(result.get("envelope",{}).get("goal",{}),use_english)+"\n"+metrics_text(result.get("entry",{}).get("metrics",{}),use_english)

static func reason_text(reason: String, use_english: bool) -> String:
	match reason:
		"size": return _l("代码过长；最多4096个UTF-8字节。","Code is too long; at most 4096 UTF-8 bytes.",use_english)
		"task": return _l("此代码不属于当前工作负载；请先返回并选择对应工作负载。","This code belongs to another workload. Return and select that workload first.",use_english)
		"stale": return _l("模型或条件版本已改变；保留代码，但暂不参与比较。","The model or conditions changed. Keep the code; it cannot currently be compared.",use_english)
		"limits": return _l("方案不满足代码中的Q1或复制限制；无法作为挑战目标。","The recipe exceeds its Q1 or copy cap and cannot be offered as a target.",use_english)
		"incomplete": return _l("需要完整且正确的实测结果。","A complete, correct measurement is required.",use_english)
		"plan": return _l("代码中的方案无效。","The recipe in this code is invalid.",use_english)
		"version": return _l("不支持此挑战码版本。","This challenge-code version is unsupported.",use_english)
	return _l("无法读取此挑战码；请粘贴完整的VNBSC1代码。","Could not read this code. Paste the complete VNBSC1 code.",use_english)
