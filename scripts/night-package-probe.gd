extends Node
## Disclosed controller input in an unchanged export with isolated fresh or cloned QA data.
var checks: Dictionary = {}
var failures: Array[String] = []
var experience: Dictionary = {}
func _ready() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks[label]=ok
	if not ok: failures.append(label); push_error(label)
func settle() -> void:
	for frame: int in 8: await get_tree().process_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw

func key_press(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code; event.physical_keycode=code; event.pressed=down
		if code==KEY_F8: Input.parse_input_event(event)
		else: get_tree().root.push_input(event,true)
		await settle()

func protected_snapshot() -> Dictionary:
	var save: Node = get_node("/root/GlobalSave")
	var second_act: Script = load("res://src/campaign/second_act_tasks.gd")
	var creation_session: Script = load("res://experiments/creation/session.gd")
	var files: Script = load("res://experiments/candidate_session/files.gd")
	var lease: Script = load("res://experiments/candidate_session/writer_lease.gd")
	var paths: Array[String] = [save.storage_path,save.workbench_storage_path,creation_session.launch_path()]
	for path: Variant in second_act.paths().values(): paths.append(str(path))
	var disk: Dictionary = {}
	for path: String in paths:
		disk[path]="absent" if not FileAccess.file_exists(path) else FileAccess.get_sha256(path)
		for transaction: String in files.transaction_paths(path): disk[transaction]=FileAccess.get_sha256(transaction)
		var lock_path: String = lease.lock_path(path)
		disk[lock_path]=DirAccess.dir_exists_absolute(lock_path)
		var owner: String = lock_path.path_join("owner.json")
		disk[owner]="absent" if not FileAccess.file_exists(owner) else FileAccess.get_sha256(owner)
	var state: Dictionary = save._save_snapshot(); state.erase("saved_at_utc")
	return {"game_state":state,"protected_files":disk}

func creative_family() -> bool:
	return str(ProjectSettings.get_setting("candidate/profile","")) in ["Creative20261018","OfflineTeammate-Creative20261018","MeasuredGrowth20261018","OfflineTeammate-MeasuredGrowth20261018"]

func creative_window_key(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode=code; event.physical_keycode=code; event.pressed=down
		Input.parse_input_event(event)
		await settle()

func creative_media(intro: Variant, output: String) -> void:
	var before: Dictionary = protected_snapshot()
	var texture: Texture2D = intro.media_texture
	var goal: String = intro.goal_label.text
	var focus: Control = get_viewport().gui_get_focus_owner()
	check(texture!=null and texture.get_width()>0 and texture.get_height()>0 and intro.media_column.visible,"Creative export imports the actual replaceable Yi Texture2D")
	for missing: Texture2D in [null,ImageTexture.new()]:
		intro.media_texture=missing; await settle()
		check(not intro.media_column.visible and intro.goal_label.text==goal and get_viewport().gui_get_focus_owner()==focus,"Creative missing or empty Yi media keeps native goal and exact focus")
		check(intro.start_button.is_visible_in_tree() and intro.skip_button.is_visible_in_tree(),"Creative media fallback retains actual Begin and Skip controls")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("intro-no-media.png"))==OK,"actual Creative missing-media frame")
	intro.media_texture=texture; await settle()
	check(protected_snapshot()==before,"Creative media replacement grants no progress or save changes")

func creative_saved_work_setup() -> void:
	var session_type: Script = load("res://experiments/creation/session.gd")
	var writer: Variant = session_type.new()
	var opened: Dictionary = writer.open(session_type.launch_path())
	check(opened.get("writable",false),"Creative controller setup owns only its actual embedded creation namespace")
	if not opened.get("writable",false): writer.close(); return
	var trained: Dictionary = writer.train()
	check(trained.get("ok",false),"Creative controller setup actually trains its finite model")
	if not trained.get("ok",false): writer.close(); return
	var transported: Dictionary = writer.transport([0,1,0,2],"predictive")
	check(transported.get("ok",false) and transported.get("lossless",false),"Creative controller setup actually restores its lossless source")
	if not transported.get("ok",false) or not transported.get("lossless",false): writer.close(); return
	check(writer.set_mode("predict").get("ok",false),"Creative controller setup enters prediction through existing permissions")
	var prediction: Dictionary = writer.begin_prediction("practice")
	check(prediction.get("ok",false),"Creative controller setup begins a real prediction round")
	if not prediction.get("ok",false): writer.close(); return
	while not writer.prediction.finished:
		var committed: Dictionary = writer.commit_prediction()
		var revealed: Dictionary = writer.reveal_prediction() if committed.get("ok",false) else {}
		check(committed.get("ok",false) and revealed.get("ok",false),"Creative controller setup commits and reveals a real prediction step")
		if not committed.get("ok",false) or not revealed.get("ok",false): writer.close(); return
	check(writer.set_mode("generate").get("ok",false),"Creative controller setup enters generation through existing permissions")
	var generated: Dictionary = writer.generate()
	check(generated.get("ok",false),"Creative controller setup actually generates its finite output")
	if not generated.get("ok",false): writer.close(); return
	var saved: Dictionary = writer.save_work("Creative package · original saved signal")
	check(saved.get("ok",false),"Creative controller setup saves a legitimate work without fabricating JSON")
	writer.close()
	if not saved.get("ok",false): return
	var path: String = session_type.launch_path()
	var lease_type: Script = load("res://experiments/candidate_session/writer_lease.gd")
	check(not DirAccess.dir_exists_absolute(lease_type.lock_path(path)),"Creative setup releases its writer before read-only Journal review")
	experience["creative_saved_work"]={"work":saved.work,"path":path,"session_sha256":FileAccess.get_sha256(path),"setup":"actual embedded train/lossless transport/prediction/generate/save controller actions; not a normal natural full journey"}
	print("SETUP: actual C/P/G model actions saved one work in the embedded profile; not a normal natural full journey")

func creative_work_review(journal: Variant, phase: String, expected: Dictionary, output: String, tester: bool) -> void:
	var before: Dictionary = protected_snapshot()
	if expected.is_empty():
		check(journal.work_selector.disabled and journal.work_view_button.disabled,"fresh Creative Journal offers no invented saved work")
		check(protected_snapshot()==before,"fresh Creative empty-work review preserves all authorities")
		return
	var selected: int = -1
	for index: int in journal.work_selector.item_count:
		if str(journal.work_selector.get_item_metadata(index))==str(expected.get("id","")): selected=index
	check(selected>=0 and not journal.work_view_button.disabled,phase+" Creative Journal resolves the original real saved id")
	if selected<0: return
	journal.work_selector.select(selected)
	journal.work_view_button.grab_focus(); await creative_window_key(KEY_SPACE)
	var exhibit: Variant = journal.work_focus
	check(is_instance_valid(exhibit) and exhibit.visible,phase+" Creative actual Journal action opens the original saved-work Window")
	if not is_instance_valid(exhibit): return
	check(JSON.stringify(JSON.parse_string(JSON.stringify(exhibit.work)),"",true)==JSON.stringify(JSON.parse_string(JSON.stringify(expected)),"",true),phase+" Creative viewer preserves the entire original id output recipe training and source snapshot")
	check(exhibit.canvas.output==exhibit.work.output and exhibit.evidence.is_empty() and exhibit.explanation_button.disabled and exhibit.fork_button.disabled,phase+" Creative saved-snapshot viewer supplies no forged generation receipt or editable fork")
	check(exhibit.request_fork.get_connections().is_empty() and exhibit.request_evidence.get_connections().is_empty(),phase+" Creative Journal connects no hidden write or evidence action")
	check(exhibit.find_child("JournalWorkProvenance",true,false).text==journal.work_note.text and exhibit.origin_label.text.contains("no verified generation event" if exhibit.english else "暂无可核对的生成事件"),phase+" Creative actual viewer retains saved-only provenance and unknown event evidence")
	check(exhibit.get_texture().get_image().save_png(output.path_join("saved-work"+("-restarted" if phase=="restarted" else "")+".png"))==OK,phase+" actual Creative saved-work frame")
	exhibit.play_button.grab_focus(); await creative_window_key(KEY_SPACE)
	var feedback: Node = get_node("/root/OfflineFeedback")
	var moments: Node = get_node("/root/PlaytestMoments")
	var was_paused: bool = get_tree().paused
	await creative_window_key(KEY_F8)
	var panel: Control = feedback.panel if tester else moments.panel
	var focus: Control = exhibit.gui_get_focus_owner()
	check(panel.visible and panel.get_viewport()==exhibit and focus!=null and panel.is_ancestor_of(focus) and not exhibit.playing,phase+" Creative saved-work F8 pauses presentation in the actual focused Window")
	check((feedback.backdrop.visible and get_tree().paused) if tester else (not feedback.backdrop.visible and get_tree().paused==was_paused),phase+" Creative saved-work feedback respects the exact role pause channel")
	await creative_window_key(KEY_ESCAPE)
	check(is_instance_valid(exhibit) and exhibit.visible and journal.visible and not (feedback.backdrop.visible if tester else moments.panel.visible) and not panel.is_visible_in_tree() and get_tree().paused==was_paused,phase+" Creative first Escape closes feedback while retaining the saved work and Journal")
	if not is_instance_valid(exhibit): return
	check(exhibit.gui_get_focus_owner()==exhibit.play_button and not exhibit.playing,phase+" Creative feedback restores original saved-work focus without autoplay")
	await creative_window_key(KEY_ESCAPE)
	check(not is_instance_valid(journal.work_focus) and journal.visible and get_viewport().gui_get_focus_owner()==journal.work_view_button,phase+" Creative next Escape returns to the exact Journal work action")
	check(protected_snapshot()==before,phase+" Creative saved-work review and feedback preserve exact protected states bytes and leases")
	experience[phase+"_work_review"]={"id":expected.id,"snapshot_only":true,"evidence":{},"fork_disabled":true,"source":"actual embedded saved work, not the tester child namespace"}

