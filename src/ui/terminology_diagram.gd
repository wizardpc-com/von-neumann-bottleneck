class_name TerminologyDiagram
extends Control

const SignalNotationType = preload("res://src/ui/signal_notation.gd")
const LayoutRecipeType = preload("res://src/layout_chapter/layout_recipe.gd")
const LayoutMemoryType = preload("res://src/layout_chapter/layout_memory_view.gd")
const WIDTH_EXAMPLES: Array[int] = [1, 2, 4]
const BATCH_RECORDS: int = 9
const BATCH_CAPACITY: int = 4

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
var example_step: int = 0


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 248.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	Localization.locale_changed.connect(_on_locale_changed)


func set_diagram(value: StringName) -> void:
	diagram_id = value
	example_step = 0
	visible = not diagram_id.is_empty()
	queue_redraw()


func _draw() -> void:
	if diagram_id.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND, true)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER, false, 1.0)
	if String(diagram_id).begins_with("gate_"):
		_draw_gate_example()
		return
	if String(diagram_id).begins_with("layout_"):
		_draw_layout_example(); return
	match diagram_id:
		&"widths": _draw_width_example()
		&"arrival", &"prefetch": _draw_arrival_example()
		&"buffer_states": _draw_buffer_example()
		&"double_buffer": _draw_double_buffer_example()
		&"prefetch_distance": _draw_distance_example()
		&"queue": _draw_queue_example()
		&"signal":
			_draw_signal()
		&"binary":
			_draw_binary()
		&"junction":
			_draw_junction()
		&"truth_table", &"half_adder":
			_draw_truth_table()
		&"register":
			_draw_storage_steps(false)
		&"opcode":
			_draw_opcode()
		&"accumulator":
			_draw_accumulator()
		&"multiplexer":
			_draw_multiplexer()
		&"alu":
			_draw_alu()
		&"sr_latch":
			_draw_storage_steps(true)
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


func multiplexer_example() -> Dictionary:
	return {"a": 0, "b": 1, "select": example_step, "output": example_step}


func _draw_multiplexer() -> void:
	var state: Dictionary = multiplexer_example()
	var center := Rect2(Vector2(size.x * 0.39, 52), Vector2(size.x * 0.26, 122))
	var color: Color = SignalNotationType.width_color(1)
	_draw_text(Rect2(12, 10, size.x - 24, 26), SignalNotationType.width_text(1), color, 17)
	_draw_box(center, "MUX", "S = " + str(state.select), ACCENT)
	for index: int in range(2):
		var y: float = 84 + index * 64
		var active: bool = index == int(state.select)
		var value: int = int(state.a) if index == 0 else int(state.b)
		var label: String = ("A" if index == 0 else "B") + " = " + str(value)
		_draw_text(Rect2(12, y - 28, center.position.x - 24, 24), label, GOOD if active else TEXT, 17)
		_draw_signal_arrow(Vector2(18, y), Vector2(center.position.x, y), value)
	_draw_signal_arrow(_right_center(center), Vector2(size.x - 18, center.get_center().y), int(state.output))
	_draw_text(Rect2(center.end.x + 4, 73, size.x - center.end.x - 12, 27), _t(&"terminology.diagram.multiplexer.output"), TEXT, 14)
	_draw_text(Rect2(center.end.x + 4, 118, size.x - center.end.x - 12, 30), str(state.output), TEXT, 24)
	_draw_signal_arrow(Vector2(center.get_center().x, 206), _bottom_center(center), int(state.select))
	_draw_text(Rect2(12, 213, size.x - 24, 26), _t(&"terminology.diagram.multiplexer.try_select"), MUTED, 14)


func alu_example() -> Dictionary:
	return {"a": 1, "b": 1, "cin": 0, "op1": 1, "op0": 0, "result": 0, "carry": 1}


