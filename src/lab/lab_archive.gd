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
var previous_focus: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50

func present(use_english: bool) -> void:
	if not visible: previous_focus = get_viewport().gui_get_focus_owner()
	english = use_english
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_build()
	show()
	preload("res://src/ui/ui_motion.gd").reveal(get_node("ArchivePaper").get_child(0))

func close() -> void:
	hide()
	closed.emit()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
	previous_focus = null

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close(); get_viewport().set_input_as_handled()

func _build() -> void:
	var shade := ColorRect.new(); shade.color = Color("050a12", 0.78)
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
		box.bg_color = Color("08111a")
		box.border_color = Color(0, 0, 0, 0)
		# Full screen, but the shelf and its reader keep a readable width.
		box.content_margin_left = 80; box.content_margin_right = 80; box.content_margin_top = 30; box.content_margin_bottom = 30
		paper.resized.connect(func() -> void:
			box.content_margin_left = maxf(32,(paper.size.x-1120)*0.5)
			box.content_margin_right = box.content_margin_left)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 14); paper.add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	var heading := _label(header, "档案架" if not english else "Archive shelf", 24, Palette.LAB_INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button = Button.new(); close_button.name = "ArchiveClose"
	close_button.text = "返回 · Esc" if not english else "Back · Esc"
	_style_button(close_button, false); close_button.pressed.connect(close); header.add_child(close_button)
	preload("res://src/lab/lab_terminal_pages.gd").style_header(header,heading,close_button)
	var split := HBoxContainer.new(); split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 22); column.add_child(split)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.x = 250
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3); scroll.add_child(list)
	var sheet := PanelContainer.new()
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sheet_box := StyleBoxFlat.new()
	sheet_box.bg_color = Palette.TERM_PANEL if terminal_page else Palette.LAB_LIGHT
	sheet_box.border_color = Palette.TERM_EDGE if terminal_page else Palette.LAB_TRIM
	sheet_box.set_border_width_all(1); sheet_box.set_corner_radius_all(4)
	for edge: String in ["left", "right", "top", "bottom"]: sheet_box.set("content_margin_" + edge, 24.0)
	sheet.add_theme_stylebox_override("panel", sheet_box)
	split.add_child(sheet)
	var ruling := Control.new(); ruling.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ruling.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.add_child(ruling)
	ruling.draw.connect(func() -> void:
		var ink: Color = body_label.get_theme_color("font_color") if is_instance_valid(body_label) else Palette.LAB_INK
		for y: int in range(36, int(ruling.size.y), 28):
			ruling.draw_line(Vector2(16, y), Vector2(ruling.size.x - 16, y), Color(ink, 0.07), 1.0))
	ruling.resized.connect(ruling.queue_redraw)
	var reader := VBoxContainer.new(); reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.add_theme_constant_override("separation", 12); sheet.add_child(reader)
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
	var page: int = 0
	for fragment: Dictionary in Fragments.FRAGMENTS:
		page += 1
		var open: bool = str(fragment.requires) in completed
		var entry := Button.new(); entry.name = "Fragment_" + str(fragment.id)
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		# Locked story titles stay private; the task prerequisite remains on hover.
		if open:
			entry.text = "%02d  %s" % [page, Fragments.title(fragment, english)]
			if first_open.is_empty() or not str(fragment.id) in read: first_open = str(fragment.id) if first_open.is_empty() or not first_open in read else first_open
		else:
			var task_title: String = str(titles.get(str(fragment.requires), "…"))
			entry.text = "%02d" % page
			entry.tooltip_text = ("完成「%s」后开启" if not english else "Opens after \"%s\"") % task_title
		entry.set_meta("page", page)
		entry.tooltip_text = entry.text if open else entry.tooltip_text
		_style_button(entry, open)
		if open and not str(fragment.id) in read:
			entry.add_theme_color_override("font_color", Palette.ACCENT_DEEP)
		entry.disabled = not open
		if not open:
			entry.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			entry.custom_minimum_size.x = 128
			entry.draw.connect(func() -> void:
				var ink := Color(entry.get_theme_color("font_disabled_color"), 0.65)
				var at := Vector2(entry.size.x - 25, entry.size.y * 0.5)
				entry.draw_arc(at - Vector2(0, 3), 4, PI, TAU, 12, ink, 1.2, true)
				entry.draw_rect(Rect2(at - Vector2(6, 3), Vector2(12, 9)), ink, false, 1.2))
		var id: String = str(fragment.id)
		entry.pressed.connect(func() -> void: _show(id))
		list.add_child(entry)
	_label(list, "锁定页随任务完成开启" if not english else "Closed tabs open as tasks are completed", 12, Palette.LAB_INK_SOFT)
	if first_open.is_empty():
		title_label.hide()
		title_label.get_parent().get_child(1).hide()
		body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		close_button.call_deferred("grab_focus")
		title_label.text = "还没有记录" if not english else "No records yet"
		var first: Dictionary = Fragments.FRAGMENTS[0] if not Fragments.FRAGMENTS.is_empty() else {}
		var first_task: String = str(titles.get(str(first.get("requires", "")), ""))
		body_label.text = ("完成「%s」后，第一页会出现在这里。" if not english else "The first page appears here after \"%s\".") % first_task if not first_task.is_empty() else ""
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
		preload("res://src/ui/ui_motion.gd").reveal(body_label)
		note_label.text = ("叙事候选 · 故事设定待确认" if not english else "Story draft · setting awaiting confirmation") if bool(fragment.get("candidate", true)) else ""
		LabState.mark_fragment_read(id)
		var entry: Button = list.get_node_or_null("Fragment_" + id)
		if entry != null:
			entry.text = "%02d  %s" % [int(entry.get_meta("page", 0)), Fragments.title(fragment, english)]
			entry.remove_theme_color_override("font_color")
			entry.add_theme_color_override("font_color", Palette.TERM_TEXT if terminal_page else Palette.LAB_INK)

