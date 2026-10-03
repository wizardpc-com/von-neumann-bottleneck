extends Control
## Two measured plans, separate units. Never computes a score or chooses a winner.
var rows: Array[Dictionary] = []
var english: bool = false
const MUTED := Color("71899b")
const CURRENT := Color("50d5ff")
const MORE := Color("efb66c")

func _init() -> void:
	custom_minimum_size = Vector2(0,246)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func configure(baseline: Dictionary, measured: Dictionary, use_english: bool) -> void:
	english = use_english; rows.clear()
	if baseline.is_empty() or measured.is_empty(): queue_redraw(); return
	if not str(baseline.get("error","invalid")).is_empty() or not str(measured.get("error","invalid")).is_empty(): queue_redraw(); return
	var keys: Array[String] = ["total_cycles","state_read_bytes","state_write_bytes","peak_bytes","all_streams_first_cycle"]
	for data: Dictionary in [baseline,measured]:
		for key: String in keys:
			var value: Variant = data.get(key)
			if not (value is int or value is float) or not is_finite(value) or value < 0: queue_redraw(); return
	var names: Array = ["Total cycles","State traffic · B","Peak memory · B","Latest first response"] if english else ["总周期","状态读写 · B","峰值空间 · B","最晚首响应周期"]
	var a: Array = [baseline.total_cycles,baseline.state_read_bytes+baseline.state_write_bytes,baseline.peak_bytes,baseline.all_streams_first_cycle]
	var b: Array = [measured.total_cycles,measured.state_read_bytes+measured.state_write_bytes,measured.peak_bytes,measured.all_streams_first_cycle]
	for i: int in 4: rows.append({"name":names[i],"baseline":int(a[i]),"current":int(b[i])})
	queue_redraw()

func _draw() -> void:
	if rows.size() != 4: return
	var font: Font = get_theme_font("font","Label")
	var width: float = (size.x-12)/2.0
	for i: int in 4:
		var r := Rect2(Vector2((i%2)*(width+12),(i/2)*117),Vector2(width,107))
		var box := StyleBoxFlat.new(); box.bg_color = Color("102431")
		box.border_color = Color("294454"); box.set_border_width_all(1); box.set_corner_radius_all(8)
		draw_style_box(box,r)
		var item: Dictionary = rows[i]
		draw_string(font,r.position+Vector2(12,21),item.name,HORIZONTAL_ALIGNMENT_LEFT,width-24,14,Color("e4eff5"))
		var span: float = maxf(1,width-105)
		var scale: float = maxf(1,maxi(item.baseline,item.current))
		for index: int in 2:
			var value: int = item.baseline if index == 0 else item.current
			var y: float = r.position.y+34+index*23
			var color: Color = MUTED if index == 0 else (MORE if item.current > item.baseline else CURRENT)
			draw_rect(Rect2(r.position.x+12,y,span,12),Color("071821"))
			draw_rect(Rect2(r.position.x+12,y,span*value/scale,12),color)
			draw_string(font,Vector2(r.position.x+span+20,y+11),str(value),HORIZONTAL_ALIGNMENT_LEFT,72,13,Color("dbe8ef"))
		var diff: int = item.current-item.baseline
		draw_string(font,r.position+Vector2(12,94),("Current − pinned: %+d" if english else "当前 − 对照：%+d") % diff,HORIZONTAL_ALIGNMENT_LEFT,width-24,13,MORE if diff > 0 else CURRENT)
	draw_string(font,Vector2(4,243),"Top grey = pinned; bottom = current. Separate scales; compare quality too." if english else "上灰条＝对照，下条＝当前；各指标独立刻度，还需一起看精度。",HORIZONTAL_ALIGNMENT_LEFT,size.x-8,12,Color("9bb2c1"))
