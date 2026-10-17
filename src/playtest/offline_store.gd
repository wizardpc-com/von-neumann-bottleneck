extends RefCounted
## Append-only incidents. Exporting never consumes the local originals.
const FORMAT := "vnb-offline-playtest"
const VERSION := 1
const MAX_FILE_BYTES := 67108864
const MAX_BUNDLE_BYTES := 1073741824
const MAX_ENTRIES := 9999
var root: String = "user://offline_playtest"
var last_error: String = ""
var _latest: Dictionary = {}

static func new_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()

static func now() -> String:
	return Time.get_datetime_string_from_system(true)+"Z"

static func build_identity() -> Dictionary:
	return {"version":ProjectSettings.get_setting("application/config/version","development"),
		"source_commit":ProjectSettings.get_setting("application/config/build_commit","development"),
		"engine":Engine.get_version_info().string,"platform":OS.get_name(),
		"offline_tester":ProjectSettings.get_setting("playtest/offline_tester",false)}

func create_case(context: Dictionary, image: Image = null) -> Dictionary:
	last_error=""
	var id: String = new_id()
	var folder: String = root.path_join("cases").path_join(id)
	var pending: String = root.path_join("pending").path_join(id)
	if not _mkdir(pending): return {}
	if not _write_new_json(pending.path_join("context.json"),context): return {}
	var screenshot_status: String = "captured"
	var screenshot_error: String = ""
	if image == null or image.is_empty():
		screenshot_status="headless" if DisplayServer.get_name()=="headless" else "unavailable"
		screenshot_error="No rendered game viewport was available."
	else:
		var result: Error = image.save_png(pending.path_join("screenshot.png"))
		if result!=OK:
			screenshot_status="failed"; screenshot_error=error_string(result)
			if FileAccess.file_exists(pending.path_join("screenshot.png")):
				DirAccess.rename_absolute(_absolute(pending.path_join("screenshot.png")),_absolute(pending.path_join("screenshot-incomplete.bin")))
	var metadata: Dictionary = {"id":id,"captured_at_utc":now(),"updated_at_utc":now(),
		"revision":0,"category":"other","note":"","status":"draft",
		"task":context.get("task",{}),"build":build_identity(),
		"screenshot_status":screenshot_status,"screenshot_error":screenshot_error}
	if not _write_new_json(pending.path_join("case.json"),metadata): return {}
	if not _mkdir(root.path_join("cases")): return {}
	var rename_error: Error = DirAccess.rename_absolute(_absolute(pending),_absolute(folder))
	if rename_error!=OK: last_error="Could not retain incident: "+error_string(rename_error); return {}
	_latest[id]=metadata.duplicate(true)
	return metadata

func save_note(id: String, note: String, category: String, reported: bool) -> Dictionary:
	last_error=""
	var current: Dictionary = _latest.get(id,{})
	if current.is_empty(): current=read_case(id)
	if current.is_empty(): last_error="Incident is unavailable; the existing files have been preserved."; return {}
	if current.note==note and current.category==category and current.status==("reported" if reported else "draft"): return current
	var revision: int = int(current.get("revision",0))+1
	var data: Dictionary = current.duplicate(true)
	data.note=note; data.category=category; data.status="reported" if reported else "draft"
	data.revision=revision; data.updated_at_utc=now()
	var destination: String = root.path_join("cases").path_join(id).path_join("notes.jsonl")
	if not _append_revision(destination,data): return {}
	_latest[id]=data.duplicate(true)
	return data

func read_case(id: String) -> Dictionary:
	if not _valid_id(id): return {}
	var folder: String = root.path_join("cases").path_join(id)
	var data: Dictionary = _read_json(folder.path_join("case.json"))
	if not _valid_case(data,id): return {}
	var journal_path: String = folder.path_join("notes.jsonl")
	if FileAccess.file_exists(journal_path):
		var file := FileAccess.open(journal_path,FileAccess.READ)
		if file!=null:
			while file.get_position()<file.get_length():
				var parser := JSON.new()
				if parser.parse(file.get_line())!=OK or not parser.data is Dictionary: continue
				var revision: Dictionary = parser.data
				if _valid_case(revision,id) and int(revision.get("revision",0))>int(data.get("revision",0)): data=revision
			file.close()
	data.revision=int(data.get("revision",0))
	return data

func cases() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(_absolute(root.path_join("cases"))): return result
	for id: String in DirAccess.get_directories_at(root.path_join("cases")):
		var data: Dictionary = read_case(id)
		if not data.is_empty(): result.append(data)
	result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a.captured_at_utc)+str(a.id)>str(b.captured_at_utc)+str(b.id))
	return result

