class_name InstrumentTheme
extends RefCounted

const SURFACE := Color("111d29")
const EDGE := Color("354b5a")
const ACCENT := Color("50d5ff")


static func primary(button: Button, accent: Color = ACCENT) -> void:
	button.add_theme_stylebox_override("normal", panel(accent, accent))
	button.add_theme_stylebox_override("hover", panel(accent.lightened(0.16), Color.WHITE))
	button.add_theme_stylebox_override("pressed", panel(accent.darkened(0.16), accent))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color("071823"))


static func panel(fill: Color, border: Color = EDGE, radius: int = 5) -> StyleBoxFlat:
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


static func apply_to(target: Theme) -> void:
	target.default_font = preload("res://assets/fonts/interface_regular.tres")
	for control_type: String in ["Button", "OptionButton", "MenuButton"]:
		target.set_stylebox("normal", control_type, panel(Color("1b2b37")))
		target.set_stylebox("hover", control_type, panel(Color("233d4b"), ACCENT))
		target.set_stylebox("pressed", control_type, panel(Color("153343"), ACCENT))
		target.set_stylebox("disabled", control_type, panel(Color("121d26"), Color("2b3945")))
		var focus: StyleBoxFlat = panel(Color.TRANSPARENT, ACCENT)
		focus.set_border_width_all(2)
		target.set_stylebox("focus", control_type, focus)
		target.set_color("font_disabled_color", control_type, Color("80919c"))
		target.set_color("font_hover_color", control_type, Color("ffffff"))
		target.set_color("font_pressed_color", control_type, Color("ffffff"))
	target.set_stylebox("normal", "LineEdit", panel(Color("0a141e")))
	target.set_stylebox("focus", "LineEdit", panel(Color("0e202c"), ACCENT))
	target.set_stylebox("panel", "PopupMenu", panel(SURFACE))
	target.set_stylebox("panel", "TooltipPanel", panel(Color("0b1822"), Color("526977")))
	target.set_font_size("font_size", "TooltipLabel", 14)
	target.set_color("font_color", "TooltipLabel", Color("e9f0fa"))
	var window: StyleBoxFlat = panel(SURFACE)
	window.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	window.shadow_size = 12
	window.shadow_offset = Vector2(0.0, 5.0)
	target.set_stylebox("panel", "PanelContainer", window)

	# Popups and trace selections belong to the same instrument family.
	target.set_stylebox("panel","AcceptDialog",panel(SURFACE,EDGE,8))
	var dialog_border: StyleBoxFlat = panel(SURFACE,ACCENT,8)
	dialog_border.expand_margin_top=32; dialog_border.content_margin_top=32; dialog_border.shadow_size=14; dialog_border.shadow_color=Color(0,0,0,0.35)
	target.set_stylebox("embedded_border","Window",dialog_border)
	target.set_stylebox("embedded_unfocused_border","Window",dialog_border)
	target.set_color("title_color","Window",Color("e9f0fa"))
	target.set_font_size("title_font_size","Window",18)
	target.set_stylebox("panel","ItemList",panel(Color("0b1722")))
	for selection: String in ["selected","selected_focus"]:
		target.set_stylebox(selection,"ItemList",panel(Color("193a4c"),ACCENT,3))
	target.set_color("font_selected_color","ItemList",Color("ffffff"))
	var scroll_colors: Dictionary = {"scroll":Color("101d29"),"grabber":Color("3b596b"),"grabber_highlight":Color("508094"),"grabber_pressed":ACCENT}
	for control: String in ["VScrollBar","HScrollBar"]:
		for state: String in scroll_colors:
			var bar: StyleBoxFlat = panel(scroll_colors[state],Color.TRANSPARENT,4)
			bar.content_margin_left=3; bar.content_margin_right=3
			bar.content_margin_top=3; bar.content_margin_bottom=3
			target.set_stylebox(state,control,bar)
