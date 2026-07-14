extends Node2D
class_name CombatArenaController

signal arena_activated(arena_id: StringName)
signal arena_completed(arena_id: StringName)
signal arena_message_shown(message: String)
signal arena_integrity_failed(arena_id: StringName, reason: String)
signal arena_debug_recovered(arena_id: StringName)
signal arena_state_changed(previous_state: int, new_state: int)

enum ArenaState {
	INACTIVE,
	ACTIVATION_REQUESTED,
	CLOSING_GATES,
	SPAWNING,
	ACTIVE,
	RESETTING,
	COMPLETED,
}

const CONTROLLER_GROUP := "combat_arena_controller"
const PLAYER_GROUP := "player"
const STYLE_MANAGER_GROUP := "style_manager"
const PROGRESSION_GROUP := "progression_component"
const ARENA_ENEMY_META := "combat_arena_id"
const ARENA_OWNER_META := "combat_arena_owner_id"

@export var arena_id: StringName = &"arena_01"
@export var activation_zone_path: NodePath
@export var gate_paths: Array[NodePath] = []
@export var blocked_exit_paths: Array[NodePath] = []
@export var enemy_spawn_paths: Array[NodePath] = []
@export var enemies_container_path: NodePath
@export var enemy_scene: PackedScene
@export var style_completion_bonus: float = 75.0
@export var completion_flag_id: StringName = &""
@export var feedback_label_path: NodePath
@export var status_message_duration: float = 2.8
## Delay between successive enemy spawns during SPAWNING (seconds). 0 = simultaneous.
@export var spawn_stagger_seconds: float = 0.0

var state: ArenaState = ArenaState.INACTIVE

var _activation_zone: Area2D = null
var _enemies_container: Node = null
var _feedback_label: Label = null
var _gates: Array[CombatArenaGate] = []
var _blocked_exits: Array[AreaExit] = []
var _spawn_points: Array[Node2D] = []
var _tracked_enemies: Array[Node] = []
var _defeated_instance_ids: Dictionary = {}
var _spawned_count: int = 0
var _status_timer: SceneTreeTimer = null
var _integrity_compromised: bool = false
var _lifecycle_generation: int = 0
var _completion_committed: bool = false
var _area_unloading: bool = false
var _activation_requires_exit: bool = false
var _pending_reset_message: String = ""
var _style_manager: StyleManager = null
var _progression: ProgressionComponent = null


func _ready() -> void:
	add_to_group(CONTROLLER_GROUP)
	_resolve_nodes()

	if _is_marked_complete_in_progression():
		_apply_completed_state(false)
		return

	_set_state(ArenaState.INACTIVE)
	if _activation_zone != null:
		_activation_zone.set_deferred("monitoring", false)
		if not _activation_zone.body_entered.is_connected(_on_activation_body_entered):
			_activation_zone.body_entered.connect(_on_activation_body_entered)
		if not _activation_zone.body_exited.is_connected(_on_activation_body_exited):
			_activation_zone.body_exited.connect(_on_activation_body_exited)


func arm_activation_monitoring() -> void:
	if state != ArenaState.INACTIVE or _area_unloading:
		return
	if _activation_zone == null:
		return
	_activation_zone.set_deferred("monitoring", true)


func bind_combat_services(
	style_manager: StyleManager = null,
	progression: ProgressionComponent = null
) -> void:
	_style_manager = style_manager
	_progression = progression
	if state == ArenaState.INACTIVE and _is_marked_complete_in_progression():
		_apply_completed_state(false)


func request_activation(body: Node) -> bool:
	if state != ArenaState.INACTIVE or _area_unloading or _activation_requires_exit:
		return false
	if body == null or not body.is_in_group(PLAYER_GROUP):
		return false

	_lifecycle_generation += 1
	var generation := _lifecycle_generation
	_integrity_compromised = false
	_completion_committed = false
	_pending_reset_message = ""
	_set_state(ArenaState.ACTIVATION_REQUESTED)
	_disable_activation_zone()
	call_deferred("_await_activation_boundary", generation)
	return true


