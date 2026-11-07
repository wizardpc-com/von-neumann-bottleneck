extends SceneTree
var failures := 0
var checks := 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	var overlay: Control = load("res://src/ui/level_completion_overlay.gd").new()
	root.add_child(overlay)
	await process_frame
	overlay.present_seal_ready(&"half_adder","HalfAdder","Ready to seal","Prologue",&"hardware_foundations","Seal","Stay","Map")
	check(overlay.visible and overlay.primary_action_button.visible,"Verified seal action remains available")
	check(not overlay.emblem.visible and overlay.music_cue_count == 0,"Ready-to-seal has no earned emblem or completion melody")
	overlay.dismiss()
	overlay.present(&"half_adder","HalfAdder","Earned","Prologue",&"hardware_foundations")
	check(overlay.emblem.visible and overlay.music_cue_count == 1,"Earned card restores emblem and plays one completion cue")
	overlay.dismiss()
	var bar := preload("res://src/ui/cycle_budget_bar.gd").new()
	root.add_child(bar)
	ProjectSettings.set_setting("game/reduced_motion",false)
	bar.show_run(100,40,80,false)
	ProjectSettings.set_setting("game/reduced_motion",true)
	bar.show_run(75,15,80,false)
	check(bar._reveal == 1.0 and bar.total == 75 and bar.waiting == 15,"Reduced motion immediately shows unchanged measured values")
	await create_timer(0.7).timeout
	check(bar._reveal == 1.0 and bar.total == 75,"An earlier reveal cannot overwrite the reduced-motion run")
	var host := Control.new()
	root.add_child(host)
	var nav := Panel.new()
	nav.size = Vector2(1280, 90)
	nav.add_to_group(&"workbench_nav"); host.add_child(nav)
	var button := Button.new()
	button.position = Vector2(1100, 100); button.size = Vector2(160, 48)
	host.add_child(button)
	preload("res://src/ui/ui_cue.gd").met(host, true)
	await process_frame
	var toast: Control = host.get_node("UiMetCue")
	check(toast.get_global_rect().position.y >= nav.get_global_rect().end.y + 10, "Repeat toast clears navigation")
	check(not toast.get_global_rect().intersects(button.get_global_rect().grow(9)), "Right toast clears toolbar buttons")
	check(is_equal_approx(toast.get_global_rect().end.x, root.get_visible_rect().size.x - 16), "Toast uses right canvas margin")
	button.position.y += 70
	await process_frame
	check(not toast.get_global_rect().intersects(button.get_global_rect().grow(9)), "Toast follows control relayout")
	overlay.present(&"half_adder", "", "Earned", "", &"hardware_foundations")
	await process_frame
	check(not toast.visible, "Blocking card hides existing toast")
	preload("res://src/ui/ui_cue.gd").met(host, false)
	check(not host.get_node("UiMetCue").visible, "Toast created under blocking card starts hidden")
	await create_timer(1.9).timeout
	check(host.get_node_or_null("UiMetCue") == null, "Hidden toast retains auto-dismiss lifetime")
	host.queue_free()
	overlay.queue_free(); bar.queue_free()
	await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ")+"F1 presentation %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
