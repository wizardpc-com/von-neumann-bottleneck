extends Control
## A view of authored bytes and draft partitions, never simulation authority.
signal block_selected(index: int)
var values: Array[int] = []
var partitions: Array[Dictionary] = []
var selected: int = 0
var hovered: int = -1
const LEFT: float = 32.0
const TOP: float = 4.0
const CELL_HEIGHT: float = 30.0

func _init() -> void:
	custom_minimum_size = Vector2(0,128)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	mouse_exited.connect(func() -> void: hovered = -1; queue_redraw())

func configure(data: Array[int], plan: Array[Dictionary], selected_block: int) -> void:
	values = data.duplicate()
	partitions = plan.duplicate(true)
	selected = selected_block
	queue_redraw()

func cell_rect(address: int) -> Rect2:
	var width: float = maxf(1.0,(size.x-LEFT-4.0)/16.0)
	return Rect2(LEFT+(address%16)*width,TOP+(address/16)*CELL_HEIGHT,width-2.0,CELL_HEIGHT-3.0)

func block_at(address: int) -> int:
	for i: int in partitions.size():
		if address >= int(partitions[i].start) and address < int(partitions[i].end): return i
	return -1

func address_at(position: Vector2) -> int:
	for i: int in mini(64,values.size()):
		if cell_rect(i).has_point(position): return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var address: int = address_at(event.position)
		if address != hovered:
			hovered = address
			tooltip_text = "[%d] = %d" % [address,values[address]] if address >= 0 else ""
			queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var index: int = block_at(address_at(event.position))
		if index >= 0:
			grab_focus(); block_selected.emit(index); accept_event()
	if event is InputEventKey and event.pressed and not partitions.is_empty():
		if event.is_action("ui_left") or event.is_action("ui_right"):
			var delta: int = -1 if event.is_action("ui_left") else 1
			block_selected.emit(clampi(selected+delta,0,partitions.size()-1)); accept_event()

func _draw() -> void:
	var font: Font = get_theme_font("font","Label")
	for row: int in 4:
		draw_string(font,Vector2(0,TOP+row*CELL_HEIGHT+20),"%02d" % [row*16],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("8ba3b4"))
	for address: int in mini(64,values.size()):
		var rect: Rect2 = cell_rect(address)
		var index: int = block_at(address)
		var value_color := Color.from_hsv(fmod(float(values[address])*0.618034,1.0),0.34,0.33)
		draw_rect(rect,value_color)
		var edge := Color("50d5ff")
		if index >= 0 and partitions[index].codec == "rle": edge = Color("62dca7")
		draw_line(rect.position,rect.position+Vector2(rect.size.x,0),edge,2.0)
		if index == selected: draw_rect(rect,Color(edge,0.6),false,1.0)
		if address == hovered: draw_rect(rect,Color.WHITE,false,2.0)
		draw_string(font,rect.position+Vector2(0,20),str(values[address]),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,14,Color("eef4f8"))
	if has_focus(): draw_rect(Rect2(Vector2.ZERO,size),Color("50d5ff"),false,1.0)
