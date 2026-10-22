extends SceneTree

var failures: Array[String] = []
var checks: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var mode: Node = root.get_node("GameMode")
	var save: Node = root.get_node("GlobalSave")
	_check(not mode.is_test_mode() and not mode.developer_tools_enabled(), "Ordinary launch defaults to Game without enabling developer tools.")
	var original: String = save.game_player_content.canonical_signature()
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub)
	await _settle()
	hub.call("_open_options_menu")
	var selector: Control = hub.find_child("SettingsGameMode", true, false)
	_check(selector != null and selector.is_visible_in_tree(), "The normal laboratory settings expose mode selection.")
	var choice: OptionButton = selector.get("option_button")
	_check(choice.item_count == 2 and choice.selected == 0, "Settings offer Game and Test with Game selected.")
	choice.item_selected.emit(1)
	_check(mode.is_test_mode() and choice.selected == 1, "The ordinary settings can enter Test.")
	_check(not mode.developer_tools_enabled(), "Mode selection does not grant unrelated developer commands.")
	choice.item_selected.emit(0)
	_check(not mode.is_test_mode() and choice.selected == 0, "The same settings can return to Game.")
	hub.queue_free()
	await _settle()
	var hardware: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(hardware)
	await _settle()
	root.get_node("WindowMode").open_settings()
	await _settle()
	var settings_layer: CanvasLayer = root.get_node("WindowMode").get("settings_layer")
	_check(settings_layer.find_child("SettingsGameMode", true, false) == null, "Generic workbench settings preserve the existing departure guards before mode changes.")
	selector = hardware.get("mode_selector")
	_check(selector.is_visible_in_tree(), "Hardware retains its supported in-place mode selector.")
	choice = selector.get("option_button")
	choice.item_selected.emit(1)
	await _settle()
	_check(mode.is_test_mode() and hardware.get("player_content") == hardware.get("test_player_content"), "The hardware selector activates the isolated Test content.")
	_check((hardware.get("component_library") as Dictionary).has(&"TinyComputer"), "Test provides the temporary processor needed to inspect later tasks.")
	_check((hardware.get("completed_levels") as Dictionary).is_empty(), "Temporary Test components do not fabricate completions.")
	choice.item_selected.emit(0)
	await _settle()
	_check(not mode.is_test_mode() and hardware.get("player_content") == save.game_player_content, "Switching back restores the real Game content.")
	_check(save.game_player_content.canonical_signature() == original, "The mode round trip preserves the actual player signature.")
	_check(not (hardware.get("component_library") as Dictionary).has(&"TinyComputer"), "Temporary Test components never become Game rewards.")
	settings_layer.queue_free()
	root.get_node("WindowMode").settings_layer = null
	hardware.queue_free()
	await _settle()
	if failures.is_empty():
		print("PASS: mode access ", checks, " checks; free_candidate=", OS.has_feature("free_candidate"))
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _settle() -> void:
	for frame: int in range(6):
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
