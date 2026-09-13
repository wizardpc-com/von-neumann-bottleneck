extends SceneTree
var failures: Array[String]=[]
func _init() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message)
func run() -> void:
	var window: Node=root.get_node("WindowMode")
	var save: Node=root.get_node("GlobalSave")
	var localization: Node=root.get_node("Localization")
	var branding=load("res://src/ui/brand_identity.gd")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		var label:=Label.new();label.text=locale
		var slot: Control=branding.title_slot(locale,label,{"logo_zh":"res://assets/branding/missing.svg"})
		check(slot==label and slot.text==locale,"Missing localized logo retains same-language text and no blank slot")
		slot.free()
		window.open_settings();await process_frame
		var host: Control=window.settings_layer.get_child(0)
		check(host.settings_only and host.options_overlay.visible and host.options_resume_button.is_visible_in_tree(),"Same settings view opens without building a hub behind the level")
		var before: Dictionary=save._save_snapshot();before.erase("saved_at_utc")
		host._close_options_menu();await process_frame
		var after: Dictionary=save._save_snapshot();after.erase("saved_at_utc")
		check(before==after and not is_instance_valid(window.settings_layer),"Closing settings leaves progression unchanged")
	var original: String=save.storage_path
	save.configure_for_test("user://missing_parent_for_failure/save.json","user://workbenches-test.json")
	# A directory in place of the target makes replacement impossible, without touching any real save.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save.storage_path))
	check(not save.save_game(true) and not save.last_error.is_empty(),"Real filesystem write failure is observable")
	check(save.export_rescue("user://synthetic-recovery.json"),"Recovery data can be exported after a failed normal write")
	check(not save.export_rescue(save.storage_path) and not save.export_rescue(save.storage_path+".bak"),"Recovery export cannot overwrite normal save or backup")
	var rescued: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://synthetic-recovery.json"))
	check(rescued is Dictionary and rescued.recovery_format==1 and rescued.has("progress"),"Recovery export is inspectable and separate from normal progression")
	save.disk_write_allowed=false;save.storage_path=original
	for message: String in failures:push_error(message)
	print("PASS: shared settings, locale fallback and real write-failure rescue" if failures.is_empty() else "FAIL: final convergence")
	quit(0 if failures.is_empty() else 1)
