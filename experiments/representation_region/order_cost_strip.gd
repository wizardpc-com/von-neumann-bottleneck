extends Control
## Read-only drawing of selected trace metrics. Never evaluates a draft or a goal.
var measurements: Array[Dictionary] = []
var english: bool = false
var selected_order: int = -1

func _init() -> void:
	custom_minimum_size = Vector2(430,140)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)

func configure(rows: Array[Dictionary], en: bool, current: int = -1) -> void:
	measurements.assign(rows.duplicate(true))
	english = en; selected_order = current
	queue_redraw()

func _draw() -> void:
	var font: Font = get_theme_font("font","Label")
	var ink := Color("dfebf2")
	var muted := Color("a9c1cf")
	var background: StyleBoxFlat = InstrumentTheme.panel(Color("102330"),Color("2d5266"))
	draw_style_box(background,Rect2(Vector2.ZERO,size))
	if measurements.is_empty():
		draw_string(font,Vector2(12,32),"No measured costs yet" if english else "尚无实测成本",HORIZONTAL_ALIGNMENT_LEFT,size.x-24,14,ink)
		draw_string(font,Vector2(12,60),"Run the draft to reveal preparation and service." if english else "运行草稿，才会显示准备与服务成本。",HORIZONTAL_ALIGNMENT_LEFT,size.x-24,14,muted)
		return
	var row_height: float = size.y / float(measurements.size())
	for index: int in measurements.size():
		var row: Dictionary = measurements[index]
		var m: Dictionary = row.metrics
		var top: float = index * row_height
		if index == selected_order:
			draw_rect(Rect2(1,top+1,size.x-2,row_height-2),Color("173344"))
		var badge: String = ("Met" if english else "达标") if row.met else ("Unmet" if english else "未达标")
		var heading: String = "%s · %s" % [row.name,badge]
		draw_string(font,Vector2(10,top+20),heading,HORIZONTAL_ALIGNMENT_LEFT,size.x-20,14,Color("62dca7") if row.met else Color("f2ba70"))
		var bytes: String = ("Stored %dB · service traffic %dB" if english else "空间%dB · 服务搬运%dB") % [m.stored_bytes,m.traffic_bytes]
		draw_string(font,Vector2(10,top+60),bytes,HORIZONTAL_ALIGNMENT_LEFT,size.x-20,14,muted)
		var equation: String = ("Prepare %d + serve %d = %d cycles" if english else "准备%d + 服务%d = 总计%d周期") % [m.preparation_cycles,m.service_cycles,m.total_cycles]
		draw_string(font,Vector2(10,top+40),equation,HORIZONTAL_ALIGNMENT_LEFT,size.x-20,14,ink)
		var width: float = size.x-20
		var total: int = int(m.total_cycles)
		var preparation_width: float = width * float(m.preparation_cycles) / float(total) if total > 0 else 0.0
		draw_rect(Rect2(10,top+66,width,3),Color("223745"))
		draw_rect(Rect2(10,top+66,preparation_width,3),Color("b29beb"))
		if total > 0: draw_rect(Rect2(10+preparation_width,top+66,width-preparation_width,3),Color("51cbd4"))
