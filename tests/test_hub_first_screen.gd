extends SceneTree
## Actual opening/management controls and keyboard focus; no gameplay fixtures or saved solutions.
const NavigationIntent = preload("res://experiments/candidate_session/navigation_intent.gd")
var checks: int = 0
var failures: int = 0
var capture: bool = false

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func progress() -> Dictionary:
	var value: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	value.erase("saved_at_utc")
	return value

func visible_leaves(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child: Node in node.get_children():
		# Hidden settings/manual/new-game layers and separate popup Windows are not homepage content.
		if child is Window: continue
		if child is Control and not child.is_visible_in_tree(): continue
		if child is Label and not child.text.is_empty(): result.append(child)
		elif child is RichTextLabel and not child.text.is_empty(): result.append(child)
		elif child is BaseButton: result.append(child)
		result.append_array(visible_leaves(child))
	return result

func displayed_text(node: Node) -> String:
	var value: String = str(node.text) if node is Label or node is RichTextLabel else ""
	for child: Node in node.get_children(): value += "\n"+displayed_text(child)
	return value

func check_bounds(surface: Control, context: String) -> void:
	var viewport: Rect2 = root.get_visible_rect()
	check(viewport.encloses(surface.get_global_rect()),context+": homepage surface remains inside viewport "+str(surface.get_global_rect()))
	var leaves: Array[Control] = visible_leaves(surface)
	check(not leaves.is_empty(),context+": homepage has visible text and controls")
	for node: Control in leaves:
		var bounds: Rect2 = node.get_global_rect()
		check(bounds.size.x > 0 and bounds.size.y > 0 and viewport.encloses(bounds),context+": visible "+str(node.name)+" fits first screen "+str(bounds))
		if node is Label:
			check(node.size.y+1 >= node.get_minimum_size().y,context+": label keeps all wrapped lines: "+str(node.name))
			check(node.get_theme_font_size("font_size") >= 14,context+": readable text floor: "+str(node.name))
		if node is Button:
			check(node.size.y >= 40,context+": usable action height: "+str(node.name))
			check(not node.clip_text,context+": action text is not hidden by clipping: "+str(node.name))
	for i: int in leaves.size():
		if not leaves[i] is BaseButton: continue
		for j: int in range(i+1,leaves.size()):
			if not leaves[j] is BaseButton: continue
			check(not leaves[i].get_global_rect().intersects(leaves[j].get_global_rect()),context+": actions do not overlap: "+str(leaves[i].name)+"/"+str(leaves[j].name))
	var can_scroll: bool = false
	for node: Node in surface.find_children("*","ScrollContainer",true,false):
		var scroll := node as ScrollContainer
		if scroll.is_visible_in_tree() and (scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED or scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED): can_scroll = true
	check(not can_scroll,context+": homepage requires no scrollable container")

func tab() -> void:
	var press := InputEventKey.new(); press.keycode = KEY_TAB; press.physical_keycode = KEY_TAB; press.pressed = true
	root.push_input(press,true)
	await process_frame
	var release := InputEventKey.new(); release.keycode = KEY_TAB; release.physical_keycode = KEY_TAB; release.pressed = false
	root.push_input(release,true)
	await process_frame

func escape() -> void:
	var press := InputEventKey.new(); press.keycode = KEY_ESCAPE; press.physical_keycode = KEY_ESCAPE; press.pressed = true
	root.push_input(press,true); await process_frame
	var release := InputEventKey.new(); release.keycode = KEY_ESCAPE; release.physical_keycode = KEY_ESCAPE; release.pressed = false
	root.push_input(release,true); await process_frame

func visible_buttons(surface: Control) -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	for node: Control in visible_leaves(surface):
		if node is BaseButton: buttons.append(node)
	return buttons

func check_focus(surface: Control, primary: Control, context: String) -> void:
	check(root.gui_get_focus_owner() == primary,context+": primary action receives startup focus")
	var leaves: Array[Control] = visible_leaves(surface)
	var positions: Dictionary = {}
	var available: int = 0
	for node: Control in leaves:
		positions[node.get_instance_id()] = node.get_global_rect()
		if node is BaseButton and not node.disabled and node.focus_mode == Control.FOCUS_ALL: available += 1
	check(available > 0,context+": keyboard actions are present")
	var visited: Dictionary = {}
	for step: int in available+1:
		var previous: Control = root.gui_get_focus_owner()
		await tab()
		var focused: Control = root.gui_get_focus_owner()
		check(focused != null and surface.is_ancestor_of(focused) and focused.is_visible_in_tree(),context+": Tab stays on visible homepage actions")
		if available > 1: check(focused != previous,context+": Tab advances to another action")
		if focused != null:
			visited[focused.get_instance_id()] = true
			check(root.get_visible_rect().encloses(focused.get_global_rect()),context+": Tab action stays on first screen")
		var moved: bool = false
		for node: Control in leaves:
			var before: Rect2 = positions[node.get_instance_id()]
			var after: Rect2 = node.get_global_rect()
			if not before.position.is_equal_approx(after.position) or not before.size.is_equal_approx(after.size): moved = true
		check(not moved,context+": keyboard focus does not scroll or shift the homepage")
	check(visited.size() >= available,context+": Tab reaches all enabled homepage actions")

func capture_screen(context: String, dimensions: Vector2i) -> void:
	if not capture: return
	RenderingServer.force_draw(false)
	await process_frame
	var screenshot: Image = root.get_texture().get_image()
	check(screenshot != null and screenshot.get_size() == dimensions,context+": captured image has requested actual dimensions")
	if screenshot == null: return
	var folder: String = "res://.godot/hub-first-screen-captures"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,context+": capture directory is available")
	var path: String = folder+"/"+context+".png"
	check(screenshot.save_png(path) == OK,context+": actual rendered capture saved")

