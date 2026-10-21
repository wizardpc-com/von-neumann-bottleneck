extends Control
## Unlocked journey records, read on the laboratory terminal.

signal closed

const Palette = preload("res://src/lab/lab_palette.gd")
const Fragments = preload("res://src/lab/archive_fragments.gd")
const LabState = preload("res://src/lab/lab_state.gd")

var english: bool = false
var terminal_page: bool = false
var list: VBoxContainer
var title_label: Label
var body_label: Label
var note_label: Label
var close_button: Button
var selected: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50

func present(use_english: bool) -> void:
	english = use_english
	for child: Node in get_children(): child.queue_free()
	_build()
	show()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)

func close() -> void:
	hide()
	closed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close(); get_viewport().set_input_as_handled()

func _build() -> void:
	var shade := ColorRect.new(); shade.color = Color(0.17, 0.22, 0.25, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed: close())
	add_child(shade)
	var paper := PanelContainer.new(); paper.name = "ArchivePaper"
	var box := StyleBoxFlat.new(); box.bg_color = Palette.LAB_WALL_TOP
	box.border_color = Palette.LAB_TRIM; box.set_border_width_all(1); box.set_corner_radius_all(14)
	box.shadow_color = Color(0.15, 0.2, 0.24, 0.22); box.shadow_size = 24
	box.content_margin_left = 28; box.content_margin_right = 28; box.content_margin_top = 22; box.content_margin_bottom = 22
	paper.add_theme_stylebox_override("panel", box)
	paper.anchor_left = 0.5; paper.anchor_right = 0.5; paper.anchor_top = 0.5; paper.anchor_bottom = 0.5
	paper.offset_left = -470; paper.offset_right = 470; paper.offset_top = -300; paper.offset_bottom = 300
	add_child(paper)
	if terminal_page:
		paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.set_corner_radius_all(0)
		box.shadow_size = 0
		box.bg_color = Palette.TERM_SCREEN
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 14); paper.add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	var heading := _label(header, "档案架" if not english else "Archive shelf", 24, Palette.LAB_INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button = Button.new(); close_button.name = "ArchiveClose"
	close_button.text = "回到终端 · Esc" if not english else "Back to terminal · Esc"
	_style_button(close_button, false); close_button.pressed.connect(close); header.add_child(close_button)
	var hint := _label(column, "每走完一段旅程，这里会多一页壹留下的记录。" if not english else "Each stage of the journey adds a page from Yi's records.", 13, Palette.LAB_INK_SOFT)
	hint.name = "ArchiveHint"
	var split := HBoxContainer.new(); split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 22); column.add_child(split)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.x = 290
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6); scroll.add_child(list)
	var reader := VBoxContainer.new(); reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.add_theme_constant_override("separation", 12); split.add_child(reader)
	title_label = _label(reader, "", 22, Palette.LAB_INK)
	var rule := ColorRect.new(); rule.color = Palette.LAB_TRIM; rule.custom_minimum_size.y = 1; reader.add_child(rule)
	body_label = _label(reader, "", 17, Palette.LAB_INK); body_label.name = "ArchiveBody"
	body_label.add_theme_constant_override("line_spacing", 7)
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	note_label = _label(reader, "", 13, Palette.LAB_INK_SOFT)
	_fill()

func _fill() -> void:
	var rows: Array[Dictionary] = LabState.tasks()
	var completed: Array[String] = LabState.completed_keys(rows)
	var read: Array[String] = LabState.read_fragments()
	var titles: Dictionary = {}
	for row: Dictionary in rows: titles[str(row.key)] = str(row.title)
	var first_open: String = ""
	for fragment: Dictionary in Fragments.FRAGMENTS:
		var open: bool = str(fragment.requires) in completed
		var entry := Button.new(); entry.name = "Fragment_" + str(fragment.id)
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if open:
			entry.text = Fragments.title(fragment, english) + ("" if str(fragment.id) in read else ("  · 新" if not english else "  · new"))
			if first_open.is_empty() or not str(fragment.id) in read: first_open = str(fragment.id) if first_open.is_empty() or not first_open in read else first_open
		else:
			var task_title: String = str(titles.get(str(fragment.requires), "…"))
			entry.text = ("未开启 · 完成「%s」" if not english else "Locked · finish \"%s\"") % task_title
			entry.tooltip_text = entry.text
		_style_button(entry, open)
		entry.disabled = not open
		var id: String = str(fragment.id)
		entry.pressed.connect(func() -> void: _show(id))
		list.add_child(entry)
	if first_open.is_empty():
		close_button.call_deferred("grab_focus")
		title_label.text = "还没有记录" if not english else "No records yet"
		body_label.text = "完成第一项任务后，这里会出现第一页。" if not english else "The first page appears after your first completed task."
		note_label.text = ""
	else:
		_show(first_open)
		var target: Node = list.get_node_or_null("Fragment_" + first_open)
		if target != null: (target as Button).call_deferred("grab_focus")

func _show(id: String) -> void:
	for fragment: Dictionary in Fragments.FRAGMENTS:
		if str(fragment.id) != id: continue
		selected = id
		title_label.text = Fragments.title(fragment, english)
		body_label.text = Fragments.body(fragment, english)
		body_label.visible_ratio = 0.0
		create_tween().tween_property(body_label, "visible_ratio", 1.0, clampf(body_label.text.length() * 0.012, 0.3, 1.4))
		if bool(fragment.get("candidate", true)):
			note_label.text = "叙事候选 · 故事设定待确认" if not english else "Story draft · setting awaiting confirmation"
		else:
			note_label.text = "旅程记录 · 可回到工作台核对" if not english else "Journey note · check it at the workbench"
		LabState.mark_fragment_read(id)
		var entry: Button = list.get_node_or_null("Fragment_" + id)
		if entry != null: entry.text = Fragments.title(fragment, english)

func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var node := Label.new(); node.text = text; node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size); node.add_theme_color_override("font_color", Palette.TERM_TEXT if terminal_page else color)
	parent.add_child(node); return node

func _style_button(button: Button, emphasised: bool) -> void:
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 15)
	for pair: Array in [["normal", Palette.LAB_WALL], ["hover", Palette.LAB_LIGHT], ["pressed", Palette.LAB_SIDE], ["disabled", Color(0, 0, 0, 0)], ["focus", Color(0, 0, 0, 0)]]:
		var box := StyleBoxFlat.new(); box.bg_color = pair[1]
		box.border_color = Palette.ACCENT_DEEP if str(pair[0]) in ["focus", "hover"] else Palette.LAB_TRIM
		box.set_border_width_all(1 if str(pair[0]) != "focus" else 2); box.set_corner_radius_all(8)
		box.content_margin_left = 12; box.content_margin_right = 12
		box.draw_center = str(pair[0]) != "focus"
		button.add_theme_stylebox_override(str(pair[0]), box)
	button.add_theme_color_override("font_color", Palette.LAB_INK if emphasised else Palette.LAB_INK_SOFT)
	button.add_theme_color_override("font_hover_color", Palette.LAB_INK)
	button.add_theme_color_override("font_focus_color", Palette.LAB_INK)
	button.add_theme_color_override("font_disabled_color", Palette.with_alpha(Palette.LAB_INK_SOFT, 0.7))
