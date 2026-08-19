extends Node

signal mode_changed(mode: StringName)

const MODE_GAME: StringName = &"game"
const MODE_TEST: StringName = &"test"
const MODES: Array[StringName] = [MODE_GAME, MODE_TEST]

var current_mode: StringName = MODE_GAME


func _ready() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if "--test-mode" in arguments or "--mode=test" in arguments:
		current_mode = MODE_TEST
	elif "--game-mode" in arguments or "--mode=game" in arguments:
		current_mode = MODE_GAME


func set_mode(mode: StringName) -> bool:
	if mode not in MODES:
		return false
	if current_mode == mode:
		return true
	current_mode = mode
	mode_changed.emit(current_mode)
	return true


func is_test_mode() -> bool:
	return current_mode == MODE_TEST


func mode_index() -> int:
	return MODES.find(current_mode)


func mode_at(index: int) -> StringName:
	return MODES[index] if index >= 0 and index < MODES.size() else MODE_GAME
