class_name ComponentPaletteItem
extends Control

signal placement_requested(template_key: String)

const SURFACE := Color("111e29")
const SURFACE_HOVER := Color("1b3441")
const BORDER := Color("354866")
const ACCENT := Color("50d5ff")
const TEXT := Color("e9f0fa")
const MUTED := Color("91a0b9")
const PREVIEW_RECT := Rect2(Vector2(8.0, 17.0), Vector2(94.0, 54.0))

var template_key: String = ""
var component_kind: StringName = &""
var label_text: String = ""
var width_hint: int = 1
var port_widths: Array[int] = [1]
var purpose_text: String = ""
var ports_text: String = ""
var placement_enabled: bool = true
var armed: bool = false
var hovered: bool = false
var component_preview: Control
var _drag_candidate: bool = false
var _press_position := Vector2.ZERO


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	mouse_entered.connect(func() -> void: hovered = true; queue_redraw())
	mouse_exited.connect(func() -> void: hovered = false; queue_redraw())
	resized.connect(_layout_component_preview)
	_build_labels()
	queue_redraw()


func configure(key: String, kind: StringName, label: String, widest_port: int = 1,
		purpose: String = "", ports: String = "") -> void:
	template_key = key
	component_kind = kind
	label_text = label
	width_hint = maxi(1, widest_port)
	port_widths.assign([width_hint])
	purpose_text = purpose
	ports_text = ports
	custom_minimum_size = Vector2(280.0, 108.0)
	tooltip_text = label
	queue_redraw()

func set_port_widths(widths: Array) -> void:
	port_widths.clear()
	for width: int in widths:
		if width not in port_widths: port_widths.append(width)
	port_widths.sort()
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
		_drag_candidate = true
		_press_position = mouse.position
		placement_requested.emit(template_key)


func _input(event: InputEvent) -> void:
	if not _drag_candidate:
		return
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index == MOUSE_BUTTON_RIGHT:
			_drag_candidate = false
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_drag_candidate = false
		return
	var motion := event as InputEventMouseMotion
	if motion == null or motion.button_mask != 0:
		return
	# Some native Mac motion events omit the button mask while Input still
	# reports the held press. Keep the normal Godot drag/drop path on that stream.
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not placement_enabled or not is_visible_in_tree():
		_drag_candidate = false
		return
	var local_position: Vector2 = get_global_transform().affine_inverse() * motion.position
	if local_position.distance_to(_press_position) >= 8.0:
		_drag_candidate = false
		force_drag(_drag_payload(), null)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_DRAG_BEGIN, NOTIFICATION_DRAG_END]:
		_drag_candidate = false


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not placement_enabled or template_key.is_empty():
		return null
	_drag_candidate = false
	# The canvas owns the single snapped, full-size component ghost. A second
	# card-sized drag preview obscures the actual placement and its ports.
	return _drag_payload()


func _drag_payload() -> Dictionary:
	return {"type": &"circuit_component_template", "template_key": template_key}



func _draw() -> void:
	var fill: Color = SURFACE_HOVER if hovered else SURFACE
	var border: Color = ACCENT if armed else BORDER
	draw_style_box(_stylebox(fill, border, 5.0, 2.0 if armed else 1.0), Rect2(Vector2.ZERO, size))
	draw_style_box(_stylebox(Color("0b1720"), Color("274552"), 5, 1), Rect2(6,8,98,size.y-16))
	var slot_width: float = 94.0 / maxi(1,port_widths.size())
	var notation = preload("res://src/ui/signal_notation.gd")
	for index: int in range(port_widths.size()):
		var width: int = port_widths[index]
		var caption: String = notation.width_text(width)
		var font: Font = get_theme_default_font()
		var x: float = 8+index*slot_width+(slot_width-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)*0.5
		draw_string(font,Vector2(x,size.y-17),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,notation.width_color(width))
	if armed:
		draw_rect(Rect2(0,9,3,size.y-18),ACCENT)


func _build_labels() -> void:
	# Labels use actual font metrics and ellipsis at narrow widths. Ignore mouse
	# input so the whole card remains one click/drag target.
	if has_node("CardText"):
		return
	var box := VBoxContainer.new()
	box.name = "CardText"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 116.0
	box.offset_right = -12.0
	box.offset_top = 10.0
	box.offset_bottom = -10.0
	box.add_theme_constant_override("separation", 3)
	var lines: Array[String] = [label_text, purpose_text, ports_text]
	for index: int in range(lines.size()):
		var label := Label.new()
		label.text = lines[index]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if index == 1:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.max_lines_visible = 2
		label.add_theme_font_size_override("font_size", 16 if index == 0 else 13)
		label.add_theme_color_override("font_color", TEXT if index == 0 else MUTED)
		box.add_child(label)


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
