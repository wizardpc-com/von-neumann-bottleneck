extends SceneTree
## Synthetic viewport keys exercise existing leave guards without changing scenes.
class CreationProbe extends "res://experiments/creation/workbench.gd":
	var departures: int = 0
	func finish_leave() -> void: departures += 1
class RepresentationProbe extends "res://experiments/representation_region/region.gd":
	var departures: int = 0
	func finish_leave() -> void: departures += 1
class ServiceProbe extends "res://experiments/service_plan/lab.gd":
	var departures: int = 0
	func finish_leave() -> void: departures += 1
class PredictionProbe extends "res://experiments/prediction/lab.gd":
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
func key(code: Key, echo: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code
		event.pressed = down; event.echo = echo and down
		root.push_input(event, true); await process_frame
	await settle()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var nav: Node = root.get_node("TaskNavigation")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for kind: String in ["creation", "representation", "service", "prediction"]:
			nav.pending = ""
			var scene: Control
			match kind:
				"creation": scene = CreationProbe.new()
				"representation": scene = RepresentationProbe.new()
				"service": scene = ServiceProbe.new()
				"prediction": scene = PredictionProbe.new()
			root.add_child(scene); await settle()
			var prefix: String = locale + " " + kind + ": "
			# Settings owns Esc before the underlying workbench can leave.
			await key(KEY_F10)
			var mode: Node = root.get_node("WindowMode")
			check(is_instance_valid(mode.settings_layer), prefix + "F10 opens Settings")
			await key(KEY_ESCAPE)
			check(not is_instance_valid(mode.settings_layer) and scene.departures == 0, prefix + "Esc closes only Settings")
			await key(KEY_ESCAPE, true)
			check(scene.departures == 0, prefix + "Esc repeat cannot navigate")
			var guard: ConfirmationDialog
			var before: Dictionary
			match kind:
				"creation":
					scene.session.data.draft.seed += 1; scene.edit_draft()
					before = scene.session.data.duplicate(true)
					guard = scene.leave_dialog
				"representation":
					scene.plan[0].codec = "rle"; scene.session_dirty = true
					before = {"plan": scene.plan.duplicate(true)}
				"service":
					scene.session_dirty = true
					before = {"plan": scene.plan.duplicate(true)}
				"prediction":
					scene.rule.select(1); scene.edit_policy()
					before = scene.policy.duplicate(true)
			await key(KEY_ESCAPE)
			match kind:
				"representation": guard = scene.get_node_or_null("UnsavedSessionDialog")
				"service": guard = scene.get_node_or_null("UnsavedServiceDialog")
				"prediction": guard = scene.get_node_or_null("LeavePredictionDialog")
			check(guard != null and guard.visible and scene.departures == 0, prefix + "Esc uses the unsaved-work guard")
			if guard != null:
				await create_timer(0.3).timeout
				await key(KEY_ESCAPE)
				check(not guard.visible and scene.departures == 0, prefix + "Esc in the guard cancels departure")
			match kind:
				"creation": check(scene.session.data == before, prefix + "Cancel preserves the draft and works")
				"representation", "service": check(scene.plan == before.plan, prefix + "Cancel preserves the plan")
				"prediction": check(scene.policy == before, prefix + "Cancel preserves the policy")
			if kind == "creation":
				var tabs := scene.find_child("DraftTabs", true, false) as TabContainer
				tabs.current_tab = 0; await settle()
				var entry := scene.find_child("CustomExample", true, false) as LineEdit
				entry.text = "A B"; entry.grab_focus()
				await key(KEY_ESCAPE)
				check(not guard.visible and entry.text == "A B" and not entry.is_editing(), prefix + "First Esc ends text editing without losing text")
				await key(KEY_ESCAPE)
				check(guard.visible, prefix + "Next Esc uses the draft guard")
				await create_timer(0.3).timeout
				await key(KEY_ESCAPE)
				scene.begin_sample_edit(0); await settle()
				var sample := scene.find_child("SampleEditText", true, false) as LineEdit
				sample.text = "invalid"; sample.grab_focus()
				await key(KEY_ESCAPE)
				check(not scene.sample_leave_dialog.visible and sample.text == "invalid", prefix + "First sample Esc keeps pending text")
				await key(KEY_ESCAPE)
				check(scene.sample_leave_dialog.visible and not scene.leave_dialog.visible, prefix + "Pending sample protection precedes the draft guard")
				await create_timer(0.3).timeout
				await key(KEY_ESCAPE)
				check(sample.text == "invalid" and scene.departures == 0, prefix + "Cancel preserves unsubmitted sample text")
			scene.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "workbench Escape %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
