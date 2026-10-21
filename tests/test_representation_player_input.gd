extends "res://tests/test_performance_player_input.gd"
## Test-mode entry only; the plan edits, measured orders and saving use UI input.
const LabState = preload("res://src/lab/lab_state.gd")
const Store = preload("res://experiments/representation_region/session_store.gd")
const TASK := "representation/prepare_once"

func finish() -> void:
	var file := FileAccess.open(evidence_root + "representation-ui-observations.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(observations, "\t"))
	print("Representation input checks: %d; failures: %d" % [observations.size(), failures.size()])
	if failures.is_empty(): print("PASS: representation preparation player input")
	quit(0 if failures.is_empty() else 1)

func order_labels() -> void:
	var names: Array = ["Prepare + short read", "Prepare + eight cold scans"] if ui.english else ["准备 + 短读", "准备 + 八次冷扫描"]
	var row: TreeItem = ui.order_comparison.get_root().get_first_child()
	for index: int in 2:
		check(ui.mission.text.contains(names[index]), "The mission names the current-language order " + str(index + 1))
		check(ui.public_order_choice.get_item_text(index + 1) == names[index], "The request preview uses the same order name as the mission.")
		check(ui.order_choice.get_item_text(index).contains(names[index]) and row.get_text(0).contains(names[index]), "The recorded selector and result table retain the mission's order names.")
		row = row.get_next()
	check(ui.result.text.contains(names[ui.order_choice.selected]), "The primary measured result names the selected order in the current language.")

func measured(totals: Array, preparation: int, stored: int, accepted: bool) -> void:
	var record: Dictionary = ui.history.back()
	check(record.accepted == accepted and record.traces.size() == 2, "Both independent orders are measured by the unchanged completion check.")
	for index: int in 2:
		var trace: RefCounted = record.traces[index]
		check(trace.passed and trace.metrics.total_cycles == totals[index], "Actual order " + str(index + 1) + " returns exact bytes with total " + str(totals[index]))
		check(trace.metrics.preparation_cycles == preparation and trace.metrics.stored_bytes == stored, "Each order includes its own preparation and retained-source storage.")
		check(trace.metrics.preparation_cycles + trace.metrics.service_cycles == trace.metrics.total_cycles, "Displayed preparation and service account for the actual total.")
	check(ui.cost_view.measurements.size() == 2, "The fixed cost overview shows both measured orders.")
	order_labels()

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("game/reduced_motion", true)
	check(root.get_node("TaskNavigation").enter(TASK), "Test access opens preparation without granting its completion.")
	await settle(16)
	ui = current_scene
	check(ui.task == 3 and ui.persistent_session and ui.history.is_empty() and not ui.completed.has(true), "The isolated task starts with an unmeasured RAW draft and no earned tasks.")
	await shot("prepare-entry")
	await press(ui.run_button)
	measured([81,1096],8,68,false)
	check(ui.order_choice.selected == 1 and ui.status.text.contains("1096") and ui.status.text.contains("930"), "The RAW run points to the over-budget eight-scan order and its measured limit.")
	var original: String = ui.history[0].traces[0].canonical_signature()
	await press(ui.result)
	await shot("raw-short-met-scans-unmet")
	await press(ui.rle_button)
	check(ui.history.size() == 1 and ui.cost_source.text.contains("differs" if ui.english else "不同"), "Changing codec marks the displayed measurement as belonging to an older draft.")
	check(ui.history[0].traces[0].canonical_signature() == original, "Editing never rewrites the RAW measurement.")
	await shot("rle-draft-before-run")
	await press(ui.run_button)
	measured([111,769],89,72,false)
	check(ui.order_choice.selected == 0 and ui.status.text.contains("111") and ui.status.text.contains("105"), "The RLE run instead identifies the short-read order as over budget.")
	check(not ui.completed[3], "Neither single-codec plan meets both orders.")
	await press(ui.result)
	await shot("rle-scans-met-short-unmet")
	await press(ui.history_list)
	await click(ui.history_list.global_position + ui.history_list.get_item_rect(0).get_center())
	check(ui.selected_run == 0 and ui.plan[0].codec == "rle" and ui.cost_source.text.contains("differs" if ui.english else "不同"), "Inspecting the old RAW result does not replace the current RLE draft.")
	await shot("raw-record-rle-draft")
	await edit_number(ui.split_at,8)
	await press(ui.split_button)
	check(ui.plan.size() == 2 and ui.plan[0].end == 8 and ui.plan[1].start == 8, "Typing a split address and pressing Split creates the two requested ranges.")
	await press(ui.blocks)
	await key(KEY_HOME)
	await press(ui.raw_button)
	check(ui.plan[0].codec == "raw" and ui.plan[1].codec == "rle", "The player changes only the selected first block to RAW.")
	await press(ui.run_button)
	measured([105,888],88,76,true)
	check(ui.completed == [false,false,false,true,false] and ui.support_plans.has(3), "Only the actually measured preparation task earns a protected successful plan.")
	check(ui.history[0].traces[0].canonical_signature() == original, "All three measurements retain the original evidence.")
	await press(ui.result)
	await shot("mixed-both-orders-met")
	await press(ui.find_child("SaveSession",true,false))
	check(not ui.session_dirty and FileAccess.file_exists(Store.PATH), "Save exploration writes the real draft, comparisons and earned support.")
	check(LabState.completed_keys(LabState.tasks()) == [TASK], "Saving exposes only the task actually earned in this isolated profile.")
	await shot("saved-preparation-result")
	await finish()