func _draw_alu() -> void:
	var state: Dictionary = alu_example()
	var alu := Rect2(Vector2(size.x * 0.38, 54), Vector2(size.x * 0.25, 120))
	_draw_text(Rect2(12, 10, size.x - 24, 27), SignalNotationType.width_text(1), SignalNotationType.width_color(1), 17)
	_draw_box(alu, "ALU", "ADD", ACCENT)
	var inputs: Array[String] = ["a", "b", "cin"]
	for index: int in range(inputs.size()):
		var y: float = 77 + index * 36
		var name: String = inputs[index]
		_draw_text(Rect2(12, y - 27, alu.position.x - 24, 24), name.to_upper() + " = " + str(state[name]), TEXT, 16)
		_draw_signal_arrow(Vector2(18, y), Vector2(alu.position.x, y), int(state[name]))
	for index: int in range(2):
		var name: String = "result" if index == 0 else "carry"
		var y: float = 90 + index * 54
		_draw_text(Rect2(alu.end.x + 4, y - 29, size.x - alu.end.x - 12, 25), name.to_upper() + " = " + str(state[name]), TEXT, 15)
		_draw_signal_arrow(Vector2(alu.end.x, y), Vector2(size.x - 18, y), int(state[name]))
	# The first ALU lesson has two scalar controls, not an implicit 2-bit socket.
	_draw_signal_arrow(Vector2(alu.get_center().x - 16, 207), Vector2(alu.get_center().x - 16, alu.end.y), int(state.op1))
	_draw_signal_arrow(Vector2(alu.get_center().x + 16, 207), Vector2(alu.get_center().x + 16, alu.end.y), int(state.op0))
	_draw_text(Rect2(12, 215, size.x - 24, 25), "OP1 = 1      OP0 = 0", TEXT, 15)


func _draw_signal_arrow(from: Vector2, to: Vector2, value: int) -> void:
	var color: Color = SignalNotationType.width_color(1) if value == 1 else MUTED
	SignalNotationType.draw_cable(self, PackedVector2Array([from, to]), color, 1)
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([to, to - direction * 8 + normal * 4, to - direction * 8 - normal * 4]), color)


func _draw_signal() -> void:
	for state: int in [0, 1]:
		var center := Vector2(size.x * (0.27 if state == 0 else 0.73), 103.0)
		var color: Color = SignalNotationType.width_color(1)
		var cell := Rect2(center - Vector2(25, 25), Vector2(50, 50))
		draw_rect(cell, color if state == 1 else PANEL, true)
		draw_rect(cell, color, false, 2.0)
		_draw_text(cell, str(state), BACKGROUND if state == 1 else TEXT, 25)
		_draw_text(Rect2(center.x - 60, 35, 120, 26), SignalNotationType.width_text(1), color, 17)
		_draw_text(Rect2(center.x - 85, 145, 170, 26), _t(&"hardware.signal.low" if state == 0 else &"hardware.signal.high"), TEXT, 16)
	_draw_text(Rect2(12, 199, size.x - 24, 26), _t(&"terminology.diagram.signal.normal"), MUTED, 14)


func _draw_binary() -> void:
	var cell_width: float = minf(94.0, (size.x - 70.0) / 4.0)
	var left: float = (size.x - cell_width * 4.0) * 0.5
	for index: int in range(4):
		var bit: int = 1 if index == 1 else 0
		var x: float = left + cell_width * index
		_draw_text(Rect2(x, 30, cell_width - 8, 28), str(1 << (3 - index)), MUTED, 16)
		_draw_box(Rect2(x, 70, cell_width - 8, 60), str(bit), "", SignalNotationType.width_color(4) if bit else MUTED)
	_draw_text(Rect2(14, 156, size.x - 28, 28), "0100 = 0 + 4 + 0 + 0 = 4", TEXT, 18)
	_draw_text(Rect2(14, 202, size.x - 28, 24), _t(&"terminology.diagram.binary.weights"), MUTED, 14)


