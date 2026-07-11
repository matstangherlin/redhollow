extends CharacterBody2D

const PLAYER_GROUP := "player"
const CAMERA_CONTROLLER_GROUP := "camera_controller"
const HITSTOP_GROUP := "hitstop_controller"

# All timing values are seconds. Movement values are pixels per second or pixels per second squared.
enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	DODGE,
	COUNTER,
	TAUNT,
	HURT,
	DEAD,
	INTERACT,
}

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

enum DodgePhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

enum CounterPhase {
	NONE,
	STARTUP,
	WINDOW,
	RECOVERY,
	COUNTER_ATTACK,
}

enum BrandBreakerPhase {
	NONE,
	CHARGING,
}

signal counter_success(attack_data: Resource, attacker: Node)
signal combo_completed
signal dodge_started
signal dodge_finished
signal counter_resolved(result: String)
signal taunt_performed(phrase: String, context: Dictionary)
signal taunt_started(phrase: String, line_id: StringName)
signal brand_breaker_charge_started
signal brand_breaker_charge_updated(charge_time: float, preview_level: int)
signal brand_breaker_charge_cancelled
signal brand_breaker_released(level: int, cost: float)

@export var default_facing_direction: int = 1
@export var max_run_speed: float = 240.0
@export var ground_acceleration: float = 1800.0
@export var ground_deceleration: float = 2200.0
@export var air_acceleration: float = 1100.0
@export var air_deceleration: float = 650.0
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var jump_velocity: float = -560.0
@export_range(0.1, 1.0, 0.01) var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12
@export var direction_marker_offset: float = 28.0
@export var floor_snap_distance: float = 6.0
@export var fall_recovery_y: float = 720.0
@export var attack_input_buffer_time: float = 0.35
@export var combo_reset_time: float = 0.45
@export var dodge_startup: float = 0.04
@export var dodge_speed: float = 560.0
@export var dodge_duration: float = 0.13
@export var invulnerability_start: float = 0.02
@export var invulnerability_end: float = 0.13
@export var dodge_recovery: float = 0.14
@export var dodge_cooldown: float = 0.28
@export var counter_startup: float = 0.05
@export var counter_window: float = 0.12
@export var counter_recovery: float = 0.28
@export var counter_cooldown: float = 0.35
@export var counter_attack: Resource = preload("res://resources/combat/calder_counter.tres")
@export var counter_hitstop_duration: float = 0.065
@export var counter_shake_intensity: float = 12.0
@export var counter_shake_duration: float = 0.28
@export var taunt_duration: float = 0.90
@export var taunt_vulnerable_start: float = 0.14
@export var taunt_vulnerable_end: float = 0.68
@export var taunt_cooldown: float = 1.20
@export var taunt_phrases: Array[String] = [
	"Você chama isso de mira?",
	"Foi isso que aprenderam na igreja?",
	"Meu braço faz mais milagres que seu bispo.",
	"Vamos, eu ainda nem comecei.",
	"Sua fé bate mais fraco que você.",
]
@export var red_brand_breaker_level_1: Resource = preload("res://resources/combat/red_brand_breaker_lv1.tres")
@export var red_brand_breaker_level_2: Resource = preload("res://resources/combat/red_brand_breaker_lv2.tres")
@export var combo_attacks: Array[Resource] = [
	preload("res://resources/combat/calder_straight.tres"),
	preload("res://resources/combat/body_hook.tres"),
	preload("res://resources/combat/red_knuckle.tres"),
]

@onready var input_controller: PlayerInputController = $Controllers/PlayerInputController
@onready var movement_controller: PlayerMovementController = $Controllers/PlayerMovementController
@onready var attack_controller: PlayerAttackController = $Controllers/PlayerAttackController
@onready var red_brand_controller: PlayerRedBrandController = $Controllers/PlayerRedBrandController
@onready var defense_controller: PlayerDefenseController = $Controllers/PlayerDefenseController
@onready var taunt_controller: PlayerTauntController = $Controllers/PlayerTauntController
@onready var state_coordinator: PlayerStateCoordinator = $Controllers/PlayerStateCoordinator
@onready var presentation_controller: PlayerPresentationController = $Controllers/PlayerPresentationController
@onready var visual_controller: PlayerVisualController = $Controllers/PlayerVisualController
@onready var debug_view: PlayerDebugView = $Controllers/PlayerDebugView

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var direction_marker: Node2D = %DirectionMarker
@onready var components: Node = %Components
@onready var debug_label: Label = %DebugLabel
@onready var hitbox_component: Area2D = %HitboxComponent
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var health_component: Node = %HealthComponent
@onready var red_brand_component: RedBrandComponent = %RedBrandComponent
@onready var brand_hand: Polygon2D = %BrandHand
@onready var interaction_detector: Node = %InteractionDetector

