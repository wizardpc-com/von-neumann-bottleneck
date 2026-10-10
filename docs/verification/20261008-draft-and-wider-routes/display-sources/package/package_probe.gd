extends Node
func _ready() -> void:
	var mode: Node = get_node("/root/GameMode")
	var remote: Node = get_node("/root/RemoteFeedback")
	var store_script: Script = load("res://src/hardware_foundations/circuit_workbench_store.gd")
	var workbench_path: String = "user://package_workbench_probe.json"
	var store = store_script.new(workbench_path)
	store.ensure_default(&"game", &"probe", {"components": [], "wires": []})
	var first_write: bool = store.save_active(&"game", &"probe", {"components": [{"id": "first"}], "wires": []})
	var second_write: bool = store.save_active(&"game", &"probe", {"components": [{"id": "second"}], "wires": []})
	var reloaded = store_script.new(workbench_path)
	var persisted: Dictionary = reloaded.active_snapshot(&"game", &"probe")
	var components: Array = persisted.get("components", [])
	var repeated_workbench_save: bool = first_write and second_write and components.size() == 1 and String((components[0] as Dictionary).get("id", "")) == "second"
	var checks: Dictionary = {
		"isolated":OS.get_user_data_dir().ends_with("VonNeumannBottleneckChecks/package-0539c92570bf"),
		"candidate_auto_start_refuses_qa_directory":not load("res://experiments/candidate_session/context.gd").configured_journey(),
		"second_act_resources":ResourceLoader.exists("res://experiments/representation_region/region.tscn") and ResourceLoader.exists("res://experiments/service_plan/lab.tscn"),
		"creation_export_configuration":bool(ProjectSettings.get_setting("candidate/creation_enabled",false))==true,
		"creation_resources":not true or ResourceLoader.exists("res://experiments/creation/workbench.tscn"),
		"candidate_feature":OS.has_feature("free_candidate"),
		"game_only":not mode.is_test_mode() and not mode.developer_tools_enabled() and not mode.set_mode(&"test"),
		"capture_disabled":mode.capture_arguments().is_empty(),
		"forty_tasks":get_node("/root/TaskNavigation").tasks().size()==40,
		"remote_default_off":not remote.enabled and remote.endpoint.is_empty(),
		"build_identity":ProjectSettings.get_setting("application/config/version")=="free-alpha-7c7f8f06f8e2" and ProjectSettings.get_setting("application/config/build_commit")=="7c7f8f06f8e281021f835454251164c7ca334710",
		"system_workspace_identity":get_node("/root/SystemChapter").workspace_version()=="e479b3d0b15c50f6697faad55b9e461e94db21df07d99d5c38e0cf6414bde5a7",
		"locality_workspace_identity":get_node("/root/LocalityChapter").workspace_version()=="7104cc990372ed8b21f46941f13d099ccb063dc434e4e6e7ccd74294f96a7958",
		"repeated_workbench_auto_save":repeated_workbench_save,
		"tests_excluded":not ResourceLoader.exists("res://tests/test_layout_simulation.gd"),
		"server_excluded":not FileAccess.file_exists("res://server/feedback_server.py")}
	var passed: bool = true
	for value: bool in checks.values(): passed=passed and value
	print("PACKAGE_CHECKS ",JSON.stringify(checks))
	if passed:
		var file=FileAccess.open("user://package_probe_result.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(checks)); file.close()
	get_tree().quit(0 if passed else 1)
