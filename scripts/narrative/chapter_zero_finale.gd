extends Node
class_name ChapterZeroFinale

signal finale_started
signal finale_finished

const STEP_DURATION := 2.4
const MAIN_MENU_SCENE := "res://scenes/product/main_menu.tscn"

@onready var _title_label: Label = null
@onready var _body_label: Label = null

var _overlay: CanvasLayer = null
var _playing: bool = false
var _return_button: Button = null
var _voice_label: Label = null


func setup(overlay: CanvasLayer, title_label: Label, body_label: Label) -> void:
	_overlay = overlay
	_title_label = title_label
	_body_label = body_label
	UiThemeHelper.style_end_card_labels(_title_label, _body_label)
	_ensure_return_button()


func play_if_needed(progress_flags: Dictionary) -> void:
	if _playing:
		return
	if bool(progress_flags.get(String(ChapterZeroFlags.FINALE_PLAYED), false)):
		show_end_card()
		return
	_playing = true
	finale_started.emit()
	await _run_sequence()
	_mark_finale_played()
	finale_finished.emit()
	_playing = false


func _run_sequence() -> void:
	if _overlay != null:
		_overlay.visible = true
		_set_return_button_visible(false)

	_play_finale_music()

	var steps: Array[String] = [
		"As pedras tremem. Algo nas profundezas respondeu à queda de Rusk.",
		"A Red Brand pulsa contra o antebraço de Calder — quente, faminta, viva.",
		"Numa câmara distante, uma estátua colossal abre os olhos.",
		"Uma sombra de Mol-Khar atravessa o subterrâneo por um instante.",
		"\"Calder Knox.\" A voz não vem da carne — vem de baixo da cidade.",
		"Entre os pilares, a silhueta de Arcturus Vale observa em silêncio.",
		"Um corredor oculto se abre: o restante de Red Hollow aguarda.",
		"Capítulo Zero concluído. A beta termina aqui — por enquanto.",
	]

	for index in range(steps.size()):
		_present_step(index + 1, steps.size(), steps[index])
		_apply_step_visuals(index + 1)
		await get_tree().create_timer(STEP_DURATION).timeout

	show_end_card()


func _play_finale_music() -> void:
	var music := get_tree().get_first_node_in_group(MusicController.MUSIC_CONTROLLER_GROUP)
	if music != null and music.has_method("play_slot"):
		music.call("play_slot", MusicSlotId.FINALE, 0.48, true)


func _present_step(step_index: int, total_steps: int, text: String) -> void:
	if _title_label != null:
		_title_label.text = "O Sino Antes do Anoitecer (%d/%d)" % [step_index, total_steps]
	if _body_label != null:
		_body_label.text = text


func _apply_step_visuals(step_index: int) -> void:
	match step_index:
		1:
			_request_tremor()
		2:
			for node in get_tree().get_nodes_in_group("chapter_zero_finale_red_brand_glow"):
				if node is CanvasItem:
					(node as CanvasItem).modulate = Color(1, 1, 1, 0.85)
		3:
			for node in get_tree().get_nodes_in_group("chapter_zero_statue_eyes"):
				node.modulate = Color(1, 1, 1, 1)
		4:
			for node in get_tree().get_nodes_in_group("chapter_zero_finale_mol_shadow"):
				if node is CanvasItem:
					(node as CanvasItem).modulate = Color(1, 1, 1, 0.72)
			for node in get_tree().get_nodes_in_group("combat_vfx_spawner"):
				if node.has_method("spawn") and _overlay != null:
					var center := get_viewport().get_visible_rect().get_center()
					node.call("spawn", &"mol_khar", center, 0.7)
					break
		5:
			_show_voice_cue("Calder Knox.")
			var audio := get_tree().get_first_node_in_group(AudioManager.AUDIO_MANAGER_GROUP)
			if audio != null and audio.has_method("play_event"):
				audio.call("play_event", AudioEventId.AMBIENCE_MOL_KHAR, null, 0.45)
		6:
			for node in get_tree().get_nodes_in_group("chapter_zero_finale_arcturus"):
				if node is CanvasItem:
					(node as CanvasItem).modulate = Color(1, 1, 1, 0.9)
		7:
			for node in get_tree().get_nodes_in_group("chapter_zero_hidden_passage"):
				if node is Polygon2D:
					(node as Polygon2D).color = Color(0.85, 0.35, 0.22, 0.9)
			for node in get_tree().get_nodes_in_group("chapter_zero_passage_label"):
				if node is Label:
					(node as Label).text = "Passagem aberta — beta"
		8:
			_hide_voice_cue()


func _request_tremor() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera != null and camera.has_method("request_shake"):
		camera.call("request_shake", 6.0, 0.55)
		return
	for node in get_tree().get_nodes_in_group("camera_controller"):
		if node.has_method("request_shake"):
			node.call("request_shake", 6.0, 0.55)
			return
	# Soft modulate flash fallback when camera rig unavailable (headless).
	if _overlay != null:
		var dim := _overlay.get_node_or_null("Dim") as CanvasItem
		if dim != null:
			dim.modulate = Color(1.1, 1.0, 1.0, 1.0)


func _show_voice_cue(line: String) -> void:
	_ensure_voice_label()
	if _voice_label == null:
		return
	_voice_label.visible = true
	_voice_label.text = line


func _hide_voice_cue() -> void:
	if _voice_label != null:
		_voice_label.visible = false


func show_end_card() -> void:
	_hide_voice_cue()
	if _title_label != null:
		_title_label.text = "Capítulo Zero — Concluído"
	if _body_label != null:
		_body_label.text = (
			"Você investigou Red Hollow, atravessou a igreja, desceu às catacumbas "
			+ "e derrotou Deacon Rusk. Algo antigo despertou — e alguém observa.\n\n"
			+ "Obrigado por jogar a beta técnica de Red Hollow.\n"
			+ "Volte ao menu e use Continuar para retomar o progresso salvo."
		)
	if _overlay != null:
		_overlay.visible = true
	_set_return_button_visible(true)


func _ensure_return_button() -> void:
	if _overlay == null or _return_button != null:
		return
	var vbox := _overlay.get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return
	_return_button = Button.new()
	_return_button.name = "ReturnToMenuButton"
	_return_button.text = "Voltar ao menu"
	_return_button.visible = false
	_return_button.pressed.connect(_on_return_to_menu_pressed)
	UiThemeHelper.style_menu_button(_return_button)
	vbox.add_child(_return_button)


func _ensure_voice_label() -> void:
	if _overlay == null or _voice_label != null:
		return
	_voice_label = Label.new()
	_voice_label.name = "VoiceCue"
	_voice_label.visible = false
	_voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voice_label.add_theme_font_size_override("font_size", 22)
	_voice_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.4, 1.0))
	_voice_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_voice_label.offset_top = 48.0
	_overlay.add_child(_voice_label)


func _set_return_button_visible(is_visible: bool) -> void:
	_ensure_return_button()
	if _return_button != null:
		_return_button.visible = is_visible


func _on_return_to_menu_pressed() -> void:
	if GameBootState != null:
		GameBootState.return_to_main_menu = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _mark_finale_played() -> void:
	for node in get_tree().get_nodes_in_group("narrative_director"):
		if node.has_method("set_narrative_flag"):
			node.call("set_narrative_flag", ChapterZeroFlags.FINALE_PLAYED, true)
			return
