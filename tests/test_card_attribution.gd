extends SceneTree
## Production cards in an isolated presentation fixture; no completion is earned.
const Catalog = preload("res://src/ui/mission_narrative_catalog.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func unattributed(node: Node) -> void:
	if node is Label or node is Button or node is Typewriter:
		var text: String = node.text
		check(not "壹" in text and not "Yi" in text, "Card has no visible attribution: " + text)
	for child: Node in node.get_children(): unattributed(child)

func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	for english: bool in [false, true]:
		root.get_node("Localization").set_locale("en" if english else "zh_CN")
		var context: Control = load("res://src/ui/journey_context_card.gd").new()
		root.add_child(context)
		for key: String in Catalog.TASK_CONTEXTS:
			var parts: PackedStringArray = key.split("/")
			context.set_task(StringName(parts[0]), StringName(parts[1]), english)
			unattributed(context)
		context.queue_free(); await settle()
		var coach: Control = load("res://src/hardware_foundations/tutorial_coach.gd").new()
		coach.english = english; root.add_child(coach); await settle()
		unattributed(coach)
		coach.queue_free(); await settle()
		var help: Control = load("res://src/ui/yi_help_card.gd").new()
		help.english = english; root.add_child(help); await settle()
		help.present(root.get_node("Localization").text(&"hardware.hint.half_adder.1"), [])
		unattributed(help)
		check(help.find_child("YiHelpSpeaker", true, false) == null, "Help has no speaker row label")
		check(help.close_button.visible and not help.body.text.is_empty(), "Help retains text and dismissal")
		help.queue_free(); await settle()
		var opening: CanvasLayer = load("res://src/ui/yi_opening.gd").new()
		root.add_child(opening)
		opening.say(Catalog.task_context(&"chapter_1", &"cpu_speed", english).action, english)
		unattributed(opening)
		check(not opening.body.text.is_empty(), "Opening retains its action")
		opening.queue_free(); await settle()
		var completion: Control = load("res://src/ui/level_completion_overlay.gd").new()
		root.add_child(completion); await settle()
		completion.present(&"tutorial", "", "", "", &"hardware_foundations")
		unattributed(completion)
		check(completion.find_child("YiCompletionSpeaker", true, false) == null, "Completion has no speaker badge")
		check(completion.yi_response_label.text.contains("NOT"), "Completion retains factual NOT response")
		completion.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "card attribution %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
