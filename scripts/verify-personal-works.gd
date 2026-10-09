extends SceneTree
## Bounded renderer evidence, executed only in an isolated QA project/profile.
## Author setup selects documented examples; results are actual workbench runs.
const Catalog = preload("res://experiments/creation/catalog.gd")
const Model = preload("res://experiments/creation/model.gd")
var folder: String = ""
var locale: String = "zh_CN"
var checks: int = 0
var failures: Array[String] = []
var report: Dictionary = {"evidence_kind":"rendered-controller-fixture", "native_input":false, "author_setup":[], "captures":[], "compression":[], "prediction":[]}
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message); push_error(message)
		report.checks=checks; report.failures=failures
		if not folder.is_empty():
			var failed_report := FileAccess.open(folder.path_join("reports.json"),FileAccess.WRITE)
			if failed_report != null: failed_report.store_string(JSON.stringify(report,"\t")); failed_report.close()
		quit(1)
func settle() -> void:
	for frame: int in 5: await process_frame
func expose(node: Control) -> void:
	var child: Node = node
	var ancestor: Node = child.get_parent()
	while ancestor != null:
		if ancestor is TabContainer: ancestor.current_tab = child.get_index()
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(node)
		child = ancestor; ancestor = ancestor.get_parent()
func click(action: Button, viewport: Window = null) -> void:
	if viewport == null: viewport = root
	check(action != null and not action.disabled,"Action available")
	if action == null or action.disabled: return
	expose(action); await settle()
	var point: Vector2 = action.get_global_rect().get_center()
	check(viewport.get_visible_rect().has_point(point),"Rendered button center in viewport: "+action.text)
	var motion := InputEventMouseMotion.new(); motion.position = point; viewport.push_input(motion,true)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		viewport.push_input(event,true); await process_frame
	await settle()
func press(scene, id: String) -> void: await click(scene.find_child(id,true,false) as Button)
func capture(name: String, viewport: Window = null) -> void:
	if viewport == null: viewport = root
	await settle(); RenderingServer.force_draw(false); await process_frame
	var picture: Image = viewport.get_texture().get_image()
	check(picture != null and picture.save_png(folder.path_join(name+".png")) == OK,"Capture "+name)
	report.captures.append({"name":name,"viewport":str(viewport.size)})
func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(folder.path_join(name),FileAccess.WRITE)
	check(file != null,"Write "+name)
	if file != null: file.store_string(JSON.stringify(value,"\t")); file.close()
func author_examples(scene, indices: Array, order: int) -> void:
	var examples: Array = []
	for index: int in indices: examples.append(Catalog.sample(index))
	scene.session.data.draft.examples = examples
	scene.session.data.draft.order = order
	scene.edit_draft(); scene.rebuild_editor_preserving_inputs()
	report.author_setup.append({"action":"select public examples and history", "indices":indices,"order":order})
	await settle(); await press(scene,"Train")