const DEATH_RESPAWN_DELAY := 0.65

var current_state: int = PlayerState.IDLE
var facing_direction: int = 1
var spawn_position: Vector2 = Vector2.ZERO
var _lock_manager: GameplayLockManager = null
var _dialogue_lock_token: GameplayLockToken = null
var _transition_lock_token: GameplayLockToken = null
var _death_lock_token: GameplayLockToken = null
var _death_respawn_pending: bool = false


func _ready() -> void:
	add_to_group(PLAYER_GROUP)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_position = global_position
	set_facing_direction(default_facing_direction)
	_setup_controllers()
	_connect_combat_signals()
	call_deferred("_bind_lock_manager")
	call_deferred("_release_legacy_player_locks")


func _setup_controllers() -> void:
	input_controller.setup(self)
	presentation_controller.setup(visual, body_visual, brand_hand, direction_marker)
	visual_controller.setup(self)
	movement_controller.setup(self, presentation_controller)
	movement_controller.configure_floor_snap()
	attack_controller.setup(self, hitbox_component)
	red_brand_controller.setup(self, red_brand_component, attack_controller, presentation_controller)
	defense_controller.setup(
		self, input_controller, attack_controller, presentation_controller, health_component, hurtbox_component
	)
	taunt_controller.setup(self, input_controller, attack_controller, presentation_controller, health_component)
	_connect_attack_controller_signals()
	_connect_red_brand_controller_signals()
	_connect_defense_controller_signals()
	_connect_taunt_controller_signals()
	var hit_landed_callable := Callable(self, "_on_hit_landed")
	if hitbox_component.has_signal("hit_landed") and not hitbox_component.is_connected("hit_landed", hit_landed_callable):
		hitbox_component.connect("hit_landed", hit_landed_callable)
	state_coordinator.setup(self)
	debug_view.setup(debug_label, hitbox_component, hurtbox_component)
	presentation_controller.refresh_from_player(self)


func _connect_attack_controller_signals() -> void:
	attack_controller.combo_completed.connect(func() -> void: combo_completed.emit())
	attack_controller.counter_attack_finished.connect(_on_counter_attack_finished)
	attack_controller.locomotion_refresh_requested.connect(
		func() -> void: _update_locomotion_state(input_controller.move_axis)
	)


func _connect_red_brand_controller_signals() -> void:
	red_brand_controller.brand_breaker_charge_started.connect(func() -> void: brand_breaker_charge_started.emit())
	red_brand_controller.brand_breaker_charge_updated.connect(
		func(charge_time: float, preview_level: int) -> void:
			brand_breaker_charge_updated.emit(charge_time, preview_level)
	)
	red_brand_controller.brand_breaker_charge_cancelled.connect(func() -> void: brand_breaker_charge_cancelled.emit())
	red_brand_controller.brand_breaker_released.connect(
		func(level: int, cost: float) -> void: brand_breaker_released.emit(level, cost)
	)
	red_brand_controller.screen_shake_requested.connect(_on_screen_shake_requested)
	red_brand_controller.hitstop_requested.connect(_on_hitstop_requested)


func _connect_defense_controller_signals() -> void:
	defense_controller.dodge_started.connect(func() -> void: dodge_started.emit())
	defense_controller.dodge_finished.connect(func() -> void: dodge_finished.emit())
	defense_controller.counter_success.connect(
		func(attack_data: Resource, attacker: Node) -> void: counter_success.emit(attack_data, attacker)
	)
	defense_controller.counter_resolved.connect(func(result: String) -> void: counter_resolved.emit(result))
	defense_controller.screen_shake_requested.connect(_on_screen_shake_requested)
	defense_controller.hitstop_requested.connect(_on_hitstop_requested)
	defense_controller.locomotion_refresh_requested.connect(
		func() -> void: _update_locomotion_state(input_controller.move_axis)
	)


