extends SceneTree
const Store = preload("res://experiments/service_plan/session_store.gd")
const Model = preload("res://experiments/service_plan/model.gd")
class LeaveProbe extends "res://experiments/service_plan/lab.gd":
	var destinations: Array[bool] = []
	func finish_leave() -> void: destinations.append(leave_to_hub)

var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func remove_fixture() -> void:
	for suffix: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(Store.PATH+suffix): DirAccess.remove_absolute(Store.PATH+suffix)
func authority(scene: Node) -> String:
	return JSON.stringify({"history":scene.history,"supports":scene.support_plans,"unlocked":scene.unlocked})

func run() -> void:
	# This suite runs only in the verifier's fresh isolated candidate directory.
	remove_fixture()
	root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
	var campaign_before: String = JSON.stringify(root.get_node("LocalityChapter").completed_levels())
	var baseline: Dictionary = Model.initial_plan()
	var resident: Dictionary = baseline.duplicate(true); resident.slots = 4
	var lossless: Dictionary = resident.duplicate(true); lossless.representations = ["rle64","rle64","raw64","raw64"]
	var scene := LeaveProbe.new(); scene.persistent_session = true; root.add_child(scene)
	await process_frame; await process_frame
	var shelf := scene.design_shelf
	check(not shelf.content.visible,"Named collection starts collapsed beside history")
	check(shelf.remember_button.disabled,"Unrun draft has no collectable measured record")
	scene.remember_design("Unrun")
	check(scene.designs.is_empty(),"Naming an unrun draft does not create a design")
	scene.run_current()
	check(str(scene.history[0].metrics.error).is_empty() and not Model.accepted(scene.history[0].metrics,0),"Fixture executes successfully while missing contract1")
	scene.edit(resident,0)
	shelf.design_name.text = "Pending player name"
	scene.group_list.item_selected.emit(0)
	check(shelf.design_name.text == "Pending player name","Selecting a draft group preserves the pending name for the same measured source")
	shelf.toggle.button_pressed = true
	await process_frame; await process_frame
	check(scene.find_child("SaveSession",true,false).get_global_rect().end.y <= 720,"Opening collection keeps Save inside minimum viewport")
	var before: String = authority(scene)
	scene.remember_design("  My measured baseline  ")
	check(scene.designs.size() == 1 and scene.designs[0].plan == baseline and scene.designs[0].task == 0,"Naming collects selected history rather than changed draft")
	check(scene.designs[0].name == "My measured baseline" and scene.session_dirty,"Naming trims the name and marks explicit unsaved work")
	check(authority(scene) == before and scene.plan == resident,"Naming leaves history, draft and completion authority unchanged")
	scene.remember_design("Renamed baseline")
	check(scene.designs.size() == 1 and scene.designs[0].name == "Renamed baseline","Naming the same task/plan renames one collected design")
	for name: String in ["   ","Bad\nname","x".repeat(49)]:
		scene.remember_design(name)
		check(scene.designs.size() == 1 and scene.designs[0].name == "Renamed baseline","Invalid design name cannot change collection")
	var selected_copy: Dictionary = scene.selected_design_record(); selected_copy.plan.slots = 3
	check(scene.designs[0].plan == baseline and scene.history[0].metrics.plan == baseline,"Collected and selected plan copies do not share mutable history data")
	scene.task = 2; scene.unlocked = 2; scene.commission_mode = 0
	before = authority(scene)
	var trace_before: RefCounted = scene.active_trace
	scene.restore_design(0)
	check(scene.task == 0 and scene.commission_mode == -1 and scene.plan == baseline,"Collection restore returns to its original task and leaves optional commission mode")
	check(authority(scene) == before and scene.active_trace == trace_before,"Restoring does not run, create supports or change unlocks")
	scene.undo()
	check(scene.plan == resident and scene.task == 0 and scene.designs[0].plan == baseline,"Existing Undo restores prior draft while retaining original task and collected design")
	scene.redo(); check(scene.plan == baseline,"Existing Redo restores the copied named draft")
	scene.unlocked = 0
	# A valid, even contract-accepted recipe in a collection has no unlock authority.
	scene.designs.append({"task":2,"plan":lossless.duplicate(true),"name":"Final alternative"})
	before = JSON.stringify({"draft":scene.plan,"task":scene.task,"authority":authority(scene)})
	scene.restore_design(1)
	check(JSON.stringify({"draft":scene.plan,"task":scene.task,"authority":authority(scene)}) == before,"Locked original task refuses restoration without granting access")
	scene.edit(Model.move(baseline,4,-4),0); scene.run_current()
	check(shelf.remember_button.disabled and scene.selected_design_record().is_empty(),"Rejected preflight record cannot be collected")
	scene.remember_design("Rejected")
	check(scene.designs.size() == 2,"Rejected measurement does not enter named collection")
	scene.selected_history = -1; scene.refresh_actions(); scene.remember_design("No selection")
	check(scene.designs.size() == 2 and shelf.remember_button.disabled,"No selected measurement cannot name the current draft")
	# Fill rolling history with detached real measurements, then exercise its eviction.
	var old: Dictionary = scene.history[0].duplicate(true)
	scene.edit(resident,0); scene.run_current()
	var later: Dictionary = scene.history[-1].duplicate(true)
	scene.history.clear(); scene.history.append(old)
	for index: int in 79: scene.history.append(later.duplicate(true))
	scene.selected_history = 79; scene.run_current()
	check(scene.history.size() == 80 and scene.history[0].metrics.plan == resident,"Rolling history evicts the originally named measurement after80 newer records")
	check(scene.designs[0].plan == baseline,"Named design survives eviction independently of measured history")
	scene.save_session()
	check(not scene.session_dirty and int(JSON.parse_string(FileAccess.get_file_as_string(Store.PATH)).schema) == 3,"Explicit Save persists named collection in schema3")
	check(Store.read_session().designs == scene.designs,"Saved named plan, name and original task roundtrip")
	var saved_designs: Array[Dictionary] = []; saved_designs.assign(scene.designs.duplicate(true))
	scene.remove_design(0)
	check(scene.session_dirty and scene.designs.size() == 1 and Store.read_session().designs == saved_designs,"Removing a design changes only unsaved local collection")
	scene.request_quit()
	var guard := scene.get_node("UnsavedServiceDialog") as ConfirmationDialog
	check(guard.visible and scene.destinations.is_empty(),"Unsaved design removal uses existing leave guard")
	guard.canceled.emit(); guard.hide()
	check(scene.session_dirty and scene.designs.size() == 1,"Keep editing retains unsaved collection removal")
	scene.save_blocked = true; scene.request_quit(); guard.confirmed.emit(); guard.hide()
	check(scene.session_dirty and scene.destinations.is_empty() and Store.read_session().designs == saved_designs,"Blocked Save cannot overwrite collection or leave")
	scene.save_blocked = false
	scene.queue_free(); await process_frame; await process_frame
	var reopened := LeaveProbe.new(); reopened.persistent_session = true; root.add_child(reopened)
	await process_frame; await process_frame
	check(reopened.designs == saved_designs and not reopened.session_dirty,"Independent reopen restores saved collection and discards unsaved removal")
	check(reopened.unlocked == 0 and reopened.support_plans.is_empty() and not reopened.has_service_closure(),"Saved collection cannot create contract supports, unlocks or closure")
	check(reopened.history.size() == 80 and reopened.history[0].metrics.plan == resident,"Reopen retains rolled history independently of named baseline")
	for locale: bool in [false,true]:
		reopened.english = locale; reopened.build(); await process_frame; await process_frame
		check(not reopened.design_shelf.content.visible,"Bilingual rebuilt shelf stays compact by default")
		reopened.design_shelf.toggle.button_pressed = true; await process_frame; await process_frame
		for control_name: String in ["DesignName","RememberDesign","NamedDesigns","RestoreDesign","RemoveDesign"]:
			var control := reopened.find_child(control_name,true,false) as Control
			check(control != null and control.is_visible_in_tree() and control.get_global_rect().end.x <= 1280 and control.get_global_rect().end.y <= 720,"Bilingual expanded named controls fit minimum viewport: "+control_name)
	# Confirmed full reload replaces all local collection state from disk.
	reopened.designs.append({"task":0,"plan":Model.represent(resident,0,"raw8"),"name":"Unsaved extra"})
	reopened.mark_session_dirty(); reopened.reload_recovered_session(); await process_frame
	check(reopened.designs == saved_designs and not reopened.session_dirty,"Confirmed reload clears unsaved collection before restoring disk")
	reopened.remove_design(1); reopened.save_session()
	check(Store.read_session().designs.size() == 1 and not reopened.session_dirty,"Explicit Save retains collection deletion")
	check(campaign_before == JSON.stringify(root.get_node("LocalityChapter").completed_levels()),"Named Service designs leave formal campaign progress unchanged")
	reopened.queue_free(); await process_frame; await process_frame; remove_fixture()
	print("PASS: test_service_design_shelf " if failures == 0 else "FAIL: test_service_design_shelf ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
