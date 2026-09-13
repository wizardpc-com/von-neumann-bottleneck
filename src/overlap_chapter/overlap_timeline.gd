class_name OverlapTimeline
extends Control
var trace: SimulationTrace
var selected_cycle: int = -1
func _ready() -> void:
	custom_minimum_size = Vector2(700, 160)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
func _draw() -> void:
	if trace == null: return
	var font: Font = get_theme_default_font()
	var elapsed: int = int(trace.metrics.total_cycles)
	var total: int = maxi(1, elapsed)
	var left: float = 122
	var usable: float = maxf(100, size.x - left - 20)
	draw_string(font,Vector2(0,20),Localization.text(&"overlap.cycles_axis"),HORIZONTAL_ALIGNMENT_LEFT,left-8,14,Color("91a0b9"))
	for lane: int in range(2):
		var y: float = 36 + lane * 56
		draw_string(font, Vector2(0,y + 20), Localization.text(&"overlap.transfer" if lane == 0 else &"overlap.compute"), HORIZONTAL_ALIGNMENT_LEFT, 116, 17, Color("d8e7f2"))
		draw_rect(Rect2(left,y,usable,32),Color("112431"))
	for event: SimulationEvent in trace.events:
		if event.kind not in [&"transfer", &"compute"]: continue
		# An issued operation can extend beyond a failed run's stopping cycle.
		var end_cycle: int = mini(event.cycle + event.duration, int(trace.metrics.total_cycles))
		if end_cycle <= event.cycle: continue
		var lane: int = 0 if event.kind == &"transfer" else 1
		var x: float = left + usable * float(event.cycle) / total
		var width: float = usable * float(end_cycle - event.cycle) / total
		var color := Color("50d5ff") if lane == 0 else Color("ba92ff")
		draw_rect(Rect2(x,36+lane*56,maxf(1,width-1),32),Color(color,0.7))
		var batch: int = int(event.details.get("batch", -1))
		var caption: String = "#"+str(batch) if batch >= 0 else Localization.text(&"overlap.timeline.work")
		if font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x <= width-10:
			draw_string(font,Vector2(roundf(x+5),58+lane*56),caption,HORIZONTAL_ALIGNMENT_LEFT,width-8,17,Color.WHITE)
	var mark_count: int = mini(4, elapsed)
	for mark: int in range(mark_count + 1):
		var at: float = float(mark)/maxi(1,mark_count)
		var text: String = str(roundi(elapsed*at))
		var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var x: float = clampf(left+usable*at-width*0.5,left,size.x-width)
		draw_string(font,Vector2(roundf(x),20),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("91a0b9"))
	if selected_cycle >= 0:
		var x: float = left + usable * clampf(float(selected_cycle)/total,0,1)
		draw_line(Vector2(x,28),Vector2(x,130),Color("ffbf69"),2)
