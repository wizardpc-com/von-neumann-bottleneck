class_name CircuitModuleRow
extends Control

const VisualLayout = preload("res://src/hardware_foundations/component_visual_layout.gd")
const VisualStyle = preload("res://src/hardware_foundations/component_visual_style.gd")
const SignalNotationType = preload("res://src/ui/signal_notation.gd")

const SURFACE := Color("192b40")
const SYMBOL := Color("d7e9f6")
const PROCESS := Color("7fcbd6")
const SELECTION := Color("f0f5ff")
const ARITHMETIC := Color("7fcbd6")
const STORAGE := Color("aab6e6")
const ROUTING := Color("f0c674")
const SIGNAL_LOW := Color("e8848c")
const SIGNAL_HIGH := Color("7fd8a4")
const SIGNAL_HIGH_Z := Color("8b929d")
const HEADING_HEIGHT := 30.0
const PORT_ROW_HEIGHT := 34.0

var visual_bands: Array = []
var component_kind: StringName = &""
var component_label: String = ""
var input_label: String = ""
var output_label: String = ""
var row_index: int = 0
var row_count: int = 1
var has_input: bool = false
var has_output: bool = false
var input_width: int = 1
var output_width: int = 1
var selection_active: bool = false
var processing_active: bool = false
var processing_progress: float = 0.0
var processing_input_visuals: Array[Dictionary] = []
var processing_output_visual: Dictionary = {}
var active_output_port: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(
		p_kind: StringName,
		p_component_label: String,
		p_input_label: String,
		p_output_label: String,
		p_row_index: int,
		p_row_count: int,
		p_has_input: bool,
		p_has_output: bool,
		p_input_width: int,
		p_output_width: int
	) -> void:
	visual_bands.clear()
	component_kind = p_kind
	component_label = p_component_label
	input_label = p_input_label
	output_label = p_output_label
	row_index = p_row_index
	row_count = maxi(1, p_row_count)
	has_input = p_has_input
	has_output = p_has_output
	input_width = maxi(1, p_input_width)
	output_width = maxi(1, p_output_width)
	queue_redraw()


func set_processing_state(
		progress: float,
		input_visuals: Array[Dictionary] = [],
		output_visual: Dictionary = {},
		p_active_output_port: int = -1
	) -> void:
	processing_active = true
	processing_progress = clampf(progress, 0.0, 1.0)
	processing_input_visuals = input_visuals.duplicate(true)
	processing_output_visual = output_visual.duplicate(true)
	active_output_port = p_active_output_port
	queue_redraw()


func clear_processing_state() -> void:
	if not processing_active:
		return
	processing_active = false
	processing_progress = 0.0
	processing_input_visuals.clear()
	processing_output_visual.clear()
	active_output_port = -1
	queue_redraw()


func set_selection_active(active: bool) -> void:
	if selection_active == active:
		return
	selection_active = active
	queue_redraw()


func shape_profile() -> StringName:
	match component_kind:
		&"mux4", &"mux2_word":
			return &"mux_wedge"
		&"alu1", &"alu4":
			return &"alu_notched"
		&"decoder1_to_2":
			return &"fanout_module"
		&"sr_latch", &"register1", &"register4":
			return &"register_module"
		&"ram2x4":
			return &"ram_grid"
		&"tiny_computer":
			return &"computer_split"
	return &"arithmetic_module"


func ram_cursor_index() -> int:
	if component_kind != &"ram2x4" or processing_input_visuals.is_empty():
		return -1
	var address: Dictionary = processing_input_visuals[0]
	if not bool(address.get("known", false)):
		return -1
	return clampi(int(address.get("numeric", 0)), 0, 1)


func output_token_enabled() -> bool:
	return _output_is_active()


func visual_hit_test(point: Vector2, tolerance: float = 3.0) -> bool:
	var body: PackedVector2Array = body_polygon()
	if Geometry2D.is_point_in_polygon(point, body):
		return true
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	if has_input and _near_segment(
		point, Vector2(0.0, center_y), Vector2(_body_left(global_t), center_y), tolerance + 2.0
	):
		return true
	return has_output and _near_segment(
		point, Vector2(_body_right(global_t), center_y), Vector2(size.x, center_y), tolerance + 2.0
	)


