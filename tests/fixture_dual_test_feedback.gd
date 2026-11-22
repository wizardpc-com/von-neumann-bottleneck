extends SceneTree
## Rendered 1280×720 dual-Test integration, run with an isolated verifier profile.
var window: Window
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	if not ok:
		failures.append(message)
		push_error(message)
	return ok

func settle() -> void:
	for i: int in 6: await process_frame
	await RenderingServer.frame_post_draw

func keypress(key: Key) -> void:
	for pressed: bool in [true,false]:
		var e := InputEventKey.new()
		e.keycode=key; e.physical_keycode=key; e.pressed=pressed
		Input.parse_input_event(e)
		await settle()

func click(button: BaseButton) -> void:
	var viewport := button.get_viewport()
	var at := button.get_global_rect().get_center()
	var embedded := viewport is Window and (viewport as Window).is_embedded()
	var receiver: Viewport = root if embedded else viewport
	if embedded: at += Vector2((viewport as Window).position)
	var move := InputEventMouseMotion.new()
	move.position=at; move.global_position=at; move.window_id=root.get_window_id()
	receiver.push_input(move,true)
	await settle()
	if not check(viewport.gui_get_hovered_control()==button, "Pointer must reach "+button.name+" at "+str(at)+" hovered="+str(viewport.gui_get_hovered_control())): return
	for pressed: bool in [true,false]:
		var e := InputEventMouseButton.new()
		e.button_index=MOUSE_BUTTON_LEFT; e.pressed=pressed; e.position=at
		e.global_position=at; e.window_id=root.get_window_id()
		receiver.push_input(e,true)
		await settle()

func distance(left: Image, right: Image) -> float:
	var total := 0.0
	for y: int in range(8,720,16):
		for x: int in range(8,1280,16):
			var a := left.get_pixel(x,y)
			var b := right.get_pixel(x,y)
			total += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
	return total / (80*45*3)

