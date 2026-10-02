extends Node
## Scene-owned, quiet placeholder voices. Only copied intervals and playback position enter.
const Profile = preload("res://src/ui/trace_ambience_profile.gd")
var profile = Profile.new()
var voices: Array[AudioStreamPlayer] = []
var envelope := Vector3.ZERO
var target := Vector3.ZERO
var position := 0.0
var active := false
var focused := true

func _ready() -> void:
	name = "TraceAmbience"
	focused = get_window().has_focus()
	for index: int in 3:
		var voice := AudioStreamPlayer.new()
		voice.stream = _tone(index)
		voice.bus = &"Ambience"
		voice.volume_db = -80.0
		add_child(voice)
		voices.append(voice)
	get_window().focus_exited.connect(_lose_focus)
	get_window().focus_entered.connect(func() -> void: focused = true)

func configure(events: Array, domain: StringName, duration: float) -> void:
	stop()
	profile.configure(events, domain, duration)

func advance(cycle: float, running: bool) -> void:
	if cycle < position or absf(cycle-position) > 16.0:
		envelope = Vector3.ZERO
	position = cycle
	active = running
	var density: Vector3 = profile.sample(cycle)
	if density.z <= 0.0:
		# Sequential work within the window must not masquerade as concurrent voices.
		if density.x >= density.y: density.y = 0.0
		else: density.x = 0.0
	# Background, compute and transfer voices; overlap emerges from simultaneous voices.
	target = Vector3(0.18, density.x, density.y) if active else Vector3.ZERO

func stop() -> void:
	active = false; target = Vector3.ZERO; envelope = Vector3.ZERO; position = 0.0
	for voice: AudioStreamPlayer in voices: voice.stop()

func _lose_focus() -> void:
	focused = false
	stop()

func _process(delta: float) -> void:
	var settings: Node = get_node("/root/WindowMode")
	var enabled: bool = settings.ambience_enabled and settings.ambience_volume > 0.0 and focused
	var desired: Vector3 = target if enabled else Vector3.ZERO
	if settings.ambience_reduced_dynamics and active and enabled:
		desired = Vector3(0.18, 0.25 if target.y > 0 else 0.0, 0.2 if target.z > 0 else 0.0)
	envelope = envelope.lerp(desired, 1.0-exp(-delta / 1.0))
	for index: int in voices.size():
		var voice: AudioStreamPlayer = voices[index]
		var gain: float = envelope[index]
		voice.volume_db = linear_to_db(maxf(0.0001, gain))
		# Headless verification has no audio mixer; keep the same envelope without starting streams.
		if DisplayServer.get_name() == "headless": continue
		if enabled and gain > 0.001:
			if not voice.playing: voice.play()
		elif gain < 0.001 or not enabled:
			voice.stop()

func _exit_tree() -> void:
	stop()
	for voice: AudioStreamPlayer in voices: voice.stream = null

static func _tone(index: int) -> AudioStreamWAV:
	# Integral-frequency, four-second loops have continuous value and slope at the seam.
	# Small harmonic pads, no event-triggered transients, random noise or pitch acceleration.
	const RATE := 22050
	const SECONDS := 4
	var frequencies: Array[float] = [130.75, 196.0, 261.5]
	var bytes := PackedByteArray(); bytes.resize(RATE * SECONDS * 2)
	for sample_index: int in RATE * SECONDS:
		var t: float = float(sample_index) / RATE
		var carrier: float = sin(TAU*frequencies[index]*t) + 0.18*sin(TAU*frequencies[index]*2.0*t)
		var modulation: float = 0.9 + 0.1*cos(TAU*0.25*t)
		bytes.encode_s16(sample_index*2, roundi(carrier*modulation*0.035*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = RATE * SECONDS
	return stream
