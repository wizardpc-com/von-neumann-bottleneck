class_name TechnicalBackdrop
extends Control
## Static, input-transparent scenery. No clocks, particles or simulation signals.
var _ambient: GradientTexture2D
var light: bool = false:
	set(value):
		light = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.43, 0.65, 0.67, 0.07))
	gradient.set_color(1, Color(0.43, 0.65, 0.67, 0.0))
	_ambient = GradientTexture2D.new()
	_ambient.gradient = gradient
	_ambient.fill = GradientTexture2D.FILL_RADIAL
	_ambient.fill_from = Vector2(0.5, 0.5)
	_ambient.fill_to = Vector2(1.0, 0.5)
	_ambient.width = 256
	_ambient.height = 256
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("e5edec") if light else Color("0c141a"))
	if _ambient != null:
		draw_texture_rect(_ambient, Rect2(Vector2(-size.x*0.2,-size.y*0.55),size*Vector2(1.3,1.5)),false)
	# Sparse registration marks are scenery, never circuit routes or latency cues.
	var mark := Color(0.22, 0.37, 0.39, 0.14) if light else Color(0.51, 0.65, 0.68, 0.09)
	for x: int in range(32, int(size.x), 112):
		for y: int in range(32, int(size.y), 112):
			draw_circle(Vector2(x, y), 0.7, mark)
	for side: int in [0,1]:
		var x: float = 16 if side==0 else size.x-16
		for index: int in range(5):
			var y: float = size.y*0.38+index*12
			draw_line(Vector2(x,y),Vector2(x+(8 if side==0 else -8),y),mark,1,true)
