class_name SystemDeviceSurface
extends Control

const BACKGROUND := Color("0c1422")
const OUTLINE := Color("52637d")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const WARNING := Color("ffbf69")
const MUTED := Color("74839b")

var device_kind: StringName = &"cpu"
var activity_kind: StringName = &""
var activity_progress: float = 0.0
var activity_details: Dictionary = {}
var waiting: bool = false
var selection_active: bool = false
var bus_bandwidth: int = 2


func _ready() -> void:
	custom_minimum_size = Vector2(190.0, 110.0 if device_kind == &"bus" else 84.0)
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
	return ACCENT if selection_active else base_color


func _draw() -> void:
	match device_kind:
		&"cpu":
			_draw_cpu()
		&"ram":
			_draw_ram()
		&"bus":
			_draw_bus()


func _draw_cpu() -> void:
	var chip := Rect2(24.0, 10.0, size.x - 48.0, size.y - 20.0)
	draw_rect(chip, BACKGROUND, true)
	draw_rect(chip, outline_color(WARNING if waiting else OUTLINE), false, 3.0 if selection_active else 2.0)
	for pin_index: int in range(5):
		var y: float = chip.position.y + 10.0 + float(pin_index) * (chip.size.y - 20.0) / 4.0
		draw_line(Vector2(chip.position.x - 8.0, y), Vector2(chip.position.x, y), OUTLINE, 2.0)
		draw_line(Vector2(chip.end.x, y), Vector2(chip.end.x + 8.0, y), OUTLINE, 2.0)
	var blocks: Array[Rect2] = [
		Rect2(chip.position + Vector2(15.0, 13.0), Vector2(31.0, chip.size.y - 26.0)),
		Rect2(chip.position + Vector2(56.0, 13.0), Vector2(38.0, chip.size.y - 26.0)),
		Rect2(chip.end - Vector2(45.0, chip.size.y - 13.0), Vector2(30.0, chip.size.y - 26.0)),
	]
	for block: Rect2 in blocks:
		draw_rect(block, Color("142238"), true)
		draw_rect(block, Color(OUTLINE, 0.65), false, 1.0)
	if not activity_kind.is_empty():
		var center_y: float = chip.get_center().y
		var start := Vector2(chip.position.x + 12.0, center_y)
		var finish := Vector2(chip.end.x - 12.0, center_y)
		draw_line(start, finish, Color(ACCENT, 0.24), 5.0)
		var cursor := start.lerp(finish, activity_progress)
		draw_circle(cursor, 5.0, WARNING if waiting else ACCENT)
		if activity_kind == &"compute":
			for block_index: int in range(blocks.size()):
				var phase: float = clampf(activity_progress * 3.0 - float(block_index), 0.0, 1.0)
				if phase > 0.0:
					draw_rect(blocks[block_index].grow(-2.0), Color(ACCENT, 0.12 + 0.20 * sin(phase * PI)), true)


func _draw_ram() -> void:
	var outer := Rect2(30.0, 8.0, size.x - 60.0, size.y - 16.0)
	draw_rect(outer, BACKGROUND, true)
	draw_rect(outer, outline_color(), false, 3.0 if selection_active else 2.0)
	var columns: int = 8
	var rows: int = 4
	var gap: float = 3.0
	var cell_size := Vector2(
		(outer.size.x - gap * float(columns + 1)) / float(columns),
		(outer.size.y - gap * float(rows + 1)) / float(rows)
	)
	var active_row: int = int(activity_details.get("index", -1)) % rows
	for row: int in range(rows):
		for column: int in range(columns):
			var rect := Rect2(
				outer.position + Vector2(gap + float(column) * (cell_size.x + gap), gap + float(row) * (cell_size.y + gap)),
				cell_size
			)
			var active_cell: bool = not activity_kind.is_empty() and (active_row < 0 or row == active_row)
			var wave: bool = float(column) / float(columns) <= activity_progress
			var fill := Color("192943")
			if active_cell and wave:
				fill = Color(GOOD if activity_kind == &"ram_read" else WARNING, 0.66)
			draw_rect(rect, fill, true)
			draw_rect(rect, Color(OUTLINE, 0.48), false, 1.0)


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
	var view: Dictionary = bus_presentation()
	var width: int = view["width"]
	var groups: int = ceili(8.0 / float(width))
	var active_group: int = view["group"]
	var transferring: bool = view["transferring"]
	var color: Color = GOOD if activity_kind == &"read_data" else WARNING
	var heading: String = _bus_text(&"system.bus.diagram.idle")
	if transferring:
		heading = ("← " if activity_kind == &"read_data" else "→ ") + _bus_text(&"system.bus.diagram.value", [view["value"]])
	_draw_bus_caption(heading, 17.0, ACCENT)
	var gap: float = 3.0
	var group_gap: float = 9.0
	var left: float = 8.0
	var cell_width: float = (size.x - left * 2.0 - gap * float(8 - groups) - group_gap * float(groups - 1)) / 8.0
	for group: int in range(groups):
		var count: int = mini(width, 8 - group * width)
		var group_width: float = float(count) * cell_width + float(count - 1) * gap
		var group_color: Color = color if transferring and group == active_group else OUTLINE
		var rect := Rect2(left - 3.0, 29.0, group_width + 6.0, 36.0)
		draw_style_box(_bus_group_style(group_color, transferring and group == active_group), rect)
		for bit: int in range(count):
			var position := Vector2(left + float(bit) * (cell_width + gap), 34.0)
			var high: bool = (int(view["value"]) & (1 << (7 - group * width - bit))) != 0
			var fill: Color = Color(color, 0.65) if transferring and high else BACKGROUND
			draw_rect(Rect2(position, Vector2(cell_width, 25.0)), fill)
			var digit: String = str(int(high)) if transferring else "·"
			var font: Font = get_theme_font("font", "Label")
			var digit_width: float = font.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string(font, position + Vector2((cell_width - digit_width) * 0.5, 18.0), digit, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e9f0fa"))
		var group_font: Font = get_theme_font("font", "Label")
		draw_string(group_font, Vector2(left, 80.0), str(group + 1), HORIZONTAL_ALIGNMENT_CENTER, group_width, 12, group_color)
		left += group_width + group_gap
	var caption: String = _bus_text(&"system.bus.diagram.capacity", [width, view["groups"]])
	if transferring:
		caption = _bus_text(&"system.bus.diagram.progress", [width, active_group + 1, view["groups"]])
	_draw_bus_caption(caption, 103.0, color if transferring else Color("b0c1d5"))


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
