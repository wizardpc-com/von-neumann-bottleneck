extends SceneTree
## Deterministic offline listening sample using the same profile, tones and smoothing.
const Profile = preload("res://src/ui/trace_ambience_profile.gd")
const Player = preload("res://src/ui/trace_ambience_player.gd")
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var solution: Dictionary = Catalog.reference_solution("buffers")
	var trace: SimulationTrace = Catalog.evaluate("buffers",solution.board,solution.program).runs[0]
	var profile = Profile.new(); profile.configure(trace.events,&"overlap",trace.metrics.total_cycles)
	var tones: Array[PackedByteArray] = []
	for index: int in 3: tones.append(Player._tone(index).data)
	var rate := 22050
	var seconds: float = trace.metrics.total_cycles*0.15+2.0
	var data := PackedByteArray(); data.resize(ceili(seconds*rate)*2)
	var envelope := Vector3.ZERO
	var peak := 0.0
	for i: int in data.size()/2:
		var time: float = float(i)/rate
		var cycle: float = time/0.15
		var density: Vector3 = profile.sample(cycle)
		if density.z <= 0:
			if density.x >= density.y: density.y=0
			else: density.x=0
		var target := Vector3(0.18,density.x,density.y) if cycle<trace.metrics.total_cycles else Vector3.ZERO
		envelope=envelope.lerp(target,1.0-exp(-1.0/rate))
		var value := 0.0
		for voice: int in 3:
			value+=tones[voice].decode_s16((i%(rate*4))*2)/32767.0*envelope[voice]*0.3
		peak=maxf(peak,absf(value))
		data.encode_s16(i*2,roundi(clampf(value,-1,1)*32767))
	var wav := AudioStreamWAV.new(); wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=rate; wav.data=data
	var error: Error=wav.save_to_wav("res://docs/verification/20261002-trace-ambience/buffers-preview.wav")
	print("Preview cycles=",trace.metrics.total_cycles," overlap=",trace.metrics.overlap," seconds=",seconds," peak=",peak)
	print("PASS: deterministic low-level ambience preview" if error==OK and peak<0.05 else "FAIL: ambience preview")
	quit(0 if error==OK and peak<0.05 else 1)
