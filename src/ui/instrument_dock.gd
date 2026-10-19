extends RefCounted
## Docked instrument layout shared by the System and Locality workbenches.
## The task opens in a left column and tools open in a right column, so the
## machine canvas keeps the middle. A panel docks only the first time it opens;
## after that it keeps wherever the player moved or resized it.

const MARGIN := 12.0

static func enabled() -> bool:
	return not preload("res://src/lab/lab_features.gd").classic

static func left_width(area: Vector2) -> float:
	return clampf(area.x * 0.24, 300.0, 420.0)

static func right_width(area: Vector2, wide: bool) -> float:
	return clampf(area.x * (0.36 if wide else 0.29), 360.0 if wide else 340.0, 600.0 if wide else 450.0)

static func _apply(panel: Control, id: StringName, area: Vector2, left_ids: Array, wide_ids: Array) -> void:
	var height: float = area.y - MARGIN * 2.0
	if id in left_ids:
		panel.position = Vector2(MARGIN, MARGIN)
		panel.size = Vector2(left_width(area), height)
	else:
		var width: float = right_width(area, id in wide_ids)
		panel.position = Vector2(area.x - MARGIN - width, MARGIN)
		panel.size = Vector2(width, height)
	panel.set_meta("docked", true)

## Docks `id` on its first opening (once the host has a real size). A second tool
## splits the right column so neither tool hides the other.
static func place(panel: Control, id: StringName, area: Vector2, left_ids: Array, wide_ids: Array, windows: Dictionary = {}) -> void:
	if not enabled() or area.x <= 0.0 or area.y <= 0.0 or panel.has_meta("docked"): return
	_apply(panel, id, area, left_ids, wide_ids)
	if id in left_ids: return
	var neighbour: Control = null
	for other: StringName in windows:
		var candidate: Control = windows[other]
		if candidate != panel and candidate.visible and not other in left_ids and candidate.position.x > area.x * 0.4:
			if neighbour == null or candidate.z_index > neighbour.z_index: neighbour = candidate
	if neighbour == null: return
	var half: float = (area.y - MARGIN * 3.0) * 0.5
	neighbour.position.y = MARGIN
	neighbour.size.y = half
	panel.position.y = MARGIN * 2.0 + half
	panel.size.y = half

## Docks visible panels that opened before the host had its size.
static func redock(area: Vector2, windows: Dictionary, left_ids: Array, wide_ids: Array) -> void:
	if not enabled() or area.x <= 0.0 or area.y <= 0.0: return
	for id: StringName in windows:
		var panel: Control = windows[id]
		if panel.visible and not panel.has_meta("docked") and not bool(panel.get("minimized")):
			_apply(panel, id, area, left_ids, wide_ids)

## Free horizontal band between visible docked panels.
static func free_band(area: Vector2, windows: Dictionary) -> Vector2:
	var left: float = 0.0
	var right: float = area.x
	for panel: Control in windows.values():
		if not panel.visible: continue
		if panel.position.x < area.x * 0.3: left = maxf(left, panel.position.x + panel.size.x)
		elif panel.position.x > area.x * 0.4: right = minf(right, panel.position.x)
	return Vector2(left, right)

## Frames the given graph nodes inside the free band. Zoom never drops below a readable floor.
static func frame(graph: GraphEdit, nodes: Array, windows: Dictionary, readable_zoom: float = 0.5) -> void:
	if not enabled() or graph == null or nodes.is_empty(): return
	var bounds := Rect2()
	var first: bool = true
	for node: Variant in nodes:
		var graph_node := node as GraphNode
		if graph_node == null or not graph_node.visible: continue
		var rect := Rect2(graph_node.position_offset, graph_node.size)
		bounds = rect if first else bounds.merge(rect)
		first = false
	if first: return
	var band: Vector2 = free_band(graph.size, windows)
	var view := Rect2(band.x + 24.0, 36.0, maxf(240.0, band.y - band.x - 48.0), graph.size.y - 72.0)
	var zoom: float = clampf(minf(view.size.x / maxf(bounds.size.x, 1.0), view.size.y / maxf(bounds.size.y, 1.0)), readable_zoom, 1.0)
	graph.zoom = zoom
	graph.scroll_offset = bounds.get_center() * zoom - view.get_center()