func _connect_taunt_controller_signals() -> void:
	taunt_controller.taunt_started.connect(
		func(phrase: String, line_id: StringName) -> void: taunt_started.emit(phrase, line_id)
	)
	taunt_controller.taunt_performed.connect(
		func(phrase: String, context: Dictionary) -> void: taunt_performed.emit(phrase, context)
	)
	taunt_controller.locomotion_refresh_requested.connect(
		func() -> void: _update_locomotion_state(input_controller.move_axis)
	)


func _bind_lock_manager() -> void:
	if _lock_manager != null:
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("gameplay_lock_manager"):
		if node is GameplayLockManager:
			_lock_manager = node as GameplayLockManager
			if not _lock_manager.player_input_blocked_changed.is_connected(_on_gameplay_input_blocked_changed):
				_lock_manager.player_input_blocked_changed.connect(_on_gameplay_input_blocked_changed)
			return


func _release_legacy_player_locks() -> void:
	clear_input_locks()


func _on_gameplay_input_blocked_changed(_is_blocked: bool) -> void:
	if _is_gameplay_input_blocked():
		velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	input_controller.update_jump_buffer(delta)
	movement_controller.update_coyote_timer(delta)
	_handle_debug_requests()
	attack_controller.update_combo_timers(delta)
	defense_controller.update_dodge_cooldown(delta)
	defense_controller.update_counter_cooldown(delta)
	taunt_controller.update_taunt_cooldown(delta)

	var input_blocked := _is_gameplay_input_blocked()
	input_controller.poll(input_blocked)

	if input_blocked:
		movement_controller.apply_input_lock(delta)
		state_coordinator.apply_blocked_state()
		_refresh_presentation_and_debug()
		return

	defense_controller.handle_dodge_input()
	defense_controller.handle_counter_input()
	taunt_controller.handle_taunt_input()
	red_brand_controller.handle_input(
		delta,
		input_controller.special_pressed,
		input_controller.special_just_pressed
	)
	_handle_interaction_input()
	if not _is_dodging() and not _is_countering() and not _is_taunting() and not _is_charging_brand_breaker():
		attack_controller.handle_attack_input(input_controller.attack_just_pressed)

	var input_direction := input_controller.move_axis
	if _is_dodging():
		movement_controller.apply_dodge_movement(delta)
	elif _is_countering() and not attack_controller.is_executing_counter_attack:
		movement_controller.apply_counter_movement(delta)
	elif _is_taunting():
		movement_controller.apply_taunt_movement(delta)
	elif _is_charging_brand_breaker():
		movement_controller.apply_brand_charge_movement(delta)
	elif _is_attacking():
		movement_controller.apply_attack_movement(delta)
	else:
		movement_controller.apply_horizontal_movement(input_direction, delta)

	movement_controller.apply_gravity(delta)
	if not _is_attacking() and not _is_dodging() and not _is_countering() and not _is_taunting() and not _is_charging_brand_breaker():
		_try_buffered_jump()
		movement_controller.apply_variable_jump_cut(input_controller.jump_just_released)

	attack_controller.update_attack_timing(delta)
	defense_controller.update_dodge_timing(delta)
	defense_controller.update_counter_timing(delta)
	taunt_controller.update_taunt_timing(delta)
	red_brand_controller.update_charge(delta, input_controller.special_pressed)
	movement_controller.move_and_slide()
	movement_controller.refresh_ground_state()
	state_coordinator.apply_post_movement_state(input_direction)
	movement_controller.recover_if_out_of_arena()
	_refresh_presentation_and_debug()


func can_interact_now() -> bool:
	if _is_gameplay_input_blocked():
		return false

	if _is_dead():
		return false

	match current_state:
		PlayerState.HURT, PlayerState.DEAD, PlayerState.INTERACT:
			return false

	if attack_controller.is_attacking() or _is_dodging() or _is_countering() or _is_taunting() or _is_charging_brand_breaker():
		return false

	return true


func is_in_dialogue() -> bool:
	if _lock_manager != null:
		return _lock_manager.has_lock(GameplayLockManager.LockReason.DIALOGUE)
	return _dialogue_lock_token != null and _dialogue_lock_token.valid


func is_in_transition() -> bool:
	if _lock_manager != null:
		return _lock_manager.has_lock(GameplayLockManager.LockReason.AREA_TRANSITION)
	return _transition_lock_token != null and _transition_lock_token.valid


func enter_transition_mode() -> void:
	_bind_lock_manager()
	if _transition_lock_token != null and _transition_lock_token.valid:
		return

	if _lock_manager != null:
		_transition_lock_token = _lock_manager.acquire_lock(
			GameplayLockManager.LockReason.AREA_TRANSITION,
			self
		)

	velocity = Vector2.ZERO
	interrupt_attack(PlayerState.INTERACT)
	current_state = PlayerState.INTERACT


