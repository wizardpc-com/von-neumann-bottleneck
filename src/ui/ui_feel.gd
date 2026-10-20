extends Node
## Small, shared feel for every control in the game: a brief light on press, so
## each click visibly lands. Presentation only; never delays or blocks input.
## Skipped headless, under --script runs and with reduced motion.

const FLASH := Color(1.22, 1.26, 1.28, 1.0)
const SECONDS := 0.18

func _ready() -> void:
	if DisplayServer.get_name() == "headless" or "--script" in OS.get_cmdline_args(): return
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.has_meta("ui_feel"): return
	button.set_meta("ui_feel", true)
	button.button_down.connect(_flash.bind(weakref(button)))

func _flash(reference: WeakRef) -> void:
	var button := reference.get_ref() as BaseButton
	if button == null or not button.is_inside_tree() or button.disabled: return
	if bool(ProjectSettings.get_setting("game/reduced_motion", false)): return
	var rest: Color = button.get_meta("ui_feel_rest", button.modulate)
	button.set_meta("ui_feel_rest", rest)
	if button.has_meta("ui_feel_tween"):
		var previous: Tween = button.get_meta("ui_feel_tween")
		if previous != null and previous.is_valid(): previous.kill()
	button.modulate = rest * FLASH
	var tween: Tween = button.create_tween()
	button.set_meta("ui_feel_tween", tween)
	tween.tween_property(button, "modulate", rest, SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
