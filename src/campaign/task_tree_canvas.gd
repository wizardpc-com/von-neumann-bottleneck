extends Control
signal task_selected(key: String)
const Layout = preload("res://src/campaign/task_tree_layout.gd")
const NODE_SIZE: Vector2 = Layout.NODE_SIZE
const COLORS := [Color("67e8a5"),Color("ffbf69"),Color("50d5ff"),Color("bc8cff"),Color("f4a6cb")]
var region_rects: Dictionary = {}
var world_size := Vector2(2500,1900)
const SHORT_TITLES := {
 "tutorial":["接线","Wiring"],"half_adder":["半加器","Half adder"],"full_adder":["全加器","Full adder"],"alu":["ALU","ALU"],"latch":["锁存器","Latch"],"register":["寄存器","Register"],"ram":["RAM","RAM"],"cpu":["CPU","CPU"],"load_store":["存取指令","Load/store"],"selector":["两路选择","Select 2"],"selector4":["四路选择","Select 4"],"parity":["一位校验","Parity"],"alarm":["留住一瞬","Remember"],"delay":["晚一拍","Delay"],
 "assembly":["三器相连","One Machine"],"cpu_speed":["快慢之间","Still Waiting"],"ram_wait":["等待的来处","Round Trip"],"bus_width":["宽窄之间","Room to Pass"],"bottleneck":["循时寻因","Find Delay"],"read_once":["一取再用","Read Once"],"two_orders":["两张订单","Two orders"],
 "distant_reads":["远取之累","Far Reads"],"nearby_storage":["留待再用","Reuse"],"cache_failure":["留不住的数据","Eviction"],"access_order":["先后有序","Order"],"working_set":["容量有界","Working Set"],"blocking":["分而复用","Batches"],"capstone":["循迹而行","Investigate"],
 "arrival":["尚在途中","Still on the Way"],"buffers":["交替接力","Taking Turns"],"backpressure":["进退有度","Give and Take"],"prefetch":["先行一步","One Step Ahead"],"distance":["过犹不及","Too Far Ahead"],"synthesis":["各行其时","In Good Time"],
 "fields":["只取所需","What We Need"],"records":["一窥全貌","Whole Picture"],"hot_cold":["冷热有别","Separate Ways"],"relocation":["搬迁有价","Moving Costs"],"batches":["化整为零","Piece by Piece"],"mixed":["两全之策","Common Ground"]}
var rows: Array[Dictionary] = []
var positions: Dictionary = {}
var pan := Vector2.ZERO
var magnification: float = 0.55
var dragging: bool = false
var moved: bool = false
var press_position := Vector2.ZERO
var drag_position := Vector2.ZERO
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
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.055,0.085,0.68))
	if rows.is_empty(): return
	draw_set_transform(pan,0,Vector2.ONE*magnification)
	# Region trays are derived from the same dependency layout as the nodes.
	# They distinguish chapters without becoming new navigation or progress gates.
	for region: int in region_rects:
		var tray: Rect2 = region_rects[region]
		var tray_style: StyleBoxFlat = InstrumentTheme.surface(Color("0c1925"),Color(_color(region),0.16),18)
		tray_style.shadow_size=24
		draw_style_box(tray_style,tray)
		draw_line(tray.position+Vector2(24,16),tray.position+Vector2(24,66),Color(_color(region),0.65),3,true)
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
		style.bg_color = Color("1b3443") if task.unlocked else Color("132331")
		style.border_color = color.lightened(0.35) if task.key==hovered_key else color
		style.set_border_width_all(3 if task.key == TaskNavigation.selected else 2 if task.key==hovered_key else 1)
		if task.key==hovered_key: style.bg_color=style.bg_color.lightened(0.06)
		style.set_corner_radius_all(10)
		style.shadow_color=Color(0,0,0,0.35)
		style.shadow_size=8
		style.shadow_offset=Vector2(0,5)
		if task.key==TaskNavigation.selected:
			style.shadow_color=Color(color,0.16); style.shadow_size=12
		draw_style_box(style,rect)
		draw_line(rect.position+Vector2(12,3),rect.position+Vector2(NODE_SIZE.x-12,3),Color(color,0.22),1,true)
		if task.completed:
			draw_circle(rect.position+Vector2(NODE_SIZE.x-12,12),5,color)
		if task.optional:
			var mid: Vector2 = rect.position+Vector2(0,NODE_SIZE.y/2)
			draw_colored_polygon(PackedVector2Array([mid+Vector2(-8,0),mid+Vector2(0,-8),mid+Vector2(8,0),mid+Vector2(0,8)]),color)
	draw_set_transform(Vector2.ZERO)
	_draw_screen_text()

