extends Control
signal field_dropped(source: int, target: int)
signal drag_started
signal drag_released(source: int, at: Vector2, payload: Dictionary)
var text: String = ""
var payload: Dictionary = {}
var dragging_field: bool = false
var field_id: int = 0
var drag_candidate: bool = false
var press_position := Vector2.ZERO
func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color=Color("192b3b")
	style.border_color=get_theme_color("font_color") if get_rect().has_point(get_local_mouse_position()) else Color("354866")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	draw_style_box(style,Rect2(Vector2.ZERO,size))
	draw_string(get_theme_default_font(),Vector2(12,size.y/2+6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,get_theme_color("font_color"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_candidate = true
		press_position = event.position
func _input(event: InputEvent) -> void:
	if dragging_field and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging_field=false
		# Native motion can start a drag on the last motion before release.
		# Let normal Godot drop run first, then resolve the same transaction once.
		drag_released.emit(field_id,event.position,payload)
	if not drag_candidate: return
	if event is InputEventMouseButton and (not event.pressed or event.button_index == MOUSE_BUTTON_RIGHT):
		drag_candidate = false
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		drag_candidate = false
		return
	if event is InputEventMouseMotion and event.button_mask == 0:
		# Match the existing palette's native Mac stream: held Input state can
		# precede motion.button_mask. Use Godot drag/drop, not a second editor.
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or not is_visible_in_tree():
			drag_candidate = false
			return
		var local: Vector2 = get_global_transform().affine_inverse()*event.position
		if local.distance_to(press_position)>=8:
			drag_candidate = false
			drag_started.emit()
			payload={"layout_field":field_id,"committed":false}
			dragging_field=true
			force_drag(payload,null)
			get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_DRAG_BEGIN,NOTIFICATION_DRAG_END]: drag_candidate=false
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: dragging_field=false
func _get_drag_data(_at: Vector2) -> Variant:
	drag_candidate=false
	drag_started.emit()
	payload={"layout_field":field_id,"committed":false}
	dragging_field=true
	var preview := Label.new()
	preview.text = text
	preview.add_theme_color_override("font_color",get_theme_color("font_color"))
	set_drag_preview(preview)
	return payload
func _can_drop_data(_at: Vector2, value: Variant) -> bool:
	return value is Dictionary and value.get("layout_field") is int and value.layout_field in range(4)
func _drop_data(_at: Vector2, value: Variant) -> void:
	if bool(value.get("committed",false)): return
	value["committed"]=true
	field_dropped.emit(int(value.layout_field),field_id)
