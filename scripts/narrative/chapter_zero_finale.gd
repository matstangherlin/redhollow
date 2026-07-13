extends Node
class_name ChapterZeroFinale

signal finale_started
signal finale_finished

const STEP_DURATION := 2.4

@onready var _title_label: Label = null
@onready var _body_label: Label = null

var _overlay: CanvasLayer = null
var _playing: bool = false


func setup(overlay: CanvasLayer, title_label: Label, body_label: Label) -> void:
	_overlay = overlay
	_title_label = title_label
	_body_label = body_label


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


func _present_step(step_index: int, total_steps: int, text: String) -> void:
	if _title_label != null:
		_title_label.text = "O Sino Antes do Anoitecer (%d/%d)" % [step_index, total_steps]
	if _body_label != null:
		_body_label.text = text


func _apply_step_visuals(step_index: int) -> void:
	match step_index:
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


func show_end_card() -> void:
	if _title_label != null:
		_title_label.text = "Capítulo Zero — Concluído"
	if _body_label != null:
		_body_label.text = (
			"Você investigou Red Hollow, atravessou a igreja, desceu às catacumbas "
			+ "e derrotou Deacon Rusk. Algo antigo despertou — e alguém observa.\n\n"
			+ "Obrigado por jogar a beta técnica de Red Hollow."
		)
	if _overlay != null:
		_overlay.visible = true


func _mark_finale_played() -> void:
	for node in get_tree().get_nodes_in_group("narrative_director"):
		if node.has_method("set_narrative_flag"):
			node.call("set_narrative_flag", ChapterZeroFlags.FINALE_PLAYED, true)
			return
