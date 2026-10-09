extends SceneTree
const Catalog = preload("res://experiments/creation/catalog.gd")
const Conditions = preload("res://experiments/creation/condition_examples.gd")
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func run() -> void:
	var learned: Dictionary = Model.learn([Catalog.sample(0)],2,Model.default_machine())
	check(learned.ok,"Commission uses actual sample-derived model")
	var model_id: String = Model.identity(learned.model)
	var changed: Array[String] = []
	for key: String in Conditions.machine(0):
		if Conditions.machine(0)[key] != Conditions.machine(1)[key]: changed.append(key)
	check(changed == ["cpu_ops_per_cycle"],"Orders change only CPU throughput")
	for index: int in 2:
		var raw: Dictionary = Codec.run_transport(Catalog.source(0),learned.model,Conditions.machine(index),"raw")
		var predictive: Dictionary = Codec.run_transport(Catalog.source(0),learned.model,Conditions.machine(index),"predictive")
		check(raw.ok and predictive.ok and raw.lossless and predictive.lossless,"Both paths deliver exact authoritative source")
		check(Conditions.delivery(raw,index).ok == (index == 0),"RAW deadline verdict derives from measured model cost")
		check(Conditions.delivery(predictive,index).ok == (index == 1),"Predictive deadline verdict derives from measured model cost")
		check(Model.identity(learned.model) == model_id,"Two orders never replace or retrain model")
		check(not Conditions.delivery({"ok":false},index).ok,"Failed transport cannot pass deadline")
	check(Catalog.sample(5).size() == 48 and Catalog.sample(5)[31] == 3,"Separate public training material exposes rare exception")
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene)
	for i: int in 6: await process_frame
	scene.session.data.draft.examples = [Catalog.sample(0)]
	scene.session.data.draft.order = 2
	scene.train_model()
	scene.change_task(2)
	scene.begin_commission(0)
	scene.transport("raw")
	check(scene.commission_receipts.size() == 1 and scene.commission_receipts[0].result.ok,"Player chosen RAW produces bound successful order receipt")
	scene.begin_commission(1)
	scene.transport("predictive")
	check(scene.commission_receipts.size() == 2 and scene.commission_receipts[1].result.ok,"Same rules continue into second chosen delivery")
	check(scene.commission_receipts[0].model_id == scene.commission_receipts[1].model_id,"Player receipts share exact learned model identity")
	scene.session.data.draft.machine.bytes_per_cycle = 4
	scene.transport("raw")
	check(scene.commission_receipts.size() == 2,"Changed public order conditions cannot counterfeit successful delivery")
	scene.queue_free()
	await process_frame
	print("%s creation commissions: %d checks, %d failures"%["PASS:" if failures.is_empty() else "FAIL:",checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
