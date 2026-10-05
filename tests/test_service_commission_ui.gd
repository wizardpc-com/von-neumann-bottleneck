extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const M = preload("res://experiments/service_plan/model.gd")
const Store = preload("res://experiments/service_plan/session_store.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.content_scale_size = Vector2i(1280,720); root.size = Vector2i(1280,720)
	var scene := Lab.new(); root.add_child(scene); await process_frame
	check(scene.find_child("ServiceCommissions",true,false).disabled,"Fresh player cannot bypass three-contract closure")
	scene.start_commission(0); check(scene.commission_mode == -1,"Direct entry without earned supports refused")
	var grouped: Dictionary = M.initial_plan(); grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	scene.edit(grouped,0); scene.run_current(); scene.change_task(1)
	var exact: Dictionary = M.initial_plan(); exact.slots = 4
	scene.edit(exact,0); scene.run_current(); scene.change_task(2)
	exact.representations = ["rle64","rle64","raw64","raw64"]
	scene.edit(exact,0); scene.run_current()
	check(scene.has_service_closure(),"Actual runs earn original ending")
	var supports: Dictionary = scene.support_plans.duplicate(true)
	var signature: String = scene.history.back().signature
	scene.start_commission(0)
	check(scene.task == 2 and scene.commission_mode == 0 and scene.evidence_tabs.current_tab == 4,"Optional mode stays within existing task2 workbench")
	check(scene.commission_ack.disabled and scene.commission_result.text.contains("4 / 1"),"Measured four-slot plan fails duty visibly")
	scene.start_commission(1)
	check(not scene.commission_ack.disabled,"Protected exact recipe can answer archive commission")
	var changed: Dictionary = exact.duplicate(true); changed.slots = 3
	scene.edit(changed,0)
	check(not scene.commission_ack.disabled and scene.commission_result.text.contains("草稿"),"Editing draft preserves acceptance of explicit selected record")
	scene.acknowledge_commission(); await process_frame
	check(scene.has_node("CommissionDelivery") and scene.get_node("CommissionDelivery").visible,"Successful measured handoff has an acknowledgement")
	scene.get_node("CommissionDelivery").hide()
	check(scene.history.back().signature == signature and scene.support_plans == supports,"Spec selection and handoff never mutate measured history/supports")
	var low: Dictionary = exact.duplicate(true); low.slots = 1; low.groups = [[0],[6],[12],[18]]
	for stream: int in 4:
		for step: int in range(1,6): low.groups.append([stream*6+step])
	scene.start_commission(0); scene.edit(low,0); scene.run_current()
	check(not scene.commission_ack.disabled and scene.active_trace.metrics.total_cycles == 1412,"New one-slot commission can be earned by own actual run")
	check(scene.support_plans == supports and scene.has_service_closure(),"Optional winner outside original final traffic budget cannot replace protected ending")
	var raw: String = Store.encode(scene.task,scene.plan,[{"task":2,"plan":low}],scene.support_records())
	var saved: Dictionary = Store.decode(raw)
	check(saved.ok and JSON.parse_string(raw).size() == 7 and saved.task == 2,"Existing schema2 saves optional plan without new task or result fields")
	check(scene.Commissions.accepted(M.run(saved.runs[0].plan).metrics,0),"Saved recipe independently recomputes commission acceptance")
	scene.start_commission(2); check(scene.commission_ack.disabled,"Measured158B archive fails compact64B specification")
	var compact: Dictionary = M.initial_plan(); compact.slots = 4; compact.representations = ["raw8","raw8","raw8","raw8"]
	scene.edit(compact,0); scene.run_current(); check(not scene.commission_ack.disabled,"Real compact plan can answer handoff")
	scene.start_commission(1); check(scene.commission_ack.disabled,"Actual approximation error cannot pass lossless specification")
	scene.change_task(2); await process_frame
	check(scene.commission_mode == -1 and scene.evidence_tabs.current_tab == 0,"Task3 returns to original contract without re-entering commission tab")
	for en: bool in [false,true]:
		scene.english = en; scene.build(); scene.start_commission(1); await process_frame; await process_frame
		check(scene.evidence_tabs.get_global_rect().end.y <= 721,"Optional scroll tab fits minimum logical height")
		check(scene.commission_choice.get_global_rect().end.x <= 1281,"Bilingual spec selector fits minimum logical width")
		check(scene.commission_brief.text.contains("160") and scene.commission_brief.text.contains("1e-9"),"Visible brief exposes the selected archive limits")
	scene.change_task(0)
	check(scene.response_chart.deadline == 0,"Original task1 has no first-response limit")
	scene.start_commission(0)
	check(scene.response_chart.deadline == 320,"Entering commission from task1 refreshes response chart deadline")
	var file := FileAccess.open(Store.PATH,FileAccess.WRITE)
	file.store_string(Store.encode(0,M.initial_plan(),[])); file.close()
	scene.reload_recovered_session(); await process_frame
	check(scene.commission_mode == -1 and scene.task == 0 and not scene.has_service_closure(),"Explicit old-snapshot reload clears unearned optional mode")
	check(scene.evidence_tabs.current_tab == 0 and scene.mission_text().contains("600B"),"Recovery shows restored original contract rather than stale commission")
	scene.queue_free(); await process_frame
	print("PASS: test_service_commission_ui " if failures == 0 else "FAIL: test_service_commission_ui ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
