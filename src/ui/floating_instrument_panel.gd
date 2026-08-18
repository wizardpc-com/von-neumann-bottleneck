class_name FloatingInstrumentPanel
extends PanelContainer

signal close_requested(instrument_id: StringName)
signal focus_requested(instrument_id: StringName)
signal minimized_changed(instrument_id: StringName, minimized: bool)

var instrument_id: StringName = &""
var content_host: MarginContainer
var minimized: bool = false

var _footer: HBoxContainer
var _minimize_button: Button
var _expanded_size: Vector2 = Vector2.ZERO
var _expanded_minimum_size: Vector2 = Vector2.ZERO

var _dragging: bool = false
var _resizing: bool = false
var _pointer_origin: Vector2 = Vector2.ZERO
var _panel_origin: Vector2 = Vector2.ZERO
var _size_origin: Vector2 = Vector2.ZERO


func setup(id: StringName, title_text: String) -> void:
	instrument_id = id
	mouse_filter = Control.MOUSE_FILTER_STOP
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 38.0
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.gui_input.connect(_on_header_input)
	root.add_child(header)
	var title := Label.new()
	title.text = "⋮⋮  %s" % title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	_minimize_button = Button.new()
	_minimize_button.text = "—"
	_minimize_button.tooltip_text = Localization.text(&"window.minimize.tooltip")
	_minimize_button.custom_minimum_size = Vector2(38.0, 32.0)
	_minimize_button.pressed.connect(toggle_minimized)
	header.add_child(_minimize_button)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = Localization.text(&"window.close.tooltip")
	close_button.custom_minimum_size = Vector2(38.0, 32.0)
	close_button.pressed.connect(func() -> void: close_requested.emit(instrument_id))
	header.add_child(close_button)

	content_host = MarginContainer.new()
	content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_host.add_theme_constant_override("margin_left", 4)
	content_host.add_theme_constant_override("margin_right", 4)
	content_host.add_theme_constant_override("margin_bottom", 2)
	root.add_child(content_host)

	_footer = HBoxContainer.new()
	_footer.custom_minimum_size.y = 22.0
	root.add_child(_footer)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(spacer)
	var resize_grip := Label.new()
	resize_grip.text = "◢"
	resize_grip.tooltip_text = Localization.text(&"window.resize.tooltip")
	resize_grip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resize_grip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resize_grip.custom_minimum_size = Vector2(30.0, 22.0)
	resize_grip.mouse_filter = Control.MOUSE_FILTER_STOP
	resize_grip.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	resize_grip.gui_input.connect(_on_resize_input)
	_footer.add_child(resize_grip)


func set_content(content: Control) -> void:
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host.add_child(content)


func show_instrument() -> void:
	visible = true
	focus_requested.emit(instrument_id)


func toggle_minimized() -> void:
	set_minimized(not minimized)


func set_minimized(value: bool) -> void:
	if minimized == value:
		return
	minimized = value
	if minimized:
		_expanded_size = size
		_expanded_minimum_size = custom_minimum_size
		content_host.hide()
		_footer.hide()
		custom_minimum_size = Vector2(minf(size.x, 220.0), 46.0)
		size = Vector2(size.x, 46.0)
		_minimize_button.text = "□"
		_minimize_button.tooltip_text = Localization.text(&"window.restore.tooltip")
	else:
		custom_minimum_size = _expanded_minimum_size if _expanded_minimum_size != Vector2.ZERO else Vector2(360.0, 250.0)
		content_host.show()
		_footer.show()
		size = _expanded_size if _expanded_size != Vector2.ZERO else custom_minimum_size
		_minimize_button.text = "—"
		_minimize_button.tooltip_text = Localization.text(&"window.minimize.tooltip")
		_clamp_position()
	minimized_changed.emit(instrument_id, minimized)


func move_by(delta: Vector2) -> void:
	position += delta
	_clamp_position()


func resize_by(delta: Vector2) -> void:
	var parent_control := get_parent() as Control
	var maximum := Vector2(1600.0, 900.0)
	if parent_control != null:
		maximum = parent_control.size - position
	size = Vector2(
		clampf(size.x + delta.x, custom_minimum_size.x, maxf(custom_minimum_size.x, maximum.x)),
		clampf(size.y + delta.y, custom_minimum_size.y, maxf(custom_minimum_size.y, maximum.y))
	)


func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.double_click:
			toggle_minimized()
			_dragging = false
			accept_event()
			return
		_dragging = event.pressed
		if _dragging:
			_pointer_origin = get_global_mouse_position()
			_panel_origin = position
			focus_requested.emit(instrument_id)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		position = _panel_origin + get_global_mouse_position() - _pointer_origin
		_clamp_position()
		accept_event()


func _on_resize_input(event: InputEvent) -> void:
	if minimized:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = event.pressed
		if _resizing:
			_pointer_origin = get_global_mouse_position()
			_size_origin = size
			focus_requested.emit(instrument_id)
		accept_event()
	elif event is InputEventMouseMotion and _resizing:
		var delta: Vector2 = get_global_mouse_position() - _pointer_origin
		size = _size_origin
		resize_by(delta)
		accept_event()


func _clamp_position() -> void:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var visible_header_width: float = minf(size.x, 170.0)
	position.x = clampf(position.x, 0.0, maxf(0.0, parent_control.size.x - visible_header_width))
	position.y = clampf(position.y, 0.0, maxf(0.0, parent_control.size.y - 48.0))
