extends SceneTree

var handbook_type: GDScript
const NarrativeType = preload("res://src/ui/mission_narrative_catalog.gd")
const LinkedTextType = preload("res://src/ui/linked_mission_text.gd")

var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	handbook_type = load("res://src/ui/terminology_handbook.gd")
	var handbook: Variant = handbook_type.new()
	root.add_child(handbook)
	await process_frame
	var save: Node = root.get_node("GlobalSave")
	var system: Node = root.get_node("SystemChapter")
	var locality: Node = root.get_node("LocalityChapter")
	var localization: Node = root.get_node("Localization")
	var player_signature: String = save.game_player_content.canonical_signature()
	handbook.open_handbook()
	check(handbook.visible_term_ids.size() == 20 and not handbook.future_toggle.button_pressed, "Future subjects do not flood the initial table of contents.")
	handbook.open_handbook(&"cache")
	check(handbook.available_term_ids.size() == 20, "Fresh Game opens only the 20 first-lesson concepts.")
	check(not handbook.is_term_unlocked(&"cache") and not handbook.detail_diagram.visible, "Opening a future term directly cannot reveal its diagram.")
	check(handbook.detail_body_label.text.contains(localization.text(&"terminology.locked.body", [handbook._lesson_title(&"cache")])), "Future topics explain the actual lesson that opens them.")
	check(save.game_player_content.canonical_signature() == player_signature, "Reading the handbook cannot mark lessons complete or install components.")
	var mapped: Array[StringName] = []
	for lesson: StringName in handbook_type.LESSON_TERMS:
		for term: StringName in handbook_type.LESSON_TERMS[lesson]:
			check(handbook_type.has_term(term) and term not in mapped, "Each mapped term exists exactly once: %s" % term)
			mapped.append(term)
	check(mapped.size() == handbook_type.TERMS.size(), "All existing terms have an explicit learning stage.")

	# These snapshots exercise availability policy only. End-to-end Game tests
	# separately earn these prerequisites by building and testing player circuits.
	for level: StringName in handbook.prologue_catalog.level_ids():
		for locale: String in ["zh_CN", "en"]:
			localization.set_locale(locale)
			var pages: Array = NarrativeType.HARDWARE_PAGES.get(level, [])
			for page: Dictionary in pages:
				_check_required_links(handbook, localization.text(page[&"body"]), String(level))
		save.game_player_content.completed_levels[level] = true
		if level == &"tutorial":
			check(handbook.is_term_unlocked(&"half_adder") and handbook.is_term_unlocked(&"sr_latch"), "Tutorial opens both existing construction branches in the handbook.")
			check(not handbook.is_term_unlocked(&"alu") and not handbook.is_term_unlocked(&"cpu"), "Tutorial does not skip later construction stages.")
	system.prologue_ready = true
	for level: StringName in handbook.system_catalog.level_ids():
		for locale: String in ["zh_CN", "en"]:
			localization.set_locale(locale)
			for key: StringName in NarrativeType.SYSTEM_PAGES[level]:
				_check_required_links(handbook, localization.text(key), String(level))
		system.game_completed[level] = true
	for level: StringName in handbook.locality_catalog.level_ids():
		for locale: String in ["zh_CN", "en"]:
			localization.set_locale(locale)
			for key: StringName in NarrativeType.LOCALITY_PAGES[level]:
				_check_required_links(handbook, localization.text(key), String(level))
		locality.game_completed[level] = true
	handbook.open_handbook()
	check(handbook.available_term_ids.size() == 89, "Original campaign completion opens all 89 entries.")
	for locale: String in ["zh_CN", "en"]:
		localization.set_locale(locale)
		for term: Dictionary in handbook_type.TERMS:
			handbook.open_handbook(term["id"])
			await process_frame
			check(not handbook.detail_body_label.text.begins_with("terminology."), "Entry is translated: %s %s" % [locale, term["id"]])
			if term.has("diagram"):
				check(handbook.detail_diagram.visible, "Illustrated entry renders: %s %s" % [locale, term["id"]])
				if "--handbook-capture" in OS.get_cmdline_user_args() and term["id"] in [&"signal", &"binary", &"half_adder", &"sr_latch", &"register", &"junction"]:
					await RenderingServer.frame_post_draw
					var folder := "res://.godot/polish/handbook/"
					DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
					root.get_texture().get_image().save_png(folder + locale + "-" + String(term["id"]) + ".png")
	handbook.search_edit.text = "cache"
	handbook.open_handbook(&"bit")
	check(handbook.search_edit.text.is_empty() and handbook.term_tree.get_selected().get_metadata(0) == &"bit", "A Mission link clears stale search filters and opens the requested entry.")
	save.game_player_content.completed_levels.clear()
	system.prologue_ready = false
	system.game_completed.clear()
	locality.game_completed.clear()
	handbook.open_handbook(&"cpu")
	check(not handbook.is_term_unlocked(&"cpu"), "Handbook does not retain stale completion after progress changes.")
	print("Handbook checks: %d; failures: %d" % [checks, failures.size()])
	print("PASS: progressive learning handbook" if failures.is_empty() else "FAIL: progressive learning handbook")
	quit(0 if failures.is_empty() else 1)


func _check_required_links(handbook: Variant, text: String, level: String) -> void:
	for term: StringName in LinkedTextType.linked_term_ids(text):
		check(handbook.is_term_unlocked(term), "Required specification is readable before solving %s: %s" % [level, term])
