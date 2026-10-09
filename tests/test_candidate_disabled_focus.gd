extends SceneTree
## Viewport Tab/Enter checks for disabled candidate actions; earned review plans are fixtures.
const ServiceModel = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 6: await process_frame

func key(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event,true); await process_frame
	await settle()

func button(scene: Node, handle: String) -> Button:
	return scene.find_child(handle,true,false) as Button

func focused(handle: String) -> bool:
	var owner: Control = root.gui_get_focus_owner()
	return owner != null and owner.name == handle

func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var start: int = 0
	for index: int in ends.size():
		plan.append({"start":start,"end":int(ends[index]),"codec":codecs[index]})
		start = int(ends[index])
	return plan

func run() -> void:
	root.size = Vector2i(1280,720)
	root.get_node("TaskNavigation").pending = ""
	var region = load("res://experiments/representation_region/region.tscn").instantiate()
	root.add_child(region); await settle()
	var closure := button(region,"RegionClosure")
	check(closure.disabled and closure.focus_mode == Control.FOCUS_NONE,"Incomplete Region review cannot receive Tab focus")
	button(region,"Language").grab_focus(); await key(KEY_TAB)
	check(focused("Quit"),"Region header Tab skips disabled review and reaches Quit")
	button(region,"Split").grab_focus(); await key(KEY_TAB)
	check(focused("RLE"),"Region edit Tab skips disabled Merge and Raw")
	await key(KEY_ENTER)
	check(region.plan[0].codec == "rle" and button(region,"Raw").focus_mode == Control.FOCUS_ALL and focused("Undo"),"Viewport RLE activation enables Raw and continues focus to Undo")
	await key(KEY_ENTER)
	check(region.plan[0].codec == "raw" and focused("Redo"),"Exhausting Region Undo continues focus to enabled Redo")
	await key(KEY_ENTER)
	check(region.plan[0].codec == "rle" and focused("Undo"),"Exhausting Region Redo continues focus to enabled Undo")
	button(region,"Split").grab_focus(); await key(KEY_TAB)
	check(focused("Raw"),"Newly enabled Raw re-enters the Region Tab chain")
	await key(KEY_ENTER)
	check(region.plan[0].codec == "raw" and focused("RLE"),"Viewport Raw activation continues focus to enabled RLE")
	var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for index: int in 5: region.support_plans[index] = plans[index]
	region.refresh_tasks(); await settle()
	check(not closure.disabled and closure.focus_mode == Control.FOCUS_ALL,"Validated five-plan fixture enables Region review focus")
	button(region,"Language").grab_focus(); await key(KEY_TAB)
	check(focused("RegionClosure"),"Enabled Region review enters header Tab chain")
	region.queue_free(); await settle()

	var service = load("res://experiments/service_plan/lab.tscn").instantiate()
	root.add_child(service); await settle()
	var service_closure := button(service,"ServiceClosure")
	check(service_closure.disabled and service_closure.focus_mode == Control.FOCUS_NONE,"Incomplete Service review cannot receive Tab focus")
	button(service,"Language").grab_focus(); await key(KEY_TAB)
	check(focused("Quit"),"Service header Tab skips disabled review and reaches Quit")
	button(service,"Task1").grab_focus(); await key(KEY_TAB)
	check(focused("Hint1"),"Service task Tab skips locked Task2 and Task3")
	await key(KEY_ENTER)
	check(service.hint_open and service.task == 0,"Viewport Enter after disabled tasks opens Hint without changing task")
	var per_stream: Dictionary = ServiceModel.initial_plan()
	per_stream.groups = []
	for index: int in 24: per_stream.groups.append([index])
	service.edit(per_stream,0); service.run_current(); await settle()
	check(service.unlocked >= 1 and not button(service,"Task2").disabled and button(service,"Task2").focus_mode == Control.FOCUS_ALL,"Actual accepted Task1 run unlocks Task2 focus")
	var next_button := button(service,"ServiceNext")
	check(not next_button.disabled,"Accepted Task1 run enables continuation")
	next_button.grab_focus(); service.refresh_actions(); await settle()
	check(focused("ServiceNext"),"Refreshing an enabled continuation preserves its keyboard focus")
	button(service,"Task1").grab_focus(); await key(KEY_TAB)
	check(focused("Task2"),"Newly unlocked Task2 enters the Service Tab chain")
	var recorded: String = JSON.stringify({"history":service.history,"supports":service.support_plans,"unlocked":service.unlocked})
	service.undo_button.grab_focus(); await key(KEY_ENTER)
	check(service.plan == ServiceModel.initial_plan() and focused("Redo"),"Service final Undo retains continuation in its enabled Redo action")
	await key(KEY_ENTER)
	check(service.plan == per_stream and focused("Undo") and JSON.stringify({"history":service.history,"supports":service.support_plans,"unlocked":service.unlocked}) == recorded,"Service final Redo returns to Undo without running or changing protected evidence")
	var resident: Dictionary = ServiceModel.initial_plan().duplicate(true); resident.slots = 4
	var lossless: Dictionary = resident.duplicate(true); lossless.representations = ["rle64","rle64","raw64","raw64"]
	service.support_plans[1] = resident
	service.support_plans[2] = lossless
	service.refresh_actions(); await settle()
	check(not service_closure.disabled and service_closure.focus_mode == Control.FOCUS_ALL,"Validated three-plan fixture enables Service review focus")
	button(service,"Language").grab_focus(); await key(KEY_TAB)
	check(focused("ServiceClosure"),"Enabled Service review enters header Tab chain")
	service.queue_free(); await settle()
	print("PASS: candidate disabled focus %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
