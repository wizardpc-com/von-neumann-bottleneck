extends Control

# Static abstract wiring: presentation only, with no simulated state or metrics.
func _ready() -> void:
	custom_minimum_size = Vector2(300,180)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var scale_factor: float = minf(size.x/360.0,size.y/220.0)
	var origin: Vector2 = (size-Vector2(360,220)*scale_factor)*0.5
	draw_set_transform(origin,0,Vector2.ONE*scale_factor)
	var edge := Color("385565")
	var light := Color("79d7e0")
	for y: int in range(20,220,20):
		for x: int in range(20,360,20): draw_circle(Vector2(x,y),1.0,Color("223b49"))
	for wire: PackedVector2Array in [
		PackedVector2Array([Vector2(68,110),Vector2(112,110)]),
		PackedVector2Array([Vector2(204,110),Vector2(258,110)]),
		PackedVector2Array([Vector2(158,68),Vector2(158,36),Vector2(292,36),Vector2(292,74)]),
		PackedVector2Array([Vector2(158,152),Vector2(158,190),Vector2(292,190),Vector2(292,146)])
	]: draw_polyline(wire,edge,2,true)
	for rect: Rect2 in [Rect2(28,88,40,44),Rect2(112,68,92,84),Rect2(258,74,68,72)]:
		var panel := StyleBoxFlat.new(); panel.bg_color = Color("142b38"); panel.border_color = edge
		panel.set_border_width_all(2); panel.set_corner_radius_all(6)
		draw_style_box(panel,rect)
	for y: int in [84,100,116,132]:
		draw_line(Vector2(126,y),Vector2(190,y),Color("37596a"),2,true)
	for y: int in [90,106,122]:
		draw_line(Vector2(272,y),Vector2(310,y),Color("547283"),3,true)
	for point: Vector2 in [Vector2(86,110),Vector2(232,110),Vector2(158,36),Vector2(292,190)]:
		draw_circle(point,4,light)
	draw_circle(Vector2(48,110),6,light)
	draw_set_transform(Vector2.ZERO)
