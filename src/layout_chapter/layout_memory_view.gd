extends Control
## Every colored cell is an authoritative mapping entry, not a schematic score.
const COLORS := [Color("67e8a5"),Color("50d5ff"),Color("ffbf69"),Color("bc8cff")]
const NAMES := ["温度","编号","电量","告警"]
const EN_NAMES := ["Temp","ID","Battery","Alarm"]
var mapping: Dictionary = {}
var records: Array = []
var selected_address: int = -1
var selected_record: int = -1
var selected_field: int = -1
var title: String = ""
func configure(map: Dictionary, data: Array, caption: String) -> void:
	mapping = map; records = data; title = caption
	custom_minimum_size = Vector2(510,100+ceilf(float(map.get("bytes",0))/16)*66)
	queue_redraw()
func highlight(event: SimulationEvent) -> void:
	selected_address = event.address
	selected_record = int(event.details.get("record",-1))
	selected_field = int(event.details.get("field",-1))
	queue_redraw()
func _draw() -> void:
	var font: Font = get_theme_default_font()
	draw_string(font,Vector2(12,26),title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("dceaf3"))
	var chinese: bool = TranslationServer.get_locale().begins_with("zh")
	draw_string(font,Vector2(12,53),"每格 4 B · 每行 16 B · 空白格是对齐空间" if chinese else "4 B / cell · 16 B / line · blank = padding",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("9aadc1"))
	var base: int = int(mapping.get("base",0))
	for row: int in range(ceili(float(mapping.get("bytes",0))/16)):
		var y: float = 75+row*66
		draw_rect(Rect2(72,y,424,60),Color("172638"))
		draw_string(font,Vector2(4,y+35),str(base+row*16),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("9aadc1"))
	for cell: Dictionary in mapping.get("cells",[]):
		var local_address: int = int(cell.address)-base
		var at := Vector2(76+(local_address%16)/4*106,79+int(local_address/16)*66)
		var f: int = int(cell.field)
		var r: int = int(cell.record)+int(mapping.get("first_record",0))
		var color: Color = COLORS[f]
		draw_rect(Rect2(at,Vector2(98,52)),Color(color,0.15))
		draw_rect(Rect2(at,Vector2(3,52)),color)
		if int(cell.address) == selected_address or (r == selected_record and f == selected_field): draw_rect(Rect2(at,Vector2(98,52)),color,false,2)
		draw_string(font,at+Vector2(8,22),(NAMES if chinese else EN_NAMES)[f]+str(r),HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
		if r<records.size(): draw_string(font,at+Vector2(8,44),str(records[r][f]),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e7f0f6"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var row: int = floori((event.position.y-75)/66)
		var column: int = floori((event.position.x-72)/106)
		if row<0 or column not in range(4): return
		var address: int = int(mapping.get("base",0))+row*16+column*4
		for cell: Dictionary in mapping.get("cells",[]):
			if int(cell.address) == address:
				selected_address = address; selected_record = int(cell.record)+int(mapping.get("first_record",0)); selected_field = int(cell.field)
				tooltip_text = "%s #%d = %d · %d B" % [NAMES[selected_field],selected_record,records[selected_record][selected_field],address]
				queue_redraw()
