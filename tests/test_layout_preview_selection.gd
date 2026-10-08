extends SceneTree
## Rebinding an address preview never transfers a historical event selection.
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 6: await process_frame

func no_selection(view: Control) -> bool:
	return view.selected_address == -1 and view.selected_record == -1 and view.selected_field == -1

func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		# Each locale starts from the same isolated Test draft. The preceding
		# locale's real edit must not become this fixture's starting recipe.
		root.get_node("LayoutChapter").test_drafts.erase("fields")
		root.get_node("TaskNavigation").pending = "chapter_4/fields"
		var host = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
		root.add_child(host); await settle()
		host._run_all(); host.trace_filter = 0; host._select_trace(0)
		var measured: LayoutRun = host.runs[0]
		var event_index: int = -1
		for index: int in measured.events.size():
			if measured.events[index].kind == &"read" and measured.events[index].address >= 0:
				event_index = index; break
		check(event_index >= 0,locale+": actual native-layout run has a physical read event")
		if event_index < 0:
			host.queue_free(); await settle(); continue
		var event: SimulationEvent = measured.events[event_index]
		var row: int = host.trace_indices.find(event_index)
		check(row >= 0,locale+": actual read appears in the unfiltered trace")
		host._trace_selected(row)
		check(host.source_view.selected_address == event.address and host.source_view.selected_record == event.details.record and host.source_view.selected_field == event.details.field,locale+": historical read selects its exact physical and logical identity")
		var old_map: Dictionary = measured.source_map.duplicate(true)
		var old_metrics: Dictionary = measured.metrics.duplicate(true)
		var old_signature: String = measured.recipe_signature
		# Use the field-drop editing action, rather than replacing the recipe fixture.
		host._drop_field(int(event.details.field),(int(event.details.field)+2)%4)
		await settle()
		var moved_address: int = -1
		for cell: Dictionary in host.source_view.mapping.cells:
			if cell.record == event.details.record and cell.field == event.details.field:
				moved_address = int(cell.address); break
		check(host.stale and moved_address >= 0 and moved_address != event.address,locale+": actual field edit moves the selected identity in the new unrun preview")
		check(no_selection(host.source_view) and no_selection(host.copy_view),locale+": rebinding a draft preview clears all old event selection fields")
		check(host.runs[0] == measured and measured.source_map == old_map and measured.metrics == old_metrics and measured.recipe_signature == old_signature,locale+": preview editing preserves the actual measured run and mapping")
		host._trace_selected(row)
		check(host.source_view.mapping == old_map and host.source_view.selected_address == event.address and host.source_view.selected_record == event.details.record and host.source_view.selected_field == event.details.field,locale+": selecting history again restores the measured map and exact event highlight")
		check(host.source_view.title.contains("历史结果" if locale == "zh_CN" else "previous run"),locale+": restored event mapping identifies its historical source")
		host.queue_free(); await settle()
	print("PASS: layout preview selection %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
