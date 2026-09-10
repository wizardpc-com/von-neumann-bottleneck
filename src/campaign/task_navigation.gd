extends Node
## Transient navigation only. Completion remains owned by the existing chapter states.
const SCENES := {"hardware_foundations": "res://src/hardware_foundations/hardware_foundations.tscn",
	"chapter_1": "res://src/system_lab/system_lab.tscn", "chapter_2": "res://src/ui/main.tscn",
	"chapter_3": "res://src/overlap_chapter/overlap_chapter.tscn", "chapter_4":"res://src/layout_chapter/layout_chapter.tscn"}
const MAP_SCENE := "res://src/campaign/task_tree.tscn"
var pending: String = ""
var selected: String = "hardware_foundations/tutorial"
var from_tree: bool = false
var camera: Vector2 = Vector2.ZERO
var zoom: float = 0.55
var camera_saved: bool = false

func tasks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var hardware := preload("res://src/hardware_foundations/prologue_level_catalog.gd").new()
	var state: Dictionary = GlobalSave.game_player_content.completed_levels
	for id: StringName in hardware.level_ids():
		var deps: Array = hardware.dependencies(id)
		result.append(_task("hardware_foundations",String(id),0,Localization.text(hardware.title_key(id)),
			Localization.text(hardware.description_key(id)),deps,hardware.is_unlocked(id,state),bool(state.get(id,false)),
			String(hardware.level_branch_id(id)).ends_with("exploration")))
	var system := preload("res://src/system_lab/system_level_catalog.gd").new()
	for id: StringName in system.level_ids():
		result.append(_task("chapter_1",String(id),1,Localization.text(system.title_key(id)),
			Localization.text(system.description_key(id)),system.dependencies(id),
			system.is_unlocked(id,SystemChapter.completed_levels(),SystemChapter.prologue_ready),
			bool(SystemChapter.completed_levels().get(id,false)),id in [&"read_once",&"two_orders"]))
	var locality := preload("res://src/locality_chapter/locality_level_catalog.gd").new()
	for id: StringName in locality.level_ids():
		result.append(_task("chapter_2",String(id),2,Localization.text(locality.title_key(id)),
			Localization.text(locality.description_key(id)),locality.dependencies(id),
			locality.is_unlocked(id,LocalityChapter.completed_levels(),LocalityChapter.chapter_unlocked()),
			bool(LocalityChapter.completed_levels().get(id,false)),false))
	var overlap = preload("res://src/overlap_chapter/overlap_catalog.gd")
	for id: String in overlap.IDS:
		result.append(_task("chapter_3",id,3,Localization.text(StringName("overlap."+id+".title")),
			Localization.text(StringName("overlap."+id+".goal")),overlap.DEPS[id],
			overlap.unlocked(id,OverlapChapter.completed(),OverlapChapter.chapter_unlocked()),
			OverlapChapter.completed().has(id),false))
	var layout = preload("res://src/layout_chapter/layout_catalog.gd")
	for id: String in layout.IDS:
		result.append(_task("chapter_4",id,4,layout.title(id),layout.goal(id),layout.DEPS[id],
			layout.unlocked(id,LayoutChapter.completed(),LayoutChapter.chapter_unlocked()),LayoutChapter.completed().has(id),false))
	for task: Dictionary in result:
		if task.body.is_empty() and task.id in ["tutorial","half_adder"]:
			task.body = Localization.text(StringName("hardware.prologue.map.%s_description"%task.id))
		match task.key:
			"chapter_1/assembly": task.dependencies.append("hardware_foundations/load_store")
			"chapter_2/distant_reads": task.dependencies.append("chapter_1/bottleneck")
			"chapter_3/arrival": task.dependencies.append("chapter_2/capstone")
			"chapter_4/fields": task.dependencies.append("chapter_2/capstone")
	return result

func _task(domain: String,id: String,region: int,title: String,body: String,deps: Array,available: bool,done: bool,optional: bool) -> Dictionary:
	var dependencies: Array[String] = []
	for dep: Variant in deps: dependencies.append(domain+"/"+String(dep))
	return {"key":domain+"/"+id,"id":id,"domain":domain,"region":region,"title":title,"body":body,
		"dependencies":dependencies,"unlocked":available or GameMode.is_test_mode(),"completed":done,"optional":optional}

func enter(key: String) -> bool:
	for task: Dictionary in tasks():
		if task.key == key and task.unlocked:
			PlaytestData.record_map_action(&"task_start",key)
			selected = key
			pending = key
			from_tree = true
			return get_tree().change_scene_to_file(SCENES[task.domain]) == OK
	return false

func consume(domain: String) -> StringName:
	if pending.get_slice("/",0) != domain: return &""
	var id := StringName(pending.get_slice("/",1))
	call_deferred("_clear_pending")
	return id

func _clear_pending() -> void:
	pending = ""

func return_to_tree() -> bool:
	if not from_tree or not pending.is_empty(): return false
	get_tree().call_deferred("change_scene_to_file",MAP_SCENE)
	return true
