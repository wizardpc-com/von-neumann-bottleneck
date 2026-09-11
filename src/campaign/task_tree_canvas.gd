extends Control
signal task_selected(key: String)
const Layout = preload("res://src/campaign/task_tree_layout.gd")
const NODE_SIZE: Vector2 = Layout.NODE_SIZE
const COLORS := [Color("67e8a5"),Color("ffbf69"),Color("50d5ff"),Color("bc8cff"),Color("f4a6cb")]
var region_rects: Dictionary = {}
var world_size := Vector2(2500,1900)
const SHORT_TITLES := {
 "tutorial":["接线","Wiring"],"half_adder":["半加器","Half adder"],"full_adder":["全加器","Full adder"],"alu":["ALU","ALU"],"latch":["锁存器","Latch"],"register":["寄存器","Register"],"ram":["RAM","RAM"],"cpu":["CPU","CPU"],"load_store":["存取指令","Load/store"],"selector":["两路选择","Select 2"],"selector4":["四路选择","Select 4"],"parity":["一位校验","Parity"],"alarm":["保留报警","Alarm"],"delay":["晚一拍","Delay"],
 "assembly":["组装系统","Assemble"],"cpu_speed":["CPU 速度","CPU speed"],"ram_wait":["谁在等待","Waiting"],"bus_width":["总线宽度","Bus width"],"bottleneck":["瓶颈调查","Bottleneck"],"read_once":["只取一次","Read once"],"two_orders":["两张订单","Two orders"],
 "distant_reads":["远处取数","Far reads"],"nearby_storage":["近处缓存","Cache"],"cache_failure":["缓存失效","Misses"],"access_order":["访问顺序","Order"],"working_set":["工作集","Working set"],"blocking":["分块查询","Blocking"],"capstone":["综合优化","Optimize"],
 "arrival":["请求完成","Arrival"],"buffers":["双缓冲","Buffers"],"backpressure":["状态协调","Flow control"],"prefetch":["提前取数","Prefetch"],"distance":["预取距离","Distance"],"synthesis":["时序综合","Coordinate"],
 "fields":["只取所需","Need only"],"records":["整条取来","Full record"],"hot_cold":["冷热分开","Hot / cold"],"relocation":["搬家成本","Move cost"],"batches":["有限分批","Batch"],"mixed":["两类查询","Two queries"]}
var rows: Array[Dictionary] = []
var positions: Dictionary = {}
var pan := Vector2.ZERO
var magnification: float = 0.55
var dragging: bool = false
var moved: bool = false
var press_position := Vector2.ZERO
var query: String = ""
var exposed: Dictionary = {}
var hovered_key: String = ""
var last_canvas_size := Vector2.ZERO

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: _set_hover(""))
	WindowMode.window_mode_changing.connect(_cancel_drag)
	resized.connect(_resize_view)
	pan = TaskNavigation.camera if TaskNavigation.camera_saved else Vector2(30,30)
	magnification = TaskNavigation.zoom
	if not TaskNavigation.camera_saved: call_deferred("locate",TaskNavigation.selected)

