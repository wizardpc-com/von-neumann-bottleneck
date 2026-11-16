extends RefCounted
## Shared release identity, also embedded in voluntarily exported diagnostics.

static func snapshot() -> Dictionary:
	return {
		"edition": str(ProjectSettings.get_setting("game/edition", "development")),
		"version": str(ProjectSettings.get_setting("application/config/version", "development")),
		"source_commit": str(ProjectSettings.get_setting("application/config/build_commit", "development")),
		"build_id": str(ProjectSettings.get_setting("application/config/build_id", "development")),
		"batch": str(ProjectSettings.get_setting("application/test_batch", "development")),
		"content": preload("res://src/playtest/task_identity.gd").content_version(),
		"profile": str(ProjectSettings.get_setting("candidate/profile", "source")),
	}


static func caption() -> String:
	var identity: Dictionary = snapshot()
	var edition: String = str(identity.edition).capitalize()
	return "%s Edition · %s" % [edition, identity.version] if edition != "Development" else "Development"


static func description() -> String:
	var identity: Dictionary = snapshot()
	return "%s\nCommit: %s\nBuild: %s\nBatch: %s\nContent: %s · Profile: %s" % [caption(), identity.source_commit, identity.build_id, identity.batch, identity.content, identity.profile]
