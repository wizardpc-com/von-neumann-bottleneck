class_name ComponentPaletteItem
extends Control

signal placement_requested(template_key: String)

const SURFACE := Color("101725")
const SURFACE_HOVER := Color("1b2a40")
const BORDER := Color("354866")
const SYMBOL := Color("aebbd0")
const ACCENT := Color("50d5ff")
const TEXT := Color("e9f0fa")
const MUTED := Color("91a0b9")

var template_key: String = ""
var component_kind: StringName = &""
var label_text: String = ""
var width_hint: int = 1
var placement_enabled: bool = true
var armed: bool = false
var hovered: bool = false


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	queue_redraw()


func configure(key: String, kind: StringName, label: String, widest_port: int = 1) -> void:
	template_key = key
	component_kind = kind
	label_text = label
	width_hint = maxi(1, widest_port)
	custom_minimum_size = Vector2(188.0, 58.0)
	tooltip_text = label
	queue_redraw()


func set_armed(value: bool) -> void:
	if armed == value:
		return
	armed = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed and placement_enabled:
		placement_requested.emit(template_key)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not placement_enabled or template_key.is_empty():
		return null
	var preview := Label.new()
	preview.text = "  %s  " % label_text
	preview.custom_minimum_size = Vector2(188.0, 58.0)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_color_override("font_color", TEXT)
	preview.add_theme_stylebox_override("normal", _stylebox(SURFACE_HOVER, ACCENT, 8.0, 2.0))
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
	set_drag_preview(preview)
	return {"type": &"circuit_component_template", "template_key": template_key}


func _draw() -> void:
	var fill: Color = SURFACE_HOVER if hovered else SURFACE
	var border: Color = ACCENT if armed else BORDER
	draw_style_box(_stylebox(fill, border, 8.0, 2.0 if armed else 1.0), Rect2(Vector2.ZERO, size))
	_draw_icon(Rect2(Vector2(10.0, 8.0), Vector2(64.0, 42.0)), border if armed else SYMBOL)
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(82.0, 27.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 92.0, 15, TEXT)
	var detail: String = "%d-bit" % width_hint if width_hint > 1 else String(component_kind).to_upper()
	draw_string(font, Vector2(82.0, 46.0), detail, HORIZONTAL_ALIGNMENT_LEFT, size.x - 92.0, 11, MUTED)


func _draw_icon(rect: Rect2, color: Color) -> void:
	var left: float = rect.position.x + 8.0
	var right: float = rect.end.x - 7.0
	var top: float = rect.position.y + 6.0
	var bottom: float = rect.end.y - 6.0
	var center := Vector2((left + right) * 0.5, (top + bottom) * 0.5)
	match component_kind:
		&"and":
			draw_line(Vector2(left + 9.0, top), Vector2(center.x, top), color, 2.5, true)
			draw_line(Vector2(left + 9.0, top), Vector2(left + 9.0, bottom), color, 2.5, true)
			draw_line(Vector2(left + 9.0, bottom), Vector2(center.x, bottom), color, 2.5, true)
			draw_arc(center, (bottom - top) * 0.5, -PI * 0.5, PI * 0.5, 18, color, 2.5, true)
			_draw_leads(rect, color)
		&"or", &"nor", &"xor":
			_draw_or_icon(rect, color, component_kind == &"xor", component_kind == &"nor")
		&"not":
			var triangle := PackedVector2Array([
				Vector2(left + 8.0, top), Vector2(left + 8.0, bottom),
				Vector2(right - 11.0, center.y), Vector2(left + 8.0, top),
			])
			draw_polyline(triangle, color, 2.5, true)
			draw_circle(Vector2(right - 6.0, center.y), 4.0, SURFACE)
			draw_circle(Vector2(right - 6.0, center.y), 4.0, color, false, 2.0, true)
			draw_line(Vector2(rect.position.x, center.y), Vector2(left + 8.0, center.y), color, 2.5, true)
			draw_line(Vector2(right - 2.0, center.y), Vector2(rect.end.x, center.y), color, 2.5, true)
		_:
			draw_style_box(_stylebox(Color(SURFACE, 0.0), color, 6.0, 2.0), Rect2(Vector2(left, top), Vector2(right - left, bottom - top)))
			var abbreviation: String = String(component_kind).replace("_", " ").to_upper().substr(0, 6)
			draw_string(get_theme_default_font(), Vector2(left + 4.0, center.y + 4.0), abbreviation, HORIZONTAL_ALIGNMENT_CENTER, right - left - 8.0, 9, color)


func _draw_leads(rect: Rect2, color: Color) -> void:
	var center_y: float = rect.get_center().y
	draw_line(Vector2(rect.position.x, center_y - 10.0), Vector2(rect.position.x + 18.0, center_y - 10.0), color, 2.5, true)
	draw_line(Vector2(rect.position.x, center_y + 10.0), Vector2(rect.position.x + 18.0, center_y + 10.0), color, 2.5, true)
	draw_line(Vector2(rect.end.x - 11.0, center_y), Vector2(rect.end.x, center_y), color, 2.5, true)


func _draw_or_icon(rect: Rect2, color: Color, xor_gate: bool, inverted: bool) -> void:
	var left: float = rect.position.x + 13.0
	var right: float = rect.end.x - (13.0 if inverted else 7.0)
	var top: float = rect.position.y + 6.0
	var bottom: float = rect.end.y - 6.0
	var center_y: float = rect.get_center().y
	draw_polyline(_cubic(Vector2(left, top), Vector2(rect.get_center().x, top), Vector2(right - 8.0, top + 3.0), Vector2(right, center_y)), color, 2.5, true)
	draw_polyline(_cubic(Vector2(right, center_y), Vector2(right - 8.0, bottom - 3.0), Vector2(rect.get_center().x, bottom), Vector2(left, bottom)), color, 2.5, true)
	draw_polyline(_cubic(Vector2(left, top), Vector2(left + 13.0, top + 8.0), Vector2(left + 13.0, bottom - 8.0), Vector2(left, bottom)), color, 2.5, true)
	if xor_gate:
		draw_polyline(_cubic(Vector2(left - 6.0, top), Vector2(left + 7.0, top + 8.0), Vector2(left + 7.0, bottom - 8.0), Vector2(left - 6.0, bottom)), color, 2.0, true)
	_draw_leads(rect, color)
	if inverted:
		draw_circle(Vector2(right + 4.0, center_y), 4.0, SURFACE)
		draw_circle(Vector2(right + 4.0, center_y), 4.0, color, false, 2.0, true)


func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(17):
		var t: float = float(index) / 16.0
		var u: float = 1.0 - t
		points.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
	return points


func _stylebox(fill: Color, border: Color, radius: float, border_width: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(int(border_width))
	box.set_corner_radius_all(int(radius))
	return box