func exit_transition_mode() -> void:
	if _lock_manager != null and _transition_lock_token != null and _transition_lock_token.valid:
		_lock_manager.release_lock(_transition_lock_token)
	_transition_lock_token = null
	velocity = Vector2.ZERO
	if current_state == PlayerState.INTERACT:
		current_state = PlayerState.IDLE


func apply_area_settings(settings: Dictionary) -> void:
	if settings.has("fall_recovery_y"):
		fall_recovery_y = float(settings.get("fall_recovery_y"))


func get_spawn_position() -> Vector2:
	return spawn_position


func set_spawn_position(position: Vector2) -> void:
	spawn_position = position


func apply_checkpoint(
	checkpoint_position: Vector2,
	restore_health: bool,
	restore_red_brand: bool
) -> void:
	spawn_position = checkpoint_position
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	movement_controller.reset_jump_timers()
	input_controller.reset_jump_buffer()
	attack_controller.cancel_attack_sequence(PlayerState.IDLE)
	_cancel_dodge(PlayerState.IDLE)
	_cancel_counter(PlayerState.IDLE)
	_cancel_taunt(PlayerState.IDLE)
	red_brand_controller.cancel_brand_breaker_charge(PlayerState.IDLE)

	if restore_health and health_component != null:
		health_component.reset_health()
		_release_death_lock()

	if restore_red_brand and red_brand_component != null:
		red_brand_component.reset_energy()


func apply_save_state(save_data: Dictionary) -> void:
	exit_dialogue_mode()
	exit_transition_mode()
	_release_death_lock()

	var position_data := save_data.get("checkpoint_position", {}) as Dictionary
	var restored_position := Vector2(
		float(position_data.get("x", global_position.x)),
		float(position_data.get("y", global_position.y))
	)
	spawn_position = restored_position
	global_position = restored_position
	velocity = Vector2.ZERO
	movement_controller.reset_jump_timers()
	input_controller.reset_jump_buffer()
	attack_controller.cancel_attack_sequence(PlayerState.IDLE)
	_cancel_dodge(PlayerState.IDLE)
	_cancel_counter(PlayerState.IDLE)
	_cancel_taunt(PlayerState.IDLE)
	red_brand_controller.cancel_brand_breaker_charge(PlayerState.IDLE)

	if health_component != null:
		health_component.set_health_values(
			float(save_data.get("player_current_health", health_component.current_health)),
			float(save_data.get("player_max_health", health_component.max_health))
		)

	if red_brand_component != null:
		red_brand_component.set_energy(
			float(save_data.get("red_brand_energy", red_brand_component.current_energy))
		)


func enter_dialogue_mode() -> void:
	_bind_lock_manager()
	if _dialogue_lock_token != null and _dialogue_lock_token.valid:
		return

	if _lock_manager != null:
		_dialogue_lock_token = _lock_manager.acquire_lock(
			GameplayLockManager.LockReason.DIALOGUE,
			self
		)

	interrupt_attack(PlayerState.INTERACT)
	velocity = Vector2.ZERO
	current_state = PlayerState.INTERACT


func exit_dialogue_mode() -> void:
	if _lock_manager != null and _dialogue_lock_token != null and _dialogue_lock_token.valid:
		_lock_manager.release_lock(_dialogue_lock_token)
	_dialogue_lock_token = null
	velocity = Vector2.ZERO
	if current_state == PlayerState.INTERACT and not _is_gameplay_input_blocked():
		current_state = PlayerState.IDLE


func clear_input_locks() -> void:
	exit_dialogue_mode()
	exit_transition_mode()
	if _lock_manager != null:
		_lock_manager.release_locks_for_owner(self)
	_release_death_lock()
	velocity = Vector2.ZERO
	if current_state == PlayerState.INTERACT and not _is_gameplay_input_blocked():
		current_state = PlayerState.IDLE


func get_health_component() -> Node:
	return health_component


func get_red_brand_component() -> RedBrandComponent:
	return red_brand_component


func export_save_state() -> Dictionary:
	return capture_persistence_state()


func import_save_state(save_data: Dictionary) -> void:
	apply_save_state(save_data)


func is_player_dodging() -> bool:
	return defense_controller.is_dodging()


