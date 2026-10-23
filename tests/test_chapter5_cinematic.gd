extends SceneTree

const Region = preload("res://experiments/representation_region/region.gd")
const Cinematic = preload("res://src/ui/cinematic_player.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var checks: int = 0
var failures: int = 0

class ObservedRegion:
	extends "res://experiments/representation_region/region.gd"
	var presentations: int = 0
	var result_ready: bool = false
	func _present_chapter5_cinematic() -> void:
		presentations += 1
		result_ready = not status.text.is_empty() and selected_run == history.size() - 1 \
			and representation_review_evidence().size() == 5

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = 0
	for index: int in ends.size():
		result.append({"start":start,"end":int(ends[index]),"codec":codecs[index]})
		start = int(ends[index])
	return result

func history_bytes() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(Cinematic.HISTORY_PATH) if FileAccess.file_exists(Cinematic.HISTORY_PATH) else PackedByteArray()

func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run chapter5 cinematic checks through the isolated verifier.")
		quit(1)
		return
	ProjectSettings.set_setting("game/full_journey", false)
	var solutions: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	var before: PackedByteArray = history_bytes()
	var existed: bool = FileAccess.file_exists(Cinematic.HISTORY_PATH)
	var region := ObservedRegion.new()
	region.candidate_journey = true
	root.add_child(region)
	region.change_task(4); region.edit_plan(solutions[4]); region.run_current()
	await process_frame
	check(region.completed[4] and region.presentations == 0, "The final listed task alone does not complete chapter5")
	for task: int in [0,1,3]:
		region.change_task(task); region.edit_plan(solutions[task]); region.run_current()
	region.change_task(2); region.edit_plan(Model.initial_plan()); region.run_current()
	await process_frame
	check(not region.completed[2] and region.presentations == 0, "A failed remaining task does not present the cinematic")
	region.edit_plan(solutions[2]); region.run_current()
	check(region.presentations == 0, "The cinematic waits for the completed result refresh")
	await process_frame
	check(region.presentations == 1 and region.result_ready, "The fifth accepted support triggers once even when it is not task4")
	check(region.history.size() == 6 and not region.persistent_session, "Presentation adds no runs or implicit persistence")
	region.run_current()
	await process_frame
	check(region.presentations == 1, "Repeating an accepted run does not retrigger chapter completion")
	region.queue_free(); await process_frame

	var restored := ObservedRegion.new()
	restored.candidate_journey = true
	for task: int in 5: restored.support_plans[task] = solutions[task].duplicate(true)
	root.add_child(restored)
	restored.change_task(0); restored.edit_plan(solutions[0]); restored.run_current()
	await process_frame
	check(restored.presentations == 0, "An already completed set of loaded supports does not retrigger on another run")
	restored.queue_free(); await process_frame
	var blocked := ObservedRegion.new()
	blocked.candidate_journey = true
	root.add_child(blocked)
	blocked.persistent_session = true
	blocked.save_blocked = true
	for task: int in [0,1,2,3]: blocked.support_plans[task] = solutions[task].duplicate(true)
	blocked.change_task(4); blocked.edit_plan(solutions[4]); blocked.run_current()
	await process_frame
	check(blocked.presentations == 1 and blocked.result_ready and blocked.session_dirty, "A blocked writer retains the first completion and its unsaved result")
	blocked.save_blocked = false
	blocked.run_current()
	await process_frame
	check(blocked.presentations == 1, "Recovering the writer and repeating a run does not retrigger chapter completion")
	blocked.queue_free(); await process_frame

	var standalone := ObservedRegion.new()
	root.add_child(standalone)
	for task: int in 5:
		standalone.change_task(task); standalone.edit_plan(solutions[task]); standalone.run_current()
	await process_frame
	check(standalone.presentations == 0, "A standalone representation experiment does not play the journey cinematic")
	standalone.queue_free(); await process_frame

	# Exercise the real presenter rather than the observation subclass.
	var automated: Control = Region.new()
	automated.candidate_journey = true
	root.add_child(automated)
	for task: int in 5:
		automated.change_task(task); automated.edit_plan(solutions[task]); automated.run_current()
	await process_frame
	check(get_nodes_in_group("cinematic_playback").is_empty() and not paused, "Automated chapter completion does not open a modal or pause")
	check(history_bytes() == before and FileAccess.file_exists(Cinematic.HISTORY_PATH) == existed, "Automated chapter completion leaves cinematic history unchanged")
	var mode: Node = root.get_node("GameMode")
	var previous_mode: StringName = mode.current_mode
	mode.set_mode(&"test")
	automated._present_chapter5_cinematic()
	check(get_nodes_in_group("cinematic_playback").is_empty() and history_bytes() == before, "Test mode does not present or consume chapter5 cinematic history")
	mode.set_mode(previous_mode)
	automated.queue_free(); await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ") + "chapter5 cinematic %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
