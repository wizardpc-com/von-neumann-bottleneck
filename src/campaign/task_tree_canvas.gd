extends Control
signal task_selected(key: String)
const Layout = preload("res://src/campaign/task_tree_layout.gd")
const NODE_SIZE: Vector2 = Layout.NODE_SIZE
const COLORS := [Color("7fd8a4"),Color("f0c674"),Color("7fcbd6"),Color("aab6e6"),Color("f4a6cb"),Color("a6b4ff"),Color("75dcc0"),Color("e2c87d")]
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
var relation_index: Dictionary = {}
var region_by_key: Dictionary = {}
var edge_geometry_cache: Dictionary = {}
var dash_geometry_cache: Dictionary = {}
var dash_cache_zoom: float = -1.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: _set_hover(""))
	WindowMode.window_mode_changing.connect(_cancel_drag)
	resized.connect(_resize_view)
	pan = TaskNavigation.camera if TaskNavigation.camera_saved else Vector2(30,30)
	magnification = TaskNavigation.zoom
	last_canvas_size = TaskNavigation.camera_view_size if TaskNavigation.camera_saved else Vector2.ZERO
	if not TaskNavigation.camera_saved: call_deferred("locate",TaskNavigation.selected)

func configure(tasks: Array[Dictionary]) -> void:
	rows = tasks
	edge_geometry_cache.clear()
	dash_geometry_cache.clear()
	_rebuild_relation_index()
	var layout: Dictionary = Layout.build(rows)
	positions=layout.positions
	region_rects=layout.regions
	world_size=layout.size
	for message: String in layout.errors: push_error(message)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.055,0.085,0.68))
	if rows.is_empty(): return
	if not is_equal_approx(dash_cache_zoom,magnification):
		dash_geometry_cache.clear();dash_cache_zoom=magnification
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
		for dep: String in task.dependencies: _draw_edge(task,dep,false)
		for dep: String in task.get("recommended_from",[]):
			if dep not in task.dependencies: _draw_edge(task,dep,true)
	for task: Dictionary in rows:
		var rect := Rect2(positions[task.key],NODE_SIZE)
		var color: Color = _color(task.region) if task.unlocked else Color("63758b")
		var matched: bool = query.is_empty() or _matches(task)
		if not matched: color.a = 0.28
		elif not relation_to_focus(task.key).is_empty(): color = color.lightened(0.12)
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

func edge_points(task: Dictionary, dep: String) -> PackedVector2Array:
	var key: String=dep+"\n"+str(task.key)
	if not edge_geometry_cache.has(key): edge_geometry_cache[key]=_build_edge_points(task,dep)
	var points: PackedVector2Array=edge_geometry_cache[key]
	return points.duplicate() # Review consumers cannot mutate the cached geometry.

func _build_edge_points(task: Dictionary, dep: String) -> PackedVector2Array:
	if not positions.has(dep) or not positions.has(task.key): return PackedVector2Array()
	var a: Vector2 = positions[dep]+Vector2(NODE_SIZE.x,NODE_SIZE.y/2)
	var b: Vector2 = positions[task.key]+Vector2(0,NODE_SIZE.y/2)
	var points: PackedVector2Array
	var source_region: int=int(region_by_key.get(dep,task.region))
	if source_region != int(task.region):
		var gutter: float = (region_rects[source_region] as Rect2).end.y+45
		points = PackedVector2Array([a,a+Vector2(24,0),Vector2(a.x+24,gutter),Vector2(b.x-32,gutter),Vector2(b.x-32,b.y),b])
	else:
		var curve := Curve2D.new(); var distance: float = maxf(30,(b.x-a.x)*0.5)
		curve.add_point(a,Vector2.ZERO,Vector2(distance,0)); curve.add_point(b,Vector2(-distance,0),Vector2.ZERO)
		points = curve.tessellate()
	return points

