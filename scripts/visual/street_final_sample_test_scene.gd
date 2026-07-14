extends Node2D

## Isolated comparison for the North Star final sample band (X 100–900).

const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")

@onready var _art_area: StreetArtArea = $ArtStreet
@onready var _player: CharacterBody2D = $Player
@onready var _camera: CameraController = $CameraController
@onready var _mode_label: Label = $UI/ModeLabel

var _mode: StringName = Spec.MODE_FINAL_CANDIDATE


func _ready() -> void:
	_art_area.set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	_mode = Spec.MODE_FINAL_CANDIDATE
	_player.global_position = Vector2(120, 848)
	_camera.configure_for_area(Spec.SAMPLE_CAMERA_LIMITS, _player, true)
	_update_mode_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_mode = _art_area.cycle_presentation_mode()
		if _mode == Spec.MODE_FINAL_CANDIDATE or _mode == Spec.MODE_NORTH_STAR:
			_camera.configure_for_area(Spec.SAMPLE_CAMERA_LIMITS, _player, false)
		else:
			_camera.configure_for_area(Rect2(0, 200, 2400, 1000), _player, false)
		_update_mode_label()
		get_viewport().set_input_as_handled()


func _update_mode_label() -> void:
	if _mode_label == null:
		return
	_mode_label.text = (
		"Final Sample — %s | F cycle greybox/north_star/final | P perf | band X %d–%d"
		% [
			Spec.mode_display_name(_mode),
			int(Spec.SAMPLE_X_MIN),
			int(Spec.SAMPLE_X_MAX),
		]
	)
