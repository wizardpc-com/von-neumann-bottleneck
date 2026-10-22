extends Control
## The half adder's specification at a glance, inside the docked guide:
##     A B    0 0   0 1   1 0   1 1
##     SUM     0     1     1     0
##     CARRY   0     0     0     1
## Each column is one input case. The column the test bench currently holds is
## lit; a column the player has actually run turns green (matched) or red
## (an output differed), and the differing cell is outlined. Clicking a column
## only selects those inputs on the test bench; it never runs or judges.

signal case_selected(index: int)

const Palette = preload("res://src/lab/lab_palette.gd")
const Typography = preload("res://src/ui/ui_typography.gd")
const BAD := Color("e58f86")
const LABEL_WIDTH := 58.0
const COLUMN_WIDTH := 40.0
const ROW_HEIGHT := 18.0

## [{A, B, SUM, CARRY}] in display order.
var cases: Array = []
## index -> {"sum": int, "carry": int} for cases actually observed on this circuit.
var observed: Dictionary = {}
var selected: int = -1
var english: bool = false
var _hover: int = -1


func _init() -> void:
	name = "GuideCaseTable"
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(LABEL_WIDTH + COLUMN_WIDTH * 4.0, ROW_HEIGHT * 3.0)


func set_cases(value: Array) -> void:
	cases = value.duplicate(true)
	custom_minimum_size.x = LABEL_WIDTH + COLUMN_WIDTH * maxf(1.0, float(cases.size()))
	queue_redraw()


func set_evidence(evidence: Dictionary, selected_index: int) -> void:
	observed = evidence.duplicate(true)
	selected = selected_index
	tooltip_text = _tooltip()
	queue_redraw()


func passed_count() -> int:
	var count: int = 0
	for index: int in observed:
		if _column_state(index) == 1: count += 1
	return count


## 0 not run on this circuit, 1 every output matched, -1 an output differed.
func _column_state(index: int) -> int:
	if not observed.has(index) or index >= cases.size(): return 0
	var actual: Dictionary = observed[index]
	var expected: Dictionary = cases[index]
	return 1 if int(actual.get("sum", -1)) == int(expected.SUM) and int(actual.get("carry", -1)) == int(expected.CARRY) else -1


func _tooltip() -> String:
	var lines: Array[String] = ["点一列，把这组输入放到测试台（不会自动运行）。" if not english else "Click a column to set those inputs on the test bench (it does not run)."]
	for index: int in observed:
		if index >= cases.size(): continue
		var expected: Dictionary = cases[index]
		var actual: Dictionary = observed[index]
		lines.append(("A=%d B=%d：实际 SUM %d、CARRY %d" if not english else "A=%d B=%d: actual SUM %d, CARRY %d") % [
			int(expected.A), int(expected.B), int(actual.get("sum", 0)), int(actual.get("carry", 0))])
	return "\n".join(lines)


func _column_at(position: Vector2) -> int:
	if position.x < LABEL_WIDTH or position.y < 0.0 or position.y > size.y: return -1
	var index: int = int((position.x - LABEL_WIDTH) / COLUMN_WIDTH)
	return index if index >= 0 and index < cases.size() else -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hover: int = _column_at((event as InputEventMouseMotion).position)
		if hover != _hover:
			_hover = hover
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hover >= 0 else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var index: int = _column_at((event as InputEventMouseButton).position)
		if index >= 0:
			case_selected.emit(index)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hover >= 0:
		_hover = -1
		queue_redraw()


func _draw() -> void:
	var font: Font = Typography.HEADING_FONT if Typography.HEADING_FONT != null else get_theme_default_font()
	var body_font: Font = get_theme_default_font()
	var size_px: int = 13
	var top: float = maxf(0.0, (size.y - ROW_HEIGHT * 3.0) * 0.5)
	var labels: Array[String] = ["A B", "SUM", "CARRY"]
	for row: int in 3:
		var y: float = top + ROW_HEIGHT * row
		draw_string(body_font, Vector2(0.0, y + ROW_HEIGHT * 0.5 + size_px * 0.36), labels[row],
			HORIZONTAL_ALIGNMENT_RIGHT, LABEL_WIDTH - 10.0, size_px, Palette.TERM_MUTED)
	draw_line(Vector2(LABEL_WIDTH - 4.0, top + ROW_HEIGHT), Vector2(size.x, top + ROW_HEIGHT), Palette.with_alpha(Palette.TERM_EDGE, 0.9), 1.0)
	for index: int in cases.size():
		var expected: Dictionary = cases[index]
		var x: float = LABEL_WIDTH + COLUMN_WIDTH * index
		var column := Rect2(x + 2.0, top - 1.0, COLUMN_WIDTH - 4.0, ROW_HEIGHT * 3.0 + 2.0)
		var state: int = _column_state(index)
		if index == selected:
			draw_rect(column, Palette.with_alpha(Palette.ACCENT, 0.13))
			draw_rect(column, Palette.with_alpha(Palette.ACCENT, 0.55), false, 1.0)
		elif index == _hover:
			draw_rect(column, Palette.with_alpha(Palette.ACCENT, 0.07))
		var head_color: Color = Palette.GOOD if state == 1 else (BAD if state == -1 else Palette.TERM_TEXT)
		var head: String = "%d %d" % [int(expected.A), int(expected.B)]
		draw_string(font, Vector2(x, top + ROW_HEIGHT * 0.5 + size_px * 0.36), head,
			HORIZONTAL_ALIGNMENT_CENTER, COLUMN_WIDTH, size_px, head_color)
		var actual: Dictionary = observed.get(index, {})
		for row: int in [1, 2]:
			var key: String = "SUM" if row == 1 else "CARRY"
			var y: float = top + ROW_HEIGHT * row
			var differs: bool = state == -1 and int(actual.get(key.to_lower(), -1)) != int(expected[key])
			if differs:
				draw_rect(Rect2(x + 8.0, y + 1.0, COLUMN_WIDTH - 16.0, ROW_HEIGHT - 2.0), Palette.with_alpha(BAD, 0.16))
				draw_rect(Rect2(x + 8.0, y + 1.0, COLUMN_WIDTH - 16.0, ROW_HEIGHT - 2.0), BAD, false, 1.0)
			# The cell keeps the specified value; the red frame marks where the actual output differed.
			var value_color: Color = Palette.TERM_TEXT if differs else (Palette.GOOD if state == 1 else Palette.TERM_TEXT)
			draw_string(font, Vector2(x, y + ROW_HEIGHT * 0.5 + size_px * 0.36), str(int(expected[key])),
				HORIZONTAL_ALIGNMENT_CENTER, COLUMN_WIDTH, size_px, value_color)