func _near_segment(point: Vector2, start: Vector2, finish: Vector2, tolerance: float) -> bool:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, finish)) <= tolerance


func visible_component_name() -> String:
	match component_kind:
		&"half_adder": return "HA"
		&"full_adder": return "FA"
		&"mux4": return "MUX 4:1"
		&"mux2_word":
			if component_label.contains("SOURCE"): return "SRC MUX"
			if component_label.contains("RESULT"): return "RES MUX"
			return "MUX 2:1"
		&"alu1": return "ALU1"
		&"alu4": return "ALU4"
		&"sr_latch": return "SR"
		&"register1": return "REG1"
		&"register4": return "ACC" if component_label.contains("ACC") else "REG4"
		&"decoder1_to_2": return "DEC 1:2"
		&"control": return "CTRL"
		&"ram2x4": return "RAM 2x4"
		&"tiny_computer": return "CPU+RAM"
	return component_label if not component_label.is_empty() else String(component_kind)


func name_layout() -> Dictionary:
	var text: String = visible_component_name()
	var safe_rect: Rect2 = _central_content_rect()
	var font_size: int = _name_font_size(text, 18, maxf(1.0, safe_rect.size.x - 4.0))
	var text_width: float = _text_width(text, font_size)
	var center_y: float = _module_height() * 0.5 - _row_origin_y()
	var text_center := Vector2(safe_rect.get_center().x, center_y - 13.0)
	var text_rect := Rect2(
		Vector2(text_center.x - text_width * 0.5 - 2.0, text_center.y - float(font_size) * 0.58 - 2.0),
		Vector2(text_width + 4.0, float(font_size) + 4.0)
	)
	var icon_rect := Rect2(Vector2(text_center.x - 17.0, center_y + 4.0), Vector2(34.0, 26.0))
	return {
		"text": text,
		"font_size": font_size,
		"text_width": text_width,
		"center": text_center,
		"rect": text_rect,
		"icon_rect": icon_rect,
		"safe_rect": safe_rect,
	}


func port_label_layouts() -> Array[Dictionary]:
	var layouts: Array[Dictionary] = []
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	if has_input:
		var text: String = _width_label(input_label, input_width)
		layouts.append(_text_layout(
			Vector2(6.0, center_y - 12.0) if not visual_bands.is_empty() else Vector2(left + 7.0, center_y), text, HORIZONTAL_ALIGNMENT_LEFT, 12, &"input"
		))
	if has_output:
		var text: String = _width_label(output_label, output_width)
		layouts.append(_text_layout(
			Vector2(size.x - 6.0, center_y - 12.0) if not visual_bands.is_empty() else Vector2(right - 7.0, center_y), text, HORIZONTAL_ALIGNMENT_RIGHT, 12, &"output"
		))
	return layouts


func function_mark_rect() -> Rect2:
	var layout: Dictionary = name_layout()
	var result: Rect2 = layout["rect"]
	var icon_rect: Rect2 = layout["icon_rect"]
	if icon_rect.has_area():
		result = result.merge(icon_rect)
	return result.grow(2.0)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if row_index < 0:
		var cap: PackedVector2Array = body_polygon()
		draw_colored_polygon(cap, SURFACE)
		draw_polyline(cap, SELECTION if selection_active else _outline_color(), 2.0, true)
		if visual_bands.is_empty():
			_draw_family_tab()
			_draw_storage_rails()
		return
	_draw_module_surface()
	_draw_pin_leads()
	_draw_processing_route()
	_draw_port_labels()
	if row_index == row_count - 1:
		# The last row paints the shared mark above earlier row fills.
		_draw_function_mark()


func _body_icon_rect() -> Rect2:
	var safe: Rect2 = _central_content_rect()
	var width: float = minf(24.0, safe.size.x)
	return Rect2(Vector2(safe.get_center().x - width * 0.5, size.y * 0.5 - 10.0), Vector2(width, 20.0))


