extends Control
## Read-only virtual pointer. No Input.parse_input_event, mouse warp, circuit or save writes.
## Caller supplies actual currently visible control/port positions in this canvas.
signal demonstration_active_changed(active: bool)
const INK := Color("edf5ff")
const ACCENT := Color("7fcbd6")
var path := PackedVector2Array()
var elapsed: float = 0.0
var duration: float = 3.6
var running: bool = false
var reduced_motion: bool = false
var english: bool = false
var caption: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	z_index = 110
	visible = false
	set_process(false)

func demonstrate(points: PackedVector2Array, text: String, reduced: bool = false) -> void:
	stop()
	if points.is_empty() or points.size() > 32: return
	for point: Vector2 in points:
		if not point.is_finite(): return
	path = points.duplicate()
	caption = text
	reduced_motion = reduced
	elapsed = 0.0
	running = true
	demonstration_active_changed.emit(true)
	visible = true
	set_process(true)
	queue_redraw()

func stop() -> void:
	var was_running: bool = running
	running = false
	if was_running: demonstration_active_changed.emit(false)
	visible = false
	set_process(false)
	path.clear()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	# A single illustration, never a distracting endless loop.
	if elapsed >= duration + 1.0: stop(); return
	queue_redraw()

func pointer_position() -> Vector2:
	if path.is_empty(): return Vector2.ZERO
	if reduced_motion or path.size() == 1: return path[-1]
	var t: float = clampf((elapsed-0.6)/(duration-1.2),0.0,1.0)
	var segment: float = smoothstep(0.0,1.0,t)*float(path.size()-1)
	var index: int = mini(path.size()-2,floori(segment))
	return path[index].lerp(path[index+1],segment-float(index))

func _draw() -> void:
	if not running or path.is_empty(): return
	for index: int in range(path.size()-1):
		draw_dashed_line(path[index],path[index+1],Color(ACCENT,0.60),2.0,8.0,true)
	for point: Vector2 in path:
		draw_arc(point,12.0,0.0,TAU,32,Color(ACCENT,0.9),2.0,true)
	var at: Vector2 = pointer_position()
	var arrow := PackedVector2Array([at,at+Vector2(0,24),at+Vector2(6,18),at+Vector2(11,28),at+Vector2(15,26),at+Vector2(10,16),at+Vector2(19,16)])
	draw_colored_polygon(arrow,INK)
	var border := arrow.duplicate(); border.append(arrow[0])
	draw_polyline(border,Color("172b3d"),1.5,true)
	# Label explicitly identifies a demonstration; it is not the player's cursor.
	var text: String = ("Demo · " if english else "演示 · ") + caption
	var font: Font = get_theme_default_font()
	var width: float = minf(360.0,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+20.0)
	var anchor := Vector2(clampf(at.x+25.0,4.0,maxf(4.0,size.x-width-4.0)),clampf(at.y+28.0,22.0,maxf(22.0,size.y-24.0)))
	draw_rect(Rect2(anchor-Vector2(5,17),Vector2(width,24)),Color("152735"),true)
	draw_string(font,anchor,text,HORIZONTAL_ALIGNMENT_LEFT,width-10.0,14,INK)


static func wire_cut_path(curve: PackedVector2Array) -> PackedVector2Array:
	# Cross the actual wire's local tangent, including vertical and bent wires.
	# A fixed vertical gesture can run along a wire instead of cutting across it.
	if curve.size()<2 or curve.size()>2048:return PackedVector2Array()
	var total: float=0.0
	for index: int in curve.size():
		if not curve[index].is_finite():return PackedVector2Array()
		if index>0:total+=curve[index-1].distance_to(curve[index])
	if total<0.01:return PackedVector2Array()
	var remaining: float=total/2.0
	for index: int in curve.size()-1:
		var delta: Vector2=curve[index+1]-curve[index]
		var length: float=delta.length()
		if length<0.0001:continue
		if remaining<=length:
			var center: Vector2=curve[index].lerp(curve[index+1],remaining/length)
			var normal: Vector2=Vector2(-delta.y,delta.x).normalized()*24.0
			return PackedVector2Array([center-normal,center+normal])
		remaining-=length
	return PackedVector2Array()
