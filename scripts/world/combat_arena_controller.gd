extends Node2D
class_name CombatArenaController

signal arena_activated(arena_id: StringName)
signal arena_completed(arena_id: StringName)
signal arena_message_shown(message: String)
signal arena_integrity_failed(arena_id: StringName, reason: String)
signal arena_debug_recovered(arena_id: StringName)

enum ArenaState {
	INACTIVE,
	ACTIVE,
	COMPLETED,
}

const CONTROLLER_GROUP := "combat_arena_controller"
const PLAYER_GROUP := "player"
const STYLE_MANAGER_GROUP := "style_manager"
const PROGRESSION_GROUP := "progression_component"

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
		_activation_zone.body_entered.connect(_on_activation_body_entered)


func bind_combat_services(
	style_manager: StyleManager = null,
	progression: ProgressionComponent = null
) -> void:
	_style_manager = style_manager
	_progression = progression


func debug_force_recover_arena() -> void:
	if state != ArenaState.ACTIVE:
		return

	_integrity_compromised = false
	_tracked_enemies = _tracked_enemies.filter(func(enemy: Node) -> bool: return is_instance_valid(enemy))
	_show_status_message("Debug: arena recuperada")
	arena_debug_recovered.emit(arena_id)


func try_complete_if_enemies_cleared() -> bool:
	if _integrity_compromised:
		return false
	if state != ArenaState.ACTIVE:
		return false
	if _spawned_count <= 0:
		return false
	if _defeated_instance_ids.size() < _spawned_count:
		return false
	if get_remaining_enemy_count() > 0:
		return false
	_complete_arena()
	return true


func is_blocking_exits() -> bool:
	return state == ArenaState.ACTIVE


func get_remaining_enemy_count() -> int:
	var alive := 0
	for enemy in _tracked_enemies:
		if not is_instance_valid(enemy):
			continue
		var health := _find_health_component(enemy)
		if health == null or not health.is_dead:
			alive += 1
	return alive


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
	if state != ArenaState.INACTIVE:
		return
	if not body.is_in_group(PLAYER_GROUP):
		return
	_activate_arena()


func _activate_arena() -> void:
	if state != ArenaState.INACTIVE:
		return

	_set_state(ArenaState.ACTIVE)
	_set_gates_closed(true)
	_set_exits_blocked(true)
	_spawn_configured_enemies()
	if _spawned_count <= 0:
		push_warning("CombatArena '%s' failed to spawn enemies. Releasing the arena." % String(arena_id))
		_abort_arena_activation("Falha ao iniciar combate")
		return

	_show_status_message("Derrote os três arquetipos para abrir as portas")
	arena_activated.emit(arena_id)


func _abort_arena_activation(message: String) -> void:
	_set_state(ArenaState.INACTIVE)
	_set_gates_closed(false)
	_set_exits_blocked(false)
	_tracked_enemies.clear()
	_defeated_instance_ids.clear()
	_spawned_count = 0
	_show_status_message(message)


func _spawn_configured_enemies() -> void:
	_tracked_enemies.clear()
	_defeated_instance_ids.clear()
	_spawned_count = 0

	if enemy_scene == null or _enemies_container == null:
		push_warning("CombatArena '%s' has no enemy scene or container." % String(arena_id))
		return

	if _spawn_points.is_empty():
		push_warning("CombatArena '%s' has no enemy spawn points." % String(arena_id))
		return

	for spawn_point in _spawn_points:
		var scene_to_spawn := _resolve_enemy_scene_for_spawn(spawn_point)
		if scene_to_spawn == null:
			continue
		var enemy := scene_to_spawn.instantiate() as Node
		if enemy == null:
			continue
		_enemies_container.add_child(enemy)
		enemy.global_position = spawn_point.global_position
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

	_tracked_enemies.append(enemy)
	enemy.set_meta("combat_arena_id", arena_id)

	var health := _find_health_component(enemy)
	if health != null:
		health.died.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)

	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)


func _on_enemy_died(enemy: Node) -> void:
	var instance_id := enemy.get_instance_id()
	if _defeated_instance_ids.has(instance_id):
		return
	_defeated_instance_ids[instance_id] = true
	_check_for_completion()


func _on_enemy_tree_exiting(enemy: Node) -> void:
	_tracked_enemies.erase(enemy)
	var instance_id := enemy.get_instance_id()
	if _defeated_instance_ids.has(instance_id):
		_check_for_completion()
		return

	var health := _find_health_component(enemy)
	if health != null and not health.is_dead:
		_handle_integrity_failure(enemy)
		return
	_check_for_completion()


func _handle_integrity_failure(enemy: Node) -> void:
	if state != ArenaState.ACTIVE or _integrity_compromised:
		return

	_integrity_compromised = true
	var enemy_name: String = String(enemy.name) if enemy != null else "unknown"
	var reason := "living_enemy_despawned:%s" % enemy_name
	push_error("CombatArena '%s' integrity failure: %s" % [String(arena_id), reason])
	arena_integrity_failed.emit(arena_id, reason)
	_abort_arena_activation("Combate interrompido — inimigo removido indevidamente")


func _check_for_completion() -> void:
	if _integrity_compromised:
		return
	if state != ArenaState.ACTIVE:
		return
	if _spawned_count <= 0:
		return
	if _defeated_instance_ids.size() < _spawned_count:
		return
	_complete_arena()


func _complete_arena() -> void:
	if state != ArenaState.ACTIVE:
		return

	_set_state(ArenaState.COMPLETED)
	_set_gates_closed(false)
	_set_exits_blocked(false)
	_disable_activation_zone()
	_mark_complete_in_progression()
	_grant_style_completion_bonus()
	_show_status_message("Portas abertas — arena concluída")
	arena_completed.emit(arena_id)


func _apply_completed_state(from_activation: bool) -> void:
	_set_state(ArenaState.COMPLETED)
	_set_gates_closed(false)
	_set_exits_blocked(false)
	_disable_activation_zone()
	if from_activation:
		_show_status_message("Arena concluída")


func _set_state(new_state: ArenaState) -> void:
	state = new_state
	if new_state == ArenaState.INACTIVE:
		_set_gates_closed(false)
		_set_exits_blocked(false)


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


func _show_status_message(message: String) -> void:
	arena_message_shown.emit(message)
	if _feedback_label == null:
		return

	_feedback_label.text = message
	_feedback_label.visible = true

	if _status_timer != null and is_instance_valid(_status_timer):
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
