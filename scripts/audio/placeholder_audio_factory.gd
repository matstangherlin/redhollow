extends RefCounted
class_name PlaceholderAudioFactory

## Procedural placeholder audio — original synthesis, no external assets.
## Replace streams via AudioManager.register_stream() when final assets exist.

const SAMPLE_RATE := 22050


static func build_library() -> Dictionary:
	return {
		AudioEventId.FOOTSTEP: _make_thump(90.0, 0.05, 0.18),
		AudioEventId.PUNCH: _make_noise_burst(0.06, 0.22, 900.0),
		AudioEventId.KICK: _make_thump(55.0, 0.07, 0.24),
		AudioEventId.IMPACT_FLESH: _make_noise_burst(0.08, 0.16, 420.0),
		AudioEventId.IMPACT_STONE: _make_tone(680.0, 0.05, 0.14, true),
		AudioEventId.IMPACT_VERMILITE: _make_tone(920.0, 0.09, 0.18, true),
		AudioEventId.DODGE: _make_noise_burst(0.10, 0.10, 1400.0),
		AudioEventId.COUNTER: _make_tone(520.0, 0.08, 0.22, true),
		AudioEventId.RED_BRAND_CHARGE: _make_tone(140.0, 0.14, 0.12, false),
		AudioEventId.RED_BRAND_BREAKER: _make_noise_burst(0.16, 0.28, 260.0),
		AudioEventId.BARRIER_HIT: _make_tone(760.0, 0.06, 0.16, true),
		AudioEventId.BARRIER_BREAK: _make_noise_burst(0.20, 0.26, 520.0),
		AudioEventId.GUNSHOT: _make_noise_burst(0.05, 0.30, 1800.0),
		AudioEventId.CHAIN: _make_tone(340.0, 0.11, 0.14, true),
		AudioEventId.CHECKPOINT: _make_tone(660.0, 0.18, 0.16, false),
		AudioEventId.DIALOGUE_BLIP: _make_tone(440.0, 0.04, 0.08, false),
		AudioEventId.UI_CONFIRM: _make_tone(520.0, 0.05, 0.12, false),
		AudioEventId.UI_NAVIGATE: _make_tone(380.0, 0.03, 0.08, false),
		AudioEventId.PLAYER_HURT: _make_noise_burst(0.10, 0.18, 300.0),
		AudioEventId.PLAYER_DEATH: _make_tone(110.0, 0.35, 0.20, false),
		AudioEventId.ENEMY_DEATH: _make_noise_burst(0.14, 0.14, 180.0),
		AudioEventId.AMBIENCE_WIND: _make_loop_noise(0.035),
		AudioEventId.AMBIENCE_WOOD: _make_loop_tone(180.0, 0.02),
		AudioEventId.AMBIENCE_BELL: _make_loop_tone(220.0, 0.015),
		AudioEventId.AMBIENCE_MINES: _make_loop_noise(0.025),
		AudioEventId.AMBIENCE_WHISPER: _make_loop_noise(0.018),
		AudioEventId.AMBIENCE_VERMILITE: _make_loop_tone(420.0, 0.012),
		AudioEventId.AMBIENCE_MOL_KHAR: _make_loop_tone(70.0, 0.01),
	}


static func silent_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.data = PackedByteArray()
	return stream


static func _make_tone(
	frequency: float,
	duration_sec: float,
	volume: float,
	hard_attack: bool
) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := 1.0 - (float(index) / float(sample_count))
		if hard_attack and index < 4:
			envelope = float(index) / 4.0
		var sample := sin(TAU * frequency * t) * volume * envelope
		_write_sample(data, index, sample)

	return _to_stream(data)


static func _make_thump(frequency: float, duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-8.0 * t / maxf(duration_sec, 0.001))
		var sample := sin(TAU * frequency * t) * volume * envelope
		_write_sample(data, index, sample)

	return _to_stream(data)


static func _make_noise_burst(duration_sec: float, volume: float, cutoff: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var previous := 0.0

	for index in range(sample_count):
		var envelope := 1.0 - (float(index) / float(sample_count))
		var noise := randf_range(-1.0, 1.0)
		var filtered := lerpf(previous, noise, clampf(cutoff / float(SAMPLE_RATE), 0.01, 0.95))
		previous = filtered
		_write_sample(data, index, filtered * volume * envelope)

	return _to_stream(data)


static func _make_loop_noise(volume: float) -> AudioStreamWAV:
	var duration_sec := 2.0
	var sample_count := int(duration_sec * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		_write_sample(data, index, randf_range(-1.0, 1.0) * volume)

	var stream := _to_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


static func _make_loop_tone(frequency: float, volume: float) -> AudioStreamWAV:
	var duration_sec := 2.0
	var sample_count := int(duration_sec * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		_write_sample(data, index, sin(TAU * frequency * t) * volume)

	var stream := _to_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


static func _write_sample(data: PackedByteArray, index: int, sample: float) -> void:
	var int_sample := int(clampf(sample, -1.0, 1.0) * 32767.0)
	data[index * 2] = int_sample & 0xFF
	data[index * 2 + 1] = (int_sample >> 8) & 0xFF


static func _to_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.data = data
	return stream
