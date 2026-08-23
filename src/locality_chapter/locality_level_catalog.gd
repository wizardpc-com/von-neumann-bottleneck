class_name LocalityLevelCatalog
extends RefCounted

const RegistryType = preload("res://src/content/campaign_content_registry.gd")
const ManifestType = preload("res://src/content/locality/locality_content_manifest.gd")
const ProgramTemplatesType = preload("res://src/simulation/program_templates.gd")

const LEVEL_IDS: Array[StringName] = [
	&"distant_reads", &"nearby_storage", &"cache_failure", &"access_order",
	&"working_set", &"blocking", &"capstone",
]
const CAPSTONE_TARGET_CYCLES := 145

var _registry
var _levels: Dictionary[StringName, Dictionary] = {}
var _content_valid := false


func _init() -> void:
	_registry = RegistryType.new()
	ManifestType.new().register_into(_registry)
	_build_levels()
	var errors: PackedStringArray = validation_errors()
	_content_valid = errors.is_empty()
	for error: String in errors:
		push_error("Invalid Chapter 2 content: %s" % error)


func level_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if _content_valid:
		result.assign(_registry.level_ids())
	return result


func definition(level_id: StringName) -> Dictionary:
	return (_levels.get(level_id, {}) as Dictionary).duplicate(true) if _content_valid else {}


func title_key(level_id: StringName) -> StringName:
	var descriptor = _registry.level(level_id)
	return descriptor.title_key if descriptor != null else &"chapter2.level.unknown.title"


func description_key(level_id: StringName) -> StringName:
	var descriptor = _registry.level(level_id)
	return descriptor.description_key if descriptor != null else &"chapter2.level.unknown.description"


func dependencies(level_id: StringName) -> Array[StringName]:
	return _registry.dependencies(level_id)


func is_unlocked(level_id: StringName, completed: Dictionary, chapter_ready: bool, test_mode: bool = false) -> bool:
	if not _content_valid or level_id not in LEVEL_IDS:
		return false
	if test_mode:
		return true
	return chapter_ready and _registry.is_unlocked(level_id, completed)


func localization_keys() -> Array[StringName]:
	var keys: Array[StringName] = _registry.localization_keys()
	for level_id: StringName in LEVEL_IDS:
		keys.append(StringName("chapter2.level.%s.objective" % String(level_id)))
		keys.append(StringName("chapter2.level.%s.learned" % String(level_id)))
		var level: Dictionary = _levels.get(level_id, {})
		for option: Dictionary in level.get("judgment_options", []):
			keys.append(StringName(option.get("text_key", &"")))
	for concept_id: StringName in [
		&"cpu_wait", &"controlled_comparison", &"bottleneck", &"cache", &"hit",
		&"miss", &"locality", &"working_set", &"blocking",
	]:
		for field: String in ["title", "body", "diagram", "related"]:
			keys.append(StringName("chapter2.notebook.%s.%s" % [String(concept_id), field]))
	for cognitive_type: String in ["observation", "exploration", "implementation", "capstone"]:
		keys.append(StringName("chapter2.level_type.%s" % cognitive_type))
	for reason: String in ["run_required", "judgment_required", "compare_required", "baseline_required", "target_required", "complete", "unknown_level"]:
		keys.append(StringName("chapter2.progress.%s" % reason))
	keys.sort()
	return keys