func is_player_invulnerable() -> bool:
	return health_component != null and health_component.invulnerable


func capture_persistence_state() -> Dictionary:
	var state := {
		"spawn_position": {"x": spawn_position.x, "y": spawn_position.y},
		"max_health": 12.0,
		"current_health": 12.0,
		"red_brand_energy": 0.0,
	}

	if health_component != null:
		state["max_health"] = health_component.max_health
		state["current_health"] = health_component.current_health

	if red_brand_component != null:
		state["red_brand_energy"] = red_brand_component.current_energy

	return state


func get_interaction_debug_info() -> Dictionary:
	if interaction_detector == null:
		return {
			"id": "none",
			"distance": -1.0,
			"priority": 0,
		}

	return {
		"id": String(interaction_detector.get("current_interaction_id")),
		"distance": float(interaction_detector.get("current_interaction_distance")),
		"priority": int(interaction_detector.get("current_interaction_priority")),
	}


func _handle_interaction_input() -> void:
	if not input_controller.interact_just_pressed:
		return

	if interaction_detector == null or not interaction_detector.has_method("try_interact"):
		return

	if not can_interact_now():
		return

	interaction_detector.call("try_interact")


func _reset_jump_buffer() -> void:
	input_controller.reset_jump_buffer()


func _reset_combat_on_recovery() -> void:
	attack_controller.interrupt_offensive(PlayerState.IDLE)
	red_brand_controller.cancel_brand_breaker_charge(PlayerState.IDLE)
	_cancel_dodge(PlayerState.IDLE)
	_cancel_counter(PlayerState.IDLE)
	_cancel_taunt(PlayerState.IDLE)


func _refresh_presentation_and_debug() -> void:
	presentation_controller.refresh_from_player(self)
	visual_controller.refresh_from_player(attack_controller)
	debug_view.refresh(_build_debug_snapshot())


func _handle_debug_requests() -> void:
	if input_controller.debug_toggle_just_pressed:
		debug_view.toggle_visibility()
	if input_controller.debug_reset_just_pressed:
		if _is_dead():
			_perform_death_respawn()
		else:
			movement_controller.recover_to_spawn()


func _build_debug_snapshot() -> Dictionary:
	var interaction_debug := get_interaction_debug_info()
	return {
		"state_name": _get_state_name(current_state),
		"velocity_x": velocity.x,
		"velocity_y": velocity.y,
		"is_on_floor": is_on_floor(),
		"coyote_time_remaining": movement_controller.coyote_time_remaining,
		"jump_buffer_remaining": input_controller.jump_buffer_remaining,
		"facing_direction": facing_direction,
		"attack_name": attack_controller.get_attack_display_name(attack_controller.current_attack),
		"combo_index_display": attack_controller.current_combo_index + 1,
		"combo_size": combo_attacks.size(),
		"buffered_attack_name": attack_controller.get_buffered_attack_display_name(),
		"combo_buffer_time_remaining": attack_controller.combo_input_buffer_time_remaining,
		"attack_phase_name": attack_controller.get_attack_phase_name(attack_controller.attack_phase),
		"attack_phase_time_remaining": attack_controller.attack_phase_time_remaining,
		"last_hit_target_name": attack_controller.last_hit_target_name,
		"dodge_phase_name": defense_controller.get_dodge_phase_name(dodge_phase),
		"dodge_elapsed_time": dodge_elapsed_time,
		"is_invulnerable": _is_health_invulnerable(),
		"dodge_recovery_remaining": defense_controller.get_dodge_recovery_time_remaining(),
		"dodge_cooldown_remaining": dodge_cooldown_time_remaining,
		"counter_phase_name": defense_controller.get_counter_phase_name(counter_phase),
		"counter_window_remaining": counter_phase_time_remaining if defense_controller.is_in_counter_window() else 0.0,
		"counter_recovery_remaining": defense_controller.get_counter_recovery_time_remaining(),
		"counter_cooldown_remaining": counter_cooldown_time_remaining,
		"last_counter_result": last_counter_result,
		"last_incoming_attack_name": last_incoming_attack_name,
		"last_incoming_counterable": last_incoming_counterable,
		"taunt_elapsed_time": taunt_elapsed_time if _is_taunting() else 0.0,
		"taunt_vulnerable": taunt_controller.is_taunt_vulnerability_window_active(),
		"taunt_cooldown_remaining": taunt_cooldown_time_remaining,
		"taunt_phrase": current_taunt_phrase if not current_taunt_phrase.is_empty() else "none",
		"red_brand_current": float(red_brand_component.current_energy) if red_brand_component != null else 0.0,
		"red_brand_max": float(red_brand_component.max_energy) if red_brand_component != null else 0.0,
		"brand_charge_level": red_brand_controller.brand_charge_level,
		"brand_breaker_release_cost": red_brand_controller.brand_breaker_release_cost,
		"brand_charge_time": red_brand_controller.brand_charge_time if _is_charging_brand_breaker() else 0.0,
		"brand_breaker_state_name": red_brand_controller.get_brand_breaker_state_name(),
		"input_blocked": _is_gameplay_input_blocked(),
		"interact_id": String(interaction_debug.get("id", "none")),
		"interact_distance": float(interaction_debug.get("distance", -1.0)),
		"interact_priority": int(interaction_debug.get("priority", 0)),
	}


