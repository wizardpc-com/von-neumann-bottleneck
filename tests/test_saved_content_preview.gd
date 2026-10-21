extends SceneTree
const Preview=preload("res://src/ui/saved_content_preview.gd")
const Model=preload("res://experiments/creation/model.gd")
var checks: int=0
var failures: int=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var view=Preview.new();root.add_child(view)
	var trained: Dictionary=Model.learn([[0,1,2,3,0,1,2,3]],1,Model.default_machine())
	var record: Dictionary=Model.generate(trained.model,[0],48,7,"weighted",Model.default_machine())
	var work: Dictionary={"id":"explicit-model-fixture","name":"QA output","output":record.output.duplicate(),"recipe":record.recipe.duplicate(true)}
	var before: String=JSON.stringify(work)
	check(view.configure_work(work,true),"Actual model output can be previewed")
	check(view.symbols==record.output and view.preview_symbols()==record.output.slice(0,32),"Preview uses exact first symbols and keeps full count")
	check(JSON.stringify(work)==before,"Preview does not rewrite saved work or recipe")
	check(view.configure_work(work,false) and not view.confirmed_source,"Recovery preview is explicitly not confirmed source")
	check(not view.configure_work({"id":"bad","output":[0,9]},true) and view.symbols.is_empty(),"Invalid symbols do not leave a partial fake work")
	check(not view.configure_work({"id":"huge","output":[1.0e100]},true),"Huge finite symbols reject before integer conversion")
	var plan: Dictionary={"components":[{"id":"A"},{"id":"B"}],"layout":{"A":{"x":12,"y":18},"B":{"x":130,"y":80}},"wires":[{"from_node":"A","to_node":"B"}]}
	before=JSON.stringify(plan)
	check(view.configure_plan(plan,"QA plan"),"Real layout/connection structure can be previewed separately")
	check(view.content_kind==&"plan" and view.positions.size()==2 and view.wires.size()==1,"Plan is a layout card, not a chip or generated work")
	check(JSON.stringify(plan)==before,"Plan preview is read-only")
	check(not view.configure_plan({"components":[{"id":"A"}],"layout":{}},"Old"),"Missing historic layout is not invented")
	check(view.content_kind.is_empty(),"Invalid/empty state clears previous preview")
	view.queue_free();await process_frame
	print("PASS: test_saved_content_preview " if failures==0 else "FAIL: test_saved_content_preview ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
