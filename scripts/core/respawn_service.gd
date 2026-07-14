extends Node
class_name RespawnService

signal respawn_completed(player: CharacterBody2D)

const SERVICE_GROUP := "respawn_service"

const DEFAULT_DEATH_RESPAWN_DELAY := 0.65
const DEFAULT_FADE_DURATION := 0.22

@export var death_respawn_delay: float = DEFAULT_DEATH_RESPAWN_DELAY
@export var fade_duration: float = DEFAULT_FADE_DURATION

var _services: GameServices = null
var _player: CharacterBody2D = null
var _camera_controller: CameraController = null
var _area_transition_manager: AreaTransitionManager = null
var _dialogue_controller: DialogueController = null
var _boss_health_hud: BossHealthHud = null
var _respawn_pending: bool = false
var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null


func _ready() -> void:
	add_to_group(SERVICE_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fade_overlay()


func bind_from_services(services: GameServices) -> void:
	_services = services
	if services == null:
		return

	_player = services.player
	_camera_controller = services.camera_controller
	_area_transition_manager = services.area_transition_manager
	_dialogue_controller = services.dialogue_controller
	_boss_health_hud = services.boss_health_hud


func request_respawn_after_death(player: CharacterBody2D) -> void:
	if player == null:
		return
	if _respawn_pending:
		return
	_respawn_pending = true
	_run_death_respawn_sequence(player)


func force_respawn_if_dead(player: CharacterBody2D) -> void:
	if player == null or not _is_player_dead(player):
		return
	if _respawn_pending:
		return
	_respawn_pending = true
	_run_death_respawn_sequence(player)


func is_respawn_pending() -> bool:
	return _respawn_pending


func _run_death_respawn_sequence(player: CharacterBody2D) -> void:
	await get_tree().create_timer(maxf(death_respawn_delay, 0.0), true).timeout

	if not is_instance_valid(player) or not _is_player_dead(player):
		_respawn_pending = false
		return

	await _fade_to_black()
	_clear_boss_hud()
	_prepare_encounters_for_respawn()
	_force_end_dialogue(player)

	var respawn_position := _resolve_respawn_position(player)
	respawn_position = _resolve_safe_spawn_position(player, respawn_position)

	player.call(
		"apply_checkpoint",
		respawn_position,
		true,
		false,
		false
	)
	player.call("set_death_vulnerability", false)
	player.call("restore_locomotion_state_after_respawn")
	_snap_camera_to_player()

	await _fade_from_black()
	player.call("release_death_lock_after_respawn")
	player.call("reset_combat_after_respawn")
	_respawn_pending = false
	respawn_completed.emit(player)


func _prepare_encounters_for_respawn() -> void:
	for node in get_tree().get_nodes_in_group(CombatArenaController.CONTROLLER_GROUP):
		if node is CombatArenaController:
			(node as CombatArenaController).reset_active_encounter_for_player_death()

	for node in get_tree().get_nodes_in_group(BossEncounterController.CONTROLLER_GROUP):
		if node is BossEncounterController:
			(node as BossEncounterController).reset_active_encounter_for_player_death()


func _force_end_dialogue(player: CharacterBody2D) -> void:
	if _dialogue_controller != null:
		_dialogue_controller.force_reset()
	elif player != null and player.has_method("exit_dialogue_mode"):
		player.call("exit_dialogue_mode")


func _clear_boss_hud() -> void:
	if _boss_health_hud != null:
		_boss_health_hud.unbind_boss()
		return

	for node in get_tree().get_nodes_in_group(BossHealthHud.HUD_GROUP):
		if node is BossHealthHud:
			(node as BossHealthHud).unbind_boss()
			return


func _resolve_respawn_position(player: CharacterBody2D) -> Vector2:
	if player == null:
		return Vector2.ZERO

	var spawn_position: Vector2 = player.call("get_spawn_position")
	if spawn_position != Vector2.ZERO:
		return spawn_position

	if _area_transition_manager != null:
		var current_area := _area_transition_manager.get_current_area()
		if current_area != null:
			return current_area.get_spawn_position(_area_transition_manager.get_current_spawn_id())

	return player.global_position


func _resolve_safe_spawn_position(player: CharacterBody2D, target_position: Vector2) -> Vector2:
	if player == null:
		return target_position

	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(0.0, -8.0),
		Vector2(0.0, -16.0),
		Vector2(0.0, -32.0),
		Vector2(0.0, -64.0),
	]

	for offset in offsets:
		var candidate := target_position + offset
		player.global_position = candidate
		var motion := PhysicsTestMotionParameters2D.new()
		motion.from = player.global_transform
		motion.motion = Vector2(0.0, 4.0)
		if not PhysicsServer2D.body_test_motion(player.get_rid(), motion):
			return candidate

	return target_position


func _snap_camera_to_player() -> void:
	if _camera_controller == null or _player == null:
		return

	var limits := _camera_controller.area_limits
	if _area_transition_manager != null:
		var current_area := _area_transition_manager.get_current_area()
		if current_area != null:
			limits = current_area.camera_limits

	_camera_controller.configure_for_area(limits, _player, true)


func _is_player_dead(player: CharacterBody2D) -> bool:
	if player == null or not player.has_method("get_health_component"):
		return false

	var health: Node = player.call("get_health_component")
	return health != null and bool(health.get("is_dead"))


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	_fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_layer.visible = false
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func _fade_to_black() -> void:
	if _fade_layer == null or _fade_rect == null:
		return

	_fade_layer.visible = true
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished


func _fade_from_black() -> void:
	if _fade_layer == null or _fade_rect == null:
		return

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	_fade_layer.visible = false
