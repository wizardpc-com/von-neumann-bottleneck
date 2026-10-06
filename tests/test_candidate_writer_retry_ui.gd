extends SceneTree
const RS = preload("res://experiments/representation_region/session_store.gd")
const SS = preload("res://experiments/service_plan/session_store.gd")
const RM = preload("res://experiments/representation_region/model.gd")
const SM = preload("res://experiments/service_plan/model.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.size = Vector2i(1280,720)
	for representation: bool in [true,false]:
		var store = RS if representation else SS
		var old_path: String = store.PATH
		for changed: bool in [false,true]:
			var path: String = "user://writer-retry-ui/"+str(representation)+"-"+str(changed)+"/session.json"
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			store.PATH = path
			var owner: RefCounted = Lease.new(path)
			var ui = load("res://experiments/representation_region/region.tscn" if representation else "res://experiments/service_plan/lab.tscn").instantiate()
			ui.persistent_session = true; root.add_child(ui); await process_frame
			check(ui.save_blocked and ui.find_child("RetryWriter",true,false) != null,"Refused window has a retry without restarting")
			for en: bool in [false,true]:
				ui.english = en; ui.build(); await process_frame; await process_frame
				var control: Button = ui.find_child("RetryWriter",true,false)
				check(control.get_global_rect().end.x <= 1281,"Writer retry fits the minimum bilingual window width")
			if representation:
				var plan: Array[Dictionary] = [{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}]
				ui.edit_plan(plan)
			else:
				var plan: Dictionary = SM.initial_plan(); plan.groups = []
				for request: int in 24: plan.groups.append([request])
				ui.edit(plan,0)
			ui.run_current()
			var draft = ui.plan.duplicate(true)
			var supports: Dictionary = ui.support_plans.duplicate(true)
			check(supports.size() == 1,"Blocked exploration can still measure and protect an accepted plan")
			ui.find_child("RetryWriter",true,false).pressed.emit(); await process_frame
			check(ui.save_blocked and owner.owns(path) and not FileAccess.file_exists(path),"Live owner is never reclaimed or written over")
			if changed:
				var raw: String
				if representation:
					var drafts: Array = []
					for task: int in 5: drafts.append(RM.initial_plan())
					raw = RS.encode(0,drafts,[])
				else: raw = SS.encode(0,SM.initial_plan(),[])
				check(store.write_session(raw,path,"",owner) == OK,"First owner saves a different disk version")
			owner.release()
			var disk_hash: String = FileAccess.get_sha256(path) if changed else ""
			ui.find_child("RetryWriter",true,false).pressed.emit(); await process_frame
			check(ui.plan == draft and ui.history.size() == 1 and ui.support_plans == supports and ui.session_dirty,"Retry preserves all live exploration and protected results")
			if changed:
				check(ui.save_blocked and ui.find_child("SaveSession",true,false).disabled,"Changed disk stays protected, save remains disabled")
				check(FileAccess.get_sha256(path) == disk_hash,"Retry never installs an obsolete draft")
				ui.find_child("ReloadCandidate",true,false).pressed.emit(); await process_frame
				var dialog: ConfirmationDialog = ui.get_node("ReplaceUnsavedRecovery")
				check(dialog.visible and ui.plan == draft,"Reload requires an explicit decision before discarding unsaved work")
				dialog.canceled.emit(); await process_frame
				check(ui.plan == draft and ui.session_dirty,"Cancel preserves unsaved work")
				ui.find_child("ReloadCandidate",true,false).pressed.emit(); await process_frame
				ui.get_node("ReplaceUnsavedRecovery").confirmed.emit(); await process_frame
				check(not ui.save_blocked and ui.history.is_empty() and not ui.session_dirty,"Confirmed reload adopts the current save while holding writer ownership")
				check(FileAccess.get_sha256(path) == disk_hash,"Confirmed reload reads without writing disk")
			else:
				check(not ui.save_blocked and not ui.find_child("SaveSession",true,false).disabled,"Normal release allows this window to save without restart")
				ui.save_session()
				check(not ui.session_dirty and store.read_session(path).runs.size() == 1,"The retained measurement actually saves")
				check(store.read_session(path).supports.size() == 1,"The retained successful plan is persisted")
			ui.queue_free(); await process_frame; await process_frame
			check(not DirAccess.dir_exists_absolute(Lease.lock_path(path)),"Retry ownership is released on scene exit")
		store.PATH = old_path
	print("PASS: test_candidate_writer_retry_ui " if failures == 0 else "FAIL: test_candidate_writer_retry_ui ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
