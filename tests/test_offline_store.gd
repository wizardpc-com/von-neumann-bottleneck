extends SceneTree
const Store = preload("res://src/playtest/offline_store.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)

func run() -> void:
	check(Store._hash(PackedByteArray())=="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","empty evidence uses SHA256 without an engine error")
	var store = Store.new()
	store.root="user://offline-store-test"
	var context: Dictionary = {"task":{"chapter_id":"chapter_1","level_id":"assembly"},"active_domain":{"unsaved_program":"LOAD 3\nHALT"}}
	var image := Image.create(32,24,false,Image.FORMAT_RGB8); image.fill(Color(0.2,0.4,0.8))
	var first: Dictionary = store.create_case(context,image)
	check(not first.is_empty(),"incident persists")
	if first.is_empty(): quit(1); return
	check(first.screenshot_status=="captured","PNG is captured")
	var updated: Dictionary = store.save_note(first.id,"卡住了\n<details>完整意见</details>","bug",true)
	check(updated.get("revision")==1,"append-only note revision")
	var reopened = Store.new(); reopened.root=store.root
	var restored: Dictionary = reopened.read_case(first.id)
	check(restored.note==updated.note and restored.id==updated.id and int(restored.revision)==int(updated.revision),"fresh store restores exact note and identity")
	check(FileAccess.get_file_as_string(store.root.path_join("cases").path_join(first.id).path_join("case.json")).contains('"note": ""'),"initial evidence never overwritten")
	var png_path: String = store.root.path_join("cases").path_join(first.id).path_join("screenshot.png")
	var png_hash: String = FileAccess.get_sha256(png_path)
	var zip: String = reopened.export_bundle("",{"session/test.json":JSON.stringify(context).to_utf8_buffer()})
	check(not zip.is_empty(),"single-file ZIP exports")
	if not zip.is_empty():
		var reader := ZIPReader.new(); check(reader.open(zip)==OK,"ZIP opens")
		var manifest: Dictionary = JSON.parse_string(reader.read_file("manifest.json").get_string_from_utf8())
		check(manifest.format==Store.FORMAT and manifest.version==1,"versioned manifest")
		for entry: Dictionary in manifest.files:
			var body: PackedByteArray = reader.read_file(entry.path)
			check(body.size()==int(entry.size) and Store._hash(body)==entry.sha256,"manifest hash "+str(entry.path))
		var exported_case: Dictionary = JSON.parse_string(reader.read_file("cases/"+str(first.id)+"/case.json").get_string_from_utf8())
		var metadata_text: String = reader.read_file("cases/"+str(first.id)+"/case.json").get_string_from_utf8()
		check(not metadata_text.contains('"revision": 1.0'),"revision remains an integer in external JSON")
		check(exported_case.note==updated.note,"export materializes latest revision")
		check(Image.load_from_file(png_path).get_width()==32,"PNG retained at original dimensions")
		reader.close()
		check(reopened.export_bundle(zip).is_empty(),"existing ZIP never overwritten")
	check(reopened.cases().size()==1 and FileAccess.get_sha256(png_path)==png_hash,"export retains all originals")
	var broken: String = store.root.path_join("cases").path_join(first.id).path_join("notes.jsonl")
	var file := FileAccess.open(broken,FileAccess.READ_WRITE); file.seek_end(); file.store_string('{"note":'); file.close()
	check(reopened.read_case(first.id).note==updated.note,"interrupted revision preserves last complete opinion")
	check(not reopened.save_note(first.id,"恢复后继续写","control",true).is_empty(),"new note follows interrupted tail")
	check(Store.new()._read_json("user://missing-evidence.json").is_empty(),"absent evidence is explicit")
	updated=reopened.read_case(first.id)
	check(updated.note=="恢复后继续写","new complete line survives interrupted previous line")
	var occupied: String = "user://occupied-file"
	file=FileAccess.open(occupied,FileAccess.WRITE); file.store_string("preserve me"); file.close()
	var failing = Store.new(); failing.root=occupied
	check(failing.create_case(context,image).is_empty() and not failing.last_error.is_empty(),"write failure visible")
	check(FileAccess.get_file_as_string(occupied)=="preserve me","storage fault does not overwrite unrelated data")
	check(reopened.export_bundle("user://missing-parent/sub/file.zip").is_empty() and not reopened.last_error.is_empty(),"export destination failure visible")
	check(reopened.read_case(first.id).note==updated.note,"failed export preserves feedback")
	var failed_zip: String = "user://failed-export.zip"
	check(reopened.export_bundle(failed_zip,{"missing.bin":"user://missing-source.bin"}).is_empty(),"unreadable evidence fails export visibly")
	var partials: bool = false
	for filename: String in DirAccess.get_files_at("user://"):
		if filename.begins_with("failed-export.zip.partial-"): partials=true
	check(not FileAccess.file_exists(failed_zip) and not partials,"failed ZIP has no exposed partial copy")
	var rescue = Store.new(); rescue.root="user://rescue-only"
	var rescue_id: String = Store.new_id()
	var rescued: Dictionary = first.duplicate(true); rescued.id=rescue_id; rescued.note="rescue-only unsaved text"
	var prefix: String = "cases/"+rescue_id+"/"
	var rescue_zip: String = rescue.export_bundle("user://rescue.zip",{
		prefix+"case.json":JSON.stringify(rescued).to_utf8_buffer(),
		prefix+"context.json":JSON.stringify(context).to_utf8_buffer(),prefix+"screenshot.png":image.save_png_to_buffer()})
	check(not rescue_zip.is_empty(),"memory-only rescue becomes a complete incident bundle")
	print("%s: offline store" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
