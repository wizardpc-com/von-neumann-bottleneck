class_name InstrumentTheme
extends RefCounted

const SURFACE := Color("1a252e")
const EDGE := Color("3a4b56")
const ACCENT := Color("8fd3dc")


static func primary(button: Button, accent: Color = ACCENT) -> void:
	button.add_theme_stylebox_override("normal", panel(accent, accent))
	button.add_theme_stylebox_override("hover", panel(accent.lightened(0.16), Color.WHITE))
	button.add_theme_stylebox_override("pressed", panel(accent.darkened(0.16), accent))
	button.add_theme_stylebox_override("hover_pressed", panel(accent.darkened(0.16), accent))
	button.add_theme_stylebox_override("disabled", panel(Color("1b252c"), EDGE))
	var focus: StyleBoxFlat = panel(Color.TRANSPARENT, Color("071823"))
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_disabled_color", Color("9eafb8"))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("071823"))


## Tool-row button: no box at rest, a soft fill on hover, an accent tint while
## pressed or toggled on. Rows of tools read as one quiet instrument strip
## instead of a wall of outlined boxes. Input geometry is unchanged.
static func tool(button: Button) -> void:
	var rest := StyleBoxFlat.new(); rest.bg_color = Color(1, 1, 1, 0.0); rest.set_corner_radius_all(7)
	_tool_margins(rest)
	var hover: StyleBoxFlat = rest.duplicate(); hover.bg_color = Color(1, 1, 1, 0.065)
	var on: StyleBoxFlat = rest.duplicate(); on.bg_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.15)
	on.border_width_bottom = 2; on.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.8)
	var on_hover: StyleBoxFlat = on.duplicate(); on_hover.bg_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.22)
	var focus := StyleBoxFlat.new(); focus.draw_center = false; focus.set_border_width_all(1)
	focus.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.7); focus.set_corner_radius_all(7)
	var disabled: StyleBoxFlat = rest.duplicate()
	button.add_theme_stylebox_override("normal", rest)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", on)
	button.add_theme_stylebox_override("hover_pressed", on_hover)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("d5e1e6"))
	button.add_theme_color_override("font_hover_color", Color("f0f6f8"))
	for state: String in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ACCENT.lightened(0.1))
	button.add_theme_color_override("font_disabled_color", Color("62737c"))


## Navigation button on the light top line: a ghost outline, quieter than tools
## and primary actions, so "where am I / where can I go" never competes with "do".
static func nav(button: Button) -> void:
	var rest := StyleBoxFlat.new(); rest.bg_color = Color(1, 1, 1, 0.025)
	rest.border_color = Color("2f404b"); rest.set_border_width_all(1); rest.set_corner_radius_all(7)
	_tool_margins(rest)
	var hover: StyleBoxFlat = rest.duplicate(); hover.bg_color = Color(1, 1, 1, 0.06)
	hover.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55)
	var pressed: StyleBoxFlat = hover.duplicate(); pressed.bg_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.14)
	var focus := StyleBoxFlat.new(); focus.draw_center = false; focus.set_border_width_all(2)
	focus.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.8); focus.set_corner_radius_all(7)
	button.add_theme_stylebox_override("normal", rest)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", rest.duplicate())
	button.add_theme_color_override("font_color", Color("d5e1e6"))
	button.add_theme_color_override("font_hover_color", Color("f0f6f8"))
	button.add_theme_color_override("font_disabled_color", Color("62737c"))


## Styles every plain button in a tool row (including ones the scene adds
## while it finishes building). Buttons with their own look are left alone.
static func tool_row(row: Node) -> void:
	var style_all := func() -> void:
		if not is_instance_valid(row): return
		for node: Node in row.find_children("*", "Button", true, false):
			var button := node as Button
			if button is CheckBox or button is CheckButton or button is OptionButton: continue
			if button.has_meta("keep_style") or button.has_meta("tool_styled"): continue
			if button.has_theme_stylebox_override("normal"): continue
			tool(button); button.set_meta("tool_styled", true)
	style_all.call_deferred()


static func _tool_margins(box: StyleBoxFlat) -> void:
	box.content_margin_left = 11.0; box.content_margin_right = 11.0
	box.content_margin_top = 5.0; box.content_margin_bottom = 5.0


static func panel(fill: Color, border: Color = EDGE, radius: int = 7) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12.0
	box.content_margin_right = 12.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box


# A raised instrument surface. Keep button/input surfaces flatter so they do not
# compete with the windows they belong to. Shadows never enlarge input geometry.
static func surface(fill: Color = SURFACE, accent: Color = EDGE, radius: int = 10) -> StyleBoxFlat:
	var box: StyleBoxFlat = panel(fill, accent, radius)
	box.shadow_color = Color(0.0, 0.015, 0.025, 0.28)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	box.border_width_top = 2
	return box


