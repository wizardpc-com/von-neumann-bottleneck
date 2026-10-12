extends SceneTree
## Authored saved-output fixture; rendered captures are not native input evidence.
const Focus = preload("res://experiments/creation/work_focus.gd")
const Model = preload("res://experiments/creation/model.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func capture(view: Window, name: String) -> void:
	if "--creation-work-listening-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false); await process_frame
	var folder: String = "res://.godot/creation-work-listening-captures"
	DirAccess.make_dir_recursive_absolute(folder)
	check(view.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"Capture "+name)

func run() -> void:
	var trained: Dictionary = Model.learn([[0,1,0,2,0,1,0,3]],1,Model.default_machine())
	var record: Dictionary = Model.generate(trained.model,[0,1],40,7,"weighted",Model.default_machine())
	check(record.get("ok",false),"Generate a real, replayable output for the exhibit")
	if not record.get("ok",false): quit(1); return
	var first_feedback: Dictionary = {}
	for item: Dictionary in record.events:
		if item.get("kind","") == "feedback_write" and item.get("index",-1) == 2:
			first_feedback = item
			break
	check(not first_feedback.is_empty(),"Actual first feedback-write event is present")
	var work: Dictionary = {"id":"listening-fixture","name":"A kept signal / 留下的光纹","output":record.output.duplicate(),"recipe":record.recipe.duplicate(true),"mapping":"light-shapes-v1","parent":""}
	var original_work: String = JSON.stringify(work)
	var original_record: String = JSON.stringify(record)
	var folder: String = "user://creation-work-listening"
	DirAccess.make_dir_recursive_absolute(folder)
	var path: String = folder.path_join("protected-fixture.json")
	var saved_bytes: String = original_work+"\n"
	var saved_file := FileAccess.open(path,FileAccess.WRITE)
	check(saved_file != null,"Open isolated snapshot file")
	if saved_file == null: quit(1); return
	saved_file.store_string(saved_bytes); saved_file.close()
	for english: bool in [false,true]:
		var view = Focus.new(); view.configure(work,english,record); root.add_child(view)
		view.size = Vector2i(640,420); view.show(); await settle()
		var language: String = "en" if english else "zh"
		check(not view.listen_button.button_pressed and view.voice.player.bus == &"Effects" and view.voice.tones.size() == 4,"Listening is opt-in on Effects "+language)
		check(view.snapshot_scroll.size.y > 70 and view.canvas.output == record.output,"Small window retains actual artwork space "+language)
		for control: Control in [view.listen_button,view.origin_label,view.phrase_label,view.previous_phrase_button,view.next_phrase_button]:
			var rect: Rect2 = control.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= view.size.x and rect.end.y <= view.size.y,"Small window shows "+control.name+" "+language)
		view.seek(1)
		check(view.origin_label.text.contains("Initial passage" if english else "起始片段"),"Verified initial passage is visible beside artwork "+language)
		view.seek(3)
		check(view.origin_label.text.contains("prior context" if english else "此前上下文") and view.origin_label.text.contains(Catalog.symbols(first_feedback.get("before_context",[]))),"Verified feedback origin uses the exact recorded context "+language)
		await capture(view,"origin-"+language)
		view.seek(1); view.next_phrase_button.pressed.emit()
		check(view.cursor == 17 and not view.static_overview and view.phrase_label.text.contains(Catalog.symbols(work.output.slice(16,32))),"Next phrase reaches the actual saved indices17–32 "+language)
		await capture(view,"phrase-"+language)
		view.previous_phrase_button.pressed.emit()
		check(view.cursor == 1 and view.previous_phrase_button.disabled,"Previous phrase returns to the first actual cell "+language)
		view.seek(0); view.next_phrase_button.pressed.emit()
		check(view.cursor == 1,"Phrase navigation starts with the first saved symbol "+language)
		view.seek(40)
		check(view.next_phrase_button.disabled and view.phrase_label.text.contains(Catalog.symbols(work.output.slice(32,40))),"Final short phrase has no invented cells "+language)
		view.listen_button.button_pressed = true
		check(view.listen_note.visible and view.listen_note.text.contains("quality" if english else "质量"),"Opt-in listening explains the non-simulation pitch mapping "+language)
		view.voice.player.stream = view.voice.tones[3]
		view.seek(0)
		check(not view.voice.player.playing and view.voice.player.stream == view.voice.tones[3],"Seek stops sound without playing a target symbol "+language)
		view.mapping_choice.select(2); view.mapping_choice.item_selected.emit(2)
		check(not view.voice.player.playing and view.voice.player.stream == view.voice.tones[3],"Changing viewing mapping stops sound without replaying a symbol "+language)
		view.step()
		check(view.cursor == 1 and view.voice.player.stream == view.voice.tones[int(work.output[0])],"Step cues only the revealed saved symbol "+language)
		view.overview_button.button_pressed = true
		check(not view.playing and not view.voice.player.playing and view.canvas.revealed == -1,"Static overview shows all symbols and stops sound "+language)
		view.overview_button.button_pressed = false
		var settings: Node = root.get_node("WindowMode")
		var prior_enabled: bool = settings.sound_enabled
		var prior_volume: float = settings.sound_volume
		settings.set_sound(true,0.25)
		var effects_bus: int = AudioServer.get_bus_index("Effects")
		check(effects_bus >= 0 and not AudioServer.is_bus_mute(effects_bus) and is_equal_approx(AudioServer.get_bus_volume_db(effects_bus),linear_to_db(0.25)),"Optional voice uses actual Effects volume path "+language)
		settings.set_sound(false,prior_volume)
		check(AudioServer.is_bus_mute(effects_bus),"Global Effects mute applies to optional work tones "+language)
		settings.set_sound(prior_enabled,prior_volume)
		view.toggle_play()
		var prior_tone: AudioStream = view.voice.player.stream
		view.mapping_choice.select(1); view.mapping_choice.item_selected.emit(1)
		check(view.playing and not view.voice.player.playing and view.voice.player.stream == prior_tone,"Mid-play mapping change cuts the cue and does not synthesize another "+language)
		view._process(0.25)
		check(view.cursor == 2 and view.voice.player.stream == view.voice.tones[int(work.output[1])],"Playback cues the newly revealed saved symbol "+language)
		view.toggle_play()
		check(not view.playing and not view.voice.player.playing,"Pause stops the short tone "+language)
		view.step(); view.listen_button.button_pressed = false
		check(not view.voice.player.playing,"Turning listening off stops a cue "+language)
		view.listen_button.button_pressed = true
		view.seek(38)
		var final_symbol: int = int(work.output[39])
		view.voice.player.stream = view.voice.tones[(final_symbol+1)%4]
		var final_tone_finished := {"value":false}
		view.voice.player.finished.connect(func() -> void: final_tone_finished.value = true,CONNECT_ONE_SHOT)
		view.toggle_play(); view._process(1.0)
		check(view.cursor == 40 and not view.playing and view.voice.player.stream == view.voice.tones[final_symbol],"Playback endpoint includes the final actual symbol "+language)
		var started_playing: bool = view.voice.player.playing
		var finish_wait_ms: int = 0
		if DisplayServer.get_name() != "headless":
			var finish_start: int = Time.get_ticks_msec()
			while not final_tone_finished.value and Time.get_ticks_msec()-finish_start < 1000:
				await process_frame
			finish_wait_ms = Time.get_ticks_msec()-finish_start
		var final_tone: AudioStreamWAV = view.voice.tones[final_symbol]
		var naturally_finished: bool = DisplayServer.get_name() == "headless" or final_tone_finished.value
		if DisplayServer.get_name() != "headless": print("LISTENING_FINAL "+language+" wait_ms="+str(finish_wait_ms)+" finished="+str(final_tone_finished.value)+" playing="+str(view.voice.player.playing))
		check(naturally_finished and not view.voice.player.playing and final_tone.loop_mode == AudioStreamWAV.LOOP_DISABLED and final_tone.data.size() == 2646,"Final one-shot finishes naturally within1s "+language+" (started_immediately="+str(started_playing)+", finished="+str(final_tone_finished.value)+", wait_ms="+str(finish_wait_ms)+", playing="+str(view.voice.player.playing)+")")
		view.reduced_motion = true; view.seek(0); view.toggle_play()
		check(view.cursor == 1 and not view.playing and view.voice.player.stream == view.voice.tones[int(work.output[0])],"Reduced motion retains explicit audible step "+language)
		view.voice.stop(); view.reduced_motion = false; view.toggle_play(); view.focus_exited.emit()
		check(not view.playing and not view.voice.player.playing,"Focus loss stops playback and sound "+language)
		view.toggle_play(); view.hide(); await settle()
		check(not view.playing and not view.voice.player.playing,"Hide stops playback and sound without automatic resume "+language)
		view.show(); await settle()
		check(not view.playing,"Showing again does not resume playback "+language)
		var wrong: Dictionary = record.duplicate(true); wrong.output[0] = (int(wrong.output[0])+1)%4
		check(not view.set_evidence(wrong),"Different output cannot impersonate saved generation evidence "+language)
		view.seek(3)
		check(view.origin_label.text.contains("snapshot only" if english else "仅已保存快照"),"No unverified origin is claimed "+language)
		view.dismiss(); await settle()
		check(FileAccess.get_file_as_string(path) == saved_bytes and JSON.stringify(work) == original_work and JSON.stringify(record) == original_record,"Exhibition preserves saved bytes, work and replay "+language)
	var future: Dictionary = work.duplicate(true); future.recipe = {"version":99,"model":"future"}
	var long_output: Array = []
	for index: int in 4096: long_output.append(index%4)
	future.output = long_output
	var future_before: String = JSON.stringify(future)
	var long_view = Focus.new(); long_view.configure(future,true); root.add_child(long_view)
	long_view.size = Vector2i(640,420); long_view.show(); await settle()
	long_view.seek(4096); long_view.previous_phrase_button.pressed.emit()
	check(long_view.cursor == 4065 and long_view.canvas.output.size() == 4096 and long_view.canvas.cell_rect(4095).end.y <= long_view.canvas.custom_minimum_size.y,"Maximum snapshot remains scrollable and phrase navigation reaches real indices")
	check(long_view.origin_label.text.contains("snapshot only") and long_view.recipe_label.text.contains("cannot be interpreted"),"Future recipe remains viewable without invented generation events")
	check(JSON.stringify(future) == future_before and FileAccess.get_file_as_string(path) == saved_bytes,"Long unknown snapshot does not rewrite the protected work")
	long_view.dismiss(); await settle()
	print("PASS: creation work listening %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
