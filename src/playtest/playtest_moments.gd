extends Node
## Voluntary local feedback available during a run and after an unfinished exit.
var panel: PanelContainer
var note: LineEdit
var status: Label
var exit_reason: OptionButton
var moment_sequence: int = -1
var last_export: String = ""
var source_selector: OptionButton
var previous_focus: Control

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1600
	add_child(layer)
	panel = PanelContainer.new()
	panel.name = "VoluntaryPlaytestFeedback"
	panel.position = Vector2(24,80)
	panel.custom_minimum_size = Vector2(560,0)
	var skin := Theme.new()
	skin.default_font_size = 20
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	panel.theme = skin
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	margin.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var title := Label.new()
	title.text = _t("title")
	title.set_meta("translation","title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_button(heading,"close",close)
	var privacy := Label.new()
	privacy.text = _t("privacy")
	privacy.set_meta("translation","privacy")
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(privacy)
	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	for kind: String in ["stuck","blocked_action","understood","fun","following"]:
		_button(grid,kind,func() -> void:
			moment_sequence = PlaytestData.mark_moment(StringName(kind))
			status.text = _t("saved") if moment_sequence > 0 else _t("failed")+PlaytestData.last_error)
	note = LineEdit.new()
	note.placeholder_text = _t("note")
	note.set_meta("translation","note")
	note.max_length = 240
	box.add_child(note)
	_button(box,"save_note",func() -> void:
		var saved: bool = PlaytestData.add_moment_note(moment_sequence,note.text)
		status.text = _t("saved") if saved else _t("choose_first")
		if saved: note.clear())
	exit_reason = OptionButton.new()
	exit_reason.add_item(_t("exit_optional"))
	for reason: String in ["other_task","rest","unclear_goal","no_strategy","unexpected_operation","repetitive"]:
		exit_reason.add_item(_t("exit."+reason))
		exit_reason.set_item_metadata(exit_reason.item_count-1,reason)
	exit_reason.item_selected.connect(func(index: int) -> void:
		if index > 0: status.text = _t("saved") if PlaytestData.set_exit_reason(StringName(exit_reason.get_item_metadata(index))) else _t("failed"))
	box.add_child(exit_reason)
	var source := OptionButton.new()
	source_selector = source
	source.add_item(_t("source.unknown"))
	source.set_item_metadata(0,"unknown")
	for kind: String in ["external_player","developer","agent_native","automated"]:
		source.add_item(_t("source."+kind))
		source.set_item_metadata(source.item_count-1,kind)
	source.disabled = PlaytestData.source_kind in ["automated","agent_native"]
	for index: int in range(source.item_count):
		if source.get_item_metadata(index) == PlaytestData.source_kind: source.select(index)
	source.item_selected.connect(func(index: int) -> void: PlaytestData.source_kind = source.get_item_metadata(index))
	box.add_child(source)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	_button(actions,"export",func() -> void:
		last_export = PlaytestData.export_current_session()
		status.text = _t("exported") if not last_export.is_empty() else _t("failed")+PlaytestData.last_error)
	_button(actions,"folder",func() -> void:
		if not last_export.is_empty(): OS.shell_show_in_file_manager(last_export))
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 32
	box.add_child(status)
	panel.hide()
	Localization.locale_changed.connect(func(_locale: String) -> void: _refresh_language())

func make_button() -> Button:
	var button := Button.new()
	button.name = "MomentFeedbackButton"
	button.text = _t("button")
	Localization.locale_changed.connect(func(_locale: String) -> void:
		if is_instance_valid(button):
			button.text = _t("button")
			button.tooltip_text = _t("title")+" · F8")
	button.tooltip_text = _t("title")+" · F8"
	button.pressed.connect(toggle)
	return button

func toggle() -> void:
	if panel.visible: close(); return
	previous_focus = get_viewport().gui_get_focus_owner()
	panel.show()
	var choices: Array[Node] = panel.find_children("*","Button",true,false)
	if not choices.is_empty(): (choices[0] as Button).grab_focus()
	exit_reason.visible = not PlaytestData.last_exit_context.is_empty()
	panel.position = Vector2(24,80)
	panel.size.x = minf(680,get_viewport().get_visible_rect().size.x-48)
	status.text = "" if PlaytestData.questionnaires_enabled() else _t("disabled")
	exit_reason.select(0)
	PlaytestData.set_feedback_visible(true,&"moments")

func close() -> void:
	panel.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	PlaytestData.set_feedback_visible(false,&"moments")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			toggle(); get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and panel.visible:
			close(); get_viewport().set_input_as_handled()

func _button(parent: Node,key: String,action: Callable) -> Button:
	var button := Button.new()
	button.text = _t(key)
	button.set_meta("translation",key)
	button.custom_minimum_size.y = 38
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _t(key: String) -> String: return Localization.text(StringName("moments."+key))

func _refresh_language() -> void:
	_translate(panel)
	exit_reason.set_item_text(0,_t("exit_optional"))
	for index: int in range(1,exit_reason.item_count): exit_reason.set_item_text(index,_t("exit."+str(exit_reason.get_item_metadata(index))))
	for index: int in range(source_selector.item_count): source_selector.set_item_text(index,_t("source."+str(source_selector.get_item_metadata(index))))
	status.text = ""

func _translate(node: Node) -> void:
	if node.has_meta("translation"):
		if node is LineEdit: node.placeholder_text = _t(str(node.get_meta("translation")))
		else: node.set("text",_t(str(node.get_meta("translation"))))
	for child: Node in node.get_children(): _translate(child)
