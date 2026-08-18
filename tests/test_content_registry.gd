extends SceneTree

const BranchType = preload("res://src/content/campaign_branch_definition.gd")
const LevelType = preload("res://src/content/campaign_level_definition.gd")
const RegistryType = preload("res://src/content/campaign_content_registry.gd")
const PlayerContentStateType = preload("res://src/content/player_content_state.gd")
const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")
const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const PrologueLevelCatalogType = preload("res://src/hardware_foundations/prologue_level_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_real_prologue_catalog()
	_test_synthetic_content_extension()
	_test_invalid_content_is_rejected()
	_test_player_content_state()
	if failures.is_empty():
		print("PASS: deterministic campaign registry, synthetic content extension, and validation tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d content-registry assertion(s) failed" % failures.size())
		quit(1)


func _test_real_prologue_catalog() -> void:
	var catalog = PrologueLevelCatalogType.new()
	_assert(catalog.validation_errors().is_empty(), "Built-in prologue content must pass registry validation.")
	_assert(
		catalog.branch_ids() == [&"foundations", &"arithmetic", &"storage", &"integration"],
		"Campaign branches must retain deterministic authored order."
	)
	_assert(
		catalog.level_ids() == [
			&"tutorial", &"half_adder", &"full_adder", &"alu",
			&"latch", &"register", &"ram", &"cpu", &"load_store",
		],
		"Registry migration must preserve the complete current progression order."
	)
	_assert(catalog.entry_kind(&"tutorial") == LevelType.ENTRY_TUTORIAL, "Tutorial entry routing must be content metadata.")
	_assert(catalog.entry_kind(&"half_adder") == LevelType.ENTRY_HALF_ADDER, "Half Adder entry routing must be content metadata.")
	_assert(catalog.entry_kind(&"full_adder") == LevelType.ENTRY_CIRCUIT, "Ordinary construction challenges must use the circuit entry contract.")
	_assert(catalog.reward_names(&"alu") == [&"ALU1", &"ALU4"], "ALU reward ownership must include its generated word wrapper.")
	_assert(catalog.reward_names(&"register") == [&"Register1", &"Register4"], "Register reward ownership must include its generated word wrapper.")
	_assert(
		catalog.dependent_level_ids(&"half_adder") == [
			&"full_adder", &"alu", &"latch", &"register", &"ram", &"cpu", &"load_store",
		],
		"Dependency invalidation must traverse every registered downstream branch deterministically."
	)
	_assert(
		&"hardware.prologue.branch.storage" in catalog.localization_keys()
		and &"hardware.prologue.ram.description" in catalog.localization_keys(),
		"Registry must expose all content-owned localization keys for catalog validation."
	)


func _test_synthetic_content_extension() -> void:
	var registry = RegistryType.new()
	_assert(registry.register_branch(BranchType.new(&"sandbox", &"test.branch.sandbox", 7)), "A new branch must register through the public content contract.")
	_assert(registry.register_level(LevelType.new(
		&"signal_basics", &"sandbox", 0, &"test.level.signal.title", &"",
		[], LevelType.ENTRY_TUTORIAL, Callable(), [&"SignalToken"]
	)), "A special-flow root level must register without an executable circuit builder.")
	_assert(registry.register_level(LevelType.new(
		&"synthetic_gate", &"sandbox", 1,
		&"test.level.synthetic.title", &"test.level.synthetic.description",
		[&"signal_basics"], LevelType.ENTRY_CIRCUIT,
		Callable(self, "_build_synthetic_level"), [&"SyntheticGate"]
	)), "A content-defined circuit challenge must register without campaign-UI changes.")

	_assert(registry.validation_errors().is_empty(), "A well-formed synthetic content pack must validate cleanly.")
	_assert(registry.branch_ids() == [&"sandbox"], "Synthetic branch ordering must be queryable by the generic map.")
	_assert(registry.level_ids_for_branch(&"sandbox") == [&"signal_basics", &"synthetic_gate"], "Synthetic level order must be queryable by the generic map.")
	_assert(not registry.is_unlocked(&"synthetic_gate", {}), "Registered prerequisites must keep synthetic content locked.")
	_assert(registry.is_unlocked(&"synthetic_gate", {&"signal_basics": true}), "Completing a registered prerequisite must unlock synthetic content.")
	var definition: Dictionary = registry.level(&"synthetic_gate").instantiate({&"marker": 41})
	_assert(definition.get("id") == &"synthetic_gate", "Descriptor identity must override accidental builder identity drift.")
	_assert(definition.get("title_key") == &"test.level.synthetic.title", "Descriptor localization metadata must reach runtime content.")
	_assert(int(definition.get("library_marker", 0)) == 42, "Level builders must receive the current player component library.")
	_assert(registry.reward_names(&"synthetic_gate") == [&"SyntheticGate"], "Synthetic reward ownership must be queryable for invalidation.")
	_assert(registry.dependent_level_ids(&"signal_basics") == [&"synthetic_gate"], "Synthetic transitive invalidation must require no level-specific UI code.")


func _test_invalid_content_is_rejected() -> void:
	var duplicate_registry = RegistryType.new()
	duplicate_registry.register_branch(BranchType.new(&"same", &"test.branch.same", 0))
	_assert(not duplicate_registry.register_branch(BranchType.new(&"same", &"test.branch.other", 1)), "Duplicate branch IDs must be rejected at registration time.")
	duplicate_registry.register_level(LevelType.new(
		&"one", &"same", 0, &"test.one.title", &"", [], LevelType.ENTRY_TUTORIAL
	))
	_assert(not duplicate_registry.register_level(LevelType.new(
		&"one", &"same", 1, &"test.other.title", &"", [], LevelType.ENTRY_TUTORIAL
	)), "Duplicate level IDs must be rejected at registration time.")
	_assert(_contains(duplicate_registry.validation_errors(), "Duplicate campaign branch"), "Duplicate registration must remain visible in validation evidence.")

	var cycle_registry = RegistryType.new()
	cycle_registry.register_branch(BranchType.new(&"cycle", &"test.branch.cycle", 0))
	cycle_registry.register_level(LevelType.new(
		&"a", &"cycle", 0, &"test.a.title", &"", [&"b"], LevelType.ENTRY_TUTORIAL, Callable(), [&"SharedReward"]
	))
	cycle_registry.register_level(LevelType.new(
		&"b", &"cycle", 1, &"test.b.title", &"", [&"a"], LevelType.ENTRY_TUTORIAL, Callable(), [&"SharedReward"]
	))
	cycle_registry.register_level(LevelType.new(
		&"missing", &"unknown_branch", 2, &"test.missing.title", &"",
		[&"unknown_level"], LevelType.ENTRY_TUTORIAL
	))
	var errors: PackedStringArray = cycle_registry.validation_errors()
	_assert(_contains(errors, "dependency graph contains a cycle"), "Dependency cycles must fail closed.")
	_assert(_contains(errors, "unknown branch"), "Unknown branches must fail validation.")
	_assert(_contains(errors, "unknown dependency"), "Unknown prerequisites must fail validation.")
	_assert(_contains(errors, "owned by both"), "Two levels must not silently own the same reusable reward.")
	_assert(not cycle_registry.is_unlocked(&"a", {&"b": true}), "Any invalid registry must fail closed instead of partially unlocking content.")


func _test_player_content_state() -> void:
	var catalog = PrologueLevelCatalogType.new()
	var state = PlayerContentStateType.new()
	var alu := ReusableComponentType.new()
	alu.component_name = &"ALU1"
	alu.behavior_kind = LogicComponentType.KIND_ALU1
	alu.source_level = &"alu"
	alu.source_signature = "alu-design-v1"
	state.install_reusable(&"alu", alu, catalog)
	_assert(state.component_library.has(&"ALU1") and state.component_library.has(&"ALU4"), "Installing a declared design must create every registered generated reward.")
	_assert(bool(state.completed_levels.get(&"alu", false)), "Installing a reusable design must complete its owning level.")
	state.completed_levels[&"cpu"] = true
	state.completed_levels[&"load_store"] = true
	var computer := ReusableComponentType.new()
	computer.component_name = &"TinyComputer"
	computer.behavior_kind = LogicComponentType.KIND_TINY_COMPUTER
	computer.source_level = &"cpu"
	computer.source_signature = "computer-derived-from-v1"
	state.component_library[&"TinyComputer"] = computer
	var replacement := alu.duplicate_component_definition()
	replacement.source_signature = "alu-design-v2"
	var invalidated: Array[StringName] = state.install_reusable(&"alu", replacement, catalog)
	_assert(invalidated == [&"cpu", &"load_store"], "Replacing a design must invalidate only registered transitive dependents in stable order.")
	_assert(not state.completed_levels.has(&"cpu") and not state.component_library.has(&"TinyComputer"), "Dependent completion and rewards must be removed together.")
	_assert(state.component_library.has(&"ALU1") and state.component_library.has(&"ALU4"), "The replacement and its generated wrapper must remain installed.")
	var manifest: Dictionary = state.manifest_snapshot()
	_assert(int(manifest.get("schema_version", 0)) == 1, "Player content must expose an explicit save-ready manifest version.")
	_assert((manifest.get("designs", []) as Array).size() == 2, "Player manifest must record both primary and generated design provenance.")
	var signature_before: String = state.canonical_signature()
	state.completed_levels[&"unused_false_entry"] = false
	_assert(state.canonical_signature() == signature_before, "False completion entries must not perturb canonical player-content identity.")


func _build_synthetic_level(library: Dictionary) -> Dictionary:
	return {
		"id": &"wrong_builder_id",
		"available": true,
		"library_marker": int(library.get(&"marker", 0)) + 1,
	}


func _contains(errors: PackedStringArray, fragment: String) -> bool:
	for error: String in errors:
		if fragment in error:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