var coyote_time_remaining: float:
	get:
		return movement_controller.coyote_time_remaining
	set(value):
		movement_controller.coyote_time_remaining = value


var jump_buffer_remaining: float:
	get:
		return input_controller.jump_buffer_remaining
	set(value):
		input_controller.jump_buffer_remaining = value


var debug_visible: bool:
	get:
		return debug_view.visible_in_game
	set(value):
		debug_view.set_debug_visible(value)


var current_attack: Resource:
	get:
		return attack_controller.current_attack


var attack_phase: int:
	get:
		return attack_controller.attack_phase
	set(value):
		attack_controller.attack_phase = value


var attack_phase_time_remaining: float:
	get:
		return attack_controller.attack_phase_time_remaining
	set(value):
		attack_controller.attack_phase_time_remaining = value


var attack_elapsed_time: float:
	get:
		return attack_controller.attack_elapsed_time
	set(value):
		attack_controller.attack_elapsed_time = value


var current_combo_index: int:
	get:
		return attack_controller.current_combo_index


var buffered_combo_attack_index: int:
	get:
		return attack_controller.buffered_combo_attack_index


var combo_input_buffer_time_remaining: float:
	get:
		return attack_controller.combo_input_buffer_time_remaining


var combo_reset_time_remaining: float:
	get:
		return attack_controller.combo_reset_time_remaining


var last_hit_target_name: String:
	get:
		return attack_controller.last_hit_target_name


var brand_breaker_phase: int:
	get:
		return red_brand_controller.brand_breaker_phase


var brand_charge_time: float:
	get:
		return red_brand_controller.brand_charge_time
	set(value):
		red_brand_controller.brand_charge_time = value


var brand_charge_level: int:
	get:
		return red_brand_controller.brand_charge_level


var brand_breaker_release_cost: float:
	get:
		return red_brand_controller.brand_breaker_release_cost


var is_executing_brand_breaker: bool:
	get:
		return red_brand_controller.is_executing_brand_breaker


var is_executing_counter_attack: bool:
	get:
		return attack_controller.is_executing_counter_attack


var dodge_phase: int:
	get:
		return defense_controller.dodge_phase
	set(value):
		defense_controller.dodge_phase = value


var dodge_phase_time_remaining: float:
	get:
		return defense_controller.dodge_phase_time_remaining
	set(value):
		defense_controller.dodge_phase_time_remaining = value


var dodge_elapsed_time: float:
	get:
		return defense_controller.dodge_elapsed_time
	set(value):
		defense_controller.dodge_elapsed_time = value


var dodge_direction: int:
	get:
		return defense_controller.dodge_direction
	set(value):
		defense_controller.dodge_direction = value


var dodge_cooldown_time_remaining: float:
	get:
		return defense_controller.dodge_cooldown_time_remaining
	set(value):
		defense_controller.dodge_cooldown_time_remaining = value


var counter_phase: int:
	get:
		return defense_controller.counter_phase
	set(value):
		defense_controller.counter_phase = value


var counter_phase_time_remaining: float:
	get:
		return defense_controller.counter_phase_time_remaining
	set(value):
		defense_controller.counter_phase_time_remaining = value


var counter_elapsed_time: float:
	get:
		return defense_controller.counter_elapsed_time
	set(value):
		defense_controller.counter_elapsed_time = value


var counter_cooldown_time_remaining: float:
	get:
		return defense_controller.counter_cooldown_time_remaining
	set(value):
		defense_controller.counter_cooldown_time_remaining = value


var last_counter_result: String:
	get:
		return defense_controller.last_counter_result
	set(value):
		defense_controller.last_counter_result = value


