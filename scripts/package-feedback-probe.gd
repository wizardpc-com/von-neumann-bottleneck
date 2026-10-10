extends Node
## Explicit synthetic QA controller, loaded externally into an unchanged export.
## It never supplies progression flags or runs on a player's profile.
var failures: Array[String] = []
var evidence: Dictionary = {}
var host: Variant

func check(value: bool, message: String) -> void:
	evidence[message]=value
	if not value: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 6: await get_tree().process_frame

func protected_work_matches(previous: Dictionary) -> bool:
	return FileAccess.get_sha256(host.session.path)==str(previous.get("work_file_sha256","")) and host.session.data.works.size()==1 and str(host.session.data.works[0].id)==str(previous.work.id) and host.session.replay_work(0).get("matches",false)

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var phase: String = str(ProjectSettings.get_setting("qa_feedback/phase",""))
	var output: String = str(ProjectSettings.get_setting("qa_feedback/output",""))
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	if not profile.begins_with("PackageFeedback-") or output.is_empty() or phase not in ["offline","online","delete"]:
		get_tree().quit(2); return
	var store: Node = get_node("/root/PlaytestData")
	var remote: Node = get_node("/root/RemoteFeedback")
	var moments: Node = get_node("/root/PlaytestMoments")
	check(OS.has_feature("free_candidate"),"actual exported candidate feature")
	check(get_node("/root/TaskNavigation").journey_tasks().size()==60,"actual exported journey contains60 tasks")
	check(not get_node("/root/GameMode").is_test_mode(),"ordinary Game mode")
	check(store.start_session(),"local observer initialized")
	host=load("res://experiments/creation/workbench.tscn").instantiate()
	add_child(host); await settle()
	if phase == "offline":
		host.change_task(7); await settle()
		check(store.current_task_context.get("level_id","")=="G2_intent","actual unfinished G2 foreground context")
		check(not host.session.data.supports.has("G2_intent"),"feedback before G2 completion")
		moments.toggle(); moments.opinion.text="SYNTHETIC package acceptance: unfinished G2 controls"
		moments.category.select(2)
		moments.panel.find_child("SendTaskFeedback",true,false).pressed.emit()
		await get_tree().create_timer(1.0).timeout
		var id: String = remote.feedback_id(moments.saved_opinion)
		evidence["feedback_id"]=id
		evidence["record"]=remote.queue[0].record.duplicate(true) if not remote.queue.is_empty() else {}
		evidence["client_id"]=remote.client_id; evidence["deletion_token"]=remote.deletion_token
		check(id.length()==64 and remote.feedback_state(id) in ["pending","sending","failed_retryable"],"offline feedback is queued, never marked received")
		check(not remote.enabled,"single opinion did not authorize automatic statistics")
		moments.close()
		remote.set_sharing_mode("basic")
		host.change_task(8); host.change_task(6)
		remote.set_sharing_mode("local")
		check(remote.queue.size()==1 and remote.queue[0].record.kind=="feedback","withdraw statistics retains only explicitly sent opinion")
		# Follow the actual restore → sealed prediction → feedback mode gates.
		host.change_task(0); host.train_model(); host.transport("predictive")
		host.change_task(3); host.switch_mode("predict"); host.begin_prediction("practice")
		host.commit_prediction(); host.reveal_prediction(); host.continue_prediction()
		check(host.session.prediction.get("finished",false),"actual sealed prediction completed before feedback mode")
		host.change_task(6); host.switch_mode("generate"); host.generate_work()
		host.name_input.text="Synthetic acceptance work"; host.keep_work()
		check(not host.kept_work.is_empty(),"real model generated and saved a protected work offline")
		evidence["work"]=host.kept_work.duplicate(true)
		evidence["work_path"]=ProjectSettings.globalize_path(host.session.path)
		evidence["work_file_sha256"]=FileAccess.get_sha256(host.session.path)
		moments.open_for_task("creation","C1_restore")
		moments.opinion.text="SYNTHETIC private unsent draft"; moments.close()
		check(remote.queue.size()==1,"unsent text remains outside transport")
	else:
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("offline.json")))
		var id: String = str(previous.feedback_id)
		check(protected_work_matches(previous),"independent process restores byte-identical protected work and replays its complete recipe")
		moments.open_for_task("creation","C1_restore")
		check(moments.opinion.text=="SYNTHETIC private unsent draft","independent process restores private unsent draft")
		moments.close()
		moments.open_for_task("creation","G2_intent")
		check(remote.feedback_id(moments.saved_opinion)==id,"reopened opinion retains the identical stable ID")
		if phase == "online":
			moments.panel.find_child("SendTaskFeedback",true,false).pressed.emit()
			remote.retry_pending()
			for attempt: int in 100:
				if remote.feedback_state(id)=="sent": break
				await get_tree().create_timer(0.1).timeout
			check(remote.feedback_state(id)=="sent","matching HTTP server acknowledgment received")
			check(remote.queue.is_empty(),"acknowledged opinion removed from durable outbox")
			check(moments.opinion_status.text.contains(id),"visible received state belongs to identical ID")
		else:
			remote.delete_uploaded_data()
			for attempt: int in 100:
				if remote.status=="deleted": break
				await get_tree().create_timer(0.1).timeout
			check(remote.status=="deleted" and remote.identity_deleted and remote.queue.is_empty(),"explicit server deletion acknowledged and queue canceled")
		check(protected_work_matches(previous),"feedback transport and deletion preserve byte-identical protected work")
		evidence["feedback_id"]=id; evidence["displayed_status"]=moments.opinion_status.text
		moments.close()
	var context: Dictionary = store.task_feedback_context("creation","G2_intent")
	evidence["context"]=context; evidence["phase"]=phase; evidence["passed"]=failures.is_empty()
	evidence["evidence_kind"]="synthetic controller input in unchanged exported binary and pack; not native OS input or newcomer acceptance"
	host.queue_free(); await settle()
	var file := FileAccess.open(output.path_join(phase+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"  ")); file.close()
	print("PASS: actual package feedback "+phase if failures.is_empty() else "FAIL: actual package feedback "+phase)
	get_tree().quit(0 if failures.is_empty() else 1)
