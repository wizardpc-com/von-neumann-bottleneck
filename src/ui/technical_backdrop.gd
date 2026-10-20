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
	# Arriving from the laboratory: this world opens out of the screen's line of light.
	if not light and preload("res://src/ui/terminal_passage.gd").take_pending_arrival():
		preload("res://src/ui/terminal_passage.gd").play_arrival(get_tree().current_scene if get_tree().current_scene != null else get_parent())

func _draw() -> void:
	if not light:
		_draw_terminal_world()
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("e5edec"))
	if _ambient != null:
		draw_texture_rect(_ambient, Rect2(Vector2(-size.x*0.2,-size.y*0.55),size*Vector2(1.3,1.5)),false)
	var mark := Color(0.22, 0.37, 0.39, 0.14)
	for x: int in range(32, int(size.x), 112):
		for y: int in range(32, int(size.y), 112):
			draw_circle(Vector2(x, y), 0.7, mark)


## Inside the terminal: a cool, self-lit field, unlike the daylit room outside.
## A faint signal grid, a top screen light and corner brackets of the screen's
## inner edge are scenery only, never circuit routes or latency cues.
func _draw_terminal_world() -> void:
	var steps: int = 12
	for index: int in steps:
		var t: float = float(index) / steps
		draw_rect(Rect2(0, size.y * t, size.x, size.y / steps + 1.0), Color("0d161d").lerp(Color("091015"), t))
	if _ambient != null:
		draw_texture_rect(_ambient, Rect2(Vector2(-size.x*0.2,-size.y*0.6),size*Vector2(1.4,1.4)),false)
	for index: int in 8:
		var t: float = float(index) / 8.0
		draw_rect(Rect2(0, size.y * t * 0.3, size.x, size.y * 0.04), Color(0.56, 0.83, 0.86, 0.018 * (1.0 - t)))
	var minor := Color(0.56, 0.83, 0.86, 0.022)
	var major := Color(0.56, 0.83, 0.86, 0.045)
	var pitch: float = 48.0
	var columns: int = int(size.x / pitch) + 1
	var rows: int = int(size.y / pitch) + 1
	for column: int in columns:
		var x: float = column * pitch
		draw_line(Vector2(x, 0), Vector2(x, size.y), major if column % 4 == 0 else minor, 1.0)
	for row: int in rows:
		var y: float = row * pitch
		draw_line(Vector2(0, y), Vector2(size.x, y), major if row % 4 == 0 else minor, 1.0)
	# Edge falloff keeps attention in the middle of the instrument.
	for ring: int in 6:
		var inset: float = ring * 22.0
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(0.0, 0.02, 0.03, 0.05), false, 22.0)
	var bezel := StyleBoxFlat.new()
	bezel.draw_center = false
	bezel.set_corner_radius_all(14)
	bezel.set_border_width_all(1)
	bezel.border_color = Color(0.56, 0.83, 0.86, 0.12)
	bezel.anti_aliasing = true
	draw_style_box(bezel, Rect2(Vector2(5, 5), size - Vector2(10, 10)))
	var bracket := Color(0.56, 0.83, 0.86, 0.32)
	var arm: float = 22.0
	for corner: Vector2 in [Vector2(12, 12), Vector2(size.x - 12, 12), Vector2(12, size.y - 12), Vector2(size.x - 12, size.y - 12)]:
		var horizontal: float = arm if corner.x < size.x * 0.5 else -arm
		var vertical: float = arm if corner.y < size.y * 0.5 else -arm
		draw_line(corner, corner + Vector2(horizontal, 0), bracket, 1.5)
		draw_line(corner, corner + Vector2(0, vertical), bracket, 1.5)
