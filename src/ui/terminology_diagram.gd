class_name TerminologyDiagram
extends Control

const BACKGROUND := Color("101a2a")
const PANEL := Color("18263a")
const PANEL_ACTIVE := Color("17384a")
const BORDER := Color("40546f")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const DANGER := Color("ff7c8e")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")

var diagram_id: StringName = &""


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 248.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	Localization.locale_changed.connect(_on_locale_changed)


func set_diagram(value: StringName) -> void:
	diagram_id = value
	visible = not diagram_id.is_empty()
	queue_redraw()


func _draw() -> void:
	if diagram_id.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND, true)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER, false, 1.0)
	match diagram_id:
		&"accumulator":
			_draw_accumulator()
		&"multiplexer":
			_draw_multiplexer()
		&"alu":
			_draw_alu()
		&"sr_latch":
			_draw_sr_latch()
		&"decoder":
			_draw_decoder()
		&"serialization":
			_draw_serialization()
		&"cpu_wait":
			_draw_cpu_wait()
		&"bottleneck":
			_draw_bottleneck()
		&"cache":
			_draw_cache()
		&"working_set":
			_draw_working_set()
		&"blocking":
			_draw_blocking()


func _draw_accumulator() -> void:
	var box_size := Vector2(minf(150.0, size.x * 0.26), 66.0)
	var left_x: float = maxf(20.0, size.x * 0.08)
	var right_x: float = size.x - left_x - box_size.x
	var top_y := 28.0
	var bottom_y := size.y - box_size.y - 28.0
	var original := Rect2(Vector2(left_x, top_y), box_size)
	var operation := Rect2(Vector2(right_x, top_y), box_size)
	var write_back := Rect2(Vector2(right_x, bottom_y), box_size)
	var reuse := Rect2(Vector2(left_x, bottom_y), box_size)
	_draw_box(original, _t(&"terminology.diagram.accumulator.original"), "ACC = 3", ACCENT)
	_draw_box(operation, _t(&"terminology.diagram.accumulator.operation"), "3 + 2 = 5", WARNING)
	_draw_box(write_back, _t(&"terminology.diagram.accumulator.write_back"), "ACC = 5", GOOD)
	_draw_box(reuse, _t(&"terminology.diagram.accumulator.reuse"), "ACC = 5", ACCENT)
	_draw_arrow(_right_center(original), _left_center(operation), ACCENT)
	_draw_arrow(_bottom_center(operation), _top_center(write_back), WARNING)
	_draw_arrow(_left_center(write_back), _right_center(reuse), GOOD)
	_draw_arrow(_top_center(reuse), _bottom_center(original), ACCENT)


func _draw_multiplexer() -> void:
	var center := Rect2(Vector2(size.x * 0.40, 45.0), Vector2(size.x * 0.24, 130.0))
	_draw_box(center, "MUX", _t(&"terminology.diagram.multiplexer.select"), ACCENT)
	var values := ["D0 = 3", "D1 = 7", "D2 = 12", "D3 = 1"]
	for index: int in range(values.size()):
		var y: float = center.position.y + 18.0 + index * 27.0
		var active: bool = index == 2
		_draw_text(Rect2(16.0, y - 9.0, center.position.x - 30.0, 22.0), values[index], TEXT if not active else GOOD, 14)
		_draw_arrow(Vector2(center.position.x - 18.0, y), Vector2(center.position.x, y), GOOD if active else MUTED)
	var output_y: float = center.get_center().y
	_draw_arrow(Vector2(center.end.x, output_y), Vector2(size.x - 18.0, output_y), GOOD)
	_draw_text(Rect2(center.end.x + 12.0, output_y - 28.0, size.x - center.end.x - 30.0, 24.0), _t(&"terminology.diagram.multiplexer.output"), GOOD, 14)
	_draw_text(Rect2(center.end.x + 12.0, output_y + 4.0, size.x - center.end.x - 30.0, 24.0), "12", TEXT, 18)
	_draw_arrow(Vector2(center.get_center().x, size.y - 18.0), Vector2(center.get_center().x, center.end.y), WARNING)
	_draw_text(Rect2(center.position.x, size.y - 43.0, center.size.x, 22.0), "OP = 10", WARNING, 14)


