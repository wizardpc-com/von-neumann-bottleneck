class_name SignalNotation
extends RefCounted

const SCALAR_STROKE: float = 3.5
const BUS_STROKE: float = 8.0
const BUS_CORE := Color("101b28")
static var _bus_port_icon: Texture2D


static func wire_stroke_width(width: int) -> float:
	return SCALAR_STROKE if width == 1 else BUS_STROKE


static func draw_cable(surface: Control, points: PackedVector2Array, color: Color, width: int) -> void:
	if points.size() < 2:
		return
	surface.draw_polyline(points, color, wire_stroke_width(width), true)
	if width > 1:
		# A single centered ribbon, never separate selectable parallel connections.
		surface.draw_polyline(points, BUS_CORE, 3.0, true)


static func bus_port_icon() -> Texture2D:
	if _bus_port_icon == null:
		# Same 24px interaction canvas and center as the scalar disk.
		var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
		for y: int in range(6, 18):
			for x: int in range(6, 18):
				if x < 9 or x >= 15 or y < 9 or y >= 15:
					image.set_pixel(x, y, Color.WHITE)
		_bus_port_icon = ImageTexture.create_from_image(image)
	return _bus_port_icon


static func wire_sample(width: int) -> Control:
	var sample := Control.new()
	sample.custom_minimum_size = Vector2(52, 28)
	sample.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sample.draw.connect(func() -> void:
		var color: Color = width_color(width)
		draw_cable(sample, PackedVector2Array([Vector2(3, 14), Vector2(42, 14)]), color, width)
		if width == 1:
			sample.draw_circle(Vector2(43, 14), 5.0, color)
		else:
			sample.draw_rect(Rect2(37, 8, 12, 12), BUS_CORE)
			sample.draw_rect(Rect2(37, 8, 12, 12), color, false, 2.0)
	)
	return sample

# Width colors are stable; they do not encode the current voltage or wire color.
static func width_color(width: int) -> Color:
	match width:
		1: return Color("f4bf75")
		2: return Color("c0a2ff")
		_: return Color("72ceff")


static func width_text(width: int) -> String:
	return _t(&"signal.width", [width])


static func bits(width: int, value: int, known: bool = true) -> PackedStringArray:
	var result := PackedStringArray()
	for index: int in range(width):
		result.append(str((value >> (width - index - 1)) & 1) if known else "·")
	return result


static func badge(width: int) -> Label:
	var label := Label.new()
	label.text = width_text(width)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", width_color(width))
	label.tooltip_text = _t(&"signal.width.range", [width, (1 << width) - 1])
	return label


static func value_row(width: int, value: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "SignalBits"
	row.add_theme_constant_override("separation", 4)
	for index: int in range(width):
		var cell := Label.new()
		cell.name = "Bit%d" % index
		cell.custom_minimum_size = Vector2(24.0, 28.0)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_theme_font_size_override("font_size", 15)
		cell.tooltip_text = _t(&"signal.bit.weight", [1 << (width - index - 1)])
		row.add_child(cell)
	var decimal := Label.new()
	decimal.name = "Decimal"
	decimal.add_theme_font_size_override("font_size", 15)
	row.add_child(decimal)
	refresh_value_row(row, width, value)
	return row


static func refresh_value_row(row: HBoxContainer, width: int, value: int) -> void:
	var digits := bits(width, value)
	for index: int in range(width):
		var cell: Label = row.get_node("Bit%d" % index)
		var lit: bool = digits[index] == "1"
		cell.text = digits[index]
		cell.add_theme_color_override("font_color", Color("0b1724") if lit else Color("a9bacb"))
		var style := StyleBoxFlat.new()
		style.bg_color = width_color(width) if lit else Color("172638")
		style.border_color = width_color(width).darkened(0.35)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		cell.add_theme_stylebox_override("normal", style)
	(row.get_node("Decimal") as Label).text = " = %d" % value


static func guide(widths: Array[int]) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "SignalGuide"
	box.add_theme_constant_override("separation", 6)
	var examples := HFlowContainer.new()
	examples.add_theme_constant_override("h_separation", 20)
	box.add_child(examples)
	for width: int in widths:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(wire_sample(width))
		row.add_child(badge(width))
		row.add_child(value_row(width, 1 if width == 1 else 2 if width == 2 else 4))
		var limits := Label.new()
		limits.text = _t(&"signal.range", [(1 << width) - 1])
		limits.add_theme_font_size_override("font_size", 13)
		limits.add_theme_color_override("font_color", Color("a9bacb"))
		row.add_child(limits)
		examples.add_child(row)
	var note := Label.new()
	note.text = _t(&"signal.guide.word" if widths.has(4) else &"signal.guide.basic")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color("a9bacb"))
	box.add_child(note)
	var wire_note := Label.new()
	wire_note.text = _t(&"signal.wire.guide.word" if widths.size() > 1 else &"signal.wire.guide.basic")
	wire_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wire_note.add_theme_font_size_override("font_size", 13)
	wire_note.add_theme_color_override("font_color", Color("a9bacb"))
	box.add_child(wire_note)
	box.move_child(wire_note, 1)
	return box


static func _t(key: StringName, values: Array = []) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node("Localization").call("text", key, values)
