extends "res://experiments/play_journeys.gd"
## Authored-answer viewport QA; it does not establish novice or native pointer play.
const C = preload("res://experiments/service_plan/commissions.gd")

# Embedded dialog Controls use their Window's local coordinates. Root dispatch
# must add the embedded Window position before its real GUI hit test.
func press(control: Control) -> void:
	if control != null and control.get_viewport() != root and control.get_viewport() is Window:
		var window := control.get_viewport() as Window
		if window.is_embedded():
			check(control.is_visible_in_tree(),"Dialog control exists and is visible")
			await click(Vector2(window.position)+control.get_global_rect().get_center()); return
	await super.press(control)

func prepare_window() -> void:
	await super.prepare_window()
	root.content_scale_size = Vector2i(1280,720)
	root.size = Vector2i(1280,720); await settle(10)

func reveal_commission(control: Control) -> void:
	var scroll := ui.evidence_tabs.get_node("Commissions") as ScrollContainer
	for attempt: int in 30:
		var visible_area: Rect2 = scroll.get_global_rect()
		var target: Rect2 = control.get_global_rect()
		if target.position.y >= visible_area.position.y and target.end.y <= visible_area.end.y: return
		await click(visible_area.get_center(),MOUSE_BUTTON_WHEEL_UP if target.position.y < visible_area.position.y else MOUSE_BUTTON_WHEEL_DOWN)
	check(false,"Commission control reachable through visible scrolling")

func deliver() -> void:
	await reveal_commission(ui.commission_ack); await press(ui.commission_ack)
	check(ui.has_node("CommissionDelivery") and ui.get_node("CommissionDelivery").visible,"Earned optional handoff acknowledgement opens")
	await capture("commission-delivery")
	await press(ui.get_node("CommissionDelivery").get_ok_button())
	check(not ui.get_node("CommissionDelivery").visible,"Continue button closes handoff before subsequent edits")
	if ui.get_node("CommissionDelivery").visible: quit(1)

func service() -> void:
	await super.service()
	var supports: Dictionary = ui.support_plans.duplicate(true)
	await press(handle("ServiceCommissions"))
	check(ui.commission_mode == 0 and ui.commission_ack.disabled,"Existing four-slot approximate winner does not satisfy single-slot exact duty")
	var low: Dictionary = service_draft(false,1,["rle64","rle64","raw64","raw64"])
	low.groups = [[0],[6],[12],[18]]
	for stream: int in 4:
		for step: int in range(1,6): low.groups.append([stream*6+step])
	await build_service(low); await press(handle("Run"))
	check(not ui.commission_ack.disabled and ui.active_trace.metrics.total_cycles == 1412,"Visible edits solve single-slot follow-up")
	check(ui.support_plans == supports,"Optional632B traffic plan preserves original protected final service")
	await capture("commission-one-slot"); await deliver()
	await reveal_commission(ui.commission_choice); await choose(ui.commission_choice,1)
	check(not ui.commission_ack.disabled and ui.commission_result.text.contains("158"),"Same measured lossless record has a158B final archive despite632B traffic")
	await capture("commission-lossless-archive")
	await reveal_commission(ui.commission_choice); await choose(ui.commission_choice,2)
	check(ui.commission_ack.disabled,"Lossless158B archive fails compact64B handoff")
	await build_service(service_draft(false,4,["rle8","rle8","rle8","rle8"])); await press(handle("Run"))
	check(not ui.commission_ack.disabled and ui.active_trace.metrics.max_error > 0.0,"Different compact representation meets explicit measured tolerance")
	await capture("commission-compact-archive"); await deliver()
	await reveal_commission(ui.commission_choice); await choose(ui.commission_choice,1)
	check(ui.commission_ack.disabled,"Real approximate error fails the lossless specification")
	await press(handle("Task3")); check(ui.commission_mode == -1,"Task3 restores original final contract")

func verify_saved() -> void:
	await super.verify_saved()
	check(not ui.get_node("ServiceReview").visible,"Original review closes before optional replay")
	await press(handle("ServiceCommissions"))
	var winners: Array[int] = [-1,-1,-1]
	for index: int in ui.history.size():
		for id: int in 3:
			if C.accepted(ui.history[index].metrics,id): winners[id] = index
	for id: int in 3:
		check(winners[id] >= 0,"Retained saved recipe can still answer specification%d" % id)
		await reveal_commission(ui.commission_choice); await choose(ui.commission_choice,id)
		await item_row(ui.history_list,winners[id]); check(not ui.commission_ack.disabled,"Restarted measured recipe revalidates commission%d" % id)
	await capture("commission-restored")
	await press(handle("Task3"))
