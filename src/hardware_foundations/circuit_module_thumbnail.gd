class_name CircuitModuleThumbnail
extends CircuitModuleRow

# A whole module at palette scale. Reuse the canvas vocabulary and function mark,
# but never compress a single labeled port row into a miniature module.
var input_widths: Array[int] = []
var output_widths: Array[int] = []


func configure_thumbnail(kind: StringName, inputs: Array[int], outputs: Array[int]) -> void:
	component_kind = kind
	input_widths = inputs.duplicate()
	output_widths = outputs.duplicate()
	custom_minimum_size = Vector2(96.0, 60.0)
	size = custom_minimum_size
	queue_redraw()


func body_polygon() -> PackedVector2Array:
	if not visual_bands.is_empty():
		var body := PackedVector2Array()
		for index: int in visual_bands.size():
			var t: float = float(index)/float(visual_bands.size()-1)
			body.append(Vector2(72.0-(12.0-_visual_edge(t,1))*1.5,6.0+t*48.0))
		for index: int in range(visual_bands.size()-1,-1,-1):
			var t: float = float(index)/float(visual_bands.size()-1)
			body.append(Vector2(24.0+_visual_edge(t,0)*1.5,6.0+t*48.0))
		return body
	return VisualStyle.shell(component_kind,Rect2(24,6,48,48))


func pin_segments() -> Array[Dictionary]:
	var pins: Array[Dictionary] = []
	var body: PackedVector2Array = body_polygon()
	for side: int in range(2):
		var widths: Array[int] = input_widths if side == 0 else output_widths
		for index: int in range(widths.size()):
			var y: float = lerpf(8.0, 52.0, float(index + 1) / float(widths.size() + 1))
			var crossings: Array[float] = []
			for edge: int in range(body.size()):
				var point: Variant = Geometry2D.segment_intersects_segment(
					Vector2(0, y), Vector2(96, y), body[edge], body[(edge + 1) % body.size()]
				)
				if point != null:
					crossings.append((point as Vector2).x)
			crossings.sort()
			if crossings.is_empty():
				continue
			pins.append({
				"outer": Vector2(6 if side == 0 else 90, y),
				"body": Vector2(crossings.front() if side == 0 else crossings.back(), y),
				"width": widths[index],
			})
	return pins


func port_label_layouts() -> Array[Dictionary]:
	return []


func function_mark_rect() -> Rect2:
	return Rect2(Vector2(36, 20), Vector2(24, 20))


func _draw() -> void:
	var body: PackedVector2Array = body_polygon()
	draw_colored_polygon(body, SURFACE)
	var outline: PackedVector2Array = body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, _outline_color(), 2.0, true)
	for pin: Dictionary in pin_segments():
		draw_line(pin.outer, pin.body, SYMBOL, 2.5 if int(pin.width) > 1 else 1.5, true)
		if int(pin.width) > 1:
			draw_rect(Rect2(pin.outer-Vector2(2.5,2.5),Vector2(5,5)),_outline_color(),false,1.2)
		else:
			draw_circle(pin.outer, 1.8, _outline_color(), true, -1, true)
	_draw_function_icon(function_mark_rect(), SYMBOL)
