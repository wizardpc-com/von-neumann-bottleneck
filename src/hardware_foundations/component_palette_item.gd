class_name ComponentPaletteItem
extends Control

signal placement_requested(template_key: String)

const SURFACE := Color("111e29")
const SURFACE_HOVER := Color("1b3441")
const BORDER := Color("354866")
const ACCENT := Color("7fcbd6")
const TEXT := Color("e2ebef")
const MUTED := Color("8fa3ad")
## The same full node is uniformly scaled; tall modules retain all of their rows.
const NAME_HEIGHT := 24.0
const PREVIEW_SCALE := 0.75
const PREVIEW_MAX_WIDTH := 224.0
const PAD := 8.0

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
	custom_minimum_size = Vector2(240.0, NAME_HEIGHT + PAD * 2.0 + 40.0)
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
	# The whole card stays one click/drag target.
	component_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node: Node in component_preview.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# The card is a patch of canvas: same ground the component will sit on.
	var fill: Color = SURFACE_HOVER if hovered else (Color("10232e") if armed else Color("0b1720"))
	draw_style_box(_stylebox(fill, ACCENT if armed else Color("1d3140"), 8.0, 1.0), Rect2(Vector2.ZERO, size))


func _build_labels() -> void:
	# Labels use actual font metrics and ellipsis at narrow widths. Ignore mouse
	# input so the whole card remains one click/drag target.
	if has_node("CardText"):
		return
	var box := VBoxContainer.new()
	box.name = "CardText"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	box.offset_left = PAD + 2.0
	box.offset_right = -PAD
	box.offset_top = PAD - 2.0
	box.offset_bottom = PAD - 2.0 + NAME_HEIGHT
	var label := Label.new()
	label.text = label_text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TEXT)
	box.add_child(label)


func _layout_component_preview() -> void:
	if component_preview == null or not is_instance_valid(component_preview):
		return
	var visual_size: Vector2 = component_preview.size
	if visual_size.x <= 0.0 or visual_size.y <= 0.0:
		visual_size = component_preview.custom_minimum_size
	if visual_size.x <= 0.0 or visual_size.y <= 0.0:
		return
	var preview_scale: float = minf(PREVIEW_SCALE, PREVIEW_MAX_WIDTH / visual_size.x)
	var drawn: Vector2 = visual_size * preview_scale
	custom_minimum_size.y = NAME_HEIGHT + PAD * 2.0 + drawn.y
	component_preview.scale = Vector2.ONE * preview_scale
	var area := Rect2(0.0, PAD + NAME_HEIGHT, maxf(size.x, custom_minimum_size.x), maxf(size.y, custom_minimum_size.y) - PAD * 2.0 - NAME_HEIGHT)
	component_preview.position = area.position + (area.size - drawn) * 0.5


func _stylebox(fill: Color, border: Color, radius: float, border_width: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(int(border_width))
	box.set_corner_radius_all(int(radius))
	return box
