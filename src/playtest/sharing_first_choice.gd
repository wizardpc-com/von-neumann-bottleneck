extends CanvasLayer
## Only the configured receiver's first menu visit asks; declining never gates play.
const PATH := "user://sharing_prompt.cfg"
var overlay: Control
var local_button: Button
var previous_focus: Control

static func needs_choice() -> bool:
	if not RemoteFeedback.endpoint_allowed() or RemoteFeedback.enabled or RemoteFeedback.deletion_pending: return false
	var settings := ConfigFile.new()
	return settings.load(PATH)!=OK or settings.get_value("choice","endpoint","")!=RemoteFeedback.endpoint or settings.get_value("choice","notice","")!=RemoteFeedback.NOTICE_VERSION

static func remember_choice(mode: String) -> bool:
	if mode not in ["local","basic"] or not RemoteFeedback.endpoint_allowed(): return false
	if not RemoteFeedback.set_sharing_mode(mode): return false
	var settings := ConfigFile.new()
	settings.set_value("choice","endpoint",RemoteFeedback.endpoint)
	settings.set_value("choice","notice",RemoteFeedback.NOTICE_VERSION)
	return settings.save(PATH)==OK

func _ready() -> void:
	layer=1700
	if not needs_choice(): return
	overlay=Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(overlay)
	var shade := ColorRect.new(); shade.color=Color("050a12",0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_child(shade)
	var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_child(center)
	var panel := PanelContainer.new(); panel.custom_minimum_size=Vector2(680,0)
	var theme := Theme.new(); theme.default_font_size=20; InstrumentTheme.apply_to(theme); panel.theme=theme
	center.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",16); panel.add_child(box)
	label(box,"settings.sharing_title",26); label(box,"settings.sharing_intro")
	var destination := Label.new(); destination.text=RemoteFeedback.endpoint; destination.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(destination)
	var details := VBoxContainer.new(); details.hide()
	var inventory := Button.new(); inventory.name="SharingInventory"; inventory.text=Localization.text(&"settings.inventory"); inventory.set_meta("locale_key","settings.inventory")
	inventory.pressed.connect(func() -> void: details.visible=not details.visible); box.add_child(inventory)
	box.add_child(details); label(details,"settings.inventory_detail")
	var buttons: Array[Control] = [inventory]
	var url: String = RemoteFeedback.privacy_url()
	if not url.is_empty():
		var privacy_link := LinkButton.new(); privacy_link.name="PrivacyNoticeLink"
		privacy_link.focus_mode=Control.FOCUS_ALL; privacy_link.custom_minimum_size.y=36
		privacy_link.text=Localization.text(&"sharing.view_privacy_notice"); privacy_link.set_meta("locale_key","sharing.view_privacy_notice")
		privacy_link.pressed.connect(func() -> void: OS.shell_open(url))
		box.add_child(privacy_link); buttons.append(privacy_link)
	local_button=Button.new(); local_button.name="SharingLocalOnly"; local_button.text=Localization.text(&"sharing.local_only"); local_button.set_meta("locale_key","sharing.local_only"); local_button.custom_minimum_size.y=48
	local_button.pressed.connect(choose.bind("local")); box.add_child(local_button)
	var basic := Button.new(); basic.name="SharingBasic"; basic.text=Localization.text(&"sharing.share_basic_statistics_one_summary_per_visit"); basic.set_meta("locale_key","sharing.share_basic_statistics_one_summary_per_visit")
	basic.custom_minimum_size.y=48; basic.pressed.connect(choose.bind("basic")); box.add_child(basic)
	buttons.append(local_button); buttons.append(basic)
	for index: int in range(buttons.size()):
		buttons[index].focus_next=buttons[index].get_path_to(buttons[(index+1)%buttons.size()])
		buttons[index].focus_previous=buttons[index].get_path_to(buttons[(index+buttons.size()-1)%buttons.size()])
	Localization.locale_changed.connect(func(_locale: String) -> void: _refresh_language())
	call_deferred("_take_focus")

func _take_focus() -> void:
	previous_focus=get_viewport().gui_get_focus_owner()
	local_button.grab_focus()

func label(parent: Node,key: String,font_size: int=20) -> void:
	var node := Label.new(); node.text=Localization.text(StringName(key)); node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.set_meta("locale_key",key)
	node.add_theme_font_size_override("font_size",font_size); parent.add_child(node)

func _refresh_language() -> void:
	if not is_instance_valid(overlay): return
	for control: Control in overlay.find_children("*","Control",true,false):
		if control.has_meta("locale_key"):
			control.set("text",Localization.text(StringName(control.get_meta("locale_key"))))

func choose(mode: String) -> void:
	remember_choice(mode)
	# A failed preference write still cannot hold the user inside this prompt.
	if is_instance_valid(overlay): overlay.hide()
	if is_instance_valid(previous_focus): previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
	if is_instance_valid(overlay) and overlay.visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		choose("local"); get_viewport().set_input_as_handled()
