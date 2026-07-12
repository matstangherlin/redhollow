extends Node2D

const ROOM_A := preload("res://scenes/environment/modular/kit_room_saloon_front.tscn")
const ROOM_B := preload("res://scenes/environment/modular/kit_room_alley_corner.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMERA_SCENE := preload("res://scenes/core/camera_controller.tscn")

@onready var _world_host: Node2D = $WorldHost
@onready var _player: CharacterBody2D = $Player
@onready var _camera: CameraController = $CameraController
@onready var _label: Label = $UI/ModeLabel

var _current_room: KitModularRoom = null
var _use_room_a: bool = true


func _ready() -> void:
	await _load_room(ROOM_A, &"default")
	_label.text = "Modular Kit Test — Enter alterna salas | F debug | A/D mover"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_swap_rooms()
		get_viewport().set_input_as_handled()


func _swap_rooms() -> void:
	if _use_room_a:
		_load_room(ROOM_B, &"default")
	else:
		_load_room(ROOM_A, &"from_alley" if not _use_room_a else &"default")
	_use_room_a = not _use_room_a


func _load_room(scene: PackedScene, spawn_id: StringName) -> void:
	for child in _world_host.get_children():
		child.queue_free()

	var room: KitModularRoom = scene.instantiate() as KitModularRoom
	_world_host.add_child(room)
	await get_tree().process_frame
	_current_room = room

	var spawn_pos := room.get_spawn_position(spawn_id)
	_player.global_position = spawn_pos
	_camera.configure_for_area(room.camera_limits, _player, true)
	_label.text = "Sala: %s | Enter alterna | exits ativos" % room.area_display_name

	for exit in room.get_exits():
		var callable := Callable(self, "_on_exit_triggered")
		if not exit.exit_triggered.is_connected(callable):
			exit.exit_triggered.connect(callable)


func _on_exit_triggered(exit: AreaExit) -> void:
	if _current_room == null:
		return
	if exit.target_scene.ends_with("kit_room_alley_corner.tscn"):
		_load_room(ROOM_B, exit.target_spawn_id)
		_use_room_a = false
	elif exit.target_scene.ends_with("kit_room_saloon_front.tscn"):
		_load_room(ROOM_A, exit.target_spawn_id)
		_use_room_a = true
