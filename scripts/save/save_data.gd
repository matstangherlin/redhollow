extends RefCounted
class_name SaveData

const CURRENT_SAVE_VERSION := 1
const REQUIRED_FIELDS := [
	"save_version",
	"current_scene",
	"checkpoint_id",
	"checkpoint_position",
	"player_max_health",
	"player_current_health",
	"red_brand_energy",
	"unlocked_abilities",
	"destroyed_barriers",
	"narrative_flags",
	"activated_checkpoints",
	"settings",
]


static func create_default(current_scene: String = "res://scenes/core/game.tscn") -> Dictionary:
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"current_scene": current_scene,
		"content_manifest_id": "",
		"chapter_id": "",
		"checkpoint_id": "",
		"checkpoint_position": {"x": 0.0, "y": 0.0},
		"player_max_health": 12.0,
		"player_current_health": 12.0,
		"red_brand_energy": 0.0,
		"unlocked_abilities": [],
		"destroyed_barriers": {},
		"narrative_flags": {},
		"activated_checkpoints": [],
		"settings": {},
	}


static func validate(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return _invalid("root_not_dictionary", false)

	var save_data := data as Dictionary
	for field_name in REQUIRED_FIELDS:
		if not save_data.has(field_name):
			return _invalid("missing_field:%s" % field_name, false)

	if typeof(save_data.get("save_version")) != TYPE_INT and typeof(save_data.get("save_version")) != TYPE_FLOAT:
		return _invalid("invalid_save_version_type", false)

	var save_version := int(save_data.get("save_version"))
	if save_version <= 0:
		return _invalid("invalid_save_version_value", false)

	if save_version > CURRENT_SAVE_VERSION:
		return _invalid("save_version_too_new:%s" % save_version, false)

	if typeof(save_data.get("checkpoint_position")) != TYPE_DICTIONARY:
		return _invalid("invalid_checkpoint_position", false)

	var position := save_data.get("checkpoint_position") as Dictionary
	if not position.has("x") or not position.has("y"):
		return _invalid("checkpoint_position_missing_axes", false)

	if typeof(save_data.get("unlocked_abilities")) != TYPE_ARRAY:
		return _invalid("invalid_unlocked_abilities", false)

	if typeof(save_data.get("destroyed_barriers")) != TYPE_DICTIONARY:
		return _invalid("invalid_destroyed_barriers", false)

	if typeof(save_data.get("narrative_flags")) != TYPE_DICTIONARY:
		return _invalid("invalid_narrative_flags", false)

	if typeof(save_data.get("activated_checkpoints")) != TYPE_ARRAY:
		return _invalid("invalid_activated_checkpoints", false)

	if typeof(save_data.get("settings")) != TYPE_DICTIONARY:
		return _invalid("invalid_settings", false)

	if save_version < CURRENT_SAVE_VERSION:
		return {
			"valid": true,
			"compatible": false,
			"reason": "save_version_outdated:%s" % save_version,
			"save_version": save_version,
		}

	return {
		"valid": true,
		"compatible": true,
		"reason": "",
		"save_version": save_version,
	}


static func _invalid(reason: String, compatible: bool) -> Dictionary:
	return {
		"valid": false,
		"compatible": compatible,
		"reason": reason,
		"save_version": -1,
	}
