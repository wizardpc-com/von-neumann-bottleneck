class_name ComponentPaletteItem
extends Control

signal placement_requested(template_key: String)

const SURFACE := Color("101725")
const SURFACE_HOVER := Color("1b2a40")
const BORDER := Color("354866")
const ACCENT := Color("50d5ff")
const TEXT := Color("e9f0fa")
const MUTED := Color("91a0b9")
const PREVIEW_RECT := Rect2(Vector2(10.0, 8.0), Vector2(64.0, 42.0))

var template_key: String = ""
var component_kind: StringName = &""
var label_text: String = ""
var width_hint: int = 1
var placement_enabled: bool = true
var armed: bool = false
var hovered: bool = false
var component_preview: Control


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


func set_component_preview(preview: Control) -> void:
	if component_preview != null and is_instance_valid(component_preview):
		component_preview.queue_free()
	component_preview = preview
	if component_preview == null:
		return
	component_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(component_preview)
	_layout_component_preview()
	call_deferred("_layout_component_preview")


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
	var preview := duplicate() as ComponentPaletteItem
	preview.placement_enabled = false
	preview.armed = true
	preview.hovered = true
	preview.size = Vector2(188.0, 58.0)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
	set_drag_preview(preview)
	return {"type": &"circuit_component_template", "template_key": template_key}


func _draw() -> void:
	var fill: Color = SURFACE_HOVER if hovered else SURFACE
	var border: Color = ACCENT if armed else BORDER
	draw_style_box(_stylebox(fill, border, 8.0, 2.0 if armed else 1.0), Rect2(Vector2.ZERO, size))
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(82.0, 27.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 92.0, 15, TEXT)
	var detail: String = "%d-bit" % width_hint if width_hint > 1 else String(component_kind).to_upper()
	draw_string(font, Vector2(82.0, 46.0), detail, HORIZONTAL_ALIGNMENT_LEFT, size.x - 92.0, 11, MUTED)


func _layout_component_preview() -> void:
	if component_preview == null or not is_instance_valid(component_preview):
		return
	var visual_size: Vector2 = component_preview.size
	if visual_size.x <= 0.0 or visual_size.y <= 0.0:
		visual_size = component_preview.custom_minimum_size
	if visual_size.x <= 0.0 or visual_size.y <= 0.0:
		return
	var preview_scale: float = minf(
		PREVIEW_RECT.size.x / visual_size.x,
		PREVIEW_RECT.size.y / visual_size.y
	)
	component_preview.scale = Vector2.ONE * preview_scale
	component_preview.position = PREVIEW_RECT.position + (
		PREVIEW_RECT.size - visual_size * preview_scale
	) * 0.5


func _stylebox(fill: Color, border: Color, radius: float, border_width: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(int(border_width))
	box.set_corner_radius_all(int(radius))
	return box