func creative_reflection(journal: Variant, phase: String, earned: bool, output: String, tester: bool) -> void:
	var before: Dictionary = protected_snapshot()
	journal.reflection_button.grab_focus(); journal.reflection_button.pressed.emit(); await settle()
	var dialog: Variant = journal.reflection_dialog
	check(is_instance_valid(dialog) and dialog.visible and is_instance_valid(dialog.first_light),phase+" Creative Journal opens its actual derived Reflection")
	if not is_instance_valid(dialog) or not is_instance_valid(dialog.first_light): return
	var light: Variant = dialog.first_light
	check(light.visible==earned and not light.has_started and not light.playing,phase+" Creative FirstLight is optional and requires actual earned tutorial")
	if not earned:
		light.play_button.pressed.emit()
		check(not light.has_started,"fresh Creative click cannot bypass the earned FirstLight guard")
	elif phase!="restarted":
		var scroll := dialog.body_column.get_parent() as ScrollContainer
		scroll.ensure_control_visible(light.play_button); await settle()
		light.play_button.grab_focus(); await creative_window_key(KEY_SPACE)
		check(light.has_started and light.scene_body.visible and dialog.gui_get_focus_owner()==light.play_button,"earned Creative actual Play reveals the scene without changing focus")
		for control: Control in [light.canvas,light.caption,light.skip_button]:
			var clip: Rect2 = dialog.get_visible_rect()
			var ancestor: Node = control.get_parent()
			while ancestor!=null:
				if ancestor is Control and ancestor.clip_contents: clip=clip.intersection(ancestor.get_global_rect())
				ancestor=ancestor.get_parent()
			check(control.is_visible_in_tree() and clip.grow(1).encloses(control.get_global_rect()),"Creative Play automatically reveals "+str(control.get_class())+" within all original scroll clips")
		check(dialog.get_texture().get_image().save_png(output.path_join("first-light-playing.png"))==OK,"actual Creative FirstLight frame without a QA reveal scroll")
		var feedback: Node = get_node("/root/OfflineFeedback")
		var moments: Node = get_node("/root/PlaytestMoments")
		var was_paused: bool = get_tree().paused
		await creative_window_key(KEY_F8)
		var panel: Control = feedback.panel if tester else moments.panel
		var focus: Control = dialog.gui_get_focus_owner()
		check(panel.visible and panel.get_viewport()==dialog and focus!=null and panel.is_ancestor_of(focus),"Creative FirstLight F8 uses the actual focused Window and role feedback channel")
		check((feedback.backdrop.visible and get_tree().paused) if tester else (not feedback.backdrop.visible and get_tree().paused==was_paused),"Creative FirstLight preserves ordinary versus tester pause behavior")
		var held: float = light.elapsed
		await get_tree().create_timer(0.12,true).timeout
		check(light.elapsed==held,"Creative FirstLight animation pauses under its real feedback panel")
		await creative_window_key(KEY_ESCAPE)
		check(is_instance_valid(dialog) and dialog.visible and not feedback.backdrop.visible and not moments.panel.visible and get_tree().paused==was_paused and dialog.gui_get_focus_owner()==light.play_button,"Creative first Escape closes feedback only and restores exact Play focus")
		light.skip_button.pressed.emit()
		check(not light.playing and light.elapsed==light.DURATION and light.caption.text.contains("output 0" if light.english else "输出0"),"Creative Skip retains the actual fixed NOT output-zero ending")
		var old_motion: Variant = ProjectSettings.get_setting("game/reduced_motion",false)
		ProjectSettings.set_setting("game/reduced_motion",true)
		light.play_button.pressed.emit()
		check(not light.playing and light.elapsed==light.DURATION,"Creative reduced-motion Replay gives the equivalent static ending")
		ProjectSettings.set_setting("game/reduced_motion",old_motion)
		await settle()
		check(dialog.get_texture().get_image().save_png(output.path_join("first-light-static.png"))==OK,"actual Creative static FirstLight frame")
	await creative_window_key(KEY_ESCAPE)
	check(not is_instance_valid(dialog) and journal.visible,phase+" Creative next Escape returns from Reflection to Journal")
	check(protected_snapshot()==before,phase+" Creative Reflection media and feedback preserve all protected authorities")
	experience[phase+"_first_light"]={"earned":earned,"source":"actual Journal milestones and saved tutorial","autoplay":false,"rendered_playback":earned and phase!="restarted"}

func feedback_over_review(review: Control, label: String, tester: bool) -> void:
	var feedback: Node = get_node("/root/OfflineFeedback")
	var moments: Node = get_node("/root/PlaytestMoments")
	var focus: Control = get_viewport().gui_get_focus_owner()
	var was_paused: bool = get_tree().paused
	var before: Dictionary = protected_snapshot()
	await key_press(KEY_F8)
	if tester:
		check(feedback.backdrop.visible and get_tree().paused and review.visible,label+" tester F8 opens actual offline overlay")
	else:
		check(moments.panel.visible and not feedback.backdrop.visible and get_tree().paused==was_paused,label+" normal F8 opens its own voluntary panel")
	check(review.visible,label+" feedback preserves its underlying review")
	await key_press(KEY_ESCAPE)
	check(not feedback.backdrop.visible and not moments.panel.visible and get_tree().paused==was_paused and review.visible,label+" Escape dismisses only actual feedback")
	check(get_viewport().gui_get_focus_owner()==focus,label+" feedback restores exact review focus")
	check(protected_snapshot()==before,label+" feedback preserves game candidate and workspace authorities")
	experience[label+"_feedback"]="offline tester F8 controller" if tester else "ordinary voluntary F8 controller"

