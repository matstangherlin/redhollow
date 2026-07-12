extends Node
class_name AreaTransitionManager

signal area_changed(area_id: StringName, area_scene_path: String)
signal area_loaded(area: AreaRoot)
signal area_unloaded(area: AreaRoot)
signal transition_started(from_area_id: StringName, to_scene_path: String)
signal transition_finished(area_id: StringName, spawn_id: StringName)

const MANAGER_GROUP := "area_transition_manager"

const STREET_SCENE := "res://scenes/areas/street_test.tscn"
const CHURCH_SCENE := "res://scenes/areas/church_entrance_test.tscn"
const UNDERGROUND_SCENE := "res://scenes/areas/underground_test.tscn"

@export var world_host_path: NodePath
@export var player_path: NodePath
@export var camera_controller_path: NodePath
@export var initial_area_scene: PackedScene
@export var initial_spawn_id: StringName = &"default"
@export var transition_pause_seconds: float = 0.18

var is_transitioning: bool = false

var _game_root: Node = null
var _game_services: GameServices = null
var _world_host: Node2D = null
var _player: CharacterBody2D = null
var _camera_controller: CameraController = null
var _progression: ProgressionComponent = null
var _current_area: AreaRoot = null
var _current_spawn_id: StringName = &"default"
var _initialized: bool = false
var _lock_manager: GameplayLockManager = null
var _transition_lock_token: GameplayLockToken = null


func _ready() -> void:
	if _has_duplicate_manager():
		push_warning("Duplicate AreaTransitionManager detected. Removing duplicate node.")
		queue_free()
		return

	add_to_group(MANAGER_GROUP)


func initialize(game_root: Node, services: GameServices = null) -> void:
	if _initialized:
		return

	_game_root = game_root
	_game_services = services
	_world_host = get_node_or_null(world_host_path) as Node2D
	_player = get_node_or_null(player_path) as CharacterBody2D
	_camera_controller = get_node_or_null(camera_controller_path) as CameraController

	if _game_services != null:
		if _game_services.progression != null:
			_progression = _game_services.progression
		if _game_services.gameplay_lock_manager != null:
			_lock_manager = _game_services.gameplay_lock_manager
		if _game_services.player != null:
			_player = _game_services.player
		if _game_services.camera_controller != null:
			_camera_controller = _game_services.camera_controller
		if _game_services.world_host != null:
			_world_host = _game_services.world_host

	if _progression == null:
		_progression = _find_progression_component()

	_initialized = true

	if _current_area == null:
		var starting_scene := initial_area_scene
		if starting_scene == null:
			starting_scene = load(STREET_SCENE) as PackedScene
		_load_area_instance(starting_scene, initial_spawn_id, false)


func get_current_area() -> AreaRoot:
	return _current_area


func get_current_area_id() -> StringName:
	return _current_area.area_id if _current_area != null else &""


func get_current_area_scene_path() -> String:
	if _current_area == null:
		return STREET_SCENE
	return _current_area.get_area_scene_path()


func get_current_spawn_id() -> StringName:
	return _current_spawn_id


func restore_area_from_save(area_scene_path: String, spawn_position: Vector2) -> void:
	if area_scene_path.is_empty():
		area_scene_path = STREET_SCENE

	var packed_scene := load(area_scene_path) as PackedScene
	if packed_scene == null:
		push_warning("Could not load saved area scene: %s" % area_scene_path)
		packed_scene = load(STREET_SCENE) as PackedScene

	_swap_area_scene(packed_scene, &"default", false)
	if _player != null:
		_player.global_position = spawn_position
		_player.set_spawn_position(spawn_position)
	_configure_camera_for_current_area(true)


func request_transition(exit: AreaExit, _body: Node) -> void:
	if is_transitioning or exit == null:
		return

	if not exit.can_be_used(_progression):
		push_warning(exit.get_blocked_reason(_progression))
		return

	var packed_scene := load(exit.target_scene) as PackedScene
	if packed_scene == null:
		push_warning("Area exit '%s' points to missing scene: %s" % [String(exit.exit_id), exit.target_scene])
		return

	var registry := ContentRegistry.get_active()
	if registry != null and not registry.can_load_area_scene(exit.target_scene):
		push_warning(
			"Area exit '%s' blocked — scene not in active manifest: %s"
			% [String(exit.exit_id), exit.target_scene]
		)
		return

	is_transitioning = true
	_perform_transition(
		packed_scene,
		exit.target_spawn_id,
		exit.transition_type,
		_current_area.area_id if _current_area != null else &""
	)


func jump_to_area(target_scene: PackedScene, spawn_id: StringName = &"default") -> void:
	if is_transitioning or target_scene == null:
		return
	is_transitioning = true
	_lock_player()
	_load_area_instance(target_scene, spawn_id, true)
	is_transitioning = false


