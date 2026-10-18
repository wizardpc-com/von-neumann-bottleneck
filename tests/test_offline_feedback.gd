extends SceneTree
const Creation = preload("res://experiments/creation/session.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)

func run() -> void:
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester",false)
	var old_toolbar_visible: bool = root.get_node("OfflineFeedback").toolbar.visible
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
	await local_entry_policy()
	ProjectSettings.set_setting("playtest/offline_tester",old_tester)
	feedback.toolbar.visible=old_toolbar_visible
	check(ProjectSettings.get_setting("playtest/offline_tester")==old_tester and feedback.toolbar.visible==old_toolbar_visible,"fixture restores the exact original role and toolbar visibility")
	print("PASS: offline feedback" if failures==0 else "FAIL: offline feedback")
	quit(0 if failures==0 else 1)

func settle() -> void:
	for frame: int in 8: await process_frame

func stroke(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code; event.physical_keycode=code; event.pressed=down
		Input.parse_input_event(event)
		await settle()

func fully_visible(control: Control) -> bool:
	if not control.is_visible_in_tree() or control.size.x<=0 or control.size.y<=0: return false
	var available: Rect2 = control.get_viewport().get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor!=null:
		if ancestor is Control and ancestor.clip_contents: available=available.intersection(ancestor.get_global_rect())
		ancestor=ancestor.get_parent()
	return available.encloses(control.get_global_rect())

func protected_state() -> Dictionary:
	var save: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	save.erase("saved_at_utc")
	var disk: Dictionary = {}
	for path: String in ["user://savegame_v1.json","user://savegame_v1.json.bak","user://hardware_workbenches_v1.json",Creation.launch_path()]:
		disk[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
		for transaction: String in Files.transaction_paths(path): disk[transaction]=FileAccess.get_sha256(transaction)
	var nav: Node = root.get_node("TaskNavigation")
	return {"game":save,"disk":disk,"best":root.get_node("PersonalRecords").best.duplicate(true),
		"lease":DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())),
		"recovery":DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())+".recovering"),
		"navigation":{"selected":nav.selected,"pending":nav.pending,"from_tree":nav.from_tree}}

func prepare_work() -> bool:
	var writer = Creation.new()
	var opened: Dictionary = writer.open(Creation.launch_path())
	check(opened.get("writable",false),"QA owns an isolated work writer before feedback browsing")
	if not opened.get("writable",false): writer.close(); return false
	var trained: Dictionary = writer.train()
	var restored: Dictionary = writer.transport([0,1,0,2],"predictive") if trained.get("ok",false) else {}
	check(restored.get("ok",false) and restored.get("lossless",false),"QA really learns and restores its source before feedback browsing")
	if not restored.get("ok",false) or not restored.get("lossless",false): writer.close(); return false
	var mode: Dictionary = writer.set_mode("predict")
	var begun: Dictionary = writer.begin_prediction("practice") if mode.get("ok",false) else {}
	if not begun.get("ok",false): check(false,"QA starts an actual prediction round"); writer.close(); return false
	for index: int in 4096:
		if writer.prediction.finished: break
		var committed: Dictionary = writer.commit_prediction()
		var revealed: Dictionary = writer.reveal_prediction() if committed.get("ok",false) else {}
		if not revealed.get("ok",false): check(false,"QA commits before each actual reveal"); writer.close(); return false
	if not writer.prediction.finished: check(false,"QA completes the actual prediction"); writer.close(); return false
	mode=writer.set_mode("generate")
	var generated: Dictionary = writer.generate() if mode.get("ok",false) else {}
	var kept: Dictionary = writer.save_work("Before feedback browsing") if generated.get("ok",false) else {}
	check(kept.get("ok",false),"QA keeps an actual immutable work with its original complete recipe")
	writer.close()
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())),"QA releases the original work writer before UI checks")
	return kept.get("ok",false)

func local_button(host: Control) -> Button:
	return host.find_child("MomentFeedbackButton",true,false) as Button

func point_at(control: Control, message: String) -> void:
	var motion := InputEventMouseMotion.new(); motion.position=control.get_global_rect().get_center()
	root.push_input(motion,true); await settle()
	var hovered: Control = root.gui_get_hovered_control()
	check(hovered==control or control.is_ancestor_of(hovered),message)