var last_incoming_attack_name: String:
	get:
		return defense_controller.last_incoming_attack_name
	set(value):
		defense_controller.last_incoming_attack_name = value


var last_incoming_counterable: bool:
	get:
		return defense_controller.last_incoming_counterable
	set(value):
		defense_controller.last_incoming_counterable = value


var taunt_time_remaining: float:
	get:
		return taunt_controller.taunt_time_remaining
	set(value):
		taunt_controller.taunt_time_remaining = value


var taunt_elapsed_time: float:
	get:
		return taunt_controller.taunt_elapsed_time
	set(value):
		taunt_controller.taunt_elapsed_time = value


var taunt_cooldown_time_remaining: float:
	get:
		return taunt_controller.taunt_cooldown_time_remaining
	set(value):
		taunt_controller.taunt_cooldown_time_remaining = value


var current_taunt_phrase: String:
	get:
		return taunt_controller.current_taunt_phrase
	set(value):
		taunt_controller.current_taunt_phrase = value


var current_taunt_line_id: StringName:
	get:
		return taunt_controller.current_taunt_line_id
	set(value):
		taunt_controller.current_taunt_line_id = value


func _on_hit_landed(target: Node, _hurtbox: Area2D, attack_data: Resource) -> void:
	attack_controller.on_hit_landed(target, attack_data)
	red_brand_controller.on_hit_landed(target, attack_data)


func _on_screen_shake_requested(intensity: float, duration: float) -> void:
	for node in get_tree().get_nodes_in_group(CAMERA_CONTROLLER_GROUP):
		if node.has_method("request_shake"):
			node.call("request_shake", intensity, duration)
			return


func _on_hitstop_requested(duration: float) -> void:
	if duration <= 0.0:
		return

	for node in get_tree().get_nodes_in_group(HITSTOP_GROUP):
		if node.has_method("request_hitstop"):
			node.call("request_hitstop", duration)
			return


func _on_counter_attack_finished() -> void:
	defense_controller.on_counter_attack_finished()


func _is_gameplay_input_blocked() -> bool:
	if _lock_manager != null:
		return _lock_manager.is_player_input_blocked()
	return (
		(_dialogue_lock_token != null and _dialogue_lock_token.valid)
		or (_transition_lock_token != null and _transition_lock_token.valid)
		or (_death_lock_token != null and _death_lock_token.valid)
	)


func _release_death_lock() -> void:
	if _lock_manager != null and _death_lock_token != null and _death_lock_token.valid:
		_lock_manager.release_lock(_death_lock_token)
	_death_lock_token = null


func set_facing_direction(direction: int) -> void:
	movement_controller.set_facing_direction(direction)


func can_cancel_attack() -> bool:
	return attack_controller.can_cancel_attack()


func interrupt_attack(next_state: int = PlayerState.HURT) -> void:
	attack_controller.interrupt_offensive(next_state)
	red_brand_controller.cancel_brand_breaker_charge(next_state)
	_cancel_dodge(next_state)
	_cancel_counter(next_state)
	_cancel_taunt(next_state)


func try_counter_hit(attack_data: Resource, _hitbox: Area2D, attacker: Node) -> bool:
	return defense_controller.try_counter_hit(attack_data, _hitbox, attacker)


func _connect_combat_signals() -> void:
	var damaged_callable := Callable(self, "_on_player_damaged")
	if health_component.has_signal("damaged") and not health_component.is_connected("damaged", damaged_callable):
		health_component.connect("damaged", damaged_callable)

	var died_callable := Callable(self, "_on_player_died")
	if health_component.has_signal("died") and not health_component.is_connected("died", died_callable):
		health_component.connect("died", died_callable)


func _try_buffered_jump() -> void:
	if movement_controller.try_buffered_jump(input_controller.jump_buffer_remaining):
		input_controller.jump_buffer_remaining = 0.0
		current_state = PlayerState.JUMP


func _can_accept_attack_input() -> bool:
	if _is_gameplay_input_blocked():
		return false

	if current_state == PlayerState.DEAD or current_state == PlayerState.INTERACT or current_state == PlayerState.DODGE or current_state == PlayerState.HURT or current_state == PlayerState.COUNTER or current_state == PlayerState.TAUNT:
		return false

	return not _is_dead()


func _start_attack_at_index(attack_index: int) -> void:
	attack_controller.start_attack_at_index(attack_index)


