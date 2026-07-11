extends CanvasLayer
class_name OptionsMenu

signal closed

enum Section {
	VIDEO,
	AUDIO,
	ACCESSIBILITY,
}

@onready var _root: Control = %OptionsRoot
@onready var _title_label: Label = %OptionsTitle
@onready var _back_button: Button = %BackButton

@onready var _display_mode_option: OptionButton = %DisplayModeOption
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _vsync_check: CheckBox = %VSyncCheck
@onready var _fps_option: OptionButton = %FpsOption
@onready var _ui_scale_slider: HSlider = %UiScaleSlider
@onready var _ui_scale_value: Label = %UiScaleValue

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _voice_slider: HSlider = %VoiceSlider
@onready var _ui_slider: HSlider = %UiSlider
@onready var _ambience_slider: HSlider = %AmbienceSlider

@onready var _shake_slider: HSlider = %ShakeSlider
@onready var _flashes_check: CheckBox = %FlashesCheck
@onready var _telegraph_slider: HSlider = %TelegraphSlider
@onready var _text_speed_slider: HSlider = %TextSpeedSlider
@onready var _instant_text_check: CheckBox = %InstantTextCheck
@onready var _subtitle_slider: HSlider = %SubtitleSlider
@onready var _vibration_check: CheckBox = %VibrationCheck
@onready var _brand_hold_check: CheckBox = %BrandHoldCheck
@onready var _simplified_check: CheckBox = %SimplifiedCheck

var _resolution_indices: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if _root != null:
		_root.visible = false
	_populate_static_options()
	_connect_signals()
	_load_from_settings()


func show_options() -> void:
	_load_from_settings()
	visible = true
	if _root != null:
		_root.visible = true
	if _back_button != null:
		_back_button.grab_focus()


func hide_options() -> void:
	visible = false
	if _root != null:
		_root.visible = false


func _populate_static_options() -> void:
	if _display_mode_option != null:
		_display_mode_option.clear()
		_display_mode_option.add_item("Janela", 0)
		_display_mode_option.add_item("Tela cheia", 1)
		_display_mode_option.add_item("Sem bordas", 2)

	if _resolution_option != null:
		_resolution_option.clear()
		_resolution_indices.clear()
		for index in range(SettingsData.RESOLUTION_PRESETS.size()):
			var preset: Vector2i = SettingsData.RESOLUTION_PRESETS[index]
			_resolution_option.add_item("%dx%d" % [preset.x, preset.y], index)
			_resolution_indices.append(index)

	if _fps_option != null:
		_fps_option.clear()
		for fps in [30, 60, 120, 0]:
			var label := "Sem limite" if fps == 0 else str(fps)
			_fps_option.add_item(label, fps)


func _connect_signals() -> void:
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)
	if _display_mode_option != null:
		_display_mode_option.item_selected.connect(_on_display_mode_changed)
	if _resolution_option != null:
		_resolution_option.item_selected.connect(_on_resolution_changed)
	if _vsync_check != null:
		_vsync_check.toggled.connect(_on_vsync_toggled)
	if _fps_option != null:
		_fps_option.item_selected.connect(_on_fps_changed)
	if _ui_scale_slider != null:
		_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)

	for slider in [_master_slider, _music_slider, _sfx_slider, _voice_slider, _ui_slider, _ambience_slider]:
		if slider != null:
			slider.value_changed.connect(_on_audio_slider_changed.bind(String(slider.name)))

	for slider in [_shake_slider, _telegraph_slider, _text_speed_slider, _subtitle_slider]:
		if slider != null:
			slider.value_changed.connect(_on_accessibility_slider_changed.bind(String(slider.name)))

	for checkbox in [_flashes_check, _instant_text_check, _vibration_check, _brand_hold_check, _simplified_check]:
		if checkbox != null:
			checkbox.toggled.connect(_on_accessibility_toggle_changed.bind(String(checkbox.name)))


