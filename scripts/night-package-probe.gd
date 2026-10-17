extends Node
## Disclosed controller input in an unchanged export with a fresh redirected APPDATA.
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

func run() -> void:
	var output: String = str(ProjectSettings.get_setting("qa_night/output",""))
	if output.is_empty() or not OS.get_environment("APPDATA").replace("\\","/").contains("/.godot/night-package/"):
		get_tree().quit(2); return
	get_tree().current_scene=null
	var nav: Node = get_node("/root/TaskNavigation")
	var feedback: Node = get_node("/root/OfflineFeedback")
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	var tester: bool = ProjectSettings.get_setting("playtest/offline_tester",false)==true
	check(profile in ["FullJourney20261018","OfflineTeammate-FullJourney20261018"],"actual embedded full-journey profile")
	check(OS.get_user_data_dir().replace("\\","/").ends_with("/VonNeumannBottleneckCandidates/representation/"+profile),"actual embedded save namespace")
	check(OS.has_feature("free_candidate") and nav.journey_tasks().size()==60,"actual exported full journey configuration")
	check(not get_node("/root/GameMode").is_test_mode(),"ordinary model mode")
	check(get_node("/root/RemoteFeedback").endpoint.is_empty() and not get_node("/root/RemoteFeedback").enabled,"no receiver or automatic upload")
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
