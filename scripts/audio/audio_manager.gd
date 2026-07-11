extends Node
class_name AudioManager

## Centralized audio playback with pooled players per bus.

const AUDIO_MANAGER_GROUP := "audio_manager"

const BUS_SFX := "SFX"
const BUS_UI := "UI"
const BUS_VOICE := "Voice"
const BUS_MUSIC := "Music"
const BUS_AMBIENCE := "Ambience"

const DEFAULT_2D_POOL := 12
const DEFAULT_UI_POOL := 4
const DEFAULT_VOICE_POOL := 2
const DEFAULT_AMBIENCE_POOL := 8

@export var sfx_pool_size: int = DEFAULT_2D_POOL
@export var ui_pool_size: int = DEFAULT_UI_POOL
@export var voice_pool_size: int = DEFAULT_VOICE_POOL
@export var ambience_pool_size: int = DEFAULT_AMBIENCE_POOL

var _streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer2D] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _voice_pool: Array[AudioStreamPlayer] = []
var _ambience_pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	add_to_group(AUDIO_MANAGER_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_placeholder_library()
	_build_pools()

	if FeedbackSettingsAccess.get_manager() != null:
		var manager := FeedbackSettingsAccess.get_manager()
		if not manager.settings_changed.is_connected(_on_settings_changed):
			manager.settings_changed.connect(_on_settings_changed)


func register_stream(event_id: StringName, stream: AudioStream) -> void:
	if event_id == &"" or stream == null:
		return
	_streams[event_id] = stream


func play_event(
	event_id: StringName,
	global_position: Variant = null,
	volume_scale: float = 1.0,
	pitch_scale: float = 1.0
) -> void:
	var stream: AudioStream = _streams.get(event_id, null)
	if stream == null:
		return

	var bus := _resolve_bus(event_id)
	if _is_ambience_event(event_id):
		_play_ambience(event_id, stream, volume_scale)
		return

	if _is_ui_event(event_id) or _is_voice_event(event_id):
		_play_ui_or_voice(event_id, stream, bus, volume_scale, pitch_scale)
		return

	_play_sfx_at(stream, bus, global_position, volume_scale, pitch_scale)


func play_ui(event_id: StringName = AudioEventId.UI_NAVIGATE, volume_scale: float = 1.0) -> void:
	play_event(event_id, null, volume_scale)


func stop_ambience_layer(layer_id: StringName) -> void:
	for player in _ambience_pool:
		if player.get_meta("layer_id", &"") == layer_id:
			player.stop()


func stop_all_ambience() -> void:
	for player in _ambience_pool:
		player.stop()


func get_stream(event_id: StringName) -> AudioStream:
	return _streams.get(event_id, null)


func _load_placeholder_library() -> void:
	_streams = PlaceholderAudioFactory.build_library()


func _build_pools() -> void:
	_sfx_pool.clear()
	for _i in sfx_pool_size:
		var player := AudioStreamPlayer2D.new()
		player.bus = BUS_SFX
		player.max_polyphony = 1
		add_child(player)
		_sfx_pool.append(player)

	_ui_pool.clear()
	for _i in ui_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_UI
		add_child(player)
		_ui_pool.append(player)

	_voice_pool.clear()
	for _i in voice_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_VOICE
		add_child(player)
		_voice_pool.append(player)

	_ambience_pool.clear()
	for _i in ambience_pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_AMBIENCE
		add_child(player)
		_ambience_pool.append(player)


func _play_sfx_at(
	stream: AudioStream,
	bus: String,
	global_position: Variant,
	volume_scale: float,
	pitch_scale: float
) -> void:
	var player := _acquire_sfx_player()
	if player == null:
		return

	player.bus = bus
	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume_scale, 0.0, 1.0))
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)

	if global_position is Vector2:
		player.global_position = global_position
	else:
		player.global_position = Vector2.ZERO

	player.play()


func _play_ui_or_voice(
	event_id: StringName,
	stream: AudioStream,
	bus: String,
	volume_scale: float,
	pitch_scale: float
) -> void:
	var pool: Array = _voice_pool if _is_voice_event(event_id) else _ui_pool
	var player := _acquire_player(pool)
	if player == null:
		return

	player.bus = bus
	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume_scale, 0.0, 1.0))
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()


func _play_ambience(layer_id: StringName, stream: AudioStream, volume_scale: float) -> void:
	var player := _acquire_ambience_player(layer_id)
	if player == null:
		return

	player.stream = stream
	player.volume_db = linear_to_db(clampf(volume_scale, 0.0, 1.0))
	if not player.playing:
		player.play()


func _acquire_sfx_player() -> AudioStreamPlayer2D:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0] if not _sfx_pool.is_empty() else null


func _acquire_player(pool: Array) -> AudioStreamPlayer:
	for player in pool:
		if not player.playing:
			return player
	return pool[0] if not pool.is_empty() else null


func _acquire_ambience_player(layer_id: StringName) -> AudioStreamPlayer:
	for player in _ambience_pool:
		if player.get_meta("layer_id", &"") == layer_id:
			return player

	for player in _ambience_pool:
		if not player.playing:
			player.set_meta("layer_id", layer_id)
			return player

	var fallback := _ambience_pool[0]
	fallback.set_meta("layer_id", layer_id)
	return fallback


func _resolve_bus(event_id: StringName) -> String:
	if _is_ui_event(event_id):
		return BUS_UI
	if _is_voice_event(event_id):
		return BUS_VOICE
	if _is_ambience_event(event_id):
		return BUS_AMBIENCE
	return BUS_SFX


func _is_ui_event(event_id: StringName) -> bool:
	return event_id in [AudioEventId.UI_CONFIRM, AudioEventId.UI_NAVIGATE]


func _is_voice_event(event_id: StringName) -> bool:
	return event_id in [AudioEventId.DIALOGUE_BLIP]


func _is_ambience_event(event_id: StringName) -> bool:
	return String(event_id).begins_with("ambience_")


func _on_settings_changed() -> void:
	FeedbackSettingsAccess.apply_audio()