func click_entry(button: Button) -> void:
	await point_at(button,"The actual pointer reaches the original feedback button")
	var at: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT; event.position=at; event.pressed=down
		root.push_input(event,true); await settle()

func host_entry(host: Control, scope: String) -> void:
	var feedback: Node = root.get_node("OfflineFeedback")
	var entry: Button = local_button(host)
	check(entry!=null and fully_visible(entry),"Original local feedback entry is visible within every ancestor clip: "+scope)
	if entry==null or not fully_visible(entry): return
	check(not feedback.toolbar.visible,"Fixed tester global strip yields to the original local entry: "+scope)
	var controls: Array[Control] = []
	if scope.contains("system"):
		controls.append(host.terminology_handbook.entry_button)
	else:
		for index: int in range(host.dock.get_child_count()-3,host.dock.get_child_count()): controls.append(host.dock.get_child(index))
	for control: Control in controls:
		check(fully_visible(control) and not feedback.toolbar.is_visible_in_tree(),"Original Handbook/Hint/Run controls are not covered by the global strip: "+scope+" "+control.name)
		await point_at(control,"Actual pointer reaches the original Handbook/Hint/Run control without triggering it: "+scope+" "+control.name)
	var before: Dictionary = protected_state()
	if "--offline-feedback-capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var path: String = "user://offline-feedback-footer-captures/"+scope+".png"
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		check(root.get_texture().get_image().save_png(path)==OK,"Actual original host footer frame: "+scope)
	await click_entry(entry)
	check(feedback.backdrop.visible and feedback.panel.is_visible_in_tree() and feedback.panel.get_viewport()==root and paused,"Actual local mouse entry opens the same offline panel and pause contract: "+scope)
	check(not feedback.toolbar.visible and not feedback.current.is_empty(),"Real local feedback captures the original host without duplicate toolbar: "+scope)
	if DisplayServer.get_name()!="headless": check(feedback.current.get("screenshot_status","")=="captured","Local entry keeps actual pre-overlay screenshot: "+scope)
	var export_button: Button
	for child: Node in feedback.panel.find_children("*","Button",true,false):
		if child.get_meta("locale_pair",[]).has("Export all feedback (one ZIP)"): export_button=child
	check(export_button!=null and fully_visible(export_button),"Original panel export remains a visible action: "+scope)
	if export_button!=null:
		var wired: bool = false
		for connection: Dictionary in export_button.pressed.get_connections():
			if connection.callable==Callable(feedback,"export_all"): wired=true
		check(wired,"Original panel export is still connected to its unchanged export function")
	await stroke(KEY_ESCAPE)
	check(not feedback.backdrop.visible and not paused and root.gui_get_focus_owner()==entry and not feedback.toolbar.visible,"Local panel Escape restores exact original entry focus without reintroducing the strip: "+scope)
	entry.grab_focus(); await stroke(KEY_F8)
	check(feedback.backdrop.visible and paused and not feedback.toolbar.visible,"Hidden duplicate strip never disables original F8: "+scope)
	await stroke(KEY_ESCAPE)
	check(not feedback.backdrop.visible and not paused and root.gui_get_focus_owner()==entry,"F8 Escape retains its exact original local focus: "+scope)
	check(protected_state()==before,"Mouse and F8 feedback preserve original work, recipe bytes, game, records, navigation and leases: "+scope)

