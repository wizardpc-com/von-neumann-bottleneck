extends Node

const PerformanceTask = preload("res://src/demo/demo_performance.gd")
const Foundations = preload("res://src/demo/demo_foundations.gd")
const IDS := ["dp_select", "dp_store", "d1_cpu", "d1_upgrade", "d2_cache", "d2_order", "d2_group", "d2_final"]
const SCHEMA := 1
const CONTENT := "demo-route-v1"

var storage_path := "user://demo_progress_v1.json"
var game: Dictionary = _empty()
var test: Dictionary = _empty()
var writes_enabled := true
var recovered := false
var warning := ""


static func _empty() -> Dictionary:
	return {"current": "dp_select", "stage": 0, "drafts": {}, "completed": {}}


func _ready() -> void:
	var args := OS.get_cmdline_args()
	args.append_array(OS.get_cmdline_user_args())
	if "--script" in args or "-s" in args or "--headless" in args or "--editor" in args:
		writes_enabled = false
	else:
		load_game()


func state() -> Dictionary:
	return test if get_node("/root/GameMode").is_test_mode() else game


func has_progress() -> bool:
	return not state()["drafts"].is_empty()


static func stages(id: String) -> int:
	return 3 if id == "dp_store" else (2 if id == "d1_upgrade" else 1)


static func key(id: String, stage: int) -> String:
	return "%s:%d" % [id, stage]


func stage_complete(id: String, stage: int) -> bool:
	return bool(state()["completed"].get(key(id, stage), {}).get("verified", false))


func task_complete(id: String) -> bool:
	for index: int in range(stages(id)):
		if not stage_complete(id, index):
			return false
	return true


func unlocked(id: String) -> bool:
	var index := IDS.find(id)
	if index < 0:
		return false
	if get_node("/root/GameMode").is_test_mode():
		return true
	return index == 0 or task_complete(IDS[index - 1])


func enter(id: String, stage: int = -1) -> bool:
	if not unlocked(id):
		return false
	if stage < 0:
		stage = 0
		while stage < stages(id) - 1 and stage_complete(id, stage):
			stage += 1
	if stage < 0 or stage >= stages(id) or (stage > 0 and not stage_complete(id, stage - 1) and not get_node("/root/GameMode").is_test_mode()):
		return false
	state()["current"] = id
	state()["stage"] = stage
	return true


func draft(id: String, stage: int) -> Dictionary:
	return state()["drafts"].get(key(id, stage), {}).duplicate(true)


func accepted_design(id: String, stage: int) -> Dictionary:
	return state()["completed"].get(key(id, stage), {}).get("design", {}).duplicate(true)


func remember(id: String, stage: int, design: Dictionary) -> void:
	state()["drafts"][key(id, stage)] = design.duplicate(true)
	save_game()


func record_run(receipt: Dictionary) -> void:
	if not receipt.get("complete", false):
		return
	var id: String = receipt["task"]
	var stage: int = receipt["stage"]
	if not unlocked(id):
		return
	# Persist a self-contained accepted design, never a mutable current draft.
	state()["completed"][key(id, stage)] = {"design": receipt["design"].duplicate(true), "signature": receipt["signature"], "identity": receipt["identity"], "verified": true}
	save_game()


static func verify(id: String, stage: int, design: Dictionary) -> Dictionary:
	return Foundations.run(id, stage, design) if id.begins_with("dp_") else PerformanceTask.run(id, stage, design)


func save_game() -> bool:
	if not writes_enabled or get_node("/root/GameMode").is_test_mode():
		return false
	var payload := {"schema": SCHEMA, "content": CONTENT, "game": game}
	var encoded := JSON.stringify(payload)
	var temp := storage_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		warning = "demo.save.failed"
		return false
	file.store_string(encoded)
	file.flush()
	file.close()
	if _read(temp).get("status") != "ok":
		warning = "demo.save.failed"
		return false
	if FileAccess.file_exists(storage_path) and not recovered:
		if DirAccess.copy_absolute(storage_path, storage_path + ".bak") != OK:
			warning = "demo.save.failed"
			return false
	if DirAccess.rename_absolute(temp, storage_path) != OK:
		warning = "demo.save.failed"
		return false
	recovered = false
	return true


