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
func write_raw(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Isolated fixture can be written")
	if file != null: file.store_string(raw); file.close()
func fixture_path(base: String, name: String) -> String:
	var directory: String = base.path_join(name)
	check(DirAccess.make_dir_recursive_absolute(directory) == OK,"Independent QA directory exists")
	return directory.path_join("session.json")
func rep_drafts(plan: Array[Dictionary]) -> Array:
	var result: Array = []
	for task: int in 5: result.append(plan.duplicate(true) if task == 0 else RM.initial_plan())
	return result

func run() -> void:
	root.size = Vector2i(1280,720)
	var base: String = "user://restore-selection-"+Crypto.new().generate_random_bytes(8).hex_encode()
	var old_rep_path: String = RS.PATH
	var old_service_path: String = SS.PATH
	var accepted: Array[Dictionary] = [{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}]
	var larger: Array[Dictionary] = [{"start":0,"end":8,"codec":"raw"},{"start":8,"end":16,"codec":"raw"},{"start":16,"end":32,"codec":"raw"},{"start":32,"end":64,"codec":"raw"}]
	var path: String = fixture_path(base,"representation-snapshot")
	RS.PATH = path
	var saved_rows: Array = [{"task":0,"plan":accepted}]
	var raw: String = RS.encode(0,rep_drafts(accepted),saved_rows,saved_rows)
	var interrupted_raw: String = RS.encode(0,rep_drafts(larger),[])
	# A real pending transaction exposes main plus an independently validated temp.
	write_raw(path,raw); write_raw(path+".tmp.interrupted",interrupted_raw)
	DirAccess.make_dir_recursive_absolute(path+".snapshots")
	var archived_path: String = (path+".snapshots").path_join("previous-original.json")
	var archived_raw: String = "previous original retained verbatim"
	write_raw(archived_path,archived_raw)
	var ui = load("res://experiments/representation_region/region.tscn").instantiate()
	ui.persistent_session = true; root.add_child(ui); await process_frame
	check(ui.writer_lease.owns(path) and ui.save_blocked and ui.recovery_state.get("error") == "recovery","Scene owns the lease and offers actual pending snapshot recovery")
	ui.edit_plan(larger); ui.selected_block = larger.size()-1; ui.refresh_plan(); ui.run_current()
	check(ui.plan == larger and ui.selected_block == 3 and ui.session_dirty,"Live exploration selects the last of four blocks before recovery")
	ui.confirm_recovery(func() -> void: ui.recover_candidate(path)); await process_frame
	var confirmation: ConfirmationDialog = ui.get_node("ReplaceUnsavedRecovery")
	check(confirmation.visible and ui.plan == larger,"Replacing live exploration requires the real recovery confirmation")
	confirmation.confirmed.emit(); await process_frame; await process_frame
	check(ui.plan == accepted and ui.selected_block == 0,"Fewer-block snapshot resets the selected block before rebuilding its editor")
	check(ui.history.size() == 1 and ui.selected_run == 0 and ui.history[0].plan == accepted,"Recovered history selects the actual restored measurement")
	check(ui.completed[0] and ui.support_plans.get(0) == accepted,"Recovery revalidates the successful support from the saved snapshot")
	check(not ui.save_blocked and not ui.session_dirty and ui.writer_lease.owns(path),"Recovered workbench remains clean and owns its writer lease")
	check(ui.raw_button.disabled == false and ui.rle_button.disabled and not ui.merge_button.disabled,"Codec and merge controls describe the first restored block")
	check(FileAccess.get_file_as_string(path) == raw,"Chosen snapshot bytes are installed without re-encoding")
	check(FileAccess.get_file_as_string((path+".snapshots").path_join(raw.sha256_text()+".json")) == raw,"Original main snapshot is preserved byte-exact")
	check(FileAccess.get_file_as_string((path+".snapshots").path_join(interrupted_raw.sha256_text()+".json")) == interrupted_raw,"Unchosen interrupted snapshot is preserved byte-exact")
	check(FileAccess.get_file_as_string(archived_path) == archived_raw,"Previously retained archive is unchanged")
	ui.queue_free(); await process_frame; await process_frame
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(path)),"Restored scene releases its lease on exit")
	RS.PATH = old_rep_path
	# A busy new profile has no saved recipe. Confirmed reload must restore defaults,
	# rather than clear dirty/history while leaving the old unsaved draft on screen.
	for representation: bool in [true,false]:
		var store = RS if representation else SS
		path = fixture_path(base,"empty-representation" if representation else "empty-service")
		store.PATH = path
		var owner: RefCounted = Lease.new(path)
		check(owner.held,"Other window owns the new empty profile")
		var empty_ui = load("res://experiments/representation_region/region.tscn" if representation else "res://experiments/service_plan/lab.tscn").instantiate()
		empty_ui.persistent_session = true; root.add_child(empty_ui); await process_frame
		check(empty_ui.save_blocked and empty_ui.find_child("ReloadCandidate",true,false) != null,"Refused window offers explicit saved-profile reload")
		if representation:
			empty_ui.edit_plan(accepted); empty_ui.run_current(); empty_ui.change_task(2)
			empty_ui.edit_plan(larger); empty_ui.selected_block = 3; empty_ui.refresh_plan()
		else:
			var grouped: Dictionary = SM.initial_plan(); grouped.groups = []
			for request: int in 24: grouped.groups.append([request])
			empty_ui.edit(grouped,23); empty_ui.run_current(); empty_ui.change_task(1)
			empty_ui.select_state_event(0); empty_ui.pin_comparison()
		check(empty_ui.task != 0 and empty_ui.session_dirty and not empty_ui.history.is_empty(),"Empty-profile reload starts with an edited later task and recorded exploration")
		owner.release()
		empty_ui.find_child("ReloadCandidate",true,false).pressed.emit(); await process_frame
		check(empty_ui.get_node("ReplaceUnsavedRecovery").visible,"Empty-profile reload still asks before replacing unsaved exploration")
		empty_ui.get_node("ReplaceUnsavedRecovery").confirmed.emit(); await process_frame; await process_frame
		check(empty_ui.task == 0 and empty_ui.plan == (RM.initial_plan() if representation else SM.initial_plan()),"Confirmed empty reload restores the initial task and actual default plan")
		check(empty_ui.history.is_empty() and empty_ui.support_plans.is_empty() and not empty_ui.session_dirty,"Empty reload clears prior live evidence without claiming it saved")
		check(not empty_ui.save_blocked and empty_ui.writer_lease.owns(path),"Empty reload retains valid exclusive ownership")
		if representation:
			check(empty_ui.selected_block == 0 and empty_ui.selected_run == -1 and empty_ui.reuse_button.disabled,"Empty Representation reload resets block/record selection and disables record reuse")
			check(not empty_ui.completed.has(true),"Empty Representation profile grants no completion")
		else:
			check(empty_ui.selected_group == 0 and empty_ui.selected_history == -1 and empty_ui.restore_button.disabled,"Empty Service reload resets group/record selection and disables record reuse")
			check(empty_ui.unlocked == 0 and empty_ui.commission_mode == -1,"Empty Service profile grants no contract or optional mode")
			check(empty_ui.selected_event_index == -1 and empty_ui.comparison_baseline.is_empty(),"Empty Service reload clears discarded event and pinned comparison")
		check(not FileAccess.file_exists(path) and store.Files.transaction_paths(path).is_empty() and not DirAccess.dir_exists_absolute(path+".snapshots"),"Reloading empty profile never creates save/backup/transaction/archive files")
		empty_ui.queue_free(); await process_frame; await process_frame
		check(not DirAccess.dir_exists_absolute(Lease.lock_path(path)),"Empty-profile reload releases ownership on exit")
		store.PATH = old_rep_path if representation else old_service_path
	print("PASS: test_candidate_restore_selection " if failures == 0 else "FAIL: test_candidate_restore_selection ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
