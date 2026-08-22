class_name CampaignMapView
extends Control

signal level_requested(level_id: StringName)

const BACKGROUND := Color("0b1220")
const SURFACE := Color("111a2a")
const TEXT := Color("d8e1ef")
const MUTED := Color("8290a8")
const ACCENT := Color("50d5ff")
const PURPLE := Color("c58cff")
const GOOD := Color("67e8a5")

const NODE_SIZE := Vector2(142.0, 78.0)
const LEFT_RESERVED: float = 420.0
const RIGHT_MARGIN: float = 28.0
const TOP_MARGIN: float = 78.0
const BOTTOM_RESERVED: float = 86.0
const LANE_GAP: float = 154.0

var level_buttons: Dictionary[StringName, Button] = {}
var level_positions: Dictionary[StringName, Vector2] = {}
var level_depths: Dictionary[StringName, int] = {}
var branch_lanes: Dictionary[StringName, float] = {}

var _branches: Array[Dictionary] = []
var _levels: Dictionary[StringName, Dictionary] = {}
var _ordered_level_ids: Array[StringName] = []
var _branch_orders: Dictionary[StringName, int] = {}
var _legend_text: String = ""
var _hovered_level: StringName = &""
var _details_panel: Panel
var _details_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_relayout)
	_build_details_panel()
	_relayout()


func configure(
		branches: Array[Dictionary],
		levels: Array[Dictionary],
		legend_text: String
	) -> void:
	_branches = []
	for branch: Dictionary in branches:
		_branches.append(branch.duplicate(true))
	_levels.clear()
	_ordered_level_ids.clear()
	_branch_orders.clear()
	_legend_text = legend_text
	for branch_index: int in range(_branches.size()):
		var branch: Dictionary = _branches[branch_index]
		_branch_orders[StringName(branch.get("id", &""))] = int(branch.get("order", branch_index))
	for level: Dictionary in levels:
		var level_id := StringName(level.get("id", &""))
		if level_id.is_empty():
			continue
		_levels[level_id] = level.duplicate(true)
		_ordered_level_ids.append(level_id)
	_ordered_level_ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		var left_level: Dictionary = _levels[left]
		var right_level: Dictionary = _levels[right]
		var left_branch := StringName(left_level.get("branch_id", &""))
		var right_branch := StringName(right_level.get("branch_id", &""))
		var left_branch_order: int = int(_branch_orders.get(left_branch, 0))
		var right_branch_order: int = int(_branch_orders.get(right_branch, 0))
		if left_branch_order != right_branch_order:
			return left_branch_order < right_branch_order
		var left_order: int = int(left_level.get("order", 0))
		var right_order: int = int(right_level.get("order", 0))
		return left_order < right_order if left_order != right_order else String(left) < String(right)
	)
	_compute_level_depths()
	_compute_branch_lanes()
	_rebuild_level_buttons()
	_relayout()
	_show_default_details()


func level_position(level_id: StringName) -> Vector2:
	return level_positions.get(level_id, Vector2.ZERO)


func level_state(level_id: StringName) -> StringName:
	if not _levels.has(level_id):
		return &"missing"
	var data: Dictionary = _levels[level_id]
	if bool(data.get("completed", false)):
		return &"completed"
	return &"unlocked" if bool(data.get("unlocked", false)) else &"locked"


func dependency_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for level_id: StringName in _ordered_level_ids:
		for dependency_variant: Variant in (_levels[level_id].get("dependencies", []) as Array):
			var dependency := StringName(dependency_variant)
			if _levels.has(dependency):
				result.append({"from": dependency, "to": level_id})
	return result


func _build_details_panel() -> void:
	if _details_panel != null:
		return
	_details_panel = Panel.new()
	_details_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_panel.add_theme_stylebox_override("panel", _stylebox(Color(SURFACE, 0.94), ACCENT, 1, 8))
	_details_panel.clip_contents = true
	add_child(_details_panel)
	_details_label = Label.new()
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_details_label.max_lines_visible = 2
	_details_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_label.add_theme_font_size_override("font_size", 13)
	_details_label.add_theme_color_override("font_color", TEXT)
	_details_panel.add_child(_details_label)


