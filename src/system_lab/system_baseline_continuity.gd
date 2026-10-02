extends RefCounted
## Only the cpu_speed -> ram_wait investigation shares an identical experiment.
## Case labels may differ; data, expected output, program and machine must not.
static func matching_source(catalog: SystemLevelCatalog, receipts: Array, program: SystemProgram, topology: SystemTopology) -> SystemRunReceipt:
	if program == null or not program.is_valid() or topology == null or not topology.is_valid():
		return null
	var previous: Array = catalog.definition(&"cpu_speed").get("cases", [])
	var current: Array = catalog.definition(&"ram_wait").get("cases", [])
	if previous.is_empty() or previous.size() != current.size(): return null
	for index: int in previous.size():
		if previous[index].get("input") != current[index].get("input") or previous[index].get("expected") != current[index].get("expected"):
			return null
	for candidate: SystemRunReceipt in receipts:
		if candidate != null and candidate.all_passed and candidate.is_bound_to(
			&"cpu_speed", program.canonical_signature(), topology.canonical_signature(), catalog.test_set_signature(&"cpu_speed")
		):
			return candidate
	return null
