extends AcceptDialog
## Derived, reopenable reflection. No completion flag, reward or persistent narrative state.
const OverlapCatalogType = preload("res://src/overlap_chapter/overlap_catalog.gd")

func _init() -> void:
	# The popup owns its viewport; the root feedback handler cannot consume its
	# built-in Escape close before the dialog processes the same event.
	dialog_close_on_escape = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if not visible or not has_focus() or event.is_echo(): return
	var feedback: Variant = get_node_or_null("/root/OfflineFeedback")
	var moments: Variant = get_node_or_null("/root/PlaytestMoments")
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		if moments != null and (feedback == null or not feedback.enabled()):
			moments.toggle()
			set_input_as_handled()
		return
	if not event.is_action_pressed("ui_close_dialog"): return
	if feedback != null and feedback.backdrop.visible and feedback.panel.get_viewport() == self:
		set_input_as_handled()
		feedback.close_panel()
		return
	if moments != null and moments.panel.visible and moments.panel.get_viewport() == self:
		set_input_as_handled()
		moments.close()
		return
	var playtest: Variant = get_node_or_null("/root/PlaytestData")
	if playtest != null and bool(playtest.get("_feedback_visible")): return
	set_input_as_handled()
	hide()
	canceled.emit()

static func milestones(hardware: Dictionary, system: Dictionary, locality: Dictionary, overlap: Dictionary, layout: Dictionary) -> Array[StringName]:
	var keys: Array[StringName] = [&"theme.entry"]
	if bool(hardware.get(&"cpu",false)): keys.append(&"theme.build")
	if bool(system.get(&"cpu_speed",false)): keys.append(&"theme.time")
	if bool(locality.get(&"nearby_storage",false)): keys.append(&"theme.distance")
	var buffers: Dictionary = overlap.get("buffers",{})
	if buffers.has("board") and buffers.has("program"):
		var report: Dictionary = OverlapCatalogType.evaluate("buffers",buffers.board,buffers.program)
		if report.passed and not report.runs.is_empty() and int(report.runs[0].metrics.get("overlap",0))>0:
			keys.append(&"theme.overlap")
	if layout.has("relocation"): keys.append(&"theme.position")
	var time_complete: bool = overlap.has("synthesis")
	var position_complete: bool = layout.has("mixed")
	if time_complete: keys.append(&"theme.time_path")
	if position_complete: keys.append(&"theme.position_path")
	if time_complete and position_complete: keys.append(&"theme.ending")
	elif time_complete or position_complete: keys.append(&"theme.other_path")
	return keys

func configure(keys: Array[StringName], translate: Callable) -> void:
	name = "ThemeReflection"
	title = "A Thought Within the World"
	ok_button_text = translate.call(&"theme.close")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(570,360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",24)
	scroll.add_child(column)
	for key: StringName in keys:
		var paragraph := Label.new()
		paragraph.text=translate.call(key)
		paragraph.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		paragraph.add_theme_font_size_override("font_size",18)
		column.add_child(paragraph)
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
