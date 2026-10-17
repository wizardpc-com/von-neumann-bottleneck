extends SceneTree
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)

func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	ProjectSettings.set_setting("playtest/offline_tester",true)
	var navigation: Node = root.get_node("TaskNavigation")
	var feedback: Node = root.get_node("OfflineFeedback")
	check(navigation.enter("hardware_foundations/tutorial"),"ordinary task opens for offline tester")
	for index: int in 6: await process_frame
	var key := InputEventKey.new(); key.physical_keycode=KEY_F8; key.keycode=KEY_F8; key.pressed=true
	Input.parse_input_event(key)
	var released := InputEventKey.new(); released.physical_keycode=KEY_F8; released.keycode=KEY_F8; released.pressed=false
	Input.parse_input_event(released)
	for index: int in 3: await process_frame
	check(feedback.backdrop.visible and paused,"fast F8 press/release opens feedback and pauses game")
	check(feedback.panel.position.x>=0 and feedback.panel.position.y>=0 and feedback.panel.get_global_rect().end.x<=1280 and feedback.panel.get_global_rect().end.y<=720,"feedback fits 720p: "+str(feedback.panel.get_global_rect()))
	feedback.note.text="这里不清楚\n希望保留完整现场，不截断为短意见。"
	feedback.note.text_changed.emit()
	check(feedback.store.read_case(feedback.current.id).note==feedback.note.text,"typing autosaves without submit")
	var id: String = feedback.current.id
	feedback.close_panel()
	check(not paused and not feedback.backdrop.visible,"close restores game pause state")
	var logical := InputEventKey.new(); logical.keycode=KEY_F8; logical.pressed=true
	Input.parse_input_event(logical)
	logical=InputEventKey.new(); logical.keycode=KEY_F8; logical.pressed=false
	Input.parse_input_event(logical)
	for index: int in 3: await process_frame
	check(feedback.backdrop.visible,"logical F8 without a physical scan code opens feedback")
	feedback.close_panel()
	feedback.open_panel(); feedback._load_case(id)
	check(feedback.note.text.contains("保留完整现场"),"history restores previous note")
	if "--offline-feedback-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://offline-panel-zh.png")==OK,"Chinese panel screenshot")
	root.get_node("Localization").set_locale("en")
	for index: int in 3: await process_frame
	check(feedback.toolbar.get_child(0).text=="Feedback · F8","global entry follows language")
	if "--offline-feedback-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://offline-panel-en.png")==OK,"English panel screenshot")
	feedback.close_panel()
	check(not paused,"pause is restored after history review")
	feedback.open_for_task("chapter_4","mixed")
	for index: int in 3: await process_frame
	check(feedback.current.task.chapter_id=="chapter_4" and feedback.current.task.level_id=="mixed","task tree feedback retains explicit target")
	feedback.close_panel()
	print("PASS: offline feedback" if failures==0 else "FAIL: offline feedback")
	quit(0 if failures==0 else 1)
