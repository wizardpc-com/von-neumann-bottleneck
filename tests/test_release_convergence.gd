extends SceneTree
const Save = preload("res://src/save/global_save.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func run() -> void:
	var nav: Node = root.get_node("TaskNavigation")
	var mode: Node = root.get_node("GameMode")
	mode.set_mode(&"game")
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	nav.remember_visit("hardware_foundations","tutorial")
	nav.selected="chapter_3/arrival"; nav.camera_saved=true
	nav.prepare_continue()
	check(nav.selected=="hardware_foundations/tutorial" and not nav.camera_saved,"Continue locates the recent task instead of a fixed chapter")
	var settings := ConfigFile.new(); settings.load(nav.NAVIGATION_PATH)
	check(settings.get_value("navigation","last_visited_task")==nav.selected,"Recent task persists independently of telemetry and progress")
	nav.last_visited_task="chapter_4/mixed"; nav.prepare_continue()
	check(nav.selected=="chapter_4/mixed","Recent fourth-chapter selection is retained even when currently locked")
	check(not nav.enter("chapter_4/mixed"),"Navigation cannot unlock a task")
	mode.set_mode(&"test"); nav.remember_visit("chapter_3","arrival")
	check(nav.last_visited_task=="chapter_4/mixed","Test visits never replace Game navigation")
	mode.set_mode(&"game")
	check(root.get_node("GlobalSave")._save_snapshot()==before,"Navigation does not mutate progress")
	var save := Save.new(); save.configure_for_test("user://writer-guard.json","user://writer-workbenches.json")
	var legacy: Dictionary = save._save_snapshot(); legacy.schema_version=1; legacy.erase("minimum_writer_version")
	write(save.storage_path,legacy)
	check(save._read_save(save.storage_path).status==&"ok","Schema-1 saves remain readable")
	save.load_game(); check(save.save_game(true),"Legacy data can be written in protected schema 2")
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save.storage_path))
	check(current.schema_version==2 and current.minimum_writer_version==2,"New snapshots protect against already-issued schema-1 binaries")
	var backup: String = FileAccess.get_file_as_string(save.storage_path+".bak")
	check(JSON.parse_string(backup).schema_version==1,"Legacy automatic backup survives first upgrade")
	for future: Dictionary in [dict_with(current,"minimum_writer_version",99),dict_with(current,"future_feature",{}),future_chapter(current),future_layout(current)]:
		write(save.storage_path,future)
		var raw: String = FileAccess.get_file_as_string(save.storage_path)
		save.load_game()
		check(not save.disk_write_allowed and not save.save_game(true) and not save.start_new_game(false).ok,"Unsupported data blocks auto-save and replacement")
		check(FileAccess.get_file_as_string(save.storage_path)==raw and FileAccess.get_file_as_string(save.storage_path+".bak")==backup,"Unknown data and its backup remain byte-identical")
	save.free()
	var recorder: Node = root.get_node("PersonalRecords")
	root.get_node("PlaytestData").record_official_run(&"hardware_foundations",&"half_adder",true,{"case_count":4,"case_set_version":"synthetic-hardware"})
	check(recorder.best["hardware_foundations/half_adder"].passed_cases==4,"Hardware records show passed cases rather than invented cycle scores")
	check(preload("res://src/ui/window_mode.gd").MINIMUM_WINDOWED_SIZE.x>=1280 and preload("res://src/ui/window_mode.gd").MINIMUM_WINDOWED_SIZE.y>=720,"Minimum window protects the readable workspace")
	var layout: Node = root.get_node("LayoutChapter")
	var reference: Dictionary = preload("res://src/layout_chapter/layout_catalog.gd").reference_solution("mixed")
	layout.game_solutions["mixed"]=reference
	for row: Dictionary in recorder.snapshot().tasks:
		if row.key=="chapter_4/mixed":
			check(row.best.ram_read_bytes>0 and row.best.ram_write_bytes>0 and row.best.peak_extra_bytes>0,"Layout records use real saved-solution transfer and space metrics")
	layout.game_solutions.clear()
	var rows: Array[Dictionary] = nav.tasks()
	var extra: Dictionary = rows[0].duplicate(true)
	extra.key="synthetic/extension"; extra.region=12; extra.region_title_key="tree.region.0"; extra.optional=true
	extra.bonus_goals=[{"id":"synthetic","complete":true}]; rows.append(extra)
	var snapshot: Dictionary = root.get_node("PersonalRecords").snapshot(rows)
	check(snapshot.total==41 and snapshot.regions.size()==6 and snapshot.bonus_total==6,"Task metadata expands regions, optional nodes and bonuses without fixed counters")
	var page: Node = load("res://src/playtest/personal_records_view.tscn").instantiate(); root.add_child(page)
	await process_frame
	check(page.find_child("CommunityToggle",true,false)==null and page.online==null,"Unconfigured builds create neither community controls nor request objects")
	page.queue_free(); await process_frame
	for message: String in failures: push_error(message)
	print("PASS: branch Continue, future-save protection, dynamic metadata and complete offline record UI" if failures.is_empty() else "FAIL: release convergence")
	quit(0 if failures.is_empty() else 1)
func dict_with(source: Dictionary,key: String,value: Variant) -> Dictionary:
	var copy: Dictionary = source.duplicate(true); copy[key]=value; return copy
func future_chapter(source: Dictionary) -> Dictionary:
	var copy: Dictionary = source.duplicate(true); copy.game.chapter_5={"valuable":"future-player-data"}; return copy
func write(path: String,value: Dictionary) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(value)); file.close()

func future_layout(source: Dictionary) -> Dictionary:
	var copy: Dictionary = source.duplicate(true); copy.game.layout.future_layout_data={"keep":true}; return copy