func _draw_junction() -> void:
	var half: float = size.x * 0.5
	for index: int in range(2):
		var x: float = half * (index + 0.5)
		draw_line(Vector2(x - 60, 106), Vector2(x + 60, 106), ACCENT, 3.0, true)
		if index == 0:
			draw_line(Vector2(x, 106), Vector2(x, 159), ACCENT, 3.0, true)
			draw_circle(Vector2(x, 106), 6.0, ACCENT)
		else:
			draw_line(Vector2(x, 54), Vector2(x, 159), WARNING, 3.0, true)
		_draw_text(Rect2(half * index + 8, 186, half - 16, 28), _t(&"terminology.diagram.junction.join" if index == 0 else &"terminology.diagram.junction.cross"), TEXT, 15)


func _draw_truth_table() -> void:
	var labels: Array[String] = ["A", "B", "AND", "OR"]
	if diagram_id == &"half_adder":
		labels = ["A", "B", "SUM", "CARRY"]
	var width: float = (size.x - 32.0) / 4.0
	for column: int in range(4):
		_draw_text(Rect2(16 + column * width, 16, width, 30), labels[column], ACCENT, 15)
	for row: int in range(4):
		var a: int = row / 2
		var b: int = row % 2
		var values: Array[int] = [a, b, a & b, a | b]
		if diagram_id == &"half_adder":
			values = [a, b, (a + b) % 2, (a + b) / 2]
		draw_rect(Rect2(16, 53 + row * 43, size.x - 32, 39), Color(PANEL if row % 2 == 0 else BACKGROUND))
		for column: int in range(4):
			_draw_text(Rect2(16 + column * width, 58 + row * 43, width, 28), str(values[column]), GOOD if values[column] else TEXT, 18)


func _draw_storage_steps(latch: bool) -> void:
	var width: float = (size.x - 74.0) / 3.0
	var inputs: Array[String] = ["D=1  LOAD=1", "D=0  LOAD=0", "D=0  LOAD=1"]
	if latch:
		inputs = ["S=1  R=0", "S=0  R=0", "S=0  R=1"]
	var actions: Array[StringName] = [&"terminology.diagram.state.write", &"terminology.diagram.state.hold", &"terminology.diagram.state.clear"]
	for index: int in range(3):
		var rect := Rect2(16 + index * (width + 21), 74, width, 76)
		_draw_text(Rect2(rect.position.x - 4, 29, width + 8, 28), inputs[index], MUTED, 14)
		_draw_box(rect, "Q = %d" % (1 if index < 2 else 0), _t(actions[index]), GOOD if index < 2 else ACCENT)
		if index < 2:
			_draw_arrow(_right_center(rect) + Vector2(2, 0), _right_center(rect) + Vector2(19, 0), ACCENT)
	_draw_text(Rect2(12, 189, size.x - 24, 36), _t(&"terminology.diagram.state.sequence"), TEXT, 14)


func _draw_opcode() -> void:
	_draw_text(Rect2(12, 14, size.x - 24, 28), _t(&"terminology.diagram.opcode.example"), TEXT, 16)
	var codes: Array[String] = ["00", "01", "10", "11"]
	var operations: Array[String] = ["AND", "OR", "ADD", "NOT A"]
	var results: Array[int] = [0, 1, 1, 0]
	for row: int in range(4):
		var y: float = 55 + row * 43
		draw_rect(Rect2(18, y, size.x - 36, 38), PANEL)
		_draw_text(Rect2(25, y + 4, size.x * 0.22, 30), codes[row], ACCENT, 17)
		_draw_text(Rect2(size.x * 0.32, y + 4, size.x * 0.30, 30), operations[row], TEXT, 16)
		_draw_text(Rect2(size.x * 0.64, y + 4, size.x * 0.31, 30), "RESULT = %d" % results[row], GOOD if results[row] else TEXT, 16)


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


func cache_example_boxes() -> Dictionary:
	var box_size := Vector2(minf(135, (size.x - 60) * 0.5), 70)
	return {"cpu": Rect2(Vector2(20, 60), box_size),
		"cache": Rect2(Vector2(size.x - 20 - box_size.x, 60), box_size),
		"ram": Rect2(Vector2(size.x - 20 - box_size.x, 154), box_size)}


