extends SceneTree
const Focus = preload("res://experiments/creation/work_focus.gd")
const Model = preload("res://experiments/creation/model.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 3: await process_frame
func run() -> void:
	var trained: Dictionary = Model.learn([[0,1,2,3,0,1,2,3]],1,Model.default_machine())
	var record: Dictionary = Model.generate(trained.model,[0],48,7,"weighted",Model.default_machine())
	var work: Dictionary = {"id":"exhibit-fixture", "name":"Actual signal", "output":record.output.duplicate(), "recipe":record.recipe.duplicate(true), "mapping":"light-shapes-v1", "parent":""}
	var before: String = JSON.stringify(work)
	var view = Focus.new(); view.configure(work,true,record); root.add_child(view); await settle()
	check(view.canvas.output==record.output and view.canvas.viewing_mapping=="light-trace-v1", "Actual recorded symbols use explicit viewer mapping")
	view.seek(0); view.static_overview=false; view.playing=true; view._process(0.5)
	check(view.cursor==2 and view.canvas.revealed==2,"Playback reveals ordered snapshot at presentation tempo")
	view.playing=false; view._process(4.0); check(view.cursor==2,"Pause keeps exact cursor")
	view.step(); check(view.cursor==3,"Step advances one actual symbol")
	view.select_cell(20); check(view.cursor==21 and view.canvas.selected==20,"Cell selection scrubs same cursor")
	view.tabs.current_tab=1; check(view.cursor==21 and "counts" in view.evidence_label.text,"Explanation keeps identity/cursor with actual count evidence")
	var wrong: Dictionary = record.duplicate(true); wrong.output[0]=3
	check(not view.set_evidence(wrong),"Different output cannot masquerade as saved generation evidence")
	check(view.set_evidence(record),"Matching saved recipe evidence remains available")
	view.seek(0); view.speed=16; view.playing=true; view._process(0.5)
	check(view.cursor==8 and JSON.stringify(work)==before and view.work==work,"Tempo changes only presentation state")
	view.reduced_motion=true; view.playing=true; view._process(99)
	check(view.cursor==8,"Reduced motion suppresses autoplay")
	view.playing=false; view.step(); check(view.cursor==9,"Reduced motion retains explicit step")
	view.static_overview=true; view.sync_presentation(); check(view.canvas.revealed==-1 and view.cursor==9,"Static overview preserves explanation position")
	view.mapping_choice.select(1); view.sync_presentation()
	check(view.canvas.viewing_mapping=="light-shapes-v1" and view.work.mapping=="light-shapes-v1" and JSON.stringify(work)==before,"Original map selectable without changing protected work")
	view.mapping_choice.select(0); view.sync_presentation(); view.canvas.size.x=840; view.canvas.update_layout()
	var rect: Rect2 = view.canvas.cell_rect(20)
	view.canvas.size.x=580; view.canvas.update_layout()
	check(view.canvas.columns==16 and int(rect.position.y/((840.0-16)/16))==int(view.canvas.cell_rect(20).position.y/view.canvas.cell_size),"Trace symbol row remains stable across widths")
	view.dismiss(); await settle()
	print("PASS: creation exhibition %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
