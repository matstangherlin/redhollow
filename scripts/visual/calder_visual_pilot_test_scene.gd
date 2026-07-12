extends Node2D

const PILOT_PROFILE := preload("res://resources/visual/calder_pilot_profile.tres")
const PLACEHOLDER_PROFILE := preload("res://resources/visual/calder_placeholder_profile.tres")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

@onready var _player: CharacterBody2D = $Player
@onready var _visual_controller: PlayerVisualController = $Player/Controllers/PlayerVisualController
@onready var _mode_label: Label = $UI/ModeLabel

var _use_pilot: bool = false


func _ready() -> void:
	_visual_controller.set_profile(PLACEHOLDER_PROFILE)
	_update_mode_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_use_pilot = not _use_pilot
		_visual_controller.set_profile(PILOT_PROFILE if _use_pilot else PLACEHOLDER_PROFILE)
		_update_mode_label()
		get_viewport().set_input_as_handled()


func _update_mode_label() -> void:
	if _mode_label == null:
		return
	_mode_label.text = (
		"Calder Visual Pilot Test — modo: %s | F alterna PLACEHOLDER/PILOT | A/D mover"
		% ("PILOT" if _use_pilot else "PLACEHOLDER")
	)