func _draw_edge(task: Dictionary,dep: String,recommended: bool) -> void:
	if not positions.has(dep): return
	var b: Vector2 = positions[task.key]+Vector2(0,NODE_SIZE.y/2)
	var color := Color("59736a") if recommended else Color("354963")
	var focus: String = relation_focus_key()
	var emphasized: bool = task.key == focus or dep == focus
	if emphasized: color = _color(task.region).lightened(0.25 if task.key == focus else 0.05)
	elif not focus.is_empty(): color.a = 0.45
	var points: PackedVector2Array=edge_points(task,dep)
	if points.size()<2: return
	var arrow: float=maxf(8.0,5.0/magnification)
	if recommended:
		var key: String=dep+"\n"+str(task.key)
		if not dash_geometry_cache.has(key):
			var dash: float=maxf(10.0,4.0/magnification)
			dash_geometry_cache[key]=dash_polyline(points,dash,dash*0.7)
		draw_multiline(dash_geometry_cache[key],Color(color,color.a*0.85),maxf(2.4 if emphasized else 1.8,1.1/magnification),true)
		draw_polyline(PackedVector2Array([b+Vector2(-arrow,-arrow*0.6),b,b+Vector2(-arrow,arrow*0.6)]),color,maxf(1.8,1.0/magnification),true)
	else:
		draw_polyline(points,Color(color,color.a*0.08),maxf(4,2/magnification),true)
		draw_polyline(points,color,maxf(3.0 if emphasized else 1.8,1.1/magnification),true)
		draw_colored_polygon(PackedVector2Array([b,b+Vector2(-arrow,-arrow*0.6),b+Vector2(-arrow,arrow*0.6)]),color)

# Shapes follow the world camera; glyphs are rasterized at their final screen size.
# At overview scale, region titles and node shapes provide orientation. Tiny task
# text is omitted; hovering or selecting still exposes the complete title.
func node_text_layout(task: Dictionary) -> Dictionary:
	var rect := Rect2(positions[task.key]*magnification+pan,NODE_SIZE*magnification)
	if magnification<0.34: return {}
	var compact: bool = magnification<0.62
	var names: Array = SHORT_TITLES.get(task.id,[task.title,task.title])
	var number: String = str(task.get("number", ""))
	if not number.is_empty(): names = [number + " " + str(names[0]), number + " " + str(names[1])]
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
		for task: Dictionary in rows:
			if task.region == region and task.has("region_title"): title = task.region_title; break
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
		var relation: String = relation_to_focus(task.key)
		var relation_label: String = ""
		var chinese: bool = Localization.current_locale().begins_with("zh")
		match relation:
			"prerequisite": relation_label = "前置" if chinese else "Prerequisite"
			"unlocks": relation_label = "后续" if chinese else "Next"
			"recommended": relation_label = "推荐联系" if chinese else "Suggested"
		if not relation_label.is_empty(): caption = relation_label + " · " + caption
		if str(task.get("evidence_status","")) == "unavailable": caption = "成果待确认" if Localization.current_locale().begins_with("zh") else "Work unconfirmed"
		elif str(task.get("progress_source","")) == "session": caption = "仅本次会话" if Localization.current_locale().begins_with("zh") else "Session only"
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
	magnification = clampf(magnification*factor,_minimum_zoom(),1.6)
	pan = point-world*magnification
	_save()

func locate(key: String) -> void:
	if not positions.has(key): return
	magnification = maxf(magnification,0.85)
	pan = size/2-(positions[key]+NODE_SIZE/2)*magnification
	last_canvas_size=size
	_save()

func _resize_view() -> void:
	if size.x <= 0 or size.y <= 0: return # Ignore intermediate container dimensions.
	# Container layout and window changes must preserve the world point at center.
	if last_canvas_size.x>0 and last_canvas_size.y>0:
		pan+=(size-last_canvas_size)/2
	last_canvas_size=size
	_save()

func focus_region(region: int) -> void:
	if not region_rects.has(region): return
	var rect: Rect2 = region_rects[region]
	magnification = clampf(minf(size.x/rect.size.x,size.y/rect.size.y)*0.9,_minimum_zoom(),1.0)
	pan = size/2-rect.get_center()*magnification
	_save()

