extends Node
class_name MusicController

## Music bus player with named slots. Beds preload at ready — never disk-load mid-combat.

const MUSIC_CONTROLLER_GROUP := "music_controller"

@export var crossfade_seconds: float = 0.85
@export var default_volume: float = 0.42

var _streams: Dictionary = {}
var _player_a: AudioStreamPlayer = null
var _player_b: AudioStreamPlayer = null
var _active_is_a: bool = true
var _current_slot: StringName = &""
var _area_slot_before_boss: StringName = &""
var _fade_tween: Tween = null
var _area_to_slot: Dictionary = {}


func _ready() -> void:
	add_to_group(MUSIC_CONTROLLER_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_area_to_slot = {
		&"vs_greybox_street": MusicSlotId.STREET,
		&"vs_street": MusicSlotId.STREET,
		&"vs_greybox_church": MusicSlotId.CHURCH,
		&"vs_church": MusicSlotId.CHURCH,
		&"vs_greybox_underground": MusicSlotId.CATACOMBS,
		&"vs_underground": MusicSlotId.CATACOMBS,
	}
	_streams = PlaceholderAudioFactory.build_music_library()
	_player_a = _make_player("MusicPlayerA")
	_player_b = _make_player("MusicPlayerB")
	add_child(_player_a)
	add_child(_player_b)


func register_stream(slot_id: StringName, stream: AudioStream) -> void:
	if slot_id == &"" or stream == null:
		return
	_streams[slot_id] = stream


func get_stream(slot_id: StringName) -> AudioStream:
	return _streams.get(slot_id, null)


func get_current_slot() -> StringName:
	return _current_slot


func play_slot(slot_id: StringName, volume_scale: float = -1.0, force: bool = false) -> void:
	if slot_id == &"":
		return
	if not force and slot_id == _current_slot:
		return

	var stream: AudioStream = _streams.get(slot_id, null)
	if stream == null:
		return

	var target_volume := default_volume if volume_scale < 0.0 else clampf(volume_scale, 0.0, 1.0)
	var incoming := _player_b if _active_is_a else _player_a
	var outgoing := _player_a if _active_is_a else _player_b

	incoming.stream = stream
	incoming.volume_db = linear_to_db(0.001)
	incoming.play()

	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", linear_to_db(target_volume), crossfade_seconds)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", linear_to_db(0.001), crossfade_seconds)

	_fade_tween.finished.connect(func() -> void:
		if outgoing != null and outgoing != incoming and outgoing.playing and outgoing.volume_db <= -40.0:
			outgoing.stop()
	, CONNECT_ONE_SHOT)

	_active_is_a = not _active_is_a
	_current_slot = slot_id


func play_for_area(area_id: StringName) -> void:
	var slot: StringName = _area_to_slot.get(area_id, &"")
	if slot != &"":
		play_slot(slot)


func begin_boss_override(slot_id: StringName = MusicSlotId.DEACON_RUSK) -> void:
	if _current_slot != MusicSlotId.DEACON_RUSK and _current_slot != MusicSlotId.FINALE:
		_area_slot_before_boss = _current_slot
	play_slot(slot_id, default_volume * 1.05, true)


func end_boss_override() -> void:
	if _area_slot_before_boss != &"":
		play_slot(_area_slot_before_boss)
		_area_slot_before_boss = &""


func stop_music(fade_seconds: float = 0.4) -> void:
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	for player in [_player_a, _player_b]:
		if player != null and player.playing:
			_fade_tween.tween_property(player, "volume_db", linear_to_db(0.001), fade_seconds)
	_fade_tween.finished.connect(func() -> void:
		if _player_a != null:
			_player_a.stop()
		if _player_b != null:
			_player_b.stop()
	, CONNECT_ONE_SHOT)
	_current_slot = &""


func _make_player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = AudioManager.BUS_MUSIC
	player.max_polyphony = 1
	return player