func body_edge_points(side: int) -> PackedVector2Array:
	# The same piecewise boundary drives fill, outline, hit testing and pin leads.
	# A single trapezoid per port row loses mid-row notches/visual bands.
	var top: float=float(maxi(0,row_index))/float(row_count)
	var bottom: float=float(maxi(0,row_index)+1)/float(row_count)
	var samples: Array[float]=[top,bottom]
	if top < 0.5 and bottom > 0.5: samples.append(0.5)
	if not visual_bands.is_empty():
		for index: int in visual_bands.size():
			var t: float=float(index)/float(visual_bands.size()-1)
			if t>top and t<bottom and t not in samples: samples.append(t)
	else:
		for point: Vector2 in _builtin_polygon():
			var t: float = (point.y - HEADING_HEIGHT) / (_module_height() - HEADING_HEIGHT)
			if t > top and t < bottom and t not in samples: samples.append(t)
	samples.sort()
	var points:=PackedVector2Array()
	for t: float in samples:
		points.append(Vector2(_body_left(t) if side==0 else _body_right(t),(t-top)/(bottom-top)*size.y))
	return points


func body_polygon() -> PackedVector2Array:
	if row_index<0:
		if visual_bands.is_empty():
			var left_edge := PackedVector2Array()
			var right_edge := PackedVector2Array()
			var levels: Array[float] = [0.0, HEADING_HEIGHT]
			for point: Vector2 in _builtin_polygon():
				if point.y > 0.0 and point.y < HEADING_HEIGHT and point.y not in levels: levels.append(point.y)
			levels.sort()
			for y: float in levels:
				left_edge.append(Vector2(_builtin_edge(y, 0), y))
				right_edge.append(Vector2(_builtin_edge(y, 1), y))
			left_edge.reverse()
			left_edge.append_array(right_edge)
			return left_edge
		var left: float = _body_left(0.0)
		var right: float = _body_right(0.0)
		return PackedVector2Array([Vector2(left, size.y), Vector2(left, 8.0),
			Vector2(left + 8.0, 0.0), Vector2(right - 8.0, 0.0),
			Vector2(right, 8.0), Vector2(right, size.y)])
	var points: PackedVector2Array=body_edge_points(0)
	var right: PackedVector2Array=body_edge_points(1)
	right.reverse()
	points.append_array(right)
	return points


func _draw_module_surface() -> void:
	var left: PackedVector2Array=body_edge_points(0)
	var right: PackedVector2Array=body_edge_points(1)
	draw_colored_polygon(body_polygon(), SURFACE)
	var outline: Color = SELECTION if selection_active else _outline_color()
	draw_polyline(left,outline,3.0,true)
	draw_polyline(right,outline,3.0,true)
	if row_index==row_count-1: draw_line(left[-1],right[-1],outline,3.0,true)
	_draw_storage_rails()

func _draw_storage_rails() -> void:
	if visual_bands.is_empty() and VisualStyle.family(component_kind) == &"storage":
		var first: float = maxf(0.0, 21.0 - _row_origin_y())
		var last: float = minf(size.y, _module_height() - 21.0 - _row_origin_y())
		if last > first:
			for x: float in [23.0, size.x - 23.0]: draw_line(Vector2(x, first), Vector2(x, last), _outline_color(), 1.2, true)

func _draw_family_tab() -> void:
	draw_colored_polygon(family_tab_polygon(), _outline_color())

func family_tab_polygon() -> PackedVector2Array:
	var x: float = 40.0
	var y: float = 18.0 if component_kind == &"decoder1_to_2" else 9.0
	return PackedVector2Array([Vector2(x, y), Vector2(x + 38, y), Vector2(x + 33, y + 5), Vector2(x, y + 5)])

func _module_height() -> float:
	return HEADING_HEIGHT + float(row_count) * (PORT_ROW_HEIGHT if row_index < 0 else size.y)

func _row_origin_y() -> float:
	return 0.0 if row_index < 0 else HEADING_HEIGHT + float(row_index) * size.y

