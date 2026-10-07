extends "res://experiments/service_plan/response_chart.gd"
## One read-only view of recorded history locations and first responses at the same time.
const Projector = preload("res://experiments/service_plan/state_replay.gd")
var frames: Array[Dictionary] = []
var record_number: int = 0
var measured_total: int = 0

func _init() -> void:
	super()
	custom_minimum_size.y = 166

func words(zh: String, en: String) -> String: return en if english else zh

func configure_record(record: Dictionary, number: int) -> void:
	frames.clear(); record_number = number; measured_total = 0
	var metrics: Dictionary = record.get("metrics",{})
	if str(metrics.get("error","invalid")).is_empty() and not first_responses.is_empty():
		frames = Projector.build(record.get("events",[]))
		measured_total = int(metrics.get("total_cycles",0))
	tooltip_text = contract_caption()+"\n"+words("回放只展示所选记录；改变草稿不会改动这些位置和回应。", "Replay shows the selected recording; draft edits do not change its locations or responses.")
	queue_redraw()

func frame_position() -> int:
	var position: int = -1
	for index: int in frames.size():
		var event: Dictionary = frames[index].event
		if float(event.get("cycle",0))+float(event.get("duration",0)) > playback_cycle: break
		position = index
	return position

func current_source_index() -> int:
	var position: int = frame_position()
	return int(frames[position].source_index) if position >= 0 else -1

func witness_snapshot() -> Dictionary:
	var position: int = frame_position()
	return frames[position].duplicate(true) if position >= 0 else {}

func contract_caption() -> String:
	if first_responses.size() != 4:
		return words("四条流不断更新历史；先运行自己的分组与驻留方案。", "Four streams keep updating history. Run your grouping and residency plan.")
	var latest: int = end_cycle()
	var who: String = char(65+first_responses.find(latest))
	if deadline > 0:
		if latest > deadline:
			return words("总%d周期%s1420；%s首回应%d > %d。总快≠及时。", "Total %d cycles%s1420; %s first %d > %d. Total time ≠ timely response.") % [measured_total,"≤" if measured_total <= 1420 else ">",who,latest,deadline]
		return words("每流首回应都≤%d；总周期、精度仍须分别达标。", "All first responses ≤%d. Check total time and quality too.") % deadline
	return words("%s最晚首回应：%d周期。本合同看搬运，下一份再看谁等。", "Last first response: %s at %d. Next contract limits waiting.") % [who,latest]

func _draw() -> void:
	var font: Font = get_theme_font("font","Label")
	var text_color := Color("dfeaf2")
	if frames.is_empty() or first_responses.size() != 4:
		draw_string(font,Vector2(4,25),words("历史留在哪里，谁先收到结果？", "Where does history stay, and who gets the next result?"),HORIZONTAL_ALIGNMENT_LEFT,size.x-8,16,text_color)
		draw_string(font,Vector2(4,52),contract_caption(),HORIZONTAL_ALIGNMENT_LEFT,size.x-8,14,Color("90a7b7"))
		return
	var frame: Dictionary = witness_snapshot()
	if frame.is_empty(): return
	var cycle: int = int(playback_cycle)
	draw_string(font,Vector2(4,16),words("记录#%d · t%d · 该时刻历史（非最终状态）", "Record#%d · t%d · snapshot, not final state") % [record_number,cycle],HORIZONTAL_ALIGNMENT_LEFT,size.x-8,14,text_color)
	draw_string(font,Vector2(4,33),contract_caption(),HORIZONTAL_ALIGNMENT_LEFT,size.x-8,13,Color("c2d4df"))
	draw_string(font,Vector2(34,51),words("外存", "Backing"),HORIZONTAL_ALIGNMENT_LEFT,76,13,Color("90a7b7"))
	draw_string(font,Vector2(132,51),words("本地历史", "Resident history"),HORIZONTAL_ALIGNMENT_LEFT,106,13,Color("90a7b7"))
	var response_title: String = words("首次回应 · 周期", "First response · cycles")
	if deadline > 0: response_title += " · ≤"+str(deadline)
	draw_string(font,Vector2(254,51),response_title,HORIZONTAL_ALIGNMENT_LEFT,size.x-258,13,Color("90a7b7"))
	var bar_width: float = maxf(1,size.x-336)
	var scale: float = float(scale_cycles())
	for stream: int in 4:
		var y: float = 58+stream*22
		var resident: Dictionary = frame.residents[stream]
		var backing: Dictionary = frame.backing[stream]
		draw_string(font,Vector2(5,y+16),char(65+stream),HORIZONTAL_ALIGNMENT_LEFT,24,15,text_color)
		draw_rect(Rect2(32,y,78,20),Color("1b3342"))
		draw_string(font,Vector2(39,y+16),"%d B" % int(backing.bytes),HORIZONTAL_ALIGNMENT_LEFT,68,14,text_color)
		draw_string(font,Vector2(114,y+16),"↔",HORIZONTAL_ALIGNMENT_LEFT,16,14,Color("688493"))
		draw_rect(Rect2(132,y,106,20),Color("246854") if resident.present else Color("142633"))
		var location: String = ("64 B*" if resident.dirty else "64 B") if resident.present else words("未驻留", "not resident")
		draw_string(font,Vector2(138,y+16),location,HORIZONTAL_ALIGNMENT_LEFT,98,14,text_color if resident.present else Color("90a7b7"))
		var rect := Rect2(254,y,bar_width,20)
		draw_rect(rect,Color("142633"))
		draw_rect(Rect2(rect.position,Vector2(bar_width*minf(playback_cycle,first_responses[stream])/scale,20)),Color("dba458") if exceeds(stream) and playback_cycle > deadline else Color("438ca5"))
		var returned: bool = playback_cycle >= first_responses[stream]
		draw_string(font,Vector2(rect.end.x+6,y+16),("✓ " if returned else "… ")+str(first_responses[stream]),HORIZONTAL_ALIGNMENT_LEFT,74,14,text_color)
	if deadline > 0:
		var limit_x: float = 254+bar_width*deadline/scale
		draw_line(Vector2(limit_x,56),Vector2(limit_x,146),Color("f3c777"),1.5)
	draw_string(font,Vector2(4,162),words("此时刻外存含目录；本地*待写回。真实事件回放，速度仅供展示。", "Backing includes directory; local* is dirty. Recorded replay; scaled speed."),HORIZONTAL_ALIGNMENT_LEFT,size.x-8,13,Color("90a7b7"))