func run() -> void:
	if not OS.get_user_data_dir().contains("/VonNeumannBottleneckChecks/") or DisplayServer.get_name()=="headless":
		push_error("Rendered isolated profile required."); quit(1); return
	var moments: Node = root.get_node("PlaytestMoments")
	var offline: Node = root.get_node("OfflineFeedback")
	var store: Node = root.get_node("PlaytestData")
	var remote: Node = root.get_node("RemoteFeedback")
	if not check(remote.is_public_test() and offline.enabled() and root.get_node("GameMode").is_test_mode(), "Requires public dual Test settings at startup."): quit(1); return
	remote.set_process(false)
	remote.request=null
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.gui_embed_subwindows=true
	# The creation exhibit also owns an F8 callback. Its dual-Test key must
	# leave the exhibit in place while the one shared shortcut opens feedback.
	var exhibit = preload("res://experiments/creation/work_focus.gd").new()
	exhibit.configure({"name":"QA work","output":[0,1,2,3],"recipe":{}},true)
	exhibit.visible = false
	root.add_child(exhibit)
	exhibit.popup_centered()
	exhibit.grab_focus()
	var exhibit_requests: Array[int] = []
	exhibit.request_feedback.connect(func() -> void: exhibit_requests.append(1))
	await settle()
	await keypress(KEY_F8)
	check(exhibit_requests.is_empty() and exhibit.visible and moments.panel.visible and moments.panel.get_viewport()==exhibit,"Saved-work F8 opens exactly one opinion form in the exhibit")
	await keypress(KEY_F8)
	check(exhibit_requests.is_empty() and not moments.panel.visible,"Exhibit F8 closes just the opinion form")
	exhibit.dismiss()
	await settle()
	window=Window.new()
	window.title="Chapter 1 workbench"
	window.borderless=true; root.add_child(window)
	window.popup(Rect2i(0,0,1280,720)); window.grab_focus()
	var host: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	window.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host._start_level(&"cpu_speed")
	await settle()
	var entry := host.find_child("MomentFeedbackButton",true,false) as Button
	if not check(entry!=null and entry.is_visible_in_tree() and window.is_embedded() and window.get_visible_rect().size==Vector2(1280,720),"Embedded task and actual 1280×720 workbench button required."): quit(1); return
	if not check(store.current_task_context.get("level_id")=="cpu_speed","Selected authored task actually started"): quit(1); return
	# Create a real capture through the older Test F8 route before enabling the
	# dual interface in the same edition profile.
	var current_version: Variant = ProjectSettings.get_setting("application/config/version")
	ProjectSettings.set_setting("application/public_test_feedback",false)
	ProjectSettings.set_setting("application/config/version","previous-offline-Test")
	await keypress(KEY_F8)
	if not check(offline.backdrop.visible and offline.current.get("build",{}).get("version")=="previous-offline-Test","Legacy F8 creates a versioned local case"): quit(1); return
	var original: String = offline.current.id
	var folder: String = offline.store.root.path_join("cases").path_join(original)
	offline.note.text = "Historical local-only QA case"
	offline.close_panel()
	await settle()
	var image_path := folder.path_join("screenshot.png")
	var original_hash := FileAccess.get_sha256(image_path)
	var note_hash := FileAccess.get_sha256(folder.path_join("notes.jsonl"))
	var case_hash := FileAccess.get_sha256(folder.path_join("case.json"))
	ProjectSettings.set_setting("application/config/version",current_version)
	ProjectSettings.set_setting("application/public_test_feedback",true)
	await click(entry)
	check(moments.panel.get_viewport()==window and moments.panel.visible and not offline.backdrop.visible,"Workbench pointer opens its opinion form")
	await keypress(KEY_F8)
	check(not moments.panel.visible and not offline.backdrop.visible,"F8 closes the online form alone")
	await settle()
	var board := window.get_texture().get_image()
	board.save_png("user://dual-workbench.png")
	await keypress(KEY_F8)
	check(moments.panel.visible and not offline.backdrop.visible and moments.target.level_id=="cpu_speed","Embedded F8 selects active workbench opinion without capture")
	var online := window.get_texture().get_image()
	online.save_png("user://dual-online.png")
	var capture: Button = moments.panel.find_child("OpenLocalDiagnosticCapture",true,false)
	await click(capture)
	if not check(offline.backdrop.visible and offline.panel.get_viewport()==window and not moments.panel.visible and offline.current.get("screenshot_status")=="captured","Local incident captured in same embedded window"): quit(1); return
	var current_image: String = offline.store.root.path_join("cases").path_join(offline.current.id).path_join("screenshot.png")
	var pic := Image.new()
	if not check(pic.load_png_from_buffer(FileAccess.get_file_as_bytes(current_image))==OK and pic.get_size()==board.get_size(),"Capture contains full workbench viewport"): quit(1); return
	var board_diff := distance(board,pic)
	var form_diff := distance(online,pic)
	print("CAPTURE_DISTANCE board=",board_diff," online_form=",form_diff)
	check(form_diff>0.025 and board_diff<form_diff*0.4,"Saved screenshot matches the workbench after the online form closes")
	pic.save_png("user://dual-captured.png")
	for i: int in offline.history.item_count:
		if offline.history.get_item_metadata(i)==original:
			offline.history.select(i); offline.history.item_selected.emit(i); break
	check(offline.current.id==original and offline.current.build.version=="previous-offline-Test" and offline.note.text=="Historical local-only QA case","Reopen returns the original note and capture")
	offline.close_panel(); await settle()
	await keypress(KEY_F8)
	await click(moments.general_button)
	check(moments.target.level_id=="" and store.current_task_context.get("level_id")=="cpu_speed","General feedback selection leaves active gameplay context intact")
	moments.opinion.text="Synthetic general feedback"
	await click(moments.send_opinion)
	if check(remote.queue.size()==1,"Exactly one explicitly sent general opinion"):
		var record: Dictionary = remote.queue[0].record
		check(record.payload.event=="general_feedback" and record.payload.mode=="test" and record.payload.visit_id=="" and not record.payload.has("chapter_id") and not record.payload.has("task_version") and not record.payload.has("level_id"),"General opinion carries neither stale task nor visit even inside the active workbench")
	var export_button: Button=moments.panel.find_child("ExportLocalDiagnosticZip",true,false)
	await click(export_button)
	if not check(offline.export_dialog.visible,"Pointer reached local ZIP chooser"): quit(1); return
	var zip:=ProjectSettings.globalize_path("user://dual-incidents.zip")
	offline.export_dialog.hide()
	offline.export_dialog.file_selected.emit(zip)
	await settle()
	var archive:=ZIPReader.new()
	if check(archive.open(zip)==OK,"Verified local ZIP created"):
		var prefix: String="cases/"+original+"/"
		var exported_case: Dictionary = JSON.parse_string(archive.read_file(prefix+"case.json").get_string_from_utf8())
		check(exported_case.get("id")==original and exported_case.get("note")=="Historical local-only QA case" and exported_case.get("build",{}).get("version")=="previous-offline-Test" and int(exported_case.get("revision",0))==int(offline.store.read_case(original).revision),"ZIP materializes the latest note with its historical build identity")
		check(archive.read_file(prefix+"screenshot.png")==FileAccess.get_file_as_bytes(image_path) and archive.read_file(prefix+"notes.jsonl")==FileAccess.get_file_as_bytes(folder.path_join("notes.jsonl")),"ZIP preserves original capture and note revisions")
		archive.close()
	check(FileAccess.get_sha256(folder.path_join("case.json"))==case_hash and FileAccess.get_sha256(image_path)==original_hash and FileAccess.get_sha256(folder.path_join("notes.jsonl"))==note_hash,"Original history survives browsing and export")
	print("EVIDENCE ",OS.get_user_data_dir())
	window.queue_free()
	await settle()
	if failures.is_empty(): print("PASS: embedded dual Test 1280×720 F8, pointer opinion, workbench capture, reopened history, general attribution and ZIP")
	quit(0 if failures.is_empty() else 1)