func on_area_unloading() -> void:
	if _area_unloading:
		return
	_area_unloading = true
	_lifecycle_generation += 1
	_disable_activation_zone()
	_set_state(ArenaState.RESETTING)
	_clear_runtime_projectiles()
	_despawn_owned_enemies()
	_clear_runtime_tracking()


func debug_force_recover_arena() -> void:
	if state != ArenaState.ACTIVE:
		return

	_integrity_compromised = false
	_tracked_enemies = _tracked_enemies.filter(
		func(enemy: Node) -> bool:
			return is_instance_valid(enemy) and _is_arena_owned_enemy(enemy)
	)
	_show_status_message("Debug: arena recuperada")
	arena_debug_recovered.emit(arena_id)


func reset_active_encounter_for_player_death() -> void:
	if state not in [
		ArenaState.ACTIVATION_REQUESTED,
		ArenaState.CLOSING_GATES,
		ArenaState.SPAWNING,
		ArenaState.ACTIVE,
	]:
		return
	_activation_requires_exit = true
	_request_reset(&"player_death", "")


func try_complete_if_enemies_cleared() -> bool:
	if _integrity_compromised or state != ArenaState.ACTIVE:
		return false
	if _spawned_count <= 0 or _defeated_instance_ids.size() < _spawned_count:
		return false
	if get_remaining_enemy_count() > 0:
		return false
	_complete_arena()
	return state == ArenaState.COMPLETED


func is_blocking_exits() -> bool:
	return state in [ArenaState.CLOSING_GATES, ArenaState.SPAWNING, ArenaState.ACTIVE]


func get_remaining_enemy_count() -> int:
	var alive := 0
	for enemy in _tracked_enemies:
		if not is_instance_valid(enemy) or not _is_arena_owned_enemy(enemy):
			continue
		var health := _find_health_component(enemy)
		if health == null or not health.is_dead:
			alive += 1
	return alive


func owns_enemy(enemy: Node) -> bool:
	return _is_arena_owned_enemy(enemy)


func _resolve_nodes() -> void:
	_activation_zone = get_node_or_null(activation_zone_path) as Area2D
	_enemies_container = get_node_or_null(enemies_container_path)
	_feedback_label = get_node_or_null(feedback_label_path) as Label

	_gates.clear()
	for gate_path in gate_paths:
		var gate := get_node_or_null(gate_path) as CombatArenaGate
		if gate != null:
			_gates.append(gate)

	_blocked_exits.clear()
	for exit_path in blocked_exit_paths:
		var exit_node := get_node_or_null(exit_path)
		if exit_node is AreaExit:
			_blocked_exits.append(exit_node as AreaExit)

	_spawn_points.clear()
	for spawn_path in enemy_spawn_paths:
		var spawn_point := get_node_or_null(spawn_path) as Node2D
		if spawn_point != null:
			_spawn_points.append(spawn_point)


func _on_activation_body_entered(body: Node) -> void:
	# Physics callbacks only register a lifecycle request. No collision or tree
	# mutation is allowed on this stack.
	request_activation(body)


func _on_activation_body_exited(body: Node) -> void:
	if body != null and body.is_in_group(PLAYER_GROUP):
		_activation_requires_exit = false


func _await_activation_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, ArenaState.ACTIVATION_REQUESTED):
		return
	call_deferred("_begin_closing_gates", generation)


func _begin_closing_gates(generation: int) -> void:
	if not _matches_lifecycle(generation, ArenaState.ACTIVATION_REQUESTED):
		return
	_set_state(ArenaState.CLOSING_GATES)
	call_deferred("_await_spawning_boundary", generation)


func _await_spawning_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, ArenaState.CLOSING_GATES):
		return
	await _begin_spawning(generation)


