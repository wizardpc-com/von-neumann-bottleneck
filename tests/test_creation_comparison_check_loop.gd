extends "res://tests/test_recovery_game_input.gd"
## Isolated candidate/Test profile. Every learning, comparison and prediction
## action below uses viewport dispatch; no supports or measured results are seeded.
const Model = preload("res://experiments/creation/model.gd")
const Ledger = preload("res://experiments/creation/cost_ledger.gd")
var completed_locales: Array[String] = []

func action(id: String) -> void:
	await press(ui.find_child(id,true,false))

func guide(expected: String) -> void:
	check(ui.next_step().action == expected,"Task %d current-model guide expected %s, actual %s" % [ui.task,expected,ui.next_step().action])
	check(ui.next_step_button.text == ui.next_step().button,"Visible guide matches selected action")

func advance(expected: String) -> void:
	guide(expected)
	# Do not follow an unrelated action after a regression.
	if ui.next_step().action == expected: await action("NextStepAction")

func popup_key(popup: PopupMenu, code: Key) -> void:
	var event := InputEventKey.new()
	event.window_id = popup.get_window_id()
	event.keycode = code; event.physical_keycode = code; event.pressed = true
	Input.parse_input_event(event); await process_frame
	if is_instance_valid(popup) and popup.visible:
		event = InputEventKey.new()
		event.window_id = popup.get_window_id(); event.keycode = code; event.physical_keycode = code
		Input.parse_input_event(event); await process_frame

func choose_order(index: int) -> void:
	var control := ui.find_child("Order",true,false) as OptionButton
	var popup: PopupMenu = control.get_popup()
	popup.prefer_native_menu = false
	await press(control)
	check(popup.visible,"History menu opens through viewport")
	if not popup.visible: return
	popup.grab_focus(); await create_timer(0.2).timeout
	for attempt: int in popup.item_count+1:
		if popup.get_focused_item() == index: break
		await popup_key(popup,KEY_DOWN)
	check(popup.get_focused_item() == index,"Keyboard selects requested history")
	await popup_key(popup,KEY_ENTER)
	await settle()

func finish_round(kind: String, guided: bool = true) -> void:
	var identity: String = Model.identity(ui.session.data.model)
	check(ui.session.prediction.get("kind","") == kind,"Active passage is "+kind)
	check(ui.session.prediction.get("rows",[]).is_empty(),"New passage starts without revealed truth")
	if guided: guide("commit")
	await action("Commit")
	check(ui.session.prediction.rows.is_empty() and not ui.session.prediction.pending.is_empty(),"Commit seals a guess without revealing truth")
	if guided: guide("reveal")
	await action("Reveal")
	check(ui.session.prediction.rows.size() == 1 and ui.session.prediction.pending.is_empty(),"Reveal adds exactly one authoritative row")
	if guided: guide("remainder")
	await action("ContinuePrediction")
	check(ui.session.prediction.finished and ui.session.prediction.rows.size() == ui.session.prediction.total,"Remainder completes the entire actual passage")
	check(ui.session.prediction.model_id == identity and Model.identity(ui.session.data.model) == identity,"Round retains its frozen learned identity")
	check(ui.latest.kind == "prediction" and ui.latest.recipe.model_id == identity and ui.latest.events == ui.session.prediction_evidence().events,"Displayed latest result is the current round")
	check(str(ui.session.get("_prediction_model")) == identity,"Completed prediction authorizes only the current model")

func stable_window() -> void:
	if "--recovery-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var frame: Image = root.get_texture().get_image()
		stable = stable+1 if frame != null and frame.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Five actual rendered frames reach 1280x720 before player actions")

func measurement_shot(label: String) -> void:
	if "--recovery-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	# The optional review is the existing visible route to Measurements, even
	# when the long English evidence tab strip has scrolled its first tab away.
	await action("ShowCPGConnection")
	if ui.connection_fragment.body.visible: await action("ShowCPGConnection")
	await press(ui.costs)
	check(ui.costs.is_visible_in_tree(),"Current measurement is visible for "+label)
	await shot(label)

func shot(label: String) -> void:
	if "--recovery-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	# Capturing must preserve the player's viewport, focus and scroll state.
	await point(Vector2(5,5)); await settle(12)
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().get_size() == Vector2i(1280,720),"Capture retains actual 1280x720 pixels: "+label)
	await capture(label)