func _perform_transition(
	target_scene: PackedScene,
	target_spawn_id: StringName,
	transition_type: int,
	from_area_id: StringName
) -> void:
	if _current_area == null and not is_transitioning:
		is_transitioning = true

	transition_started.emit(from_area_id, target_scene.resource_path)
	_lock_player()

	match transition_type:
		1:
			await get_tree().create_timer(transition_pause_seconds, true).timeout
		_:
			await get_tree().create_timer(transition_pause_seconds, true).timeout

	_load_area_instance(target_scene, target_spawn_id, true)
	is_transitioning = false
	transition_finished.emit(get_current_area_id(), target_spawn_id)


func _load_area_instance(packed_scene: PackedScene, spawn_id: StringName, animate_camera: bool) -> void:
	if packed_scene == null:
		return

	_swap_area_scene(packed_scene, spawn_id, animate_camera)
	_notify_world_rebound()


func _swap_area_scene(packed_scene: PackedScene, spawn_id: StringName, animate_camera: bool) -> void:
	_clear_current_area()

	var area_instance := packed_scene.instantiate()
	if not (area_instance is AreaRoot):
		push_warning("Area scene root must extend AreaRoot: %s" % packed_scene.resource_path)
		area_instance.queue_free()
		return

	_world_host.add_child(area_instance)
	_current_area = area_instance as AreaRoot
	_current_spawn_id = spawn_id
	_connect_area_exits(_current_area)
	_place_player_at_spawn(spawn_id)
	_apply_area_settings_to_player()
	_configure_camera_for_current_area(animate_camera)
	area_changed.emit(_current_area.area_id, _current_area.get_area_scene_path())
	area_loaded.emit(_current_area)


func _clear_current_area() -> void:
	if _current_area == null:
		return

	var unloading_area := _current_area
	unloading_area.prepare_for_unload()
	area_unloaded.emit(unloading_area)

	for exit in unloading_area.get_exits():
		if exit.is_connected("exit_triggered", Callable(self, "_on_exit_triggered")):
			exit.disconnect("exit_triggered", Callable(self, "_on_exit_triggered"))

	if _game_services != null:
		_game_services.on_area_unloaded(unloading_area)

	unloading_area.queue_free()
	_current_area = null


func _connect_area_exits(area: AreaRoot) -> void:
	for exit in area.get_exits():
		if not exit.is_connected("exit_triggered", Callable(self, "_on_exit_triggered")):
			exit.connect("exit_triggered", Callable(self, "_on_exit_triggered"))


func _on_exit_triggered(exit: AreaExit, body: Node) -> void:
	if is_transitioning:
		return
	request_transition(exit, body)


func _place_player_at_spawn(spawn_id: StringName) -> void:
	if _player == null or _current_area == null:
		return

	var spawn_position: Vector2 = _current_area.get_spawn_position(spawn_id)
	_player.global_position = spawn_position
	_player.set_spawn_position(spawn_position)


func _apply_area_settings_to_player() -> void:
	if _player == null or _current_area == null:
		return

	_player.apply_area_settings(
		{
			"fall_recovery_y": _current_area.fall_recovery_y,
			"area_id": _current_area.area_id,
		}
	)


func _configure_camera_for_current_area(animate_camera: bool) -> void:
	if _camera_controller == null or _current_area == null:
		return

	_camera_controller.configure_for_area(_current_area.camera_limits, _player, not animate_camera)


func _lock_player() -> void:
	_bind_lock_manager()
	if _lock_manager != null:
		if _transition_lock_token == null or not _transition_lock_token.valid:
			_transition_lock_token = _lock_manager.acquire_lock(
				GameplayLockManager.LockReason.AREA_TRANSITION,
				self
			)
		return

	if _player != null:
		_player.enter_transition_mode()


func _unlock_player() -> void:
	if _lock_manager != null:
		if _transition_lock_token != null and _transition_lock_token.valid:
			_lock_manager.release_lock(_transition_lock_token)
		_transition_lock_token = null
		return

	if _player != null:
		_player.exit_transition_mode()


func _bind_lock_manager() -> void:
	if _lock_manager != null:
		return

	if _game_services != null and _game_services.gameplay_lock_manager != null:
		_lock_manager = _game_services.gameplay_lock_manager
		return

	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("gameplay_lock_manager"):
		if node is GameplayLockManager:
			_lock_manager = node as GameplayLockManager
			return


func _notify_world_rebound() -> void:
	_force_close_dialogue()
	_unlock_player()

	if _game_services != null:
		_game_services.on_area_loaded(_current_area)

	if _current_area != null:
		for node in get_tree().get_nodes_in_group("narrative_director"):
			if node.has_method("notify_area_entered"):
				node.call("notify_area_entered", _current_area.area_id)


func _find_progression_component() -> ProgressionComponent:
	if _game_services != null and _game_services.progression != null:
		return _game_services.progression

	for node in get_tree().get_nodes_in_group("progression_component"):
		if node is ProgressionComponent:
			return node
	return null


func _force_close_dialogue() -> void:
	if _game_services != null and _game_services.dialogue_controller != null:
		_game_services.dialogue_controller.force_reset()
		return

	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node is DialogueController:
			(node as DialogueController).force_reset()
			return


func _has_duplicate_manager() -> bool:
	for node in get_tree().get_nodes_in_group(MANAGER_GROUP):
		if node != self:
			return true
	return false