func _builtin_polygon() -> PackedVector2Array:
	return VisualStyle.shell(component_kind, Rect2(28.0, 0.0, size.x - 56.0, _module_height()))

func _builtin_edge(y: float, side: int) -> float:
	var polygon: PackedVector2Array = _builtin_polygon()
	var crossings: Array[float] = []
	for index: int in polygon.size():
		var a: Vector2 = polygon[index]
		var b: Vector2 = polygon[(index + 1) % polygon.size()]
		if is_equal_approx(a.y, b.y):
			if is_equal_approx(y, a.y): crossings.append(a.x); crossings.append(b.x)
		elif y >= minf(a.y, b.y) and y <= maxf(a.y, b.y):
			crossings.append(lerpf(a.x, b.x, (y - a.y) / (b.y - a.y)))
	crossings.sort()
	return crossings.front() if side == 0 else crossings.back()


func _draw_pin_leads() -> void:
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	if has_input:
		SignalNotationType.draw_cable(self, PackedVector2Array([Vector2(0.0, center_y), Vector2(left, center_y)]), SYMBOL, input_width)
		_draw_pin_direction(Vector2(left - 10.0, center_y))
	if has_output:
		SignalNotationType.draw_cable(self, PackedVector2Array([Vector2(right, center_y), Vector2(size.x, center_y)]), SYMBOL, output_width)
		_draw_pin_direction(Vector2(right + 18.0, center_y))


func _draw_pin_direction(tip: Vector2) -> void:
	draw_polyline(PackedVector2Array([tip + Vector2(-5.0, -4.0), tip, tip + Vector2(-5.0, 4.0)]), SYMBOL, 2.0, true)


func _draw_port_labels() -> void:
	for layout: Dictionary in port_label_layouts():
		_draw_text(
			layout["anchor"], layout["text"], SignalNotationType.width_color(input_width if layout["side"] == &"input" else output_width),
			layout["alignment"], int(layout["font_size"])
		)


func _draw_function_mark() -> void:
	var strength: float = _stage_strength(0.24, 0.76)
	var color: Color = SYMBOL.lerp(PROCESS, strength)
	var layout: Dictionary = name_layout()
	var icon_rect: Rect2 = layout["icon_rect"]
	if icon_rect.has_area():
		draw_set_transform(icon_rect.get_center(), 0.0, Vector2(1.35, 1.35))
		_draw_function_icon(Rect2(-12, -10, 24, 20), _outline_color().lerp(PROCESS, strength))
		draw_set_transform(Vector2.ZERO)
	var name_rect: Rect2 = layout["rect"]
	draw_rect(name_rect.grow(1.5), Color(SURFACE, 0.98), true)
	_draw_text(
		layout["center"], layout["text"], color,
		HORIZONTAL_ALIGNMENT_CENTER, int(layout["font_size"])
	)


func _draw_function_icon(rect: Rect2, color: Color) -> void:
	var center: Vector2 = rect.get_center()
	match component_kind:
		&"half_adder", &"full_adder":
			draw_circle(center, 9.0, color, false, 1.5, true)
			draw_line(center - Vector2(5, 0), center + Vector2(5, 0), color, 1.5, true)
			draw_line(center - Vector2(0, 5), center + Vector2(0, 5), color, 1.5, true)
		&"mux4", &"mux2_word":
			_draw_mux_mark(center, color)
		&"alu1", &"alu4":
			_draw_alu_mark(center, color)
		&"sr_latch", &"register1", &"register4":
			_draw_latch_mark(center, color)
		&"decoder1_to_2", &"control":
			_draw_fanout_mark(center, color)
		&"ram2x4":
			_draw_ram_mark(center, color)
		&"tiny_computer":
			_draw_computer_mark(center, color)
		_:
			draw_circle(center, 5.0, color, false, 2.0, true)


