extends SceneTree
## Synthetic recipes test navigation/provenance; they do not establish player discovery.
const RS = preload("res://experiments/representation_region/session_store.gd")
const SS = preload("res://experiments/service_plan/session_store.gd")
const RM = preload("res://experiments/representation_region/model.gd")
const SM = preload("res://experiments/service_plan/model.gd")
class RepresentationProbe extends "res://experiments/representation_region/region.gd":
	var departures: int = 0
	var departed_to_map: bool = false
	func finish_leave() -> void:
		departures += 1; departed_to_map = leave_to_hub and get_node("/root/TaskNavigation").from_tree
class ServiceProbe extends "res://experiments/service_plan/lab.gd":
	var departures: int = 0
	var departed_to_map: bool = false
	func finish_leave() -> void:
		departures += 1; departed_to_map = leave_to_hub and not leave_to_journey and get_node("/root/TaskNavigation").from_tree
class PredictionProbe extends "res://experiments/prediction/lab.gd":
	var departures: int = 0
	var departed_to_map: bool = false
	func finish_leave() -> void:
		departures += 1; departed_to_map = leave_to_hub and get_node("/root/TaskNavigation").from_tree

var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func write_fixture(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Isolated fixture can be written")
	if file != null: file.store_string(raw); file.close()
func target(nav: Node, domain: String, index: int) -> void:
	nav.pending = nav.candidate_key(domain,index)
	nav.selected = nav.pending
	nav.from_tree = true
func cancel(dialog: ConfirmationDialog) -> void:
	dialog.hide(); dialog.canceled.emit()

func run() -> void:
	root.size = Vector2i(1280,720)
	var nav: Node = root.get_node("TaskNavigation")
	var previous_pending: String = nav.pending
	var previous_selected: String = nav.selected
	var previous_from_tree: bool = nav.from_tree
	var previous_last_visited: String = nav.last_visited_task
	var save: Node = root.get_node("GlobalSave")
	var before: Dictionary = save._save_snapshot(); before.erase("saved_at_utc")
	check(nav.tasks().size() == 40,"Integration preserves the original forty task catalog")
	if nav.candidate_journey_enabled(): check(nav.journey_tasks().size() == 51,"Opt-in task tree includes eleven separate second-act investigations")
	# This branch exercises real opt-in flags with in-memory navigation only.
	if "--candidate-journey" in OS.get_cmdline_user_args():
		var localization: Node = root.get_node("Localization")
		var previous_locale: String = localization.current_locale()
		for locale: String in ["zh_CN","en"]:
			localization.set_locale(locale)
			nav.last_visited_task = nav.candidate_key("prediction",2)
			check(nav.resume_title().contains("交替") if locale == "zh_CN" else nav.resume_title().contains("Alternating"),"Temporary Prediction retains its exact task location")
			check(not nav.has_resume(),"Discarded Prediction is not recoverable exploration")
			check(nav.home_action_text() == ("重新探索预测" if locale == "zh_CN" else "Reopen Prediction"),"Prediction primary honestly reopens a temporary workshop")
			check(nav.next_task_title().contains("不保留") if locale == "zh_CN" else nav.next_task_title().contains("not retained"),"Prediction summary explicitly names the temporary boundary")
			if preload("res://src/campaign/second_act_tasks.gd").paths().is_empty():
				for domain: String in ["representation","service"]:
					nav.last_visited_task = nav.candidate_key(domain,0)
					check(not nav.has_resume(),"Unbound "+domain+" is not advertised as restored work")
					check(nav.home_action_text() == ("重新打开临时工作台" if locale == "zh_CN" else "Reopen temporary workshop"),"Unbound "+domain+" reopens without promising saved continuation")
					check(nav.next_task_title().contains("不保留") if locale == "zh_CN" else nav.next_task_title().contains("not retained"),"Unbound "+domain+" summary marks session-only exploration")
		localization.set_locale(previous_locale)
		nav.last_visited_task = previous_last_visited
	var base: String = "user://unified-journey-"+Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(base) == OK,"Independent QA directory exists")
	var old_rep: String = RS.PATH; var old_service: String = SS.PATH
	RS.PATH = base.path_join("representation.json"); SS.PATH = base.path_join("service.json")
	var accepted: Array[Dictionary] = [{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}]
	var alternate: Array[Dictionary] = [{"start":0,"end":32,"codec":"raw"},{"start":32,"end":64,"codec":"raw"}]
	var drafts: Array = []
	for index: int in 5: drafts.append(alternate if index == 2 else RM.initial_plan())
	var rep_raw: String = RS.encode(4,drafts,[{"task":0,"plan":accepted}])
	write_fixture(RS.PATH,rep_raw)
	target(nav,"representation",2)
	var rep := RepresentationProbe.new(); rep.candidate_journey = true; rep.persistent_session = true
	root.add_child(rep); await process_frame; await process_frame
	check(rep.task == 2 and rep.plan == alternate and nav.pending.is_empty(),"Representation consumes the exact tree target after restoring its task4 save")
	check(rep.history.size() == 1 and rep.history[0].task == 0 and rep.selected_run == 0,"Changing target retains the immutable saved record and its original task")
	check(rep.completed[0] and not rep.completed[2] and rep.support_plans.size() == 1,"Saved recipes are revalidated; target selection and drafts grant no completion")
	rep.change_task(1); rep.change_task(2)
	check(rep.plan == alternate and rep.drafts[4].plan == RM.initial_plan(),"Existing per-task drafts survive tree entry and local task switching")
	if nav.candidate_journey_enabled(): check(nav.selected == nav.candidate_key("representation",2),"Opt-in navigation remembers the Representation task actually opened")
	rep.request_hub()
	var guard := rep.get_node("UnsavedSessionDialog") as ConfirmationDialog
	cancel(guard)
	check(rep.departures == 0 and rep.task == 2 and rep.plan == alternate and rep.session_dirty and nav.from_tree,"Cancel map return keeps Representation exploration and navigation context")
	rep.request_hub(); rep.save_blocked = true; guard.hide(); guard.confirmed.emit()
	check(rep.departures == 0 and rep.session_dirty and not rep.leave_to_hub,"Failed Save cannot leave and clears the stale departure request")
	rep.request_hub(); guard.hide(); guard.custom_action.emit(&"discard")
	check(rep.departures == 1 and rep.departed_to_map and FileAccess.get_file_as_string(RS.PATH) == rep_raw,"Discard returns toward the map without changing the saved Representation profile")
	rep.save_blocked = false; rep.request_hub(); guard.hide(); guard.confirmed.emit()
	check(rep.departures == 2 and not rep.session_dirty and RS.read_session().task == 2 and RS.read_session().drafts[2] == alternate,"Explicit Save persists the selected task and exact draft before map departure")
	rep.queue_free(); await process_frame; await process_frame
	var final_plan: Dictionary = SM.initial_plan(); final_plan.slots = 4
	final_plan.representations = ["rle64","rle64","raw64","raw64"]
	check(SM.accepted(SM.run(final_plan).metrics,2),"Service support fixture meets the actual final contract")
	var shared: Dictionary = SM.initial_plan()
	var service_raw: String = SS.encode(0,shared,[],[{"task":2,"plan":final_plan}])
	write_fixture(SS.PATH,service_raw); target(nav,"service",1)
	var service := ServiceProbe.new(); service.candidate_journey = true; service.persistent_session = true
	root.add_child(service); await process_frame; await process_frame
	check(service.task == 1 and service.unlocked == 2 and nav.pending.is_empty(),"Service restores its existing support-based unlock before consuming the selected task")
	check(service.plan == shared and service.support_plans.size() == 1 and service.history.is_empty(),"Service preserves its shared draft; protected saved support does not fabricate a comparison receipt")
	service.change_task(2); check(service.plan == shared,"Local Service task switching retains the same shared draft")
	if nav.candidate_journey_enabled(): check(nav.selected == nav.candidate_key("service",2),"Opt-in navigation follows the Service contract actually opened")
	service.request_hub(); guard = service.get_node("UnsavedServiceDialog") as ConfirmationDialog
	cancel(guard)
	check(service.departures == 0 and service.task == 2 and service.plan == shared and service.session_dirty and nav.from_tree,"Cancel map return preserves Service task, shared draft and navigation")
	service.request_hub(); service.save_blocked = true; guard.hide(); guard.confirmed.emit()
	check(service.departures == 0 and service.session_dirty and not service.leave_to_hub,"Failed Service Save cannot leave or keep a stale destination")
	service.request_hub(); guard.hide(); guard.custom_action.emit(&"discard")
	check(service.departures == 1 and service.departed_to_map and FileAccess.get_file_as_string(SS.PATH) == service_raw,"Discard returns toward the map without overwriting saved Service evidence")
	service.queue_free(); await process_frame; await process_frame
	write_fixture(SS.PATH,SS.encode(2,shared,[],[{"task":2,"plan":shared}]))
	target(nav,"service",2)
	service = ServiceProbe.new(); service.candidate_journey = true; service.persistent_session = true
	root.add_child(service); await process_frame; await process_frame
	check(service.task == 0 and service.unlocked == 0 and service.support_plans.is_empty() and nav.pending.is_empty(),"Unsuccessful saved supports and forged pending targets cannot bypass Service unlocks")
	if nav.candidate_journey_enabled(): check(nav.selected == nav.candidate_key("service",0),"Refused locked target records the accessible Service task actually restored")
	service.queue_free(); await process_frame; await process_frame
	target(nav,"prediction",2)
	var prediction := PredictionProbe.new(); prediction.candidate_journey = true
	root.add_child(prediction); await process_frame; await process_frame
	check(prediction.task == 2 and nav.pending.is_empty() and prediction.history.is_empty(),"Prediction opens the precise optional tree investigation without granting evidence")
	if nav.candidate_journey_enabled(): check(nav.selected == nav.candidate_key("prediction",2),"Opt-in navigation locates the temporary Prediction investigation actually opened")
	prediction.step_current()
	var observation: Dictionary = prediction.public_observation()
	var signature: String = prediction.active_trace.canonical_signature()
	var policy: Dictionary = prediction.policy.duplicate(true)
	prediction.request_hub(); guard = prediction.get_node("LeavePredictionDialog") as ConfirmationDialog
	check(guard.ok_button_text.contains("地图") or guard.ok_button_text.contains("map"),"Temporary discard warning names the actual task-map destination")
	cancel(guard)
	check(prediction.departures == 0 and prediction.policy == policy and prediction.public_observation() == observation and prediction.active_trace.canonical_signature() == signature and nav.from_tree,"Cancel preserves the temporary policy, revealed prefix, hidden trace and map context")
	prediction.request_hub(); guard.hide(); guard.confirmed.emit()
	check(prediction.departures == 1 and prediction.departed_to_map,"Prediction leaves toward the map only after explicit temporary discard")
	prediction.queue_free(); await process_frame; await process_frame
	var after: Dictionary = save._save_snapshot(); after.erase("saved_at_utc")
	check(before == after and nav.tasks().size() == 40,"Unified host navigation writes no core progress or completion authority")
	RS.PATH = old_rep; SS.PATH = old_service
	nav.pending = previous_pending; nav.selected = previous_selected; nav.from_tree = previous_from_tree; nav.last_visited_task = previous_last_visited
	print("PASS: test_unified_journey_navigation " if failures == 0 else "FAIL: test_unified_journey_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