func run() -> void:
	capture = "--hub-capture" in OS.get_cmdline_user_args()
	if capture and DisplayServer.get_name() == "headless":
		check(false,"--hub-capture requires a rendered window; ordinary headless runs do not capture")
		capture = false
	var localization: Node = root.get_node("Localization")
	var save: Node = root.get_node("GlobalSave")
	var mode: Node = root.get_node("GameMode")
	var original_locale: String = localization.current_locale()
	var original_mode: StringName = mode.current_mode
	var original_notice: StringName = save.recovery_notice
	var original_details: String = save.recovery_details
	var before: Dictionary = progress()
	mode.set_mode(&"game")
	NavigationIntent.pending_review = ""
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1600,900)]:
		root.mode = Window.MODE_WINDOWED
		root.size = dimensions; root.content_scale_size = dimensions
		await settle()
		for locale: String in ["zh_CN","en"]:
			localization.set_locale(locale)
			for candidate: bool in [false,true]:
				if capture:
					root.mode = Window.MODE_WINDOWED
					await create_timer(1.0).timeout
					root.size = dimensions; root.content_scale_size = dimensions
					await create_timer(0.4).timeout
				save.recovery_notice = &""; save.recovery_details = ""
				var hub = load("res://src/ui/prototype_hub.tscn").instantiate(); hub.candidate_journey = candidate
				root.add_child(hub); await settle()
				var context: String = ("candidate" if candidate else "ordinary")+"-"+locale+"-%dx%d" % [dimensions.x,dimensions.y]
				var surface := hub.find_child("HubSurface",true,false) as Control
				check(surface != null,context+": fixed homepage surface is present")
				if surface == null:
					hub.queue_free(); await settle(); continue
				check_bounds(surface,context)
				var navigation := hub.find_child("HubNavigation",true,false) as Control
				check(surface.is_visible_in_tree() and navigation != null and not navigation.is_visible_in_tree(),context+": only the simple homepage is visible initially")
				check(visible_buttons(surface).size() == 5,context+": homepage has exactly five actions including the three header controls")
				var header := hub.find_child("HeaderActions",true,false) as Control
				check(header != null and visible_buttons(header).size() == 3,context+": header keeps language, settings and fullscreen only")
				var primary := hub.find_child("RecommendedJourneyAction" if candidate else "TaskTree",true,false) as BaseButton
				check(primary != null and primary.is_visible_in_tree() and not primary.disabled,context+": primary entry is visible and available")
				var browse := hub.find_child("HubBrowseJourney",true,false) as Button
				check(browse != null and browse.is_visible_in_tree() and not browse.disabled,context+": shared journey-map launcher is visible")
				for id: String in ["ContinueButton","NewGameButton","ThemeReflectionButton","HubTerminologyButton","EnterRepresentationCandidate","EnterServiceCandidate","EnterPredictionCandidate","SavedSecondActReview","CompletionStory","RecommendedJourneyInfo"]:
					var action := hub.find_child(id,true,false) as BaseButton
					check(action == null or not action.is_visible_in_tree(),context+": secondary action is outside homepage: "+id)
				var work_title := hub.find_child("HubWorkTitle",true,false) as Label
				check(work_title != null and work_title.text == localization.text(&"game.title"),context+": actual work title anchors the opening")
				var theme_title := hub.find_child("HubThemeTitle",true,false) as Label
				check(theme_title != null and theme_title.text == "A Thought Within the World",context+": stable theme is present")
				var target := hub.find_child("HubResumeTitle",true,false) as Label
				var task_navigation: Node = root.get_node("TaskNavigation")
				check(primary != null and primary.text == task_navigation.home_action_text() and target != null and target.text == task_navigation.next_task_title(),context+": opening uses the shared authoritative continuation target")
				check(hub.find_child("ChapterCards",true,false) == null and hub.find_child("CandidateStages",true,false) == null,context+": separate chapter and second-act lobbies are replaced by the shared map")
				await capture_screen(context,dimensions)
				if primary != null: await check_focus(surface,primary,context)
				var snapshot: Dictionary = progress()
				if browse == null or navigation == null:
					hub.queue_free(); await settle(); continue
				var settings_button := hub.find_child("HubSettings",true,false) as Button
				settings_button.grab_focus(); settings_button.pressed.emit(); await settle()
				var manage := hub.find_child("HubManageProgress",true,false) as Button
				check(hub.options_overlay.visible and manage != null and manage.is_visible_in_tree(),context+": clearly named achievements/save management is discoverable in Settings")
				if manage == null:
					hub.queue_free(); await settle(); continue
				manage.grab_focus(); manage.pressed.emit(); await settle()
				check(navigation.is_visible_in_tree() and not surface.is_visible_in_tree() and not hub.options_overlay.visible,context+": management replaces opening and dismisses Settings")
				check_bounds(navigation,context+"-management")
				for id: String in ["ContinueButton","NewGameButton","ThemeReflectionButton","HubTerminologyButton"]:
					var action := hub.find_child(id,true,false) as BaseButton
					check(action != null and action.is_visible_in_tree(),context+": management keeps existing action "+id)
				for id: String in ["SavedSecondActReview","CompletionStory","RecommendedJourneyInfo"]:
					var button := hub.find_child(id,true,false) as BaseButton
					check(button != null and button.is_visible_in_tree() if candidate else button == null,context+": candidate-only saved review boundary "+id)
				for id: String in ["EnterRepresentationCandidate","EnterServiceCandidate","EnterPredictionCandidate","HubCoreTreeEntry"]:
					check(hub.find_child(id,true,false) == null,context+": management is not a parallel task launcher: "+id)
				await capture_screen(context+"-management",dimensions)
				var navigation_close := hub.find_child("HubNavigationClose",true,false) as Button
				check(navigation_close != null and navigation_close.is_visible_in_tree() and not navigation_close.disabled,context+": management has an available return action")
				if navigation_close != null: await check_focus(navigation,navigation_close,context+"-management")
				var handbook_button := hub.find_child("HubTerminologyButton",true,false) as Button
				handbook_button.grab_focus(); handbook_button.pressed.emit(); await settle()
				check(hub.terminology_handbook.is_open(),context+": management handbook action opens the manual")
				await escape(); await settle()
				check(not hub.terminology_handbook.is_open() and navigation.is_visible_in_tree() and root.gui_get_focus_owner() == handbook_button,context+": handbook Escape retains management and restores its launcher focus")
				check_bounds(navigation,context+"-after-handbook")
				hub.new_game_button.pressed.emit(); await process_frame
				check(hub.new_game_overlay.visible,context+": New Game opens its existing confirmation")
				check(hub.new_game_button.text.contains("core") if locale == "en" else hub.new_game_button.text.contains("核心"),context+": restart explicitly targets the core journey")
				var confirmation_text: String = displayed_text(hub.new_game_overlay)
				check(confirmation_text.contains("Representation and Service") and confirmation_text.contains("retained") if locale == "en" else confirmation_text.contains("表示与服务") and confirmation_text.contains("保留"),context+": confirmation states independent second-act saves are retained")
				hub.new_game_clear_workbenches.button_pressed = true
				hub.find_child("NewGameCancelButton",true,false).pressed.emit(); await settle()
				check(not hub.new_game_overlay.visible and progress() == snapshot,context+": cancel with opt-in checkbox still retains progress")
				check(navigation.is_visible_in_tree() and not surface.is_visible_in_tree(),context+": restart cancel retains the management page")
				check_bounds(navigation,context+"-management-after-cancel")
				await escape(); await settle()
				check(surface.is_visible_in_tree() and not navigation.is_visible_in_tree() and root.gui_get_focus_owner() == settings_button,context+": Escape closes management and restores Settings focus")
				check_bounds(surface,context+"-after-management")
				save.recovery_notice = &"save.recovery.newer"
				save.recovery_details = "Synthetic warning detail; no disk content was replaced."
				hub._refresh_save_actions(); await settle()
				check(surface.is_visible_in_tree() and not navigation.is_visible_in_tree(),context+": recovery warning remains on the simple homepage")
				check(hub.save_recovery_label.is_visible_in_tree() and not hub.save_recovery_label.text.is_empty(),context+": recovery warning is visible")
				check(hub.save_recovery_label.text.contains("writing disabled") if locale == "en" else hub.save_recovery_label.text.contains("禁止写入"),context+": write protection is visible before opening details")
				check_bounds(surface,context+"-recovery")
				check(visible_buttons(surface).size() <= 6,context+": recovery adds only its necessary details action to the simple homepage")
				var recovery_button := hub.find_child("SaveRecoveryDetails",true,false) as Button
				check(recovery_button != null and recovery_button.is_visible_in_tree() and not recovery_button.disabled,context+": complete recovery information remains reachable")
				if recovery_button != null:
					recovery_button.pressed.emit(); await settle()
					var dialog := hub.get_node_or_null("SaveRecoveryReview") as AcceptDialog
					check(dialog != null and dialog.visible,context+": recovery details opens actual warning dialog")
					if dialog != null:
						var text: String = dialog.get_label().text
						check(text.contains(localization.text(&"save.recovery.newer")) and text.contains(save.recovery_details),context+": compact warning preserves full original explanation and recovery details")
						dialog.get_ok_button().pressed.emit(); await settle()
				check_bounds(surface,context+"-after-recovery-details")
				check(progress() == snapshot,context+": warning presentation changes no progress")
				hub.queue_free(); await settle()
	save.recovery_notice = original_notice; save.recovery_details = original_details
	localization.set_locale(original_locale); mode.set_mode(original_mode)
	check(progress() == before,"All entry, focus, cancel and warning checks leave progression unchanged")
	print("PASS: test_hub_first_screen " if failures == 0 else "FAIL: test_hub_first_screen ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