func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var node := Label.new(); node.text = text; node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size); node.add_theme_color_override("font_color", Palette.TERM_TEXT if terminal_page else color)
	parent.add_child(node); return node

func _style_button(button: Button, emphasised: bool) -> void:
	button.custom_minimum_size.y = 32 if button.name.begins_with("Fragment_") else 40
	button.add_theme_font_size_override("font_size", 20 if button.name.begins_with("Fragment_") and not emphasised else 15)
	# On the terminal workspace the page is written in terminal colours, which the
	# room skin then maps onto its light glass; on paper it keeps the lab palette.
	var fills: Array = [Palette.TERM_PANEL, Palette.TERM_SCREEN_LIFT, Palette.TERM_SCREEN] if terminal_page else [Palette.LAB_WALL, Palette.LAB_LIGHT, Palette.LAB_SIDE]
	for pair: Array in [["normal", fills[0]], ["hover", fills[1]], ["pressed", fills[2]], ["disabled", fills[0]], ["focus", Color(0, 0, 0, 0)]]:
		var box := StyleBoxFlat.new(); box.bg_color = pair[1]
		box.border_color = Palette.ACCENT_DEEP if str(pair[0]) in ["focus", "hover"] else (Palette.TERM_EDGE if terminal_page else Palette.LAB_TRIM)
		box.set_border_width_all(2 if str(pair[0]) == "focus" else 1); box.set_corner_radius_all(3)
		if button.name.begins_with("Fragment_"):
			box.border_width_left = 4
			box.corner_radius_top_right = 12
			box.corner_radius_bottom_right = 0
			box.border_color = Palette.ACCENT_DEEP if emphasised else (Palette.TERM_EDGE if terminal_page else Palette.LAB_TRIM)
		box.content_margin_left = 12; box.content_margin_right = 12
		box.draw_center = str(pair[0]) != "focus"
		button.add_theme_stylebox_override(str(pair[0]), box)
	var ink: Color = Palette.TERM_TEXT if terminal_page else Palette.LAB_INK
	var soft: Color = Palette.TERM_MUTED if terminal_page else Palette.LAB_INK_SOFT
	button.add_theme_color_override("font_color", ink if emphasised else soft)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	button.add_theme_color_override("font_disabled_color", soft)
