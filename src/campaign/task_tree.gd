extends Control
const Canvas = preload("res://src/campaign/task_tree_canvas.gd")
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
	column.add_theme_constant_override("separation",14)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_button(header,"tree.home",func() -> void:
		TaskNavigation.from_tree = false
		get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	var title := Label.new()
	title.text = _t("title")
	title.add_theme_font_size_override("font_size",30)
	header.add_child(title)
	header.add_child(PlaytestMoments.make_button())
	search = LineEdit.new()
	search.placeholder_text = _t("search")
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(search)
	_button(header,"tree.locate",func() -> void: canvas.locate(TaskNavigation.selected))
	_button(header,"tree.overview",func() -> void: canvas.overview())
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
	detail_kind=Label.new(); detail_kind.add_theme_font_size_override("font_size",18); side.add_child(detail_kind)
	detail_title=Label.new(); detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail_title.add_theme_font_size_override("font_size",28); side.add_child(detail_title)
	detail_status=Label.new(); detail_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	side.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	detail_scroll=scroll; scroll.follow_focus=true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	details = Label.new()
	details.custom_minimum_size.x = 300
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(details)
	side.add_child(detail_status)
	enter_button = _button(side,"tree.enter",func() -> void:
		if not selected.is_empty(): TaskNavigation.enter(selected.key))
	var records := Button.new(); records.text="我的任务记录" if TranslationServer.get_locale().begins_with("zh") else "My task record"
	records.custom_minimum_size.y=42; side.add_child(records)
	records.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/playtest/personal_records_view.tscn"))
	var opinion := Button.new(); opinion.text="评价所选任务" if TranslationServer.get_locale().begins_with("zh") else "Feedback on selected task"
	opinion.custom_minimum_size.y=42; side.add_child(opinion)
	opinion.pressed.connect(func() -> void:
		if not selected.is_empty(): PlaytestMoments.open_for_task(selected.key.get_slice("/",0),selected.id))
	var help := Label.new()
	help.text = _t("controls")
	help.add_theme_color_override("font_color",Color("91a0b9"))
	column.add_child(help)
	rows = TaskNavigation.tasks()
	PlaytestData.record_map_action(&"map_open","")
	for task: Dictionary in rows:
		if task.unlocked: PlaytestData.record_map_action(&"eligible",task.key)
	canvas.configure(rows)
	canvas.task_selected.connect(func(key: String) -> void:
		PlaytestData.record_map_action(&"detail_view",key)
		_select(key))
	search.text_changed.connect(func(value: String) -> void: canvas.set_search(value))
	search.text_submitted.connect(func(_value: String) -> void: canvas.locate_match())
	_select(TaskNavigation.selected)

func _select(key: String) -> void:
	for task: Dictionary in rows:
		if task.key != key: continue
		selected = task
		TaskNavigation.selected = key
		var accent: Color = canvas._color(task.region)
		var frame: StyleBoxFlat = InstrumentTheme.surface(Color("132330"),Color(accent,0.4),8)
		frame.content_margin_left=18; frame.content_margin_right=18
		frame.content_margin_top=18; frame.content_margin_bottom=18
		detail_panel.add_theme_stylebox_override("panel",frame)
		detail_title.text=task.title
		detail_kind.text=_t("optional" if task.optional else "main")
		detail_kind.add_theme_color_override("font_color",accent)
		detail_status.text=("✓ " if task.completed else "● " if task.unlocked else "○ ")+_t("completed" if task.completed else "available" if task.unlocked else "locked")
		detail_status.add_theme_color_override("font_color",accent if task.unlocked else Color("acb9cb"))
		var text: String = task.body
		text += "\n\n"+_t("prerequisites")
		if task.dependencies.is_empty(): text += "\n"+_t("none")
		for dependency: String in task.dependencies:
			for candidate: Dictionary in rows:
				if candidate.key == dependency:
					text += "\n"+("✓ " if candidate.completed else "○ ")+candidate.title
		if task.key == "chapter_2/capstone":
			text += "\n\n"+("✓ " if not LocalityChapter.economical_design.is_empty() else "◇ ")+Localization.text(&"bonus.economical")
		elif task.key in ["chapter_3/distance","chapter_3/synthesis"]:
			text += "\n\n"+("✓ " if OverlapChapter.bonus_status(task.id).complete else "◇ ")+Localization.text(StringName("overlap.bonus."+task.id))
		details.text = text
		detail_scroll.scroll_vertical=0
		InstrumentTheme.primary(enter_button,accent)
		enter_button.disabled = not task.unlocked
		canvas.queue_redraw()
		return

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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
