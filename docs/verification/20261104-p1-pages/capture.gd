extends Node
var phase := "before"
func wait() -> void:
	await get_tree().create_timer(0.6).timeout
func shot(key: String) -> void:
	await wait()
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("res://docs/verification/20261104-p1-pages/"+phase+"-"+key+".png")
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	if "--after" in OS.get_cmdline_user_args(): phase = "after"
	get_tree().root.size = Vector2i(1280,720)
	get_tree().root.content_scale_size = Vector2i(1280,720)
	for locale: String in ["zh_CN","en"]:
		get_node("/root/Localization").set_preferred_locale(locale)
		var hub: Node = load("res://src/ui/prototype_hub.tscn").instantiate()
		get_tree().root.add_child(hub)
		get_tree().current_scene = hub
		await wait()
		hub.terminology_handbook.open_handbook()
		await shot("handbook-"+locale)
		hub.terminology_handbook.close_handbook()
		if "--handbook-only" in OS.get_cmdline_user_args():
			hub.queue_free()
			await wait()
			continue
		hub._open_options_menu()
		await shot("settings-"+locale)
		hub._close_options_menu()
		hub._open_hub_navigation()
		await shot("achievements-"+locale)
		hub._close_hub_navigation()
		hub.laboratory._present_archive()
		await shot("archive-"+locale)
		hub.laboratory.archive.close()
		get_node("/root/PlaytestMoments").toggle()
		await shot("feedback-"+locale)
		get_node("/root/PlaytestMoments").close()
		hub._open_journey_journal()
		await shot("journal-"+locale)
		hub.journey_journal.close()
		hub.queue_free()
		await wait()
	get_tree().quit()
