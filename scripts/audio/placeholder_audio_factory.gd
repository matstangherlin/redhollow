extends RefCounted
class_name PlaceholderAudioFactory

## Procedural placeholder audio — original synthesis, no external assets.
## Replace streams via AudioManager / MusicController.register_stream() when final assets exist.
## All beds preload at manager ready — never synthesize or load from disk mid-combat.

const SAMPLE_RATE := 22050


static func build_library() -> Dictionary:
	return {
		AudioEventId.FOOTSTEP: _make_layered_thump(95.0, 48.0, 0.055, 0.20),
		AudioEventId.PUNCH: _make_layered_hit(0.055, 0.24, 1100.0, 180.0),
		AudioEventId.KICK: _make_layered_thump(52.0, 28.0, 0.08, 0.26),
		AudioEventId.IMPACT_FLESH: _make_noise_burst(0.085, 0.18, 380.0),
		AudioEventId.IMPACT_STONE: _make_tone(720.0, 0.055, 0.15, true),
		AudioEventId.IMPACT_VERMILITE: _make_vermilite_chime(0.12, 0.20),
		AudioEventId.DODGE: _make_noise_burst(0.09, 0.11, 1600.0),
		AudioEventId.COUNTER: _make_counter_clang(0.10, 0.24),
		AudioEventId.RED_BRAND_CHARGE: _make_brand_growl(0.22, 0.14),
		AudioEventId.RED_BRAND_BREAKER: _make_layered_hit(0.18, 0.32, 220.0, 70.0),
		AudioEventId.BARRIER_HIT: _make_tone(800.0, 0.06, 0.17, true),
		AudioEventId.BARRIER_BREAK: _make_noise_burst(0.22, 0.28, 480.0),
		AudioEventId.GUNSHOT: _make_gun_report(0.09, 0.34),
		AudioEventId.CHAIN: _make_chain_rattle(0.14, 0.16),
		AudioEventId.DOOR: _make_door_thunk(0.16, 0.22),
		AudioEventId.CHECKPOINT: _make_tone(660.0, 0.20, 0.17, false),
		AudioEventId.BOSS_HIT: _make_layered_thump(70.0, 36.0, 0.10, 0.28),
		AudioEventId.BOSS_STINGER: _make_boss_stinger(0.45, 0.22),
		AudioEventId.DIALOGUE_BLIP: _make_tone(460.0, 0.035, 0.09, false),
		AudioEventId.UI_CONFIRM: _make_tone(540.0, 0.05, 0.13, false),
		AudioEventId.UI_NAVIGATE: _make_tone(390.0, 0.028, 0.09, false),
		AudioEventId.PLAYER_HURT: _make_noise_burst(0.10, 0.19, 280.0),
		AudioEventId.PLAYER_DEATH: _make_tone(105.0, 0.38, 0.22, false),
		AudioEventId.ENEMY_DEATH: _make_noise_burst(0.15, 0.15, 170.0),
		AudioEventId.AMBIENCE_WIND: _make_loop_noise(0.038),
		AudioEventId.AMBIENCE_WOOD: _make_loop_tone(175.0, 0.022),
		AudioEventId.AMBIENCE_BELL: _make_loop_bell(218.0, 0.014),
		AudioEventId.AMBIENCE_MINES: _make_loop_noise(0.028),
		AudioEventId.AMBIENCE_WHISPER: _make_loop_noise(0.016),
		AudioEventId.AMBIENCE_VERMILITE: _make_loop_tone(430.0, 0.013),
		AudioEventId.AMBIENCE_MOL_KHAR: _make_loop_tone(64.0, 0.011),
	}


static func build_music_library() -> Dictionary:
	## Quiet original drones — Music bus slots without third-party music.
	return {
		MusicSlotId.MENU: _make_music_bed(72.0, 108.0, 0.045),
		MusicSlotId.STREET: _make_music_bed(82.0, 123.0, 0.040),
		MusicSlotId.CHURCH: _make_music_bed(65.0, 98.0, 0.038),
		MusicSlotId.CATACOMBS: _make_music_bed(55.0, 82.0, 0.042),
		MusicSlotId.DEACON_RUSK: _make_music_bed(58.0, 116.0, 0.050),
		MusicSlotId.FINALE: _make_music_bed(48.0, 96.0, 0.046),
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


static func _make_layered_thump(
	freq_a: float,
	freq_b: float,
	duration_sec: float,
	volume: float
) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-9.0 * t / maxf(duration_sec, 0.001))
		var sample := (
			sin(TAU * freq_a * t) * 0.7
			+ sin(TAU * freq_b * t) * 0.35
		) * volume * envelope
		_write_sample(data, index, sample)

	return _to_stream(data)


