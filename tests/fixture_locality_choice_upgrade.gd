extends SceneTree
## Separate-process fixture for the exact 2026-10 grouping-choice transition.
const Templates = preload("res://src/simulation/program_templates.gd")
const FILE := "user://locality-choice-upgrade.json"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var locality: Node = root.get_node("LocalityChapter")
	root.get_node("GameMode").set_mode(&"game")
	if "--writer" in OS.get_cmdline_user_args():
		var snapshot: Dictionary = {
			"schema_version": 1, "completed_levels": [],
			"workspaces": {"blocking": {
				"version": locality.BEFORE_GROUP_CHOICES,
				"draft_source": "unfinished ???", "applied_source": Templates.ROW_FIRST,
				"cache_lines": 1, "passes": 2, "blocks": 1, "bypass": false,
			}},
			"observations": {"working_set": [{
				"version": locality.BEFORE_GROUP_CHOICES, "source": Templates.ROW_FIRST,
				"cache_lines": 1, "passes": 2, "blocks": 0, "bypass": false,
				"metrics": {"total_cycles": 1},
			}]},
		}
		if not _write(snapshot): return
	else:
		var snapshot: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		if not snapshot is Dictionary:
			_fail("Missing upgrade fixture"); return
		locality.restore_game(snapshot, true)
		var workspace: Dictionary = locality.workspace_for(&"blocking")
		var receipts: Array = locality.receipts_for(&"working_set")
		if workspace.get("stale", false) or workspace.get("draft_source") != "unfinished ???" or workspace.get("blocks") != 1 or workspace.get("applied_source") != Templates.ROW_FIRST:
			_fail("Original draft or selected configuration was lost"); return
		if receipts.size() != 1 or int(receipts[0].metrics.total_cycles) != 210 or not locality.game_completed.is_empty():
			_fail("Observation was not replayed or granted unearned progress"); return
		locality.retain_workspace(&"blocking", workspace)
		if locality.game_workspaces.blocking.previous_version.version != locality.BEFORE_GROUP_CHOICES:
			_fail("Original workspace was not retained"); return
		if not _write(locality.game_snapshot()): return
	print("PASS: grouping-choice upgrade ", "writer" if "--writer" in OS.get_cmdline_user_args() else "reader")
	quit(0)

func _write(value: Dictionary) -> bool:
	var file := FileAccess.open(FILE, FileAccess.WRITE)
	if file == null:
		_fail("Cannot write upgrade fixture"); return false
	file.store_string(JSON.stringify(value))
	file.flush()
	return true

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
