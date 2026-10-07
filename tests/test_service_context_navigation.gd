extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
# The autoload script depends on other autoload identifiers; compile this probe only
# after SceneTree initialization, as existing navigation suites load their hosts.
const NAVIGATION_PROBE_SOURCE: String = """extends "res://src/campaign/task_navigation.gd"
var visits: Array[String] = []
func candidate_journey_enabled() -> bool: return true
func remember_candidate_visit(domain: String, index: int) -> void:
	visits.append("%s/%d" % [domain,index])
	super.remember_candidate_visit(domain,index)
"""

var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func evidence(scene: Lab) -> String:
	return JSON.stringify({"history":scene.history,"supports":scene.support_plans,"unlocked":scene.unlocked})

func run() -> void:
	# Use real navigation memory with candidate presentation enabled; Test mode blocks cfg writes.
	var mode: Node = root.get_node("GameMode")
	var previous_mode: StringName = mode.current_mode
	check(mode.set_mode(&"test"),"Isolated navigation assertions use Test mode")
	var navigation_script := GDScript.new()
	navigation_script.source_code = NAVIGATION_PROBE_SOURCE
	var reload_error: Error = navigation_script.reload()
	check(reload_error == OK,"Navigation probe compiles after autoload initialization")
	if reload_error != OK:
		mode.set_mode(previous_mode)
		print("FAIL: test_service_context_navigation probe compile ",reload_error)
		quit(1); return
	var original_navigation: Node = root.get_node("TaskNavigation")
	root.remove_child(original_navigation)
	var navigation: Node = navigation_script.new(); navigation.name = "TaskNavigation"; root.add_child(navigation)
	var config_existed: bool = FileAccess.file_exists(navigation.NAVIGATION_PATH)
	var config_before := FileAccess.get_file_as_bytes(navigation.NAVIGATION_PATH) if config_existed else PackedByteArray()
	navigation.last_visited_task = "hardware_foundations/tutorial"
	var scene := Lab.new(); root.add_child(scene); await process_frame
	scene.previous_auto_quit = auto_accept_quit; scene.persistent_session = true
	var baseline: Dictionary = Model.initial_plan()
	scene.designs.append({"task":0,"plan":baseline.duplicate(true),"name":"Original contract"})
	scene.task = 2; scene.unlocked = 2; scene.commission_mode = 0
	navigation.selected = navigation.candidate_key("service",2)
	navigation.visits.clear()
	var before: String = evidence(scene)
	scene.restore_design(0)
	check(scene.task == 0 and scene.commission_mode == -1 and scene.plan == baseline,"Restoring an identical recipe still switches to its original contract")
	check(navigation.visits == ["service/0"],"Successful cross-contract restore remembers the contract actually opened")
	check(navigation.selected == navigation.candidate_key("service",0) and scene.session_dirty,"Real navigation selects the restored contract and retains explicit unsaved work")
	check(evidence(scene) == before and scene.undo_stack.is_empty(),"Navigation synchronization neither measures nor creates an unnecessary draft edit")
	scene.restore_design(0)
	check(navigation.visits == ["service/0"],"Repeating a restore in the same context does not create a new visit")

	scene.unlocked = 0
	scene.session_dirty = false
	scene.designs.append({"task":2,"plan":baseline.duplicate(true),"name":"Locked contract"})
	var invalid: Dictionary = baseline.duplicate(true); invalid.slots = 0
	scene.designs.append({"task":0,"plan":invalid,"name":"Invalid recipe"})
	before = JSON.stringify({"draft":scene.plan,"task":scene.task,"evidence":evidence(scene)})
	for index: int in [-1,1,2,3]: scene.restore_design(index)
	check(navigation.visits == ["service/0"],"Locked, invalid and nonexistent recipes never change navigation memory")
	check(navigation.selected == navigation.candidate_key("service",0) and not scene.session_dirty,"Rejected recipes preserve the real selection and clean state")
	check(JSON.stringify({"draft":scene.plan,"task":scene.task,"evidence":evidence(scene)}) == before,"Rejected restores retain the current draft, contract and earned evidence")
	scene.start_commission(0)
	check(scene.task == 0 and scene.commission_mode == -1 and navigation.visits == ["service/0"],"Unearned optional commission cannot change the task or remembered visit")

	# Publicly accepted recipes are synthetic fixtures, not player completion evidence.
	var grouped: Dictionary = Model.initial_plan(); grouped.groups = []
	for request: int in 24: grouped.groups.append([request])
	var lossless: Dictionary = Model.initial_plan(); lossless.slots = 4
	lossless.representations = ["rle64","rle64","raw64","raw64"]
	scene.support_plans = {0:grouped,1:lossless,2:lossless}; scene.unlocked = 2
	check(scene.has_service_closure(),"Commission fixture contains three genuinely qualifying protected plans")
	before = evidence(scene)
	scene.start_commission(-1); scene.start_commission(3)
	check(scene.task == 0 and navigation.visits == ["service/0"],"Out-of-range commissions do not alter the remembered contract")
	scene.start_commission(0)
	check(scene.task == 2 and scene.commission_mode == 0 and navigation.visits == ["service/0","service/2"],"Entering an earned follow-up remembers Task3 for subsequent continuation")
	check(navigation.selected == navigation.candidate_key("service",2) and scene.session_dirty,"Real navigation selects the successful commission's actual contract")
	check(scene.evidence_tabs.current_tab == 4 and evidence(scene) == before and scene.plan == baseline,"Commission navigation preserves its page, draft and all measured/support authority")
	scene.start_commission(1)
	check(scene.commission_mode == 1 and navigation.visits == ["service/0","service/2"],"Changing an optional specification within Task3 does not create a task visit")
	scene.designs.append({"task":2,"plan":baseline.duplicate(true),"name":"Task3 draft"})
	scene.restore_design(3)
	check(scene.task == 2 and scene.commission_mode == -1 and navigation.visits[-1] == "service/2","Leaving a commission through its original-contract design retains Task3 navigation")
	check(evidence(scene) == before,"Returning from a commission cannot grant new progress or replace measured records")
	check(navigation.last_visited_task == "hardware_foundations/tutorial","Test mode leaves persistent continuation preference untouched")
	check(FileAccess.file_exists(navigation.NAVIGATION_PATH) == config_existed and (not config_existed or FileAccess.get_file_as_bytes(navigation.NAVIGATION_PATH) == config_before),"Navigation regression never writes task_navigation.cfg")

	scene.queue_free(); await process_frame
	root.remove_child(navigation); navigation.queue_free(); root.add_child(original_navigation)
	mode.set_mode(previous_mode)
	print("PASS: test_service_context_navigation " if failures == 0 else "FAIL: test_service_context_navigation ",checks," checks, ",failures," failures")
	quit(1 if failures > 0 else 0)