func review_experience(host: Control, earned: bool, output: String, tester: bool) -> void:
	var phase: String = "earned" if earned else "fresh"
	var before: Dictionary = protected_snapshot()
	var launcher := host.find_child("OpenJourneyJournal",true,false) as Button
	check(launcher!=null,phase+" actual Journal launcher exists")
	if launcher==null: return
	launcher.grab_focus(); launcher.pressed.emit(); await settle()
	var journal: Variant = host.journey_journal
	check(is_instance_valid(journal) and journal.visible and journal.rows.size()==60,phase+" Journal reads actual exported sixty-task catalog")
	journal.show_task("hardware_foundations/tutorial")
	var has_fragment: bool = not journal.civilization_fragment(journal.selected_task()).is_empty()
	check(journal.earned(journal.selected_task())==earned and has_fragment==earned,phase+" tutorial retrospective derives only from real completion")
	journal.show_task("hardware_foundations/half_adder")
	check(not journal.earned(journal.selected_task()) and journal.civilization_fragment(journal.selected_task()).is_empty(),phase+" accessible half-adder grants no earned retrospective")
	journal.show_task("unknown/task")
	check(journal.selected_task().is_empty() and journal.enter_button.disabled,phase+" unknown Journal identity remains unconfirmed")
	journal.show_task("hardware_foundations/tutorial"); await settle()
	if creative_family():
		await creative_reflection(journal,phase,earned,output,tester)
		await creative_work_review(journal,phase,experience.get("creative_saved_work",{}).get("work",{}),output,tester)
	if earned:
		check(get_viewport().get_texture().get_image().save_png(output.path_join("journal.png"))==OK,"actual exported earned Journal frame")
		journal.help_button.grab_focus(); journal.help_button.pressed.emit(); await settle()
		check(journal.handbook.is_open(),"actual earned Journal opens existing handbook")
		await feedback_over_review(journal,"journal",tester)
		check(journal.handbook.is_open(),"feedback preserves nested Journal handbook")
		await key_press(KEY_ESCAPE)
		check(journal.visible and not journal.handbook.is_open() and get_viewport().gui_get_focus_owner()==journal.help_button,"Journal Escape closes handbook before Journal")
	await key_press(KEY_ESCAPE)
	check(not journal.visible and get_viewport().gui_get_focus_owner()==launcher,phase+" Journal closes to its actual launcher")
	check(protected_snapshot()==before,phase+" Journal browsing preserves exact protected authorities")
	launcher=host.find_child("OpenJourneyObservatory",true,false) as Button
	check(launcher!=null,phase+" actual Observatory launcher exists")
	if launcher==null: return
	launcher.grab_focus(); launcher.pressed.emit(); await settle()
	var observatory: Variant = host.journey_observatory
	check(is_instance_valid(observatory) and observatory.visible and observatory.rows.size()==60,phase+" Observatory reads actual exported catalog")
	check(observatory.viewport_3d.own_world_3d and observatory.camera is Camera3D,phase+" Observatory owns a real isolated 3D camera and world")
	for region: int in observatory.region_choice.item_count:
		if int(observatory.region_choice.get_item_metadata(region))==0:
			observatory.region_choice.select(region); observatory.region_choice.item_selected.emit(region); break
	observatory.select_task("hardware_foundations/tutorial"); await settle()
	var selected: Dictionary = {}
	for row: Dictionary in observatory.region_rows:
		if str(row.key)=="hardware_foundations/tutorial": selected=row
	check(not selected.is_empty() and observatory.earned(selected)==earned and observatory.task_status.text.contains("✓")==earned,phase+" actual tutorial lamp derives from real accepted record")
	check(observatory.geometry.find_children("*","OmniLight3D",true,false).size()==(1 if earned else 0),phase+" geometry lights exactly the genuinely earned tutorial")
	var world: Image = observatory.viewport_3d.get_texture().get_image()
	var colors: Dictionary = {}
	if not world.is_empty():
		for y: int in range(0,world.get_height(),16):
			for x: int in range(0,world.get_width(),16): colors[world.get_pixel(x,y).to_html()]=true
	check(not world.is_empty() and colors.size()>5,phase+" exported 3D texture contains rendered geometry rather than a flat image")
	var world_path: String = output.path_join("observatory-"+phase+"-3d.png")
	check(not world.is_empty() and world.save_png(world_path)==OK,phase+" actual exported 3D texture saved")
	experience[phase+"_world"]={"file":world_path.get_file(),"sha256":FileAccess.get_sha256(world_path),"dimensions":str(world.get_size()),"sampled_colors":colors.size(),"task":observatory.selected_key,"earned":earned}
	if earned:
		check(get_viewport().get_texture().get_image().save_png(output.path_join("observatory.png"))==OK,"actual exported earned Observatory frame")
		await feedback_over_review(observatory,"observatory",tester)
	for view: int in 3:
		observatory.view_choice.select(view); observatory.view_choice.item_selected.emit(view); await settle()
	await key_press(KEY_ESCAPE)
	check(not observatory.visible and get_viewport().gui_get_focus_owner()==launcher,phase+" Observatory closes to its actual launcher")
	check(protected_snapshot()==before,phase+" 3D browsing and view changes preserve exact protected authorities")

func measured_state() -> Dictionary:
	var nav: Node = get_node("/root/TaskNavigation")
	var lease: Script = load("res://experiments/candidate_session/writer_lease.gd")
	var creation: Script = load("res://experiments/creation/session.gd")
	return {"protected":protected_snapshot(),"selected":nav.selected,"pending":nav.pending,"from_tree":nav.from_tree,
		"best":get_node("/root/PersonalRecords").best.duplicate(true),
		"creation_recovery_lock":DirAccess.dir_exists_absolute(lease.lock_path(creation.launch_path())+".recovering")}

func measured_visible(control: Control) -> bool:
	var clip: Rect2 = get_viewport().get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor!=null:
		if ancestor is Control and ancestor.clip_contents: clip=clip.intersection(ancestor.get_global_rect())
		ancestor=ancestor.get_parent()
	return control.is_visible_in_tree() and clip.grow(1).encloses(control.get_global_rect())

func measured_context(host: Control) -> Dictionary:
	return {"authorities":measured_state(),
		"design":host.get("design").duplicate(true) if host.get("design") is Dictionary else {},
		"board":host.get("board").duplicate(true) if host.get("board") is Dictionary else {},
		"program":host.editor.text if host.get("editor")!=null else ""}

func measured_reveal(control: Control) -> void:
	var ancestor: Node = control.get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(control)
		ancestor=ancestor.get_parent()
	await settle()
	check(measured_visible(control),"Measured action reachable within every original ancestor clip: "+str(control.name))

