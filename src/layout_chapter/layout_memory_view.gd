extends Control
## Every colored cell is an authoritative mapping entry, not a schematic score.
const COLORS := [Color("67e8a5"),Color("50d5ff"),Color("ffbf69"),Color("bc8cff")]
const NAMES := ["温度","编号","电量","告警"]
const EN_NAMES := ["Temp","ID","Battery","Alarm"]
const ROW_HEIGHT: float = 90.0
const CELL_HEIGHT: float = 78.0
var mapping: Dictionary = {}
var records: Array = []
var selected_address: int = -1
var selected_record: int = -1
var selected_field: int = -1
var title: String = ""
var _heading: Label
var _legend: Label
var _grid_top: float = 100.0

func _ready() -> void:
	_heading = _text_label(20,Color("dceaf3"))
	_legend = _text_label(16,Color("9aadc1"))
	resized.connect(_layout_text)
	_heading.minimum_size_changed.connect(_layout_text)
	_legend.minimum_size_changed.connect(_layout_text)
	_layout_text()

func _text_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	add_child(label)
	return label

func configure(map: Dictionary, data: Array, caption: String) -> void:
	mapping = map; records = data; title = caption
	_layout_text()

func _layout_text() -> void:
	if not is_instance_valid(_heading): return
	_heading.text = title
	_legend.text = Localization.text(&"layout.memory.legend")
	_heading.position = Vector2(12,8)
	_heading.size = Vector2(maxf(486,size.x-24),0)
	_legend.position = Vector2(12,_heading.position.y+_heading.get_minimum_size().y+6)
	_legend.size = Vector2(maxf(486,size.x-24),0)
	_grid_top = ceilf(_legend.position.y+_legend.get_minimum_size().y+16)
	custom_minimum_size = Vector2(510,_grid_top+ceilf(float(mapping.get("bytes",0))/16)*ROW_HEIGHT+8)
	queue_redraw()

func highlight(event: SimulationEvent) -> void:
	selected_address = event.address
	selected_record = int(event.details.get("record",-1))
	selected_field = int(event.details.get("field",-1))
	queue_redraw()

func _column_width() -> float:
	return floorf((maxf(size.x,510)-86)/4)

func cell_rect(address: int) -> Rect2:
	var offset: int = address-int(mapping.get("base",0))
	return Rect2(Vector2(76+(offset%16)/4*_column_width(),_grid_top+4+int(offset/16)*ROW_HEIGHT),Vector2(_column_width()-8,CELL_HEIGHT))

func _draw() -> void:
	var font: Font = get_theme_default_font()
	var chinese: bool = TranslationServer.get_locale().begins_with("zh")
	var base: int = int(mapping.get("base",0))
	for row: int in range(ceili(float(mapping.get("bytes",0))/16)):
		var y: float = _grid_top+row*ROW_HEIGHT
		draw_rect(Rect2(72,y,4*_column_width(),CELL_HEIGHT+8),Color("172638"))
		draw_string(font,Vector2(4,y+46),str(base+row*16),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("9aadc1"))
	for cell: Dictionary in mapping.get("cells",[]):
		var rect: Rect2 = cell_rect(int(cell.address))
		var at: Vector2 = rect.position
		var f: int = int(cell.field)
		var r: int = int(cell.record)+int(mapping.get("first_record",0))
		var color: Color = COLORS[f]
		draw_rect(rect,Color(color,0.15))
		draw_rect(Rect2(at,Vector2(3,CELL_HEIGHT)),color)
		if int(cell.address) == selected_address or (r == selected_record and f == selected_field): draw_rect(rect,color,false,2)
		# Field, source record and value remain distinct even for double-digit records.
		draw_string(font,at+Vector2(8,22),(NAMES if chinese else EN_NAMES)[f],HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
		draw_string(font,at+Vector2(8,43),"#"+str(r),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("9aadc1"))
		if r<records.size(): draw_string(font,at+Vector2(8,67),str(records[r][f]),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e7f0f6"))

func _cell_at(point: Vector2) -> Dictionary:
	for cell: Dictionary in mapping.get("cells",[]):
		if cell_rect(int(cell.address)).has_point(point): return cell
	return {}

func _get_tooltip(at_position: Vector2) -> String:
	var cell: Dictionary = _cell_at(at_position)
	if cell.is_empty(): return ""
	var record: int = int(cell.record)+int(mapping.get("first_record",0))
	var field: int = int(cell.field)
	var chinese: bool = TranslationServer.get_locale().begins_with("zh")
	return Localization.text(&"layout.memory.cell_tooltip",[(NAMES if chinese else EN_NAMES)[field],record,int(records[record][field]),int(cell.address)])

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell: Dictionary = _cell_at(event.position)
		if cell.is_empty(): return
		selected_address = int(cell.address)
		selected_record = int(cell.record)+int(mapping.get("first_record",0))
		selected_field = int(cell.field)
		queue_redraw()
