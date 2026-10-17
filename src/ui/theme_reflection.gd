extends AcceptDialog
## Derived, reopenable reflection. No completion flag, reward or persistent narrative state.
const OverlapCatalogType = preload("res://src/overlap_chapter/overlap_catalog.gd")
const FirstLightType = preload("res://src/ui/first_light.gd")

var body_column: VBoxContainer
var first_light: FirstLightType


func _ready() -> void:
	_add_first_light()


func _add_first_light() -> void:
	# Home configures before adding the Window; Journal configures after adding it.
	if body_column == null or not is_inside_tree() or is_instance_valid(first_light): return
	var localization: Node = get_node_or_null("/root/Localization")
	var english: bool = localization != null and localization.call("current_locale") == "en"
	first_light = FirstLightType.new()
	first_light.configure(english, _first_light_earned)
	body_column.add_child(first_light)
	first_light.play_button.pressed.connect(_queue_first_light_reveal)


func _queue_first_light_reveal() -> void:
	if not _first_light_earned() or not first_light.has_started: return
	# Showing the scene queues Container layout; reveal its settled geometry.
	if not get_tree().process_frame.is_connected(_reveal_first_light):
		get_tree().process_frame.connect(_reveal_first_light, CONNECT_ONE_SHOT)


func _reveal_first_light() -> void:
	if is_queued_for_deletion() or not visible or not has_focus() or not _first_light_earned(): return
	if not is_instance_valid(first_light) or not first_light.is_visible_in_tree(): return
	if gui_get_focus_owner() != first_light.play_button: return
	if first_light.playback_paused(): return
	var scroll := body_column.get_parent() as ScrollContainer
	if scroll != null: scroll.ensure_control_visible(first_light.scene_body)


func _first_light_earned() -> bool:
	if not is_inside_tree(): return false
	var save: Node = get_node_or_null("/root/GlobalSave")
	var mode: Node = get_node_or_null("/root/GameMode")
	if save == null or mode == null or mode.call("is_test_mode"): return false
	var content: Variant = save.get("game_player_content")
	return content != null and bool(content.completed_levels.get(&"tutorial", false))

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
	body_column = column
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",24)
	scroll.add_child(column)
	for key: StringName in keys:
		var paragraph := Label.new()
		paragraph.text=translate.call(key)
		paragraph.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		paragraph.add_theme_font_size_override("font_size",18)
		column.add_child(paragraph)
	_add_first_light()
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
