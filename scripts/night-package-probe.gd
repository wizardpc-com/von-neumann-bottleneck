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
	var file := FileAccess.open(output.path_join("embedded.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"profile":profile,"tester":tester,
		"source_commit":ProjectSettings.get_setting("application/config/build_commit",""),
		"build_id":ProjectSettings.get_setting("application/config/version",""),
		"evidence_grade":"rendered controller input, not native OS or human playtest"},"\t")); file.close()
	print("PASS: night package embedded configuration and first experience" if failures.is_empty() else "FAIL: night package")
	get_tree().quit(0 if failures.is_empty() else 1)
