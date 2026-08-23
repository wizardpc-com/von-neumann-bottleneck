extends RefCounted

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")

const LEVEL_IDS: Array[StringName] = [
	&"distant_reads", &"nearby_storage", &"cache_failure", &"access_order",
	&"working_set", &"blocking", &"capstone",
]


func register_into(registry) -> void:
	registry.register_branch(BranchType.new(&"locality", &"chapter2.branch.title", 0))
	for index: int in range(LEVEL_IDS.size()):
		var level_id: StringName = LEVEL_IDS[index]
		var dependencies: Array[StringName] = []
		if index > 0:
			dependencies.append(LEVEL_IDS[index - 1])
		registry.register_level(LevelType.new(
			level_id,
			&"locality",
			index,
			StringName("chapter2.level.%s.title" % String(level_id)),
			StringName("chapter2.level.%s.description" % String(level_id)),
			dependencies,
			LevelType.ENTRY_LOCALITY
		))
