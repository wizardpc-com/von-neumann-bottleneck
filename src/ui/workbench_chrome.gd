extends RefCounted
## One look for every workbench header inside the terminal: a single light
## navigation line (no heavy frame, one hairline underneath) with the task name,
## then the scene's own actions, then the shared navigation in one order:
##   旅程地图 → 实验室 → 设置   (退出游戏 last, muted red, where a scene has it)
## The line keeps one row at normal text size; the canvas gets the height back.
## Only presentation: nodes keep their names, signals and behaviour.

const Palette = preload("res://src/lab/lab_palette.gd")
const Typography = preload("res://src/ui/ui_typography.gd")
const BUTTON_HEIGHT := 34.0
const TITLE_SIZE := 19
const SUBTITLE_SIZE := 14
## Navigation bars join this group; level guidance places itself below them.
const NAV_GROUP := &"workbench_nav"


static func add_handbook(host: Control, navigation: Control, domain: String, lesson: String) -> Control:
	var handbook: Control = load("res://src/ui/terminology_handbook.gd").new()
	host.add_child(handbook)
	handbook.set_lesson(domain, lesson)
	handbook.entry_button.reparent(navigation)
	handbook.entry_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tidy_button(handbook.entry_button)
	return handbook


## The navigation line's surface: a faint lift and a hairline, no box.
static func bar_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.with_alpha(Palette.TERM_PANEL, 0.55)
	box.border_color = Palette.with_alpha(Palette.TERM_EDGE, 0.9)
	box.border_width_bottom = 1
	box.set_corner_radius_all(0)
	box.corner_radius_top_left = 8; box.corner_radius_top_right = 8
	box.content_margin_left = 14; box.content_margin_right = 8; box.content_margin_top = 3; box.content_margin_bottom = 4
	return box


## Wraps `header` (an HBoxContainer already in the tree) in the shared frame.
static func frame(header: Control) -> PanelContainer:
	if header.get_parent() is PanelContainer and str(header.get_parent().name).ends_with("Chrome"):
		return header.get_parent()
	var parent: Node = header.get_parent()
	var index: int = header.get_index()
	var chrome := PanelContainer.new(); chrome.name = str(header.name) + "Chrome"
	if chrome.name == "Chrome": chrome.name = "WorkbenchHeaderChrome"
	chrome.add_theme_stylebox_override("panel", bar_style())
	chrome.add_to_group(NAV_GROUP)
	if parent != null:
		parent.remove_child(header)
		parent.add_child(chrome)
		parent.move_child(chrome, index)
	chrome.add_child(header)
	if header is BoxContainer: (header as BoxContainer).add_theme_constant_override("separation", 8)
	for child: Node in header.get_children():
		if child is Button: tidy_button(child)
	# Buttons that scenes append later (settings, feedback, review) match too.
	if not header.child_entered_tree.is_connected(_tidy_late_child):
		header.child_entered_tree.connect(_tidy_late_child)
	return chrome


static func _tidy_late_child(child: Node) -> void:
	if child is Button: tidy_button(child)


static func title(label: Label) -> void:
	label.add_theme_font_override("font", Typography.HEADING_FONT)
	label.add_theme_font_size_override("font_size", TITLE_SIZE)
	label.add_theme_color_override("font_color", Palette.ACCENT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


static func subtitle(label: Label) -> void:
	label.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	label.add_theme_color_override("font_color", Palette.TERM_MUTED)


static func tidy_button(button: Button) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, BUTTON_HEIGHT)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Navigation reads as a ghost outline; Quit and primary actions keep their own look.
	if not button.has_meta("keep_style") and not button.has_theme_stylebox_override("normal"):
		preload("res://src/ui/instrument_theme.gd").nav(button)


## Leaving the game reads apart from every other action, everywhere.
static func quit_style(button: Button) -> void:
	button.set_meta("keep_style", true)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.QUIT_DEEP.lightened(0.08 if state == "hover" else 0.0).darkened(0.2 if state == "pressed" else 0.0)
		box.border_color = Palette.QUIT if state != "normal" else Palette.with_alpha(Palette.QUIT, 0.7)
		box.set_border_width_all(2 if state == "focus" else 1); box.set_corner_radius_all(7)
		box.content_margin_left = 12; box.content_margin_right = 12
		box.draw_center = state != "focus"
		button.add_theme_stylebox_override(state, box)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Palette.QUIT)


## Moves the shared navigation buttons to the end of the header, in order.
static func order_navigation(header: Node, ordered: Array) -> void:
	for node: Variant in ordered:
		if node is Node and is_instance_valid(node) and (node as Node).get_parent() == header:
			header.move_child(node, -1)
