extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func run() -> void:
	var service: Node = root.get_node("PersonalRecords")
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	var snapshot: Dictionary = service.snapshot()
	check(snapshot.total==40 and snapshot.main_total+snapshot.side_total==40 and snapshot.regions.size()==5,"All existing tasks, no replacement progression.")
	check(snapshot.bonus_total==5,"Existing three plus two Chapter 4 bonus goals.")
	var store: Node = root.get_node("PlaytestData")
	var telemetry: bool = store.telemetry_enabled
	store.telemetry_enabled=false
	store.record_official_run(&"chapter_4",&"mixed",true,{"cycles":2495,"case_set_version":"synthetic-test","case_count":2})
	check(service.best.get("chapter_4/mixed",{}).get("cycles")==2495,"Local result record remains available with telemetry off.")
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	# Snapshot generation time is not player progress.
	before.erase("saved_at_utc"); after.erase("saved_at_utc")
	check(after==before,"Personal record never grants completion.")
	store.telemetry_enabled=telemetry
	var view: Node = load("res://src/playtest/personal_records_view.tscn").instantiate(); root.add_child(view)
	await process_frame
	check(view.data.total==40 and view.content.get_child_count()==5,"Offline completion board shows one card per region, no individual task rows.")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for width: float in [1280.0,960.0]:
			view.size=Vector2(width,720)
			await process_frame; await process_frame
			var total: Label = view.find_child("CompletionTotal",true,false)
			check(total.autowrap_mode==TextServer.AUTOWRAP_OFF and total.get_line_count()==1,"Completion count stays one line at supported widths.")
			check(view.content.columns==(3 if width>=1250 else 2),"Regional cards adapt to available width.")
	view.queue_free(); await process_frame
	if failures.is_empty(): print("PASS: offline personal records, no progression authority, telemetry-independent local results")
	else:
		for message: String in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
