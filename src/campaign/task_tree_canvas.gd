extends Control
signal task_selected(key: String)
const NODE_SIZE := Vector2(208,82)
const WORLD_SIZE := Vector2(2310,1770)
const COLORS := [Color("67e8a5"),Color("ffbf69"),Color("50d5ff"),Color("bc8cff")]
const POSITIONS := {
	"tutorial":Vector2(0,1),"half_adder":Vector2(1,0),"full_adder":Vector2(2,0),"alu":Vector2(3,0),
	"latch":Vector2(1,2),"register":Vector2(2,2),"ram":Vector2(3,2),"cpu":Vector2(5,1),"load_store":Vector2(6,1),
	"selector":Vector2(2,-1),"selector4":Vector2(3,-1),"parity":Vector2(1,-1),"alarm":Vector2(1,3),"delay":Vector2(3,3),
	"assembly":Vector2(0,0),"cpu_speed":Vector2(1,0),"ram_wait":Vector2(2,0),"bus_width":Vector2(3,0),"bottleneck":Vector2(4,0),
	"read_once":Vector2(2,1),"two_orders":Vector2(4,1),
	"distant_reads":Vector2(0,0),"nearby_storage":Vector2(1,0),"cache_failure":Vector2(2,0),"access_order":Vector2(3,0),
	"working_set":Vector2(4,0),"blocking":Vector2(5,0),"capstone":Vector2(6,0),
	"arrival":Vector2(0,1),"buffers":Vector2(1,0),"backpressure":Vector2(2,0),"prefetch":Vector2(1,2),
	"distance":Vector2(2,2),"synthesis":Vector2(3,1)}
var rows: Array[Dictionary] = []
var positions: Dictionary = {}
var pan := Vector2.ZERO
var magnification: float = 0.55
var dragging: bool = false
var moved: bool = false
var press_position := Vector2.ZERO
var query: String = ""

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	pan = TaskNavigation.camera if TaskNavigation.camera_saved else Vector2(30,30)
	magnification = TaskNavigation.zoom
	if not TaskNavigation.camera_saved: call_deferred("locate",TaskNavigation.selected)

func configure(tasks: Array[Dictionary]) -> void:
	rows = tasks
	for task: Dictionary in rows:
		var p: Vector2 = POSITIONS.get(task.id,Vector2.ZERO)
		var region: int = task.region
		var y: float = [220.0,790.0,1150.0,1400.0][region]
		positions[task.key] = Vector2(80+p.x*300,y+p.y*112)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0a1220"))
	if rows.is_empty(): return
	draw_set_transform(pan,0,Vector2.ONE*magnification)
	var font: Font = get_theme_default_font()
	for region: int in range(4):
		var y: float = [55.0,730.0,1090.0,1330.0][region]
		draw_string(font,Vector2(80,y),Localization.text(StringName("tree.region."+str(region))),HORIZONTAL_ALIGNMENT_LEFT,-1,32,COLORS[region])
	for task: Dictionary in rows:
		for dep: String in task.dependencies:
			if not positions.has(dep): continue
			var a: Vector2 = positions[dep]+Vector2(NODE_SIZE.x,NODE_SIZE.y/2)
			var b: Vector2 = positions[task.key]+Vector2(0,NODE_SIZE.y/2)
			var color := Color("354963")
			if task.key == TaskNavigation.selected: color = COLORS[task.region]
			var path := PackedVector2Array([a,Vector2((a.x+b.x)/2,a.y),Vector2((a.x+b.x)/2,b.y),b])
			draw_polyline(path,color,2.0,true)
			draw_colored_polygon(PackedVector2Array([b,b+Vector2(-8,-5),b+Vector2(-8,5)]),color)
	for task: Dictionary in rows:
		var rect := Rect2(positions[task.key],NODE_SIZE)
		var color: Color = COLORS[task.region] if task.unlocked else Color("63758b")
		var matched: bool = query.is_empty() or _matches(task)
		if not matched: color.a = 0.28
		var style := StyleBoxFlat.new()
		style.bg_color = Color("142337") if task.unlocked else Color("101b2a")
		style.border_color = color
		style.set_border_width_all(3 if task.key == TaskNavigation.selected else 1)
		style.set_corner_radius_all(10)
		draw_style_box(style,rect)
		var title: String = task.title
		var font_size: int = 18
		while font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > NODE_SIZE.x-24 and title.length()>2:
			title = title.left(title.length()-2)+"…"
		draw_string(font,rect.position+Vector2(12,31),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
		var state: String = "completed" if task.completed else "available" if task.unlocked else "locked_short"
		var caption: String = ("◇ " if task.optional else "")+Localization.text(StringName("tree."+state))
		draw_string(font,rect.position+Vector2(12,62),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,15,color)
	draw_set_transform(Vector2.ZERO)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom_at(event.position,1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.12)
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				dragging = true; moved = false; press_position = event.position
			else:
				if dragging and not moved and event.button_index == MOUSE_BUTTON_LEFT:
					var world: Vector2 = (event.position-pan)/magnification
					for task: Dictionary in rows:
						if Rect2(positions[task.key],NODE_SIZE).has_point(world): task_selected.emit(task.key); break
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		if event.position.distance_to(press_position)>4: moved = true
		if moved: pan += event.relative; _save()
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.position,event.factor)
	elif event is InputEventPanGesture:
		pan -= event.delta*18; _save()
	accept_event()

func _zoom_at(point: Vector2,factor: float) -> void:
	var world: Vector2 = (point-pan)/magnification
	magnification = clampf(magnification*factor,0.28,1.6)
	pan = point-world*magnification
	_save()

func locate(key: String) -> void:
	if not positions.has(key): return
	magnification = maxf(magnification,0.85)
	pan = size/2-(positions[key]+NODE_SIZE/2)*magnification
	_save()

func overview() -> void:
	magnification = clampf(minf(size.x/WORLD_SIZE.x,size.y/WORLD_SIZE.y),0.28,0.8)
	pan = Vector2(15,15)
	_save()

func set_search(value: String) -> void:
	query = value.strip_edges().to_lower()
	queue_redraw()

func locate_match() -> void:
	for task: Dictionary in rows:
		if not query.is_empty() and _matches(task):
			locate(task.key); task_selected.emit(task.key); return

func _matches(task: Dictionary) -> bool:
	return query in String(task.title).to_lower() or query in String(task.key).to_lower()

func _save() -> void:
	TaskNavigation.camera = pan
	TaskNavigation.zoom = magnification
	TaskNavigation.camera_saved = true
	queue_redraw()
