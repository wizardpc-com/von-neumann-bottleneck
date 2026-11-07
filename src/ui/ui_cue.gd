extends RefCounted
## Short event cues share the player's Effects bus and never schedule game actions.
static func play(host: Node, event: StringName) -> void:
	if DisplayServer.get_name() == "headless": return
	var bus: int = AudioServer.get_bus_index("Effects")
	if bus < 0 or AudioServer.is_bus_mute(bus): return
	var voice: AudioStreamPlayer = host.get_node_or_null("UiCueVoice") as AudioStreamPlayer
	if voice == null:
		voice = AudioStreamPlayer.new()
		voice.name = "UiCueVoice"
		voice.bus = &"Effects"
		voice.volume_db = -19.0
		host.add_child(voice)
	var frequencies: Dictionary = {&"connect":660.0, &"reject":196.0, &"run":392.0, &"fail":164.8, &"met":784.0, &"improve":880.0, &"save":523.25}
	var frequency: float = float(frequencies.get(event, 440.0))
	const RATE := 22050
	const FRAMES := 2646
	var bytes := PackedByteArray()
	bytes.resize(FRAMES * 2)
	for index: int in FRAMES:
		var t: float = float(index) / RATE
		var envelope: float = sin(PI * float(index) / FRAMES)
		bytes.encode_s16(index * 2, roundi(sin(TAU * frequency * t) * envelope * envelope * 0.22 * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	voice.stream = stream
	voice.play()

class MetToast extends PanelContainer:
	func _process(_delta: float) -> void:
		visible = not preload("res://src/ui/guide_stage.gd").blocked(get_tree())
		if not visible: return
		var viewport: Vector2 = get_viewport().get_visible_rect().size
		var top: float = 12.0
		for node: Node in get_tree().get_nodes_in_group(&"workbench_nav"):
			if node is Control and node.is_visible_in_tree():
				top = maxf(top, node.get_global_rect().end.y + 10.0)
		var candidate := Rect2(Vector2(viewport.x - size.x - 16.0, top), size)
		var buttons: Array[Node] = get_tree().root.find_children("*", "BaseButton", true, false)
		for attempt: int in buttons.size() + 1:
			var next_top: float = candidate.position.y
			for node: Node in buttons:
				var button := node as Control
				if button.is_visible_in_tree() and candidate.intersects(button.get_global_rect().grow(10.0)):
					next_top = maxf(next_top, button.get_global_rect().end.y + 10.0)
			if is_equal_approx(next_top, candidate.position.y): break
			candidate.position.y = next_top
		global_position = candidate.position
		visible = candidate.position.x >= 0.0 and candidate.end.y <= viewport.y - 16.0


static func met(host: Node, again: bool) -> void:
	play(host, &"met")
	var old: Node = host.get_node_or_null("UiMetCue")
	if old != null:
		host.remove_child(old)
		old.queue_free()
	var cue := MetToast.new()
	cue.name = "UiMetCue"
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cue.z_index = 1900
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = host.get_node("/root/Localization").text(&"f1.met_again" if again else &"common.level_complete.title")
	label.add_theme_font_size_override("font_size", 20)
	cue.add_child(label)
	host.add_child(cue)
	cue.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	cue.size = cue.get_combined_minimum_size()
	cue.set_as_top_level(true)
	cue._process(0.0)
	host.get_tree().create_timer(1.8).timeout.connect(cue.queue_free)
