extends Control
## Read-only virtual pointer. No Input.parse_input_event, mouse warp, circuit or save writes.
## Caller supplies actual currently visible control/port positions in this canvas.
signal demonstration_active_changed(active: bool)
const INK := Color("edf5ff")
const ACCENT := Color("83b5ed")
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
		draw_dashed_line(path[index], path[index+1], Color(ACCENT, 0.35), 2.0, 7.0, true)
	for point: Vector2 in path:
		draw_arc(point, 9.0, 0.0, TAU, 32, Color(ACCENT, 0.75), 1.5, true)
	var at: Vector2 = pointer_position()
	var held: bool = elapsed >= 0.6 and elapsed < duration - 0.6
	for layer: int in range(18, 0, -1):
		draw_circle(at + Vector2(7, 10), float(layer) * (2.0 if held else 1.7), Color(ACCENT, 0.012), true, -1.0, true)
	if not reduced_motion:
		for moment: float in [0.6, duration - 0.6]:
			var pulse: float = (elapsed - moment) / 0.45
			if pulse >= 0.0 and pulse <= 1.0:
				draw_arc(at, 10.0 + pulse * 14.0, 0.0, TAU, 40, Color(ACCENT, 1.0 - pulse), 2.0, true)
	var arrow := PackedVector2Array([
		Vector2(0, 1), Vector2(0.5, 0.3), Vector2(1.5, 0), Vector2(3, 0.3),
		Vector2(24, 8.3), Vector2(25, 9), Vector2(25.3, 10), Vector2(24.8, 11),
		Vector2(23.5, 11.8), Vector2(14, 15), Vector2(12.8, 16.2),
		Vector2(9, 26), Vector2(8.2, 27.2), Vector2(7, 27.5), Vector2(5.8, 26.8),
		Vector2(5.2, 25.5), Vector2(0, 3),
	])
	for index: int in arrow.size(): arrow[index] += at
	var shadow := arrow.duplicate()
	for index: int in shadow.size(): shadow[index] += Vector2(0, 2)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.28))
	draw_colored_polygon(arrow, Color("172432"))
	var border := arrow.duplicate()
	border.append(arrow[0])
	draw_polyline(border, INK, 2.2, true)




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
