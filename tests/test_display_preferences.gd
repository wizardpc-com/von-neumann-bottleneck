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
		hub.find_child("HubBrowseJourney",true,false).grab_focus()
		hub.find_child("HubBrowseJourney",true,false).pressed.emit()
		for frame: int in range(5): await process_frame
		var page: Control = hub.find_child("HubNavigation",true,false)
		var cards: Control = hub.find_child("ChapterCards",true,false)
		valid = valid and page.visible and cards.get_child_count()==5 and page.get_global_rect().encloses(cards.get_global_rect())
		for card: Control in cards.get_children():
			valid = valid and page.get_global_rect().encloses(card.get_global_rect())
		hub.find_child("HubNavigationClose",true,false).pressed.emit()
		for frame: int in range(3): await process_frame
		valid = valid and not page.visible and hub.find_child("HubBrowseJourney",true,false).has_focus()
		hub.queue_free()
		await process_frame
	if valid: print("PASS: display settings coexist, retain unrelated preferences and reject unsupported rates; five chapter choices fit their explicit page without scrolling in both languages")
	else: push_error("Display preference preservation or reachable chapter-card layout failed")
	quit(0 if valid else 1)