func cache_hit_arrow() -> PackedVector2Array:
	var boxes: Dictionary = cache_example_boxes()
	return PackedVector2Array([_left_center(boxes.cache), _right_center(boxes.cpu)])


func _draw_cache() -> void:
	var boxes: Dictionary = cache_example_boxes()
	var cpu: Rect2 = boxes.cpu
	var cache: Rect2 = boxes.cache
	var ram: Rect2 = boxes.ram
	_draw_box(cpu, "CPU", _t(&"terminology.diagram.cache.load"), ACCENT)
	_draw_box(cache, "CACHE", _t(&"terminology.diagram.cache.line"), GOOD)
	_draw_box(ram, "RAM", _t(&"terminology.diagram.cache.memory"), WARNING)
	var hit: PackedVector2Array = cache_hit_arrow()
	_draw_arrow(hit[0], hit[1], GOOD)
	_draw_text(Rect2(14, 16, size.x - 28, 27), _t(&"terminology.diagram.cache.hit"), GOOD, 15)
	_draw_arrow(_bottom_center(cache), _top_center(ram), WARNING)
	_draw_wrapped_text(Rect2(14, 163, ram.position.x - 26, 61), _t(&"terminology.diagram.cache.miss"), WARNING, 14)


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


func example_count() -> int:
	if String(diagram_id).begins_with("gate_"): return 2 if diagram_id == &"gate_not" else 4
	match diagram_id:
		&"widths": return WIDTH_EXAMPLES.size()
		&"layout_data_layout", &"layout_field_group", &"multiplexer": return 2
		&"layout_copy_cost", &"layout_bounded_batch": return 3
		&"arrival", &"prefetch", &"queue": return 3
		&"buffer_states", &"double_buffer", &"prefetch_distance": return 4
	return 1


func advance_example(direction: int) -> void:
	example_step = posmod(example_step+direction,example_count())
	queue_redraw()


func _draw_width_example() -> void:
	var width: int = WIDTH_EXAMPLES[example_step]
	var color: Color = SignalNotationType.width_color(width)
	var value: int = 1 if width == 1 else 2 if width == 2 else 5
	_draw_text(Rect2(16,14,size.x-32,28),SignalNotationType.width_text(width),color,20)
	SignalNotationType.draw_cable(self,PackedVector2Array([Vector2(30,76),Vector2(size.x-30,76)]),color,width)
	if width == 1: draw_circle(Vector2(size.x-30,76),6,color)
	else: draw_rect(Rect2(size.x-36,70,12,12),color,false,2)
	var cell: float = minf(65,(size.x-40)/width)
	var left: float = (size.x-cell*width)*0.5
	for index: int in range(width):
		var bit: int = (value >> (width-index-1)) & 1
		var rect := Rect2(left+index*cell,110,cell-6,62)
		draw_rect(rect, PANEL_ACTIVE if bit else PANEL, true)
		draw_rect(rect, color if bit else MUTED, false, 2.0)
		_draw_text(rect, str(bit), color if bit else MUTED, 24)
	_draw_text(Rect2(16,190,size.x-32,30),_t(&"terminology.diagram.width_value") % [value,(1<<width)-1],TEXT,16)


func _draw_gate_example() -> void:
	var gate: String = String(diagram_id).trim_prefix("gate_")
	var a: int = example_step if gate == "not" else example_step/2
	var b: int = example_step%2
	var output: int = 1-a if gate == "not" else a & b if gate == "and" else a | b if gate == "or" else a ^ b if gate == "xor" else 1-(a|b)
	var rect := Rect2(size.x*0.36,64,size.x*0.28,94)
	_draw_box(rect,gate.to_upper(),"",ACCENT)
	_draw_text(Rect2(8,50,size.x*0.25,30),"A = %d" % a,TEXT,20)
	_draw_arrow(Vector2(24,94),Vector2(rect.position.x,94),WARNING if a else MUTED)
	if gate != "not":
		_draw_text(Rect2(8,158,size.x*0.25,30),"B = %d" % b,TEXT,20)
		_draw_arrow(Vector2(24,136),Vector2(rect.position.x,136),WARNING if b else MUTED)
	_draw_arrow(_right_center(rect),Vector2(size.x-30,rect.get_center().y),WARNING if output else MUTED)
	_draw_text(Rect2(size.x*0.70,58,size.x*0.28,35),str(output),TEXT,24)
	_draw_text(Rect2(16,204,size.x-32,26),_t(&"terminology.diagram.gate_try"),MUTED,14)


