extends RefCounted
class_name SettingsData

const CURRENT_SETTINGS_VERSION := 1
const SETTINGS_PATH := "user://settings.json"

const DISPLAY_WINDOWED := "windowed"
const DISPLAY_FULLSCREEN := "fullscreen"
const DISPLAY_BORDERLESS := "borderless"

const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const AUDIO_BUS_NAMES: PackedStringArray = [
	"Master",
	"Music",
	"SFX",
	"Voice",
	"UI",
	"Ambience",
]


static func create_default() -> Dictionary:
	return {
		"settings_version": CURRENT_SETTINGS_VERSION,
		"video": {
			"display_mode": DISPLAY_WINDOWED,
			"resolution": {"x": 1920, "y": 1080},
			"vsync": true,
			"max_fps": 60,
			"ui_scale": 1.0,
		},
		"audio": {
			"master": 1.0,
			"music": 1.0,
			"sfx": 1.0,
			"voice": 1.0,
			"ui": 1.0,
			"ambience": 1.0,
		},
		"accessibility": {
			"screen_shake_intensity": 1.0,
			"reduced_flashes": false,
			"telegraph_contrast": 1.0,
			"text_speed": 1.0,
			"instant_text": false,
			"subtitle_size": 1.0,
			"vibration_enabled": true,
			"red_brand_hold_mode": true,
			"simplified_commands": false,
		},
	}


static func validate(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return _invalid("root_not_dictionary")

	var settings := data as Dictionary
	if not settings.has("settings_version"):
		return _invalid("missing_settings_version")

	var version := int(settings.get("settings_version", 0))
	if version <= 0:
		return _invalid("invalid_settings_version")

	if version > CURRENT_SETTINGS_VERSION:
		return _invalid("settings_version_too_new")

	if typeof(settings.get("video", null)) != TYPE_DICTIONARY:
		return _invalid("invalid_video")

	if typeof(settings.get("audio", null)) != TYPE_DICTIONARY:
		return _invalid("invalid_audio")

	if typeof(settings.get("accessibility", null)) != TYPE_DICTIONARY:
		return _invalid("invalid_accessibility")

	return {
		"valid": true,
		"compatible": version == CURRENT_SETTINGS_VERSION,
		"reason": "",
		"settings_version": version,
	}


static func merge_with_defaults(data: Dictionary) -> Dictionary:
	var merged := create_default()
	_merge_section(merged, data, "video")
	_merge_section(merged, data, "audio")
	_merge_section(merged, data, "accessibility")
	if data.has("settings_version"):
		merged["settings_version"] = int(data.get("settings_version"))
	return merged


static func _merge_section(target: Dictionary, source: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	var section: Variant = source.get(key)
	if typeof(section) != TYPE_DICTIONARY:
		return
	var target_section: Dictionary = target.get(key, {})
	for field in (section as Dictionary).keys():
		target_section[field] = section[field]
	target[key] = target_section


static func _invalid(reason: String) -> Dictionary:
	return {
		"valid": false,
		"compatible": false,
		"reason": reason,
		"settings_version": -1,
	}
