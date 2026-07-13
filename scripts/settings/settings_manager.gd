extends Node

signal settings_loaded
signal settings_saved
signal settings_changed

const SETTINGS_PATH := SettingsData.SETTINGS_PATH

var current: Dictionary = SettingsData.create_default()


func _ready() -> void:
	load_settings()
	apply_all()


func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		current = SettingsData.create_default()
		settings_loaded.emit()
		return false

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		push_warning("SettingsManager failed to open %s" % SETTINGS_PATH)
		current = SettingsData.create_default()
		settings_loaded.emit()
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed == null:
		push_warning("SettingsManager found invalid JSON in %s" % SETTINGS_PATH)
		current = SettingsData.create_default()
		settings_loaded.emit()
		return false

	var validation := SettingsData.validate(parsed)
	if not validation.get("valid", false):
		push_warning(
			"Settings validation failed (%s). Using defaults."
			% String(validation.get("reason", "unknown"))
		)
		current = SettingsData.create_default()
		settings_loaded.emit()
		return false

	current = SettingsData.merge_with_defaults(parsed as Dictionary)
	settings_loaded.emit()
	return true


func save_settings() -> bool:
	var json_text := JSON.stringify(current, "\t")
	var temp_path := "%s.tmp" % SETTINGS_PATH
	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		push_warning("SettingsManager failed to write temp settings file.")
		return false

	temp_file.store_string(json_text)
	temp_file.close()

	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)

	if DirAccess.rename_absolute(temp_path, SETTINGS_PATH) != OK:
		push_warning("SettingsManager failed to finalize settings file.")
		return false

	settings_saved.emit()
	return true


func apply_all() -> void:
	apply_video()
	apply_audio()
	settings_changed.emit()


func apply_video() -> void:
	var video: Dictionary = current.get("video", {})
	var display_mode := String(video.get("display_mode", SettingsData.DISPLAY_WINDOWED))
	var resolution_data: Dictionary = video.get("resolution", {"x": 1920, "y": 1080})
	var resolution := Vector2i(
		int(resolution_data.get("x", 1920)),
		int(resolution_data.get("y", 1080))
	)
	var vsync_enabled := bool(video.get("vsync", true))
	var max_fps := int(video.get("max_fps", 60))
	var ui_scale := float(video.get("ui_scale", 1.0))

	match display_mode:
		SettingsData.DISPLAY_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		SettingsData.DISPLAY_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	Engine.max_fps = maxi(max_fps, 0)

	if get_tree() != null:
		var root := get_tree().root as Window
		if root != null:
			root.content_scale_factor = clampf(ui_scale, 0.75, 2.0)


func apply_audio() -> void:
	var audio: Dictionary = current.get("audio", {})
	for bus_name in SettingsData.AUDIO_BUS_NAMES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var linear := float(audio.get(bus_name.to_lower(), 1.0))
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear, 0.0, 1.0)))


func get_accessibility() -> Dictionary:
	return (current.get("accessibility", {}) as Dictionary).duplicate(true)


func get_video() -> Dictionary:
	return (current.get("video", {}) as Dictionary).duplicate(true)


func get_audio() -> Dictionary:
	return (current.get("audio", {}) as Dictionary).duplicate(true)


func set_video_field(field_name: String, value: Variant) -> void:
	var video: Dictionary = current.get("video", {})
	video[field_name] = value
	current["video"] = video
	apply_video()
	settings_changed.emit()


func set_audio_field(field_name: String, value: Variant) -> void:
	var audio: Dictionary = current.get("audio", {})
	audio[field_name] = value
	current["audio"] = audio
	apply_audio()
	settings_changed.emit()


func set_accessibility_field(field_name: String, value: Variant) -> void:
	var accessibility: Dictionary = current.get("accessibility", {})
	accessibility[field_name] = value
	current["accessibility"] = accessibility
	settings_changed.emit()


func get_screen_shake_multiplier() -> float:
	var accessibility := get_accessibility()
	return clampf(float(accessibility.get("screen_shake_intensity", 1.0)), 0.0, 1.0)


func is_red_brand_hold_mode() -> bool:
	return bool(get_accessibility().get("red_brand_hold_mode", true))


func is_reduced_flashes_enabled() -> bool:
	return bool(get_accessibility().get("reduced_flashes", false))


func is_reduced_particles_enabled() -> bool:
	return bool(get_accessibility().get("reduced_particles", false))


func is_reduced_distortion_enabled() -> bool:
	return bool(get_accessibility().get("reduced_distortion", false))


func is_reduced_extreme_contrast_enabled() -> bool:
	return bool(get_accessibility().get("reduced_extreme_contrast", false))


func is_chromatic_aberration_disabled() -> bool:
	return bool(get_accessibility().get("disable_chromatic_aberration", false))


func get_telegraph_contrast_multiplier() -> float:
	return clampf(float(get_accessibility().get("telegraph_contrast", 1.0)), 0.5, 2.0)


func get_text_speed_multiplier() -> float:
	return clampf(float(get_accessibility().get("text_speed", 1.0)), 0.25, 3.0)


func is_instant_text_enabled() -> bool:
	return bool(get_accessibility().get("instant_text", false))


func get_subtitle_scale() -> float:
	return clampf(float(get_accessibility().get("subtitle_size", 1.0)), 0.75, 2.0)


func is_vibration_enabled() -> bool:
	return bool(get_accessibility().get("vibration_enabled", true))
