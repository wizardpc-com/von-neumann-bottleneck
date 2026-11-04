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
	overlay.queue_free(); bar.queue_free()
	await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ")+"F1 presentation %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
