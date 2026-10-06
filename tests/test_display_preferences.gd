extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	var settings := ConfigFile.new(); settings.set_value("other","preserve","yes"); settings.save("user://presentation.cfg")
	var mode: Node = root.get_node("WindowMode")
	mode.set_frame_limit(120); mode.set_reduced_motion(true)
	settings.load("user://presentation.cfg")
	var valid: bool = settings.get_value("display","frame_limit")==120 and settings.get_value("display","reduced_motion")==true and settings.get_value("other","preserve")=="yes"
	mode.set_frame_limit(999)
	valid=valid and mode.frame_limit==120
	var localization: Node = root.get_node("Localization")
	for language: String in ["zh_CN", "en"]:
		localization.set_locale(language)
		var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub)
		for frame: int in range(8): await process_frame
		var primary: Button = hub.find_child("TaskTree",true,false)
		var surface: Control = hub.find_child("HubSurface",true,false)
		valid = valid and primary.has_focus() and surface.get_global_rect().encloses(primary.get_global_rect())
		var title := hub.find_child("HubWorkTitle",true,false) as Label
		valid = valid and title.text == localization.text(&"game.title") and surface.get_global_rect().encloses(title.get_global_rect())
		var settings_button := hub.find_child("HubSettings",true,false) as Button
		settings_button.grab_focus(); settings_button.pressed.emit()
		for frame: int in range(3): await process_frame
		var manage := hub.find_child("HubManageProgress",true,false) as Button
		valid = valid and hub.options_overlay.visible and manage.is_visible_in_tree()
		manage.grab_focus(); manage.pressed.emit()
		for frame: int in range(5): await process_frame
		var page: Control = hub.find_child("HubNavigation",true,false)
		valid = valid and page.visible and not hub.options_overlay.visible and not surface.visible
		for id: String in ["ContinueButton","NewGameButton","ThemeReflectionButton","HubTerminologyButton","HubNavigationClose"]:
			var action := hub.find_child(id,true,false) as Button
			valid = valid and action.is_visible_in_tree() and page.get_global_rect().encloses(action.get_global_rect())
		valid = valid and hub.find_child("ChapterCards",true,false) == null and hub.find_child("CandidateStages",true,false) == null
		hub.find_child("HubNavigationClose",true,false).pressed.emit()
		for frame: int in range(3): await process_frame
		valid = valid and not page.visible and settings_button.has_focus()
		hub.queue_free()
		await process_frame
	var embedded = load("res://src/ui/prototype_hub.tscn").instantiate(); embedded.settings_only = true
	root.add_child(embedded)
	for frame: int in range(5): await process_frame
	valid = valid and embedded.find_child("HubManageProgress",true,false) == null and embedded.options_overlay.visible
	embedded.queue_free(); await process_frame
	if valid: print("PASS: display settings retain unrelated preferences and reject unsupported rates; bilingual work title and bounded management remain reachable; embedded settings add no Hub entry")
	else: push_error("Display preference preservation or reachable title/management layout failed")
	quit(0 if valid else 1)