func exercise(locale: String) -> void:
	root.get_node("TaskNavigation").pending = ""
	ui = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(ui); current_scene = ui
	await settle(12)
	await stable_window()
	ui.session.close()
	var path: String = "user://creation-comparison-check/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	var opened: Dictionary = ui.session.open(path)
	ui.writable = bool(opened.get("writable",false))
	check(ui.writable,"Fresh isolated candidate profile is writable: "+locale)
	ui._clear_replaced_exploration(); ui.change_task(0)
	await settle()
	await advance("train")
	await advance("transport")
	await advance("next")
	check(ui.task == 1,"C1 naturally advances to C2")
	await advance("compare")
	check(ui.session.data.supports.has("C2_cost"),"C2 records an actual same-condition codec comparison")
	check(ui.transport_comparisons.size() == 1,"C2 records exactly one paired observation")
	if ui.transport_comparisons.is_empty(): return
	var comparison: Dictionary = ui.transport_comparisons[-1]
	check(comparison.results.raw.lossless and comparison.results.predictive.lossless and comparison.results.raw.output_id == comparison.results.predictive.output_id,"RAW and predictive reconstruct the same original")
	await advance("next")
	check(ui.task == 2,"C2 naturally advances to C3")
	var learned: Dictionary = ui.session.data.model.duplicate(true)
	var pairs: Array[Dictionary] = []
	for condition: int in 2:
		var prior: int = ui.transport_comparisons.size()
		await action("MachineCondition"+str(condition))
		check(ui.transport_comparisons.size() == prior and ui.session.data.model == learned,"Changing machine neither runs nor relearns")
		await action("RunCostComparison")
		check(ui.transport_comparisons.size() == prior+1,"Explicit Run records new machine comparison")
		if ui.transport_comparisons.size() <= prior: return
		pairs.append(ui.transport_comparisons[-1].duplicate(true))
		check(Ledger.matches(pairs[-1],ui.latest.source,learned,ui.session.data.draft.machine),"New result binds current source, machine and rules")
		await shot("c3-machine-"+str(condition))
	check(Ledger.total(pairs[0],"raw","total_cycles") < Ledger.total(pairs[0],"predictive","total_cycles") and Ledger.total(pairs[1],"raw","total_cycles") > Ledger.total(pairs[1],"predictive","total_cycles"),"Actual machine intervention reverses measured cycle winner")
	check(ui.session.data.supports.has("C3_conditions"),"C3 accepts actual two-machine evidence")
	await advance("next")
	await advance("predict")
	await advance("practice")
	await finish_round("practice")
	await advance("next")
	check(ui.task == 4,"Completed P1 leads to P2")
	await advance("examples")
	var before: Dictionary = ui.session.data.model.duplicate(true)
	var machine: Dictionary = ui.session.data.draft.machine.duplicate(true)
	await choose_order(2)
	check(ui.session.data.draft.order == 2 and ui.session.data.model == before,"History edit changes draft only, before explicit Learn")
	await advance("train")
	check(ui.session.data.model.order == 2 and ui.session.data.model.examples == before.examples and ui.session.data.draft.machine == machine,"P2 Learn changes history while retaining material and machine")
	await advance("transport")
	check(ui.task == 4 and str(ui.session.get("_transport_model")) == Model.identity(ui.session.data.model),"New-model restoration retains P2 and verifies current identity")
	await advance("practice")
	await finish_round("practice")
	check(ui.session.data.supports.has("P2_memory"),"P2 records comparable real rounds with different learned history")
	await measurement_shot("p2-history-comparison")
	await advance("next")
	check(ui.task == 5,"P2 leads to P3")
	await advance("examples")
	await action("Example5")
	await advance("train")
	await advance("transport")
	await advance("family_practice")
	await finish_round("practice-v2")
	await advance("family_check")
	check(not ui.session.prediction.seen,"First family check is not labelled previously seen")
	await finish_round("check-v2")
	check(ui.session.data.supports.has("P3_check"),"P3 support comes from a completed frozen check")
	guide("next")
	await action("Check")
	check(ui.session.prediction.seen and ui.session.prediction.kind == "check-v2","Repeated explicit Check marks this round seen")
	var expected_seen: String = "Check answers seen before this run: true" if locale == "en" else "本轮开始前，检查答案已见：true"
	check(expected_seen in ui.costs.text,"Displayed measurement labels repeated check as seen")
	await measurement_shot("p3-repeated-seen-check")
	await finish_round("check-v2",false)
	guide("next")
	completed_locales.append(locale)
	ui.queue_free(); await settle()

func _run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var game_before: Dictionary = root.get_node("GlobalSave")._save_snapshot().game.duplicate(true)
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await exercise(locale)
	check(completed_locales == ["zh_CN","en"],"Both locales completed the entire comparison/check loop")
	check(root.get_node("GlobalSave")._save_snapshot().game == game_before,"Test-mode comparison/check loops preserve ordinary Game state")
	finish()

func finish() -> void:
	var file := FileAccess.open(evidence_root+"creation-comparison-check-loop.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope":"Isolated candidate/Test profile; viewport comparison and prediction loop, not ordinary Game unlock acceptance","observations":observations,"failures":failures},"\t")); file.close()
	else: failures.append("Could not write comparison/check evidence")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"creation comparison check loop %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
