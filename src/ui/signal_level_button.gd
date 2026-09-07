class_name SignalLevelButton
extends CheckButton

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
	var signal_color: Color = HIGH if button_pressed else LOW
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1a2e39") if is_hovered() else Color("101e29")
	box.border_color = Color("50d5ff") if has_focus() else Color("405668")
	box.set_border_width_all(2 if has_focus() else 1)
	box.set_corner_radius_all(5)
	draw_style_box(box, Rect2(Vector2.ONE, size - Vector2.ONE * 2.0))
	var center_y: float = size.y * 0.5
	var points := PackedVector2Array([
		Vector2(17.0, center_y - 10.0), Vector2(17.0, center_y + 10.0), Vector2(33.0, center_y),
	])
	if button_pressed:
		draw_colored_polygon(points, signal_color)
	points.append(points[0])
	draw_polyline(points, signal_color, 2.0, true)
	draw_line(Vector2(34.0, center_y), Vector2(42.0, center_y), signal_color, 2.0, true)
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(51.0, center_y + (font.get_ascent(20) - font.get_descent(20)) * 0.5), str(int(button_pressed)), HORIZONTAL_ALIGNMENT_LEFT, 22.0, 20, Color("e9f0fa"))