func measured_frame(output: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = output.path_join(name+".png")
	var image: Image = get_viewport().get_texture().get_image()
	check(not image.is_empty() and image.save_png(path)==OK,"Actual exported Measured frame "+name)
	var frames: Array = experience.get("measured_frames",[])
	frames.append({"file":name+".png","sha256":FileAccess.get_sha256(path),"dimensions":[image.get_width(),image.get_height()]})
	experience["measured_frames"]=frames

func measured_feedback(action: Control, label: String, tester: bool, output: String, host: Control) -> void:
	await measured_reveal(action)
	action.grab_focus()
	var before: Dictionary = measured_context(host)
	var previous_pause: bool = get_tree().paused
	await creative_window_key(KEY_F8)
	var offline: Node = get_node("/root/OfflineFeedback")
	var moments: Node = get_node("/root/PlaytestMoments")
	var panel: Control = offline.panel if tester else moments.panel
	check((offline.backdrop.visible if tester else moments.panel.visible) and panel.is_visible_in_tree() and panel.get_viewport()==get_viewport() and panel.is_ancestor_of(get_viewport().gui_get_focus_owner()),label+" actual role F8 owns the original viewport and focus")
	check(get_tree().paused if tester else get_tree().paused==previous_pause,label+" retains the original role pause contract")
	if tester: check(not offline.current.is_empty() and offline.current.get("screenshot_status","")=="captured",label+" retains an actual local pre-overlay incident")
	await measured_frame(output,label+"-feedback")
	await creative_window_key(KEY_ESCAPE)
	check(not (offline.backdrop.visible if tester else moments.panel.visible) and not panel.is_visible_in_tree() and get_tree().paused==previous_pause and get_viewport().gui_get_focus_owner()==action,label+" first Escape closes only feedback and restores exact action focus")
	check(measured_context(host)==before,label+" feedback preserves original works game draft navigation and locks")

func measured_apparatus(output: String, tester: bool) -> void:
	check(get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")==OK,"Measured actual Home loads")
	await settle()
	var hub: Variant = get_tree().current_scene
	var launcher := hub.find_child("OpenJourneyObservatory",true,false) as Button
	check(launcher!=null,"Measured actual Home keeps the Observatory launcher")
	if launcher==null: return
	launcher.grab_focus(); launcher.pressed.emit(); await settle()
	var view: Variant = hub.journey_observatory
	var before: Dictionary = measured_state()
	for index: int in view.region_choice.item_count:
		if int(view.region_choice.get_item_metadata(index))==0:
			view.region_choice.select(index); view.region_choice.item_selected.emit(index); break
	view.select_task("hardware_foundations/tutorial"); await settle()
	if not measured_require(view.selected_key=="hardware_foundations/tutorial" and view.earned(view.region_rows[view.task_choice.selected]),"Measured apparatus binds only the actually completed tutorial"): return
	var pose: Transform3D = view.camera.transform
	var camera_size: float = view.camera.size
	var shapes: Array = []
	for node: Node3D in view.apparatus_nodes:
		var meshes: Array = []
		for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false): meshes.append([mesh.get_path(),mesh.transform,mesh.get_aabb()])
		shapes.append({"pose":node.transform,"meshes":meshes,"task":node.get_meta("task_key"),"earned":node.get_meta("earned")})
	await measured_reveal(view.inspect_button)
	view.inspect_button.grab_focus(); await creative_window_key(KEY_SPACE)
	check(view.inspection_enabled and view.camera.size<camera_size and view.selected_key=="hardware_foundations/tutorial","Measured actual Inspect frames the same source task")
	for index: int in view.apparatus_nodes.size():
		var selected: bool = str(view.region_rows[index].key)==view.selected_key
		check(str(view.apparatus_nodes[index].get_meta("task_key"))==str(view.region_rows[index].key),"Measured apparatus retains its exact source task binding "+str(index))
		check(view.apparatus_nodes[index].visible==selected and view.marker_buttons[index].visible==selected,"Measured near view contains only the selected original apparatus "+str(index))
	await measured_frame(output,"apparatus-near")
	await measured_feedback(view.overview_button,"apparatus",tester,output,view)
	view.overview_button.grab_focus(); await creative_window_key(KEY_SPACE)
	check(not view.inspection_enabled and view.camera.transform.is_equal_approx(pose) and is_equal_approx(view.camera.size,camera_size) and view.selected_key=="hardware_foundations/tutorial","Measured Overview restores the original camera and task")
	for index: int in shapes.size():
		var node: Node3D = view.apparatus_nodes[index]
		var meshes: Array = []
		for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false): meshes.append([mesh.get_path(),mesh.transform,mesh.get_aabb()])
		check({"pose":node.transform,"meshes":meshes,"task":node.get_meta("task_key"),"earned":node.get_meta("earned")}==shapes[index],"Measured framing preserves original apparatus shape and source "+str(index))
	check(measured_state()==before,"Measured near and restore never change authoritative content or navigation")
	await measured_frame(output,"apparatus-overview")
	await creative_window_key(KEY_ESCAPE)
	check(not view.visible and get_viewport().gui_get_focus_owner()==launcher,"Measured Observatory returns to its exact real Home launcher")
	get_tree().current_scene=null; hub.queue_free(); await settle()

func measured_require(ok: bool, label: String) -> bool:
	check(ok,label)
	if not ok: get_tree().quit(1)
	return ok

func measured_json_equal(a: Variant, b: Variant) -> bool:
	return JSON.stringify(JSON.parse_string(JSON.stringify(a)),"",true)==JSON.stringify(JSON.parse_string(JSON.stringify(b)),"",true)

func measured_original_work(seed: Dictionary) -> bool:
	var session: Script = load("res://experiments/creation/session.gd")
	var lease: Script = load("res://experiments/candidate_session/writer_lease.gd")
	return FileAccess.get_sha256(session.launch_path())==str(seed.original_saved_work.session_sha256) and not DirAccess.dir_exists_absolute(lease.lock_path(session.launch_path())) and not DirAccess.dir_exists_absolute(lease.lock_path(session.launch_path())+".recovering")

func measured_host(scene: String, task: String) -> Control:
	var navigation: Node = get_node("/root/TaskNavigation")
	if not measured_require(navigation.enter(task),"Measured original navigation legally enters "+task): return null
	await settle()
	var host: Control = get_tree().current_scene
	if not measured_require(is_instance_valid(host) and host.scene_file_path==scene,"Measured entered Host matches "+task): return null
	return host

func measured_finish_hardware(host: Control) -> bool:
	var frames: int = 0
	while host.official_sequence_active and frames<128:
		if host.playback_running: host._finish_playback()
		await get_tree().process_frame
		frames+=1
	return measured_require(not host.official_sequence_active and host.official_passed and host.passing_topology_signature==host._circuit_from_graph().canonical_signature(),"Measured original official aggregate verifies the exact hardware topology "+str(host.current_level_id))

func measured_hardware_report(report: Dictionary, half: bool = false) -> Dictionary:
	var rows: Array = []
	for item: Dictionary in report.get("cases" if half else "steps",[]):
		var trace: Variant = item.get("trace" if half else "result")
		rows.append({"passed":bool(item.get("passed",false)),"trace_signature":trace.canonical_signature() if trace!=null else ""})
	return {"passed":bool(report.get("passed",false)),"cases":rows}

func measured_hardware(seed: Dictionary) -> bool:
	var host: Variant = await measured_host("res://src/hardware_foundations/hardware_foundations.tscn","hardware_foundations/half_adder")
	if host==null: return false
	host._start_challenge(false); await settle()
	if not measured_require(host.current_level_id==&"half_adder" and host.current_phase==&"half_adder" and not host.hint_mode,"Measured HalfAdder is the original editable task"): return false
	for wire: Dictionary in host._half_adder_reference_wires():
		host._on_connection_request(wire.from_node,int(wire.from_port),wire.to_node,int(wire.to_port))
	host._run_official()
	if not await measured_finish_hardware(host): return false
	if not measured_require(host.official_report.get("passed",false),"Measured HalfAdder official cases really pass"): return false
	var steps: Array = [{"task":"half_adder","circuit_signature":host._circuit_from_graph().canonical_signature(),"report":measured_hardware_report(host.official_report,true)}]
	host._dismiss_level_completion(); host._seal_half_adder()
	if not measured_require(host.sealing,"Measured verified HalfAdder starts original sealing"): return false
	host._finish_encapsulation(); await settle()
	for id: StringName in [&"full_adder",&"alu",&"latch",&"register",&"ram",&"cpu",&"load_store"]:
		host._start_prologue_level(id,false); await settle()
		if not measured_require(host.current_level_id==id and host.current_phase==&"prologue" and not host.hint_mode,"Measured original hardware prerequisite opens "+str(id)): return false
		if not host.current_level_definition.get("locked_topology",false):
			for wire: Dictionary in host.current_level_definition.get("reference_wires",[]):
				host._on_connection_request(wire["from"],int(wire.get("from_port",0)),wire["to"],int(wire.get("to_port",0)))
		var circuit: Variant = host._circuit_from_graph()
		if not measured_require(not host._uses_offline_reference(circuit),"Measured owned components avoid tester reference provenance "+str(id)): return false
		host._run_official()
		if not await measured_finish_hardware(host): return false
		if not measured_require(host.prologue_report.get("passed",false),"Measured original prologue model cases pass "+str(id)): return false
		steps.append({"task":String(id),"circuit_signature":circuit.canonical_signature(),"report":measured_hardware_report(host.prologue_report)})
		if id!=&"load_store":
			host._dismiss_level_completion(); host._seal_prologue_component()
			if not measured_require(host.sealing,"Measured verified original component starts sealing "+str(id)): return false
			host._finish_encapsulation(); await settle()
		if not measured_require(host.player_content.completed_levels.get(id,false) and measured_original_work(seed),"Measured original sealing earns only real hardware and preserves existing work "+str(id)): return false
	var chapter: Node = get_node("/root/SystemChapter")
	if not measured_require(chapter.prologue_ready and not chapter.cpu_source_signature.begins_with("reference-") and not chapter.ram_source_signature.begins_with("reference-"),"Measured LOAD STORE hands verified owned CPU RAM to the real System chapter"): return false
	for component: Variant in host.player_content.component_library.values():
		if not measured_require(component.source_level!=&"tester_reference" and not component.metadata.get("tester_reference",false),"Measured earned library has no tester reference component"): return false
	experience["measured_hardware_preparation"]={"steps":steps,"manifest":host.player_content.manifest_snapshot(),"cpu_source_signature":chapter.cpu_source_signature,"ram_source_signature":chapter.ram_source_signature,"scope":"public reference wiring submitted through original official models and sealing actions in disposable clone; not an unaided player solution"}
	host._stop_playback(); get_tree().current_scene=null; host.queue_free(); await settle()
	return true

