extends RefCounted
## Candidate-only decisions; all measurements and unlocks are recomputed.
const Model = preload("res://experiments/service_plan/model.gd")
const PATH := "user://service-session.json"
const MAX_BYTES := 262144

static func contract_id() -> String:
	var data: Array = []
	for stream: int in 4:
		var inputs: Array = []
		for step: int in 6: inputs.append(Model.input(stream,step))
		data.append([Model.initial(stream),inputs])
	return JSON.stringify([Model.VERSION,Model.WEIGHTS,data,Model.REPRESENTATIONS,Model.SCRATCH_LIMIT,
		[64,72,4,4,24,8,0.65,0.35],[1420,350,600,320,320,0.000000001,0.02]]).sha256_text()

static func integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func clean_plan(value: Variant) -> Dictionary:
	if not value is Dictionary or value.size() != 3: return {}
	if not integer(value.get("slots"),1,4): return {}
	if not value.get("representations") is Array or value.representations.size() != 4: return {}
	var formats: Array = []
	for format: Variant in value.representations:
		if not format is String or format not in Model.REPRESENTATIONS: return {}
		formats.append(format)
	if not value.get("groups") is Array or value.groups.is_empty() or value.groups.size() > 24: return {}
	var groups: Array = []; var seen: Dictionary = {}
	for group: Variant in value.groups:
		if not group is Array or group.is_empty() or group.size() > 24: return {}
		var ids: Array = []
		for id: Variant in group:
			if not integer(id,0,23) or seen.has(int(id)): return {}
			ids.append(int(id)); seen[int(id)] = true
		groups.append(ids)
	if seen.size() != 24: return {}
	return {"slots":int(value.slots),"representations":formats,"groups":groups}

static func decode(raw: String) -> Dictionary:
	if raw.to_utf8_buffer().size() > MAX_BYTES: return {"ok":false,"error":"size"}
	var parser := JSON.new()
	if parser.parse(raw) != OK: return {"ok":false,"error":"json"}
	var data: Variant = parser.data
	if not data is Dictionary or data.size() != 6: return {"ok":false,"error":"schema"}
	if not integer(data.get("schema"),1,1) or data.get("model") != Model.VERSION or data.get("contracts") != contract_id(): return {"ok":false,"error":"version"}
	if not integer(data.get("task"),0,2): return {"ok":false,"error":"task"}
	var draft: Dictionary = clean_plan(data.get("draft"))
	if draft.is_empty(): return {"ok":false,"error":"draft"}
	if not data.get("runs") is Array or data.runs.size() > 80: return {"ok":false,"error":"runs"}
	var runs: Array = []
	for run: Variant in data.runs:
		if not run is Dictionary or run.size() != 2 or not integer(run.get("task"),0,2): return {"ok":false,"error":"run"}
		var plan: Dictionary = clean_plan(run.get("plan"))
		if plan.is_empty(): return {"ok":false,"error":"run_plan"}
		runs.append({"task":int(run.task),"plan":plan})
	return {"ok":true,"task":int(data.task),"draft":draft,"runs":runs}

static func encode(task: int, draft: Dictionary, runs: Array) -> String:
	return JSON.stringify({"schema":1,"model":Model.VERSION,"contracts":contract_id(),"task":task,"draft":draft,"runs":runs})

static func read_session(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok":true,"empty":true,"digest":""}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {"ok":false,"error":"read"}
	if file.get_length() > MAX_BYTES: return {"ok":false,"error":"size"}
	var raw := file.get_as_text()
	var result := decode(raw)
	result["digest"] = raw.sha256_text()
	return result

static func write_session(raw: String, path: String = PATH, expected_digest: String = "") -> Error:
	if not decode(raw).ok: return ERR_INVALID_DATA
	# Never overwrite unknown, corrupt or newer data implicitly.
	var current := read_session(path)
	if not current.ok: return ERR_INVALID_DATA
	if current.get("digest", "") != expected_digest: return ERR_ALREADY_IN_USE
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(raw); file.flush()
	var write_error := file.get_error(); file.close()
	if write_error != OK: return write_error
	if not read_session(temporary).ok: return ERR_FILE_CORRUPT
	var had_previous := FileAccess.file_exists(path)
	if had_previous:
		var moved := DirAccess.rename_absolute(path,backup)
		if moved != OK: return moved
	var installed := DirAccess.rename_absolute(temporary,path)
	if installed != OK and had_previous: DirAccess.rename_absolute(backup,path)
	return installed
