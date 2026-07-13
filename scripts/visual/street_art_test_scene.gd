extends Node2D

const STREET_ART := preload("res://scenes/areas/vertical_slice_street_art.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMERA_SCENE := preload("res://scenes/core/camera_controller.tscn")

@onready var _art_area: StreetArtArea = $ArtStreet
@onready var _player: CharacterBody2D = $Player
@onready var _camera: CameraController = $CameraController
@onready var _mode_label: Label = $UI/ModeLabel

var _use_art: bool = true


func _ready() -> void:
	_art_area.set_visual_mode(true)
	_player.global_position = Vector2(120, 848)
	_camera.configure_for_area(Rect2(0, 200, 2400, 1000), _player, true)
	_update_mode_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_use_art = not _use_art
		_art_area.set_visual_mode(_use_art)
		_update_mode_label()
		get_viewport().set_input_as_handled()


func _update_mode_label() -> void:
	if _mode_label == null:
		return
	_mode_label.text = (
		"Street Art Test — modo: %s | F greybox/art | P perf overlay | A/D mover"
		% ("ART PILOT" if _use_art else "GREYBOX")
	)
