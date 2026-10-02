extends SceneTree
const Reflection=preload("res://src/ui/theme_reflection.gd")
const Overlap=preload("res://src/overlap_chapter/overlap_catalog.gd")
var failed:=false
func _init() -> void:call_deferred("_run")
func _run() -> void:
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		root.get_node("GameMode").set_mode(&"test")
		var hub: Control=load("res://src/ui/prototype_hub.tscn").instantiate();root.add_child(hub)
		root.mode=Window.MODE_WINDOWED;await create_timer(1.5).timeout
		root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
		for frame: int in 5:await process_frame
		hub.find_child("ThemeReflectionButton",true,false).pressed.emit()
		for frame: int in 4:await process_frame
		var fresh: AcceptDialog=hub.get_node("ThemeReflection")
		await _capture(locale+"-fresh")
		fresh.hide();fresh.queue_free();await process_frame
		var keys: Array[StringName]=Reflection.milestones({&"cpu":true},{&"cpu_speed":true},{&"nearby_storage":true},{"buffers":Overlap.reference_solution("buffers"),"synthesis":{}},{"relocation":{},"mixed":{}})
		var full=Reflection.new();full.configure(keys,root.get_node("Localization").text);hub.add_child(full);full.popup_centered(Vector2i(640,500))
		for frame: int in 4:await process_frame
		var scroll: ScrollContainer
		for child: Node in full.get_children():
			if child is ScrollContainer:scroll=child
		scroll.ensure_control_visible(scroll.get_child(0).get_child(keys.size()-1))
		for frame: int in 4:await process_frame
		failed=failed or not full.get_ok_button().is_visible_in_tree()
		await _capture(locale+"-ending")
		full.hide();hub.queue_free();await process_frame
	print("FAIL: theme reflection capture" if failed else "PASS: bilingual fresh and earned ending render at 1280x720")
	quit(1 if failed else 0)
func _capture(label: String) -> void:
	RenderingServer.force_draw(false)
	failed=failed or root.size!=Vector2i(1280,720)
	failed=root.get_texture().get_image().save_png("res://docs/verification/20261002-theme-reflection/"+label+".png")!=OK or failed
