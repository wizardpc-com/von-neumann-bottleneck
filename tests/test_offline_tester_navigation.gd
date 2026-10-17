extends SceneTree
const SecondAct = preload("res://src/campaign/second_act_tasks.gd")
const Creation = preload("res://src/campaign/creation_tasks.gd")
const Service = preload("res://experiments/service_plan/lab.gd")
const Context = preload("res://experiments/candidate_session/context.gd")
const PlayerContent = preload("res://src/content/player_content_state.gd")

var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	root.size = Vector2i(1280,720)
	var navigation: Node = root.get_node("TaskNavigation")
	var save: Node = root.get_node("GlobalSave")
	var before: Dictionary = save._save_snapshot(); before.erase("saved_at_utc")
	var prior_setting: Variant = ProjectSettings.get_setting("playtest/offline_tester",false)
	ProjectSettings.set_setting("playtest/offline_tester",false)
	var ordinary_core: Array[Dictionary] = navigation.tasks()
	var ordinary_second: Array[Dictionary] = SecondAct.build({},false)
	check(ordinary_core.size()==40 and ordinary_second.size()==11,"Original catalog sizes remain unchanged")
	check(not ordinary_second[6].unlocked and not ordinary_second[7].unlocked,"Fresh ordinary Service contracts2 and3 remain locked")
	check(Context.configured_journey_for(true,"representation","OfflineTeammate","C:/QA/VonNeumannBottleneckCandidates/representation/OfflineTeammate"),"OfflineTeammate binds an isolated Representation and Service pair")
	check(not Context.configured_journey_for(true,"representation","OfflineTeammate","C:/QA/VonNeumannBottleneckCandidates/representation/CloudPlaytest"),"OfflineTeammate cannot reuse the CloudPlaytest save channel")
	var service := Service.new(); service.candidate_journey = true
	root.add_child(service); await process_frame
	service.change_task(2)
	check(service.task==0 and service.unlocked==0 and service.support_plans.is_empty(),"Ordinary Service host refuses a fresh locked contract")
	ProjectSettings.set_setting("playtest/offline_tester",true)
	check(navigation.offline_tester_enabled() and not root.get_node("GameMode").is_test_mode(),"Tester entrance access does not enable developer test mode")
	var core: Array[Dictionary] = navigation.tasks()
	var second: Array[Dictionary] = SecondAct.build({},false)
	var path: String = "user://offline-navigation-"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	var creation: Array[Dictionary] = Creation.build(false,PackedStringArray(["--creation-profile="+path]))
	var all_tasks: Array[Dictionary] = []
	all_tasks.append_array(core); all_tasks.append_array(second); all_tasks.append_array(creation)
	check(all_tasks.size()==60,"Fresh tester catalog contains all sixty task entrances")
	var available: bool = true
	var distinct: Dictionary = {}
	for task: Dictionary in all_tasks:
		available = available and bool(task.unlocked)
		distinct[task.key] = true
	check(available and distinct.size()==60,"Every tester task key is distinct and enterable")
	for index: int in core.size():
		check(core[index].completed==ordinary_core[index].completed,"Tester access does not grant core completion: "+core[index].key)
	check(not second[6].completed and not second[7].completed and not creation[8].completed,"Open candidate entrances grant no saved support")
	var hardware = load("res://src/hardware_foundations/hardware_foundations.gd").new()
	hardware._activate_content_state()
	var fresh_content := PlayerContent.new()
	hardware.player_content = fresh_content
	hardware._install_offline_reference_library()
	for level_id: StringName in [&"full_adder",&"alu",&"register",&"ram",&"cpu",&"load_store",&"delay",&"alarm"]:
		check(bool(hardware.level_catalog.definition(level_id,hardware.component_library).get("available",false)),"Fresh tester can instantiate hardware task "+String(level_id))
	var reference = hardware.component_library.get(&"HalfAdder")
	check(reference != null and reference.source_level==&"tester_reference" and bool(reference.metadata.get("tester_reference",false)),"Temporary component identifies itself as a tester reference")
	var reference_circuit := LogicCircuit.new()
	reference_circuit.add_component(reference.instantiate(&"TEST_REFERENCE"))
	check(hardware._uses_offline_reference(reference_circuit),"Tester references cannot count as earned circuit evidence")
	var owned := reference.duplicate_component_definition()
	owned.source_level = &"half_adder"
	owned.source_signature = "genuine-player-test-source"
	owned.metadata.clear()
	var seeded := PlayerContent.new()
	seeded.component_library[&"HalfAdder"] = owned
	hardware.player_content = seeded
	hardware._install_offline_reference_library()
	check(hardware.component_library[&"HalfAdder"] == owned and not owned.metadata.has("tester_reference"),"Reference overlay preserves an existing player component")
	var owned_circuit := LogicCircuit.new()
	owned_circuit.add_component(owned.instantiate(&"TEST_OWNED"))
	check(not hardware._uses_offline_reference(owned_circuit),"Earned component remains valid evidence in tester mode")
	check(fresh_content.component_library.is_empty() and fresh_content.completed_levels.is_empty() and seeded.component_library.size()==1 and seeded.completed_levels.is_empty(),"Temporary references never enter player content or completed levels")
	hardware.free()
	service.change_task(2)
	check(service.task==2 and service.unlocked==0 and service.support_plans.is_empty() and service.history.is_empty(),"Tester can open Service contract3 without forging support or measurements")
	check(not service.task_buttons[2].disabled,"Fresh Service contract3 has a usable direct entrance")
	ProjectSettings.set_setting("playtest/offline_tester",false)
	service.change_task(0)
	check(service.task==0 and service.task_buttons[2].disabled,"Ordinary Service gate returns when tester setting is absent")
	service.queue_free(); await process_frame
	ProjectSettings.set_setting("playtest/offline_tester",prior_setting)
	var after: Dictionary = save._save_snapshot(); after.erase("saved_at_utc")
	check(before==after,"Entrance-only tester access leaves campaign save authority unchanged")
	print("PASS: test_offline_tester_navigation " if failures==0 else "FAIL: test_offline_tester_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