func _draw_alu() -> void:
	var alu := Rect2(Vector2(size.x * 0.35, 36.0), Vector2(size.x * 0.30, 150.0))
	_draw_box(alu, "ALU", _t(&"terminology.diagram.alu.selected"), ACCENT)
	_draw_arrow(Vector2(18.0, 74.0), Vector2(alu.position.x, 74.0), ACCENT)
	_draw_arrow(Vector2(18.0, 145.0), Vector2(alu.position.x, 145.0), ACCENT)
	_draw_text(Rect2(18.0, 42.0, alu.position.x - 34.0, 24.0), "A = 6", TEXT, 16)
	_draw_text(Rect2(18.0, 113.0, alu.position.x - 34.0, 24.0), "B = 3", TEXT, 16)
	_draw_arrow(Vector2(alu.get_center().x, size.y - 18.0), Vector2(alu.get_center().x, alu.end.y), WARNING)
	_draw_text(Rect2(alu.position.x, size.y - 45.0, alu.size.x, 22.0), "OP = ADD", WARNING, 14)
	_draw_arrow(Vector2(alu.end.x, alu.get_center().y), Vector2(size.x - 18.0, alu.get_center().y), GOOD)
	_draw_text(Rect2(alu.end.x + 12.0, alu.get_center().y - 34.0, size.x - alu.end.x - 30.0, 24.0), _t(&"terminology.diagram.alu.result"), GOOD, 14)
	_draw_text(Rect2(alu.end.x + 12.0, alu.get_center().y + 2.0, size.x - alu.end.x - 30.0, 24.0), "9", TEXT, 19)


func _draw_sr_latch() -> void:
	var gate_size := Vector2(minf(150.0, size.x * 0.28), 62.0)
	var gate_x: float = (size.x - gate_size.x) * 0.5
	var upper := Rect2(Vector2(gate_x, 32.0), gate_size)
	var lower := Rect2(Vector2(gate_x, size.y - gate_size.y - 32.0), gate_size)
	_draw_box(upper, "NOR", _t(&"terminology.diagram.sr_latch.set_path"), ACCENT)
	_draw_box(lower, "NOR", _t(&"terminology.diagram.sr_latch.reset_path"), ACCENT)
	_draw_text(Rect2(14.0, 44.0, gate_x - 32.0, 24.0), "S = 1", GOOD, 15)
	_draw_text(Rect2(14.0, lower.position.y + 12.0, gate_x - 32.0, 24.0), "R = 0", TEXT, 15)
	_draw_arrow(Vector2(gate_x - 12.0, upper.get_center().y), _left_center(upper), GOOD)
	_draw_arrow(Vector2(gate_x - 12.0, lower.get_center().y), _left_center(lower), MUTED)
	_draw_arrow(_right_center(upper), Vector2(size.x - 18.0, upper.get_center().y), GOOD)
	_draw_arrow(_right_center(lower), Vector2(size.x - 18.0, lower.get_center().y), MUTED)
	_draw_text(Rect2(upper.end.x + 12.0, upper.position.y + 4.0, size.x - upper.end.x - 28.0, 24.0), "Q = 1", GOOD, 16)
	_draw_text(Rect2(lower.end.x + 12.0, lower.position.y + 4.0, size.x - lower.end.x - 28.0, 24.0), "Q̅ = 0", MUTED, 16)
	var loop_x: float = size.x * 0.76
	_draw_polyline(PackedVector2Array([Vector2(upper.end.x, upper.end.y - 13.0), Vector2(loop_x, upper.end.y - 13.0), Vector2(loop_x, lower.position.y + 13.0), Vector2(lower.end.x, lower.position.y + 13.0)]), GOOD)
	var left_loop_x: float = size.x * 0.24
	_draw_polyline(PackedVector2Array([Vector2(lower.position.x, lower.position.y + 13.0), Vector2(left_loop_x, lower.position.y + 13.0), Vector2(left_loop_x, upper.end.y - 13.0), Vector2(upper.position.x, upper.end.y - 13.0)]), MUTED)


func _draw_decoder() -> void:
	var decoder := Rect2(Vector2(size.x * 0.34, 44.0), Vector2(size.x * 0.28, 150.0))
	_draw_box(decoder, _t(&"terminology.diagram.decoder.name"), "ADDR = 01", ACCENT)
	_draw_arrow(Vector2(18.0, decoder.get_center().y), _left_center(decoder), ACCENT)
	_draw_text(Rect2(16.0, decoder.get_center().y - 33.0, decoder.position.x - 32.0, 24.0), _t(&"terminology.diagram.decoder.address"), ACCENT, 14)
	for index: int in range(4):
		var y: float = decoder.position.y + 24.0 + index * 34.0
		var active: bool = index == 1
		_draw_arrow(Vector2(decoder.end.x, y), Vector2(size.x - 24.0, y), GOOD if active else MUTED)
		_draw_text(Rect2(decoder.end.x + 10.0, y - 25.0, size.x - decoder.end.x - 30.0, 22.0), "W%d = %d" % [index, 1 if active else 0], GOOD if active else MUTED, 14)


