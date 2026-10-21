extends SceneTree
const Curriculum = preload("res://src/hardware_foundations/operation_curriculum.gd")
const Narrative = preload("res://src/ui/mission_narrative_catalog.gd")
const Catalog = preload("res://src/hardware_foundations/prologue_level_catalog.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var catalog = Catalog.new()
	var skills: Dictionary = {}
	for id: StringName in catalog.level_ids():
		for english: bool in [false,true]:
			var lesson: Dictionary = Curriculum.lesson(id,english)
			check(not lesson.is_empty(),"Every actual prologue level has a teaching focus: "+String(id))
			if lesson.is_empty(): continue
			check(not lesson.text.is_empty(),"Both languages have concrete instruction")
			skills[lesson.skill]=true
	check(skills.size()>=12,"Teaching is spread over distinct operations, not repeated build/test copy")
	var tutorial_bodies: Array = Narrative.HARDWARE_PAGES[&"tutorial"].map(func(page: Dictionary) -> StringName: return page[&"body"])
	check(&"teaching.edit" not in tutorial_bodies and &"teaching.view" not in tutorial_bodies,"First lesson no longer front-loads editing and navigation manuals")
	var full_bodies: Array = Narrative.HARDWARE_PAGES[&"full_adder"].map(func(page: Dictionary) -> StringName: return page[&"body"])
	var register_bodies: Array = Narrative.HARDWARE_PAGES[&"register"].map(func(page: Dictionary) -> StringName: return page[&"body"])
	check(&"teaching.edit" in full_bodies and &"teaching.view" in register_bodies,"Editing and navigation are retained in later mandatory prologue tasks")
	check(Curriculum.lesson(&"missing").is_empty(),"Unknown task does not invent a lesson")
	print("PASS: test_operation_curriculum " if failures==0 else "FAIL: test_operation_curriculum ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