func configure(tasks: Array[Dictionary]) -> void:
	rows = tasks
	var layout: Dictionary = Layout.build(rows)
	positions=layout.positions
	region_rects=layout.regions
	world_size=layout.size
	for message: String in layout.errors: push_error(message)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0a1220"))
	if rows.is_empty(): return
	draw_set_transform(pan,0,Vector2.ONE*magnification)
	var font: Font = get_theme_default_font()
	for region: int in region_rects:
		var rect: Rect2 = region_rects[region]
		var key: StringName = StringName("tree.region."+str(region))
		var title: String = Localization.text(key)
		if title==String(key): title="Chapter "+str(region)
		draw_string(font,rect.position+Vector2(50,10),title,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(30,ceili(15/magnification)),_color(region))
	for task: Dictionary in rows:
		for dep: String in task.dependencies:
			if not positions.has(dep): continue
			var a: Vector2 = positions[dep]+Vector2(NODE_SIZE.x,NODE_SIZE.y/2)
			var b: Vector2 = positions[task.key]+Vector2(0,NODE_SIZE.y/2)
			var color := Color("354963")
			if task.key == TaskNavigation.selected: color = _color(task.region)
			var points: PackedVector2Array
			if dep.get_slice("/",0)!=task.domain:
				# Chapter bridges travel through the free gutter, never across task cards.
				var source_region: int = 0
				for other: Dictionary in rows:
					if other.key==dep: source_region=other.region; break
				var gutter: float = (region_rects[source_region] as Rect2).end.y+45
				points=PackedVector2Array([a,a+Vector2(24,0),Vector2(a.x+24,gutter),Vector2(b.x-32,gutter),Vector2(b.x-32,b.y),b])
			else:
				var curve := Curve2D.new()
				var distance: float = maxf(30,(b.x-a.x)*0.5)
				curve.add_point(a,Vector2.ZERO,Vector2(distance,0))
				curve.add_point(b,Vector2(-distance,0),Vector2.ZERO)
				points=curve.tessellate()
			draw_polyline(points,Color(color,0.14),maxf(6,3/magnification),true)
			draw_polyline(points,color,maxf(1.8,1.1/magnification),true)
			draw_colored_polygon(PackedVector2Array([b,b+Vector2(-8,-5),b+Vector2(-8,5)]),color)
	for task: Dictionary in rows:
		var rect := Rect2(positions[task.key],NODE_SIZE)
		var color: Color = _color(task.region) if task.unlocked else Color("63758b")
		var matched: bool = query.is_empty() or _matches(task)
		if not matched: color.a = 0.28
		var style := StyleBoxFlat.new()
		style.bg_color = Color("142337") if task.unlocked else Color("101b2a")
		style.border_color = color.lightened(0.35) if task.key==hovered_key else color
		style.set_border_width_all(3 if task.key == TaskNavigation.selected else 2 if task.key==hovered_key else 1)
		if task.key==hovered_key: style.bg_color=style.bg_color.lightened(0.06)
		style.set_corner_radius_all(10)
		if task.key==TaskNavigation.selected:
			style.shadow_color=Color(color,0.16); style.shadow_size=12
		draw_style_box(style,rect)
		if task.completed:
			draw_circle(rect.position+Vector2(NODE_SIZE.x-12,12),5,color)
		if task.optional:
			var mid: Vector2 = rect.position+Vector2(0,NODE_SIZE.y/2)
			draw_colored_polygon(PackedVector2Array([mid+Vector2(-8,0),mid+Vector2(0,-8),mid+Vector2(8,0),mid+Vector2(0,8)]),color)
		if magnification<0.62:
			var names: Array = SHORT_TITLES.get(task.id,[task.title,task.title])
			var short_title: String = names[0 if Localization.current_locale().begins_with("zh") else 1]
			var compact_size: int = ceili(14/magnification)
			while font.get_string_size(short_title,HORIZONTAL_ALIGNMENT_LEFT,-1,compact_size).x>NODE_SIZE.x-22 and compact_size>18: compact_size-=1
			while font.get_string_size(short_title,HORIZONTAL_ALIGNMENT_LEFT,-1,compact_size).x>NODE_SIZE.x-22 and short_title.length()>2:
				short_title=short_title.left(short_title.length()-2)+"…"
			draw_string(font,rect.position+Vector2(10,51),short_title,HORIZONTAL_ALIGNMENT_LEFT,-1,compact_size,color)
			continue
		var title: String = task.title
		var font_size: int = maxi(18,ceili(16.0/magnification))
		while font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x > NODE_SIZE.x-24 and title.length()>2:
			title = title.left(title.length()-2)+"…"
		draw_string(font,rect.position+Vector2(12,31),title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
		var caption: String = ("◇ " if task.optional else "")+(("已完成" if task.completed else "可进入" if task.unlocked else "未解锁") if Localization.current_locale().begins_with("zh") else ("Completed" if task.completed else "Available" if task.unlocked else "Locked"))
		draw_string(font,rect.position+Vector2(12,62),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(15,ceili(12.0/magnification)),color)
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
						if Rect2(positions[task.key],NODE_SIZE).has_point(world):
							task_selected.emit(task.key)
							if magnification<0.62: locate(task.key)
							break
				dragging = false
	elif event is InputEventMouseMotion and dragging:
		if (event.button_mask & (MOUSE_BUTTON_MASK_LEFT|MOUSE_BUTTON_MASK_MIDDLE))==0:
			_cancel_drag(); return
		if event.position.distance_to(press_position)>4: moved = true
		if moved: pan += event.relative; _save()
	elif event is InputEventMouseMotion:
		tooltip_text=""
		var next_hover: String = ""
		var world: Vector2 = (event.position-pan)/magnification
		for task: Dictionary in rows:
			if Rect2(positions[task.key],NODE_SIZE).has_point(world):
				tooltip_text=task.title; next_hover=task.key; break
		_set_hover(next_hover)
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.position,event.factor)
	elif event is InputEventPanGesture:
		pan -= event.delta*18; _save()
	accept_event()

func _set_hover(key: String) -> void:
	if hovered_key==key: return
	hovered_key=key
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if not key.is_empty() else Control.CURSOR_ARROW
	queue_redraw()

func _cancel_drag() -> void:
	dragging=false; moved=false
	_set_hover("")

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: _cancel_drag()

func _zoom_at(point: Vector2,factor: float) -> void:
	var world: Vector2 = (point-pan)/magnification
	magnification = clampf(magnification*factor,0.18,1.6)
	pan = point-world*magnification
	_save()

func locate(key: String) -> void:
	if not positions.has(key): return
	magnification = maxf(magnification,0.85)
	pan = size/2-(positions[key]+NODE_SIZE/2)*magnification
	last_canvas_size=size
	_save()

func _resize_view() -> void:
	# Container layout and window changes must preserve the world point at center.
	if last_canvas_size.x>0 and last_canvas_size.y>0:
		pan+=(size-last_canvas_size)/2
	last_canvas_size=size
	_save()

func overview() -> void:
	magnification = clampf(minf(size.x/world_size.x,size.y/world_size.y),0.18,0.8)
	pan = (size-world_size*magnification)/2
	_save()

func set_search(value: String) -> void:
	query = value.strip_edges().to_lower()
	var count: int = 0
	for task: Dictionary in rows:
		if _matches(task): count += 1
	PlaytestData.record_map_action(&"search", "", {"result_count":count})
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
	call_deferred("_report_exposure")
	queue_redraw()


func _report_exposure() -> void:
	# Compact nodes have no readable labels; do not count them as task exposure.
	if magnification<0.62: return
	for task: Dictionary in rows:
		var rect := Rect2(positions.get(task.key,Vector2.ZERO)*magnification+pan,NODE_SIZE*magnification)
		if Rect2(Vector2.ZERO,size).intersects(rect) and not exposed.has(task.key):
			exposed[task.key] = true
			PlaytestData.record_map_action(&"viewport_exposure",task.key,{"zoom":magnification,"eligible":task.unlocked})


func _color(region: int) -> Color: return COLORS[posmod(region,COLORS.size())]