func _buffer_next_combo_attack() -> void:
	attack_controller.buffer_next_combo_attack()


func _can_start_brand_charge() -> bool:
	return red_brand_controller.can_start_brand_charge()


func _start_brand_charge() -> void:
	red_brand_controller.start_brand_charge()


func _release_brand_breaker() -> void:
	red_brand_controller.release_brand_breaker()


func _cancel_brand_breaker_charge(next_state: int = PlayerState.IDLE) -> void:
	red_brand_controller.cancel_brand_breaker_charge(next_state)


func _start_ground_dodge() -> void:
	defense_controller.start_ground_dodge()


func _start_counter() -> void:
	defense_controller.start_counter()


func _start_taunt() -> void:
	taunt_controller.start_taunt()


func _update_dodge_invulnerability() -> void:
	defense_controller.update_dodge_invulnerability()


func _update_taunt_vulnerability() -> void:
	taunt_controller.update_taunt_vulnerability()


func _cancel_dodge(next_state: int = PlayerState.IDLE) -> void:
	defense_controller.cancel_dodge(next_state)


func _cancel_counter(next_state: int = PlayerState.IDLE) -> void:
	defense_controller.cancel_counter(next_state)


func _cancel_taunt(next_state: int = PlayerState.IDLE) -> void:
	taunt_controller.cancel_taunt(next_state)


func _update_locomotion_state(input_direction: float) -> void:
	state_coordinator.update_locomotion(input_direction)


func _is_countering() -> bool:
	return defense_controller.is_countering()


func _is_in_counter_window() -> bool:
	return defense_controller.is_in_counter_window()


func _is_taunting() -> bool:
	return taunt_controller.is_taunting()


func _is_health_invulnerable() -> bool:
	return health_component != null and bool(health_component.get("invulnerable"))


func _is_dodging() -> bool:
	return defense_controller.is_dodging()


func _is_attacking() -> bool:
	return attack_controller.is_attacking()


func _is_charging_brand_breaker() -> bool:
	return red_brand_controller.is_charging_brand_breaker()


func _is_dead() -> bool:
	return health_component != null and bool(health_component.get("is_dead"))


func _apply_horizontal_movement(input_direction: float, delta: float) -> void:
	movement_controller.apply_horizontal_movement(input_direction, delta)


func _get_state_name(state: int) -> String:
	match state:
		PlayerState.IDLE:
			return "idle"
		PlayerState.RUN:
			return "run"
		PlayerState.JUMP:
			return "jump"
		PlayerState.FALL:
			return "fall"
		PlayerState.ATTACK:
			return "attack"
		PlayerState.DODGE:
			return "dodge"
		PlayerState.COUNTER:
			return "counter"
		PlayerState.TAUNT:
			return "taunt"
		PlayerState.HURT:
			return "hurt"
		PlayerState.DEAD:
			return "dead"
		PlayerState.INTERACT:
			return "interact"
		_:
			return "unknown"


func _on_player_damaged(_amount: float, _source: Node) -> void:
	if current_state == PlayerState.DEAD:
		return

	defense_controller.on_player_damaged_during_counter_window()
	interrupt_attack(PlayerState.HURT)


func _on_player_died() -> void:
	interrupt_attack(PlayerState.DEAD)
	velocity = Vector2.ZERO
	_bind_lock_manager()
	if _lock_manager != null and (_death_lock_token == null or not _death_lock_token.valid):
		_death_lock_token = _lock_manager.acquire_lock(GameplayLockManager.LockReason.DEATH, self)
	_schedule_death_respawn()


func _schedule_death_respawn() -> void:
	if _death_respawn_pending:
		return
	_death_respawn_pending = true

	var tree := get_tree()
	if tree == null:
		_death_respawn_pending = false
		return

	var timer := tree.create_timer(DEATH_RESPAWN_DELAY, true)
	timer.timeout.connect(_perform_death_respawn, CONNECT_ONE_SHOT)


func _perform_death_respawn() -> void:
	_death_respawn_pending = false
	if not is_inside_tree() or health_component == null:
		return
	if not bool(health_component.get("is_dead")):
		_release_death_lock()
		return

	var respawn_position := spawn_position
	if respawn_position == Vector2.ZERO:
		respawn_position = global_position

	apply_checkpoint(respawn_position, true, false)
	current_state = PlayerState.IDLE
	_release_death_lock()
	_reset_combat_on_recovery()
	_refresh_presentation_and_debug()
