extends SceneTree
const Workspace = preload("res://src/save/chapter_workspace.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var mode: Node=root.get_node("GameMode")
	var locality: Node=root.get_node("LocalityChapter")
	var system: Node=root.get_node("SystemChapter")
	mode.set_mode(&"game")
	var draft: Dictionary={"draft_source":"unfinished ???","applied_source":"LOOP 1\nEND","cache_lines":2,"passes":2,"blocks":0,"bypass":false}
	locality.retain_workspace(&"capstone",draft)
	var saved: Dictionary=JSON.parse_string(JSON.stringify(locality.game_snapshot()))
	locality.restore_game(saved,false)
	check(locality.workspace_for(&"capstone").draft_source=="unfinished ???","Even invalid drafts survive locked prerequisites and JSON round trip")
	check(locality.workspace_for(&"capstone").applied_source==draft.applied_source and locality.game_completed.is_empty(),"Restoring a draft neither applies nor completes it")
	var incompatible: Dictionary=saved.duplicate(true)
	incompatible.workspaces.capstone.version="future-model"
	locality.restore_game(incompatible,false)
	check(locality.workspace_for(&"capstone").get("stale",false) and not locality.workspace_for(&"capstone").has("applied_source"),"Changed model keeps draft but does not revive executable configuration")
	locality.retain_workspace(&"capstone",draft)
	check(locality.game_workspaces.capstone.previous_version.version=="future-model","Superseded workspace remains locally recoverable")
	check(Workspace.bounded_workspaces({},[&"capstone"]).is_empty(),"Missing workspaces must not create phantom drafts")
	locality.reset_game_progress()
	var template = preload("res://src/simulation/program_templates.gd")
	var recipe: Dictionary={"source":template.COLUMN_FIRST,"cache_lines":1,"passes":2,"blocks":0,"bypass":false,"version":locality.workspace_version()}
	var receipt: Variant=locality._replay_observation(&"capstone",recipe)
	check(receipt!=null and receipt.passed,"Observed baseline recipe can be recomputed by the actual simulator")
	locality.record_receipt(&"capstone",receipt,recipe)
	var observations: Dictionary=JSON.parse_string(JSON.stringify(locality.game_snapshot()))
	locality.restore_game(observations,true)
	check(locality.receipts_for(&"capstone").size()==1 and locality.game_completed.is_empty(),"Actual recorded observation restores without granting completion")
	observations.observations.capstone[0].version="incompatible"
	locality.restore_game(observations,true)
	check(locality.receipts_for(&"capstone").is_empty(),"Incompatible observations are not promoted to current evidence")
	locality.game_completed[&"capstone"]=true
	var completed_host: Control=load("res://src/ui/main.tscn").instantiate();root.add_child(completed_host);await process_frame
	# Completion is pre-existing here; there is no replay receipt after an old-save restart.
	completed_host.current_level_id=&"capstone"
	check(not completed_host._capstone_baseline_pending() and not completed_host._capstone_first_experiment_pending(),"Completed capstone remains editable after old-save restart without receipts")
	completed_host.queue_free();await process_frame
	mode.set_mode(&"test")
	locality.reset_test_progress()
	var lab: Control=load("res://src/ui/main.tscn").instantiate(); root.add_child(lab)
	await process_frame
	lab._start_level(&"capstone")
	var applied: String=lab.applied_program_source
	lab.editor.text="INVALID DRAFT ???"
	lab.current_cache_lines=2
	lab._save_level_workspace()
	lab.queue_free(); await process_frame
	lab=load("res://src/ui/main.tscn").instantiate(); root.add_child(lab); await process_frame
	lab._start_level(&"capstone")
	check(lab.editor.text=="INVALID DRAFT ???" and lab.applied_program_source==applied and lab.program_dirty,"Recreated Chapter 2 scene keeps draft/applied identity")
	check(not lab.program_validation_label.text.contains(root.get_node("Localization").text(&"dsl.error.empty")),"Unsupported source explains the syntax error without a misleading empty-program message")
	lab.editor.text=""
	lab._on_program_changed()
	check(lab.program_validation_label.text.contains(root.get_node("Localization").text(&"dsl.error.empty")),"A genuinely empty draft still explains that it is empty")
	check(lab.current_cache_lines==2 and lab.current_trace==null,"Restored configuration requires a new run")
	lab.queue_free(); await process_frame
	system.reset_test_progress()
	var host: Control=load("res://src/system_lab/system_lab.tscn").instantiate();root.add_child(host);await process_frame
	host._start_level(&"read_once")
	var system_applied: String=host.applied_program_source
	host.editor.text="UNFINISHED ???"
	host.graph.clear_connections()
	host.device_nodes[&"CPU"].position_offset=Vector2(333,222)
	host._save_level_session()
	host.queue_free();await process_frame
	host=load("res://src/system_lab/system_lab.tscn").instantiate();root.add_child(host);await process_frame
	host._start_level(&"read_once")
	check(host.editor.text=="UNFINISHED ???" and host.applied_program_source==system_applied and host.draft_dirty,"Recreated Chapter 1 preserves unfinished work separately")
	check(host.graph.get_connection_list().is_empty(),"An intentionally empty wiring layout remains empty")
	check(host.device_nodes[&"CPU"].position_offset==Vector2(333,222),"JSON-safe positions restore")
	host.queue_free();await process_frame
	check(system.game_workspaces.is_empty(),"Test workspaces cannot replace Game drafts")
	for message: String in failures: push_error(message)
	print("PASS: separate drafts, applied state, observation replay, scene recovery and mode isolation" if failures.is_empty() else "FAIL: chapter workspaces")
	quit(0 if failures.is_empty() else 1)