func completion_status(level_id: StringName, receipts: Array, selected_judgment: StringName = &"") -> Dictionary:
	var level: Dictionary = _levels.get(level_id, {})
	if level.is_empty():
		return {"complete": false, "progress": 0, "required": 1, "reason": &"unknown_level"}
	var valid_receipts: Array = []
	for receipt: Variant in receipts:
		if receipt != null and receipt.level_id == level_id and receipt.passed:
			valid_receipts.append(receipt)
	var completion_kind := StringName(level.get("completion_kind", &"run"))
	if completion_kind == &"judgment":
		if valid_receipts.is_empty():
			return {"complete": false, "progress": 0, "required": 2, "reason": &"run_required"}
		var correct: bool = selected_judgment == StringName(level.get("correct_judgment", &""))
		return {
			"complete": correct,
			"progress": 2 if correct else 1,
			"required": 2,
			"reason": &"complete" if correct else &"judgment_required",
		}
	if completion_kind == &"cache_exploration":
		var direct_seen := false
		var reuse_seen := false
		for receipt: Variant in valid_receipts:
			direct_seen = direct_seen or receipt.bypass_cache
			reuse_seen = reuse_seen or (
				not receipt.bypass_cache
				and int(receipt.metrics.get("cache_misses", 0)) > 0
				and int(receipt.metrics.get("cache_hits", 0)) > 0
			)
		return {
			"complete": direct_seen and reuse_seen,
			"progress": int(direct_seen) + int(reuse_seen),
			"required": 2,
			"reason": &"complete" if direct_seen and reuse_seen else &"compare_required",
		}
	if completion_kind == &"performance":
		var target: int = int(level.get("target_cycles", 0))
		var baseline_seen: bool = level_id != &"capstone" or capstone_baseline_seen(valid_receipts)
		var target_seen := false
		for receipt: Variant in valid_receipts:
			if int(receipt.metrics.get("total_cycles", 0)) > target:
				continue
			if level_id == &"access_order" and receipt.traversal_pattern != "row-first":
				continue
			if level_id == &"blocking" and receipt.block_lines <= 0:
				continue
			target_seen = true
			break
		if level_id == &"capstone":
			return {
				"complete": baseline_seen and target_seen,
				"progress": int(baseline_seen) + int(target_seen),
				"required": 2,
				"reason": &"complete" if baseline_seen and target_seen else (&"baseline_required" if not baseline_seen else &"target_required"),
			}
		if target_seen:
			return {"complete": true, "progress": 1, "required": 1, "reason": &"complete"}
		return {
			"complete": false,
			"progress": 0,
			"required": 1,
			"reason": &"target_required" if not valid_receipts.is_empty() else &"run_required",
		}
	return {
		"complete": not valid_receipts.is_empty(),
		"progress": 1 if not valid_receipts.is_empty() else 0,
		"required": 1,
		"reason": &"complete" if not valid_receipts.is_empty() else &"run_required",
	}


func capstone_baseline_seen(receipts: Array) -> bool:
	for receipt: Variant in receipts:
		if (
			receipt != null
			and receipt.level_id == &"capstone"
			and receipt.passed
			and not receipt.bypass_cache
			and receipt.traversal_pattern == "column-first"
			and receipt.cache_lines == 1
			and receipt.pass_count == 2
			and receipt.block_lines == 0
		):
			return true
	return false


func validation_errors() -> PackedStringArray:
	var errors: PackedStringArray = _registry.validation_errors()
	if _registry.level_ids() != LEVEL_IDS:
		errors.append("Chapter 2 registry order must match the seven authored levels.")
	for index: int in range(LEVEL_IDS.size()):
		var level_id: StringName = LEVEL_IDS[index]
		if not _levels.has(level_id):
			errors.append("Missing Chapter 2 runtime definition %s." % level_id)
			continue
		var level: Dictionary = _levels[level_id]
		if StringName(level.get("id", &"")) != level_id or int(level.get("order", -1)) != index:
			errors.append("Chapter 2 level %s has mismatched identity or order." % level_id)
		if int(level.get("pass_count", 0)) not in [1, 2]:
			errors.append("Chapter 2 level %s has an unsupported pass count." % level_id)
		if StringName(level.get("completion_kind", &"")) == &"judgment":
			var correct := StringName(level.get("correct_judgment", &""))
			var option_ids: Array[StringName] = []
			for option: Dictionary in level.get("judgment_options", []):
				option_ids.append(StringName(option.get("id", &"")))
			if correct.is_empty() or correct not in option_ids:
				errors.append("Chapter 2 observation %s has no valid evidence judgment." % level_id)
	return errors