func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): folder=argument.trim_prefix("--evidence-dir=")
		elif argument.begins_with("--locale="): locale=argument.trim_prefix("--locale=")
	if folder.is_empty() or DisplayServer.get_name()=="headless":
		push_error("Requires rendered isolated QA run with --evidence-dir absolute path"); quit(1); return
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_node("Localization").set_locale(locale)
	report.locale=locale
	var watchdog := create_timer(90.0)
	watchdog.timeout.connect(func() -> void: check(false,"Bounded evidence runner exceeded 90 seconds"))
	root.get_node("TaskNavigation").pending=""; root.get_node("TaskNavigation").from_tree=false
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	root.mode=Window.MODE_WINDOWED
	await create_timer(0.5).timeout
	root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720)
	DisplayServer.window_set_size(Vector2i(1280,720))
	await create_timer(0.5).timeout
	await settle()
	check(scene.session.data.works.is_empty(),"Fresh isolated profile has no player works")
	if not scene.session.data.works.is_empty(): scene.queue_free(); quit(1); return
	await author_examples(scene,[5],2)
	var carried_model: String = Model.identity(scene.session.data.model)
	scene.change_task(2); await settle()
	for order: int in 2:
		scene.begin_commission(order); await settle()
		for codec: String in ["raw","predictive"]:
			await press(scene,"Raw" if codec=="raw" else "Transport")
			check(scene.latest.get("lossless",false),"Order transport restores exact source")
			report.compression.append({"order":order,"codec":codec,"model_id":Model.identity(scene.session.data.model),"machine":scene.session.data.draft.machine.duplicate(true),"cost":scene.latest.get("cost",{}).duplicate(true),"metrics":scene.latest.get("metrics",{}).duplicate(true),"receipt":scene.commission_receipts[-1].duplicate(true) if not scene.commission_receipts.is_empty() else {}})
		await capture("01-order-"+str(order+1))
	scene.commission=-1
	scene.change_task(5); await settle()
	await press(scene,"ToPredict")
	check(scene.session.data.mode=="predict" and Model.identity(scene.session.data.model)==carried_model,"C→P inherits the actual sample5 rule box")
	scene.change_task(5); await settle()
	for kind: String in ["practice-v2","check-v2"]:
		await press(scene,"FamilyPractice" if kind=="practice-v2" else "FamilyCheck")
		check(not scene.session.prediction.is_empty(),"Family prediction starts successfully")
		if scene.session.prediction.is_empty(): return
		var prefix_before: Array = scene.session.prediction.prefix.duplicate()
		await press(scene,"Commit")
		check(scene.session.prediction.prefix==prefix_before and scene.session.prediction.rows.is_empty(),"Manual commit preserves sealed truth")
		await capture("02-"+kind+"-committed")
		await press(scene,"Reveal")
		await press(scene,"ContinuePrediction")
		check(scene.session.prediction.finished,"Remainder completes through authoritative commit/reveal")
		report.prediction.append({"round":scene.session.prediction.duplicate(true),"evidence":scene.session.prediction_evidence().duplicate(true)})
		await capture("03-"+kind+"-finished")
	# Same carried machine; explicit author setup changes the selected samples.
	scene.change_task(7); await settle()
	await press(scene,"ToGenerate")
	scene.change_task(7); await settle()
	await author_examples(scene,[0,1],2)
	scene.session.data.draft.seed=17; scene.session.data.draft.initial=[0,1]; scene.session.data.draft.length=64; scene.session.data.draft.sampler="weighted"
	scene.edit_draft(); scene.rebuild_editor_preserving_inputs(); await settle()
	report.author_setup.append({"action":"generation controls","seed":17,"initial":[0,1],"length":64,"sampler":"weighted"})
	await press(scene,"Generate"); await press(scene,"PinCreationAQuick")
	var a: Dictionary = scene.pinned_creation.duplicate(true)
	await capture("04-generation-A")
	await author_examples(scene,[0,4],2)
	await press(scene,"Generate")
	var b: Dictionary = scene.compared_creation.duplicate(true)
	check(not a.is_empty() and not b.is_empty() and scene.creation_report.get("controlled_effect",false),"One public passage change causes measured output difference")
	report.comparison=scene.creation_report.duplicate(true)
	report.generation_a=a; report.generation_b=b
	await capture("05-generation-B")
	await press(scene,"CreationFirstDifference"); await capture("06-first-difference")
	scene.name_input.text="Two paths · A" if locale=="en" else "两条路 · A"; await press(scene,"KeepCreationA")
	scene.name_input.text="Another path · B" if locale=="en" else "另一条路 · B"; await press(scene,"KeepCreationB")
	check(scene.session.data.works.size()==2,"A and B saved as protected actual works")
	if scene.session.data.works.size()!=2:
		write_json("reports.json",report); scene.queue_free(); quit(1); return
	var saved: Array = scene.session.data.works.duplicate(true)
	write_json("work-A.json",saved[0]); write_json("work-B.json",saved[1])
	scene.works.select(1); scene.focus_work(); await settle()
	check(is_instance_valid(scene.work_focus),"Saved exhibition opens")
	if not is_instance_valid(scene.work_focus): return
	var view = scene.work_focus
	view.static_overview=false; view.seek(32); await capture("07-performance-mid",view)
	view.seek(64); await capture("08-performance-complete",view)
	view.tabs.current_tab=1; view.select_cell(int(report.comparison.first_difference)); await capture("09-performance-explanation",view)
	check(view.work==saved[1] and view.canvas.selected==int(report.comparison.first_difference),"Exhibition explanation has same saved work and actual divergence")
	# Emit the renderer's public host bridge after photographing its real button.
	view.request_fork.emit(); await settle()
	check(scene.session.data.works==saved and scene.session.data.parent_work==saved[1].id,"Fork creates recipe draft and preserves both works")
	await capture("10-fork-return")
	scene.session.save()
	write_json("session.json",scene.session.data)
	report.checks=checks; report.failures=failures
	write_json("reports.json",report)
	scene.queue_free(); await settle()
	print("PASS: personal works rendered evidence %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