func _draw_serialization() -> void:
	_draw_text(Rect2(18.0, 17.0, size.x - 36.0, 24.0), _t(&"terminology.diagram.serialization.value"), ACCENT, 16)
	var bus8 := Rect2(Vector2(24.0, 62.0), Vector2(size.x - 48.0, 45.0))
	var bus2 := Rect2(Vector2(24.0, 150.0), Vector2(size.x - 48.0, 45.0))
	_draw_timeline(bus8, _t(&"terminology.diagram.serialization.bus8"), ["1010 0101"], GOOD)
	_draw_timeline(bus2, _t(&"terminology.diagram.serialization.bus2"), ["10", "10", "01", "01"], WARNING)


func _draw_cpu_wait() -> void:
	var start_x := 112.0
	var end_x := size.x - 22.0
	_draw_text(Rect2(10.0, 56.0, 90.0, 24.0), "CPU", ACCENT, 15)
	_draw_text(Rect2(10.0, 138.0, 90.0, 24.0), "RAM", WARNING, 15)
	draw_line(Vector2(start_x, 68.0), Vector2(end_x, 68.0), BORDER, 2.0)
	draw_line(Vector2(start_x, 150.0), Vector2(end_x, 150.0), BORDER, 2.0)
	var request_x: float = start_x + 24.0
	var return_x: float = end_x - 34.0
	_draw_arrow(Vector2(request_x, 68.0), Vector2(request_x + 34.0, 150.0), ACCENT)
	_draw_arrow(Vector2(return_x - 34.0, 150.0), Vector2(return_x, 68.0), GOOD)
	draw_rect(Rect2(Vector2(request_x + 8.0, 48.0), Vector2(return_x - request_x - 16.0, 40.0)), Color(DANGER, 0.18), true)
	_draw_text(Rect2(request_x + 12.0, 54.0, return_x - request_x - 24.0, 24.0), _t(&"terminology.diagram.cpu_wait.waiting"), DANGER, 15)
	_draw_text(Rect2(request_x - 38.0, 183.0, 110.0, 24.0), _t(&"terminology.diagram.cpu_wait.request"), ACCENT, 13)
	_draw_text(Rect2(return_x - 54.0, 183.0, 130.0, 24.0), _t(&"terminology.diagram.cpu_wait.return"), GOOD, 13)


func _draw_bottleneck() -> void:
	var labels := ["CPU", "BUS", "RAM"]
	var cycles := [2, 4, 12]
	var colors := [ACCENT, WARNING, DANGER]
	var origin_x := 122.0
	var max_width: float = size.x - origin_x - 38.0
	for index: int in range(labels.size()):
		var y: float = 43.0 + index * 62.0
		_draw_text(Rect2(12.0, y - 5.0, 92.0, 26.0), labels[index], colors[index], 15)
		var width: float = max_width * float(cycles[index]) / 12.0
		draw_rect(Rect2(Vector2(origin_x, y), Vector2(width, 27.0)), Color(colors[index], 0.30), true)
		draw_rect(Rect2(Vector2(origin_x, y), Vector2(width, 27.0)), colors[index], false, 2.0)
		_draw_text(Rect2(origin_x + 6.0, y - 2.0, maxf(50.0, width - 12.0), 24.0), "%d cycles" % cycles[index], TEXT, 14)
	_draw_text(Rect2(origin_x, size.y - 32.0, max_width, 22.0), _t(&"terminology.diagram.bottleneck.slowest"), DANGER, 14)


func _draw_cache() -> void:
	var cpu := Rect2(Vector2(20.0, 80.0), Vector2(105.0, 70.0))
	var cache := Rect2(Vector2(size.x * 0.38, 47.0), Vector2(135.0, 70.0))
	var ram := Rect2(Vector2(size.x - 155.0, 150.0), Vector2(130.0, 70.0))
	_draw_box(cpu, "CPU", _t(&"terminology.diagram.cache.load"), ACCENT)
	_draw_box(cache, "CACHE", _t(&"terminology.diagram.cache.line"), GOOD)
	_draw_box(ram, "RAM", _t(&"terminology.diagram.cache.memory"), WARNING)
	_draw_arrow(_right_center(cpu), _left_center(cache), GOOD)
	_draw_text(Rect2(cpu.end.x + 6.0, 53.0, cache.position.x - cpu.end.x - 12.0, 24.0), _t(&"terminology.diagram.cache.hit"), GOOD, 14)
	_draw_polyline(PackedVector2Array([_bottom_center(cache), Vector2(cache.get_center().x, ram.get_center().y), _left_center(ram)]), WARNING)
	_draw_text(Rect2(cache.position.x + 10.0, 159.0, ram.position.x - cache.position.x - 22.0, 24.0), _t(&"terminology.diagram.cache.miss"), WARNING, 14)


