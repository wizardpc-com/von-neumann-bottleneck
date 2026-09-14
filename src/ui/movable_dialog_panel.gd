extends PanelContainer
## Title-only dragging for modal reading/settings surfaces. No saved game state.
var desired_size := Vector2(760, 780)
var _moved: bool = false
var _dragging: bool = false
var _pointer_origin := Vector2.ZERO
var _panel_origin := Vector2.ZERO

func setup(handle: Control, preferred: Vector2) -> void:
	desired_size = preferred
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	handle.tooltip_text = get_node("/root/Localization").text(&"window.drag.tooltip")
	handle.gui_input.connect(_on_title_input)
	visibility_changed.connect(func() -> void: _dragging = false)
	get_parent().resized.connect(fit_to_bounds)
	call_deferred("fit_to_bounds")

func fit_to_bounds() -> void:
	var bounds: Control = get_parent() as Control
	if bounds == null or bounds.size.x <= 0 or bounds.size.y <= 0: return
	var available := (bounds.size - Vector2(32, 32)).max(Vector2.ONE)
	custom_minimum_size = desired_size.min(available)
	size = custom_minimum_size
	if not _moved: position = (bounds.size - size) * 0.5
	_clamp_position()

func _clamp_position() -> void:
	var bounds: Control = get_parent() as Control
	position = position.clamp(Vector2(16, 16), (bounds.size - size - Vector2(16, 16)).max(Vector2(16, 16)))

func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_pointer_origin = _pointer_in_parent(event.global_position)
			_panel_origin = position
		get_viewport().set_input_as_handled()

func _pointer_in_parent(point: Vector2) -> Vector2:
	return (get_parent() as Control).get_global_transform_with_canvas().affine_inverse() * point

func _input(event: InputEvent) -> void:
	if not _dragging: return
	if not is_visible_in_tree():
		_dragging = false
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (not event.pressed or event.button_index == MOUSE_BUTTON_RIGHT):
		_dragging = false
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		_moved = true
		position = _panel_origin + _pointer_in_parent(event.global_position) - _pointer_origin
		_clamp_position()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_dragging = false
