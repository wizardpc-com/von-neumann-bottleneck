extends Control
## Two measured receipts, one common cycle scale; presentation only.
var samples: Array[Dictionary] = []
var captions: PackedStringArray = []
var legend: String = ""
const COMPUTE := Color("50d5ff")
const WAIT := Color("ffbf69")

func _init() -> void:
	custom_minimum_size.y = 144
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func configure(before: Dictionary, after: Dictionary, translate: Callable) -> void:
	samples.clear()
	captions = PackedStringArray([translate.call(&"system.history.chart.before"),translate.call(&"system.history.chart.after")])
	legend = "%s  /  %s" % [translate.call(&"system.profiler.name.cpu_compute_cycles"),translate.call(&"system.profiler.name.cpu_wait_cycles")]
	for metrics: Dictionary in [before,after]:
		for key: String in ["total_cycles","cpu_compute_cycles","cpu_wait_cycles"]:
			var value: Variant = metrics.get(key)
			if not value is int or value < 0:
				samples.clear(); hide(); queue_redraw(); return
		if metrics.total_cycles <= 0 or metrics.cpu_compute_cycles + metrics.cpu_wait_cycles != metrics.total_cycles:
			samples.clear(); hide(); queue_redraw(); return
		samples.append(metrics.duplicate(true))
	show(); queue_redraw()

func _draw() -> void:
	if samples.size() != 2: return
	var font: Font = get_theme_font("font","Label")
	var scale: float = maxf(samples[0].total_cycles,samples[1].total_cycles)
	var span: float = maxf(1,size.x-84)
	draw_string(font,Vector2(0,17),legend.split("  /  ")[0],HORIZONTAL_ALIGNMENT_LEFT,size.x/2,14,COMPUTE)
	draw_string(font,Vector2(size.x/2,17),legend.split("  /  ")[1],HORIZONTAL_ALIGNMENT_LEFT,size.x/2,14,WAIT)
	for index: int in 2:
		var item: Dictionary = samples[index]
		var y: float = 46+index*53
		draw_string(font,Vector2(0,y-6),captions[index],HORIZONTAL_ALIGNMENT_LEFT,size.x,13,Color("91a0b9"))
		draw_rect(Rect2(0,y,span,18),Color("071821"))
		var compute_width: float = span*item.cpu_compute_cycles/scale
		var wait_width: float = span*item.cpu_wait_cycles/scale
		draw_rect(Rect2(0,y,compute_width,18),COMPUTE)
		draw_rect(Rect2(compute_width,y,wait_width,18),WAIT)
		draw_string(font,Vector2(span+8,y+15),str(item.total_cycles),HORIZONTAL_ALIGNMENT_LEFT,76,14,Color("e9f0fa"))
