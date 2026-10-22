class_name FloatingInstrumentPanel
extends PanelContainer
## One instrument window for every workbench: a quiet graphite body with a
## hairline edge and a soft drop shadow, an integrated title strip (role mark,
## title, drawn window controls) and a corner resize grip that costs no row.
## The window the player last touched is "active": its edge and title lift,
## the others recede, so stacked tools keep a clear order without glow.
## Presentation only; geometry, signals and node names are the contract.

const UiTypographyType = preload("res://src/ui/ui_typography.gd")
const Palette = preload("res://src/lab/lab_palette.gd")
const HEADER_HEIGHT := 36.0
const RADIUS := 10
const BODY := Color("141f28")
const STRIP := Color("19252f")
const EDGE := Color("2c3c47")
const TITLE_ACTIVE := Color("e6f0f3")
const TITLE_IDLE := Color("a9bac2")


## Flat icon control for the title strip. The text keeps its old glyph as the
## state ("—" fold, "□" restore, "×" close) for scripts and screen readers,
## while the icon itself is drawn so it stays crisp at any scale.
class GlyphButton extends Button:
	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(28.0, 26.0)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
			add_theme_color_override(state, Color.TRANSPARENT)
		var hover := StyleBoxFlat.new(); hover.bg_color = Color(1, 1, 1, 0.07); hover.set_corner_radius_all(6)
		var pressed := StyleBoxFlat.new(); pressed.bg_color = Color(1, 1, 1, 0.12); pressed.set_corner_radius_all(6)
		var focus := StyleBoxFlat.new(); focus.draw_center = false; focus.set_border_width_all(1)
		focus.border_color = Color("8fd3dc"); focus.set_corner_radius_all(6)
		add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		add_theme_stylebox_override("hover", hover)
		add_theme_stylebox_override("pressed", pressed)
		add_theme_stylebox_override("hover_pressed", pressed)
		add_theme_stylebox_override("focus", focus)
		mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var hovered: bool = is_hovered()
		var color := Color("e6f0f3") if hovered else Color("8fa3ad")
		if text == "×" and hovered: color = Color("e9a39c")
		var c: Vector2 = size * 0.5
		var r: float = 4.5
		match text:
			"×":
				draw_line(c + Vector2(-r, -r), c + Vector2(r, r), color, 1.6, true)
				draw_line(c + Vector2(-r, r), c + Vector2(r, -r), color, 1.6, true)
			"□":
				draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), color, false, 1.4)
			_:
				draw_line(c + Vector2(-r - 0.5, 0.5), c + Vector2(r + 0.5, 0.5), color, 1.6, true)


## Two short diagonal strokes in the corner; dragging resizes the window.
class ResizeGrip extends Control:
	func _draw() -> void:
		var color := Color("5d7684") if not is_hovered_now() else Color("8fd3dc")
		var e: Vector2 = size - Vector2(5, 5)
		for step: float in [4.0, 8.0]:
			draw_line(e + Vector2(-step, 0), e + Vector2(0, -step), color, 1.4, true)

	var _hover: bool = false
	func is_hovered_now() -> bool: return _hover
	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER: _hover = true; queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT: _hover = false; queue_redraw()

signal close_requested(instrument_id: StringName)
signal focus_requested(instrument_id: StringName)
signal minimized_changed(instrument_id: StringName, minimized: bool)
signal minimize_requested(instrument_id: StringName)

var instrument_id: StringName = &""
var content_host: MarginContainer
var minimized: bool = false
var minimizable: bool = true
var custom_minimize_action: bool = false

var _footer: Control
var _minimize_button: Button
var _title: Label
var _mark: ColorRect
var _accent: Color = Color("7fcbd6")
var _active: bool = true
var _expanded_size: Vector2 = Vector2.ZERO
var _expanded_minimum_size: Vector2 = Vector2.ZERO
var _base_minimum_size: Vector2 = Vector2.ZERO
var _edge_margin: float = 8.0

var _dragging: bool = false
var _resizing: bool = false
var _pointer_origin: Vector2 = Vector2.ZERO
var _panel_origin: Vector2 = Vector2.ZERO
var _size_origin: Vector2 = Vector2.ZERO