func _draw_processing_route() -> void:
	if not processing_active:
		return
	var center_y: float = size.y * 0.5
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var left: float = _body_left(global_t)
	var right: float = _body_right(global_t)
	var center_x: float = size.x * 0.5
	var body_strength: float = _stage_strength(0.22, 0.78)
	if body_strength > 0.0:
		var route_color := Color(PROCESS, 0.28 + body_strength * 0.62)
		var guarded_rect := function_mark_rect()
		var input_start_x: float = left + 3.0
		var output_finish_x: float = right - 3.0
		for layout: Dictionary in port_label_layouts():
			var label_rect: Rect2 = layout["rect"]
			if StringName(layout["side"]) == &"input":
				input_start_x = maxf(input_start_x, label_rect.end.x + 3.0)
			else:
				output_finish_x = minf(output_finish_x, label_rect.position.x - 3.0)
		var input_finish_x: float = center_x - 15.0
		var output_start_x: float = center_x + 15.0
		if guarded_rect.has_area():
			input_finish_x = minf(input_finish_x, guarded_rect.position.x - 3.0)
			output_start_x = maxf(output_start_x, guarded_rect.end.x + 3.0)
		if has_input:
			if input_finish_x > input_start_x:
				draw_line(
					Vector2(input_start_x, center_y), Vector2(input_finish_x, center_y),
					route_color, 3.0, true
				)
		if _output_is_active() and output_start_x < output_finish_x:
			draw_line(
				Vector2(output_start_x, center_y), Vector2(output_finish_x, center_y),
				route_color, 3.0, true
			)
	if has_input:
		var input_visual: Dictionary = _input_visual()
		_draw_processing_token(
			Vector2(0.0, center_y), Vector2(left + 5.0, center_y),
			0.0, 0.36, input_visual, input_width
		)
	if _output_is_active():
		_draw_processing_token(
			Vector2(right - 5.0, center_y), Vector2(size.x, center_y),
			0.64, 1.0, processing_output_visual, output_width
		)


func _draw_processing_token(
		start: Vector2,
		finish: Vector2,
		stage_start: float,
		stage_end: float,
		visual: Dictionary,
		width: int
	) -> void:
	if processing_progress < stage_start or processing_progress > stage_end:
		return
	var local_progress: float = smoothstep(
		0.0, 1.0, inverse_lerp(stage_start, stage_end, processing_progress)
	)
	var point: Vector2 = start.lerp(finish, local_progress)
	var color: Color = visual.get("color", SIGNAL_HIGH_Z)
	SignalNotationType.draw_cable(self, PackedVector2Array([start, point]), color, width)


func _draw_mux_mark(center: Vector2, color: Color) -> void:
	var wedge := PackedVector2Array([
		center + Vector2(-8.0, -8.0), center + Vector2(8.0, -5.0),
		center + Vector2(8.0, 5.0), center + Vector2(-8.0, 8.0),
		center + Vector2(-8.0, -8.0),
	])
	draw_polyline(wedge, color, 2.0, true)
	draw_line(center + Vector2(-11.0, -4.0), center + Vector2(-8.0, -4.0), color, 2.0, true)
	draw_line(center + Vector2(-11.0, 4.0), center + Vector2(-8.0, 4.0), color, 2.0, true)
	draw_line(center + Vector2(8.0, 0.0), center + Vector2(11.0, 0.0), color, 2.0, true)


func _draw_alu_mark(center: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		center + Vector2(-10.0, -8.0), center + Vector2(9.0, -6.0),
		center + Vector2(5.0, 0.0), center + Vector2(9.0, 6.0),
		center + Vector2(-10.0, 8.0), center + Vector2(-5.0, 0.0),
		center + Vector2(-10.0, -8.0),
	])
	draw_polyline(body, color, 2.0, true)
	draw_line(center + Vector2(-2.0, -3.0), center + Vector2(4.0, -3.0), color, 1.5, true)
	draw_line(center + Vector2(1.0, -6.0), center + Vector2(1.0, 0.0), color, 1.5, true)


