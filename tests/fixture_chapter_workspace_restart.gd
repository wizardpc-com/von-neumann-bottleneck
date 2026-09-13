extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	var save: Node=root.get_node("GlobalSave")
	var system: Node=root.get_node("SystemChapter")
	var locality: Node=root.get_node("LocalityChapter")
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://workspace-restart.json","user://synthetic-workbenches.json")
	var writer: bool="--writer" in OS.get_cmdline_user_args()
	if writer:
		system.retain_workspace(&"read_once",{"draft_source":"INVALID unfinished system", "applied_source":"HALT", "part_ids":{},"connections":[],"positions":{"CPU":Vector2(333,222)}})
		locality.retain_workspace(&"capstone",{"draft_source":"INVALID unfinished locality", "applied_source":"acc = 0", "cache_lines":2,"passes":2,"blocks":0,"bypass":false})
	else:
		save.load_game() # Return value describes qualified Continue progress, not read success.
		if not save.loaded_save or not save.last_error.is_empty(): push_error("Restart read failed: "+save.last_error);quit(1);return
		var a: Dictionary=system.workspace_for(&"read_once")
		var b: Dictionary=locality.workspace_for(&"capstone")
		if a.get("draft_source")!="INVALID unfinished system" or a.get("applied_source")!="HALT" or a.get("connections",[1])!=[] or b.get("draft_source")!="INVALID unfinished locality" or b.get("cache_lines")!=2:
			push_error("Unfinished workspace changed on process restart");quit(1);return
		if not system.game_completed.is_empty() or not locality.game_completed.is_empty():
			push_error("Draft restoration granted completion");quit(1);return
	if not save.save_game(true):push_error("Write failed");quit(1);return
	print("PASS: process workspace "+("writer" if writer else "reader"));quit(0)