func setup(id: StringName, title_text: String) -> void:
	instrument_id = id
	_base_minimum_size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_accent = Color("7fd8a4") if id == &"test_bench" else Color("f0c674") if id == &"inspector" else Color("7fcbd6")
	_apply_frame()
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var header := HBoxContainer.new()
	header.name = "WindowHeader"
	header.custom_minimum_size.y = HEADER_HEIGHT
	header.add_theme_constant_override("separation", 2)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	header.tooltip_text = Localization.text(&"window.drag.tooltip")
	header.gui_input.connect(_on_header_input)
	root.add_child(header)
	var lead := Control.new(); lead.custom_minimum_size.x = 12.0; lead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(lead)
	_mark = ColorRect.new()
	_mark.color = _accent
	_mark.custom_minimum_size = Vector2(3.0, 14.0)
	_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_mark)
	var gap := Control.new(); gap.custom_minimum_size.x = 8.0; gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(gap)
	var title := Label.new()
	title.text = title_text
	title.name = "WindowTitle"
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.tooltip_text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", UiTypographyType.WINDOW_TITLE_SIZE - 2)
	title.add_theme_font_override("font", UiTypographyType.HEADING_FONT)
	title.add_theme_color_override("font_color", TITLE_ACTIVE)
	header.add_child(title)
	_title = title
	_minimize_button = GlyphButton.new()
	_minimize_button.name = "MinimizeButton"
	_minimize_button.text = "—"
	_minimize_button.tooltip_text = Localization.text(&"window.minimize.tooltip")
	_minimize_button.pressed.connect(toggle_minimized)
	header.add_child(_minimize_button)
	var close_button := GlyphButton.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.tooltip_text = Localization.text(&"window.close.tooltip")
	close_button.pressed.connect(func() -> void: close_requested.emit(instrument_id))
	header.add_child(close_button)
	var tail := Control.new(); tail.custom_minimum_size.x = 6.0; tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(tail)

	content_host = MarginContainer.new()
	content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Tight sides (scenes size their content to the old 4px gutter), a little
	# air under the title strip, and nothing ever drawn past the frame.
	content_host.add_theme_constant_override("margin_left", 8)
	content_host.add_theme_constant_override("margin_right", 6)
	content_host.add_theme_constant_override("margin_top", 8)
	content_host.add_theme_constant_override("margin_bottom", 12)
	content_host.clip_contents = true
	root.add_child(content_host)

	# The grip floats in the corner instead of taking a footer row.
	var resize_grip := ResizeGrip.new()
	resize_grip.name = "ResizeGrip"
	resize_grip.top_level = false
	resize_grip.tooltip_text = Localization.text(&"window.resize.tooltip")
	resize_grip.custom_minimum_size = Vector2(18.0, 18.0)
	resize_grip.mouse_filter = Control.MOUSE_FILTER_STOP
	resize_grip.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	resize_grip.gui_input.connect(_on_resize_input)
	# A container stretches its direct children; the grip sits on a pass-through
	# overlay so only its own corner takes the pointer.
	var overlay := Control.new(); overlay.name = "WindowOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.add_child(resize_grip)
	_footer = resize_grip
	overlay.resized.connect(_place_grip)
	_place_grip()


## The shared body: graphite, hairline edge, soft depth. The active window's
## edge takes the accent at low strength; others keep the quiet edge.
func _apply_frame() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = BODY
	box.border_color = Palette.with_alpha(Palette.ACCENT, 0.42) if _active else EDGE
	box.set_border_width_all(1)
	box.set_corner_radius_all(RADIUS)
	box.shadow_color = Color(0.0, 0.01, 0.02, 0.42 if _active else 0.3)
	box.shadow_size = 18 if _active else 12
	box.shadow_offset = Vector2(0.0, 8.0 if _active else 5.0)
	box.anti_aliasing = true
	for side: int in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]: box.set_content_margin(side, 1.0)
	add_theme_stylebox_override("panel", box)


## Called by the window itself and by scenes that focus a window in code.
func mark_active() -> void:
	var parent: Node = get_parent()
	if parent == null: return
	for sibling: Node in parent.get_children():
		if sibling is FloatingInstrumentPanel: (sibling as FloatingInstrumentPanel)._set_active(sibling == self)