func _rebuild_level_buttons() -> void:
	for button: Button in level_buttons.values():
		if is_instance_valid(button):
			remove_child(button)
			button.queue_free()
	level_buttons.clear()
	for level_id: StringName in _ordered_level_ids:
		var data: Dictionary = _levels[level_id]
		var button := Button.new()
		button.name = "Level_%s" % String(level_id).to_pascal_case()
		button.custom_minimum_size = NODE_SIZE
		button.size = NODE_SIZE
		button.focus_mode = Control.FOCUS_ALL
		button.disabled = not bool(data.get("unlocked", false))
		button.tooltip_text = String(data.get("tooltip", ""))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not button.disabled else Control.CURSOR_ARROW
		_apply_button_style(button, data)
		_build_button_content(button, data)
		button.pressed.connect(_on_level_pressed.bind(level_id))
		button.mouse_entered.connect(_show_level_details.bind(level_id))
		button.mouse_exited.connect(_on_level_mouse_exited.bind(level_id))
		button.focus_entered.connect(_show_level_details.bind(level_id))
		level_buttons[level_id] = button
		add_child(button)
	if _details_panel != null:
		move_child(_details_panel, get_child_count() - 1)


func _build_button_content(button: Button, data: Dictionary) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	button.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var title := Label.new()
	title.text = String(data.get("title", data.get("id", "?")))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 33.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", TEXT if bool(data.get("unlocked", false)) else MUTED)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)
	var state := Label.new()
	state.text = "%s  %s" % [_status_glyph(data), String(data.get("status", ""))]
	state.add_theme_font_size_override("font_size", 11)
	state.add_theme_color_override("font_color", _status_color(data))
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(state)


func _apply_button_style(button: Button, data: Dictionary) -> void:
	var color: Color = _status_color(data)
	button.add_theme_stylebox_override("normal", _stylebox(Color(SURFACE, 0.96), color, 2, 12))
	button.add_theme_stylebox_override("hover", _stylebox(Color(color, 0.17), color, 3, 12))
	button.add_theme_stylebox_override("pressed", _stylebox(Color(color, 0.26), color, 3, 12))
	button.add_theme_stylebox_override("focus", _stylebox(Color.TRANSPARENT, color, 3, 12))
	button.add_theme_stylebox_override("disabled", _stylebox(Color("101725", 0.82), Color(MUTED, 0.38), 1, 12))


func _status_color(data: Dictionary) -> Color:
	if bool(data.get("completed", false)):
		return GOOD
	if bool(data.get("unlocked", false)):
		return ACCENT
	return MUTED


func _status_glyph(data: Dictionary) -> String:
	if bool(data.get("completed", false)):
		return "✓"
	if bool(data.get("unlocked", false)):
		return "◆"
	return "○"


func _compute_level_depths() -> void:
	level_depths.clear()
	for level_id: StringName in _ordered_level_ids:
		level_depths[level_id] = 0
	for _pass: int in range(maxi(1, _ordered_level_ids.size())):
		var changed: bool = false
		for level_id: StringName in _ordered_level_ids:
			var depth: int = 0
			for dependency_variant: Variant in (_levels[level_id].get("dependencies", []) as Array):
				var dependency := StringName(dependency_variant)
				if level_depths.has(dependency):
					depth = maxi(depth, int(level_depths[dependency]) + 1)
			if int(level_depths[level_id]) != depth:
				level_depths[level_id] = depth
				changed = true
		if not changed:
			break