func _draw_arrival_example() -> void:
	var labels: Array[StringName] = [&"request",&"moving",&"arrived"]
	var x: float = 20+(size.x-112)*float(example_step)/2.0
	_draw_text(Rect2(12,12,size.x-24,30),_t(StringName("teaching."+String(labels[example_step]))),ACCENT,19)
	SignalNotationType.draw_cable(self,PackedVector2Array([Vector2(38,115),Vector2(size.x-38,115)]),ACCENT,8)
	_draw_box(Rect2(x,77,72, 70),"5", SignalNotationType.width_text(8),GOOD)
	_draw_text(Rect2(12,170,size.x-24,30),_t(StringName("teaching.arrival."+str(example_step))),TEXT,16)
	_draw_text(Rect2(12,211,size.x-24,24),_t(&"teaching.model_note"),MUTED,13)


func _draw_buffer_example() -> void:
	var states: Array[String] = ["empty","filling","ready","in_use"]
	var cell: float = (size.x-38)/4
	for index: int in range(4):
		var rect := Rect2(16+index*cell,32,cell-6,66)
		_draw_box(rect,str(index+1),_t(StringName("overlap.state."+states[index])),ACCENT if index==example_step else MUTED)
	_draw_text(Rect2(16,125,size.x-32,30),"ready = %d       free = %d" % [1 if example_step==2 else 0,1 if example_step==0 else 0],WARNING,20)
	_draw_text(Rect2(16,174,size.x-32,34),_t(StringName("teaching.buffer."+str(example_step))),TEXT,15)


func _draw_distance_example() -> void:
	var values: Array[String] = ["—","A","B","A"]
	_draw_box(Rect2(size.x*0.3,34,size.x*0.4,100),"Cache · 1","",ACCENT)
	_draw_text(Rect2(size.x*0.3,74,size.x*0.4,45),values[example_step],TEXT,30)
	_draw_text(Rect2(14,147,size.x-28,35),_t(StringName("teaching.distance."+str(example_step))),TEXT,16)
	_draw_text(Rect2(14,202,size.x-28,25),_t(&"teaching.cache_auto"),MUTED,14)


func _draw_queue_example() -> void:
	var cell: float = (size.x-70)*0.5
	for index: int in range(2):
		_draw_box(Rect2(22+index*(cell+20),60,cell,83),_t(&"teaching.active" if index==0 else &"teaching.queued"),str(index) if example_step>index else "—",ACCENT if example_step>index else MUTED)
	_draw_text(Rect2(16,175,size.x-32,32),_t(StringName("teaching.queue."+str(example_step))),TEXT,15)


func _draw_double_buffer_example() -> void:
	var stages: Array = [["ready","empty"],["in_use","filling"],["empty","ready"],["filling","in_use"]]
	var cell: float = (size.x-66)*0.5
	for index: int in range(2):
		var state: String = stages[example_step][index]
		_draw_box(Rect2(20+index*(cell+26),54,cell,95),"A" if index==0 else "B",_t(StringName("overlap.state."+state)),GOOD if state=="in_use" else ACCENT)
	_draw_text(Rect2(16,182,size.x-32,36),_t(StringName("teaching.double_buffer."+str(example_step))),TEXT,15)

func _draw_layout_example() -> void:
	match diagram_id:
		&"layout_copy_cost":
			_draw_copy_cost_example()
		&"layout_bounded_batch":
			_draw_batch_example()
		_:
			_draw_layout_mapping_example()