func _set_active(value: bool) -> void:
	if _active == value and has_theme_stylebox_override("panel"): return
	_active = value
	_apply_frame()
	if _title != null: _title.add_theme_color_override("font_color", TITLE_ACTIVE if value else TITLE_IDLE)
	if _mark != null: _mark.color = _accent if value else Palette.with_alpha(_accent, 0.45)
	queue_redraw()


func is_active() -> bool:
	return _active


func _place_grip() -> void:
	if _footer == null: return
	var overlay: Control = _footer.get_parent() as Control
	_footer.size = _footer.custom_minimum_size
	_footer.position = overlay.size - _footer.size - Vector2(3.0, 3.0)


func _draw() -> void:
	# Title strip: a faintly lifted band with rounded top corners and a hairline.
	var strip := StyleBoxFlat.new()
	strip.bg_color = STRIP
	strip.corner_radius_top_left = RADIUS - 1; strip.corner_radius_top_right = RADIUS - 1
	strip.anti_aliasing = true
	var height: float = HEADER_HEIGHT + 1.0
	draw_style_box(strip, Rect2(Vector2(1, 1), Vector2(size.x - 2.0, height - 1.0)))
	if not minimized:
		draw_line(Vector2(1, height), Vector2(size.x - 1.0, height), Palette.with_alpha(EDGE, 1.0), 1.0)


func set_content(content: Control) -> void:
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host.add_child(content)


func should_hide_on_toggle() -> bool:
	# A toolbar click recalls a covered/minimized tool instead of hiding it unseen.
	if not visible or minimized: return false
	var siblings: Array[Node] = get_parent().get_children()
	for index: int in range(get_index()+1, siblings.size()):
		var sibling: Node = siblings[index]
		if sibling is FloatingInstrumentPanel and sibling.visible and get_global_rect().intersects(sibling.get_global_rect()):
			return false
	return true

func show_instrument() -> void:
	var newly_visible: bool = not visible
	visible = true
	if minimized: set_minimized(false)
	if newly_visible: preload("res://src/ui/ui_motion.gd").reveal(self)
	mark_active()
	focus_requested.emit(instrument_id)


func set_minimizable(value: bool) -> void:
	minimizable = value
	if not minimizable and minimized:
		set_minimized(false)
	if _minimize_button != null:
		_minimize_button.visible = minimizable


func set_custom_minimize_action(value: bool) -> void:
	custom_minimize_action = value


func set_custom_minimized_state(value: bool) -> void:
	if _minimize_button == null:
		return
	_minimize_button.text = "□" if value else "—"
	_minimize_button.tooltip_text = Localization.text(
		&"window.restore.tooltip" if value else &"window.minimize.tooltip"
	)


func toggle_minimized() -> void:
	if not minimizable:
		return
	if custom_minimize_action:
		minimize_requested.emit(instrument_id)
		return
	set_minimized(not minimized)


func set_minimized(value: bool) -> void:
	if custom_minimize_action:
		return
	if value and not minimizable:
		return
	if minimized == value:
		return
	minimized = value
	if minimized:
		_expanded_size = size
		_expanded_minimum_size = custom_minimum_size
		content_host.hide()
		_footer.hide()
		custom_minimum_size = Vector2(minf(size.x, 220.0), HEADER_HEIGHT + 2.0)
		size = Vector2(size.x, HEADER_HEIGHT + 2.0)
		_minimize_button.text = "□"
		_minimize_button.tooltip_text = Localization.text(&"window.restore.tooltip")
	else:
		custom_minimum_size = _expanded_minimum_size if _expanded_minimum_size != Vector2.ZERO else Vector2(360.0, 250.0)
		content_host.show()
		_footer.show()
		size = _expanded_size if _expanded_size != Vector2.ZERO else custom_minimum_size
		_minimize_button.text = "—"
		_minimize_button.tooltip_text = Localization.text(&"window.minimize.tooltip")
		fit_to_parent(_edge_margin)
	minimized_changed.emit(instrument_id, minimized)


func move_by(delta: Vector2) -> void:
	position += delta
	_clamp_position()