static func apply_to(target: Theme, light: bool = false) -> void:
	target.default_font = preload("res://assets/fonts/interface_regular.tres")
	var surface_color := Color("f6f8f7") if light else SURFACE
	var border := Color("7a9097") if light else EDGE
	var text := Color("223840") if light else Color("e7eff2")
	var muted := Color("53666d") if light else Color("9eafb8")
	var accent := Color("245e6d") if light else ACCENT
	var idle := Color("edf2f1") if light else Color("1f2b34")
	var hover := Color("e0ecec") if light else Color("273843")
	var selected := Color("d2e6e8") if light else Color("1f3d47")
	var disabled := Color("e9eeee") if light else Color("1b252c")
	var input := Color("ffffff") if light else Color("101a21")
	for control_type: String in ["Label", "Button", "OptionButton", "MenuButton", "LineEdit", "ItemList", "PopupMenu"]:
		target.set_color("font_color", control_type, text)
	target.set_color("default_color", "RichTextLabel", text)
	for control_type: String in ["Button", "OptionButton", "MenuButton"]:
		target.set_stylebox("normal", control_type, panel(idle, border))
		target.set_stylebox("hover", control_type, panel(hover, accent))
		var pressed: StyleBoxFlat = panel(selected, accent)
		pressed.border_width_left = 3
		target.set_stylebox("pressed", control_type, pressed)
		target.set_stylebox("hover_pressed", control_type, pressed)
		target.set_stylebox("disabled", control_type, panel(disabled, border))
		var focus: StyleBoxFlat = panel(Color.TRANSPARENT, text)
		focus.set_border_width_all(2)
		target.set_stylebox("focus", control_type, focus)
		target.set_color("font_disabled_color", control_type, muted)
		for state: String in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			target.set_color(state, control_type, text)
	target.set_stylebox("normal", "LineEdit", panel(input, border))
	var input_focus: StyleBoxFlat = panel(Color.TRANSPARENT, accent)
	input_focus.set_border_width_all(2)
	target.set_stylebox("focus", "LineEdit", input_focus)
	target.set_stylebox("read_only", "LineEdit", panel(disabled, border))
	target.set_color("font_uneditable_color", "LineEdit", muted)
	target.set_color("font_placeholder_color", "LineEdit", muted)
	target.set_color("caret_color", "LineEdit", text)
	target.set_color("selection_color", "LineEdit", selected)
	target.set_color("font_selected_color", "LineEdit", text)
	target.set_stylebox("panel", "PopupMenu", panel(surface_color, border))
	target.set_stylebox("hover", "PopupMenu", panel(selected, accent))
	target.set_color("font_hover_color", "PopupMenu", text)
	target.set_color("font_disabled_color", "PopupMenu", muted)
	target.set_stylebox("panel", "TooltipPanel", panel(surface_color, border))
	target.set_font_size("font_size", "TooltipLabel", 14)
	target.set_color("font_color", "TooltipLabel", text)
	# Plain containers (bars, docks, canvas frames) are a quiet layer: a hairline
	# and no shadow. Depth is reserved for real windows and dialogs, so the
	# terminal reads as one surface with tools floating above it.
	var layer: StyleBoxFlat = panel(surface_color if light else Color("15212a"), border if light else Color("27363f"), 9)
	target.set_stylebox("panel", "PanelContainer", layer)

	# Popups and trace selections belong to the same instrument family.
	target.set_stylebox("panel", "AcceptDialog", panel(surface_color, border, 8))
	var dialog_border: StyleBoxFlat = panel(surface_color, accent, 8)
	dialog_border.expand_margin_top = 32
	dialog_border.content_margin_top = 32
	dialog_border.shadow_size = 8
	dialog_border.shadow_color = Color(0, 0, 0, 0.25)
	target.set_stylebox("embedded_border", "Window", dialog_border)
	var unfocused_border: StyleBoxFlat = dialog_border.duplicate()
	unfocused_border.border_color = border
	target.set_stylebox("embedded_unfocused_border", "Window", unfocused_border)
	target.set_color("title_color", "Window", text)
	target.set_color("title_unfocused_color", "Window", muted)
	target.set_font_size("title_font_size", "Window", 18)
	target.set_stylebox("panel", "ItemList", panel(input, border))
	for selection: String in ["selected", "selected_focus"]:
		var selection_box: StyleBoxFlat = panel(selected, accent, 3)
		selection_box.border_width_left = 3
		target.set_stylebox(selection, "ItemList", selection_box)
	var list_focus: StyleBoxFlat = panel(Color.TRANSPARENT, text, 3)
	list_focus.set_border_width_all(2)
	target.set_stylebox("focus", "ItemList", list_focus)
	if not light:
		# Machine canvases are part of the terminal's own field (see TechnicalBackdrop):
		# deep blue-black with a faint cyan grid, not a neutral grey sheet.
		var field := StyleBoxFlat.new()
		field.bg_color = Color("0a131a")
		for state: String in ["panel", "panel_focus"]: target.set_stylebox(state, "GraphEdit", field)
		target.set_color("grid_minor", "GraphEdit", Color(0.56, 0.83, 0.86, 0.07))
		target.set_color("grid_major", "GraphEdit", Color(0.56, 0.83, 0.86, 0.16))
		target.set_color("selection_fill", "GraphEdit", Color(0.56, 0.83, 0.86, 0.10))
		target.set_color("selection_stroke", "GraphEdit", Color(0.56, 0.83, 0.86, 0.6))
	target.set_color("font_selected_color", "ItemList", text)
	target.set_color("font_disabled_color", "ItemList", muted)
	var scroll_colors: Dictionary = {"scroll": input, "grabber": border, "grabber_highlight": muted, "grabber_pressed": accent}
	for control: String in ["VScrollBar", "HScrollBar"]:
		for state: String in scroll_colors:
			var bar: StyleBoxFlat = panel(scroll_colors[state], Color.TRANSPARENT, 4)
			bar.content_margin_left = 3
			bar.content_margin_right = 3
			bar.content_margin_top = 3
			bar.content_margin_bottom = 3
			target.set_stylebox(state, control, bar)
