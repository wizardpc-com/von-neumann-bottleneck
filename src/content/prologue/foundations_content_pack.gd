extends RefCounted

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")


func register_into(registry, _builders: Dictionary) -> void:
	registry.register_branch(BranchType.new(
		&"foundations", &"hardware.prologue.branch.foundations", 0
	))
	registry.register_level(LevelType.new(
		&"tutorial", &"foundations", 0,
		&"hardware.phase.tutorial", &"", [], LevelType.ENTRY_TUTORIAL
	))
