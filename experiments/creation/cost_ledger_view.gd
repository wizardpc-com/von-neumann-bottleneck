extends Control
## Static, linear measured bars. No wall-clock progress or estimated simulation.
const Ledger = preload("res://experiments/creation/cost_ledger.gd")
const COLORS := {"encode":Color("eead67"),"transfer":Color("6ce2de"),"decode":Color("bcacf0"),"output":Color("8cd793")}
var snapshot: Dictionary = {}
var english: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(320,210)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func show_snapshot(value: Dictionary, use_english: bool) -> void:
	snapshot = value.duplicate(true)
	english = use_english
	queue_redraw()

func bar_geometry(codec: String, metric: String, available: float) -> Array:
	var result: Dictionary = snapshot.get("results",{}).get(codec,{})
	if not result.get("ok",false): return []
	var maximum: int = maxi(Ledger.total(snapshot,"raw",metric),Ledger.total(snapshot,"predictive",metric))
	if maximum <= 0: return []
	var pieces: Array = Ledger.cycle_segments(snapshot,codec) if metric == "total_cycles" else [{"phase":"packet","value":Ledger.total(snapshot,codec,metric)}]
	var offset: float = 0
	for piece: Dictionary in pieces:
		piece["x"] = offset
		piece["width"] = maxf(0,available)*int(piece.value)/float(maximum)
		offset += float(piece.width)
	return pieces

func _draw() -> void:
	if snapshot.is_empty(): return
	var font: Font = get_theme_default_font()
	var left: float = 88
	var width: float = maxf(0,size.x-left-95)
	for metric_index: int in 2:
		var metric: String = "total_cycles" if metric_index == 0 else "packet_bytes"
		var y: float = 18+metric_index*91
		var title: String = ("Sequential cycles" if english else "顺序周期") if metric_index == 0 else ("Actual packet bytes (separate scale)" if english else "实际包字节（独立标尺）")
		draw_string(font,Vector2(0,y),title,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("dce6ef"))
		for row: int in 2:
			var codec: String = Ledger.CODECS[row]
			var top: float = y+10+row*27
			draw_string(font,Vector2(0,top+14),"RAW" if row == 0 else ("Predictive" if english else "预测包"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("a9bbc9"))
			var result: Dictionary = snapshot.results[codec]
			if not result.ok:
				draw_string(font,Vector2(left,top+14),"not completed" if english else "未完成",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("eead67"))
				continue
			draw_rect(Rect2(left,top,width,18),Color("112432"))
			for piece: Dictionary in bar_geometry(codec,metric,width):
				if piece.width>0: draw_rect(Rect2(left+float(piece.x),top,float(piece.width),18),COLORS.get(piece.phase,Color("6ce2de")))
			draw_string(font,Vector2(left+width+6,top+14),str(Ledger.total(snapshot,codec,metric)),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dce6ef"))
	var x: float = 0
	for phase: String in Ledger.PHASES:
		draw_rect(Rect2(x,195,9,9),COLORS[phase])
		draw_string(font,Vector2(x+14,204),Ledger.phase_name(phase,english),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("a9bbc9"))
		x += 80 if english else 63