func window_entry_policy(host: Control) -> void:
	var feedback: Node = root.get_node("OfflineFeedback")
	var before: Dictionary = protected_state()
	var window := Window.new(); window.title="Feedback viewport fixture"; root.add_child(window)
	window.popup_centered(Vector2i(480,260)); window.grab_focus(); await settle()
	check(feedback._focused_window(root)==window and feedback.toolbar.visible,"Focused window without a local entry retains global fallback despite another viewport's entry")
	var clip := Control.new(); clip.clip_contents=true; clip.size=Vector2(300,80); window.add_child(clip)
	var button: Button = root.get_node("PlaytestMoments").make_button(); clip.add_child(button)
	button.position=Vector2(12,12); button.size=Vector2(180,44); await settle()
	check(not feedback.toolbar.visible,"Same focused viewport's live registered entry suppresses the duplicate strip")
	button.disabled=true; await settle()
	check(feedback.toolbar.visible,"Disabled local entry cannot remove fallback")
	button.disabled=false
	var old_mouse_filter: int = button.mouse_filter
	button.mouse_filter=Control.MOUSE_FILTER_IGNORE; await settle()
	check(feedback.toolbar.visible,"Mouse-ignoring local entry cannot remove fallback")
	button.mouse_filter=old_mouse_filter; await settle()
	check(not feedback.toolbar.visible,"Restoring the original mouse filter restores local-entry suppression")
	var old_process_mode: int = button.process_mode
	button.process_mode=Node.PROCESS_MODE_DISABLED; await settle()
	check(feedback.toolbar.visible,"Non-processing local entry cannot remove fallback")
	button.process_mode=old_process_mode; await settle()
	check(not feedback.toolbar.visible,"Restoring the original process mode restores local-entry suppression")
	button.position.x=290; await settle()
	check(feedback.toolbar.visible,"Ancestor clipping cannot remove the only fallback")
	button.position.x=12; button.hide(); await settle()
	check(feedback.toolbar.visible,"Hidden local entry cannot remove fallback")
	button.show(); await settle(); check(not feedback.toolbar.visible,"Restored local entry restores suppression without cached state")
	button.queue_free(); await settle()
	check(feedback.toolbar.visible,"Freed weak entry immediately restores fallback")
	button=root.get_node("PlaytestMoments").make_button(); clip.add_child(button); button.position=Vector2(12,12); button.size=Vector2(180,44)
	button.grab_focus(); await settle(); await stroke(KEY_F8)
	check(feedback.backdrop.visible and feedback.layer.get_parent()==window and not feedback.toolbar.visible,"F8 in the focused Window owns the original panel layer")
	window.queue_free(); await settle(); root.grab_focus(); await settle()
	check(not is_instance_valid(window) and feedback.layer.get_parent()==feedback and not feedback.backdrop.visible and not paused,"Closing a Window returns the feedback layer and pause state safely")
	check(local_button(host).is_visible_in_tree() and not feedback.toolbar.visible,"Returning to the real host re-evaluates its live local entry")
	check(protected_state()==before,"Window switches, hidden/clipped entries and destruction preserve all original authorities")

func local_entry_policy() -> void:
	var mode: Node = root.get_node("GameMode")
	var old_mode: StringName = mode.current_mode
	mode.set_mode(&"test")
	if not prepare_work(): mode.set_mode(old_mode); return
	var nav: Node = root.get_node("TaskNavigation")
	check(change_scene_to_file("res://src/ui/prototype_hub.tscn")==OK,"Original Home supplies the no-local-entry fallback route")
	await settle()
	var feedback: Node = root.get_node("OfflineFeedback")
	check(feedback.toolbar.visible,"Home without a local feedback entry keeps its original global fallback")
	if DisplayServer.get_name()!="headless":
		var before: Dictionary = protected_state()
		await click_entry(feedback.toolbar.get_child(0))
		check(feedback.backdrop.visible and paused,"Actual global fallback mouse entry still opens the same offline panel")
		await stroke(KEY_ESCAPE)
		check(not paused and not feedback.backdrop.visible and feedback.toolbar.visible,"Fallback Escape restores the original global entry")
		check(protected_state()==before,"Global fallback interaction preserves the existing saved work and original authorities")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for task: String in ["chapter_1/cpu_speed","chapter_3/buffers"]:
			check(nav.enter(task),"Real fixed tester navigation opens original host: "+task)
			await settle()
			var host: Control = current_scene
			if host==null: check(false,"Navigation must yield an original host"); continue
			if DisplayServer.get_name()!="headless":
				for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1600,1000)]:
					root.size=dimensions; root.content_scale_size=dimensions; await settle()
					await host_entry(host,locale+"-"+("system" if task.begins_with("chapter_1") else "overlap")+"-"+str(dimensions.x)+"x"+str(dimensions.y))
				if task=="chapter_1/cpu_speed" and locale=="en": await window_entry_policy(host)
			else:
				check(local_button(host)!=null and not root.get_node("OfflineFeedback").toolbar.visible,"Headless source-policy check only; actual footer pointer/capture NOT_RUN")
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null; await settle()
	mode.set_mode(old_mode)