static func _make_layered_hit(
	duration_sec: float,
	volume: float,
	noise_cutoff: float,
	body_freq: float
) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var previous := 0.0

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-7.5 * t / maxf(duration_sec, 0.001))
		var noise := randf_range(-1.0, 1.0)
		var filtered := lerpf(previous, noise, clampf(noise_cutoff / float(SAMPLE_RATE), 0.01, 0.95))
		previous = filtered
		var body := sin(TAU * body_freq * t) * 0.55
		_write_sample(data, index, (filtered * 0.65 + body) * volume * envelope)

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


static func _make_vermilite_chime(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-5.5 * t / maxf(duration_sec, 0.001))
		var sample := (
			sin(TAU * 920.0 * t) * 0.55
			+ sin(TAU * 1380.0 * t) * 0.30
			+ sin(TAU * 460.0 * t) * 0.20
		) * volume * envelope
		_write_sample(data, index, sample)

	return _to_stream(data)


static func _make_counter_clang(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-10.0 * t / maxf(duration_sec, 0.001))
		var sample := (
			sin(TAU * 980.0 * t) * 0.45
			+ sin(TAU * 1460.0 * t) * 0.25
			+ sin(TAU * 220.0 * t) * 0.35
		) * volume * envelope
		_write_sample(data, index, sample)

	return _to_stream(data)


static func _make_brand_growl(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var climb := clampf(t / maxf(duration_sec * 0.7, 0.001), 0.0, 1.0)
		var envelope := climb * (1.0 - t / maxf(duration_sec, 0.001))
		var freq := 120.0 + 80.0 * climb
		var sample := sin(TAU * freq * t) * volume * envelope
		_write_sample(data, index, sample)

	return _to_stream(data)


static func _make_gun_report(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var previous := 0.0

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-14.0 * t / maxf(duration_sec, 0.001))
		var noise := randf_range(-1.0, 1.0)
		var filtered := lerpf(previous, noise, 0.55)
		previous = filtered
		var body := sin(TAU * 95.0 * t) * 0.5
		_write_sample(data, index, (filtered * 0.8 + body) * volume * envelope)

	return _to_stream(data)


static func _make_chain_rattle(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-6.0 * t / maxf(duration_sec, 0.001))
		var metallic := sin(TAU * 340.0 * t) + 0.45 * sin(TAU * 680.0 * t)
		var tick := 1.0 if fmod(t, 0.028) < 0.006 else 0.35
		_write_sample(data, index, metallic * 0.5 * volume * envelope * tick)

	return _to_stream(data)


static func _make_door_thunk(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var previous := 0.0

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-5.5 * t / maxf(duration_sec, 0.001))
		var wood := sin(TAU * 140.0 * t) * 0.7 + sin(TAU * 70.0 * t) * 0.4
		var noise := randf_range(-1.0, 1.0)
		var filtered := lerpf(previous, noise, 0.12)
		previous = filtered
		_write_sample(data, index, (wood + filtered * 0.25) * volume * envelope)

	return _to_stream(data)


static func _make_boss_stinger(duration_sec: float, volume: float) -> AudioStreamWAV:
	var sample_count := maxi(int(duration_sec * float(SAMPLE_RATE)), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-3.2 * t / maxf(duration_sec, 0.001))
		var sample := (
			sin(TAU * 55.0 * t) * 0.55
			+ sin(TAU * 82.5 * t) * 0.30
			+ sin(TAU * 220.0 * t) * 0.18 * exp(-8.0 * t)
		) * volume * envelope
		_write_sample(data, index, sample)

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


static func _make_loop_bell(frequency: float, volume: float) -> AudioStreamWAV:
	var duration_sec := 3.0
	var sample_count := int(duration_sec * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var pulse := 0.55 + 0.45 * sin(TAU * 0.35 * t)
		var sample := (
			sin(TAU * frequency * t)
			+ 0.35 * sin(TAU * frequency * 2.0 * t)
		) * volume * pulse
		_write_sample(data, index, sample)

	var stream := _to_stream(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


static func _make_music_bed(root_hz: float, fifth_hz: float, volume: float) -> AudioStreamWAV:
	var duration_sec := 4.0
	var sample_count := int(duration_sec * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var breathe := 0.72 + 0.28 * sin(TAU * 0.08 * t)
		var sample := (
			sin(TAU * root_hz * t) * 0.55
			+ sin(TAU * fifth_hz * t) * 0.32
			+ sin(TAU * (root_hz * 0.5) * t) * 0.22
		) * volume * breathe
		_write_sample(data, index, sample)

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
