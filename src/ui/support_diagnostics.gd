extends RefCounted
## Explicit local export. No player designs, notes, paths, IDs, tokens or raw logs.
static func snapshot() -> Dictionary:
	return {"format":1,"build_id":ProjectSettings.get_setting("application/config/version",""),
		"source_commit":ProjectSettings.get_setting("application/config/build_commit","development"),
		"engine":Engine.get_version_info().string,"platform":OS.get_name(),
		"locale":Localization.current_locale(),"frame_limit":WindowMode.frame_limit,
		"sound_enabled":WindowMode.sound_enabled,"sound_volume":WindowMode.sound_volume,
		"reduced_motion":ProjectSettings.get_setting("game/reduced_motion",false),
		"viewport":str(WindowMode.get_viewport().get_visible_rect().size),
		"remote_configured":RemoteFeedback.endpoint_allowed(),"sharing_mode":RemoteFeedback.sharing_mode,
		"pending_uploads":RemoteFeedback.queue.size()}

static func export_local() -> String:
	var folder: String = "user://diagnostics"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))!=OK: return ""
	var path: String = folder.path_join("diagnostics-%d.json" % Time.get_unix_time_from_system())
	var base_path: String = path.trim_suffix(".json")
	var suffix: int = 1
	while FileAccess.file_exists(path):
		path="%s-%d.json" % [base_path,suffix]
		suffix+=1
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return ""
	file.store_string(JSON.stringify(snapshot(),"\t")); file.flush()
	var error: Error = file.get_error()
	file.close()
	if error!=OK: return ""
	return ProjectSettings.globalize_path(path)
