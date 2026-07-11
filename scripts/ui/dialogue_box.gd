extends CanvasLayer

var _root: Control
var _panel: PanelContainer
var _portrait_rect: TextureRect
var _portrait_panel: PanelContainer
var _speaker_label: Label
var _body_label: Label
var _advance_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_nodes()
	hide_box()
	if InputDeviceManager != null:
		InputDeviceManager.device_changed.connect(_on_input_device_changed)


func _cache_nodes() -> void:
	_root = get_node_or_null("%DialogueRoot") as Control
	_panel = get_node_or_null("%DialoguePanel") as PanelContainer
	_portrait_rect = get_node_or_null("%PortraitRect") as TextureRect
	_portrait_panel = get_node_or_null("%PortraitPanel") as PanelContainer
	_speaker_label = get_node_or_null("%SpeakerLabel") as Label
	_body_label = get_node_or_null("%BodyLabel") as Label
	_advance_label = get_node_or_null("%AdvanceLabel") as Label


func show_box() -> void:
	visible = true
	if _root != null:
		_root.visible = true
	if _panel != null:
		_panel.visible = true


func hide_box() -> void:
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


var _last_is_last_line: bool = false


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

	if _speaker_label != null:
		_speaker_label.text = speaker

	if _body_label != null:
		_body_label.text = clean_text

	if _advance_label != null:
		if InputDeviceManager != null:
			_advance_label.text = InputDeviceManager.format_dialogue_advance_prompt(is_last_line)
		elif is_last_line:
			_advance_label.text = "[E] Fechar | [Esc] Sair"
		else:
			_advance_label.text = "[E] Continuar | [Esc] Sair"

	_set_portrait(portrait_path)
	return true


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
