extends Node2D
class_name BossEncounterController

signal encounter_started(encounter_id: StringName)
signal boss_defeated(boss_id: StringName)
signal encounter_completed(encounter_id: StringName)
signal boss_hud_bound(boss_id: StringName)
signal encounter_message_shown(message: String)
signal encounter_state_changed(previous_state: int, new_state: int)

enum EncounterState {
	INACTIVE,
	ACTIVATION_REQUESTED,
	CLOSING_GATES,
	SPAWNING,
	ACTIVE,
	RESETTING,
	COMPLETED,
}

const CONTROLLER_GROUP := "boss_encounter_controller"
const PLAYER_GROUP := "player"
const BOSS_HUD_GROUP := "boss_health_hud"
const STYLE_MANAGER_GROUP := "style_manager"
const PROGRESSION_GROUP := "progression_component"

@export var encounter_id: StringName = &"deacon_rusk_encounter"
@export var activation_zone_path: NodePath
@export var gate_paths: Array[NodePath] = []
@export var blocked_exit_paths: Array[NodePath] = []
@export var boss_path: NodePath
@export var style_completion_bonus: float = 150.0
@export var completion_flag_id: StringName = &"boss_deacon_rusk_defeated"
@export var feedback_label_path: NodePath
@export var status_message_duration: float = 2.8

var state: EncounterState = EncounterState.INACTIVE

var _activation_zone: Area2D = null
var _boss: DeaconRusk = null
var _feedback_label: Label = null
var _gates: Array[CombatArenaGate] = []
var _blocked_exits: Array[AreaExit] = []
var _status_timer: SceneTreeTimer = null
var _style_manager: StyleManager = null
var _progression: ProgressionComponent = null
var _boss_health_hud: BossHealthHud = null
var _lifecycle_generation: int = 0
var _completion_committed: bool = false
var _area_unloading: bool = false
var _activation_requires_exit: bool = false


func _ready() -> void:
	add_to_group(CONTROLLER_GROUP)
	_resolve_nodes()

	if _is_marked_complete_in_progression():
		_apply_completed_state()
		return

	_set_state(EncounterState.INACTIVE)
	if _activation_zone != null:
		_activation_zone.set_deferred("monitoring", false)
		if not _activation_zone.body_entered.is_connected(_on_activation_body_entered):
			_activation_zone.body_entered.connect(_on_activation_body_entered)
		if not _activation_zone.body_exited.is_connected(_on_activation_body_exited):
			_activation_zone.body_exited.connect(_on_activation_body_exited)


func arm_activation_monitoring() -> void:
	if state != EncounterState.INACTIVE or _area_unloading:
		return
	if _activation_zone == null:
		return
	_activation_zone.set_deferred("monitoring", true)


func bind_encounter_services(
	style_manager: StyleManager = null,
	progression: ProgressionComponent = null,
	boss_health_hud: BossHealthHud = null
) -> void:
	_style_manager = style_manager
	_progression = progression
	_boss_health_hud = boss_health_hud
	if state == EncounterState.INACTIVE and _is_marked_complete_in_progression():
		_apply_completed_state()


func request_activation(body: Node) -> bool:
	if state != EncounterState.INACTIVE or _area_unloading or _activation_requires_exit:
		return false
	if body == null or not body.is_in_group(PLAYER_GROUP):
		return false

	_lifecycle_generation += 1
	var generation := _lifecycle_generation
	_completion_committed = false
	_set_state(EncounterState.ACTIVATION_REQUESTED)
	_disable_activation_zone()
	call_deferred("_await_activation_boundary", generation)
	return true


func is_blocking_exits() -> bool:
	return state in [EncounterState.CLOSING_GATES, EncounterState.SPAWNING, EncounterState.ACTIVE]


func on_area_unloading() -> void:
	if _area_unloading:
		return
	_area_unloading = true
	_lifecycle_generation += 1
	_disable_activation_zone()
	_set_state(EncounterState.RESETTING)
	_unbind_boss_hud()
	_clear_boss_projectiles()
	_reset_boss_to_dormant()


func reset_active_encounter_for_player_death() -> void:
	if state not in [
		EncounterState.ACTIVATION_REQUESTED,
		EncounterState.CLOSING_GATES,
		EncounterState.SPAWNING,
		EncounterState.ACTIVE,
	]:
		return
	_activation_requires_exit = true
	_request_reset()


func _resolve_nodes() -> void:
	_activation_zone = get_node_or_null(activation_zone_path) as Area2D
	_feedback_label = get_node_or_null(feedback_label_path) as Label
	_boss = get_node_or_null(boss_path) as DeaconRusk

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


func _on_activation_body_entered(body: Node) -> void:
	# Physics callbacks only register a lifecycle request.
	request_activation(body)


func _on_activation_body_exited(body: Node) -> void:
	if body != null and body.is_in_group(PLAYER_GROUP):
		_activation_requires_exit = false


func _await_activation_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, EncounterState.ACTIVATION_REQUESTED):
		return
	call_deferred("_begin_closing_gates", generation)


func _begin_closing_gates(generation: int) -> void:
	if not _matches_lifecycle(generation, EncounterState.ACTIVATION_REQUESTED):
		return
	_set_state(EncounterState.CLOSING_GATES)
	call_deferred("_await_start_boundary", generation)


func _await_start_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, EncounterState.CLOSING_GATES):
		return
	call_deferred("_start_encounter", generation)