func _draw_working_set() -> void:
	_draw_text(Rect2(18.0, 20.0, size.x - 36.0, 24.0), _t(&"terminology.diagram.working_set.phase"), ACCENT, 15)
	var gap := 12.0
	var start_x := 25.0
	var line_width: float = (size.x - 50.0 - gap * 3.0) / 4.0
	for index: int in range(4):
		var line_rect := Rect2(Vector2(start_x + index * (line_width + gap), 68.0), Vector2(line_width, 54.0))
		_draw_box(line_rect, "LINE %d" % index, _t(&"terminology.diagram.working_set.needed"), WARNING)
	var cache_rect := Rect2(Vector2(size.x * 0.34, 161.0), Vector2(size.x * 0.32, 58.0))
	_draw_box(cache_rect, _t(&"terminology.diagram.working_set.cache"), _t(&"terminology.diagram.working_set.one_slot"), DANGER)


func _draw_blocking() -> void:
	_draw_text(Rect2(16.0, 18.0, size.x * 0.46, 24.0), _t(&"terminology.diagram.blocking.before"), MUTED, 15)
	_draw_text(Rect2(size.x * 0.52, 18.0, size.x * 0.46 - 16.0, 24.0), _t(&"terminology.diagram.blocking.after"), GOOD, 15)
	var before: Array[String] = ["L0 P1", "L1 P1", "L0 P2", "L1 P2"]
	var after: Array[String] = ["L0 P1", "L0 P2", "L1 P1", "L1 P2"]
	_draw_schedule(Rect2(18.0, 58.0, size.x * 0.44, 150.0), before, MUTED)
	_draw_schedule(Rect2(size.x * 0.53, 58.0, size.x * 0.44, 150.0), after, GOOD)


func _draw_timeline(rect: Rect2, label: String, parts: Array[String], color: Color) -> void:
	_draw_text(Rect2(rect.position.x, rect.position.y - 25.0, 90.0, 22.0), label, color, 14)
	var label_width := 100.0
	var part_width: float = (rect.size.x - label_width) / parts.size()
	for index: int in range(parts.size()):
		var part_rect := Rect2(Vector2(rect.position.x + label_width + index * part_width, rect.position.y), Vector2(part_width - 4.0, rect.size.y))
		draw_rect(part_rect, Color(color, 0.20), true)
		draw_rect(part_rect, color, false, 1.5)
		_draw_text(part_rect.grow(-4.0), parts[index], TEXT, 14)


func _draw_schedule(rect: Rect2, steps: Array[String], color: Color) -> void:
	var gap := 6.0
	var step_height: float = (rect.size.y - gap * 3.0) / 4.0
	for index: int in range(steps.size()):
		var step_rect := Rect2(Vector2(rect.position.x, rect.position.y + index * (step_height + gap)), Vector2(rect.size.x, step_height))
		draw_rect(step_rect, Color(color, 0.20), true)
		draw_rect(step_rect, color, false, 1.0)
		_draw_text(step_rect.grow(-3.0), steps[index], TEXT, 13)


func _draw_box(rect: Rect2, title: String, subtitle: String, color: Color) -> void:
	draw_rect(rect, PANEL_ACTIVE if color == ACCENT or color == GOOD else PANEL, true)
	draw_rect(rect, color, false, 2.0)
	_draw_text(Rect2(rect.position + Vector2(6.0, 9.0), Vector2(rect.size.x - 12.0, 22.0)), title, color, 15)
	_draw_text(Rect2(rect.position + Vector2(6.0, rect.size.y - 29.0), Vector2(rect.size.x - 12.0, 21.0)), subtitle, TEXT, 13)


func _draw_text(rect: Rect2, value: String, color: Color, font_size: int) -> void:
	var font: Font = get_theme_default_font()
	var resolved_size: int = font_size
	while resolved_size > 11 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, resolved_size).x > rect.size.x:
		resolved_size -= 1
	var baseline: float = rect.position.y + (rect.size.y + font.get_height(resolved_size)) * 0.5 - font.get_descent(resolved_size)
	draw_string(font, Vector2(rect.position.x, baseline), value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, resolved_size, color)


func _draw_arrow(from: Vector2, to: Vector2, color: Color) -> void:
	draw_line(from, to, color, 2.0, true)
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var head := PackedVector2Array([to, to - direction * 9.0 + normal * 5.0, to - direction * 9.0 - normal * 5.0])
	draw_colored_polygon(head, color)


func _draw_polyline(points: PackedVector2Array, color: Color) -> void:
	draw_polyline(points, color, 2.0, true)
	if points.size() >= 2:
		_draw_arrow(points[-2], points[-1], color)


func _left_center(rect: Rect2) -> Vector2:
	return Vector2(rect.position.x, rect.get_center().y)


func _right_center(rect: Rect2) -> Vector2:
	return Vector2(rect.end.x, rect.get_center().y)


func _top_center(rect: Rect2) -> Vector2:
	return Vector2(rect.get_center().x, rect.position.y)


func _bottom_center(rect: Rect2) -> Vector2:
	return Vector2(rect.get_center().x, rect.end.y)


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _t(key: StringName) -> String:
	return Localization.text(key)