func _compute_branch_lanes() -> void:
	branch_lanes.clear()
	var parent_branches: Dictionary[StringName, Array] = {}
	var branch_ids: Array[StringName] = []
	for branch: Dictionary in _branches:
		var branch_id := StringName(branch.get("id", &""))
		if branch_id.is_empty():
			continue
		branch_ids.append(branch_id)
		parent_branches[branch_id] = []
	for level_id: StringName in _ordered_level_ids:
		var level_branch := StringName(_levels[level_id].get("branch_id", &""))
		for dependency_variant: Variant in (_levels[level_id].get("dependencies", []) as Array):
			var dependency := StringName(dependency_variant)
			if not _levels.has(dependency):
				continue
			var dependency_branch := StringName(_levels[dependency].get("branch_id", &""))
			if dependency_branch != level_branch and dependency_branch not in parent_branches[level_branch]:
				parent_branches[level_branch].append(dependency_branch)
	var roots: Array[StringName] = []
	for branch_id: StringName in branch_ids:
		if parent_branches[branch_id].is_empty():
			roots.append(branch_id)
	_assign_sibling_lanes(roots, 0.0)
	for _pass: int in range(maxi(1, branch_ids.size())):
		var changed: bool = false
		for branch_id: StringName in branch_ids:
			if branch_lanes.has(branch_id):
				continue
			var parents: Array = parent_branches[branch_id]
			var parents_ready: bool = not parents.is_empty()
			for parent_variant: Variant in parents:
				if not branch_lanes.has(StringName(parent_variant)):
					parents_ready = false
					break
			if not parents_ready:
				continue
			if parents.size() > 1:
				var total: float = 0.0
				for parent_variant: Variant in parents:
					total += float(branch_lanes[StringName(parent_variant)])
				branch_lanes[branch_id] = total / float(parents.size())
				changed = true
				continue
			var parent_id := StringName(parents[0])
			var siblings: Array[StringName] = []
			for candidate: StringName in branch_ids:
				var candidate_parents: Array = parent_branches[candidate]
				if candidate_parents.size() == 1 and StringName(candidate_parents[0]) == parent_id:
					siblings.append(candidate)
			siblings.sort_custom(func(left: StringName, right: StringName) -> bool:
				return int(_branch_orders.get(left, 0)) < int(_branch_orders.get(right, 0))
			)
			_assign_sibling_lanes(siblings, float(branch_lanes[parent_id]))
			changed = true
		if not changed:
			break
	for branch_id: StringName in branch_ids:
		if not branch_lanes.has(branch_id):
			branch_lanes[branch_id] = 0.0


func _assign_sibling_lanes(branch_ids: Array[StringName], center: float) -> void:
	if branch_ids.is_empty():
		return
	for index: int in range(branch_ids.size()):
		var offset: float = (float(index) - float(branch_ids.size() - 1) * 0.5) * 2.0
		branch_lanes[branch_ids[index]] = center + offset


func _relayout() -> void:
	if level_buttons.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var left: float = minf(LEFT_RESERVED, maxf(24.0, size.x * 0.29))
	var available_width: float = maxf(320.0, size.x - left - RIGHT_MARGIN - NODE_SIZE.x)
	var maximum_depth: int = 0
	for depth: int in level_depths.values():
		maximum_depth = maxi(maximum_depth, depth)
	var depth_step: float = available_width / float(maxi(1, maximum_depth))
	var map_bottom: float = maxf(TOP_MARGIN + NODE_SIZE.y, size.y - BOTTOM_RESERVED)
	var center_y: float = (TOP_MARGIN + map_bottom - NODE_SIZE.y) * 0.5
	var largest_lane: float = 1.0
	for lane: float in branch_lanes.values():
		largest_lane = maxf(largest_lane, absf(lane))
	var lane_gap: float = minf(LANE_GAP, maxf(88.0, (map_bottom - TOP_MARGIN - NODE_SIZE.y) * 0.48 / largest_lane))
	level_positions.clear()
	for level_id: StringName in _ordered_level_ids:
		var branch_id := StringName(_levels[level_id].get("branch_id", &""))
		var position := Vector2(
			left + float(level_depths.get(level_id, 0)) * depth_step,
			center_y + float(branch_lanes.get(branch_id, 0.0)) * lane_gap,
		)
		level_positions[level_id] = position
		var button: Button = level_buttons[level_id]
		button.position = position
		button.size = NODE_SIZE
	if _details_panel != null:
		_details_panel.position = Vector2(left, size.y - 67.0)
		_details_panel.size = Vector2(maxf(320.0, size.x - left - RIGHT_MARGIN), 52.0)
		_details_label.position = Vector2(12.0, 5.0)
		_details_label.size = _details_panel.size - Vector2(24.0, 10.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND, true)
	if _levels.is_empty():
		return
	_draw_branch_labels()
	for edge: Dictionary in dependency_edges():
		_draw_dependency(StringName(edge["from"]), StringName(edge["to"]))


