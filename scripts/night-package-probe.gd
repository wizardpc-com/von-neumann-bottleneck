extends Node
## Disclosed controller input in an unchanged export with a fresh redirected APPDATA.
var checks: Dictionary = {}
var failures: Array[String] = []
func _ready() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks[label]=ok
	if not ok: failures.append(label); push_error(label)
func settle() -> void:
	for frame: int in 8: await get_tree().process_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw

func run() -> void:
	var output: String = str(ProjectSettings.get_setting("qa_night/output",""))
	if output.is_empty() or not OS.get_environment("APPDATA").replace("\\","/").contains("/.godot/night-package/"):
		get_tree().quit(2); return
	get_tree().current_scene=null
	var nav: Node = get_node("/root/TaskNavigation")
	var feedback: Node = get_node("/root/OfflineFeedback")
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	var tester: bool = ProjectSettings.get_setting("playtest/offline_tester",false)==true
	check(profile in ["NightExperience20261018","OfflineTeammate-Night20261018"],"actual embedded night profile")
	check(OS.get_user_data_dir().replace("\\","/").ends_with("/VonNeumannBottleneckCandidates/representation/"+profile),"actual embedded save namespace")
	check(OS.has_feature("free_candidate") and nav.journey_tasks().size()==60,"actual exported full journey configuration")
	check(not get_node("/root/GameMode").is_test_mode(),"ordinary model mode")
	check(get_node("/root/RemoteFeedback").endpoint.is_empty() and not get_node("/root/RemoteFeedback").enabled,"no receiver or automatic upload")
	var unavailable: int = 0
	for task: Dictionary in nav.tasks():
		if not task.unlocked: unavailable+=1
	check(unavailable==0 if tester else unavailable>0,"tester and normal progression remain distinct")
	check(get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn")==OK,"actual Home loads")
	await settle()
	var hub: Variant = get_tree().current_scene
	check(str(hub.find_child("BuildIdentifier",true,false).text).contains(str(ProjectSettings.get_setting("application/config/version",""))),"visible build identity belongs to this export")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("home.png"))==OK,"actual exported Home frame")
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
	host._on_connection_request(&"A_IN",0,&"NOT_1",0)
	host._on_connection_request(&"NOT_1",0,&"LAMP",0)
	host.input_a_button.button_pressed=true; host._run_debug()
	host._on_disconnection_request(&"NOT_1",0,&"LAMP",0)
	check(not host.completed_levels.get(&"tutorial",false),"incomplete actual actions retain incomplete status")
	host._on_connection_request(&"NOT_1",0,&"LAMP",0); await settle()
	check(host.completed_levels.get(&"tutorial",false) and host.level_completion_overlay.visible,"actual five actions earn first completion in export")
	check(host.level_completion_overlay.yi_response_label.text.contains("1 → 0"),"exported response reflects true NOT outcome")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("first-result.png"))==OK,"actual exported first result frame")
	var circuit_signature: String = host._circuit_from_graph().canonical_signature()
	host._dismiss_level_completion()
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
	check(nav.open_tree(),"actual embedded journey map opens")
	await settle()
	var map: Variant = get_tree().current_scene
	check(map.scene_file_path=="res://src/campaign/task_tree.tscn" and map.rows.size()==60,"actual embedded map contains all sixty task rows")
	check(map.journey_scope.text.contains("60") and map.creation_route.visible and map.creation_route.get_child_count()==3,"actual embedded map footer and three creation shortcuts match its catalog")
	check(get_viewport().get_texture().get_image().save_png(output.path_join("map.png"))==OK,"actual exported full-journey map frame")
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
		"evidence_grade":"rendered controller input, not native OS or human playtest"},"\t")); file.close()
	print("PASS: night package embedded configuration and first experience" if failures.is_empty() else "FAIL: night package")
	get_tree().quit(0 if failures.is_empty() else 1)
