extends RefCounted
class_name AudioAssetRegistry

## Provenance registry for every shipped audio event / music slot.
## External licensed files must be registered here before mark-as-integrated.

const VERSION := "0.2.0-beta.1-presentation"
const ORIGIN_PROCEDURAL := "PlaceholderAudioFactory (runtime AudioStreamWAV)"
const LICENSE_ORIGINAL := "Original Red Hollow"
const AUTHOR_PROJECT := "Red Hollow / project code"


static func build_entries() -> Dictionary:
	var entries: Dictionary = {}
	_register_sfx(entries)
	_register_music(entries)
	return entries


static func get_entry(event_or_slot_id: StringName) -> Dictionary:
	return build_entries().get(event_or_slot_id, {})


static func has_entry(event_or_slot_id: StringName) -> bool:
	return build_entries().has(event_or_slot_id)


static func _entry(
	file_path: String,
	event_id: StringName,
	notes: String = "procedural placeholder"
) -> Dictionary:
	return {
		"id": event_id,
		"origin": ORIGIN_PROCEDURAL,
		"license": LICENSE_ORIGINAL,
		"author": AUTHOR_PROJECT,
		"file": file_path,
		"version": VERSION,
		"notes": notes,
	}


static func _register_sfx(entries: Dictionary) -> void:
	var factory := "res://scripts/audio/placeholder_audio_factory.gd"
	var pairs: Array = [
		[AudioEventId.FOOTSTEP, "passos"],
		[AudioEventId.PUNCH, "golpes"],
		[AudioEventId.KICK, "golpes"],
		[AudioEventId.IMPACT_FLESH, "impactos"],
		[AudioEventId.IMPACT_STONE, "impactos"],
		[AudioEventId.IMPACT_VERMILITE, "impactos / Vermilite"],
		[AudioEventId.DODGE, "esquiva"],
		[AudioEventId.COUNTER, "counter"],
		[AudioEventId.RED_BRAND_CHARGE, "Red Brand"],
		[AudioEventId.RED_BRAND_BREAKER, "Red Brand"],
		[AudioEventId.BARRIER_HIT, "barreira"],
		[AudioEventId.BARRIER_BREAK, "barreira"],
		[AudioEventId.GUNSHOT, "tiro"],
		[AudioEventId.CHAIN, "corrente"],
		[AudioEventId.DOOR, "portas"],
		[AudioEventId.CHECKPOINT, "checkpoint"],
		[AudioEventId.BOSS_HIT, "boss"],
		[AudioEventId.BOSS_STINGER, "boss"],
		[AudioEventId.DIALOGUE_BLIP, "UI / diálogo"],
		[AudioEventId.UI_CONFIRM, "UI"],
		[AudioEventId.UI_NAVIGATE, "UI"],
		[AudioEventId.PLAYER_HURT, "golpes"],
		[AudioEventId.PLAYER_DEATH, "impactos"],
		[AudioEventId.ENEMY_DEATH, "impactos"],
		[AudioEventId.AMBIENCE_WIND, "vento"],
		[AudioEventId.AMBIENCE_WOOD, "madeira"],
		[AudioEventId.AMBIENCE_BELL, "sino"],
		[AudioEventId.AMBIENCE_MINES, "catacumbas"],
		[AudioEventId.AMBIENCE_WHISPER, "igreja"],
		[AudioEventId.AMBIENCE_VERMILITE, "Vermilite"],
		[AudioEventId.AMBIENCE_MOL_KHAR, "Mol-Khar"],
	]
	for pair in pairs:
		var event_id: StringName = pair[0]
		entries[event_id] = _entry(factory, event_id, String(pair[1]))


static func _register_music(entries: Dictionary) -> void:
	var factory := "res://scripts/audio/placeholder_audio_factory.gd"
	var pairs: Array = [
		[MusicSlotId.MENU, "menu bed"],
		[MusicSlotId.STREET, "rua bed"],
		[MusicSlotId.CHURCH, "igreja bed"],
		[MusicSlotId.CATACOMBS, "catacumbas bed"],
		[MusicSlotId.DEACON_RUSK, "Deacon Rusk bed"],
		[MusicSlotId.FINALE, "finale bed"],
	]
	for pair in pairs:
		var slot_id: StringName = pair[0]
		entries[slot_id] = _entry(factory, slot_id, String(pair[1]))