func overview() -> void:
	magnification = clampf(minf(size.x/world_size.x,size.y/world_size.y)*0.94,_minimum_zoom(),0.8)
	pan = (size-world_size*magnification)/2
	_save()

func set_search(value: String) -> void:
	query = value.strip_edges().to_lower()
	PlaytestData.record_map_action(&"search", "", {"result_count":matching_keys().size()})
	queue_redraw()

func locate_match() -> void:
	var matches: Array[String] = matching_keys()
	if not matches.is_empty():
		locate(matches[0]); task_selected.emit(matches[0])

func matching_keys() -> Array[String]:
	var matches: Array[String] = []
	if query.is_empty(): return matches
	for task: Dictionary in rows:
		if _matches(task): matches.append(task.key)
	return matches

func _matches(task: Dictionary) -> bool:
	return query in String(task.title).to_lower() or query in String(task.key).to_lower()

func _save() -> void:
	TaskNavigation.camera = pan
	if size.x > 0 and size.y > 0: TaskNavigation.camera_view_size = size
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



func _rebuild_relation_index() -> void:
	relation_index.clear()
	region_by_key.clear()
	for task: Dictionary in rows: region_by_key[task.key]=int(task.region)
	for task: Dictionary in rows:
		if not relation_index.has(task.key): relation_index[task.key] = {}
		for dep: String in task.dependencies:
			relation_index[task.key][dep] = "prerequisite"
			if not relation_index.has(dep): relation_index[dep] = {}
			relation_index[dep][task.key] = "unlocks"
		for dep: String in task.get("recommended_from",[]):
			if not relation_index[task.key].has(dep): relation_index[task.key][dep] = "recommended"
			if not relation_index.has(dep): relation_index[dep] = {}
			if not relation_index[dep].has(task.key): relation_index[dep][task.key] = "recommended"

func relation_to_focus(key: String) -> String:
	var focus: String = relation_focus_key()
	if key == focus: return "selected"
	return String(relation_index.get(focus,{}).get(key,""))


func _minimum_zoom() -> float:
	# The later chapters extend the map vertically. Overview must fit all of them,
	# not silently crop the ending at the old fixed 18% minimum.
	return maxf(0.01,minf(0.18,minf(size.x/maxf(1,world_size.x),size.y/maxf(1,world_size.y))*0.9))

func relation_focus_key() -> String:
	if not hovered_key.is_empty(): return hovered_key
	if magnification<0.34 or not positions.has(TaskNavigation.selected): return ""
	var selected_rect:=Rect2(positions[TaskNavigation.selected]*magnification+pan,NODE_SIZE*magnification)
	return TaskNavigation.selected if Rect2(Vector2.ZERO,size).intersects(selected_rect) else ""


static func dash_polyline(points: PackedVector2Array, dash: float, gap: float) -> PackedVector2Array:
	# Carry dash phase across tessellation segments. Restarting draw_dashed_line
	# for every short segment can make a curved recommendation look solid.
	var result:=PackedVector2Array()
	if points.size()<2 or dash<=0.0 or gap<=0.0 or not is_finite(dash) or not is_finite(gap):return result
	for point: Vector2 in points:
		if not point.is_finite():return result
	var remaining: float=dash
	var visible_dash: bool=true
	for index: int in points.size()-1:
		var cursor: Vector2=points[index]
		var distance: float=cursor.distance_to(points[index+1])
		if distance<0.0001:continue
		var direction: Vector2=(points[index+1]-cursor)/distance
		while distance>0.0001:
			var step: float=minf(distance,remaining)
			var finish: Vector2=cursor+direction*step
			if visible_dash:
				result.append(cursor)
				result.append(finish)
			cursor=finish;distance-=step;remaining-=step
			if remaining<0.0001:
				visible_dash=not visible_dash
				remaining=dash if visible_dash else gap
	return result
