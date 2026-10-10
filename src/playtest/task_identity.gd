extends RefCounted
## Authored content identity only. Never inspect player recipes or training text.
const LEGACY_VERSION: String = "tasks-20260910-v1"
const JOURNEY_VERSION: String = "tasks-20261010-journey-v1"
const CATEGORIES := ["confusion","control","bug","audiovisual","discovery","other"]
const SecondAct = preload("res://src/campaign/second_act_tasks.gd")
const Creation = preload("res://src/campaign/creation_tasks.gd")
static var contracts: Dictionary = {}

static func content_version() -> String:
	return JOURNEY_VERSION if SecondAct.enabled() or Creation.enabled() else LEGACY_VERSION

static func metadata(chapter: String, level: String) -> Dictionary:
	var result: Dictionary = {
		"chapter_id":chapter,"level_id":level,"task_version":content_version(),
		"build_version":str(ProjectSettings.get_setting("application/config/version","development")),
		"source_commit":str(ProjectSettings.get_setting("application/config/build_commit","unknown")),
		"test_batch":str(ProjectSettings.get_setting("application/test_batch","unspecified")),
		"model_version":"unspecified","case_set_version":"unspecified"}
	if chapter not in ["representation","service","prediction","creation"]: return result
	result.task_version=JOURNEY_VERSION
	if not contracts.has(chapter):
		match chapter:
			"representation": contracts[chapter]=preload("res://experiments/representation_region/session_store.gd").contract_id()
			"service": contracts[chapter]=preload("res://experiments/service_plan/session_store.gd").contract_id()
			"prediction":
				var specs: Array = []
				for index: int in 3: specs.append(preload("res://experiments/prediction/catalog.gd").scenario(index))
				contracts[chapter]=JSON.stringify(specs).sha256_text()
			"creation":
				# Versioned authored contract; this is not a digest of the player's model.
				var catalog: Script = preload("res://experiments/creation/catalog.gd")
				contracts[chapter]=JSON.stringify([catalog.IDS,catalog.GOALS_EN,"check-v2","design-v1"]).sha256_text()
	result.model_version={"representation":"representation-region-v1","service":"service-plan-v1","prediction":"prediction-address-v1","creation":"creation-continuous-v1"}[chapter]
	result.case_set_version=contracts[chapter]
	return result
