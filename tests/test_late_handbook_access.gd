extends SceneTree

var handbook_script: Script

class CreationProfile:
	extends "res://experiments/creation/session.gd"
	var isolated_path: String
	func open(_save_path: String = "") -> Dictionary: return super.open(isolated_path)

class CreationProbe:
	extends "res://experiments/creation/workbench.gd"
	var departures: int = 0
	func finish_leave() -> void: departures += 1

class RepresentationProbe:
	extends "res://experiments/representation_region/region.gd"
	var departures: int = 0
	func finish_leave() -> void: departures += 1

class ServiceProbe:
	extends "res://experiments/service_plan/lab.gd"
	var departures: int = 0
	func finish_leave() -> void: departures += 1

class PredictionProbe:
	extends "res://experiments/prediction/lab.gd"
	var departures: int = 0
	func finish_leave() -> void: departures += 1

var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func key(code: Key) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event,true)
		await process_frame
	await settle()

func fits(control: Control) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var bounds: Rect2 = root.get_visible_rect()
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents: bounds = bounds.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return bounds.grow(1).encloses(control.get_global_rect())

func progress() -> Dictionary:
	var snapshot: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	snapshot.erase("saved_at_utc")
	return snapshot

func draft(scene: Control, domain: String) -> Dictionary:
	match domain:
		"creation": return scene.session.data.duplicate(true)
		"prediction": return scene.policy.duplicate(true)
	return {"plan":scene.plan.duplicate(true),"supports":scene.support_plans.duplicate(true)}

func handbook_count(scene: Control) -> int:
	var count: int = 0
	for node: Node in scene.find_children("*","",true,false):
		if node.get_script() == handbook_script: count += 1
	return count

func capture(label: String) -> void:
	if "--handbook-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var folder: String = "user://late-handbook-captures"
	check(DirAccess.make_dir_recursive_absolute(folder) == OK,"Create isolated handbook capture directory")
	check(root.get_texture().get_image().save_png(folder.path_join(label+".png")) == OK,"Capture actual handbook "+label)

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run late handbook checks through the isolated verifier.")
		quit(1)
		return
	handbook_script = load("res://src/ui/terminology_handbook.gd") as Script
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	ProjectSettings.set_setting("game/full_journey",false)
	ProjectSettings.set_setting("playtest/offline_tester",true)
	root.get_node("GameMode").set_mode(&"game")
	root.get_node("GlobalSave").configure_for_test("user://handbook-progress.json","user://handbook-workbenches.json")
	var original: Dictionary = progress()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for domain: String in ["representation","service","prediction","creation"]:
			root.get_node("TaskNavigation").pending = ""
			var scene: Control
			match domain:
				"representation": scene = RepresentationProbe.new()
				"service": scene = ServiceProbe.new()
				"prediction": scene = PredictionProbe.new()
				"creation":
					scene = CreationProbe.new()
					var profile := CreationProfile.new()
					profile.isolated_path = "user://late-handbook-"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
					scene.session = profile
			if domain != "creation": scene.candidate_journey = true
			root.add_child(scene)
			scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			await settle()
			var context: String
			var term: StringName
			match domain:
				"representation":
					scene.change_task(3)
					var plan: Array[Dictionary] = scene.plan.duplicate(true)
					plan[0].codec = "rle"; scene.edit_plan(plan)
					context = "representation:prepare_once"; term = &"online_preparation"
				"service":
					scene.change_task(2)
					var plan: Dictionary = scene.plan.duplicate(true)
					plan.slots = 2 if int(plan.slots) != 2 else 3
					scene.edit(plan,0)
					context = "service:one_plan"; term = &"quantization"
				"prediction":
					scene.change_task(2); scene.rule.select(1); scene.edit_policy()
					context = "prediction:alternating"; term = &"address_prediction"
				"creation":
					scene.change_task(8); scene.session.data.draft.seed += 1; scene.edit_draft()
					context = "creation:G3_keep"; term = &"work_recipe"
			await settle()
			var prefix: String = locale+" "+domain+": "
			var handbook: Control = scene.terminology_handbook
			var before: Dictionary = draft(scene,domain)
			check(handbook_count(scene) == 1 and handbook.entry_button.get_parent() != handbook,prefix+"one handbook has its entry in the workbench navigation")
			check(fits(handbook.entry_button),prefix+"handbook entry fits 1280x720")
			handbook.entry_button.pressed.emit(); await settle()
			check(handbook.is_open() and String(handbook.context_lesson) == context,prefix+"actual task change sets the handbook context")
			check(handbook.recommended_toggle.button_pressed and term in handbook.visible_term_ids and handbook.is_term_unlocked(term),prefix+"the corresponding concept is recommended and available without earned completion")
			check(root.gui_get_focus_owner() == handbook.search_edit and fits(handbook.close_button),prefix+"opening focuses search and exposes the close action")
			check(handbook.modal.size == root.get_visible_rect().size and handbook.detail_scroll_container.size.y >= 248,prefix+"the reading layer fills the actual scene and leaves room for its diagram")
			await capture(locale+"-"+domain)
			handbook.close_button.grab_focus(); await key(KEY_ESCAPE)
			check(not handbook.is_open() and scene.departures == 0 and scene.is_inside_tree(),prefix+"Escape closes only the handbook")
			check(root.gui_get_focus_owner() == handbook.entry_button and draft(scene,domain) == before,prefix+"closing restores entry focus without losing edits")
			handbook.entry_button.pressed.emit(); await settle()
			handbook.close_button.grab_focus(); await key(KEY_F10)
			var mode: Node = root.get_node("WindowMode")
			check(is_instance_valid(mode.settings_layer) and handbook.is_open(),prefix+"settings can temporarily cover the handbook")
			await key(KEY_ESCAPE)
			check(not is_instance_valid(mode.settings_layer) and handbook.is_open() and scene.departures == 0,prefix+"Escape closes settings before the handbook")
			handbook.close_handbook()
			for iteration: int in 2:
				scene.toggle_language(); await settle()
				handbook = scene.terminology_handbook
				check(handbook_count(scene) == 1 and scene.find_children("TerminologyButton","Button",true,false).size() == 1,prefix+"language rebuild keeps one handbook and entry")
				handbook.entry_button.pressed.emit(); await settle()
				check(String(handbook.context_lesson) == context and term in handbook.visible_term_ids,prefix+"rebuilt handbook retains the selected task recommendation")
				handbook.close_handbook()
			check(draft(scene,domain) == before and progress() == original and scene.departures == 0,prefix+"reading and language rebuilds neither change the draft nor grant game progress")
			scene.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ")+"late handbook access %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
