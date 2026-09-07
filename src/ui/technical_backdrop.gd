class_name TechnicalBackdrop
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("08131d"))
	for x: int in range(0, int(size.x), 36):
		for y: int in range(0, int(size.y), 36):
			draw_circle(Vector2(x, y), 0.8, Color(0.26, 0.47, 0.56, 0.12))
	for side: int in [0, 1]:
		var origin := Vector2(0.0 if side == 0 else size.x, size.y * 0.48)
		var direction: float = 1.0 if side == 0 else -1.0
		for index: int in range(6):
			var a := origin + Vector2(0.0, index * 22.0)
			var b := a + Vector2(direction * (55.0 + index * 20.0), 0.0)
			var c := b + Vector2(direction * 64.0, -64.0)
			var d := c + Vector2(0.0, -size.y * 0.22)
			draw_polyline(PackedVector2Array([a, b, c, d]), Color(0.26, 0.73, 0.83, 0.10), 1.0, true)
			draw_circle(d, 3.0, Color(0.26, 0.73, 0.83, 0.18), false, 1.0, true)
