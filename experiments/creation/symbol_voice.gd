extends Node
## Optional playback cue for the saved symbol currently being revealed.
const RATE: int = 22050
const SAMPLES: int = 1323
const FREQUENCIES := [220.0,246.94,261.63,293.66]
var player: AudioStreamPlayer
var tones: Array[AudioStreamWAV] = []

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = &"Effects"
	add_child(player)
	for frequency: float in FREQUENCIES: tones.append(_tone(frequency))

func play_symbol(symbol: int) -> void:
	if symbol < 0 or symbol >= tones.size(): return
	player.stop()
	player.stream = tones[symbol]
	if DisplayServer.get_name() != "headless": player.play()

func stop() -> void:
	if player != null: player.stop()

static func _tone(frequency: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(SAMPLES*2)
	for index: int in SAMPLES:
		var time: float = float(index)/RATE
		var envelope: float = sin(PI*float(index)/float(SAMPLES-1))
		envelope *= envelope
		var wave: float = sin(TAU*frequency*time)+0.12*sin(TAU*frequency*2.0*time)
		bytes.encode_s16(index*2,roundi(wave*envelope*0.08*32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
