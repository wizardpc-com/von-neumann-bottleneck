extends Node
## Synthetic acceptance controller; run only with an isolated QA player directory.
var results: Dictionary = {}
var failures: Array[String] = []

func check(value: bool, label: String) -> void:
	results[label]=value
	if not value: failures.append(label); push_error(label)

func _ready() -> void: call_deferred("run")

func settle() -> void:
	for index: int in 5: await get_tree().process_frame
	if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw

func run() -> void:
	var phase: String = str(ProjectSettings.get_setting("qa_offline/phase",""))
	var output: String = str(ProjectSettings.get_setting("qa_offline/output",""))
	if phase not in ["capture","reopen"] or output.is_empty() or not OS.get_user_data_dir().replace("\\","/").contains("OfflinePlaytestQA"):
		get_tree().quit(2); return
	var navigation: Node = get_node("/root/TaskNavigation")
	# Keep this disclosed QA controller as a sibling while real task scenes change.
	if get_tree().current_scene==self: get_tree().current_scene=null
	var feedback: Node = get_node("/root/OfflineFeedback")
	var remote: Node = get_node("/root/RemoteFeedback")
	check(feedback.enabled() and remote.endpoint.is_empty() and not remote.enabled,"tester is entirely offline")
	check(not get_node("/root/GameMode").is_test_mode(),"normal model and completion mode")
	if phase=="capture":
		var tasks: Array[Dictionary] = navigation.journey_tasks()
		check(tasks.size()==60,"full sixty task catalog")
		var visited: Array[String] = []
		for task: Dictionary in tasks:
			check(navigation.enter(task.key),"enter "+str(task.key))
			await settle()
			var actual: Dictionary = get_node("/root/PlaytestData").current_task_context
			check(actual.get("chapter_id","")+"/"+actual.get("level_id","")==task.key,"actual foreground "+str(task.key))
			visited.append(task.key)
		results["visited"]=visited
		for key: String in ["hardware_foundations/tutorial","chapter_1/assembly","creation/G2_intent"]:
			check(navigation.enter(key),"capture entrance "+key); await settle()
			feedback.open_panel(); await settle()
			check(feedback.backdrop.visible and not feedback.current.is_empty(),"global feedback opens "+key)
			feedback.note.text="SYNTHETIC offline acceptance: "+key+"\n希望操作更清楚。"
			feedback.note.text_changed.emit()
			feedback._save_note(true)
			check(feedback.current.get("status")=="reported","note saved "+key)
			check(feedback.current.screenshot_status=="captured" if DisplayServer.get_name()!="headless" else feedback.current.screenshot_status=="headless","screenshot status "+key)
			feedback.close_panel(); await settle()
		results["case_ids"]=feedback.store.cases().map(func(item: Dictionary) -> String: return str(item.id))
		feedback.export_all(output.path_join("captured.zip"))
		check(not feedback.last_export.is_empty(),"one ZIP export")
		check(not remote.enabled and remote.queue.is_empty(),"no upload or pending remote data")
	else:
		var cases: Array[Dictionary] = feedback.store.cases()
		check(cases.size()==3,"three incidents survive independent restart")
		for item: Dictionary in cases:
			check(str(item.note).contains("SYNTHETIC offline acceptance") and item.status=="reported","persisted note "+str(item.id))
			check(FileAccess.file_exists(feedback.store.root.path_join("cases").path_join(item.id).path_join("context.json")),"persisted context "+str(item.id))
		check(navigation.enter("service/one_plan"),"second play enters a different workbench")
		await settle()
		feedback.open_panel(); await settle()
		feedback.note.text="SYNTHETIC second play session: service/one_plan\n重启后新增反馈。"
		feedback.note.text_changed.emit(); feedback._save_note(true)
		check(feedback.current.get("status")=="reported","second play records a new incident")
		check(feedback.current.screenshot_status=="captured","second play captures its own screenshot")
		feedback.close_panel(); await settle()
		feedback.export_all(output.path_join("reopened.zip"))
		check(not feedback.last_export.is_empty(),"restart export includes history")
		check(feedback.store.cases().size()==4,"final export preserves incidents from both plays")
	results["phase"]=phase; results["failures"]=failures
	var file := FileAccess.open(output.path_join(phase+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t")); file.close()
	print("PASS: offline playtest "+phase if failures.is_empty() else "FAIL: offline playtest "+phase)
	get_tree().quit(0 if failures.is_empty() else 1)
