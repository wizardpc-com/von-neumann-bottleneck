extends RefCounted
## One look for every workbench header inside the terminal: a framed bar with
## the chapter (accent, heading font) above the task name (muted), then the
## scene's own actions, then the shared navigation in one order:
##   章节地图 / 旅程地图 → 实验室 → 设置   (退出游戏 last, muted red, where a scene has it)
## Only presentation: nodes keep their names, signals and behaviour.

const Palette = preload("res://src/lab/lab_palette.gd")
const Typography = preload("res://src/ui/ui_typography.gd")
const BUTTON_HEIGHT := 38.0
const TITLE_SIZE := 21
const SUBTITLE_SIZE := 14


## Wraps `header` (an HBoxContainer already in the tree) in the shared frame.
static func frame(header: Control) -> PanelContainer:
	if header.get_parent() is PanelContainer and str(header.get_parent().name).ends_with("Chrome"):
		return header.get_parent()
	var parent: Node = header.get_parent()
	var index: int = header.get_index()
	var chrome := PanelContainer.new(); chrome.name = str(header.name) + "Chrome"
	if chrome.name == "Chrome": chrome.name = "WorkbenchHeaderChrome"
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.with_alpha(Palette.TERM_PANEL, 0.96)
	box.border_color = Palette.TERM_EDGE; box.set_border_width_all(1); box.border_width_bottom = 2
	box.set_corner_radius_all(10)
	box.content_margin_left = 16; box.content_margin_right = 10; box.content_margin_top = 6; box.content_margin_bottom = 6
	chrome.add_theme_stylebox_override("panel", box)
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


## Leaving the game reads apart from every other action, everywhere.
static func quit_style(button: Button) -> void:
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
