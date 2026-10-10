extends SceneTree
## Candidate feedback observes actual tasks without becoming model/save authority.
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 5: await process_frame
func run() -> void:
	var recorder: Node = root.get_node("PlaytestData")
	var moments: Node = root.get_node("PlaytestMoments")
	var remote: Node = root.get_node("RemoteFeedback")
	recorder.telemetry_enabled=true; recorder.questionnaire_enabled=true
	check(recorder.start_session(),"Recorder fixture starts an explicit isolated session")
	remote.endpoint="" # This suite never sends HTTP; the separate network probe proves receipts.
	var scenes := ["res://experiments/representation_region/region.tscn","res://experiments/service_plan/lab.tscn","res://experiments/prediction/lab.tscn","res://experiments/creation/workbench.tscn"]
	var domains := ["representation","service","prediction","creation"]
	for index: int in scenes.size():
		var host_script: Script = load(scenes[index].replace(".tscn",".gd"))
		if host_script == null or not host_script.can_instantiate():
			check(false,"Host script did not compile "+domains[index]); quit(1); return
		var scene: Variant = load(scenes[index]).instantiate()
		root.add_child(scene); await settle()
		check(recorder.current_task_context.get("chapter_id","")==domains[index],"Host replaces the prior task context "+domains[index])
		check(scene.find_child("MomentFeedbackButton",true,false)!=null,"Host has visible unfinished-task feedback "+domains[index])
		var visit: String = recorder.current_visit_id
		check(not visit.is_empty(),"Actual host has an observed visit "+domains[index])
		moments.toggle(); check(moments.target.get("chapter_id","")==domains[index],"Feedback freezes actual foreground domain "+domains[index])
		moments.opinion.text="synthetic candidate feedback"
		moments.category.select(3)
		check(moments._save_opinion(),"Unfinished candidate can save note without ratings "+domains[index])
		var saved: Dictionary = moments.saved_opinion.duplicate(true)
		if saved.is_empty():
			moments.close(); scene.queue_free(); await settle(); continue
		check(saved.payload.chapter_id==domains[index] and saved.visit_id==visit,"Opinion keeps task and actual visit "+domains[index])
		check(saved.payload.category=="bug" and saved.payload.fun==null,"Category is opinion-only and no score is prefilled")
		var id: String = remote.feedback_id(saved)
		moments.close(); moments.toggle()
		check(moments.opinion.text=="synthetic candidate feedback" and remote.feedback_id(moments.saved_opinion)==id,"Closing/reopening retains original local event ID")
		moments._save_opinion(); check(remote.feedback_id(moments.saved_opinion)==id,"Unchanged saved opinion does not create a duplicate submission")
		moments.opinion.text="changed unsent draft"
		moments.close(); moments.toggle()
		check(moments.opinion.text=="changed unsent draft","Unsubmitted local text survives feedback reopening")
		moments.close()
		if domains[index]=="creation":
			moments.open_for_task("creation","C1_restore")
			var frozen_visit: String = moments.target.get("visit_id","")
			moments.opinion.text="frozen C1 context while host moved"
			moments.opinion.caret_column=5
			scene.change_task(7); await settle()
			check(moments._save_opinion(),"Frozen C1 opinion remains submittable after G2 entry")
			var frozen: Dictionary = moments.saved_opinion
			if not frozen.is_empty():
				check(frozen.payload.level_id=="C1_restore" and frozen.visit_id==frozen_visit and frozen.payload.get("run_id","")==moments.target.get("run_id",""),"Open feedback keeps original task/visit/run without inheriting G2")
			moments.close(); moments.open_for_task("creation","C1_restore")
			check(moments.opinion.caret_column==5,"Reopened task draft keeps its text cursor")
			moments.close()
		if domains[index]=="service":
			scene.run_current()
		elif domains[index]=="creation":
			scene.change_task(7); await settle()
			check(recorder.current_task_context.level_id=="G2_intent","G2 feedback never inherits Cache or C1")
		elif domains[index]=="representation":
			scene.change_task(1); scene.run_current()
		else:
			scene.change_task(1); scene.run_current()
		scene.queue_free(); await settle()
		check(recorder.current_task_context.is_empty(),"Leaving host closes its own task context "+domains[index])
	# Rebuild from the bounded disk draft, simulating the next process reader.
	moments.drafts.clear(); moments._load_drafts()
	moments.open_for_task("creation","C1_restore")
	check(moments.opinion.text=="frozen C1 context while host moved" and not moments.saved_opinion.is_empty(),"Disk reader restores unsubmitted text and original stored event")
	moments.close()
	# A rejected JSON/schema keeps original bytes and requires an explicit local recovery.
	var good: String = FileAccess.get_file_as_string(moments.DRAFT_PATH)
	var bad := FileAccess.open(moments.DRAFT_PATH,FileAccess.WRITE); bad.store_string("{\"version\":99,\"PRIVATE\":\"must survive\"}"); bad.close()
	moments.drafts_blocked=false; moments._load_drafts()
	check(moments.drafts_blocked,"Unknown draft format blocks automatic overwrite")
	moments._store_draft(); check(FileAccess.get_file_as_string(moments.DRAFT_PATH).contains("must survive"),"Blocked writes preserve original draft bytes")
	check(moments._recover_drafts(),"Explicit recovery preserves a byte-exact old copy")
	var restored := FileAccess.open(moments.DRAFT_PATH,FileAccess.WRITE); restored.store_string(good); restored.close()
	moments.drafts.clear(); moments._load_drafts()
	check(not moments.drafts_blocked,"Valid original drafts remain readable after local recovery")
	print("PASS: candidate foreground tasks, unfinished opinion, local drafts and stable feedback IDs" if failures.is_empty() else "FAIL: candidate feedback")
	quit(0 if failures.is_empty() else 1)
