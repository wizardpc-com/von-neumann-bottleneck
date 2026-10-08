extends Control
## Displays supplied snapshots only. Presentation playback never runs the model.
signal cell_selected(index: int)
const COLORS := [Color("6ce2de"),Color("eead67"),Color("bcacf0"),Color("8cd793")]
var lanes: Array = [[],[],[]]
var captions: Array = ["", "", ""]
var corrections: Array = []
var selected: int = -1
var cursor: int = -1
var page: int = 0
var english: bool = false
var _cells: Array[Dictionary] = []

func _ready() -> void:
	custom_minimum_size = Vector2(400,216)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func set_tracks(values: Array, titles: Array, marks: Array = []) -> void:
	lanes = values.duplicate(true)
	captions = titles.duplicate()
	corrections = marks.duplicate()
	selected = -1
	cursor = -1
	page = 0
	queue_redraw()

func output_length() -> int:
	var result: int = 0
	for lane: Array in lanes: result = maxi(result,lane.size())
	return result

func _draw() -> void:
	_cells.clear()
	var font: Font = get_theme_default_font()
	var columns: int = maxi(8,mini(24,int((size.x - 18) / 28)))
	var count: int = columns * 2
	var start: int = page * count
	var width: float = (size.x - 20) / columns
	var lane_height: float = (size.y - 24) / 3
	for lane_index: int in 3:
		var y: float = lane_index * lane_height
		draw_string(font,Vector2(8,y+15),str(captions[lane_index]),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("a9bbc9"))
		var values: Array = lanes[lane_index]
		for i: int in range(start,mini(start+count,values.size())):
			var local: int = i-start
			var rect := Rect2(10+(local%columns)*width,y+23+(local/columns)*23,width-3,20)
			var value: int = int(values[i])
			var active: bool = cursor < 0 or i <= cursor
			var color: Color = COLORS[clampi(value,0,3)] if value >= 0 else Color("536674")
			if not active: color = color.darkened(0.6)
			draw_rect(rect,Color("112432"),true)
			if i == selected or i == cursor: draw_rect(rect,Color("e9f0fa"),false,1.5)
			var center: Vector2 = rect.position+Vector2(9,10)
			match value:
				0: draw_circle(center,4,color)
				1: draw_rect(Rect2(center-Vector2(4,4),Vector2(8,8)),color)
				2: draw_colored_polygon(PackedVector2Array([center+Vector2(0,-5),center+Vector2(5,4),center+Vector2(-5,4)]),color)
				3: draw_polyline(PackedVector2Array([center+Vector2(0,-5),center+Vector2(5,0),center+Vector2(0,5),center+Vector2(-5,0),center+Vector2(0,-5)]),color,1.8,true)
				_: draw_line(center-Vector2(4,0),center+Vector2(4,0),color,1.5)
			draw_string(font,rect.position+Vector2(17,14),["A","B","C","D"][value] if value >= 0 and value < 4 else "?",HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
			if lane_index == 2 and i in corrections:
				draw_line(rect.position+Vector2(2,18),rect.position+Vector2(width-5,18),Color("eead67"),2)
			_cells.append({"rect":rect,"index":i})
	var last: int = mini(start+count,output_length())
	draw_string(font,Vector2(10,size.y-5),"%d–%d / %d · %s"%[start+1,last,output_length(),"shapes + letters; playback ≠ cycles" if english else "图形＋字母；播放速度≠模拟周期"],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("91a0b9"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for cell: Dictionary in _cells:
			if cell.rect.has_point(event.position):
				selected = int(cell.index)
				cell_selected.emit(selected)
				queue_redraw()
				accept_event()
				return

func turn_page(direction: int) -> void:
	var columns: int = maxi(8,mini(24,int((size.x-18)/28)))
	page = clampi(page+direction,0,maxi(0,ceili(float(output_length())/(columns*2))-1))
	queue_redraw()
