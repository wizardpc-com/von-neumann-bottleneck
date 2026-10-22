class_name SystemDeviceSurface
extends Control

const VisualStyle = preload("res://src/hardware_foundations/component_visual_style.gd")
const BACKGROUND := Color("0c1422")
const OUTLINE := Color("52637d")
const ACCENT := Color("7fcbd6")
const GOOD := Color("7fd8a4")
const WARNING := Color("f0c674")
const MUTED := Color("74839b")

var device_kind: StringName = &"cpu"
var activity_kind: StringName = &""
var activity_progress: float = 0.0
var activity_details: Dictionary = {}
var waiting: bool = false
var selection_active: bool = false
var bus_bandwidth: int = 2


func _ready() -> void:
	custom_minimum_size = Vector2(190.0, 122.0 if device_kind == &"bus" else 120.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure(kind: StringName) -> void:
	device_kind = kind
	queue_redraw()


func show_activity(kind: StringName, progress: float, details: Dictionary = {}) -> void:
	activity_kind = kind
	activity_progress = clampf(progress, 0.0, 1.0)
	activity_details = details.duplicate(true)
	waiting = bool(details.get("cpu_waiting", false)) and device_kind == &"cpu"
	queue_redraw()


func clear_activity() -> void:
	activity_kind = &""
	activity_progress = 0.0
	activity_details.clear()
	waiting = false
	queue_redraw()


func set_selection_active(active: bool) -> void:
	if selection_active == active:
		return
	selection_active = active
	queue_redraw()


func outline_color(base_color: Color = OUTLINE) -> Color:
	return VisualStyle.SELECTED if selection_active else VisualStyle.accent(device_kind) if base_color == OUTLINE else base_color


func _draw() -> void:
	match device_kind:
		&"cpu":
			_draw_cpu()
		&"ram":
			_draw_ram()
		&"bus":
			_draw_bus()


func is_computing() -> bool:
	return device_kind == &"cpu" and activity_kind == &"compute" and not waiting


func active_memory_row() -> int:
	if device_kind != &"ram" or activity_kind not in [&"ram_read", &"ram_write"]:
		return -1
	var index: int = int(activity_details.get("index", -1))
	return index % 4 if index >= 0 else -1


func _draw_device_shell(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = VisualStyle.shell(device_kind, rect)
	draw_colored_polygon(points, VisualStyle.SURFACE)
	points.append(points[0])
	draw_polyline(points, outline_color(color), 3.0 if selection_active else 2.0, true)
	draw_rect(Rect2(rect.position + Vector2(9.0, 9.0), Vector2(3.0, 15.0)), VisualStyle.accent(device_kind))
	var font: Font = get_theme_font("font", "Label")
	draw_string(font, rect.position + Vector2(20.0, 22.0), String(device_kind).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, VisualStyle.TEXT)


func _draw_inset_panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = fill
	panel.border_color = border
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(radius)
	draw_style_box(panel, rect)


func _draw_cpu() -> void:
	var chip := Rect2(12.0, 6.0, size.x - 24.0, size.y - 12.0)
	_draw_device_shell(chip, WARNING if waiting else OUTLINE)
	# System ports belong to the host GraphNode; these blocks are functional symbols.
	var gap: float = 7.0
	var block_size := Vector2((chip.size.x - 32.0 - gap * 2.0) / 3.0, chip.size.y - 45.0)
	var blocks: Array[Rect2] = []
	var accent: Color = VisualStyle.accent(device_kind)
	for block_index: int in range(3):
		var block := Rect2(chip.position + Vector2(16.0 + float(block_index) * (block_size.x + gap), 33.0), block_size)
		blocks.append(block)
		_draw_inset_panel(block, Color("142334"), Color("3c5266"), 4)
		var font: Font = get_theme_font("font", "Label")
		var tag: String = ["CTRL", "ALU", "REG"][block_index]
		draw_string(font, block.position + Vector2(0.0, 13.0), tag, HORIZONTAL_ALIGNMENT_CENTER, block.size.x, 10, MUTED)
	var control_center: Vector2 = blocks[0].get_center() + Vector2(0.0, 7.0)
	for branch: int in range(4):
		var y: float = control_center.y + (float(branch) - 1.5) * 5.0
		draw_line(Vector2(control_center.x - 6.0, y), Vector2(control_center.x + 7.0, y), accent, 1.5, true)
		draw_polyline(PackedVector2Array([Vector2(control_center.x + 4.0, y - 2.0), Vector2(control_center.x + 7.0, y), Vector2(control_center.x + 4.0, y + 2.0)]), accent, 1.5, true)
	draw_line(control_center + Vector2(-6.0, -7.5), control_center + Vector2(-6.0, 7.5), accent, 1.5, true)
	draw_line(control_center + Vector2(-11.0, 0.0), control_center + Vector2(-6.0, 0.0), accent, 1.5, true)
	var compute_center: Vector2 = blocks[1].get_center() + Vector2(0.0, 7.0)
	draw_circle(compute_center, 9.0, accent, false, 1.5, true)
	draw_line(compute_center - Vector2(5.0, 0.0), compute_center + Vector2(5.0, 0.0), accent, 1.5, true)
	draw_line(compute_center - Vector2(0.0, 5.0), compute_center + Vector2(0.0, 5.0), accent, 1.5, true)
	var register_center: Vector2 = blocks[2].get_center() + Vector2(0.0, 7.0)
	draw_rect(Rect2(register_center - Vector2(10.0, 7.0), Vector2(20.0, 14.0)), accent, false, 1.5)
	for divider: int in range(1, 4):
		var x: float = register_center.x - 10.0 + float(divider) * 5.0
		draw_line(Vector2(x, register_center.y - 7.0), Vector2(x, register_center.y + 7.0), accent, 1.0, true)
	for side: float in [-1.0, 1.0]:
		draw_line(register_center + Vector2(side * 13.0, -5.0), register_center + Vector2(side * 13.0, 5.0), accent, 1.5, true)
	if is_computing():
		var start := Vector2(chip.position.x + 66.0, chip.position.y + 17.0)
		var finish := Vector2(chip.end.x - 18.0, start.y)
		draw_line(start, finish, Color(ACCENT, 0.24), 3.0, true)
		draw_circle(start.lerp(finish, activity_progress), 4.0, ACCENT)
		for block_index: int in range(blocks.size()):
			var phase: float = clampf(activity_progress * 3.0 - float(block_index), 0.0, 1.0)
			if phase > 0.0:
				draw_rect(blocks[block_index].grow(-2.0), Color(ACCENT, 0.12 + 0.20 * sin(phase * PI)), true)
	if waiting:
		# A stationary pause mark keeps memory latency distinct from computation.
		var center := Vector2(chip.end.x - 24.0, chip.position.y + 17.0)
		draw_line(center + Vector2(-4.0, -5.0), center + Vector2(-4.0, 5.0), WARNING, 3.0, true)
		draw_line(center + Vector2(4.0, -5.0), center + Vector2(4.0, 5.0), WARNING, 3.0, true)


func _draw_ram() -> void:
	var outer := Rect2(12.0, 6.0, size.x - 24.0, size.y - 12.0)
	_draw_device_shell(outer, OUTLINE)
	var columns: int = 8
	var rows: int = 4
	var gap: float = 3.0
	var grid := Rect2(outer.position + Vector2(16.0, 33.0), outer.size - Vector2(32.0, 45.0))
	var cell_size := Vector2(
		(grid.size.x - gap * float(columns - 1)) / float(columns),
		(grid.size.y - gap * float(rows - 1)) / float(rows)
	)
	var active_row: int = active_memory_row()
	# Rows illustrate the trace address modulo this schematic, never RAM capacity.
	for row: int in range(rows):
		for column: int in range(columns):
			var rect := Rect2(grid.position + Vector2(float(column) * (cell_size.x + gap), float(row) * (cell_size.y + gap)), cell_size)
			var active_cell: bool = row == active_row
			var wave: bool = float(column) / float(columns) <= activity_progress
			var fill := Color("142334")
			if active_cell and wave:
				fill = Color(GOOD if activity_kind == &"ram_read" else WARNING, 0.66)
			_draw_inset_panel(rect, fill, Color("3c5266"), 2)


func set_bus_bandwidth(bits_per_cycle: int) -> void:
	bus_bandwidth = clampi(bits_per_cycle, 1, 8)
	queue_redraw()


# A read-only illustration: event details own the word and transfer count.
# Visual grouping does not define a physical serial bit order.
func bus_presentation() -> Dictionary:
	var transferring: bool = activity_kind in [&"read_data", &"write_data"]
	var width: int = clampi(int(activity_details.get("bits_per_cycle", bus_bandwidth)), 1, 8) if transferring else bus_bandwidth
	var groups: int = maxi(1, int(activity_details.get("segments", ceili(8.0 / float(width))))) if transferring else ceili(8.0 / float(width))
	return {
		"width": width, "groups": groups, "transferring": transferring,
		"group": mini(groups - 1, int(floor(activity_progress * float(groups)))) if transferring else -1,
		"value": int(activity_details.get("value", 0)) & 255,
	}


func _draw_bus() -> void:
	_draw_device_shell(Rect2(Vector2(1.0, 1.0), Vector2(size.x - 2.0, 85.0)), OUTLINE)
	var view: Dictionary = bus_presentation()
	var width: int = view["width"]
	var groups: int = ceili(8.0 / float(width))
	var active_group: int = view["group"]
	var transferring: bool = view["transferring"]
	var color: Color = GOOD if activity_kind == &"read_data" else WARNING
	var heading: String = _bus_text(&"system.bus.diagram.idle")
	if transferring:
		heading = ("← " if activity_kind == &"read_data" else "→ ") + _bus_text(&"system.bus.diagram.value", [view["value"]])
	_draw_bus_caption(heading, 99.0, VisualStyle.accent(device_kind))
	var gap: float = 3.0
	var group_gap: float = 9.0
	var left: float = 8.0
	var cell_width: float = (size.x - left * 2.0 - gap * float(8 - groups) - group_gap * float(groups - 1)) / 8.0
	for group: int in range(groups):
		var count: int = mini(width, 8 - group * width)
		var group_width: float = float(count) * cell_width + float(count - 1) * gap
		var group_color: Color = color if transferring and group == active_group else OUTLINE
		var rect := Rect2(left - 3.0, 34.0, group_width + 6.0, 30.0)
		draw_style_box(_bus_group_style(group_color, transferring and group == active_group), rect)
		for bit: int in range(count):
			var position := Vector2(left + float(bit) * (cell_width + gap), 37.0)
			var high: bool = (int(view["value"]) & (1 << (7 - group * width - bit))) != 0
			var fill: Color = Color(color, 0.65) if transferring and high else BACKGROUND
			_draw_inset_panel(Rect2(position, Vector2(cell_width, 23.0)), fill, Color("3c5266"), 2)
			var digit: String = str(int(high)) if transferring else "·"
			var font: Font = get_theme_font("font", "Label")
			var digit_width: float = font.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string(font, position + Vector2((cell_width - digit_width) * 0.5, 18.0), digit, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e2ebef"))
		left += group_width + group_gap
	var caption: String = _bus_text(&"system.bus.diagram.capacity", [width, view["groups"]])
	if transferring:
		caption = _bus_text(&"system.bus.diagram.progress", [width, active_group + 1, view["groups"]])
	_draw_bus_caption(caption, 113.0, color if transferring else Color("b0c1d5"))
	if transferring:
		var start := Vector2(16.0, 74.0)
		var finish := Vector2(size.x - 16.0, 74.0)
		if activity_kind == &"read_data":
			var swap: Vector2 = start
			start = finish
			finish = swap
		draw_line(start, finish, color, 1.5, true)
		var direction: float = signf(start.x - finish.x)
		draw_polyline(PackedVector2Array([finish + Vector2(direction * 5.0, -3.0), finish, finish + Vector2(direction * 5.0, 3.0)]), color, 1.5, true)


func _bus_group_style(color: Color, active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.10 if active else 0.04)
	style.border_color = outline_color(color)
	style.set_border_width_all(2 if active or selection_active else 1)
	style.set_corner_radius_all(4)
	return style


func _draw_bus_caption(text: String, baseline: float, color: Color) -> void:
	var font: Font = get_theme_font("font", "Label")
	var font_size: int = 14
	while font_size > 11 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > size.x - 8.0:
		font_size -= 1
	draw_string(font, Vector2(4.0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8.0, font_size, color)


func _bus_text(key: StringName, values: Array = []) -> String:
	return get_node("/root/Localization").call("text", key, values)
