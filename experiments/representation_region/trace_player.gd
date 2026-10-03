extends Control
## Playback of completed events. This class never runs or changes a simulation.
signal event_selected(index: int)
signal playing_changed(value: bool)
var recorded_events: Array[Dictionary] = []
var current: int = -1
var playing: bool = false
var elapsed: float = 0.0
var english: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(0,94)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_process(false)

func configure(events: Array, use_english: bool) -> void:
	set_playing(false)
	recorded_events.clear()
	for event: Dictionary in events: recorded_events.append(event.duplicate(true))
	english = use_english
	current = -1; elapsed = 0.0
	queue_redraw()

func set_playing(value: bool) -> void:
	playing = value and not recorded_events.is_empty()
	set_process(playing)
	playing_changed.emit(playing)
	queue_redraw()

func toggle_play() -> void:
	if playing: set_playing(false); return
	if current < 0 or current >= recorded_events.size()-1: seek(0)
	set_playing(true)

func seek(index: int) -> void:
	if index < 0 or index >= recorded_events.size(): return
	current = index; elapsed = 0.0
	event_selected.emit(current)
	queue_redraw()

func step() -> void:
	set_playing(false)
	seek(mini(current+1,recorded_events.size()-1))

func display_duration() -> float:
	if current < 0: return 0.1
	# Readability scaling only; all displayed simulation times stay exact.
	return clampf(float(recorded_events[current].get("duration",0))*0.025,0.12,0.8)

func _process(delta: float) -> void:
	if not playing: return
	elapsed += delta
	if elapsed >= display_duration():
		if current+1 >= recorded_events.size(): set_playing(false)
		else: seek(current+1)
	queue_redraw()

func phase(kind: String) -> int:
	if "request" in kind: return 0
	if kind in ["transfer","prepare_source_read","prepare_write"]: return 1
	if kind in ["decode","encode"]: return 2
	if kind == "consume": return 3
	return -1

func _draw() -> void:
	var font: Font = get_theme_font("font","Label")
	var labels: Array[String] = []
	labels.assign(["Request","Transfer","Transform","Consume"] if english else ["请求","搬运","编码/解码","读取结果"])
	var active: int = -1
	var detail: String = "Choose a recorded event or play its evidence" if english else "选择已记录事件，或播放它的证据"
	if current >= 0 and current < recorded_events.size():
		var event: Dictionary = recorded_events[current]
		active = phase(str(event.kind))
		detail = "#%d/%d · %s · t=%d + %d · @%d" % [current+1,recorded_events.size(),str(event.kind),int(event.cycle),int(event.duration),int(event.address)]
	var width: float = size.x/4.0
	for i: int in 4:
		var rect := Rect2(i*width+2,6,width-6,34)
		draw_style_box(InstrumentTheme.panel(Color("173748") if i == active else Color("101e2b"),Color("50d5ff") if i == active else Color("354b5a"),5),rect)
		draw_string(font,rect.position+Vector2(0,22),labels[i],HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,13,Color("dfeaf2"))
		if i == active and playing and not bool(ProjectSettings.get_setting("game/reduced_motion",false)):
			var fraction: float = clampf(elapsed/display_duration(),0,1)
			draw_line(rect.position+Vector2(4,30),rect.position+Vector2(4+(rect.size.x-8)*fraction,30),Color("62dca7"),3.0)
	draw_string(font,Vector2(4,61),detail,HORIZONTAL_ALIGNMENT_LEFT,maxf(0,size.x-8),12,Color("dfeaf2"))
	draw_string(font,Vector2(4,82),"Visual replay only; recorded cycles and results never change." if english else "仅回放已完成事件；动画速度不改变记录周期或结果。",HORIZONTAL_ALIGNMENT_LEFT,maxf(0,size.x-8),11,Color("90a7b7"))