func export_bundle(destination: String = "", extras: Dictionary = {}) -> String:
	last_error=""
	var id: String = new_id()
	if destination.is_empty():
		if not _mkdir(root.path_join("exports")): return ""
		destination=root.path_join("exports").path_join("VNB-feedback-%s-%s.zip" % [now().replace(":","-"),id.left(8)])
	if FileAccess.file_exists(destination): last_error="Choose a new filename; existing exports are never overwritten."; return ""
	var pending: String = destination+".partial-"+id
	var archive := ZIPPacker.new()
	var result: Error = archive.open(pending)
	if result!=OK: last_error="Could not create ZIP: "+error_string(result); return ""
	var files: Array[Dictionary] = []
	var total: int = 0
	var sources: Dictionary = {}
	_collect_files(root.path_join("cases"),"cases",sources)
	# Damaged incidents remain exportable as raw recovery evidence, alongside
	# usable incidents, rather than preventing the entire playtest from leaving.
	for case_id: String in DirAccess.get_directories_at(root.path_join("cases")) if DirAccess.dir_exists_absolute(_absolute(root.path_join("cases"))) else PackedStringArray():
		var folder: String = root.path_join("cases").path_join(case_id)
		if read_case(case_id).is_empty() or _read_json(folder.path_join("context.json")).is_empty():
			for relative: String in sources.keys():
				if relative.begins_with("cases/"+case_id+"/"):
					sources["recovery/"+relative]=sources[relative]; sources.erase(relative)
	_collect_files(root.path_join("pending"),"recovery",sources)
	for key: String in extras:
		if sources.has(key): last_error="Duplicate evidence path."; break
		sources[key]=extras[key]
	if sources.size()>MAX_ENTRIES: last_error="Export exceeds 9,999 evidence files; originals are retained."
	for relative: String in sources:
		if not last_error.is_empty(): break
		var bytes: PackedByteArray
		if sources[relative] is PackedByteArray: bytes=sources[relative]
		else:
			if _linked_source(str(sources[relative])): last_error="Linked evidence cannot be exported: "+relative; break
			var source := FileAccess.open(str(sources[relative]),FileAccess.READ)
			if source==null: last_error="Could not read evidence: "+relative; break
			if source.get_length()>MAX_FILE_BYTES: last_error="Evidence exceeds 64 MiB; originals are retained: "+relative; source.close(); break
			bytes=source.get_buffer(source.get_length()); source.close()
		# Export a current materialized note while retaining its append-only revisions.
		if relative.begins_with("cases/") and relative.ends_with("/case.json") and not sources[relative] is PackedByteArray:
			var metadata: Dictionary = read_case(relative.get_slice("/",1))
			if metadata.is_empty(): last_error="Invalid incident metadata; originals are retained: "+relative; break
			bytes=JSON.stringify(metadata,"\t").to_utf8_buffer()
		total+=bytes.size()
		if bytes.size()>MAX_FILE_BYTES or total>MAX_BUNDLE_BYTES: last_error="ZIP exceeds the evidence limit; originals are retained."; break
		if not _zip_entry(archive,relative,bytes): break
		files.append({"path":relative,"size":bytes.size(),"sha256":_hash(bytes)})
	if last_error.is_empty():
		var manifest: Dictionary = {"format":FORMAT,"version":VERSION,"bundle_id":id,"created_at_utc":now(),
			"build":build_identity(),"files":files,"case_count":files.filter(func(entry: Dictionary) -> bool: return str(entry.path).begins_with("cases/") and str(entry.path).ends_with("/case.json")).size(),
			"privacy":"Offline game screenshots, designs, saves, action history and written feedback. Share this file deliberately; no automatic upload."}
		_zip_entry(archive,"manifest.json",JSON.stringify(manifest,"\t").to_utf8_buffer())
	result=archive.close()
	if not last_error.is_empty(): _discard_partial(pending); return ""
	if result!=OK: last_error="ZIP close failed; local originals are retained."; _discard_partial(pending); return ""
	# Verify the finished archive before exposing a successful export to the player.
	var reader := ZIPReader.new()
	if reader.open(pending)!=OK: last_error="ZIP verification failed."; _discard_partial(pending); return ""
	for entry: Dictionary in files:
		var bytes: PackedByteArray = reader.read_file(entry.path)
		if bytes.size()!=int(entry.size) or _hash(bytes)!=entry.sha256:
			last_error="ZIP evidence verification failed: "+str(entry.path); break
	reader.close()
	if not last_error.is_empty(): _discard_partial(pending); return ""
	result=DirAccess.rename_absolute(_absolute(pending),_absolute(destination))
	if result!=OK: last_error="Could not finish ZIP; local originals are retained: "+error_string(result); _discard_partial(pending); return ""
	return _absolute(destination)

