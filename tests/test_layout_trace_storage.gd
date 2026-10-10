extends SceneTree
## Physical storage and allocation history, through the real layout host.
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func open_host(id: String):
	root.get_node("TaskNavigation").pending = "chapter_4/"+id
	var host = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host)
	await settle()
	return host
func find_event(run: LayoutRun, kind: StringName, stage: String, scratch: bool, first_record: int = -1, after: int = -1) -> int:
	for index: int in range(after+1,run.events.size()):
		var event: SimulationEvent = run.events[index]
		if event.kind != kind or event.details.get("stage","") != stage: continue
		if first_record >= 0 and int(event.details.get("record",-1)) != first_record: continue
		if scratch != (event.address >= int(run.source_map.bytes)) or event.address < 0: continue
		return index
	return -1
func select_event(host, event_index: int) -> void:
	check(event_index >= 0,"Required actual event exists")
	if event_index < 0: return
	var row: int = host.trace_indices.find(event_index)
	check(row >= 0,"Actual event is in the visible unfiltered trace")
	if row >= 0: host._trace_selected(row)
func check_source(host, event: SimulationEvent, message: String) -> void:
	check(host.source_view.visible and not host.copy_view.visible,message)
	check(host.source_view.selected_address == event.address,"Source highlight uses actual event address")
	check(host.copy_view.selected_address == -1 and host.copy_view.selected_record == -1,"Opposite scratch highlights are cleared")
func check_scratch(host, event: SimulationEvent, first_record: int, message: String) -> void:
	check(host.copy_view.visible and not host.source_view.visible,message)
	check(host.copy_view.selected_address == event.address and int(host.copy_view.mapping.first_record) == first_record,"Scratch address and actual allocation match the selected event")
	check(host.source_view.selected_address == -1 and host.source_view.selected_record == -1,"Opposite source highlights are cleared")
func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var host = await open_host("mixed")
	host.design = Catalog.reference_solution("mixed")
	host._changed(); host._run_all(); host.trace_filter = 0; host._select_trace(0)
	var run: LayoutRun = host.runs[0]
	check(run.passed and run.scratch_maps.size() > 1,"Real batch fixture is correct and reuses scratch for multiple batches")
	var source_read: int = find_event(run,&"read","prepare",false,0)
	select_event(host,source_read); check_source(host,run.events[source_read],"Preparing reads source even when the same identity has a scratch copy")
	var scratch_write: int = find_event(run,&"write","prepare",true,0)
	select_event(host,scratch_write); check_scratch(host,run.events[scratch_write],0,"Preparation writes the actual scratch region")
	var scratch_read: int = find_event(run,&"read","query",true,0)
	select_event(host,scratch_read); check_scratch(host,run.events[scratch_read],0,"Query reads the actual scratch region")
	var query_source: int = find_event(run,&"read","query",false,-1,scratch_read)
	select_event(host,query_source); check_source(host,run.events[query_source],"Uncopied query fields return to source rather than the corresponding scratch record")
	var next_scratch: int = find_event(run,&"write","prepare",true,4)
	select_event(host,next_scratch); check_scratch(host,run.events[next_scratch],4,"Reused scratch address resolves to the next actual batch")
	select_event(host,scratch_write); check_scratch(host,run.events[scratch_write],0,"Scrubbing backward resolves the original batch at the reused address")
	var eviction: int = find_event(run,&"evict","query",true)
	select_event(host,eviction)
	if eviction >= 0:
		check_scratch(host,run.events[eviction],0,"Eviction uses physical scratch address despite lacking a logical record")
		check(host.copy_view.selected_record == -1,"Eviction never invents a record identity")
	var output_index: int = -1
	for index: int in run.events.size():
		if run.events[index].kind == &"output": output_index = index; break
	select_event(host,output_index)
	check(host.source_view.selected_address == -1 and host.copy_view.selected_address == -1 and host.source_view.selected_record == -1 and host.copy_view.selected_record == -1,"Output sink has no physical RAM or stale logical highlight")
	# Edit after running: the old trace must restore its own map, not the preview.
	host.design.recipe.groups[0].order = "field"
	host._changed(); select_event(host,scratch_write)
	check(host.stale and host.copy_view.mapping == run.scratch_maps[0],"Historical trace restores actual mapping after draft edits")
	host.design.strategy = "full"; host.design.copy_fields = [0,1,2,3]
	host._changed(); host._run_all(); host.trace_filter = 0; host._select_trace(0)
	var failed: LayoutRun = host.runs[0]
	check(failed.metrics.error == "space_limit","Finite-space failure is produced by the real simulator")
	select_event(host,failed.events.size()-1)
	check(host.source_view.selected_address == -1 and host.copy_view.selected_address == -1 and host.source_view.selected_record == -1 and host.copy_view.selected_record == -1,"No-address error clears both region highlights")
	host.queue_free(); await settle()
	# Real order selector must synchronize event indices with its selected case.
	host = await open_host("relocation")
	host.design = Catalog.reference_solution("relocation")
	host._changed(); host._run_all(); host.trace_filter = 0; host._select_trace(1)
	await settle()
	var b_events: int = host.trace_indices.size()
	var choice := host.find_child("LayoutOrderChoice",true,false) as OptionButton
	check(choice != null,"Public order selector exists")
	if choice != null: choice.item_selected.emit(0)
	await settle()
	check(host.case_index == 0 and host.trace_indices.size() == host.runs[0].events.size() and host.trace_indices.size() < b_events,"Switching B to A synchronizes the displayed trace rather than indexing the old B list")
	host._trace_selected(host.trace_indices.size()-1)
	check(host.source_view.selected_address == -1 and host.copy_view.selected_address == -1,"Final A output is safely inspectable after switching from longer B")
	host.queue_free(); await settle()
	print("PASS: layout trace storage %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
