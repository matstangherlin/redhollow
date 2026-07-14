extends CanvasLayer

## Dialogue presentation with accessibility (text speed, instant text, subtitle scale).

const CHARS_PER_SECOND_BASE := 42.0

var _root: Control
var _panel: PanelContainer
var _portrait_rect: TextureRect
var _portrait_panel: PanelContainer
var _speaker_label: Label
var _body_label: Label
var _advance_label: Label

var _last_is_last_line: bool = false
var _typewriter_tween: Tween = null
var _full_body_text: String = ""
var _typewriter_finished: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_nodes()
	_apply_presentation_theme()
	hide_box()
	if InputDeviceManager != null:
		InputDeviceManager.device_changed.connect(_on_input_device_changed)
	var settings := FeedbackSettingsAccess.get_manager()
	if settings != null and settings.has_signal("settings_changed"):
		if not settings.settings_changed.is_connected(_on_settings_changed):
			settings.settings_changed.connect(_on_settings_changed)


func _cache_nodes() -> void:
	_root = get_node_or_null("%DialogueRoot") as Control
	_panel = get_node_or_null("%DialoguePanel") as PanelContainer
	_portrait_rect = get_node_or_null("%PortraitRect") as TextureRect
	_portrait_panel = get_node_or_null("%PortraitPanel") as PanelContainer
	_speaker_label = get_node_or_null("%SpeakerLabel") as Label
	_body_label = get_node_or_null("%BodyLabel") as Label
	_advance_label = get_node_or_null("%AdvanceLabel") as Label


func _apply_presentation_theme() -> void:
	if _panel != null:
		UiThemeHelper.style_dialogue_panel(_panel)
	_apply_subtitle_scale()


func _apply_subtitle_scale() -> void:
	var scale := 1.0
	var manager := FeedbackSettingsAccess.get_manager()
	if manager != null and manager.has_method("get_subtitle_scale"):
		scale = float(manager.call("get_subtitle_scale"))
	if _body_label != null:
		_body_label.add_theme_font_size_override("font_size", int(roundf(16.0 * scale)))
		_body_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.80, 1.0))
	if _speaker_label != null:
		_speaker_label.add_theme_font_size_override("font_size", int(roundf(15.0 * scale)))
		_speaker_label.add_theme_color_override("font_color", Color(0.94, 0.72, 0.48, 1.0))
	if _advance_label != null:
		_advance_label.add_theme_font_size_override("font_size", int(roundf(12.0 * scale)))


func _on_settings_changed() -> void:
	_apply_subtitle_scale()


func show_box() -> void:
	visible = true
	if _root != null:
		_root.visible = true
	if _panel != null:
		_panel.visible = true


func hide_box() -> void:
	_stop_typewriter()
	visible = false
	if _root != null:
		_root.visible = false
	if _panel != null:
		_panel.visible = false
	if _speaker_label != null:
		_speaker_label.text = ""
	if _body_label != null:
		_body_label.text = ""
	if _advance_label != null:
		_advance_label.text = ""
	_set_portrait("")


func is_box_visible() -> bool:
	return visible and (_root == null or _root.visible)


func is_typewriter_finished() -> bool:
	return _typewriter_finished


func skip_typewriter() -> void:
	if _typewriter_finished or _body_label == null:
		return
	_stop_typewriter()
	_body_label.visible_characters = -1
	_body_label.text = _full_body_text
	_typewriter_finished = true


func _on_input_device_changed(_device_kind: int) -> void:
	if not is_box_visible() or _advance_label == null:
		return
	if InputDeviceManager != null:
		_advance_label.text = InputDeviceManager.format_dialogue_advance_prompt(_last_is_last_line)


func present_line(speaker: String, text: String, portrait_path: String, is_last_line: bool) -> bool:
	_cache_nodes()
	_last_is_last_line = is_last_line
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		push_warning("Refusing to present an empty dialogue line.")
		hide_box()
		return false

	show_box()
	_apply_subtitle_scale()

	if _speaker_label != null:
		_speaker_label.text = speaker

	_full_body_text = clean_text
	_start_typewriter(clean_text)

	if _advance_label != null:
		if InputDeviceManager != null:
			_advance_label.text = InputDeviceManager.format_dialogue_advance_prompt(is_last_line)
		elif is_last_line:
			_advance_label.text = "[E] Fechar | [Esc] Sair"
		else:
			_advance_label.text = "[E] Continuar | [Esc] Sair"

	_set_portrait(portrait_path)
	return true


func _start_typewriter(clean_text: String) -> void:
	_stop_typewriter()
	if _body_label == null:
		_typewriter_finished = true
		return

	_body_label.text = clean_text
	var instant := false
	var text_speed := 1.0
	var manager := FeedbackSettingsAccess.get_manager()
	if manager != null:
		if manager.has_method("is_instant_text_enabled"):
			instant = bool(manager.call("is_instant_text_enabled"))
		if manager.has_method("get_text_speed_multiplier"):
			text_speed = float(manager.call("get_text_speed_multiplier"))
		elif manager.has_method("get_text_speed"):
			text_speed = float(manager.call("get_text_speed"))

	if instant or clean_text.length() <= 1:
		_body_label.visible_characters = -1
		_typewriter_finished = true
		return

	_body_label.visible_characters = 0
	_typewriter_finished = false
	var duration := float(clean_text.length()) / maxf(CHARS_PER_SECOND_BASE * text_speed, 8.0)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(
		_body_label,
		"visible_characters",
		clean_text.length(),
		duration
	)
	_typewriter_tween.finished.connect(func() -> void:
		_typewriter_finished = true
		if _body_label != null:
			_body_label.visible_characters = -1
	)


func _stop_typewriter() -> void:
	if _typewriter_tween != null and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_typewriter_tween = null


func _set_portrait(portrait_path: String) -> void:
	if _portrait_rect == null or _portrait_panel == null:
		return

	if portrait_path.is_empty():
		_portrait_panel.visible = false
		_portrait_rect.texture = null
		return

	if not ResourceLoader.exists(portrait_path):
		push_warning("Dialogue portrait not found: %s" % portrait_path)
		_portrait_panel.visible = false
		_portrait_rect.texture = null
		return

	var texture := load(portrait_path) as Texture2D
	if texture == null:
		push_warning("Dialogue portrait failed to load: %s" % portrait_path)
		_portrait_panel.visible = false
		_portrait_rect.texture = null
		return

	_portrait_rect.texture = texture
	_portrait_panel.visible = true
