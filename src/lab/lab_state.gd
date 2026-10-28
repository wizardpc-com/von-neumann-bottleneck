extends RefCounted
## Read-only view of real progress for the laboratory, plus a separate record of
## which completions the lab has already "answered". The record never grants or
## changes progression; deleting user://lab_state.cfg only replays responses.

const PATH := "user://lab_state.cfg"
# Journey board stations: region numbers from TaskNavigation.journey_tasks().
const STATIONS := [
	{"regions": [0], "zh": "构造", "en": "Build"},
	{"regions": [1], "zh": "等待", "en": "Waiting"},
	{"regions": [2], "zh": "就近", "en": "Nearby"},
	{"regions": [3], "zh": "在途", "en": "In flight"},
	{"regions": [4], "zh": "布局", "en": "Layout"},
	{"regions": [5], "zh": "表示", "en": "Representation"},
	{"regions": [6], "zh": "服务", "en": "Service"},
	{"regions": [7], "zh": "地址预测", "en": "Address"},
	{"regions": [8], "zh": "压缩", "en": "Compression"},
	{"regions": [9], "zh": "内容预测", "en": "Content"},
	{"regions": [10], "zh": "创造", "en": "Creation"},
]

static var _visits: int = 0

static func note_visit() -> int:
	_visits += 1
	return _visits

static func visits() -> int:
	return _visits

static func tasks() -> Array[Dictionary]:
	var navigation: Node = Engine.get_main_loop().root.get_node_or_null("/root/TaskNavigation")
	if navigation == null: return []
	return navigation.journey_tasks()

static func completed_keys(rows: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for row: Dictionary in rows:
		if bool(row.get("completed", false)): result.append(str(row.key))
	return result

static func station_progress(rows: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for station: Dictionary in STATIONS:
		var station_rows: Array[Dictionary] = []
		for row: Dictionary in rows:
			if int(row.get("region", -1)) in station.regions:
				station_rows.append(row)
		var counts: Dictionary = progress_counts(station_rows)
		counts["zh"] = station.zh; counts["en"] = station.en
		result.append(counts)
	return result

static func progress_counts(rows: Array[Dictionary]) -> Dictionary:
	var counts := {"done": 0, "total": 0, "temporary": 0}
	for row: Dictionary in rows:
		if str(row.get("progress_source", "")) == "session":
			counts.temporary += 1
			continue
		counts.total += 1
		if bool(row.get("completed", false)): counts.done += 1
	return counts

static func seen() -> Array[String]:
	var config := ConfigFile.new()
	var result: Array[String] = []
	if config.load(PATH) == OK:
		for key: Variant in config.get_value("lab", "answered", []): result.append(str(key))
	return result

static func mark_seen(keys: Array[String]) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("lab", "answered", keys)
	config.save(PATH)

static func read_fragments() -> Array[String]:
	var config := ConfigFile.new()
	var result: Array[String] = []
	if config.load(PATH) == OK:
		for key: Variant in config.get_value("archive", "read", []): result.append(str(key))
	return result

static func mark_fragment_read(id: String) -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	var read: Array = config.get_value("archive", "read", [])
	if not id in read: read.append(id)
	config.set_value("archive", "read", read)
	config.save(PATH)