func measured_flush() -> Dictionary:
	get_tree().call_group("workspace_owners","flush_workspace")
	get_node("/root/WindowMode")._save_window_geometry()
	var save: Node = get_node("/root/GlobalSave")
	if not measured_require(save.save_game(true),"Measured original save APIs persist the exact legitimate preparation"): return {}
	var disk: Dictionary = {}
	for name: String in ["savegame_v1.json","savegame_v1.json.bak","hardware_workbenches_v1.json","personal_task_records_v1.json","task_navigation.cfg","presentation.cfg"]:
		var path: String = "user://"+name
		disk[name]={"sha256":FileAccess.get_sha256(path),"text":FileAccess.get_file_as_string(path)} if FileAccess.file_exists(path) else {"absent":true}
	return {"protected":protected_snapshot(),"disk":disk,"best":get_node("/root/PersonalRecords").best.duplicate(true),"last_visited_task":get_node("/root/TaskNavigation").last_visited_task,"window_geometry":{"fullscreen":get_node("/root/WindowMode").is_fullscreen(),"size":var_to_str(DisplayServer.window_get_size()),"position":var_to_str(DisplayServer.window_get_position())}}

func measured_cpu(output: String, tester: bool) -> void:
	var chapter: Node = get_node("/root/SystemChapter")
	var host: Variant = await measured_host("res://src/system_lab/system_lab.tscn","chapter_1/assembly")
	if host==null: return
	if not measured_require(host.current_level_id==&"assembly","Measured real hardware gate permits System assembly"): return
	host._auto_connect(); host._run_official(); host._finish_playback(); await settle()
	if not measured_require(host.graph.get_connection_list().size()==6 and host.latest_receipt!=null and host.latest_receipt.all_passed and chapter.completed_levels().get(&"assembly",false),"Measured original six-route assembly passes official cases before CPU entry"): return
	experience["measured_assembly_preparation"]={"receipt_signature":host.latest_receipt.canonical_signature(),"metrics":host.latest_receipt.metrics.duplicate(true),"topology_signature":host._topology_from_graph().canonical_signature(),"program_signature":host.latest_receipt.program_signature,"test_set_signature":host.latest_receipt.test_set_signature,"source":host.applied_program_source,"parts":host.selected_part_ids.duplicate(true)}
	host._dismiss_level_completion(); host._start_level(&"cpu_speed"); await settle()
	if not measured_require(host.current_level_id==&"cpu_speed" and host.prediction_selector.item_count>1 and host.part_selectors[&"cpu"].item_count>1,"Measured CPU task is legally initialized before any selection"): return
	host.prediction_selector.select(1); host._lock_prediction()
	host._run_official(); host._finish_playback(); await settle()
	if not measured_require(chapter.receipts_for(&"cpu_speed").size()==1 and not chapter.completed_levels().get(&"cpu_speed",false) and not host.efficiency_fragment.visible,"Measured single actual reference run supplies no comparison"): return
	host.part_selectors[&"cpu"].select(1); host._on_part_selected(1,&"cpu")
	host._run_official(); host._finish_playback(); await settle()
	var receipts: Array = chapter.receipts_for(&"cpu_speed")
	if not measured_require(receipts.size()==2 and receipts[0].all_passed and receipts[1].all_passed and chapter.completed_levels().get(&"cpu_speed",false),"Measured owned CPU pair is accepted only after two real official model runs"): return
	if receipts.size()!=2: host.queue_free(); await settle(); return
	var fragment: Variant = host.efficiency_fragment
	if not measured_require(fragment.before.metrics==receipts[0].metrics and fragment.after.metrics==receipts[1].metrics and not fragment.body.visible,"Measured fragment derives exactly the original pair without autoplay"): return
	check(host.history_chart.samples[0]==receipts[0].metrics and host.history_chart.samples[1]==receipts[1].metrics,"Measured original comparison chart retains the same two actual samples")
	host._dismiss_level_completion()
	for id: StringName in host.instrument_windows: host._close_instrument(id)
	host._open_instrument(&"history"); await settle()
	experience["measured_cpu_prepared"] = measured_flush()
	var before: Dictionary = measured_context(host)
	var receipt_signatures: Array = [receipts[0].canonical_signature(),receipts[1].canonical_signature()]
	await measured_reveal(fragment.toggle_button)
	fragment.toggle_button.grab_focus(); await creative_window_key(KEY_SPACE)
	check(fragment.body.visible and measured_visible(fragment.source_label) and measured_visible(fragment.metric_label),"Measured real fragment expansion reveals its original identity and numbers")
	for step: int in 3:
		await measured_reveal(fragment.step_buttons[step])
		fragment.step_buttons[step].grab_focus(); await creative_window_key(KEY_SPACE)
		check(fragment.step==step,"Measured original fragment step "+str(step))
	check(fragment.before.source=="game" and fragment.after.source=="game" and (fragment.source_label.text.contains("原运行记录") if not fragment.english else fragment.source_label.text.contains("Original run records")),"Measured pair is explicitly bound to its actual record source")
	await measured_frame(output,"cpu-controlled-pair")
	await measured_reveal(fragment.chart_button)
	fragment.chart_button.grab_focus(); await creative_window_key(KEY_SPACE)
	check(not fragment.body.visible and measured_visible(host.history_chart),"Measured fragment returns to the unchanged original same-scale chart")
	fragment.toggle_button.grab_focus(); await creative_window_key(KEY_SPACE)
	await measured_feedback(fragment.step_buttons[2],"cpu-fragment",tester,output,host)
	await creative_window_key(KEY_ESCAPE)
	check(not fragment.body.visible and get_viewport().gui_get_focus_owner()==fragment.toggle_button,"Measured second Escape collapses only the focused fragment")
	check(measured_context(host)==before and [receipts[0].canonical_signature(),receipts[1].canonical_signature()]==receipt_signatures,"Measured fragment exploration preserves both reference receipts and all original authorities")
	experience["measured_cpu_pair"]={"before":host._efficiency_record(receipts[0]),"after":host._efficiency_record(receipts[1]),"scope":"real game-mode official CPU runs after controller-wired and officially sealed hardware; QA solved setup, not unaided player progress"}
	host.flush_workspace()
	experience["measured_system_workspaces"]={"assembly":chapter.workspace_for(&"assembly"),"cpu_speed":chapter.workspace_for(&"cpu_speed")}
	get_tree().current_scene=null; host.queue_free(); await settle()

