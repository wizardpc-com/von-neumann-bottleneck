extends SceneTree
## Presentation geometry and category navigation in the actual room and floating surfaces.
var failures: int = 0
var checks: int = 0
var hub: Control
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 12: await process_frame
func fits(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var rect: Rect2 = control.get_global_rect()
	var bounds: Rect2 = control.get_viewport().get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents: bounds = bounds.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return bounds.grow(1).encloses(rect)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--page-layout-capture" not in OS.get_cmdline_user_args(): return
	RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute("res://.godot/page-layout-captures")
	check(root.get_texture().get_image().save_png("res://.godot/page-layout-captures/"+name+".png") == OK,"Capture "+name)
func click_tab(tabs: TabContainer, index: int) -> void:
	var bar: TabBar = tabs.get_tab_bar()
	var point: Vector2 = bar.global_position + bar.get_tab_rect(index).get_center()
	if tabs.get_viewport() is SubViewport:
		var pages: Control = hub.laboratory.terminal_pages
		point = pages.global_position + point / Vector2(pages.resolution) * pages.size
	for pressed: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		event.position = point; event.global_position = point
		root.push_input(event,true)
		await process_frame
	await settle()
	check(tabs.current_tab == index,"Pointer selects settings category %d" % index)
func inspect_settings(host: Control, prefix: String) -> void:
	var tabs: TabContainer = host.find_child("SettingsCategories",true,false)
	check(tabs != null and tabs.get_tab_count() == 3,"Three settings categories")
	if tabs == null: return
	for index: int in 3:
		await click_tab(tabs,index)
		check(fits(host.options_resume_button) and fits(host.options_quit_button),"Settings footer fits "+prefix)
		check(fits(tabs.get_tab_bar()),"Settings categories fit "+prefix)
		var key: String = ["LanguageChoice","SoundVolume","ExportDiagnostics"][index]
		check(fits(host.find_child(key,true,false)),"Selected category action visible "+key+prefix)
		var active: Control = tabs.get_current_tab_control()
		for control: Node in active.find_children("*","Control",true,false):
			if control is BaseButton and control.is_visible_in_tree() and not control.disabled:
				var next_path: NodePath = control.focus_next
				if not next_path.is_empty(): check(control.get_node(next_path).is_visible_in_tree(),"Focus stays on visible controls "+control.name)
		capture(prefix+"-settings-"+str(index))
func inspect_feedback(prefix: String) -> void:
	var feedback: Node = root.get_node("PlaytestMoments")
	await settle()
	for key: String in ["FeedbackCategory","KeepFeedbackLocally","SendTaskFeedback"]:
		check(fits(feedback.panel.find_child(key,true,false)),"Feedback first-screen action fits "+prefix+key)
	check(fits(feedback.opinion),"Opinion visible "+prefix)
	check(fits(feedback.status),"Feedback delivery status fits "+prefix)
	check(fits(feedback.panel.find_child("FeedbackPrivacy",true,false)),"Feedback privacy fits "+prefix)
	capture(prefix+"-feedback")
func run() -> void:
	ProjectSettings.set_setting("game/reduced_motion",true)
	ProjectSettings.set_setting("playtest/offline_tester",false)
	var feedback: Node = root.get_node("PlaytestMoments")
	var offline: Node = root.get_node("OfflineFeedback")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.size = Vector2i(1280,720); root.content_scale_size = root.size
		hub = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub); current_scene = hub; await settle()
		hub.laboratory._on_room_action("settings"); await settle()
		await inspect_settings(hub,locale+"-room")
		for dimensions: Vector2i in [Vector2i(1280,960),Vector2i(1920,900)]:
			root.size=dimensions; root.content_scale_size=dimensions; await settle()
			var tabs: TabContainer = hub.find_child("SettingsCategories",true,false)
			check(fits(tabs) and fits(hub.options_resume_button),"Room settings fit "+str(dimensions))
		root.size=Vector2i(1280,720); root.content_scale_size=root.size; await settle()
		hub._close_options_menu(); await settle()
		hub.laboratory._on_room_action("feedback"); await inspect_feedback(locale+"-room")
		feedback.close(); await settle()
		ProjectSettings.set_setting("playtest/offline_tester",true)
		hub.laboratory._on_room_action("feedback"); await settle()
		check(fits(offline.note) and fits(offline.category),"Offline note and category fit "+locale)
		check(fits(offline.preview) and fits(offline.history),"Offline captured scene and history fit "+locale)
		capture(locale+"-room-offline")
		offline.close_panel(); ProjectSettings.set_setting("playtest/offline_tester",false)
		hub.queue_free(); await settle()
		var floating: Control = load("res://src/ui/prototype_hub.gd").new()
		floating.settings_only=true; floating.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(floating); await settle()
		await inspect_settings(floating,locale+"-floating")
		floating.queue_free(); await settle()
		feedback.toggle(); await inspect_feedback(locale+"-floating")
		feedback.close(); await settle()
		ProjectSettings.set_setting("playtest/offline_tester",true)
		await offline.open_panel(); await settle()
		check(fits(offline.note) and fits(offline.category) and fits(offline.preview),"Floating offline essentials fit "+locale)
		capture(locale+"-floating-offline")
		offline.close_panel(); ProjectSettings.set_setting("playtest/offline_tester",false)
		await settle()
	print(("PASS: " if failures == 0 else "FAIL: ")+"settings and feedback layout %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