func _begin_spawning(generation: int) -> void:
	if not _matches_lifecycle(generation, ArenaState.CLOSING_GATES):
		return
	_set_state(ArenaState.SPAWNING)
	await _spawn_configured_enemies_async(generation)
	if not _matches_lifecycle(generation, ArenaState.SPAWNING):
		return
	if _spawned_count <= 0:
		push_warning("CombatArena '%s' failed to spawn enemies. Releasing the arena." % String(arena_id))
		_abort_arena_activation("Falha ao iniciar combate")
		return

	_set_state(ArenaState.ACTIVE)
	_show_status_message("Um de cada vez — leia o telegraph")
	arena_activated.emit(arena_id)


func _abort_arena_activation(message: String) -> void:
	_request_reset(&"activation_failed", message)


func _request_reset(reason: StringName, message: String) -> void:
	if state in [ArenaState.INACTIVE, ArenaState.RESETTING, ArenaState.COMPLETED]:
		return
	_lifecycle_generation += 1
	var generation := _lifecycle_generation
	_pending_reset_message = message
	_integrity_compromised = reason == &"integrity_failure"
	_disable_activation_zone()
	_set_state(ArenaState.RESETTING)
	call_deferred("_await_reset_boundary", generation)


func _await_reset_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, ArenaState.RESETTING):
		return
	call_deferred("_perform_reset_cleanup", generation)


func _perform_reset_cleanup(generation: int) -> void:
	if not _matches_lifecycle(generation, ArenaState.RESETTING):
		return
	_clear_runtime_projectiles()
	_despawn_owned_enemies()
	_clear_runtime_tracking()
	call_deferred("_await_reset_finalize_boundary", generation)


func _await_reset_finalize_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, ArenaState.RESETTING):
		return
	call_deferred("_finalize_reset", generation)


func _finalize_reset(generation: int) -> void:
	if not _matches_lifecycle(generation, ArenaState.RESETTING):
		return
	_integrity_compromised = false
	_completion_committed = false
	_set_state(ArenaState.INACTIVE)
	if not _pending_reset_message.is_empty():
		_show_status_message(_pending_reset_message)
	_pending_reset_message = ""
	arm_activation_monitoring()


func _spawn_configured_enemies() -> void:
	_clear_runtime_tracking()

	if enemy_scene == null or _enemies_container == null:
		push_warning("CombatArena '%s' has no enemy scene or container." % String(arena_id))
		return
	if _spawn_points.is_empty():
		push_warning("CombatArena '%s' has no enemy spawn points." % String(arena_id))
		return

	for spawn_point in _spawn_points:
		_spawn_enemy_at(spawn_point)


func _spawn_configured_enemies_async(generation: int) -> void:
	_clear_runtime_tracking()

	if enemy_scene == null or _enemies_container == null:
		push_warning("CombatArena '%s' has no enemy scene or container." % String(arena_id))
		return
	if _spawn_points.is_empty():
		push_warning("CombatArena '%s' has no enemy spawn points." % String(arena_id))
		return

	for index in range(_spawn_points.size()):
		if not _matches_lifecycle(generation, ArenaState.SPAWNING):
			return
		_spawn_enemy_at(_spawn_points[index])
		if spawn_stagger_seconds > 0.0 and index < _spawn_points.size() - 1:
			var tree := get_tree()
			if tree == null:
				return
			await tree.create_timer(spawn_stagger_seconds).timeout


func _spawn_enemy_at(spawn_point: Node2D) -> void:
	var scene_to_spawn := _resolve_enemy_scene_for_spawn(spawn_point)
	if scene_to_spawn == null:
		return
	var enemy := scene_to_spawn.instantiate() as Node
	if enemy == null:
		return
	enemy.set_meta(ARENA_ENEMY_META, arena_id)
	enemy.set_meta(ARENA_OWNER_META, get_instance_id())
	_enemies_container.add_child(enemy)
	if enemy is Node2D:
		(enemy as Node2D).global_position = spawn_point.global_position
	_register_enemy(enemy)
	_spawned_count += 1


