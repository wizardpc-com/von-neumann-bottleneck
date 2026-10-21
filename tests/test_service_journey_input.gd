extends "res://tests/test_performance_player_input.gd"
## Isolated task entry; recorded-state inspection through viewport input.

func finish() -> void:
	var file := FileAccess.open(evidence_root + "journey-ui-observations.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t"))
	print("Journey input checks: %d; failures: %d" % [observations.size(),failures.size()])
	if failures.is_empty(): print("PASS: service journey input")
	quit(0 if failures.is_empty() else 1)

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("playtest/offline_tester",true)
	ProjectSettings.set_setting("game/reduced_motion",true)
	var entered: bool = root.get_node("TaskNavigation").enter("service/prompt_response")
	check(entered,"Offline tester opens the isolated service task.")
	if not entered:
		await finish()
		return
	await settle(16)
	ui = current_scene
	await shot("journey-entry")
	await press(ui.run_button)
	var record: String = JSON.stringify(ui.history[0])
	check(ui.response_chart.first_responses == [89,180,271,362],"The chart reads actual first responses from the initial run.")
	var overview: ScrollContainer = ui.find_child("OverviewEvidenceScroll",true,false)
	check(overview.get_global_rect().encloses(ui.response_chart.get_global_rect()),"The complete wrapped chart fits the visible 720p overview.")
	await shot("journey-late-response")
	await press(ui.response_step)
	var witness: Dictionary = ui.response_chart.witness_snapshot()
	check(ui.response_chart.playback_cycle == 89 and witness.event.kind == "output" and witness.event.details.stream == 0,"Next response selects the actual A output event at cycle89.")
	check(witness.residents[0].present and witness.residents[0].dirty,"The displayed A state is resident and awaiting write-back at that event.")
	await shot("journey-first-a")
	for index: int in 3: await press(ui.response_step)
	witness = ui.response_chart.witness_snapshot()
	check(ui.response_chart.playback_cycle == 362 and witness.event.details.stream == 3,"Three further clicks reach D's real first output at362.")
	check(witness.residents[3].present and witness.residents[3].dirty and not witness.residents[0].present,"The D response displays the corresponding recorded residency, not final state.")
	await edit_number(ui.slots,4)
	check(JSON.stringify(ui.history[0]) == record and ui.response_chart.witness_snapshot() == witness,"Editing draft capacity preserves the selected response and state witness.")
	await shot("journey-draft-keeps-record")
	check(ui.support_plans.is_empty() and ui.next_button.disabled,"Reading and replaying the failed record cannot earn completion.")
	await finish()
