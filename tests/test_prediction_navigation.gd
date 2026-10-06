extends SceneTree
## Synthetic navigation checks retain public evidence; no authored winning policy.
class NavigationProbe extends "res://experiments/prediction/lab.gd":
	var departed: int = 0
	var departed_home: bool = false
	func finish_leave() -> void:
		departed += 1; departed_home = leave_to_hub

var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func control(scene: Node, handle: String) -> Button:
	return scene.find_child(handle,true,false) as Button
func cancel(scene: Node) -> void:
	var dialog := scene.get_node("LeavePredictionDialog") as ConfirmationDialog
	dialog.hide(); dialog.canceled.emit()

func run() -> void:
	root.size = Vector2i(1280,720)
	var original_auto_quit: bool = auto_accept_quit
	var localization: Node = root.get_node("Localization")
	var original_locale: String = localization.current_locale()
	var save: Node = root.get_node("GlobalSave")
	var campaign_before: Dictionary = save._save_snapshot(); campaign_before.erase("saved_at_utc")
	for english: bool in [false,true]:
		localization.set_locale("en" if english else "zh_CN")
		var scene := NavigationProbe.new(); scene.candidate_journey = true
		root.add_child(scene); await process_frame; await process_frame
		check(scene.english == english,"Prediction follows the shared current language")
		check(control(scene,"CandidateHome") != null,"Candidate journey offers Home")
		check(not auto_accept_quit and scene.is_in_group("candidate_quit_owners"),"Prediction owns OS-close handling so campaign quit cannot preempt its guard")
		scene.request_hub()
		check(scene.departed == 1 and scene.departed_home and scene.get_node_or_null("LeavePredictionDialog") == null,"Empty exploration returns Home without a discard prompt")
		scene.departed = 0
		# Only edit public controls; this is an arbitrary exploration, not a solution.
		scene.rule.select(1); scene.edit_policy()
		scene.request_quit()
		check(scene.get_node("LeavePredictionDialog").visible and scene.departed == 0,"An unrun edited policy also requires an explicit discard decision")
		cancel(scene)
		scene.step_current()
		var prefix: Dictionary = scene.public_observation()
		var partial_signature: String = scene.active_trace.canonical_signature()
		control(scene,"CandidateHome").pressed.emit()
		check(scene.get_node("LeavePredictionDialog").visible,"Home warns before losing revealed evidence")
		cancel(scene)
		check(scene.public_observation() == prefix and scene.active_trace.canonical_signature() == partial_signature and scene.revealed == 1,"Cancel preserves policy, hidden trace, revealed prefix and source")
		scene.run_current(); scene.step_current()
		var observed_before: Dictionary = scene.public_observation()
		var signatures: Array[String] = []
		for row: Dictionary in scene.history: signatures.append(row.trace.canonical_signature())
		scene._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		var guard := scene.get_node("LeavePredictionDialog") as ConfirmationDialog
		check(guard.visible and guard.ok_button_text.contains("quit" if english else "退出"),"OS close uses the temporary-data guard and quit destination")
		cancel(scene)
		check(scene.public_observation() == observed_before and scene.departed == 0,"Cancel OS close preserves measured history and current prefix")
		for index: int in signatures.size(): check(scene.history[index].trace.canonical_signature() == signatures[index],"Departure dialogs never change recorded Trace")
		control(scene,"Quit").pressed.emit(); guard.hide(); guard.confirmed.emit()
		check(scene.departed == 1 and not scene.departed_home,"Confirmed discard uses quit destination")
		scene.departed = 0; control(scene,"CandidateHome").pressed.emit()
		check(guard.ok_button_text.contains("Home" if english else "首页"),"Reused guard updates its destination after a quit attempt")
		guard.hide(); guard.confirmed.emit()
		check(scene.departed == 1 and scene.departed_home,"Confirmed Home departure follows the chosen destination")
		scene.queue_free(); await process_frame; await process_frame
		check(auto_accept_quit == original_auto_quit,"Leaving the workbench restores prior window-close behavior")
	var standalone := NavigationProbe.new(); root.add_child(standalone); await process_frame
	check(control(standalone,"CandidateHome") == null,"Standalone launch keeps Home opt-in")
	standalone.request_quit()
	check(standalone.departed == 1 and not standalone.departed_home,"Fresh standalone quit has no data-loss prompt")
	standalone.queue_free(); await process_frame; await process_frame
	localization.set_locale(original_locale)
	var campaign_after: Dictionary = save._save_snapshot(); campaign_after.erase("saved_at_utc")
	check(campaign_before == campaign_after,"Prediction navigation grants no campaign progress or save authority")
	print("PASS: test_prediction_navigation " if failures == 0 else "FAIL: test_prediction_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
