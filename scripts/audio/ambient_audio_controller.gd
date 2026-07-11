extends Node
class_name AmbientAudioController

## Layered ambience placeholders per area profile.

const AREA_PROFILES: Dictionary = {
	&"vs_greybox_street": [
		{"id": AudioEventId.AMBIENCE_WIND, "volume": 0.35},
		{"id": AudioEventId.AMBIENCE_WOOD, "volume": 0.18},
	],
	&"vs_street": [
		{"id": AudioEventId.AMBIENCE_WIND, "volume": 0.35},
		{"id": AudioEventId.AMBIENCE_WOOD, "volume": 0.18},
	],
	&"vs_greybox_church": [
		{"id": AudioEventId.AMBIENCE_WIND, "volume": 0.22},
		{"id": AudioEventId.AMBIENCE_BELL, "volume": 0.12},
		{"id": AudioEventId.AMBIENCE_WHISPER, "volume": 0.08},
	],
	&"vs_church": [
		{"id": AudioEventId.AMBIENCE_WIND, "volume": 0.22},
		{"id": AudioEventId.AMBIENCE_BELL, "volume": 0.12},
		{"id": AudioEventId.AMBIENCE_WHISPER, "volume": 0.08},
	],
	&"vs_greybox_underground": [
		{"id": AudioEventId.AMBIENCE_MINES, "volume": 0.30},
		{"id": AudioEventId.AMBIENCE_VERMILITE, "volume": 0.14},
		{"id": AudioEventId.AMBIENCE_MOL_KHAR, "volume": 0.06},
	],
	&"vs_underground": [
		{"id": AudioEventId.AMBIENCE_MINES, "volume": 0.30},
		{"id": AudioEventId.AMBIENCE_VERMILITE, "volume": 0.14},
		{"id": AudioEventId.AMBIENCE_MOL_KHAR, "volume": 0.06},
	],
}

var _audio_manager: AudioManager = null
var _active_area_id: StringName = &""


func setup(audio_manager: AudioManager) -> void:
	_audio_manager = audio_manager


func apply_area_profile(area_id: StringName) -> void:
	if _audio_manager == null:
		return

	if area_id == _active_area_id:
		return

	_audio_manager.stop_all_ambience()
	_active_area_id = area_id

	var profile: Variant = AREA_PROFILES.get(area_id, [])
	if not (profile is Array):
		return

	for layer in profile:
		if typeof(layer) != TYPE_DICTIONARY:
			continue
		var layer_dict := layer as Dictionary
		var layer_id: StringName = layer_dict.get("id", &"")
		var volume := float(layer_dict.get("volume", 0.2))
		_audio_manager.play_event(layer_id, null, volume)
