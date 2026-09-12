class_name TechnicalBackdrop
extends Control
## Static, input-transparent scenery. No clocks, particles or simulation signals.
var _ambient: GradientTexture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.13, 0.37, 0.46, 0.19))
	gradient.set_color(1, Color(0.04, 0.10, 0.16, 0.0))
	_ambient = GradientTexture2D.new()
	_ambient.gradient = gradient
	_ambient.fill = GradientTexture2D.FILL_RADIAL
	_ambient.fill_from = Vector2(0.5, 0.5)
	_ambient.fill_to = Vector2(1.0, 0.5)
	_ambient.width = 256
	_ambient.height = 256
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070f19"))
	if _ambient != null:
		draw_texture_rect(_ambient, Rect2(Vector2(-size.x*0.2,-size.y*0.55),size*Vector2(1.3,1.5)),false)
		draw_texture_rect(_ambient, Rect2(Vector2(size.x*0.5,size.y*0.3),size*Vector2(0.9,1.1)),false,Color(0.75,0.6,1.0,0.55))
	# A quiet drafting plane beneath the foreground instruments. It is scenery,
	# never a connection route or a representation of distance/latency in a circuit.
	var horizon: float = size.y*0.66
	for index: int in range(1,7):
		var depth: float = pow(float(index)/6.0,1.8)
		var y: float = lerpf(horizon,size.y,depth)
		draw_line(Vector2(0,y),Vector2(size.x,y),Color(0.25,0.48,0.57,0.035+depth*0.035),1,true)
	for index: int in range(-7,8):
		var top := Vector2(size.x*0.5+index*size.x/20.0,horizon)
		var bottom := Vector2(size.x*0.5+index*size.x/7.0,size.y)
		draw_line(top,bottom,Color(0.25,0.48,0.57,0.045),1,true)
	for x: int in range(24,int(size.x),72):
		for y: int in range(24,int(horizon),72):
			draw_circle(Vector2(x,y),0.7,Color(0.33,0.53,0.65,0.11))
	for side: int in [0,1]:
		var x: float = 16 if side==0 else size.x-16
		for index: int in range(5):
			var y: float = size.y*0.38+index*12
			draw_line(Vector2(x,y),Vector2(x+(8 if side==0 else -8),y),Color(0.37,0.65,0.74,0.15),1,true)
