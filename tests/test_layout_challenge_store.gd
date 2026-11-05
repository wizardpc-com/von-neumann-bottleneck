extends SceneTree
const Store = preload("res://src/layout_chapter/layout_challenge_store.gd")
const Code = preload("res://src/layout_chapter/layout_challenge_code.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
class BlockedReplace:
	extends "res://src/layout_chapter/layout_challenge_store.gd"
	var blocked_destination: String = ""
	func _replace_file(temporary: String, target: String) -> Error:
		# Exercise a real OS rename failure; only destination routing is injected.
		return DirAccess.rename_absolute(temporary,blocked_destination if not blocked_destination.is_empty() else target)
var failures: Array[String] = []
var checks: int = 0
var codes: Dictionary = {}
var directory: String = "user://layout-challenge-store-tests"

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func path(name: String) -> String: return directory+"/"+name+".json"
func store_for(name: String) -> RefCounted:
	var store: RefCounted = Store.new()
	store.storage_path = path(name)
	return store
func write(file_path: String, text: String) -> void:
	var file := FileAccess.open(file_path,FileAccess.WRITE)
	file.store_string(text); file.flush(); file.close()
func snapshot(targets: Dictionary) -> String:
	return JSON.stringify({"schema_version":1,"targets":targets},"",true)
func envelope_code(value: Dictionary) -> String:
	return Code.PREFIX+JSON.stringify(value,"",true)
func entry(task: String, title: String = "Target") -> Dictionary:
	return {"code":codes[task],"title":title}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	for task: String in Catalog.IDS:
		var encoded: Dictionary = Code.encode(task,Catalog.reference_solution(task),"cycles")
		check(encoded.ok,"Real eligible "+task+" supplies the persistence fixture.")
		codes[task] = encoded.code
	var store: RefCounted = store_for("basic")
	check(store.read_target("mixed",&"test").entry.is_empty() and not store._game_loaded,"Test read never loads Game data.")
	check(store.pin("mixed",&"test",codes.mixed,"Test target").ok,"Test pin accepts a freshly measured eligible target.")
	check(not FileAccess.file_exists(store.storage_path) and not store._game_loaded,"Test pin remains entirely in memory.")
	check(store.read_target("mixed",&"game").entry.is_empty(),"Game target is independent of Test.")
	for task: String in Catalog.IDS:
		check(store.pin(task,&"game",codes[task],"Saved "+task).ok,"Game "+task+" pin persists.")
	check(store._game_targets.size() == 6,"All six known tasks fit the bounded store.")
	var original: String = FileAccess.get_file_as_string(store.storage_path)
	check(original.to_utf8_buffer().size() <= Store.MAX_BYTES,"Complete six-task snapshot stays below the file bound.")
	check(store.read_target("mixed",&"test").entry.title == "Test target","Game writes never replace the separate Test target.")
	var restarted: RefCounted = store_for("basic")
	for task: String in Catalog.IDS:
		var read: Dictionary = restarted.read_target(task,&"game")
		check(read.status == "ready" and read.entry.code == codes[task],"Fresh store restores exact "+task+" recipe code.")
		check(Code.inspect(read.entry.code,task).ok,"Restored "+task+" target replays with the current model.")
	check(restarted.read_target("mixed",&"test").entry.is_empty(),"Process-style restart carries no transient Test target.")
	var detached: Dictionary = restarted.read_target("mixed",&"game")
	detached.entry.title = "Mutated caller copy"
	check(restarted.read_target("mixed",&"game").entry.title == "Saved mixed","Reads expose detached data.")
	var result: Dictionary = restarted.pin("mixed",&"game",codes.mixed,"Saved mixed")
	result.entry.title = "Mutated return"
	check(restarted.read_target("mixed",&"game").entry.title == "Saved mixed","Pin results also expose detached data.")
	check(FileAccess.get_file_as_string(store.storage_path) == original,"Duplicate pin is idempotent and retains exact original bytes.")
	for invalid_title: Variant in ["x".repeat(41),"line\nbreak","tab\tname",String.chr(127),String.chr(133)]:
		check(not restarted.pin("mixed",&"game",codes.mixed,invalid_title).ok,"Oversized or controlled title is rejected.")
	check(not restarted.pin("mixed",&"game",codes.fields,"Wrong task").ok,"Outer task cannot disagree with code task.")
	check(not restarted.pin("mixed",&"unknown",codes.mixed,"Unknown mode").ok and not restarted.clear("mixed",&"unknown").ok,"Unknown mode cannot select Game implicitly.")
	check(not restarted.pin("unknown",&"game",codes.mixed,"Unknown task").ok and not restarted.clear("unknown",&"game").ok,"Unknown task cannot be stored or cleared.")
	check(FileAccess.get_file_as_string(store.storage_path) == original,"All rejected actions leave persisted targets byte-identical.")
	check(restarted.clear("mixed",&"test").ok and restarted.read_target("mixed",&"game").entry.code == codes.mixed,"Clearing Test never removes Game.")
	check(restarted.clear("mixed",&"game").ok and restarted.read_target("mixed",&"game").entry.is_empty(),"Explicit Game clear removes only the chosen target.")
	check(restarted.read_target("fields",&"game").entry.code == codes.fields,"Clearing one target preserves other tasks.")
	var cleared: String = FileAccess.get_file_as_string(store.storage_path)
	check(restarted.clear("mixed",&"game").ok and FileAccess.get_file_as_string(store.storage_path) == cleared,"Duplicate clear is idempotent.")
	var stale_envelope: Dictionary = Code.decode(codes.mixed).challenge
	stale_envelope.model = "older-layout-model"
	var stale_code: String = envelope_code(stale_envelope)
	var stale_raw: String = snapshot({"mixed":{"code":stale_code,"title":"Old model"}})
	write(path("stale"),stale_raw)
	var stale_store: RefCounted = store_for("stale")
	var stale_read: Dictionary = stale_store.read_target("mixed",&"game")
	check(stale_read.status == "ready" and stale_read.entry.code == stale_code,"Supported old identity is retained exactly instead of discarded.")
	check(Code.inspect(stale_read.entry.code).reason == "model","Old recipe has no current comparison authority.")
	check(stale_store.pin("fields",&"game",codes.fields,"Current field target").ok,"Another current target can be saved alongside supported stale data.")
	check(JSON.parse_string(FileAccess.get_file_as_string(stale_store.storage_path)).targets.mixed.code == stale_code,"Saving another target preserves the old code without relabeling it.")
	var malformed: Array[Dictionary] = [
		{"name":"future","text":JSON.stringify({"schema_version":2,"targets":{},"valuable":"future"},"",true)},
		{"name":"corrupt","text":"{valuable unfinished"},
		{"name":"extra-root","text":JSON.stringify({"schema_version":1,"targets":{},"unknown":{}},"",true)},
		{"name":"wrong-container","text":JSON.stringify({"schema_version":1,"targets":[]},"",true)},
		{"name":"wrong-entry","text":snapshot({"mixed":17})},
		{"name":"nested-extra","text":snapshot({"mixed":{"code":codes.mixed,"title":"Keep","future":42}})},
		{"name":"missing-title","text":snapshot({"mixed":{"code":codes.mixed}})},
		{"name":"wrong-code-type","text":snapshot({"mixed":{"code":42,"title":"Keep"}})},
		{"name":"task-mismatch","text":snapshot({"mixed":entry("fields")})},
		{"name":"unknown-task","text":snapshot({"future_task":entry("mixed")})},
		{"name":"control-title","text":snapshot({"mixed":entry("mixed","Keep\noriginal")})},
		{"name":"oversize-title","text":snapshot({"mixed":entry("mixed","x".repeat(41))})},
		{"name":"future-code","text":snapshot({"mixed":{"code":"VNB4C2:{}","title":"Future"}})},
		{"name":"oversize-code","text":snapshot({"mixed":{"code":"x".repeat(Code.MAX_BYTES+1),"title":"Keep"}})},
		{"name":"oversize-file","text":"x".repeat(Store.MAX_BYTES+1)},
	]
	var seven: Dictionary = {}
	for task: String in Catalog.IDS: seven[task] = entry(task)
	seven["future_task"] = entry("mixed")
	malformed.append({"name":"oversize-count","text":snapshot(seven)})
	var with_score: Dictionary = Code.decode(codes.mixed).challenge
	with_score["cycles"] = 1
	malformed.append({"name":"claimed-score","text":snapshot({"mixed":{"code":envelope_code(with_score),"title":"Fabricated"}})})
	var inner_bad: Dictionary = Code.decode(codes.mixed).challenge
	inner_bad.design.recipe.groups[0]["future_field"] = true
	malformed.append({"name":"nested-code-corrupt","text":snapshot({"mixed":{"code":envelope_code(inner_bad),"title":"Keep"}})})
	var duplicate_key: String = snapshot({"mixed":entry("mixed")}).replace('"schema_version":1','"schema_version":1,"schema_version":1')
	malformed.append({"name":"duplicate-key","text":duplicate_key})
	for fixture: Dictionary in malformed:
		write(path(fixture.name),fixture.text)
		var guarded: RefCounted = store_for(fixture.name)
		check(guarded.read_target("mixed",&"game").status == "read_only","Full "+fixture.name+" history becomes read-only.")
		check(not guarded.pin("fields",&"game",codes.fields,"New valid target").ok and not guarded.clear("mixed",&"game").ok,"Corrupt "+fixture.name+" history blocks both write paths.")
		check(FileAccess.get_file_as_string(guarded.storage_path) == fixture.text,"Corrupt "+fixture.name+" original bytes survive later valid actions.")
		check(guarded.pin("mixed",&"test",codes.mixed,"Independent Test").ok,"Read-only Game "+fixture.name+" does not prevent Test exploration.")
		check(FileAccess.get_file_as_string(guarded.storage_path) == fixture.text,"Test cannot repair or overwrite "+fixture.name+" Game history.")
	var externally_changed: RefCounted = store_for("external-change")
	check(externally_changed.pin("mixed",&"game",codes.mixed,"Original").ok,"External-change fixture starts with a real saved recipe.")
	var replacement: String = snapshot({"fields":entry("fields","Written elsewhere")})
	write(externally_changed.storage_path,replacement)
	check(not externally_changed.pin("records",&"game",codes.records,"Do not overwrite").ok and externally_changed.storage_status == "read_only","An unseen external writer is detected before pin replacement.")
	check(FileAccess.get_file_as_string(externally_changed.storage_path) == replacement,"External new bytes are preserved.")
	var appeared: RefCounted = store_for("appeared")
	appeared.read_target("mixed",&"game")
	write(appeared.storage_path,replacement)
	check(not appeared.clear("mixed",&"game").ok and FileAccess.get_file_as_string(appeared.storage_path) == replacement,"An externally created file is protected even during an otherwise empty clear.")
	var disappeared: RefCounted = store_for("disappeared")
	disappeared.pin("mixed",&"game",codes.mixed,"Original")
	DirAccess.remove_absolute(disappeared.storage_path)
	check(not disappeared.pin("fields",&"game",codes.fields,"New").ok and not FileAccess.file_exists(disappeared.storage_path),"An externally deleted file is not silently recreated from stale memory.")
	verify_write_retry()
	verify_replace_retry()
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	before.erase("saved_at_utc"); after.erase("saved_at_utc")
	check(before == after,"Challenge persistence never writes GlobalSave or awards progression.")
	print(("PASS" if failures.is_empty() else "FAIL"),": layout challenge store ",checks," checks")
	quit(0 if failures.is_empty() else 1)

func verify_write_retry() -> void:
	var store: RefCounted = store_for("write-retry")
	check(store.pin("mixed",&"game",codes.mixed,"Original").ok,"Write-failure fixture starts with a valid target.")
	var original: String = FileAccess.get_file_as_string(store.storage_path)
	DirAccess.make_dir_recursive_absolute(store.storage_path+".tmp")
	var failed: Dictionary = store.pin("mixed",&"game",codes.mixed,"Requested new title")
	check(not failed.ok and failed.status == "write_failed" and failed.reason == "write","Actual temp-open failure is reported.")
	check(FileAccess.get_file_as_string(store.storage_path) == original and store.read_target("mixed",&"game").entry.title == "Original","Failed pin preserves disk and committed memory.")
	DirAccess.remove_absolute(store.storage_path+".tmp")
	check(store.pin("mixed",&"game",codes.mixed,"Requested new title").ok,"Identical pin retries successfully after temp-open failure.")
	DirAccess.make_dir_recursive_absolute(store.storage_path+".tmp")
	check(not store.clear("mixed",&"game").ok and store.read_target("mixed",&"game").entry.title == "Requested new title","Failed clear preserves the current target.")
	DirAccess.remove_absolute(store.storage_path+".tmp")
	check(store.clear("mixed",&"game").ok and store.read_target("mixed",&"game").entry.is_empty(),"Identical clear retries after temp-open failure.")

func verify_replace_retry() -> void:
	var store := BlockedReplace.new()
	store.storage_path = path("replace-retry")
	check(store.pin("mixed",&"game",codes.mixed,"Original").ok,"Replace-failure fixture starts with a valid target.")
	var original: String = FileAccess.get_file_as_string(store.storage_path)
	var blocked: String = directory+"/blocked-rename"
	DirAccess.make_dir_recursive_absolute(blocked)
	write(blocked+"/preserved.txt","keep directory bytes")
	store.blocked_destination = ProjectSettings.globalize_path(blocked)
	var failed: Dictionary = store.pin("mixed",&"game",codes.mixed,"Replacement")
	check(not failed.ok and failed.status == "write_failed" and failed.reason == "replace","Actual rename-to-directory failure is reported.")
	check(FileAccess.get_file_as_string(store.storage_path) == original and FileAccess.get_file_as_string(blocked+"/preserved.txt") == "keep directory bytes","Failed atomic replace preserves both original and blocked destination.")
	check(store.read_target("mixed",&"game").entry.title == "Original","Failed replace does not commit in-memory target.")
	store.blocked_destination = ""
	check(store.pin("mixed",&"game",codes.mixed,"Replacement").ok,"Identical pin retries a real replace failure.")
	store.blocked_destination = ProjectSettings.globalize_path(blocked)
	check(not store.clear("mixed",&"game").ok and store.read_target("mixed",&"game").entry.title == "Replacement","Failed replacement during clear preserves memory.")
	store.blocked_destination = ""
	check(store.clear("mixed",&"game").ok,"Identical clear retries a real replace failure.")