func load_game() -> bool:
	warning = ""
	recovered = false
	var result := _read(storage_path)
	if result["status"] == "future":
		writes_enabled = false
		warning = "demo.save.future"
		return false
	if result["status"] != "ok":
		var backup := _read(storage_path + ".bak")
		if backup["status"] != "ok":
			if result["status"] != "missing" or backup["status"] != "missing":
				writes_enabled = false
				warning = "demo.save.corrupt"
			return false
		result = backup
		recovered = true
		warning = "demo.save.recovered"
	game = result["data"]["game"].duplicate(true)
	for id: String in IDS:
		for stage: int in range(stages(id)):
			var evidence: Dictionary = game["completed"].get(key(id, stage), {})
			if evidence.is_empty():
				continue
			var run := verify(id, stage, evidence.get("design", {}))
			evidence["verified"] = run.get("complete", false) and run.get("signature", "") == evidence.get("signature", "") and run.get("identity", "") == evidence.get("identity", "")
			if not evidence["verified"]:
				warning = "demo.save.reverify"
	if not unlocked(game["current"]):
		game["current"] = "dp_select"
		game["stage"] = 0
	if int(game["stage"]) > 0 and not stage_complete(game["current"], int(game["stage"]) - 1):
		game["stage"] = 0
	return true


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 4000000:
		return {"status": "corrupt"}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"status": "corrupt"}
	var data: Variant = parser.data
	if not data is Dictionary or not data.get("schema") is float and not data.get("schema") is int:
		return {"status": "corrupt"}
	if data["schema"] != SCHEMA or data.get("content", "") != CONTENT:
		return {"status": "future"}
	if not data.get("game") is Dictionary:
		return {"status": "corrupt"}
	var saved: Dictionary = data["game"]
	if saved.get("current", "") not in IDS or not saved.get("drafts") is Dictionary or not saved.get("completed") is Dictionary:
		return {"status": "corrupt"}
	if not saved.get("stage") is float and not saved.get("stage") is int:
		return {"status": "corrupt"}
	if float(saved["stage"]) != int(saved["stage"]) or int(saved["stage"]) < 0 or int(saved["stage"]) >= stages(saved["current"]):
		return {"status": "corrupt"}
	for bucket: String in ["drafts", "completed"]:
		for entry: Variant in saved[bucket]:
			if not saved[bucket][entry] is Dictionary:
				return {"status": "corrupt"}
			if bucket == "completed" and not saved[bucket][entry].get("design") is Dictionary:
				return {"status": "corrupt"}
	var valid_keys: Dictionary = {}
	for id: String in IDS:
		for stage: int in range(stages(id)):
			valid_keys[key(id, stage)] = true
			if saved["drafts"].has(key(id, stage)) and not _draft_shape(id, stage, saved["drafts"][key(id, stage)]):
				return {"status": "corrupt"}
	for draft_key: Variant in saved["drafts"]:
		if not valid_keys.has(draft_key):
			return {"status": "corrupt"}
	return {"status": "ok", "data": data}


static func _draft_shape(id: String, stage: int, design: Dictionary) -> bool:
	if id.begins_with("dp_"):
		var circuit := Foundations.restore(design)
		if not Foundations.supply_valid(id, stage, circuit) or not design.get("layout", {}) is Dictionary:
			return false
		for part: Variant in design.get("layout", {}):
			if not part is String or not circuit.components.has(StringName(part)):
				return false
			var position: Variant = design["layout"][part]
			if not position is Array or position.size() != 2:
				return false
			for coordinate: Variant in position:
				if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
					return false
		return true
	var base := PerformanceTask.initial(id, stage)
	var allowed := PerformanceTask.choices(id, stage)
	if design.size() != base.size():
		return false
	for field: String in base:
		if not design.has(field):
			return false
		var value: Variant = design[field]
		if field == "source" and PerformanceTask.editable_program(id):
			if not value is String or value.length() > 8000:
				return false
		elif allowed.has(field):
			if field in ["cache", "group"] and (value is int or value is float):
				if value != int(value):
					return false
				value = int(value)
			if value not in allowed[field]:
				return false
		elif value != base[field]:
			return false
	return true
