extends SceneTree
## Bilingual control geometry, not screenshots or a beginner comprehension study.
const Coach=preload("res://src/hardware_foundations/tutorial_coach.gd")
const Curriculum=preload("res://src/hardware_foundations/operation_curriculum.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	for english: bool in [false,true]:
		root.get_node("Localization").set_locale("en" if english else "zh_CN")
		for width: float in [440.0,640.0]:
			for id: String in Curriculum.LESSONS:
				if id in ["cpu","load_store"]:continue # These use their existing mission briefing.
				var coach=Coach.new();coach.set_english(english);root.add_child(coach)
				coach.custom_minimum_size.x=width;coach.size=Vector2(width,0)
				coach.use_steps(id!="tutorial","")
				coach.set_operation_lesson(StringName(id))
				var states: Array[bool]=[]
				for step: int in (5 if id=="tutorial" else 3): states.append(false)
				coach.update_states(states)
				coach.demonstration_skip.show()
				coach.reset_size()
				for frame: int in 3:await process_frame
				var bounds:=coach.get_global_rect()
				check(coach.size.x<=width+1,"Coach retains requested width: "+id)
				check(coach.size.y<=320,"Coach leaves canvas space: "+id)
				for item: Control in [coach.demonstration_button,coach.demonstration_skip,coach.instruction,coach.operation_tip]:
					check(bounds.encloses(item.get_global_rect()),"Teaching controls stay within the card: "+id)
				check(not coach.instruction.get_global_rect().intersects(coach.operation_tip.get_global_rect()),"Instruction and extra operation focus do not overlap")
				coach.queue_free();await process_frame
	print("PASS: test_operation_coach_layout " if failures==0 else "FAIL: test_operation_coach_layout ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
