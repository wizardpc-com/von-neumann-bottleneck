extends "res://experiments/play_commissions.gd"
## Visible-input QA of the new learning instrument, not novice/native acceptance.
func tab_at(tabs: TabContainer, index: int) -> void:
	var bar: TabBar = tabs.get_tab_bar()
	var point: Vector2 = bar.global_position + bar.get_tab_rect(index).get_center()
	if bar.get_viewport() is Window and bar.get_viewport() != root:
		point += Vector2(bar.get_viewport().position)
	await click(point)
	check(tabs.current_tab == index,"Visible tab selects page%d" % index)

func inspect_state() -> void:
	await tab_at(ui.evidence_tabs,5)
	await press(handle("StateEnd"))
	check(ui.state_replay.current_source_index == ui.history[ui.selected_history].events.size()-1,"End shows actual final flushed event")
	check(ui.state_replay.frames.back().responses.size() == 24,"Final replay contains24 actual returned requests")
	await capture("state-final")
	await press(handle("StateStart"))
	check(ui.state_replay.current_source_index == 0,"Start returns to recorded initialization")
	for i: int in 14: await press(handle("StateNext"))
	check(ui.selected_event_index == ui.state_replay.current_source_index,"Visible stepping synchronizes recorded event inspector")
	await capture("state-prefix")

func service() -> void:
	await open_scene("res://experiments/service_plan/lab.tscn")
	await press(handle("ServiceIntroduction")); await settle()
	var intro: AcceptDialog = ui.get_node("ServiceBriefing")
	check(intro.visible and ui.history.is_empty(),"Rules open before measured work without creating a run")
	for index: int in 3:
		await tab_at(intro.get_node("BriefingPages"),index)
		await capture("state-introduction%d" % index)
	await press(intro.get_ok_button()); check(not intro.visible,"Return closes optional briefing")
	await number(ui.slots,2); await press(handle("Run"))
	check(ui.history.size() == 1 and str(ui.active_trace.metrics.error).is_empty(),"Own visible slot edit produces a measured run")
	var record: Dictionary = ui.history[0].duplicate(true)
	await inspect_state()
	await press(handle("FormatA"))
	check(ui.state_source.text.contains("草稿") or ui.state_source.text.contains("Draft"),"Unrun draft is distinguished from replay measurement")
	check(ui.history[0] == record,"Replay and draft editing leave actual historical result untouched")
	await capture("state-source-draft")

func verify_saved() -> void:
	var saved: Dictionary = ServiceStore.read_session()
	check(saved.ok and saved.runs.size() == 1 and saved.supports.is_empty(),"Existing candidate schema retains own run without fabricated completion")
	check(ui.history.size() == 1 and not ui.session_dirty,"Independent resume restores measured plan and clean workbench")
	await inspect_state()
	check(ui.state_source.text.contains("草稿") or ui.state_source.text.contains("Draft"),"Restored unrun draft still differs from measured source")
	await press(handle("ServiceIntroduction")); await settle()
	check(ui.get_node("ServiceBriefing").visible,"Introduction remains reopenable after resume")
	await press(ui.get_node("ServiceBriefing").get_ok_button())
	check(not ui.get_node("ServiceBriefing").visible,"Reopened introduction closes through visible input")