func _resolve_enemy_scene_for_spawn(spawn_point: Node2D) -> PackedScene:
	if spawn_point is CombatArenaSpawnPoint:
		var typed := spawn_point as CombatArenaSpawnPoint
		if typed.enemy_scene != null:
			return typed.enemy_scene
	return enemy_scene


func _register_enemy(enemy: Node) -> void:
	if enemy == null or _tracked_enemies.has(enemy):
		return
	if not _is_arena_owned_enemy(enemy):
		return

	_tracked_enemies.append(enemy)
	var health := _find_health_component(enemy)
	if health != null and not health.died.is_connected(_on_enemy_died.bind(enemy)):
		health.died.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)
	if not enemy.tree_exiting.is_connected(_on_enemy_tree_exiting.bind(enemy)):
		enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)


func _on_enemy_died(enemy: Node) -> void:
	if not _is_arena_owned_enemy(enemy):
		return
	var instance_id := enemy.get_instance_id()
	if _defeated_instance_ids.has(instance_id):
		return
	_defeated_instance_ids[instance_id] = true
	_check_for_completion()


func _on_enemy_tree_exiting(enemy: Node) -> void:
	var was_owned := _is_arena_owned_enemy(enemy)
	var instance_id := enemy.get_instance_id()
	var was_defeated := _defeated_instance_ids.has(instance_id)
	var health := _find_health_component(enemy)
	var was_dead := health != null and health.is_dead
	_tracked_enemies.erase(enemy)

	if not was_owned or _area_unloading or state in [ArenaState.RESETTING, ArenaState.COMPLETED]:
		return
	if was_defeated or was_dead:
		_check_for_completion()
		return
	_handle_integrity_failure(enemy)


func _handle_integrity_failure(enemy: Node) -> void:
	if state != ArenaState.ACTIVE or _integrity_compromised:
		return
	_integrity_compromised = true
	_activation_requires_exit = true
	var enemy_name := String(enemy.name) if enemy != null else "unknown"
	var reason := "living_enemy_despawned:%s" % enemy_name
	push_warning("CombatArena '%s' integrity failure: %s" % [String(arena_id), reason])
	arena_integrity_failed.emit(arena_id, reason)
	_request_reset(&"integrity_failure", "Combate interrompido — inimigo removido indevidamente")


func _check_for_completion() -> void:
	if _integrity_compromised or state != ArenaState.ACTIVE:
		return
	if _spawned_count <= 0 or _defeated_instance_ids.size() < _spawned_count:
		return
	if get_remaining_enemy_count() > 0:
		return
	_complete_arena()


func _complete_arena() -> void:
	if state != ArenaState.ACTIVE or _completion_committed:
		return
	_completion_committed = true
	_clear_runtime_projectiles()
	_set_state(ArenaState.COMPLETED)
	_disable_activation_zone()
	_mark_complete_in_progression()
	_grant_style_completion_bonus()
	_show_status_message("Portas abertas — arena concluída")
	arena_completed.emit(arena_id)


func _apply_completed_state(from_activation: bool) -> void:
	_lifecycle_generation += 1
	_completion_committed = true
	_clear_runtime_tracking()
	_set_state(ArenaState.COMPLETED)
	_disable_activation_zone()
	if from_activation:
		_show_status_message("Arena concluída")


func _set_state(new_state: ArenaState) -> void:
	var previous_state := state
	state = new_state
	match new_state:
		ArenaState.CLOSING_GATES, ArenaState.SPAWNING, ArenaState.ACTIVE:
			_set_gates_closed(true)
			_set_exits_blocked(true)
		ArenaState.INACTIVE, ArenaState.ACTIVATION_REQUESTED, ArenaState.RESETTING, ArenaState.COMPLETED:
			_set_gates_closed(false)
			_set_exits_blocked(false)
	if previous_state != new_state:
		arena_state_changed.emit(previous_state, new_state)


func _set_gates_closed(closed: bool) -> void:
	for gate in _gates:
		if is_instance_valid(gate):
			gate.set_closed(closed)


