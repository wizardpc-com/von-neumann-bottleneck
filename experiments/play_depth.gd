extends "res://experiments/viewport_input.gd"
## Known-objective viewport acceptance. Not an unknown-answer or novice player.
var steps: Array[Dictionary] = []
func log_step(label: String, metrics: Dictionary) -> void:
	steps.append({"step":label,"metrics":metrics.duplicate(true)})
	var file := FileAccess.open(evidence_root+"depth-steps.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(steps,"\t"))
	await capture(label)

func select_block(index: int) -> void:
	var item: TreeItem=ui.blocks.get_root().get_first_child()
	for i: int in index: item=item.get_next()
	await click(ui.blocks.global_position+ui.blocks.get_item_area_rect(item).get_center())
	check(ui.selected_block==index,"Block row selected through viewport")

func split_at(address: int) -> void:
	await press(ui.split_at.get_line_edit()); await key(KEY_A,true); await type_text(str(address)); await key(KEY_ENTER)
	await press(ui.split_button)

# Native popup focus may lag injected mouse input on macOS. Retry only UI keys;
# never select an item or emit its signal directly. Keep attempts in the log.
func choose(control: OptionButton, index: int) -> void:
	var popup: PopupMenu = control.get_popup()
	popup.prefer_native_menu = false
	for attempt: int in 3:
		root.grab_focus()
		await create_timer(0.2).timeout
		if not popup.visible: await press(control)
		await create_timer(0.2).timeout
		if not popup.visible: continue
		popup.grab_focus()
		await create_timer(0.2).timeout
		await popup_key(popup, KEY_HOME)
		for i: int in range(control.item_count + 1):
			if popup.get_focused_item() == index: break
			await popup_key(popup, KEY_DOWN)
		print("MENU attempt=", attempt + 1, " focus=", popup.get_focused_item(), " want=", index)
		if popup.get_focused_item() == index:
			await popup_key(popup, KEY_ENTER)
		else:
			await popup_key(popup, KEY_ESCAPE)
		if control.selected == index and not popup.visible:
			check(true, "Visible selector accepts choice %d" % index)
			return
	check(false, "Visible selector accepts choice %d" % index)

func _run() -> void:
	await settle()
	root.mode=Window.MODE_WINDOWED
	await create_timer(1.0).timeout
	root.size=Vector2i(1600,900)
	await settle(10)
	change_scene_to_file("res://experiments/representation/puzzle.tscn")
	await settle(20); ui=current_scene
	await press(ui.run_button)
	check(not ui.completed[0],"Unpartitioned raw asset misses storage goal")
	await log_step("plan-raw-baseline",ui.visible_trace.metrics)
	await select_block(0); await split_at(16)
	await select_block(0); await press(ui.rle_button); await press(ui.run_button)
	check(ui.completed[0],"Player-built two-block mixed plan meets scan constraints")
	await log_step("plan-mixed-scan",ui.visible_trace.metrics)
	await press(ui.task_buttons[1]); await press(ui.run_button)
	check(not ui.history[-1].accepted,"Scan solution is not automatically good for hotspots")
	await log_step("plan-hotspot-counterexample",ui.visible_trace.metrics)
	var old_signature: String=ui.visible_trace.canonical_signature()
	await select_block(1); await split_at(48)
	await select_block(2); await press(ui.rle_button)
	check(ui.visible_trace.canonical_signature()==old_signature,"Editing does not rewrite prior Trace")
	await press(ui.run_button)
	check(ui.completed[1],"Small cached endpoint blocks meet hotspot constraints")
	await log_step("plan-hotspot-improved",ui.visible_trace.metrics)
	await select_block(1); await press(ui.merge_button)
	check(ui.plan.size()==2,"Merge edits the actual partition")
	await press(ui.undo_button); check(ui.plan.size()==3,"Undo restores partition")
	await press(ui.redo_button); check(ui.plan.size()==2,"Redo reapplies partition edit")
	await press(ui.undo_button)
	await press(ui.task_buttons[2]); await press(ui.run_button)
	check(ui.completed[2] and ui.history[-1].traces.size()==2,"One actual plan serves both orders")
	await choose(ui.order_choice,1)
	await log_step("plan-paired-final",ui.visible_trace.metrics)
	change_scene_to_file("res://experiments/intelligent_workload/state_lab.tscn")
	await settle(20); ui=current_scene
	await press(ui.run_button)
	check(ui.active_trace.metrics.state_reads==24 and ui.active_trace.metrics.state_writes==24,"Round-robin single-slot actual state thrashes")
	await log_step("state-thrashing",ui.active_trace.metrics)
	await choose(ui.order,2); await press(ui.run_button)
	check(ui.active_trace.metrics.state_reads==4 and ui.active_trace.metrics.state_writes==4,"Grouping avoids repeated spills but flushes all dirty states")
	await log_step("state-grouped",ui.active_trace.metrics)
	await choose(ui.contract,1)
	check(ui.active_trace.metrics.all_streams_first_cycle>240,"Grouped throughput plan delays other contexts")
	await log_step("state-grouped-latency",ui.active_trace.metrics)
	await choose(ui.order,0); await choose(ui.slots,2); await press(ui.run_button)
	check(ui.active_trace.metrics.total_cycles<=1040 and ui.active_trace.metrics.all_streams_first_cycle<=240 and ui.active_trace.metrics.max_error==0.0,"Exact resident plan also meets prompt service")
	await log_step("state-resident-exact",ui.active_trace.metrics)
	await choose(ui.batch,2); await press(ui.run_button)
	check(not ui.active_trace.passed,"Oversized batch plus four contexts is rejected")
	await log_step("state-memory-rejection",ui.active_trace.metrics)
	await choose(ui.batch,0); await choose(ui.state_precision,3); await press(ui.run_button)
	check(ui.active_trace.metrics.max_state_error>0.02,"Two-bit persistent state loses numerical information")
	await log_step("state-low-precision-loss",ui.active_trace.metrics)
	await choose(ui.state_precision,1); await press(ui.run_button)
	check(ui.active_trace.metrics.max_state_error<=0.02 and ui.active_trace.metrics.max_error<=0.02,"Eight-bit state is measured, not assigned a quality score")
	await log_step("state-eight-bit",ui.active_trace.metrics)
	var row: TreeItem=ui.tree.get_root().get_first_child()
	for i: int in 5: row=row.get_next()
	await click(ui.tree.global_position+ui.tree.get_item_area_rect(row).get_center())
	await capture("state-event-inspection")
	var file := FileAccess.open(evidence_root+"checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t"))
	print("PASS: depth viewport acceptance " if failures.is_empty() else "FAIL: depth viewport acceptance ",observations.size())
	quit(0 if failures.is_empty() else 1)