func measured_targets(output: String, tester: bool) -> void:
	var layout: Script = load("res://src/layout_chapter/layout_catalog.gd")
	var overlap: Script = load("res://src/overlap_chapter/overlap_catalog.gd")
	var host: Variant = await measured_host("res://src/layout_chapter/layout_chapter.tscn","chapter_4/fields")
	if not measured_require(host!=null and host.level=="fields","Measured Layout uses the original fields contract"): return
	host.design=layout.starter_design(); host._changed(); host._run_all(); await settle()
	if not measured_require(not host.runs.is_empty(),"Measured original Layout model produced its actual cases"): return
	var run: Variant = host.runs[0]
	var task: Dictionary = layout.cases("fields")[0]
	var traffic: int = int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes)
	check(run.passed and not run.metrics.target_met and traffic>int(task.target_bytes),"Measured actual Layout output is correct but RAM traffic exceeds its public cap")
	var text: String = host._case_contract_feedback(run,task)
	check(text.contains(str(traffic)) and text.contains(str(task.target_bytes)) and text.contains(str(traffic-int(task.target_bytes))),"Measured Layout explains the actual traffic cap and difference")
	var action := host.find_child("LayoutLocateIssue0",true,false) as Button
	if not measured_require(action!=null,"Measured original Layout exposes its witness action"): return
	host._toggle("trace",true); await settle()
	await measured_reveal(action)
	var before: Dictionary = measured_context(host)
	var signature: String = run.canonical_signature()
	action.grab_focus(); await creative_window_key(KEY_SPACE)
	check(host.case_index==0 and host.trace_filter==0 and not host.trace_list.get_selected_items().is_empty() and run.canonical_signature()==signature,"Measured Layout action locates the same original event without changing its trace")
	check(measured_context(host)==before,"Measured Layout location preserves original work draft and earned history")
	await measured_frame(output,"layout-traffic-witness")
	await measured_feedback(action,"layout-guidance",tester,output,host)
	check(run.canonical_signature()==signature,"Measured Layout feedback preserves the original trace")
	host._move_group(0,host.design.recipe.groups.size()); await settle()
	check(host.stale and action.disabled,"Measured actual Layout edit disables old location")
	host.flush_workspace()
	experience["measured_layout_preparation"]={"draft":get_node("/root/LayoutChapter").drafts()["fields"].duplicate(true),"run_signature":run.canonical_signature(),"passed":run.passed,"target_met":run.metrics.target_met}
	get_tree().current_scene=null; host.queue_free(); await settle()
	host=await measured_host("res://src/overlap_chapter/overlap_chapter.tscn","chapter_3/backpressure")
	if not measured_require(host!=null and host.level=="backpressure","Measured Overlap uses the original changed-workload contract"): return
	host.board=overlap.buffer_board(2)
	host.editor.text=overlap.buffer_program().replace("consume A\nfree A","consume A\ntick 8\nfree A")
	host._changed(); host._run_official(); await settle()
	if not measured_require(host.runs.size()==2,"Measured original Overlap model produced both actual workloads"): return
	var tasks: Array[Dictionary] = overlap.cases("backpressure")
	check(host.runs[0].passed and int(host.runs[0].metrics.total_cycles)<=int(tasks[0].target) and host.runs[1].passed and int(host.runs[1].metrics.total_cycles)>int(tasks[1].target),"Measured unchanged model meets only the first workload cap")
	check(host.case_select.selected==1 and host.trace==host.runs[1] and host.trace.test_name==str(tasks[1].name),"Measured first unmet selection synchronizes actual dropdown identity and trace")
	check(host.metrics.text.contains(str(int(host.trace.metrics.total_cycles)-int(tasks[1].target))),"Measured later-case result shows its actual cycle difference")
	host._toggle("trace",true); await settle(); await measured_reveal(host.locate_issue_button)
	before=measured_context(host)
	host.locate_issue_button.grab_focus(); await creative_window_key(KEY_SPACE)
	check(not host.events.get_selected_items().is_empty() and int(host.scrub.value)==int(host.events.get_item_metadata(host.events.get_selected_items()[0])),"Measured Overlap location synchronizes real event and playback cycle")
	check(measured_context(host)==before,"Measured later-case location changes no original authority or draft")
	await measured_frame(output,"overlap-later-case-witness")
	host.flush_workspace()
	experience["measured_overlap_preparation"]={"backpressure":{"board":host.board.duplicate(true),"program":host.editor.text,"trace_signature":host.trace.canonical_signature()}}
	get_tree().current_scene=null; host.queue_free(); await settle()
	host=await measured_host("res://src/overlap_chapter/overlap_chapter.tscn","chapter_3/buffers")
	if not measured_require(host!=null and host.level=="buffers","Measured original Buffer workload legally opens"): return
	host.board=overlap.buffer_board(1); host.editor.text="# first batch\nfetch A 0\nconsume A\nidle\n"
	host._changed(); host._run_official(); await settle()
	check(host.trace.metrics.error=="not_ready" and int(host.trace.metrics.error_line)==3,"Measured original early-consumption error binds its source line")
	host._toggle("trace",true); await settle(); await measured_reveal(host.locate_issue_button)
	before=measured_context(host)
	host.locate_issue_button.grab_focus(); await creative_window_key(KEY_SPACE)
	check(host.editor.get_caret_line()==2 and get_viewport().gui_get_focus_owner()==host.editor and measured_context(host)==before,"Measured runtime witness selects the original offending line without altering content")
	await measured_frame(output,"overlap-runtime-witness")
	await measured_feedback(host.locate_issue_button,"overlap-guidance",tester,output,host)
	var x: Variant = host.board.nodes.A.x
	host.board.nodes.A.x=float(x)+1.0
	check(not host._recorded_issue_is_current(),"Measured changed board rejects the old line even with identical code")
	var caret: int = host.editor.get_caret_line()
	var focus: Control = get_viewport().gui_get_focus_owner()
	host._locate_recorded_issue()
	check(host.editor.get_caret_line()==caret and get_viewport().gui_get_focus_owner()==focus,"Measured stale board location cannot steal current focus")
	host.board.nodes.A.x=x
	var edits: Dictionary = {"signals":0}
	host.editor.text_changed.connect(func() -> void: edits.signals+=1)
	host.editor.set_caret_line(host.editor.get_line_count()-1)
	host.editor.set_caret_column(host.editor.get_line(host.editor.get_caret_line()).length())
	host.editor.insert_text_at_caret("# changed\n"); await settle()
	check(int(edits.signals)>0 and host.trace_stale and host.locate_issue_button.disabled,"Measured real CodeEdit insertion invalidates old source guidance")
	host._run_official(); await settle()
	check(host._recorded_issue_is_current() and not host.locate_issue_button.disabled,"Measured rerun binds the actual edited source and board")
	host.flush_workspace()
	experience.measured_overlap_preparation["buffers"]={"board":host.board.duplicate(true),"program":host.editor.text,"trace_signature":host.trace.canonical_signature()}
	get_tree().current_scene=null; host.queue_free(); await settle()

