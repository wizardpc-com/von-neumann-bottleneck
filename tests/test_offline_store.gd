extends SceneTree
const Store = preload("res://src/playtest/offline_store.gd")

class BlockedPngStore:
	extends "res://src/playtest/offline_store.gd"
	func _reserve_case_folder(id: String) -> String:
		var folder: String = super._reserve_case_folder(id)
		if not folder.is_empty(): DirAccess.make_dir_absolute(_absolute(folder.path_join("screenshot.png")))
		return folder

class FailedMetadataVerificationStore:
	extends "res://src/playtest/offline_store.gd"
	func _write_new_json(path: String, data: Dictionary) -> bool:
		var written: bool = super._write_new_json(path,data)
		if written and path.get_file()=="case.json":
			last_error="Fixture: completed metadata failed its subsequent verification."
			return false
		return written

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
	publication_checks(context,image)
	print("%s: offline store" % ("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)

func publication_checks(context: Dictionary, image: Image) -> void:
	var store = Store.new(); store.root="user://publication-contract"
	var first: Dictionary = store.create_case(context,image)
	var second_context: Dictionary = context.duplicate(true); second_context["second_capture"]=true
	var second: Dictionary = store.create_case(second_context,image)
	check(not first.is_empty() and not second.is_empty(),"two consecutive incidents publish without moving a populated directory")
	if first.is_empty() or second.is_empty(): return
	check(first.id!=second.id and store.cases().size()==2,"consecutive captures retain independent identities")
	var first_folder: String = store.root.path_join("cases").path_join(first.id)
	var first_hashes: Dictionary = folder_hashes(first_folder)
	check(store._reserve_case_folder(first.id).is_empty() and not store.last_error.is_empty(),"existing case directory is not reserved again")
	check(folder_hashes(first_folder)==first_hashes,"case identity collision preserves all original bytes")
	var file_collision = Store.new(); file_collision.root="user://case-file-conflict"
	check(file_collision._mkdir(file_collision.root.path_join("cases")),"case file conflict parent exists")
	var file_id: String = Store.new_id()
	var file_path: String = file_collision.root.path_join("cases").path_join(file_id)
	write_text(file_path,"occupied case path")
	check(file_collision._reserve_case_folder(file_id).is_empty() and FileAccess.get_file_as_string(file_path)=="occupied case path","case path occupied by a file is preserved")
	var pending_id: String = Store.new_id()
	var pending_folder: String = store.root.path_join("pending").path_join(pending_id)
	check(store._mkdir(pending_folder),"old pending fixture directory is created")
	var pending_metadata: Dictionary = first.duplicate(true); pending_metadata.id=pending_id
	check(store._write_new_json(pending_folder.path_join("context.json"),context) and store._write_new_json(pending_folder.path_join("case.json"),pending_metadata),"old pending fixture contains complete evidence")
	var pending_hashes: Dictionary = folder_hashes(pending_folder)
	check(store._reserve_case_folder(pending_id).is_empty(),"complete old pending identity is never promoted or reused")
	check(not DirAccess.dir_exists_absolute(Store._absolute(store.root.path_join("cases").path_join(pending_id))) and folder_hashes(pending_folder)==pending_hashes,"pending conflict creates no new case and preserves every old byte")
	var pending_file_id: String = Store.new_id()
	var pending_file: String = store.root.path_join("pending").path_join(pending_file_id)
	write_text(pending_file,"old pending file")
	check(store._reserve_case_folder(pending_file_id).is_empty() and FileAccess.get_file_as_string(pending_file)=="old pending file","pending file identity collision is also preserved")
	var partial_ids: Array[String] = []
	var partial_hashes: Dictionary = {}
	for kind: String in ["context_only","partial_metadata","invalid_metadata"]:
		var id: String = Store.new_id(); partial_ids.append(id)
		var folder: String = store._reserve_case_folder(id)
		check(not folder.is_empty() and store._write_new_json(folder.path_join("context.json"),context),"unfinished capture retains its context: "+kind)
		if kind=="partial_metadata": write_text(folder.path_join("case.json"),'{"id":')
		elif kind=="invalid_metadata": write_text(folder.path_join("case.json"),JSON.stringify({"id":id,"note":""}))
		partial_hashes[id]=folder_hashes(folder)
		check(store.read_case(id).is_empty() and not store._latest.has(id),"unfinished metadata never enters readable history or cache: "+kind)
	check(store.cases().size()==2,"history exposes only the two complete captures")
	var archive_path: String = store.export_bundle()
	check(not archive_path.is_empty(),"complete and interrupted captures export together")
	if not archive_path.is_empty():
		var reader := ZIPReader.new(); check(reader.open(archive_path)==OK,"publication recovery ZIP opens")
		var manifest: Dictionary = JSON.parse_string(reader.read_file("manifest.json").get_string_from_utf8())
		check(int(manifest.case_count)==2,"recovery evidence is not counted as a completed incident")
		for id: String in partial_ids:
			for name: String in partial_hashes[id]:
				var path: String = "recovery/cases/"+id+"/"+name
				check(reader.file_exists(path) and Store._hash(reader.read_file(path))==partial_hashes[id][name],"partial capture bytes remain recoverable: "+path)
		for name: String in pending_hashes:
			var path: String = "recovery/"+pending_id+"/"+name
			check(reader.file_exists(path) and Store._hash(reader.read_file(path))==pending_hashes[name],"old pending is exported only as unchanged recovery")
		reader.close()
	check(folder_hashes(first_folder)==first_hashes and folder_hashes(pending_folder)==pending_hashes,"export consumes neither complete nor old pending evidence")
	var failed = BlockedPngStore.new(); failed.root="user://blocked-png-contract"
	# This fixture deliberately directs the native PNG writer at a directory.
	var printed_errors: bool = Engine.print_error_messages
	Engine.print_error_messages=false
	var no_png: Dictionary = failed.create_case(context,image)
	Engine.print_error_messages=printed_errors
	check(not no_png.is_empty(),"PNG write failure retains an incident with usable context")
	if not no_png.is_empty():
		check(no_png.screenshot_status=="failed" and not str(no_png.screenshot_error).is_empty(),"failed PNG is never reported as captured")
		check(not FileAccess.file_exists(failed.root.path_join("cases").path_join(no_png.id).path_join("screenshot.png")),"failed screenshot has no invalid PNG file in a normal incident")
		check(not failed.export_bundle().is_empty(),"a truthful screenshot-failed incident remains exportable")
	var verification = FailedMetadataVerificationStore.new(); verification.root="user://metadata-verification-contract"
	check(verification.create_case(context,image).is_empty() and verification._latest.is_empty(),"post-write verification failure does not install an active cached incident")
	var recoverable: Array[Dictionary] = verification.cases()
	check(recoverable.size()==1 and not verification.read_case(str(recoverable[0].id)).is_empty(),"completed valid metadata remains recoverable after a failed later verification; atomic visibility is not promised")

func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file!=null,"fixture opens its own file")
	if file!=null: file.store_string(text); file.close()

func folder_hashes(folder: String) -> Dictionary:
	var result: Dictionary = {}
	for name: String in DirAccess.get_files_at(folder): result[name]=FileAccess.get_sha256(folder.path_join(name))
	return result