func resize_by(delta: Vector2) -> void:
	var parent_control := get_parent() as Control
	var maximum := Vector2(1600.0, 900.0)
	if parent_control != null:
		maximum = parent_control.size - position - Vector2.ONE * _edge_margin
	maximum.x = maxf(1.0, maximum.x)
	maximum.y = maxf(1.0, maximum.y)
	var minimum := Vector2(
		minf(custom_minimum_size.x, maximum.x),
		minf(custom_minimum_size.y, maximum.y)
	)
	size = Vector2(
		clampf(size.x + delta.x, minimum.x, maximum.x),
		clampf(size.y + delta.y, minimum.y, maximum.y)
	)


func fit_to_parent(margin: float = 8.0) -> void:
	var parent_control := get_parent() as Control
	if parent_control == null or parent_control.size.x <= 0.0 or parent_control.size.y <= 0.0:
		return
	_edge_margin = maxf(0.0, margin)
	var available := Vector2(
		maxf(1.0, parent_control.size.x - _edge_margin * 2.0),
		maxf(1.0, parent_control.size.y - _edge_margin * 2.0)
	)
	if minimized:
		custom_minimum_size = Vector2(
			minf(220.0, available.x),
			minf(HEADER_HEIGHT + 2.0, available.y)
		)
	else:
		var baseline: Vector2 = (
			_base_minimum_size if _base_minimum_size != Vector2.ZERO
			else Vector2(360.0, 250.0)
		)
		custom_minimum_size = Vector2(
			minf(baseline.x, available.x),
			minf(baseline.y, available.y)
		)
	size = Vector2(
		clampf(size.x, custom_minimum_size.x, available.x),
		clampf(size.y, custom_minimum_size.y, available.y)
	)
	_clamp_position()


func _on_header_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.double_click and minimizable:
			toggle_minimized()
			_dragging = false
			accept_event()
			return
		_dragging = event.pressed
		if _dragging:
			_pointer_origin = _pointer_in_parent(event.global_position)
			_panel_origin = position
			mark_active()
			focus_requested.emit(instrument_id)
			accept_event()


func _on_resize_input(event: InputEvent) -> void:
	if minimized:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = event.pressed
		if _resizing:
			_pointer_origin = _pointer_in_parent(event.global_position)
			_size_origin = size
			mark_active()
			focus_requested.emit(instrument_id)
		accept_event()


func _pointer_in_parent(point: Vector2) -> Vector2:
	return (get_parent() as Control).get_global_transform_with_canvas().affine_inverse() * point


func _input(event: InputEvent) -> void:
	if not _dragging and not _resizing: return
	if not is_visible_in_tree():
		_cancel_gesture()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_gesture()
	elif event is InputEventMouseButton and (not event.pressed or event.button_index == MOUSE_BUTTON_RIGHT):
		_cancel_gesture()
	elif event is InputEventMouseMotion:
		var delta: Vector2 = _pointer_in_parent(event.global_position) - _pointer_origin
		if _dragging:
			position = _panel_origin + delta
			_clamp_position()
		else:
			size = _size_origin
			resize_by(delta)
	else: return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _active: mark_active()


func _cancel_gesture() -> void:
	_dragging = false
	_resizing = false


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_cancel_gesture()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_cancel_gesture()


func _clamp_position() -> void:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	position.x = clampf(
		position.x,
		_edge_margin,
		maxf(_edge_margin, parent_control.size.x - size.x - _edge_margin)
	)
	position.y = clampf(
		position.y,
		_edge_margin,
		maxf(_edge_margin, parent_control.size.y - size.y - _edge_margin)
	)


# Transient presentation state for round trips through separate canvases.
# This is not a player save format and contains no circuit or simulation state.
func capture_view_state() -> Dictionary:
	return {"position":position,"size":size,"visible":visible,"minimized":minimized,
		"expanded_size":_expanded_size if minimized else size,
		"minimum":_expanded_minimum_size if minimized else custom_minimum_size}


func restore_view_state(state: Dictionary) -> void:
	set_minimized(false)
	custom_minimum_size = state.minimum
	position = state.position
	size = state.expanded_size
	set_minimized(bool(state.minimized))
	if not minimized: size = state.size
	fit_to_parent(10.0)
	visible = bool(state.visible)