func measured_evidence(output: String, profile: String, tester: bool) -> void:
	check(profile==("OfflineTeammate-MeasuredGrowth20261018" if tester else "MeasuredGrowth20261018"),"Measured supplement requires its exact isolated role profile")
	var save: Node = get_node("/root/GlobalSave")
	var seed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("seed.json")))
	if not measured_require(DisplayServer.get_name()!="headless" and save.loaded_save and save.disk_write_allowed and not get_node("/root/GameMode").is_test_mode(),"Measured ordinary exported launch actually loads its seed in game mode"): return
	var before: Dictionary = protected_snapshot()
	if not measured_require(measured_json_equal(before.game_state,seed.initial_game_state) and save.game_player_content.completed_levels.get(&"tutorial",false) and measured_original_work(seed),"Measured loaded seed retains the original tutorial and exact existing work"): return
	var official: Array[Dictionary] = []
	var remote: Script = load("res://src/playtest/remote_feedback.gd")
	get_node("/root/PlaytestData").official_result.connect(func(event: Dictionary) -> void: official.append({"event":event.duplicate(true),"safe":remote.minimal_context(event)}))
	var initial_best: Dictionary = get_node("/root/PersonalRecords").best.duplicate(true)
	await measured_apparatus(output,tester)
	if not failures.is_empty(): get_tree().quit(1); return
	if not await measured_hardware(seed): return
	await measured_cpu(output,tester)
	if not failures.is_empty(): get_tree().quit(1); return
	var cpu_ready: Dictionary = experience.get("measured_cpu_prepared",{})
	if cpu_ready.is_empty(): return
	if tester:
		await measured_targets(output,tester)
	else:
		var navigation: Node = get_node("/root/TaskNavigation")
		for key: String in ["chapter_4/fields","chapter_3/buffers"]:
			var denied: Dictionary = measured_state()
			check(not navigation.enter(key) and measured_state()==denied,"Measured normal locked target remains gated: "+key)
		experience["measured_targets"]={"status":"NOT_RUN_NORMAL_LOCKED","reason":"Original Locality capstone prerequisite has not been completed; tester has a distinct fixed access contract."}
	if not failures.is_empty(): get_tree().quit(1); return
	var final: Dictionary = measured_flush()
	if final.is_empty(): return
	check(measured_original_work(seed) and not get_node("/root/GameMode").is_test_mode(),"Measured legitimate preparation never changes existing saved work or game-mode authority")
	var receipt: Dictionary = {"checks":checks,"failures":failures,"source_commit":ProjectSettings.get_setting("application/config/build_commit",""),
		"build_id":ProjectSettings.get_setting("application/config/version",""),"profile":profile,"tester":tester,
		"exe_sha256":FileAccess.get_sha256(OS.get_executable_path()),"controller_sha256":FileAccess.get_sha256(get_script().resource_path),
		"parent_controller_sha256":seed.parent_controller_sha256,"protected_before":before,"prepared_cpu":cpu_ready,"prepared_final":final,
		"initial_best":initial_best,"official_events":official,"original_work":seed.original_saved_work.work,
		"original_work_session_sha256":FileAccess.get_sha256(load("res://experiments/creation/session.gd").launch_path()),
		"creation_recovery_lock":measured_state().creation_recovery_lock,"extended_experience":experience,
		"evidence_grade":"actual exported game-mode controller supplement in copied QA data; legal reference wiring and original official/sealing APIs, not an unaided natural journey"}
	var file := FileAccess.open(output.path_join("measured-evidence.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt,"\t")); file.close()
	print("PASS: Measured exported supplemental evidence" if failures.is_empty() else "FAIL: Measured exported supplemental evidence")
	get_tree().quit(0 if failures.is_empty() else 1)

func run() -> void:
	var output: String = str(ProjectSettings.get_setting("qa_night/output",""))
	if output.is_empty() or not OS.get_environment("APPDATA").replace("\\","/").contains("/.godot/night-package/"):
		get_tree().quit(2); return
	get_tree().current_scene=null
	var nav: Node = get_node("/root/TaskNavigation")
	var feedback: Node = get_node("/root/OfflineFeedback")
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	var tester: bool = ProjectSettings.get_setting("playtest/offline_tester",false)==true
	check(profile in (["OfflineTeammate-FullJourney20261018","OfflineTeammate-Creative20261018","OfflineTeammate-MeasuredGrowth20261018"] if tester else ["FullJourney20261018","Creative20261018","MeasuredGrowth20261018"]),"actual embedded full-journey profile")
	check(OS.get_user_data_dir().replace("\\","/").ends_with("/VonNeumannBottleneckCandidates/representation/"+profile),"actual embedded save namespace")
	check(OS.has_feature("free_candidate") and nav.journey_tasks().size()==60,"actual exported full journey configuration")
	check(not get_node("/root/GameMode").is_test_mode(),"ordinary model mode")
	check(get_node("/root/RemoteFeedback").endpoint.is_empty() and not get_node("/root/RemoteFeedback").enabled,"no receiver or automatic upload")
	if str(ProjectSettings.get_setting("qa_night/phase", "capture")) == "measured":
		await measured_evidence(output,profile,tester); return
	if str(ProjectSettings.get_setting("qa_night/phase", "capture")) == "reopen":
		await reopen_embedded_profile(output,profile,tester); return
	var unavailable: int = 0
	for task: Dictionary in nav.tasks():
		if not task.unlocked: unavailable+=1
	check(unavailable==0 if tester else unavailable>0,"tester and normal progression remain distinct")
	check(get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")==OK,"actual Home loads")
	await settle()
	var hub: Variant = get_tree().current_scene
	check(str(hub.find_child("BuildIdentifier",true,false).text).contains(str(ProjectSettings.get_setting("application/config/version",""))),"visible build identity belongs to this export")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("home.png"))==OK,"actual exported Home frame")
	await review_experience(hub,false,output,tester)
	var primary: Button = hub.find_child("RecommendedJourneyAction",true,false)
	primary.pressed.emit(); await settle()
	check(hub.yi_introduction.visible and hub.yi_introduction.skip_button.visible,"fresh exported Home offers skippable introduction")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("intro.png"))==OK,"actual exported introduction frame")
	if creative_family(): await creative_media(hub.yi_introduction,output)
	if tester:
		feedback.open_panel(); await settle()
		check(feedback.backdrop.visible and get_tree().paused and hub.yi_introduction.visible,"exported feedback opens over introduction")
		feedback.close_panel(); await settle()
		check(not get_tree().paused and hub.yi_introduction.visible,"exported feedback returns to introduction")
	hub.yi_introduction.skip_button.pressed.emit(); await settle()
	var host: Variant = get_tree().current_scene
	check(host.scene_file_path=="res://src/hardware_foundations/hardware_foundations.tscn" and host.current_level_id==&"tutorial","skip reaches the real first task")
	check(not host.completed_levels.get(&"tutorial",false),"introduction never grants earned completion")
	check(is_instance_valid(host.journey_context) and host.journey_context.last_task=="hardware_foundations/tutorial" and not host.journey_context.details.visible,"actual exported tutorial has direct task action and optional context")
	while host.mission_briefing_active:
		host.mission_briefing_continue_button.pressed.emit(); await settle()
	host._on_connection_request(&"A_IN",0,&"NOT_1",0)
	host._on_connection_request(&"NOT_1",0,&"LAMP",0)
	host.input_a_button.button_pressed=true; host._run_debug()
	host._on_disconnection_request(&"NOT_1",0,&"LAMP",0)
	check(not host.completed_levels.get(&"tutorial",false),"incomplete actual actions retain incomplete status")
	host._on_connection_request(&"NOT_1",0,&"LAMP",0); await settle()
	check(host.completed_levels.get(&"tutorial",false) and host.level_completion_overlay.visible,"actual five actions earn first completion in export")
	check(host.level_completion_overlay.yi_response_label.text.contains("1 → 0"),"exported response reflects true NOT outcome")
	check(host.journey_context.context_label.text.contains("Earned record" if host.journey_context.english else "已有验收记录"),"actual exported task context refreshes earned capability")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("first-result.png"))==OK,"actual exported first result frame")
	var circuit_signature: String = host._circuit_from_graph().canonical_signature()
	host._dismiss_level_completion()
	host._show_desktop_window(&"task")
	host.journey_context.toggle.button_pressed=true
	var context_parent: Node = host.journey_context.get_parent()
	while context_parent!=null:
		if context_parent is ScrollContainer: context_parent.ensure_control_visible(host.journey_context.toggle)
		context_parent=context_parent.get_parent()
	await settle()
	var context_clip: Rect2 = get_viewport().get_visible_rect()
	context_parent = host.journey_context.toggle.get_parent()
	while context_parent!=null:
		if context_parent is Control and context_parent.clip_contents: context_clip=context_clip.intersection(context_parent.get_global_rect())
		context_parent=context_parent.get_parent()
	check(host.journey_context.toggle.is_visible_in_tree() and context_clip.grow(1).encloses(host.journey_context.toggle.get_global_rect()),"actual earned context control is visible inside the exported Mission and its ancestor scroll clips")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("context.png"))==OK,"actual exported earned task context frame")
	host.journey_context.toggle.button_pressed=false
	var handbook: Variant = host.terminology_handbook
	handbook.open_handbook(&"half_adder"); await settle()
	check(handbook.is_term_unlocked(&"half_adder") and handbook.detail_diagram.diagram_id==&"half_adder","actual earned tutorial makes the half-adder rule available")
	if handbook.detail_diagram.diagram_id==&"half_adder":
		for button: Button in handbook.detail_diagram.input_buttons: button.pressed.emit()
		handbook.detail_scroll_container.ensure_control_visible(handbook.detail_diagram)
		await settle()
		var example: Dictionary = handbook.detail_diagram.logic_example()
		check(example.a==1 and example.b==1 and example.outputs==[0,1],"actual isolated half-adder input buttons show sum0 carry1")
		check(host._circuit_from_graph().canonical_signature()==circuit_signature,"rule exploration preserves the player's actual circuit")
		check(get_viewport().get_texture().get_image().save_png(output.path_join("rules.png"))==OK,"actual exported interactive rule frame")
	handbook.close_handbook()
	host._save_active_workbench()
	check(get_node("/root/GlobalSave").save_game(true),"actual exported earned tutorial explicitly saves before derived review")
	if creative_family(): await creative_saved_work_setup()
	check(nav.open_tree(),"actual embedded journey map opens")
	await settle()
	var map: Variant = get_tree().current_scene
	check(map.scene_file_path=="res://src/campaign/task_tree.tscn" and map.rows.size()==60,"actual embedded map contains all sixty task rows")
	check(map.journey_scope.text.contains("60") and map.creation_route.visible and map.creation_route.get_child_count()==3,"actual embedded map footer and three creation shortcuts match its catalog")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("map.png"))==OK,"actual exported full-journey map frame")
	await review_experience(map,true,output,tester)
	if tester:
		check(nav.enter("chapter_1/cpu_speed"),"actual tester enters CPU comparison without granting completion")
		await settle()
		var system: Variant = get_tree().current_scene
		system._open_instrument(&"mission")
		var next_action: Label = system.mission_next_action_label
		var mission_scroll := next_action.get_parent().get_parent() as ScrollContainer
		check(mission_scroll!=null and next_action.visible,"actual incomplete comparison has baseline guidance in Mission")
		if mission_scroll!=null:
			mission_scroll.ensure_control_visible(next_action); await settle()
			check(mission_scroll.get_global_rect().encloses(next_action.get_global_rect()) and get_viewport().get_visible_rect().encloses(next_action.get_global_rect()),"actual next-action guidance is within its scroll clip and game viewport")
			check(not get_node("/root/SystemChapter").completed_levels().get(&"cpu_speed",false),"viewing next-action guidance grants no comparison completion")
			check(get_viewport().get_texture().get_image().save_png(output.path_join("system-guidance.png"))==OK,"actual exported visible next-action guidance frame")
		get_tree().call_group("workspace_owners","flush_workspace")
		check(get_node("/root/GlobalSave").save_game(true),"actual exported tester workspace saves before restart snapshot")
		var saved_state: Dictionary = get_node("/root/GlobalSave")._save_snapshot()
		check(saved_state.get("game",{}).get("system",{}).get("workspaces",{}).has("cpu_speed"),"restart snapshot includes the actual flushed CPU workspace")
		check(not get_node("/root/SystemChapter").completed_levels().get(&"cpu_speed",false),"flushing the actual workspace grants no CPU comparison completion")
	var file := FileAccess.open(output.path_join("embedded.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"profile":profile,"tester":tester,
		"source_commit":ProjectSettings.get_setting("application/config/build_commit",""),
		"build_id":ProjectSettings.get_setting("application/config/version",""),
		"logical_viewport":str(get_viewport().get_visible_rect().size),"physical_frame":str(get_viewport().get_texture().get_image().get_size()),
		"extended_experience":experience,"restart_protected":protected_snapshot(),
		"evidence_grade":"rendered controller input, not native OS or human playtest"},"\t")); file.close()
	print("PASS: night package embedded configuration and first experience" if failures.is_empty() else "FAIL: night package")
	get_tree().quit(0 if failures.is_empty() else 1)

