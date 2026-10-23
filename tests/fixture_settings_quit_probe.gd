extends "res://src/ui/prototype_hub.gd"

var direct_quits: int = 0

func _quit_game() -> void: direct_quits += 1
