class_name LayoutRun
extends SimulationTrace
var output_values: Array[int] = []
var expected_values: Array[int] = []
var source_map: Dictionary = {}
var scratch_maps: Array[Dictionary] = []
var recipe_signature: String = ""
var case_signature: String = ""
var model_version: String = ""

func canonical_signature() -> String:
	return JSON.stringify({"trace":super.canonical_signature(),"outputs":output_values,"expected":expected_values,
		"recipe":recipe_signature,"case":case_signature,"model":model_version})
