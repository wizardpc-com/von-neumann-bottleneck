extends Node

signal locale_changed(locale: String)

const DEFAULT_LOCALE := "zh_CN"
const SUPPORTED_LOCALES := ["zh_CN", "en"]


func _enter_tree() -> void:
	var requested_locale: String = _locale_override()
	if requested_locale.is_empty():
		var engine_locale: String = TranslationServer.standardize_locale(TranslationServer.get_locale())
		var os_locale: String = TranslationServer.standardize_locale(OS.get_locale())
		if engine_locale != os_locale and engine_locale in SUPPORTED_LOCALES:
			requested_locale = engine_locale
	if requested_locale.is_empty():
		requested_locale = String(ProjectSettings.get_setting("game/default_locale", DEFAULT_LOCALE))
	if not set_locale(requested_locale):
		set_locale(DEFAULT_LOCALE)


func set_locale(locale: String) -> bool:
	var standardized: String = TranslationServer.standardize_locale(locale)
	if not standardized in SUPPORTED_LOCALES:
		return false
	TranslationServer.set_locale(standardized)
	_update_window_title()
	locale_changed.emit(standardized)
	return true


func current_locale() -> String:
	return TranslationServer.get_locale()


func supported_locales() -> PackedStringArray:
	return PackedStringArray(SUPPORTED_LOCALES)


func text(key: StringName, arguments: Array = []) -> String:
	var translated: String = TranslationServer.translate(key)
	if arguments.is_empty():
		return translated
	return translated % arguments


func text_from_spec(spec: Dictionary) -> String:
	if spec.is_empty():
		return ""
	var key := StringName(spec.get("key", &""))
	var arguments: Array = spec.get("args", [])
	return text(key, arguments)


func text_list(specs: Array[Dictionary], separator: String = " ") -> String:
	var parts := PackedStringArray()
	for spec: Dictionary in specs:
		parts.append(text_from_spec(spec))
	return separator.join(parts)


func _locale_override() -> String:
	var arguments: PackedStringArray = OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for index: int in range(arguments.size()):
		if arguments[index].begins_with("--locale=") or arguments[index].begins_with("--language="):
			return arguments[index].get_slice("=", 1)
		if arguments[index] in ["--locale", "--language"] and index + 1 < arguments.size():
			return arguments[index + 1]
	return ""


func _update_window_title() -> void:
	var window: Window = get_window()
	if window != null:
		window.title = text(&"game.window_title")
