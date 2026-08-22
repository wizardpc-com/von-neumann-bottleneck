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


func _ready() -> void:
	custom_minimum_size = Vector2(190.0, 84.0)
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


func _draw_bus() -> void:
	var left: float = 17.0
	var right: float = size.x - 17.0
	var segments: int = maxi(1, int(activity_details.get("segments", 1)))
	for lane: int in range(4):
		var y: float = 18.0 + float(lane) * 15.0
		draw_line(Vector2(left, y), Vector2(right, y), Color(outline_color(), 0.95 if selection_active else 0.72), 5.0 if selection_active else 4.0)
		if activity_kind in [&"read_request", &"write_request", &"read_data", &"write_data"]:
			var phased: float = fmod(activity_progress * float(segments) + float(lane) * 0.11, 1.0)
			var cursor_x: float = lerpf(left, right, phased)
			var color := GOOD if activity_kind == &"read_data" else (WARNING if activity_kind == &"write_data" else ACCENT)
			draw_line(Vector2(maxf(left, cursor_x - 15.0), y), Vector2(cursor_x, y), color, 4.0)
