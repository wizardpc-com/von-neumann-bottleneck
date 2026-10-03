extends Control
## Read-only view of measured first responses; not a scheduler or live clock.
var first_responses: Array[int] = []
var deadline: int = 0
var english: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(0,142)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func configure(values: Array, limit: int, use_english: bool) -> void:
	first_responses.clear(); deadline = maxi(0,limit); english = use_english
	if values.size() == 4:
		for value: Variant in values:
			if not (value is int or value is float) or float(value) <= 0 or not is_finite(float(value)) or float(value) != floor(float(value)):
				first_responses.clear(); queue_redraw(); return
			first_responses.append(int(value))
	queue_redraw()

func scale_cycles() -> int:
	var result: int = maxi(1,deadline)
	for value: int in first_responses: result = maxi(result,value)
	return result

func exceeds(index: int) -> bool:
	return index >= 0 and index < first_responses.size() and deadline > 0 and first_responses[index] > deadline

func _draw() -> void:
	var font: Font = get_theme_font("font","Label")
	var title: String = "Measured first response · cycles" if english else "实测首次响应 · 周期"
	title += (" · current limit ≤%d" if english else " · 当前任务上限≤%d") % deadline if deadline > 0 else (" · no first-response limit in this task" if english else " · 本任务未限制首响应")
	draw_string(font,Vector2(4,18),title,HORIZONTAL_ALIGNMENT_LEFT,size.x-8,14,Color("dfeaf2"))
	if first_responses.size() != 4:
		draw_string(font,Vector2(4,55),"Run a valid plan to compare when each stream first responds." if english else "有效运行后，可比较每条流何时拿到第一次结果。",HORIZONTAL_ALIGNMENT_LEFT,size.x-8,13,Color("90a7b7"))
		return
	var width: float = maxf(1,size.x-116)
	var scale: float = float(scale_cycles())
	for i: int in 4:
		var y: float = 29+i*25
		var rect := Rect2(34,y,width,18)
		draw_string(font,Vector2(5,y+14),char(65+i),HORIZONTAL_ALIGNMENT_LEFT,24,14,Color("dfeaf2"))
		draw_rect(rect,Color("142633"))
		var fill := Rect2(rect.position,Vector2(width*first_responses[i]/scale,18))
		draw_rect(fill,Color("dba458") if exceeds(i) else Color("438ca5"))
		draw_string(font,Vector2(rect.end.x+8,y+14),str(first_responses[i]),HORIZONTAL_ALIGNMENT_LEFT,70,13,Color("eef4f8"))
	if deadline > 0:
		var x: float = 34+width*deadline/scale
		draw_line(Vector2(x,26),Vector2(x,125),Color("f3c777"),1.5)
	var footer: String = ("Measured from cycle 0; the line is the current task's limit." if english else "从周期0计时；竖线仅表示当前任务的首响应上限。") if deadline > 0 else ("Bar lengths are recorded elapsed cycles, not a live timer." if english else "柱长表示实测周期，不是运行中的计时器。")
	draw_string(font,Vector2(34,140),footer,HORIZONTAL_ALIGNMENT_LEFT,size.x-38,11,Color("90a7b7"))