func _load_from_settings() -> void:
	if SettingsManager == null:
		return

	var video := SettingsManager.get_video()
	var audio := SettingsManager.get_audio()
	var accessibility := SettingsManager.get_accessibility()

	if _display_mode_option != null:
		match String(video.get("display_mode", SettingsData.DISPLAY_WINDOWED)):
			SettingsData.DISPLAY_FULLSCREEN:
				_display_mode_option.select(1)
			SettingsData.DISPLAY_BORDERLESS:
				_display_mode_option.select(2)
			_:
				_display_mode_option.select(0)

	if _resolution_option != null:
		var resolution_data: Dictionary = video.get("resolution", {"x": 1920, "y": 1080})
		var target := Vector2i(int(resolution_data.get("x", 1920)), int(resolution_data.get("y", 1080)))
		var selected := 0
		for index in range(SettingsData.RESOLUTION_PRESETS.size()):
			if SettingsData.RESOLUTION_PRESETS[index] == target:
				selected = index
				break
		_resolution_option.select(selected)

	if _vsync_check != null:
		_vsync_check.button_pressed = bool(video.get("vsync", true))

	if _fps_option != null:
		var max_fps := int(video.get("max_fps", 60))
		for index in range(_fps_option.item_count):
			if int(_fps_option.get_item_id(index)) == max_fps:
				_fps_option.select(index)
				break

	if _ui_scale_slider != null:
		_ui_scale_slider.value = float(video.get("ui_scale", 1.0))
		_update_ui_scale_label(float(_ui_scale_slider.value))

	_set_slider_value(_master_slider, float(audio.get("master", 1.0)))
	_set_slider_value(_music_slider, float(audio.get("music", 1.0)))
	_set_slider_value(_sfx_slider, float(audio.get("sfx", 1.0)))
	_set_slider_value(_voice_slider, float(audio.get("voice", 1.0)))
	_set_slider_value(_ui_slider, float(audio.get("ui", 1.0)))
	_set_slider_value(_ambience_slider, float(audio.get("ambience", 1.0)))

	_set_slider_value(_shake_slider, float(accessibility.get("screen_shake_intensity", 1.0)))
	_set_slider_value(_telegraph_slider, float(accessibility.get("telegraph_contrast", 1.0)))
	_set_slider_value(_text_speed_slider, float(accessibility.get("text_speed", 1.0)))
	_set_slider_value(_subtitle_slider, float(accessibility.get("subtitle_size", 1.0)))

	if _flashes_check != null:
		_flashes_check.button_pressed = bool(accessibility.get("reduced_flashes", false))
	if _instant_text_check != null:
		_instant_text_check.button_pressed = bool(accessibility.get("instant_text", false))
	if _vibration_check != null:
		_vibration_check.button_pressed = bool(accessibility.get("vibration_enabled", true))
	if _brand_hold_check != null:
		_brand_hold_check.button_pressed = bool(accessibility.get("red_brand_hold_mode", true))
	if _simplified_check != null:
		_simplified_check.button_pressed = bool(accessibility.get("simplified_commands", false))
		if _simplified_check != null:
			_simplified_check.disabled = true
			_simplified_check.tooltip_text = "Preparação futura — ainda não altera o combate."


func _set_slider_value(slider: HSlider, value: float) -> void:
	if slider != null:
		slider.value = value


func _on_back_pressed() -> void:
	FeedbackUiHelper.play_confirm(get_tree())
	if SettingsManager != null:
		SettingsManager.save_settings()
	hide_options()
	closed.emit()


func _on_display_mode_changed(index: int) -> void:
	if SettingsManager == null:
		return
	var mode := SettingsData.DISPLAY_WINDOWED
	match index:
		1:
			mode = SettingsData.DISPLAY_FULLSCREEN
		2:
			mode = SettingsData.DISPLAY_BORDERLESS
	SettingsManager.set_video_field("display_mode", mode)


func _on_resolution_changed(index: int) -> void:
	if SettingsManager == null:
		return
	var preset: Vector2i = SettingsData.RESOLUTION_PRESETS[index]
	SettingsManager.set_video_field("resolution", {"x": preset.x, "y": preset.y})


func _on_vsync_toggled(enabled: bool) -> void:
	if SettingsManager != null:
		SettingsManager.set_video_field("vsync", enabled)


func _on_fps_changed(index: int) -> void:
	if SettingsManager == null or _fps_option == null:
		return
	SettingsManager.set_video_field("max_fps", int(_fps_option.get_item_id(index)))


func _on_ui_scale_changed(value: float) -> void:
	_update_ui_scale_label(value)
	if SettingsManager != null:
		SettingsManager.set_video_field("ui_scale", value)


func _update_ui_scale_label(value: float) -> void:
	if _ui_scale_value != null:
		_ui_scale_value.text = "%.0f%%" % (value * 100.0)


func _on_audio_slider_changed(value: float, slider_name: String) -> void:
	FeedbackUiHelper.play_navigate(get_tree())
	if SettingsManager == null:
		return
	var field := slider_name.replace("Slider", "").to_lower()
	SettingsManager.set_audio_field(field, value)


func _on_accessibility_slider_changed(value: float, slider_name: String) -> void:
	if SettingsManager == null:
		return
	var field_map := {
		"ShakeSlider": "screen_shake_intensity",
		"TelegraphSlider": "telegraph_contrast",
		"TextSpeedSlider": "text_speed",
		"SubtitleSlider": "subtitle_size",
	}
	var field := String(field_map.get(slider_name, ""))
	if field.is_empty():
		return
	SettingsManager.set_accessibility_field(field, value)


func _on_accessibility_toggle_changed(enabled: bool, checkbox_name: String) -> void:
	if SettingsManager == null:
		return
	var field_map := {
		"FlashesCheck": "reduced_flashes",
		"InstantTextCheck": "instant_text",
		"VibrationCheck": "vibration_enabled",
		"BrandHoldCheck": "red_brand_hold_mode",
		"SimplifiedCheck": "simplified_commands",
	}
	var field := String(field_map.get(checkbox_name, ""))
	if field.is_empty():
		return
	SettingsManager.set_accessibility_field(field, enabled)