func _start_encounter(generation: int) -> void:
	if not _matches_lifecycle(generation, EncounterState.CLOSING_GATES):
		return

	_set_state(EncounterState.SPAWNING)
	_reset_boss_to_dormant()
	if _boss == null:
		push_warning("BossEncounter '%s' has no boss. Releasing the encounter." % String(encounter_id))
		_request_reset()
		return

	_set_state(EncounterState.ACTIVE)
	_bind_boss_hud()
	_boss.activate_boss()
	_show_status_message("Deacon Rusk")
	encounter_started.emit(encounter_id)
	_start_intro_dialogue()

	if not _boss.boss_defeated.is_connected(_on_boss_defeated):
		_boss.boss_defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)


func _request_reset() -> void:
	if state in [EncounterState.INACTIVE, EncounterState.RESETTING, EncounterState.COMPLETED]:
		return
	_lifecycle_generation += 1
	var generation := _lifecycle_generation
	_disable_activation_zone()
	_set_state(EncounterState.RESETTING)
	_unbind_boss_hud()
	call_deferred("_await_reset_boundary", generation)


func _await_reset_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, EncounterState.RESETTING):
		return
	call_deferred("_perform_reset", generation)


func _perform_reset(generation: int) -> void:
	if not _matches_lifecycle(generation, EncounterState.RESETTING):
		return
	_clear_boss_projectiles()
	_reset_boss_to_dormant()
	call_deferred("_await_reset_finalize_boundary", generation)


func _await_reset_finalize_boundary(generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.physics_frame
	if not _matches_lifecycle(generation, EncounterState.RESETTING):
		return
	call_deferred("_finalize_reset", generation)


func _finalize_reset(generation: int) -> void:
	if not _matches_lifecycle(generation, EncounterState.RESETTING):
		return
	_completion_committed = false
	_set_state(EncounterState.INACTIVE)
	arm_activation_monitoring()


func _on_boss_defeated(boss_id: StringName) -> void:
	if state != EncounterState.ACTIVE:
		return
	_complete_encounter(boss_id)


func _complete_encounter(boss_id: StringName) -> void:
	if state != EncounterState.ACTIVE or _completion_committed:
		return
	_completion_committed = true
	_clear_boss_projectiles()
	_unbind_boss_hud()
	_set_state(EncounterState.COMPLETED)
	_disable_activation_zone()
	_mark_complete_in_progression()
	_grant_style_completion_bonus()
	_show_status_message("Executor caído")
	encounter_completed.emit(encounter_id)
	boss_defeated.emit(boss_id)


func _start_intro_dialogue() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("dialogue_controller"):
		if node is DialogueController:
			var player := tree.get_first_node_in_group("player")
			(node as DialogueController).try_start_dialogue(&"cz_deacon_intro", player, self)
			return


func _apply_completed_state() -> void:
	_lifecycle_generation += 1
	_completion_committed = true
	_unbind_boss_hud()
	_set_state(EncounterState.COMPLETED)
	_disable_activation_zone()
	if _boss != null:
		_boss.mark_encounter_cleared()


func _bind_boss_hud() -> void:
	if _boss == null:
		return

	if _boss_health_hud != null:
		_boss_health_hud.bind_boss(_boss)
		boss_hud_bound.emit(_boss.boss_id if _boss.boss_id != &"" else encounter_id)
		return

	for node in get_tree().get_nodes_in_group(BOSS_HUD_GROUP):
		if node is BossHealthHud:
			(node as BossHealthHud).bind_boss(_boss)
			boss_hud_bound.emit(_boss.boss_id if _boss.boss_id != &"" else encounter_id)
			return


func _unbind_boss_hud() -> void:
	if _boss_health_hud != null:
		_boss_health_hud.unbind_boss()
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(BOSS_HUD_GROUP):
		if node is BossHealthHud:
			(node as BossHealthHud).unbind_boss()
			return


func _reset_boss_to_dormant() -> void:
	if _boss != null and _boss.has_method("reset_for_player_death"):
		_boss.call("reset_for_player_death")


func _clear_boss_projectiles() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("physical_projectile"):
		if not (node is PhysicalProjectile):
			continue
		var projectile := node as PhysicalProjectile
		if projectile.owner_node == _boss:
			projectile.queue_free()


func _set_state(new_state: EncounterState) -> void:
	var previous_state := state
	state = new_state
	match new_state:
		EncounterState.CLOSING_GATES, EncounterState.SPAWNING, EncounterState.ACTIVE:
			_set_gates_closed(true)
			_set_exits_blocked(true)
		EncounterState.INACTIVE, EncounterState.ACTIVATION_REQUESTED, EncounterState.RESETTING, EncounterState.COMPLETED:
			_set_gates_closed(false)
			_set_exits_blocked(false)
	if previous_state != new_state:
		encounter_state_changed.emit(previous_state, new_state)


func _matches_lifecycle(generation: int, expected_state: EncounterState) -> bool:
	return (
		is_inside_tree()
		and not _area_unloading
		and generation == _lifecycle_generation
		and state == expected_state
	)


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
	encounter_message_shown.emit(message)
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
		_style_manager.grant_style_reward(style_completion_bonus, "Boss +%.0f" % style_completion_bonus)
		return

	for node in get_tree().get_nodes_in_group(STYLE_MANAGER_GROUP):
		if node is StyleManager:
			(node as StyleManager).grant_style_reward(style_completion_bonus, "Boss +%.0f" % style_completion_bonus)
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
		return bool(_progression.narrative_flags.get(String(completion_flag_id), false))

	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			return bool((node as ProgressionComponent).narrative_flags.get(String(completion_flag_id), false))
	return false