func _set_exits_blocked(blocked: bool) -> void:
	for exit in _blocked_exits:
		if is_instance_valid(exit):
			exit.set_arena_blocked(blocked)


func _disable_activation_zone() -> void:
	if _activation_zone != null:
		_activation_zone.set_deferred("monitoring", false)


func _despawn_owned_enemies() -> void:
	var owned: Array[Node] = []
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy) and _is_arena_owned_enemy(enemy) and not owned.has(enemy):
			owned.append(enemy)
	if _enemies_container != null:
		for child in _enemies_container.get_children():
			if is_instance_valid(child) and _is_arena_owned_enemy(child) and not owned.has(child):
				owned.append(child)
	for enemy in owned:
		enemy.queue_free()


func _clear_runtime_tracking() -> void:
	_tracked_enemies.clear()
	_defeated_instance_ids.clear()
	_spawned_count = 0


func _clear_runtime_projectiles() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("physical_projectile"):
		if not (node is PhysicalProjectile):
			continue
		var projectile := node as PhysicalProjectile
		var owner_node := projectile.owner_node
		if owner_node != null and _is_arena_owned_enemy(owner_node):
			projectile.queue_free()


func _is_arena_owned_enemy(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	return (
		enemy.get_meta(ARENA_ENEMY_META, &"") == arena_id
		and int(enemy.get_meta(ARENA_OWNER_META, 0)) == get_instance_id()
	)


func _matches_lifecycle(generation: int, expected_state: ArenaState) -> bool:
	return (
		is_inside_tree()
		and not _area_unloading
		and generation == _lifecycle_generation
		and state == expected_state
	)


func _show_status_message(message: String) -> void:
	arena_message_shown.emit(message)
	if _feedback_label == null:
		return
	_feedback_label.text = message
	_feedback_label.visible = true
	if _status_timer != null and is_instance_valid(_status_timer):
		if _status_timer.timeout.is_connected(_hide_status_message):
			_status_timer.timeout.disconnect(_hide_status_message)
	_status_timer = get_tree().create_timer(status_message_duration, true)
	_status_timer.timeout.connect(_hide_status_message, CONNECT_ONE_SHOT)


func _hide_status_message() -> void:
	if _feedback_label != null:
		_feedback_label.visible = false


func _grant_style_completion_bonus() -> void:
	if style_completion_bonus <= 0.0:
		return
	if _style_manager != null:
		_style_manager.grant_style_reward(style_completion_bonus, "Arena +%.0f" % style_completion_bonus)
		return
	for node in get_tree().get_nodes_in_group(STYLE_MANAGER_GROUP):
		if node is StyleManager:
			(node as StyleManager).grant_style_reward(style_completion_bonus, "Arena +%.0f" % style_completion_bonus)
			return


func _mark_complete_in_progression() -> void:
	if completion_flag_id == &"":
		return
	if _progression != null:
		_progression.set_narrative_flag(completion_flag_id, true)
		return
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			(node as ProgressionComponent).set_narrative_flag(completion_flag_id, true)
			return


func _is_marked_complete_in_progression() -> bool:
	if completion_flag_id == &"":
		return false
	if _progression != null:
		if bool(_progression.narrative_flags.get(String(completion_flag_id), false)):
			return true
		if completion_flag_id == &"arena_vs_church_yard_complete":
			return bool(_progression.narrative_flags.get("arena_church_yard_01_complete", false))
		return false
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			var flags: Dictionary = (node as ProgressionComponent).narrative_flags
			if bool(flags.get(String(completion_flag_id), false)):
				return true
			if completion_flag_id == &"arena_vs_church_yard_complete":
				return bool(flags.get("arena_church_yard_01_complete", false))
	return false


func _find_health_component(node: Node) -> HealthComponent:
	if node == null:
		return null
	if node is HealthComponent:
		return node as HealthComponent
	for child in node.get_children():
		var health := _find_health_component(child)
		if health != null:
			return health
	return null
