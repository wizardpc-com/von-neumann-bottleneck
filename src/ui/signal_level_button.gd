class_name SignalLevelButton
extends CheckButton

const SignalNotationType = preload("res://src/ui/signal_notation.gd")

const LOW := Color("ff6b7d")
const HIGH := Color("67e8a5")


func _ready() -> void:
	custom_minimum_size = Vector2(76.0, 42.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_icon := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	for icon_name: String in ["checked", "unchecked", "checked_disabled", "unchecked_disabled", "checked_mirrored", "unchecked_mirrored", "checked_disabled_mirrored", "unchecked_disabled_mirrored"]:
		add_theme_icon_override(icon_name, empty_icon)
	for style_name: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(color_name, Color.TRANSPARENT)
	toggled.connect(func(_high: bool) -> void: queue_redraw())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1a2e39") if is_hovered() else Color("101e29")
	box.border_color = Color("50d5ff") if has_focus() else Color("405668")
	box.set_border_width_all(2 if has_focus() else 1)
	box.set_corner_radius_all(5)
	draw_style_box(box, Rect2(Vector2.ONE, size - Vector2.ONE * 2.0))
	var font: Font = get_theme_default_font()
	var rect := Rect2(8.0, (size.y - 30.0) * 0.5, 32.0, 30.0)
	var color: Color = SignalNotationType.width_color(1)
	var cell := StyleBoxFlat.new()
	cell.bg_color = color if button_pressed else Color("172638")
	cell.border_color = color
	cell.set_border_width_all(1)
	cell.set_corner_radius_all(3)
	draw_style_box(cell, rect)
	var digit: String = str(int(button_pressed))
	var offset := Vector2(-font.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 21).x * 0.5, (font.get_ascent(21) - font.get_descent(21)) * 0.5)
	draw_string(font, rect.get_center() + offset, digit, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 21, Color("101c29") if button_pressed else Color("e9f0fa"))
	# The arrows indicate a toggle, not a second bit cell.
	var cy: float = size.y * 0.5
	var hint_color := Color("a9bacb")
	draw_line(Vector2(49, cy - 4), Vector2(65, cy - 4), hint_color, 1.5, true)
	draw_polyline(PackedVector2Array([Vector2(61, cy - 8), Vector2(65, cy - 4), Vector2(61, cy)]), hint_color, 1.5, true)
	draw_line(Vector2(65, cy + 5), Vector2(49, cy + 5), hint_color, 1.5, true)
	draw_polyline(PackedVector2Array([Vector2(53, cy + 1), Vector2(49, cy + 5), Vector2(53, cy + 9)]), hint_color, 1.5, true)
