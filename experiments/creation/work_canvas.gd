extends Control
## The saved output only. All cells remain available in a vertical scroll surface.
signal cell_selected(index: int)
const COLORS := [Color("6ce2de"),Color("eead67"),Color("bcacf0"),Color("8cd793")]
var output: Array = []
var selected: int = -1
var columns: int = 16
var cell_size: float = 36
const TRACE_MAPPING: String = "light-trace-v1"
const PHRASE_MAPPING: String = "light-phrases-v1"
const PHRASE_HEIGHT: float = 180.0
const PHRASE_LEFT: float = 36.0
const LANE_TOP: float = 48.0
const LANE_PITCH: float = 28.0
var viewing_mapping: String = "light-shapes-v1"
var revealed: int = -1

func set_presentation(mapping: String, count: int) -> void:
	viewing_mapping = mapping
	revealed = count
	update_layout()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(update_layout)
	update_layout()

func set_output(value: Array) -> void:
	output = value.duplicate()
	selected = -1
	update_layout()

func update_layout() -> void:
	columns = 16 if viewing_mapping in [TRACE_MAPPING,PHRASE_MAPPING] else maxi(4,mini(32,int(maxf(144,size.x-16)/36)))
	if viewing_mapping == PHRASE_MAPPING:
		cell_size = maxf(16,(size.x-PHRASE_LEFT-16)/columns)
		custom_minimum_size = Vector2(320,maxf(90,ceili(float(output.size())/columns)*PHRASE_HEIGHT+8))
	else:
		cell_size = maxf(16,(size.x-16)/columns)
		custom_minimum_size = Vector2(160,maxf(90,ceili(float(output.size())/columns)*cell_size+16))
	queue_redraw()

func cell_rect(index: int) -> Rect2:
	if viewing_mapping == PHRASE_MAPPING:
		return Rect2(PHRASE_LEFT+(index%columns)*cell_size,(index/columns)*PHRASE_HEIGHT+32,cell_size-2,132)
	return Rect2(8+(index%columns)*cell_size,8+(index/columns)*cell_size,cell_size-3,cell_size-3)

func phrase_point(index: int) -> Vector2:
	# A fixed lane encodes the saved symbol, never a model prediction or time cost.
	return Vector2(cell_rect(index).get_center().x,(index/columns)*PHRASE_HEIGHT+LANE_TOP+clampi(int(output[index]),0,3)*LANE_PITCH)

func index_at_position(point: Vector2) -> int:
	var origin := Vector2(PHRASE_LEFT,0) if viewing_mapping == PHRASE_MAPPING else Vector2(8,8)
	var local: Vector2 = point-origin
	if local.x < 0 or local.y < 0: return -1
	var column: int = int(local.x/cell_size)
	var row_height: float = PHRASE_HEIGHT if viewing_mapping == PHRASE_MAPPING else cell_size
	var index: int = int(local.y/row_height)*columns+column
	if column >= columns or index >= output.size() or not cell_rect(index).has_point(point): return -1
	return index

func draw_symbol(center: Vector2, radius: float, value: int, color: Color) -> void:
	match value:
		0: draw_circle(center,radius,color)
		1: draw_rect(Rect2(center-Vector2(radius,radius),Vector2.ONE*radius*2),color)
		2: draw_colored_polygon(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,radius),center+Vector2(-radius,radius)]),color)
		3: draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]),color,1.5,true)

func draw_phrases(font: Font) -> void:
	var phrase_count: int = ceili(float(output.size())/columns)
	var ink := Color("ccd4de")
	var panel: StyleBoxFlat = phrase_panel()
	for phrase: int in phrase_count:
		var top: float = phrase*PHRASE_HEIGHT
		var start: int = phrase*columns
		var end: int = mini(start+columns,output.size())
		var right: float = PHRASE_LEFT+columns*cell_size
		draw_style_box(panel,Rect2(8,top+8,size.x-16,160))
		draw_string(font,Vector2(PHRASE_LEFT,top+25),"%d — %d"%[start+1,end],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(ink,0.55))
		for lane: int in 4:
			var y: float = top+LANE_TOP+lane*LANE_PITCH
			draw_string(font,Vector2(18,y+4),["A","B","C","D"][lane],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(COLORS[lane],0.65))
			draw_line(Vector2(PHRASE_LEFT,y),Vector2(right-3,y),Color(COLORS[lane],0.08),1.0,true)
		for index: int in range(start,end):
			var rect: Rect2 = cell_rect(index)
			var center: Vector2 = phrase_point(index)
			var color: Color = COLORS[clampi(int(output[index]),0,3)]
			var lit: bool = revealed < 0 or index < revealed
			if selected == index:
				draw_rect(rect,Color(ink,0.06),true)
				draw_rect(rect,Color(ink,0.40),false,1)
			if index > start:
				var before: Vector2 = phrase_point(index-1)
				if lit:
					# Adjacent saved symbols supply both endpoints; no invented samples.
					draw_line(before,center,Color(color,0.06),6.0,true)
					draw_line(before,center,Color(color,0.48),1.5,true)
			if lit:
				var recent: bool = revealed >= 0 and revealed-index <= 4
				draw_circle(center,10 if recent else 8,Color(color,0.10 if recent else 0.05))
				draw_symbol(center,4.5,int(output[index]),Color(color,0.95))
			else:
				draw_circle(center,1.5,Color(color,0.20))
			if selected == index: draw_arc(center,9,0,TAU,24,ink,1.3,true)
			var caption: String = str(index+1)
			var number_width: float = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x
			draw_string(font,Vector2(rect.get_center().x-number_width/2,top+157),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color(ink,0.90 if selected == index else 0.42))
		# A phrase break is a viewing fold, not a gap in the output sequence.
		if end < output.size(): draw_string(font,Vector2(right-14,top+25),"↳",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(ink,0.55))

func phrase_panel() -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("151b24")
	panel.corner_radius_top_left = 8
	panel.corner_radius_top_right = 8
	panel.corner_radius_bottom_left = 8
	panel.corner_radius_bottom_right = 8
	return panel

func _draw() -> void:
	var font: Font = get_theme_default_font()
	if viewing_mapping == PHRASE_MAPPING:
		draw_phrases(font)
		return
	for index: int in output.size():
		var rect: Rect2 = cell_rect(index)
		var value: int = int(output[index])
		var color: Color = COLORS[clampi(value,0,3)]
		var lit: bool = revealed < 0 or index < revealed
		if not lit: color = color.darkened(0.86)
		draw_rect(rect,color.darkened(0.80),true)
		if viewing_mapping == TRACE_MAPPING and lit:
			draw_circle(rect.get_center(),minf(12,cell_size*0.32),Color(color,0.07))
			if index > 0 and index % columns != 0:
				draw_line(cell_rect(index-1).get_center(),rect.get_center(),Color(color,0.18),1.0,true)
		var center: Vector2 = rect.position+rect.size*Vector2(0.35,0.5)
		var radius: float = minf(6,cell_size*0.17)
		draw_symbol(center,radius,value,color)
		if cell_size >= 28:
			draw_string(font,rect.position+Vector2(cell_size*0.62,cell_size*0.62),["A","B","C","D"][clampi(value,0,3)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
		if selected == index: draw_rect(rect,Color("e9f0fa"),false,2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index: int = index_at_position(event.position)
		if index >= 0:
			selected = index
			cell_selected.emit(index)
			queue_redraw()
			accept_event()
