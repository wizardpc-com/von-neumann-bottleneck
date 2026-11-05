extends SceneTree
const Code = preload("res://src/layout_chapter/layout_challenge_code.gd")
const Store = preload("res://src/layout_chapter/layout_challenge_store.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/20261104-round3/process-"):
		push_error("Fresh isolated process profile required.")
		quit(1)
		return
	var store = Store.new()
	var expected: Dictionary = Code.encode("fields",Catalog.reference_solution("fields"),"traffic")
	var state: Node = root.get_node("LayoutChapter")
	var before: Dictionary = state.game_snapshot()
	var seeded: bool = "--seed" in OS.get_cmdline_user_args()
	var ok: bool = expected.ok
	if seeded:
		ok = ok and store.read_target("fields",&"game").entry.is_empty()
		ok = ok and store.pin("fields",&"game",expected.code,"Across process").ok
		ok = ok and store.pin("fields",&"test",expected.code,"Temporary").ok
	else:
		var stored: Dictionary = store.read_target("fields",&"game")
		ok = ok and stored.entry.get("code","") == expected.code
		var replayed: Dictionary = Code.inspect(str(stored.entry.get("code","")),"fields")
		ok = ok and replayed.get("ok",false)
		if replayed.get("ok",false):
			ok = ok and replayed.row.cycles == 122 and replayed.row.traffic == 80 and replayed.row.peak == 0
			print("REPLAY: "+JSON.stringify({"cycles":replayed.row.cycles,"traffic":replayed.row.traffic,"peak":replayed.row.peak,"recipe_id":replayed.row.recipe_id}))
		ok = ok and store.read_target("fields",&"test").entry.is_empty()
	ok = ok and state.game_snapshot() == before and state.game_solutions.is_empty()
	print(("PASS: " if ok else "FAIL: ")+("process seed" if seeded else "new process replay and Test isolation"))
	quit(0 if ok else 1)
