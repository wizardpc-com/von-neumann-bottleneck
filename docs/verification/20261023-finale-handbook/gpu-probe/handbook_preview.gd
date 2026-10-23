extends SceneTree
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		quit(1); return
	var handbook: Control = load("res://src/ui/terminology_handbook.gd").new()
	root.add_child(handbook)
	var signature: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for width: int in [1280,960]:
			root.size = Vector2i(width,720 if width == 1280 else 640)
			root.content_scale_size = root.size
			for term: StringName in [&"operation_navigation",&"operation_wiring",&"high_impedance"]:
				handbook.open_handbook(term)
				for frame: int in 8: await process_frame
				RenderingServer.force_draw(false); await process_frame
				var path: String = "E:/VNB/game/docs/verification/20261023-finale-handbook/"+locale+"-"+str(width)+"-"+String(term)+".png"
				var code: Error = root.get_texture().get_image().save_png(path)
				checks += 1
				if code != OK or not root.get_visible_rect().encloses(handbook.close_button.get_global_rect()): failures += 1
	if signature != root.get_node("GlobalSave").game_player_content.canonical_signature(): failures += 1
	handbook.queue_free(); await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ")+"handbook preview %d frames, %d failures"%[checks,failures])
	quit(0 if failures == 0 else 1)