func _draw_latch_mark(center: Vector2, color: Color) -> void:
	var rect := Rect2(center - Vector2(9.0, 7.0), Vector2(18.0, 14.0))
	draw_rect(rect, color, false, 2.0)
	if component_kind == &"register4":
		for bit: int in range(1, 4):
			var x: float = rect.position.x + rect.size.x * float(bit) / 4.0
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), color, 1.0, true)
	draw_line(center + Vector2(-9.0, -3.0), center + Vector2(-5.0, -3.0), color, 1.5, true)
	draw_line(center + Vector2(-9.0, 3.0), center + Vector2(-5.0, 3.0), color, 1.5, true)
	draw_line(center + Vector2(5.0, -3.0), center + Vector2(9.0, -3.0), color, 1.5, true)
	draw_line(center + Vector2(5.0, 3.0), center + Vector2(9.0, 3.0), color, 1.5, true)


func _draw_fanout_mark(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-10.0, 0.0), center + Vector2(-2.0, 0.0), color, 2.0, true)
	draw_circle(center + Vector2(-2.0, 0.0), 2.0, color)
	draw_line(center + Vector2(-2.0, 0.0), center + Vector2(9.0, -6.0), color, 1.8, true)
	draw_line(center + Vector2(-2.0, 0.0), center + Vector2(9.0, 6.0), color, 1.8, true)


func _draw_ram_mark(center: Vector2, color: Color) -> void:
	var origin := center + Vector2(-10.0, -7.0)
	var cursor: int = ram_cursor_index()
	for address: int in range(2):
		var row_rect := Rect2(origin + Vector2(0.0, address * 8.0), Vector2(20.0, 6.0))
		if processing_active and cursor == address and _stage_strength(0.22, 0.82) > 0.0:
			draw_rect(row_rect, Color(PROCESS, 0.42), true)
		draw_rect(row_rect, color, false, 1.5)
		for bit: int in range(1, 4):
			var x: float = row_rect.position.x + row_rect.size.x * float(bit) / 4.0
			draw_line(
				Vector2(x, row_rect.position.y),
				Vector2(x, row_rect.end.y), color, 1.0, true
			)


func _draw_computer_mark(center: Vector2, color: Color) -> void:
	var rect := Rect2(center + Vector2(-10.0, -7.0), Vector2(20.0, 14.0))
	draw_rect(rect, color, false, 2.0)
	draw_line(center + Vector2(0.0, -7.0), center + Vector2(0.0, 7.0), color, 1.5, true)
	draw_circle(center + Vector2(-5.0, 0.0), 2.0, color, false, 1.5, true)
	draw_rect(Rect2(center + Vector2(3.0, -3.0), Vector2(4.0, 6.0)), color, false, 1.0)


func _draw_value_badge(center: Vector2, text: String, color: Color) -> void:
	var font_size: int = 8
	var width: float = ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x + 6.0
	var rect := Rect2(center - Vector2(width * 0.5, 6.0), Vector2(width, 12.0))
	draw_rect(rect, Color(SURFACE, 0.94), true)
	draw_rect(rect, Color(color, 0.8), false, 1.0)
	_draw_text(center + Vector2(0.0, 0.5), text, color, HORIZONTAL_ALIGNMENT_CENTER, font_size)


func _draw_text(
		anchor: Vector2,
		text: String,
		color: Color,
		alignment: HorizontalAlignment,
		font_size: int
	) -> void:
	if text.is_empty():
		return
	var text_width: float = ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x
	var x: float = anchor.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x -= text_width * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= text_width
	var position := Vector2(x, anchor.y + float(font_size) * 0.36)
	for offset: Vector2 in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0), Vector2(0.0, 1.0)]:
		draw_string(
			ThemeDB.fallback_font, position + offset,
			text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(SURFACE, 0.96)
		)
	draw_string(
		ThemeDB.fallback_font,
		position,
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color
	)


func _name_font_size(text: String, preferred: int, max_width: float = 86.0) -> int:
	var font_size: int = preferred
	while font_size > 6 and _text_width(text, font_size) > max_width:
		font_size -= 1
	return font_size


func _text_width(text: String, font_size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size
	).x


