extends SceneTree
## Availability fixtures, not a claim of earned player progression.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var save: Node = root.get_node("GlobalSave")
	var book: Control = load("res://src/ui/terminology_handbook.gd").new()
	root.add_child(book)
	await process_frame
	root.get_node("GameMode").set_mode(&"game")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		save.game_player_content.completed_levels.clear()
		save.game_player_content.completed_levels[&"tutorial"] = true
		book.set_lesson("hardware", "latch")
		check(not book.is_term_unlocked(&"multiplexer"), locale + ": tutorial alone does not open MUX early")
		# The storage branch is valid without completing any arithmetic task.
		save.game_player_content.completed_levels[&"latch"] = true
		save.game_player_content.completed_levels[&"register"] = true
		book.set_lesson("hardware", "ram")
		var signature: String = save.game_player_content.canonical_signature()
		check(book.prologue_catalog.is_unlocked(&"ram", save.game_player_content.completed_levels), locale + ": storage-only route makes RAM playable")
		check(not book.prologue_catalog.is_unlocked(&"selector", save.game_player_content.completed_levels), locale + ": fixture has not opened the optional selector route")
		check(book.is_term_unlocked(&"multiplexer"), locale + ": RAM's supplied MUX has readable guidance before arithmetic")
		book.open_handbook(&"multiplexer")
		check(book.detail_diagram.visible, locale + ": storage-first player can inspect the MUX diagram")
		check(save.game_player_content.canonical_signature() == signature, locale + ": handbook reading grants no progress or components")
		save.game_player_content.completed_levels.clear()
		save.game_player_content.completed_levels[&"tutorial"] = true
		save.game_player_content.completed_levels[&"half_adder"] = true
		book.set_lesson("hardware", "selector")
		check(book.is_term_unlocked(&"multiplexer"), locale + ": arithmetic-first selector guidance remains available")
	book.queue_free()
	await process_frame
	print("PASS: independent hardware-branch handbook availability" if failures.is_empty() else "FAIL: independent hardware-branch handbook availability")
	quit(0 if failures.is_empty() else 1)