func reopen_embedded_profile(output: String, profile: String, tester: bool) -> void:
	var prior_path: String = output.path_join("receipt.json")
	check(FileAccess.file_exists(prior_path),"embedded reopen requires a successful parent receipt")
	if not FileAccess.file_exists(prior_path): get_tree().quit(1); return
	var prior: Variant = JSON.parse_string(FileAccess.get_file_as_string(prior_path))
	check(prior is Dictionary and prior.get("failures",["missing"]).is_empty(),"parent embedded acceptance has no failed checks")
	if not prior is Dictionary: get_tree().quit(1); return
	check(prior.get("source_commit","")==ProjectSettings.get_setting("application/config/build_commit","") and prior.get("build_id","")==ProjectSettings.get_setting("application/config/version",""),"reopen uses the same frozen source and build")
	check(prior.get("profile","")==profile and prior.get("tester",not tester)==tester,"reopen retains the actual embedded profile and role")
	check(FileAccess.get_sha256(OS.get_executable_path())==str(prior.get("exe_sha256","")),"reopen executable matches the already accepted ZIP binary")
	check(FileAccess.get_sha256(get_script().resource_path)==str(prior.get("controller_sha256","")),"reopen uses the identical external controller")
	var baseline_path: String = output.path_join("embedded-profile-post-exit-baseline.json")
	check(FileAccess.file_exists(baseline_path),"post-exit protected baseline exists")
	if not FileAccess.file_exists(baseline_path): get_tree().quit(1); return
	var baseline: Variant = JSON.parse_string(FileAccess.get_file_as_string(baseline_path))
	check(baseline is Dictionary,"post-exit protected baseline is readable")
	if not baseline is Dictionary: get_tree().quit(1); return
	check(baseline.get("parent_receipt_sha256","")==FileAccess.get_sha256(prior_path),"post-exit baseline binds the successful parent receipt")
	for identity: String in ["source_commit","build_id","profile","tester","controller_sha256"]:
		check(baseline.get(identity)!=null and baseline.get(identity)==prior.get(identity),"post-exit baseline retains parent "+identity)
	var before: Dictionary = protected_snapshot()
	# JSON parsing represents integers as floats; compare both through the same parser.
	check(JSON.stringify(baseline.get("protected",{}),"",true)==JSON.stringify(JSON.parse_string(JSON.stringify(before,"",true)),"",true),"saved game workbench and candidate authorities survive independent process restart")
	var save: Node = get_node("/root/GlobalSave")
	check(FileAccess.file_exists(save.storage_path) and FileAccess.file_exists(save.workbench_storage_path),"genuinely saved game and hardware workbench exist in embedded namespace")
	check(get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")==OK,"restarted actual Home loads")
	await settle()
	var nav: Node = get_node("/root/TaskNavigation")
	check(nav.open_tree(),"restarted embedded map opens")
	await settle()
	var map: Variant = get_tree().current_scene
	check(map.scene_file_path=="res://src/campaign/task_tree.tscn" and map.rows.size()==60,"restarted map reads its actual sixty tasks")
	var tutorial: Dictionary = {}
	for row: Dictionary in map.rows:
		if str(row.key)=="hardware_foundations/tutorial": tutorial=row
	check(not tutorial.is_empty() and bool(tutorial.get("completed",false)),"real tutorial completion reloads independently from tester access")
	var launcher := map.find_child("OpenJourneyJournal",true,false) as Button
	check(launcher!=null,"restarted map keeps the actual Journal entrance")
	if launcher!=null:
		launcher.pressed.emit(); await settle()
		var journal: Variant = map.journey_journal
		journal.show_task("hardware_foundations/tutorial")
		check(journal.earned(journal.selected_task()) and not journal.civilization_fragment(journal.selected_task()).is_empty(),"restarted Journal derives its earned retrospective from saved tutorial")
		journal.show_task("hardware_foundations/half_adder")
		check(not journal.earned(journal.selected_task()) and journal.civilization_fragment(journal.selected_task()).is_empty(),"restarted access still grants no unearned half-adder retrospective")
		if creative_family():
			await creative_reflection(journal,"restarted",true,output,tester)
			var expected_work: Dictionary = prior.get("extended_experience",{}).get("creative_saved_work",{}).get("work",{})
			check(not expected_work.is_empty(),"Creative restart binds the originally accepted real saved work")
			if not expected_work.is_empty(): await creative_work_review(journal,"restarted",expected_work,output,tester)
		await key_press(KEY_ESCAPE)
	check(protected_snapshot()==before,"restarted map and Journal preserve exact saved authority bytes and state")
	var receipt: Dictionary = {"checks":checks,"failures":failures,"profile":profile,"tester":tester,
		"source_commit":ProjectSettings.get_setting("application/config/build_commit",""),"build_id":ProjectSettings.get_setting("application/config/version",""),
		"parent_receipt_sha256":FileAccess.get_sha256(prior_path),"exe_sha256":FileAccess.get_sha256(OS.get_executable_path()),
		"controller_sha256":FileAccess.get_sha256(get_script().resource_path),"protected":before,
		"post_exit_baseline_sha256":FileAccess.get_sha256(baseline_path),
		"evidence_grade":"same embedded namespace after independent process restart; rendered controller, not native input"}
	var file := FileAccess.open(output.path_join("embedded-profile-reopen.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt,"\t")); file.close()
	print("PASS: embedded profile independent restart" if failures.is_empty() else "FAIL: embedded profile independent restart")
	get_tree().quit(0 if failures.is_empty() else 1)