# Shapes follow the world camera; glyphs are rasterized at their final screen size.
# At overview scale, region titles and node shapes provide orientation. Tiny task
# text is omitted; hovering or selecting still exposes the complete title.
func node_text_layout(task: Dictionary) -> Dictionary:
	var rect := Rect2(positions[task.key]*magnification+pan,NODE_SIZE*magnification)
	if magnification<0.34: return {}
	var compact: bool = magnification<0.62
	var names: Array = SHORT_TITLES.get(task.id,[task.title,task.title])
	var title: String = names[0 if Localization.current_locale().begins_with("zh") else 1] if compact else task.title
	var font_size: int = 14 if compact else maxi(16,roundi(18*magnification))
	var inset: float = maxf(7,12*magnification)
	var width: float = rect.size.x-2*inset
	var font: Font = get_theme_default_font()
	# Preserve the identifying words instead of truncating a repeated chapter prefix.
	if font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
		title=names[0 if Localization.current_locale().begins_with("zh") else 1]
	title=_fit_text(title,font,font_size,width)
	var baseline: float = (rect.size.y-font.get_height(font_size))*0.5+font.get_ascent(font_size) if compact else 31*magnification
	return {"rect":rect,"title":title,"font_size":font_size,"width":width,
		"position":(rect.position+Vector2(inset,baseline)).round(),"compact":compact}

func _fit_text(value: String,font: Font,font_size: int,width: float) -> String:
	if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=width: return value
	var shortened: String=value
	while not shortened.is_empty() and font.get_string_size(shortened+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
		shortened=shortened.left(shortened.length()-1)
	# Prefer English word boundaries, while keeping Chinese character boundaries.
	var space: int=shortened.rfind(" ")
	if space>shortened.length()/2: shortened=shortened.left(space)
	return shortened.strip_edges()+"…"

func _draw_screen_text() -> void:
	var font: Font=get_theme_default_font()
	for region: int in region_rects:
		var rect: Rect2=region_rects[region]
		var key:=StringName("tree.region."+str(region))
		var title: String=Localization.text(key)
		if title==String(key): title="Chapter "+str(region)
		var font_size: int=maxi(16,roundi(30*magnification))
		var width: float=rect.size.x*magnification-20
		draw_string(font,((rect.position+Vector2(50,10))*magnification+pan).round(),_fit_text(title,font,font_size,width),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,_color(region))
	for task: Dictionary in rows:
		var layout: Dictionary=node_text_layout(task)
		if layout.is_empty(): continue
		var color:=Color("e2eef8") if task.unlocked else Color("9baabd")
		if not query.is_empty() and not _matches(task): color.a=0.35
		draw_string(font,layout.position,layout.title,HORIZONTAL_ALIGNMENT_LEFT,-1,layout.font_size,color)
		if layout.compact: continue
		var caption: String=("◇ " if task.optional else "")+(("已完成" if task.completed else "可进入" if task.unlocked else "未解锁") if Localization.current_locale().begins_with("zh") else ("Completed" if task.completed else "Available" if task.unlocked else "Locked"))
		var caption_size: int=maxi(12,roundi(15*magnification))
		var rect: Rect2=layout.rect
		var at: Vector2=Vector2(layout.position.x,rect.position.y+62*magnification).round()
		draw_string(font,at,_fit_text(caption,font,caption_size,layout.width),HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size,color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom_at(event.position,1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.12)
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
			if event.pressed:
				dragging = true; moved = false; press_position = event.position
				drag_position = event.position
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
		# Captured native motion can omit its button mask. The preceding press,
		# explicit release and focus notifications own the gesture lifetime.
		if event.position.distance_to(press_position)>4: moved = true
		if moved: pan += event.position-drag_position; _save()
		drag_position = event.position
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

func _input(event: InputEvent) -> void:
	if not dragging or not event is InputEventMouseButton: return
	if event.pressed or event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]: return
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
	if not Rect2(Vector2.ZERO,size).has_point(local): _cancel_drag()

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