func _build_levels() -> void:
	_register_level(&"distant_reads", 0, ProgramTemplatesType.ROW_FIRST, false, 0, [], 1, [0], 0, true, 0,
		[&"mission", &"test_bench", &"notebook"], &"judgment", 0,
		&"repeated_ram", _judgments("distant_reads", [&"repeated_ram", &"cpu_math", &"result_store"]))
	_register_level(&"nearby_storage", 1, ProgramTemplatesType.ROW_FIRST, false, 0, [0, 1], 1, [0], 0, true, 1,
		[&"mission", &"test_bench", &"cache", &"profiler", &"notebook"], &"cache_exploration")
	_register_level(&"cache_failure", 2, ProgramTemplatesType.COLUMN_FIRST, false, 1, [1], 1, [0], 0, false, 1,
		[&"mission", &"test_bench", &"profiler", &"notebook"], &"judgment", 0,
		&"replacement", _judgments("cache_failure", [&"replacement", &"slow_cpu", &"wrong_result"]))
	_register_level(&"access_order", 3, ProgramTemplatesType.COLUMN_FIRST, true, 1, [1], 1, [0], 0, false, 1,
		[&"mission", &"program", &"test_bench", &"profiler", &"notebook"], &"performance", 105)
	_register_level(&"working_set", 4, ProgramTemplatesType.ROW_FIRST, false, 1, [1], 2, [0], 0, false, 2,
		[&"mission", &"test_bench", &"profiler", &"notebook"], &"judgment", 0,
		&"does_not_fit", _judgments("working_set", [&"does_not_fit", &"bad_order", &"more_math"]))
	_register_level(&"blocking", 5, ProgramTemplatesType.ROW_FIRST, false, 1, [1], 2, [0, 1], 0, false, 2,
		[&"mission", &"test_bench", &"blocking", &"profiler", &"notebook"], &"performance", CAPSTONE_TARGET_CYCLES)
	_register_level(&"capstone", 6, ProgramTemplatesType.COLUMN_FIRST, true, 1, [1, 2, 4], 2, [0, 1, 2, 4], 0, false, 2,
		[&"mission", &"program", &"test_bench", &"cache", &"blocking", &"profiler", &"notebook"],
		&"performance", CAPSTONE_TARGET_CYCLES)


func _register_level(
		id: StringName,
		order: int,
		program_source: String,
		program_editable: bool,
		default_cache_lines: int,
		cache_choices: Array[int],
		pass_count: int,
		block_choices: Array[int],
		default_block_lines: int,
		bypass_cache: bool,
		profiler_tier: int,
		tools: Array[StringName],
		completion_kind: StringName,
		target_cycles: int = 0,
		correct_judgment: StringName = &"",
		judgment_options: Array[Dictionary] = []
	) -> void:
	_levels[id] = {
		"id": id,
		"order": order,
		"title_key": title_key(id),
		"description_key": description_key(id),
		"objective_key": StringName("chapter2.level.%s.objective" % String(id)),
		"dependencies": dependencies(id),
		"program_source": program_source,
		"program_editable": program_editable,
		"default_cache_lines": default_cache_lines,
		"cache_choices": cache_choices.duplicate(),
		"pass_count": pass_count,
		"block_choices": block_choices.duplicate(),
		"default_block_lines": default_block_lines,
		"bypass_cache": bypass_cache,
		"profiler_tier": profiler_tier,
		"tools": tools.duplicate(),
		"completion_kind": completion_kind,
		"target_cycles": target_cycles,
		"correct_judgment": correct_judgment,
		"judgment_options": judgment_options.duplicate(true),
	}


func _judgments(level_id: String, ids: Array[StringName]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: StringName in ids:
		result.append({
			"id": id,
			"text_key": StringName("chapter2.level.%s.judgment.%s" % [level_id, String(id)]),
		})
	return result
