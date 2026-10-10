extends SceneTree
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
const Ledger = preload("res://experiments/creation/cost_ledger.gd")
const View = preload("res://experiments/creation/cost_ledger_view.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func check_conservation(snapshot: Dictionary) -> void:
	for codec: String in Ledger.CODECS:
		var result: Dictionary = snapshot.results[codec]
		if not result.ok: continue
		var cycles: int = 0; var ops: int = 0; var traffic: int = 0
		for row: Dictionary in result.phases.values():
			cycles += int(row.cycles); ops += int(row.ops); traffic += int(row.bytes)
		check(cycles == result.cost.total_cycles, codec+" ledger cycles conserve resolved events")
		check(ops == result.cost.cpu_ops and traffic == result.cost.transfer_bytes, codec+" ledger ops/traffic conserve resolved events")
		var m: Dictionary = result.metrics
		check(m.packet_bytes == m.header_bytes+m.model_bytes+m.payload_bytes+m.checksum_bytes, codec+" actual packet components sum exactly")
		check(result.phases.transfer.bytes == m.packet_bytes, codec+" transfer phase carries real packet size")
	var view = View.new(); root.add_child(view)
	view.show_snapshot(snapshot,false)
	for metric: String in ["total_cycles","packet_bytes"]:
		var maximum: int = maxi(Ledger.total(snapshot,"raw",metric),Ledger.total(snapshot,"predictive",metric))
		for codec: String in Ledger.CODECS:
			var width: float = 0
			for part: Dictionary in view.bar_geometry(codec,metric,300): width += float(part.width)
			check(is_equal_approx(width,300.0*Ledger.total(snapshot,codec,metric)/maxi(1,maximum)), "Bar width uses common linear scale: "+codec+" "+metric)
	view.free()
func run() -> void:
	var machine: Dictionary = Model.default_machine()
	var source: Array = []
	for i: int in 4096: source.append(0)
	var trained: Dictionary = Model.learn([[0,0,0,0,0,0,0,0]],0,machine)
	var raw: Dictionary = Codec.run_transport(source,trained.model,machine,"raw")
	var predictive: Dictionary = Codec.run_transport(source,trained.model,machine,"predictive")
	var pair: Dictionary = Ledger.capture(source,trained.model,machine,trained.cost,raw,predictive)
	check_conservation(pair)
	check(pair.results.predictive.metrics.packet_bytes<pair.results.raw.metrics.packet_bytes and pair.results.predictive.cost.total_cycles>pair.results.raw.cost.total_cycles, "Smaller/slower counterexample stays visible on separate scales")
	check("smaller" in Ledger.verdict(pair,true) and "more cycles" in Ledger.verdict(pair,true), "Comparison caption names smaller-but-slower tradeoff")
	check(str(int(trained.cost.total_cycles)+int(predictive.cost.total_cycles)) in Ledger.describe(pair,false), "First-use learning cost is disclosed separately from per-send bars")
	var frozen: String = JSON.stringify(pair)
	source[0] = 3; machine.bytes_per_cycle = 1; raw.cost.total_cycles = 0
	check(JSON.stringify(pair) == frozen and not Ledger.matches(pair,source,trained.model,machine), "Input/result edits cannot mutate frozen ledger")
	var failed: Dictionary = Ledger.capture(source,trained.model,machine,trained.cost,{"ok":false,"error":"memory_limit","required_bytes":10000},predictive)
	var view = View.new(); root.add_child(view); view.show_snapshot(failed,true)
	check(view.bar_geometry("raw","total_cycles",300).is_empty(), "Failed run has no zero-cost bar")
	check("not completed" in Ledger.describe(failed,true) and "10000" in Ledger.describe(failed,false), "Failed run retains its diagnostic and required bytes")
	view.free()
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	scene.source_kind = 2
	scene.compare_transport(); await settle()
	check(scene.transport_comparisons.size() == 1 and scene.transport_comparisons[0].results.raw.ok and not scene.transport_comparisons[0].results.predictive.ok, "Untrained comparison retains successful RAW and explicit predictive failure")
	check(not scene.session.set_mode("predict").ok, "Paired RAW cannot bypass model restoration")
	check(scene.session.train().ok, "Learn for paired comparison")
	scene.change_task(1); await settle()
	scene.compare_transport(); await settle()
	check(scene.transport_comparisons.size() == 2 and scene.session.data.supports.has("C2_cost"), "Real paired runs provide existing C2 comparison evidence")
	var old: String = JSON.stringify(scene.transport_comparisons[1])
	check_conservation(scene.transport_comparisons[1])
	scene.session.data.draft.machine.request_cycles = 64
	scene.edit_draft(); await settle()
	check(JSON.stringify(scene.transport_comparisons[1]) == old and "条件已改变" in scene.cost_comparison_status.text, "Parameter edits keep historical results and show stale-condition notice")
	scene.compare_transport(); await settle()
	check(scene.transport_comparisons.size() == 3 and scene.transport_comparisons[1].machine.request_cycles == 2 and scene.transport_comparisons[2].machine.request_cycles == 64, "Rerun adds separate measured machine conditions")
	check(scene.transport_comparisons[2].preparation_machine.request_cycles == 2, "Historical learning machine stays distinct from current transport machine")
	scene.selected_cost_comparison = 1; scene.refresh_cost_comparison()
	check(scene.cost_comparison_view.snapshot == scene.transport_comparisons[1], "History selection shows exact old snapshot")
	scene.toggle_language(); await settle()
	check(scene.transport_comparisons.size() == 3 and JSON.stringify(scene.transport_comparisons[1]) == old and "Conditions changed" in scene.cost_comparison_status.text, "Language rebuild preserves selected frozen comparison")
	for i: int in 5: scene.compare_transport()
	check(scene.transport_comparisons.size() == 6 and scene.selected_cost_comparison == 5, "History remains bounded and latest selected")
	scene.queue_free(); await settle()
	print("PASS: creation cost ledger %d checks" % checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
