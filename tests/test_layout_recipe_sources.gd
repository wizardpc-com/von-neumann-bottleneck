extends SceneTree
## The visible copy action and official records name actually executed orders.
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Simulator = preload("res://src/layout_chapter/layout_simulator.gd")
var failures: Array[String] = []
var checks: int = 0
var official: Array[Dictionary] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func open_host(id: String):
	root.get_node("TaskNavigation").pending = "chapter_4/"+id
	var host = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host); await settle()
	return host
func capture(event: Dictionary) -> void:
	if event.get("payload",{}).get("chapter_id","") == "chapter_4": official.append(event.duplicate(true))
func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("PlaytestData").official_result.connect(capture)
	var state: Node = root.get_node("LayoutChapter")
	var host = await open_host("relocation")
	host.design = Catalog.reference_solution("relocation")
	host._changed(); host._run_all()
	check(not official.is_empty(),"Real official run emits its measured provenance")
	var first_digest: String = str(official[-1].payload.recipe_digest)
	var first_signatures: Array = [host.runs[0].recipe_signature,host.runs[1].recipe_signature]
	var accepted: Dictionary = state.completed().relocation.duplicate(true)
	host.design.recipe = Recipe.field_major()
	host._changed(); host._run_all()
	check(official[-1].payload.recipe_digest == first_digest,"An unused relocation root recipe cannot change official provenance")
	check([host.runs[0].recipe_signature,host.runs[1].recipe_signature] == first_signatures,"Both actually executed order signatures remain unchanged")
	host.design.orders.B.recipe = Recipe.record_major()
	host._changed(); host._run_all()
	check(official[-1].payload.recipe_digest != first_digest,"Changing an executed B layout changes the official recipe digest")
	check(host.runs[0].recipe_signature == first_signatures[0] and host.runs[1].recipe_signature != first_signatures[1],"Actual A remains fixed and actual B changes")
	host.queue_free(); await settle()
	host = await open_host("batches")
	var before: Dictionary = host.design.duplicate(true)
	var copy_button := host.find_child("LayoutCopyPrevious",true,false) as Button
	check(copy_button != null,"An executed previous B order offers a copy action")
	if copy_button != null:
		check(copy_button.text.contains("订单 B") or copy_button.text.contains("order B"),"Copy action explicitly names previous order B")
		copy_button.pressed.emit(); await settle()
		check(host.design.recipe == accepted.orders.B.recipe and host.design.recipe != accepted.recipe,"Actual copy callback uses B's executed recipe rather than the unused root container")
		check(state.completed().relocation == accepted,"Copy never mutates the accepted source order")
		host._undo(false); await settle()
		check(host.design == before,"Copy is one undoable design edit")
		host._undo(true); await settle()
		check(host.design.recipe == accepted.orders.B.recipe,"Redo restores the same copied B recipe")
	host._run_all()
	check(official[-1].payload.recipe_digest == Simulator.design_signature(host.design),"Single-design levels retain their existing recipe digest")
	# A legacy single-plan relocation record may have no B order. Its root
	# is not evidence that the B-specific layout was executed.
	state.completed().relocation = Catalog.starter_design()
	host._rebuild_tools(); await settle()
	check(host.find_child("LayoutCopyPrevious",true,false) == null,"Missing B provenance hides the B copy action rather than guessing from the root")
	state.completed().relocation = accepted
	host.queue_free(); await settle()
	root.get_node("PlaytestData").official_result.disconnect(capture)
	print("PASS: layout recipe sources %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
