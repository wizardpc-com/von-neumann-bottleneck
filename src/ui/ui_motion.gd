class_name UiMotion
extends RefCounted
## Short presentation-only transitions. No delay, input lock or simulation coupling.
const REVEAL_SECONDS: float = 0.12
static func reveal(control: Control) -> void:
	if control.has_meta("reveal_tween"):
		var previous: Tween = control.get_meta("reveal_tween")
		if previous != null and previous.is_valid(): previous.kill()
	control.modulate.a=1.0
	if DisplayServer.get_name()=="headless" or "--script" in OS.get_cmdline_args() or bool(ProjectSettings.get_setting("game/reduced_motion",false)): return
	control.modulate.a=0.88
	var tween: Tween = control.create_tween()
	control.set_meta("reveal_tween",tween)
	tween.tween_property(control,"modulate:a",1.0,REVEAL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
