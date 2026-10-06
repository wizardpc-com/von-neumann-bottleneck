extends SceneTree
const Lab = preload("res://experiments/prediction/lab.tscn")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	root.size = Vector2i(1280,720)
	var lab = Lab.instantiate(); root.add_child(lab); lab.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); lab.size = Vector2(root.size); await process_frame
	lab.run_current()
	var signature: String = lab.history[0].trace.canonical_signature()
	lab.change_task(1); lab.rule.select(1); lab.edit_policy(); lab.run_current()
	var second_signature: String = lab.history[1].trace.canonical_signature()
	for en: bool in [false,true]:
		lab.english = en; lab.build(); await process_frame; await process_frame
		lab.select_run(0)
		var public: Dictionary = lab.public_observation()
		var source: Dictionary = public.get("evidence_source",{})
		check(public.task == 1 and lab.mission.text == lab.mission_text(),"Review preserves the current investigation")
		check(source.get("task",-1) == 0 and source.get("run_index",-1) == 0,"Review identifies earlier record task independently")
		check(source.get("policy",{}) == lab.history[0].policy,"Review source uses recorded rule, not current editor")
		var caption := lab.find_child("RecordedSource",true,false) as Label
		check(caption != null,"Recorded evidence has a visible source caption")
		if caption != null:
			check(caption.text.contains("#1") and caption.text.contains("off") and caption.text.contains("Regular" if en else "规律流"),"Cross-task caption identifies the record and rule")
			check(caption.text.contains("differs" if en else "不同"),"Cross-task record is explicitly distinguished from the current draft")
			check(caption.get_global_rect().end.x <= root.size.x,"Bilingual source caption wraps within the minimum viewport")
		if source.has("policy"): source.policy.rule = "unknown"
		check(lab.history[0].policy.rule == "off","Public source is detached from immutable recipe")
		lab.select_run(1)
		caption = lab.find_child("RecordedSource",true,false) as Label
		check(caption != null and caption.text.contains("matches" if en else "一致"),"Same task and exact recorded rule match the current draft")
		lab.restart()
		public = lab.public_observation()
		check(public.get("evidence_source",{}).is_empty() and public.observed_addresses.is_empty(),"New run clears old evidence provenance and observations")
		lab.step_current(); public = lab.public_observation(); source = public.get("evidence_source",{})
		check(source.get("task",-1) == 1 and source.get("run_index",0) == -1,"Partial evidence belongs to current task without claiming a receipt")
		check(public.observed_addresses.size() == 1 and not source.has("metrics") and not source.has("events"),"Source caption exposes no hidden future evidence")
		lab.rule.select(2); lab.edit_policy()
		check(lab.public_observation().get("evidence_source",{}).is_empty(),"Editing a rule clears the partial source")
		lab.rule.select(1); lab.edit_policy()
		check(lab.history[0].trace.canonical_signature() == signature and lab.history[1].trace.canonical_signature() == second_signature,"Review and edits preserve measured traces")
	lab.queue_free(); await process_frame
	print("PASS: prediction record source %d checks" % checks if failures == 0 else "FAIL: prediction record source %d failures / %d checks" % [failures,checks])
	quit(0 if failures == 0 else 1)
