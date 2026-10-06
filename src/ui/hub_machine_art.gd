extends Control
## Original static title artwork. The material and paths are a motif, never a machine trace.
## No task state, clock, randomness or input participates in the drawing.
const INK := Color("0c1b27")
const EDGE := Color("385b67")
const CYAN := Color("91dfd7")
const GOLD := Color("dfb983")

func _ready() -> void:
	custom_minimum_size = Vector2(460,340)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _path(points: Array[Vector2], color: Color, width: float = 1.5) -> void:
	draw_polyline(PackedVector2Array(points),color,width,true)

func _face(points: Array[Vector2], color: Color, edge: Color = EDGE) -> void:
	var polygon := PackedVector2Array(points)
	draw_colored_polygon(polygon,color)
	polygon.append(points[0]); draw_polyline(polygon,edge,1,true)

func _tile(origin: Vector2, width: float, depth: float, height: float, color: Color) -> void:
	var right := Vector2(width,20*width/100)
	var back := Vector2(depth,-0.65*depth)
	var up := Vector2(0,-height)
	_face([origin,origin+right,origin+right+up,origin+up],color.darkened(0.35))
	_face([origin+right,origin+right+back,origin+right+back+up,origin+right+up],color.darkened(0.5))
	_face([origin+up,origin+right+up,origin+right+back+up,origin+back+up],color)

func _draw() -> void:
	var ratio: float = minf(size.x/640.0,size.y/520.0)
	var origin: Vector2 = (size-Vector2(640,520)*ratio)*0.5
	draw_set_transform(origin,0,Vector2.ONE*ratio)
	# A finite field, drawn in layers: room around the system matters as much as its lines.
	for radius: int in range(5,0,-1):
		draw_circle(Vector2(330,260),float(radius)*48,Color(0.21,0.55,0.57,0.015))
	for index: int in 9:
		var start := Vector2(34+index*52,424+index*10.4)
		draw_line(start,start+Vector2(174,-113),Color("203741"),1,true)
	for index: int in 7:
		var start := Vector2(34+index*29,424-index*18.8)
		draw_line(start,start+Vector2(416,83.2),Color("203741"),1,true)
	# Lower material plate and its fine exposed edge.
	_tile(Vector2(93,374),330,152,13,Color("152e3a"))
	_path([Vector2(95,363),Vector2(425,429),Vector2(571,334)],Color("547e83"),1)
	_path([Vector2(124,393),Vector2(320,432)],Color("223f4a"),3)
	# Stored marks vary in form; none stand in for measured data or player progress.
	for row: int in 5:
		for column: int in 6:
			var point := Vector2(132,329)+Vector2(column*24,column*4.8)+Vector2(row*13,-row*8.45)
			var warm: bool = (column+row*2)%7 == 0
			_tile(point,16,10,2,Color("8d795d") if warm else Color("345560"))
	# Three elevated sheets hold distinct marks with clear depth and bounded surfaces.
	for layer: int in range(2,-1,-1):
		var base := Vector2(293,299-layer*30)
		_tile(base,126,98,8,Color("1c3944") if layer != 0 else Color("274952"))
		for line: int in 5:
			var start := base+Vector2(22+line*10,-18-line*6.5)
			_path([start,start+Vector2(83,16.6)],Color("557c7e"),2)
	# Information crosses a narrow connection and leaves a continuing, bounded trail.
	_path([Vector2(143,297),Vector2(188,267),Vector2(245,278),Vector2(284,252)],Color("345762"),7)
	_path([Vector2(143,297),Vector2(188,267),Vector2(245,278),Vector2(284,252)],CYAN,1.8)
	_path([Vector2(333,180),Vector2(379,150),Vector2(461,166),Vector2(495,144)],Color("3d646c"),5)
	_path([Vector2(333,180),Vector2(379,150),Vector2(461,166),Vector2(495,144)],CYAN,1.4)
	# A standing plane: individual strokes become a retained arrangement.
	_face([Vector2(117,266),Vector2(229,288),Vector2(229,147),Vector2(117,125)],INK)
	_face([Vector2(229,288),Vector2(241,280),Vector2(241,139),Vector2(229,147)],Color("152a35"))
	for line: int in 8:
		var start := Vector2(132,145+line*14)
		var length: float = 73 if line%3 == 0 else 48 if line%3 == 1 else 60
		_path([start,start+Vector2(length,length*0.2)],GOLD if line == 5 else Color("537c83"),2.5)
		if line%3 == 1: draw_circle(start+Vector2(76,15.2),2,CYAN)
	# A smaller terminal surface keeps the motif open, without a face or consciousness claim.
	_tile(Vector2(457,271),54,39,80,Color("274750"))
	for line: int in 4:
		var start := Vector2(466,204+line*12)
		_path([start,start+Vector2(31,6.2)],CYAN if line == 1 else Color("60888c"),2)
	_path([Vector2(495,144),Vector2(529,122),Vector2(554,127)],Color("456b70"),1)
	draw_circle(Vector2(554,127),3,GOLD)
	# Registration marks are framing, not clickable map nodes.
	for corner: Vector2 in [Vector2(76,104),Vector2(559,426)]:
		draw_line(corner,corner+Vector2(14,0),Color("567479"),1,true)
		draw_line(corner,corner+Vector2(0,14),Color("567479"),1,true)
	draw_set_transform(Vector2.ZERO)
