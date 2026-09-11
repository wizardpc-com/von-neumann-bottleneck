extends SceneTree
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func run() -> void:
	var localization: Node = root.get_node("Localization")
	var mode: Node = root.get_node("WindowMode")
	var remote: Node = root.get_node("RemoteFeedback"); remote.set_process(false)
	var save: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	var settings := ConfigFile.new(); settings.set_value("other","keep",17); settings.save("user://presentation.cfg")
	check(localization.set_preferred_locale("en"),"Can persist English.")
	mode.set_sound(false,0.25); mode.set_reduced_motion(true); mode.set_frame_limit(120)
	settings.load("user://presentation.cfg")
	check(settings.get_value("interface","locale")=="en" and settings.get_value("audio","volume")==0.25 and settings.get_value("other","keep")==17,"Presentation preferences coexist without erasing unknown settings.")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"Mute applies to actual effect audio bus.")
	var prompt: GDScript = load("res://src/playtest/sharing_first_choice.gd")
	check(not prompt.needs_choice(),"Offline build never shows sharing prompt.")
	remote.endpoint="http://127.0.0.1:9876/v1"
	check(prompt.needs_choice(),"Configured endpoint shows an explicit first choice.")
	check(prompt.remember_choice("local") and not prompt.needs_choice() and not remote.enabled,"Decline persists and never enables uploads.")
	remote.endpoint="http://127.0.0.1:9877/v1"
	check(prompt.needs_choice(),"Endpoint change requires a new first choice.")
	check(prompt.remember_choice("basic") and remote.enabled and remote.queue.is_empty() and remote.eligible_visits.is_empty() and not remote.scores_enabled,"Basic consent has no backfill or score permission.")
	mode.reset_presentation()
	check(remote.enabled and remote.sharing_mode=="basic" and mode.frame_limit==60 and mode.sound_enabled and is_equal_approx(mode.sound_volume,0.7),"Defaults reset does not alter privacy.")
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	# Snapshot generation time is not player progress.
	save.erase("saved_at_utc"); after.erase("saved_at_utc")
	check(after==save,"Settings and consent do not alter progression.")
	var diagnostics: GDScript = load("res://src/ui/support_diagnostics.gd")
	var path: String = diagnostics.export_local()
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(report.has("build_id") and not report.has("client_id") and not report.has("endpoint") and not report.has("path"),"Diagnostic export is bounded and excludes identities and device paths.")
	var first_contents: String = FileAccess.get_file_as_string(path)
	var second_path: String = diagnostics.export_local()
	check(not second_path.is_empty() and second_path!=path and FileAccess.get_file_as_string(path)==first_contents,"Repeated diagnostic exports preserve earlier reports.")
	remote.set_sharing_mode("local"); remote.endpoint=""
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate(); root.add_child(hub)
		hub.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); hub.size=Vector2(1280,720); hub._open_options_menu()
		for frame: int in range(5): await process_frame
		var panel: Control = hub.find_child("ChapterOptionsPanel",true,false)
		check(hub.size==Vector2(1280,720) and Rect2(Vector2.ZERO,hub.size).encloses(panel.get_global_rect()),"Settings panel fits minimum viewport in "+locale)
		check(panel.get_global_rect().encloses(hub.options_resume_button.get_global_rect()),"Close stays visible below scrolling content.")
		var reset: Button = hub.find_child("ResetPresentation",true,false); reset.grab_focus()
		var reset_dialog: ConfirmationDialog = hub.find_child("ResetPresentationConfirm",true,false)
		check(reset_dialog.ok_button_text==localization.text(&"common.confirm") and reset_dialog.cancel_button_text==localization.text(&"common.cancel"),"Reset confirmation buttons follow the selected language.")
		for frame: int in range(4): await process_frame
		var scroll: ScrollContainer = hub.find_child("SettingsScroll",true,false)
		check(scroll.scroll_vertical>0 and scroll.get_global_rect().encloses(reset.get_global_rect()),"Keyboard focus scrolls to the offscreen reset action.")
		var export_button: Button = hub.find_child("ExportDiagnostics",true,false)
		export_button.pressed.emit()
		var folder_button: Button = hub.options_open_export_folder_button
		check(folder_button.visible and reset.get_node(reset.focus_previous)==folder_button,"Newly revealed export folder action joins the keyboard focus order.")
		folder_button.hide()
		check(reset.get_node(reset.focus_previous)!=folder_button,"Hidden export folder action leaves the keyboard focus order.")
		var moments: Node = root.get_node("PlaytestMoments"); moments.opinion.text="keep my draft"; moments.ratings[0].select(3)
		localization.set_locale("en" if locale=="zh_CN" else "zh_CN")
		check(moments.opinion.text=="keep my draft" and moments.ratings[0].selected==3,"Live feedback translation preserves draft and ratings.")
		var delete_dialog: ConfirmationDialog = moments.find_child("DeleteUploadsConfirm",true,false)
		check(delete_dialog.get_ok_button().text==localization.text(&"common.confirm") and delete_dialog.get_cancel_button().text==localization.text(&"common.cancel"),"Persistent deletion confirmation buttons refresh after a language change.")
		hub.queue_free(); await process_frame
	if failures.is_empty(): print("PASS: language/audio persistence, safe reset, first choice, diagnostic privacy and bounded bilingual settings")
	else:
		for message: String in failures: push_error(message)
	quit(0 if failures.is_empty() else 1)
