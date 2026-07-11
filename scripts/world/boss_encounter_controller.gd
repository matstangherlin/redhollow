extends Node2D
class_name BossEncounterController

signal encounter_started(encounter_id: StringName)
signal boss_defeated(boss_id: StringName)
signal encounter_message_shown(message: String)

enum EncounterState {
	INACTIVE,
	ACTIVE,
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


func _ready() -> void:
	add_to_group(CONTROLLER_GROUP)
	_resolve_nodes()

	if _is_marked_complete_in_progression():
		_apply_completed_state()
		return

	_set_state(EncounterState.INACTIVE)
	if _activation_zone != null:
		_activation_zone.body_entered.connect(_on_activation_body_entered)


func is_blocking_exits() -> bool:
	return state == EncounterState.ACTIVE


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
	if state != EncounterState.INACTIVE:
		return
	if not body.is_in_group(PLAYER_GROUP):
		return
	_start_encounter()


func _start_encounter() -> void:
	if state != EncounterState.INACTIVE:
		return

	_set_state(EncounterState.ACTIVE)
	_set_gates_closed(true)
	_set_exits_blocked(true)
	_bind_boss_hud()
	if _boss != null:
		_boss.activate_boss()
	_show_status_message("Deacon Rusk")
	encounter_started.emit(encounter_id)

	if _boss != null and not _boss.boss_defeated.is_connected(_on_boss_defeated):
		_boss.boss_defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)


func _on_boss_defeated(boss_id: StringName) -> void:
	if state != EncounterState.ACTIVE:
		return
	_complete_encounter(boss_id)


func _complete_encounter(boss_id: StringName) -> void:
	_set_state(EncounterState.COMPLETED)
	_set_gates_closed(false)
	_set_exits_blocked(false)
	_disable_activation_zone()
	_mark_complete_in_progression()
	_grant_style_completion_bonus()
	_show_status_message("Executor caído")
	boss_defeated.emit(boss_id)


func _apply_completed_state() -> void:
	_set_state(EncounterState.COMPLETED)
	_set_gates_closed(false)
	_set_exits_blocked(false)
	_disable_activation_zone()
	if _boss != null:
		if _boss.has_method("mark_encounter_cleared"):
			_boss.call("mark_encounter_cleared")
		elif _boss.has_method("_set_dormant"):
			_boss.call("_set_dormant", true)


func _bind_boss_hud() -> void:
	if _boss == null:
		return
	for node in get_tree().get_nodes_in_group(BOSS_HUD_GROUP):
		if node.has_method("bind_boss"):
			node.call("bind_boss", _boss)
			return


func _set_state(new_state: EncounterState) -> void:
	state = new_state
	if new_state == EncounterState.INACTIVE:
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
	for node in get_tree().get_nodes_in_group(STYLE_MANAGER_GROUP):
		if node.has_method("grant_style_reward"):
			node.call("grant_style_reward", style_completion_bonus, "Boss +%.0f" % style_completion_bonus)
			return


func _mark_complete_in_progression() -> void:
	if completion_flag_id == &"":
		return
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node.has_method("set_narrative_flag"):
			node.call("set_narrative_flag", completion_flag_id, true)
			return


func _is_marked_complete_in_progression() -> bool:
	if completion_flag_id == &"":
		return false
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node.get("narrative_flags") is Dictionary:
			var flags: Dictionary = node.get("narrative_flags")
			return bool(flags.get(String(completion_flag_id), false))
	return false
