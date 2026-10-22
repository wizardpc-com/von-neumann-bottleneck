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
		for width: float in [1252.0,1572.0]:
			for id: String in Curriculum.LESSONS:
				if id in ["cpu","load_store"]:continue # These use their existing mission briefing.
				var coach=Coach.new();coach.set_english(english);root.add_child(coach)
				coach.custom_minimum_size.x=width;coach.size=Vector2(width,0)
				coach.use_steps(id!="tutorial","Produce SUM and CARRY for each input case." if id=="half_adder" else "")
				coach.set_operation_lesson(StringName(id))
				if id=="half_adder":
					coach.set_cases([{ "A":0,"B":0,"SUM":0,"CARRY":0 },{ "A":0,"B":1,"SUM":1,"CARRY":0 },{ "A":1,"B":0,"SUM":1,"CARRY":0 },{ "A":1,"B":1,"SUM":0,"CARRY":1 }])
				var states: Array[bool]=[]
				for step: int in (5 if id=="tutorial" else 3): states.append(false)
				coach.update_states(states)
				coach.demonstration_skip.show()
				coach.reset_size()
				for frame: int in 3:await process_frame
				var bounds:=coach.get_global_rect()
				check(coach.size.x<=width+1,"Coach retains requested width: "+id)
				check(coach.size.y<=80,"Docked coach leaves canvas space: "+id)
				for item: Control in [coach.demonstration_button,coach.demonstration_skip,coach.instruction_well,coach.briefing_button,coach.collapse_button]:
					check(bounds.encloses(item.get_global_rect()),"Teaching controls stay within the docked strip: "+id)
				check(not coach.demonstration_button.get_global_rect().intersects(coach.demonstration_skip.get_global_rect()),"Demo actions do not overlap")
				check(coach.demonstration_button.tooltip_text==str(Curriculum.lesson(StringName(id),english).get("text", "")) and not coach.demonstration_button.tooltip_text.is_empty(),"Full curriculum remains available in the tooltip: "+id)
				if id=="half_adder":
					check(bounds.encloses(coach.case_table.get_global_rect()),"Case specification stays within the strip")
				coach.queue_free();await process_frame
	print("PASS: test_operation_coach_layout " if failures==0 else "FAIL: test_operation_coach_layout ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