# Use the same address mapper and field identity as the playable memory view.
# The grouping is deliberately a small neutral example, not the hot/cold solution.
func layout_example_mapping() -> Dictionary:
	var recipe: Dictionary = LayoutRecipeType.record_major() if example_step == 0 else LayoutRecipeType.field_major()
	if diagram_id == &"layout_field_group":
		var order: String = "record" if example_step == 0 else "field"
		recipe = {"groups": [{"fields": [0, 1], "order": order}, {"fields": [2, 3], "order": order}], "block": 0}
	return LayoutRecipeType.mapping(recipe, 2)


func _draw_layout_mapping_example() -> void:
	var map: Dictionary = layout_example_mapping()
	var grouped: bool = diagram_id == &"layout_field_group"
	var title_key := StringName("terminology.diagram.layout." + ("group_" if grouped else "") + ("record" if example_step == 0 else "field"))
	_draw_text(Rect2(12, 10, size.x - 24, 28), _t(title_key), TEXT, 17)
	var cell_width: float = (size.x - 84.0) / 4.0
	for row: int in range(int(map.bytes) / LayoutRecipeType.LINE_BYTES):
		var y: float = 48.0 + row * 63.0
		draw_rect(Rect2(66, y, size.x - 78, 58), PANEL, true)
		draw_rect(Rect2(66, y, size.x - 78, 58), BORDER, false, 1.0)
		_draw_text(Rect2(6, y, 54, 58), str(row * LayoutRecipeType.LINE_BYTES) + " B", MUTED, 13)
	var chinese: bool = TranslationServer.get_locale().begins_with("zh")
	for cell: Dictionary in map.cells:
		var address: int = int(cell.address)
		var field: int = int(cell.field)
		var rect := Rect2(70 + (address % LayoutRecipeType.LINE_BYTES) / LayoutRecipeType.WORD_BYTES * cell_width,
			52 + int(address / LayoutRecipeType.LINE_BYTES) * 63, cell_width - 5, 50)
		var color: Color = LayoutMemoryType.COLORS[field]
		draw_rect(rect, Color(color, 0.15))
		draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), color)
		var field_name: String = (LayoutMemoryType.NAMES if chinese else LayoutMemoryType.EN_NAMES)[field]
		_draw_text(Rect2(rect.position + Vector2(4, 2), Vector2(rect.size.x - 8, 24)), field_name, color, 15)
		_draw_text(Rect2(rect.position + Vector2(4, 25), Vector2(rect.size.x - 8, 22)), "#" + str(cell.record), TEXT, 14)
	_draw_wrapped_text(Rect2(12, 181, size.x - 24, 57), _t(&"terminology.diagram.layout.legend"), MUTED, 14)


func _draw_copy_cost_example() -> void:
	var keys: Array[StringName] = [&"terminology.diagram.copy.read", &"terminology.diagram.copy.write", &"terminology.diagram.copy.query"]
	_draw_text(Rect2(12, 10, size.x - 24, 28), _t(&"terminology.diagram.copy.title"), TEXT, 17)
	var width: float = (size.x - 58) / 3.0
	for index: int in range(3):
		var rect := Rect2(14 + index * (width + 15), 64, width, 74)
		var color: Color = ACCENT if index == example_step else MUTED
		_draw_box(rect, str(index + 1), _t(keys[index]), color)
		if index < 2:
			_draw_arrow(_right_center(rect) + Vector2(2, 0), _right_center(rect) + Vector2(13, 0), MUTED)
	_draw_wrapped_text(Rect2(14, 163, size.x - 28, 73), _t(StringName("terminology.diagram.copy.step." + str(example_step))), TEXT, 15)