func _draw_branch_labels() -> void:
	for branch: Dictionary in _branches:
		var branch_id := StringName(branch.get("id", &""))
		var first_id: StringName = &""
		for level_id: StringName in _ordered_level_ids:
			if StringName(_levels[level_id].get("branch_id", &"")) != branch_id:
				continue
			if first_id.is_empty() or int(level_depths[level_id]) < int(level_depths[first_id]):
				first_id = level_id
		if first_id.is_empty() or not level_positions.has(first_id):
			continue
		var position: Vector2 = level_positions[first_id] + Vector2(0.0, -20.0)
		draw_string(
			ThemeDB.fallback_font, position, String(branch.get("title", branch_id)),
			HORIZONTAL_ALIGNMENT_LEFT, NODE_SIZE.x, 13, Color(PURPLE, 0.92)
		)


func _draw_dependency(from_id: StringName, to_id: StringName) -> void:
	if not level_positions.has(from_id) or not level_positions.has(to_id):
		return
	var start: Vector2 = level_positions[from_id] + Vector2(NODE_SIZE.x, NODE_SIZE.y * 0.5)
	var finish: Vector2 = level_positions[to_id] + Vector2(0.0, NODE_SIZE.y * 0.5)
	var target_data: Dictionary = _levels[to_id]
	var color: Color = _status_color(target_data)
	var control_distance: float = maxf(36.0, (finish.x - start.x) * 0.48)
	var curve := _cubic(
		start,
		start + Vector2(control_distance, 0.0),
		finish - Vector2(control_distance, 0.0),
		finish
	)
	draw_polyline(curve, Color(BACKGROUND, 0.95), 8.0, true)
	draw_polyline(curve, Color(color, 0.76 if bool(target_data.get("unlocked", false)) else 0.34), 3.0, true)
	var direction: Vector2 = (curve[curve.size() - 1] - curve[curve.size() - 2]).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		finish,
		finish - direction * 11.0 + normal * 6.0,
		finish - direction * 11.0 - normal * 6.0,
	])
	draw_colored_polygon(arrow, Color(color, 0.86 if bool(target_data.get("unlocked", false)) else 0.42))


func _show_level_details(level_id: StringName) -> void:
	if not _levels.has(level_id):
		return
	_hovered_level = level_id
	var data: Dictionary = _levels[level_id]
	_details_label.text = "%s  ·  %s\n%s" % [
		String(data.get("title", level_id)),
		String(data.get("requirement", "")),
		String(data.get("description", "")),
	]
	_details_label.add_theme_color_override("font_color", _status_color(data))


func _on_level_mouse_exited(level_id: StringName) -> void:
	if _hovered_level == level_id:
		_hovered_level = &""
		_show_default_details()


func _show_default_details() -> void:
	if _details_label == null:
		return
	_details_label.text = _legend_text
	_details_label.add_theme_color_override("font_color", TEXT)


func _on_level_pressed(level_id: StringName) -> void:
	level_requested.emit(level_id)


func _stylebox(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box


func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(25):
		var t: float = float(index) / 24.0
		var one_minus_t: float = 1.0 - t
		points.append(
			a * one_minus_t * one_minus_t * one_minus_t
			+ b * 3.0 * one_minus_t * one_minus_t * t
			+ c * 3.0 * one_minus_t * t * t
			+ d * t * t * t
		)
	return points