func _discard_partial(path: String) -> void:
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(_absolute(path))!=OK:
		last_error+=" Partial export remains at: "+_absolute(path)

func _collect_files(folder: String, prefix: String, output: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(_absolute(folder)): return
	var directory := DirAccess.open(folder)
	if directory==null: last_error="Could not list local evidence: "+prefix; return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if directory.is_link(entry): last_error="Linked evidence is excluded; originals are retained: "+prefix; break
		if directory.current_is_dir(): _collect_files(folder.path_join(entry),prefix.path_join(entry),output)
		else: output[prefix.path_join(entry)]=folder.path_join(entry)
		entry=directory.get_next()
	directory.list_dir_end()

func _write_new_json(path: String, data: Dictionary) -> bool:
	if FileAccess.file_exists(path): last_error="Existing evidence was preserved: "+path.get_file(); return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: last_error="Could not save local feedback: "+error_string(FileAccess.get_open_error()); return false
	var body: String = JSON.stringify(data,"\t")
	file.store_string(body); file.flush()
	var result: Error = file.get_error()
	file.close()
	if result!=OK or FileAccess.get_file_as_string(path)!=body:
		last_error="Feedback write verification failed; the incident files are retained."; return false
	return true

func _append_revision(path: String, data: Dictionary) -> bool:
	var exists: bool = FileAccess.file_exists(path)
	var file := FileAccess.open(path,FileAccess.READ_WRITE if exists else FileAccess.WRITE_READ)
	if file==null: last_error="Could not save note: "+error_string(FileAccess.get_open_error()); return false
	if file.get_length()>0:
		file.seek(file.get_length()-1)
		var needs_boundary: bool = file.get_8()!=10
		file.seek_end()
		# An interrupted final line remains raw evidence; a new complete record
		# starts on its own line so future notes cannot join the damaged fragment.
		if needs_boundary: file.store_8(10)
	var start: int = file.get_position()
	var body: PackedByteArray = (JSON.stringify(data)+"\n").to_utf8_buffer()
	file.store_buffer(body); file.flush()
	var result: Error = file.get_error()
	file.seek(start)
	var verified: bool = file.get_buffer(body.size())==body
	file.close()
	if result!=OK or not verified: last_error="Note write verification failed; earlier notes are retained."; return false
	return true

func _zip_entry(archive: ZIPPacker, path: String, bytes: PackedByteArray) -> bool:
	if archive.start_file(path)!=OK: last_error="Could not add ZIP evidence: "+path; return false
	if archive.write_file(bytes)!=OK: last_error="Could not write ZIP evidence: "+path; return false
	if archive.close_file()!=OK: last_error="Could not finish ZIP evidence: "+path; return false
	return true

func _mkdir(path: String) -> bool:
	var ancestor: String = _absolute(path)
	while not ancestor.is_empty() and not DirAccess.dir_exists_absolute(ancestor):
		if FileAccess.file_exists(ancestor): last_error="Feedback folder is blocked by an existing file."; return false
		var parent: String = ancestor.get_base_dir()
		if parent==ancestor: break
		ancestor=parent
	var result: Error = DirAccess.make_dir_recursive_absolute(_absolute(path))
	if result!=OK: last_error="Could not create feedback folder: "+error_string(result); return false
	return true

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	return parser.data if parser.data is Dictionary else {}

static func _valid_id(id: String) -> bool:
	return id.length()==32 and id.is_valid_hex_number(false)

static func _valid_case(data: Dictionary, id: String) -> bool:
	var revision: Variant = data.get("revision")
	return (data.get("id","")==id and data.get("note") is String and data.get("category") is String
		and data.get("task") is Dictionary and data.get("status") in ["draft","reported"]
		and (revision is int or revision is float) and int(revision)==revision and revision>=0)

static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path

static func _linked_source(path: String) -> bool:
	var cursor: String = _absolute(path).replace("\\","/").simplify_path()
	while cursor!=cursor.get_base_dir() and not cursor.is_empty():
		var parent: String = cursor.get_base_dir()
		var directory := DirAccess.open(parent)
		if directory!=null and directory.is_link(cursor.get_file()): return true
		cursor=parent
	return false

static func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	return context.finish().hex_encode()
