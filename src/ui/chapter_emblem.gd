class_name ChapterEmblem
extends Control

var chapter: StringName = &"hardware"
var accent := Color("50d5ff")


func _ready() -> void:
	custom_minimum_size.y = 108.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 52.0)
	var outline := Color(accent, 0.55)
	for index: int in range(5):
		var x: float = center.x - 44.0 + index * 22.0
		draw_line(Vector2(x, 5.0), Vector2(x, 23.0), outline, 2.0, true)
		draw_line(Vector2(x, 81.0), Vector2(x, 99.0), outline, 2.0, true)
	var chip := Rect2(center - Vector2(66.0, 29.0), Vector2(132.0, 58.0))
	draw_style_box(preload("res://src/ui/instrument_theme.gd").panel(Color(accent, 0.06), outline), chip)
	for side: int in [-1, 1]:
		for index: int in range(3):
			var start := Vector2(center.x + side * 67.0, 34.0 + index * 18.0)
			var corner := start + Vector2(side * (22.0 + index * 12.0), 0.0)
			var end := corner + Vector2(side * 10.0, (index - 1) * 12.0)
			draw_polyline(PackedVector2Array([start, corner, end]), Color(accent, 0.35), 1.5, true)
			draw_circle(end, 3.0, accent if index == 1 else outline, false, 1.5, true)
	match chapter:
		&"hardware":
			var triangle := PackedVector2Array([center + Vector2(-22, -16), center + Vector2(-22, 16), center + Vector2(8, 0), center + Vector2(-22, -16)])
			draw_polyline(triangle, accent, 2.5, true)
			draw_circle(center + Vector2(14, 0), 5.0, accent, false, 2.0, true)
			draw_line(center + Vector2(20, 0), center + Vector2(40, 0), accent, 2.0, true)
		&"system":
			for index: int in range(3):
				var origin := center + Vector2(-47.0 + index * 35.0, -14.0)
				draw_rect(Rect2(origin, Vector2(25.0, 28.0)), accent, false, 2.0)
				if index < 2:
					draw_line(origin + Vector2(26.0, 14.0), origin + Vector2(35.0, 14.0), accent, 2.0)
		&"overlap":
			for lane: int in range(2):
				var lane_color := Color("50d5ff") if lane == 0 else accent
				for batch: int in range(3):
					var cell := Rect2(center + Vector2(-50+batch*29+lane*13,-19+lane*23),Vector2(24,15))
					draw_rect(cell,Color(lane_color,0.6),true)
					draw_rect(cell,lane_color,false,1)
		_:
			for row: int in range(2):
				for column: int in range(5):
					var cell := Rect2(center + Vector2(-45.0 + column * 19.0, -17.0 + row * 19.0), Vector2(14.0, 14.0))
					draw_rect(cell, Color(accent, 0.75 if row == 0 else 0.15), true)
					draw_rect(cell, outline, false, 1.0)