func _text_layout(
		anchor: Vector2,
		text: String,
		alignment: HorizontalAlignment,
		font_size: int,
		side: StringName
	) -> Dictionary:
	var text_width: float = _text_width(text, font_size)
	var x: float = anchor.x
	if alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x -= text_width * 0.5
	elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= text_width
	return {
		"anchor": anchor,
		"text": text,
		"alignment": alignment,
		"font_size": font_size,
		"side": side,
		"rect": Rect2(
			Vector2(x - 2.0, anchor.y - float(font_size) * 0.58 - 2.0),
			Vector2(text_width + 4.0, float(font_size) + 4.0)
		),
	}


func _central_content_rect() -> Rect2:
	var global_t: float = (float(row_index) + 0.5) / float(row_count)
	var safe_left: float = _body_left(global_t) + 8.0
	var safe_right: float = _body_right(global_t) - 8.0
	for layout: Dictionary in port_label_layouts():
		var rect: Rect2 = layout["rect"]
		if StringName(layout["side"]) == &"input":
			safe_left = maxf(safe_left, rect.end.x + 7.0)
		else:
			safe_right = minf(safe_right, rect.position.x - 7.0)
	var half_width: float = maxf(1.0, minf(size.x * 0.5 - safe_left, safe_right - size.x * 0.5))
	var center_y: float = _module_height() * 0.5 - _row_origin_y()
	return Rect2(
		Vector2(size.x * 0.5 - half_width, center_y - 28.0),
		Vector2(half_width * 2.0, 60.0)
	)


func _body_left(t: float) -> float:
	if not visual_bands.is_empty():
		return 28.0 + _visual_edge(t,0) / 4.0 * 24.0
	return _builtin_edge(HEADING_HEIGHT + clampf(t, 0, 1) * (_module_height() - HEADING_HEIGHT), 0)


func _body_right(t: float) -> float:
	if not visual_bands.is_empty():
		return size.x - 28.0 - (12.0-_visual_edge(t,1)) / 4.0 * 24.0
	return _builtin_edge(HEADING_HEIGHT + clampf(t, 0, 1) * (_module_height() - HEADING_HEIGHT), 1)


func _outline_color() -> Color:
	return VisualStyle.accent(component_kind)


func _input_visual() -> Dictionary:
	if row_index >= 0 and row_index < processing_input_visuals.size():
		return processing_input_visuals[row_index]
	return {"known": false, "numeric": 0, "text": "Z", "color": SIGNAL_HIGH_Z}


func _output_is_active() -> bool:
	return has_output and (active_output_port < 0 or active_output_port == row_index)


func _stage_strength(start: float, finish: float) -> float:
	if not processing_active or finish <= start:
		return 0.0
	if processing_progress < start or processing_progress > finish:
		return 0.0
	return sin(inverse_lerp(start, finish, processing_progress) * PI)


func _width_label(label: String, width: int) -> String:
	var compact: String = _compact_port_label(label)
	return "%s %s" % [compact, SignalNotationType.width_text(maxi(1, width))]


func _compact_port_label(label: String) -> String:
	match label:
		"SOURCE_SEL": return "SRC"
		"RESULT_SEL": return "RES"
		"ACC_LOAD": return "ACC"
		"MEM_WRITE": return "MEM"
		"DATA_IN": return "DIN"
		"DATA_OUT": return "DOUT"
		"ENABLE": return "EN"
		"WRITE": return "WR"
		"LOAD": return "LD"
		"RESULT": return "R"
		"CARRY": return "C"
		"COUT": return "CO"
		"ADDR": return "ADR"
	return label.left(7)


func set_visual_snapshot(snapshot: Dictionary, source_signature: String) -> void:
	visual_bands = snapshot.bands.duplicate(true) if VisualLayout.is_valid(snapshot,source_signature) else []
	queue_redraw()

func _visual_edge(t: float, side: int) -> float:
	var coordinate: float = clampf(t,0.0,1.0)*float(visual_bands.size()-1)
	var index: int = mini(visual_bands.size()-1,floori(coordinate))
	var next: int = mini(index+1,visual_bands.size()-1)
	return lerpf(float(visual_bands[index][side]),float(visual_bands[next][side]),coordinate-float(index))
