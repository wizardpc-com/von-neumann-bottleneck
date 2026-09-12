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
		var cards: Control = hub.find_child("ChapterCards",true,false)
		var scroll: ScrollContainer = hub.find_child("ChapterScroll",true,false)
		valid = valid and cards.get_child_count()==5 and cards.size.x <= scroll.size.x+0.1
		var entry: Control = hub.find_child("TaskTreeEntry",true,false)
		var primary: Button = hub.find_child("TaskTree",true,false)
		valid = valid and entry.get_global_rect().end.y <= cards.global_position.y and primary.has_focus()
		for card: Control in cards.get_children():
			valid = valid and card.global_position.x>=scroll.global_position.x and card.get_global_rect().end.x<=scroll.get_global_rect().end.x+1
		scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value)
		for frame: int in range(3): await process_frame
		valid = valid and cards.get_global_rect().end.y<=scroll.get_global_rect().end.y+1
		hub.queue_free()
		await process_frame
	if valid: print("PASS: display settings coexist, retain unrelated preferences and reject unsupported rates; five chapter cards fit in both languages")
	else: push_error("Display preference preservation or reachable chapter-card layout failed")
	quit(0 if valid else 1)
