extends Control
## The saved output only. All cells remain available in a vertical scroll surface.
signal cell_selected(index: int)
const COLORS := [Color("6ce2de"),Color("eead67"),Color("bcacf0"),Color("8cd793")]
var output: Array = []
var selected: int = -1
var columns: int = 16
var cell_size: float = 36
const TRACE_MAPPING: String = "light-trace-v1"
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
	columns = 16 if viewing_mapping == TRACE_MAPPING else maxi(4,mini(32,int(maxf(144,size.x-16)/36)))
	cell_size = maxf(16,(size.x-16)/columns)
	custom_minimum_size = Vector2(160,maxf(90,ceili(float(output.size())/columns)*cell_size+16))
	queue_redraw()

func cell_rect(index: int) -> Rect2:
	return Rect2(8+(index%columns)*cell_size,8+(index/columns)*cell_size,cell_size-3,cell_size-3)

func _draw() -> void:
	var font: Font = get_theme_default_font()
	for index: int in output.size():
		var rect: Rect2 = cell_rect(index)
		var value: int = int(output[index])
		var color: Color = COLORS[clampi(value,0,3)]
		var lit: bool = revealed < 0 or index < revealed
		if not lit: color = color.darkened(0.86)
		if viewing_mapping == TRACE_MAPPING and lit:
			draw_circle(rect.get_center(),minf(12,cell_size*0.32),Color(color,0.07))
			if index > 0 and index % columns != 0:
				draw_line(cell_rect(index-1).get_center(),rect.get_center(),Color(color,0.18),1.0,true)
		draw_rect(rect,color.darkened(0.80),true)
		var center: Vector2 = rect.position+rect.size*Vector2(0.35,0.5)
		var radius: float = minf(6,cell_size*0.17)
		match value:
			0: draw_circle(center,radius,color)
			1: draw_rect(Rect2(center-Vector2(radius,radius),Vector2.ONE*radius*2),color)
			2: draw_colored_polygon(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,radius),center+Vector2(-radius,radius)]),color)
			3: draw_polyline(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]),color,1.5,true)
		if cell_size >= 28:
			draw_string(font,rect.position+Vector2(cell_size*0.62,cell_size*0.62),["A","B","C","D"][clampi(value,0,3)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
		if selected == index: draw_rect(rect,Color("e9f0fa"),false,2)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = event.position-Vector2(8,8)
		if local.x<0 or local.y<0: return
		var column: int = int(local.x/cell_size)
		var index: int = int(local.y/cell_size)*columns+column
		if column<columns and index<output.size() and cell_rect(index).has_point(event.position):
			selected = index
			cell_selected.emit(index)
			queue_redraw()
			accept_event()
