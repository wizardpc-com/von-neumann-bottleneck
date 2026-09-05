extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var english: Array[String] = []
	var chinese: Array[String] = []
	var catalogs: Dictionary = {}
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var keys: Array[String] = []
		var values: Dictionary = {}
		var source := FileAccess.get_file_as_string("res://localization/demo.%s.po" % locale)
		for line: String in source.split("\n"):
			if line.begins_with('msgid "demo.'):
				var key: String = JSON.parse_string(line.substr(6))
				if key in keys:
					failures.append("Duplicate key: " + key)
				keys.append(key)
				values[key] = String(TranslationServer.translate(key))
				if String(TranslationServer.translate(key)) == key:
					failures.append("Missing translation: %s %s" % [locale, key])
		catalogs[locale] = values
		if locale == "en":
			english = keys
		else:
			chinese = keys
	english.sort()
	chinese.sort()
	if english != chinese or english.size() < 150:
		failures.append("Mainline catalogs must have matching complete key coverage.")
	var placeholder := RegEx.new()
	placeholder.compile("%[ds]")
	for key: String in english:
		var formats: Array[Array] = []
		for locale: String in ["zh_CN", "en"]:
			var fields: Array[String] = []
			for found: RegExMatch in placeholder.search_all(catalogs[locale].get(key, "")):
				fields.append(found.get_string())
			formats.append(fields)
		if formats[0] != formats[1]:
			failures.append("Mismatched placeholder order/types: " + key)
	for id: String in root.get_node("DemoProgress").IDS:
		for field: String in ["title", "goal", "specs", "hint1", "hint2", "hint3"]:
			if "demo.task.%s.%s" % [id, field] not in english:
				failures.append("Missing task field: " + id + "." + field)
	for failure: String in failures:
		push_error(failure)
	root.get_node("Localization").set_locale("zh_CN")
	if failures.is_empty():
		print("PASS: all eight task specifications/hints and %d bilingual mainline keys" % english.size())
	quit(0 if failures.is_empty() else 1)