func batch_example() -> Dictionary:
	var first: int = example_step * BATCH_CAPACITY
	var count: int = mini(BATCH_CAPACITY, BATCH_RECORDS - first)
	# All four fields are copied in this example; aligned scratch storage comes
	# from the actual mapper rather than a decorative, fixed-size batch picture.
	var map: Dictionary = LayoutRecipeType.mapping(LayoutRecipeType.field_major(), count)
	var full_map: Dictionary = LayoutRecipeType.mapping(LayoutRecipeType.field_major(), BATCH_CAPACITY)
	return {"first": first, "count": count, "bytes": int(map.bytes), "capacity_bytes": int(full_map.bytes)}


func _draw_batch_example() -> void:
	var batch: Dictionary = batch_example()
	_draw_text(Rect2(12, 10, size.x - 24, 28), _t(&"terminology.diagram.batch.title"), TEXT, 16)
	var width: float = (size.x - 30) / float(BATCH_RECORDS)
	for record: int in range(BATCH_RECORDS):
		var active: bool = record >= int(batch.first) and record < int(batch.first) + int(batch.count)
		var rect := Rect2(15 + record * width, 48, width - 4, 34)
		draw_rect(rect, PANEL_ACTIVE if active else PANEL, true)
		draw_rect(rect, ACCENT if active else BORDER, false, 1.0)
		_draw_text(rect, "#" + str(record), TEXT if active else MUTED, 13)
	var scratch := Rect2(20, 111, size.x - 40, 73)
	draw_rect(scratch, PANEL, true)
	draw_rect(scratch, ACCENT, false, 1.5)
	_draw_arrow(Vector2(size.x * 0.5, 85), Vector2(size.x * 0.5, 108), ACCENT)
	_draw_text(Rect2(scratch.position + Vector2(5, 4), Vector2(scratch.size.x - 10, 25)),
		_t(&"terminology.diagram.batch.storage") % [int(batch.count), int(batch.bytes)], ACCENT, 16)
	var range_text: String = _t(&"terminology.diagram.batch.single") % int(batch.first) if int(batch.count) == 1 else _t(&"terminology.diagram.batch.range") % [int(batch.first), int(batch.first) + int(batch.count) - 1]
	_draw_text(Rect2(scratch.position + Vector2(5, 46), Vector2(scratch.size.x - 10, 22)), range_text, TEXT, 14)
	var meter := Rect2(27, 143, size.x - 54, 10)
	draw_rect(meter, BACKGROUND, true)
	draw_rect(batch_storage_fill(), ACCENT, true)
	for boundary: int in range(1, BATCH_CAPACITY):
		var x: float = meter.position.x + meter.size.x * float(boundary) / BATCH_CAPACITY
		draw_line(Vector2(x, meter.position.y), Vector2(x, meter.end.y), BORDER, 1.0)
	draw_rect(meter, BORDER, false, 1.0)
	_draw_wrapped_text(Rect2(12, 191, size.x - 24, 48), _t(&"terminology.diagram.batch.sequence"), MUTED, 14)


func batch_storage_fill() -> Rect2:
	var batch: Dictionary = batch_example()
	var fraction: float = float(batch.bytes) / float(batch.capacity_bytes)
	return Rect2(27, 143, (size.x - 54) * fraction, 10)


func wrapped_text_layout(rect: Rect2, value: String, font_size: int) -> Dictionary:
	var font: Font = get_theme_default_font()
	var resolved_size: int = font_size
	var measured: Vector2 = font.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, resolved_size)
	while resolved_size > 12 and measured.y > rect.size.y:
		resolved_size -= 1
		measured = font.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, resolved_size)
	return {"font_size": resolved_size, "measured": measured,
		"max_lines": maxi(1, floori(rect.size.y / font.get_height(resolved_size)))}


func _draw_wrapped_text(rect: Rect2, value: String, color: Color, font_size: int) -> void:
	var font: Font = get_theme_default_font()
	var layout: Dictionary = wrapped_text_layout(rect, value, font_size)
	draw_multiline_string(font, rect.position + Vector2(0, font.get_ascent(int(layout.font_size))), value,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, int(layout.font_size), int(layout.max_lines), color)
