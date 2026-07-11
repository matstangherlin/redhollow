extends CharacterBody2D

const RUN_SPEED_THRESHOLD := 1.0
const ATTACK_MOVEMENT_DECELERATION_SCALE := 0.75
const NO_BUFFERED_ATTACK := -1
const PLAYER_BODY_COLOR := Color(0.76, 0.18, 0.13, 1.0)
const DODGE_BODY_COLOR := Color(0.95, 0.42, 0.22, 1.0)
const DODGE_BODY_SCALE := Vector2(1.28, 0.82)
const COUNTER_WINDOW_BODY_COLOR := Color(0.28, 0.58, 0.95, 1.0)
const COUNTER_RECOVERY_BODY_COLOR := Color(0.48, 0.48, 0.52, 1.0)
const COUNTER_ATTACK_BODY_COLOR := Color(0.92, 0.72, 0.18, 1.0)
const TAUNT_BODY_COLOR := Color(0.82, 0.24, 0.42, 1.0)
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

const DEFAULT_BRAND_HAND_COLOR := Color(1.0, 0.06, 0.02, 1.0)
const CHARGING_BRAND_HAND_COLOR := Color(1.0, 0.42, 0.08, 1.0)
const MAX_CHARGE_BRAND_HAND_COLOR := Color(1.0, 0.82, 0.18, 1.0)

var current_state: int = PlayerState.IDLE
var facing_direction: int = 1
var coyote_time_remaining: float = 0.0
var jump_buffer_remaining: float = 0.0
var debug_visible: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var current_attack: Resource
var attack_phase: int = AttackPhase.NONE
var attack_phase_time_remaining: float = 0.0
var attack_elapsed_time: float = 0.0
var current_combo_index: int = 0
var buffered_combo_attack_index: int = NO_BUFFERED_ATTACK
var combo_input_buffer_time_remaining: float = 0.0
var combo_reset_time_remaining: float = 0.0
var last_hit_target_name: String = "none"
var dodge_phase: int = DodgePhase.NONE
var dodge_phase_time_remaining: float = 0.0
var dodge_elapsed_time: float = 0.0
var dodge_direction: int = 1
var dodge_cooldown_time_remaining: float = 0.0
var dodge_invulnerability_applied: bool = false
var was_invulnerable_before_dodge: bool = false
var counter_phase: int = CounterPhase.NONE
var counter_phase_time_remaining: float = 0.0
var counter_elapsed_time: float = 0.0
var counter_cooldown_time_remaining: float = 0.0
var is_executing_counter_attack: bool = false
var last_counter_result: String = "none"
var last_incoming_attack_name: String = "none"
var last_incoming_counterable: bool = false
var taunt_time_remaining: float = 0.0
var taunt_elapsed_time: float = 0.0
var taunt_cooldown_time_remaining: float = 0.0
var current_taunt_phrase: String = ""
var current_taunt_line_id: StringName = &""
var taunt_vulnerability_applied: bool = false
var was_invulnerable_before_taunt: bool = false
var _taunt_phrase_bag: Array[String] = []
var _last_taunt_phrase: String = ""
var brand_breaker_phase: int = BrandBreakerPhase.NONE
var brand_charge_time: float = 0.0
var brand_charge_level: int = 0
var brand_breaker_release_cost: float = 0.0
var is_executing_brand_breaker: bool = false
var _lock_manager: GameplayLockManager = null
var _dialogue_lock_token: GameplayLockToken = null
var _transition_lock_token: GameplayLockToken = null
var _death_lock_token: GameplayLockToken = null


func _ready() -> void:
	add_to_group(PLAYER_GROUP)
	process_mode = Node.PROCESS_MODE_PAUSABLE
	spawn_position = global_position
	floor_snap_length = floor_snap_distance
	set_facing_direction(default_facing_direction)
	_connect_combat_signals()
	_set_debug_visible(false)
	_update_dodge_visual()
	_update_counter_visual()
	call_deferred("_bind_lock_manager")
	call_deferred("_release_legacy_player_locks")


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
	_handle_debug_input()
	_update_timers(delta)
	_update_combo_timers(delta)
	_update_dodge_cooldown(delta)
	_update_counter_cooldown(delta)
	_update_taunt_cooldown(delta)

	if _is_gameplay_input_blocked():
		_apply_input_lock(delta)
		return

	_handle_dodge_input()
	_handle_counter_input()
	_handle_taunt_input()
	_handle_brand_breaker_input(delta)
	_handle_interaction_input()
	if not _is_dodging() and not _is_countering() and not _is_taunting() and not _is_charging_brand_breaker():
		_handle_attack_input()

	var input_direction := _get_input_direction()
	if _is_dodging():
		_apply_dodge_movement(delta)
	elif _is_countering() and not is_executing_counter_attack:
		_apply_counter_movement(delta)
	elif _is_taunting():
		_apply_taunt_movement(delta)
	elif _is_charging_brand_breaker():
		_apply_brand_charge_movement(delta)
	elif _is_attacking():
		_apply_attack_movement(delta)
	else:
		_apply_horizontal_movement(input_direction, delta)

	_apply_gravity(delta)
	if not _is_attacking() and not _is_dodging() and not _is_countering() and not _is_taunting() and not _is_charging_brand_breaker():
		_try_buffered_jump()
		_apply_variable_jump_cut()

	_update_attack_timing(delta)
	_update_dodge_timing(delta)
	_update_counter_timing(delta)
	_update_taunt_timing(delta)
	_update_brand_breaker_charge(delta)
	move_and_slide()

	_refresh_ground_state()
	if _is_charging_brand_breaker():
		current_state = PlayerState.ATTACK
	elif _is_taunting():
		current_state = PlayerState.TAUNT
	elif _is_countering():
		current_state = PlayerState.COUNTER
	elif _is_dodging():
		current_state = PlayerState.DODGE
	elif not _is_attacking():
		_update_locomotion_state(input_direction)
	else:
		current_state = PlayerState.ATTACK

	_recover_if_out_of_arena()
	_update_debug_label()


func can_interact_now() -> bool:
	if _is_gameplay_input_blocked():
		return false

	if _is_dead():
		return false

	match current_state:
		PlayerState.HURT, PlayerState.DEAD, PlayerState.INTERACT:
			return false

	if current_attack != null or _is_dodging() or _is_countering() or _is_taunting() or _is_charging_brand_breaker():
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
	coyote_time_remaining = 0.0
	jump_buffer_remaining = 0.0
	_cancel_attack_sequence(PlayerState.IDLE)
	_cancel_dodge(PlayerState.IDLE)
	_cancel_counter(PlayerState.IDLE)
	_cancel_taunt(PlayerState.IDLE)
	_cancel_brand_breaker_charge(PlayerState.IDLE)

	if restore_health and health_component != null:
		health_component.call("reset_health")
		_release_death_lock()

	if restore_red_brand and red_brand_component != null:
		red_brand_component.call("reset_energy")


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
	coyote_time_remaining = 0.0
	jump_buffer_remaining = 0.0
	_cancel_attack_sequence(PlayerState.IDLE)
	_cancel_dodge(PlayerState.IDLE)
	_cancel_counter(PlayerState.IDLE)
	_cancel_taunt(PlayerState.IDLE)
	_cancel_brand_breaker_charge(PlayerState.IDLE)

	if health_component != null:
		health_component.call(
			"set_health_values",
			float(save_data.get("player_current_health", health_component.get("current_health"))),
			float(save_data.get("player_max_health", health_component.get("max_health")))
		)

	if red_brand_component != null:
		red_brand_component.call(
			"set_energy",
			float(save_data.get("red_brand_energy", red_brand_component.get("current_energy")))
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
	if not Input.is_action_just_pressed("interact"):
		return

	if interaction_detector == null or not interaction_detector.has_method("try_interact"):
		return

	if not can_interact_now():
		return

	interaction_detector.call("try_interact")


func _apply_input_lock(delta: float) -> void:
	velocity = Vector2.ZERO
	_apply_gravity(delta)
	move_and_slide()
	_refresh_ground_state()
	current_state = PlayerState.INTERACT
	_update_debug_label()


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
	if direction == 0:
		return

	facing_direction = 1 if direction > 0 else -1
	_apply_facing_direction()


func can_cancel_attack() -> bool:
	return _is_in_combo_window()


func interrupt_attack(next_state: int = PlayerState.HURT) -> void:
	_cancel_attack_sequence(next_state)
	_cancel_dodge(next_state)
	_cancel_counter(next_state)
	_cancel_taunt(next_state)
	_cancel_brand_breaker_charge(next_state)


func try_counter_hit(attack_data: Resource, _hitbox: Area2D, attacker: Node) -> bool:
	last_incoming_attack_name = _get_attack_display_name(attack_data)
	last_incoming_counterable = attack_data != null and bool(attack_data.get("counterable"))

	if counter_phase != CounterPhase.WINDOW:
		last_counter_result = "miss_window"
		return false

	if attack_data == null or not last_incoming_counterable:
		last_counter_result = "not_counterable"
		return false

	last_counter_result = "success"
	if attacker is Node2D:
		var direction := signi(int((attacker as Node2D).global_position.x - global_position.x))
		if direction != 0:
			set_facing_direction(direction)

	return true


func _connect_combat_signals() -> void:
	var hit_landed_callable := Callable(self, "_on_hit_landed")
	if hitbox_component.has_signal("hit_landed") and not hitbox_component.is_connected("hit_landed", hit_landed_callable):
		hitbox_component.connect("hit_landed", hit_landed_callable)

	var damaged_callable := Callable(self, "_on_player_damaged")
	if health_component.has_signal("damaged") and not health_component.is_connected("damaged", damaged_callable):
		health_component.connect("damaged", damaged_callable)

	var died_callable := Callable(self, "_on_player_died")
	if health_component.has_signal("died") and not health_component.is_connected("died", died_callable):
		health_component.connect("died", died_callable)

	var hit_countered_callable := Callable(self, "_on_hit_countered")
	if hurtbox_component.has_signal("hit_countered") and not hurtbox_component.is_connected("hit_countered", hit_countered_callable):
		hurtbox_component.connect("hit_countered", hit_countered_callable)


func _get_input_direction() -> float:
	return Input.get_axis("move_left", "move_right")


func _apply_horizontal_movement(input_direction: float, delta: float) -> void:
	if not is_zero_approx(input_direction):
		set_facing_direction(1 if input_direction > 0.0 else -1)

	var target_speed := input_direction * max_run_speed
	var acceleration := _get_acceleration_for(input_direction)
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)


func _apply_attack_movement(delta: float) -> void:
	var deceleration := ground_deceleration if is_on_floor() else air_deceleration
	velocity.x = move_toward(velocity.x, 0.0, deceleration * ATTACK_MOVEMENT_DECELERATION_SCALE * delta)


func _apply_dodge_movement(delta: float) -> void:
	match dodge_phase:
		DodgePhase.STARTUP:
			velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		DodgePhase.ACTIVE:
			velocity.x = dodge_speed * float(dodge_direction)
		DodgePhase.RECOVERY:
			velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)


func _get_acceleration_for(input_direction: float) -> float:
	if is_on_floor():
		return ground_acceleration if not is_zero_approx(input_direction) else ground_deceleration

	return air_acceleration if not is_zero_approx(input_direction) else air_deceleration


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y > 0.0:
		velocity.y = 0.0
		return

	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _update_timers(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_remaining = jump_buffer_time
	else:
		jump_buffer_remaining = maxf(jump_buffer_remaining - delta, 0.0)

	if is_on_floor():
		coyote_time_remaining = coyote_time
	else:
		coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)


func _update_combo_timers(delta: float) -> void:
	if _has_buffered_combo_input():
		combo_input_buffer_time_remaining = maxf(combo_input_buffer_time_remaining - delta, 0.0)
		if combo_input_buffer_time_remaining <= 0.0:
			_clear_combo_buffer()

	if current_attack != null or combo_reset_time_remaining <= 0.0:
		return

	combo_reset_time_remaining = maxf(combo_reset_time_remaining - delta, 0.0)
	if combo_reset_time_remaining <= 0.0:
		current_combo_index = 0
		last_hit_target_name = "none"


func _update_dodge_cooldown(delta: float) -> void:
	if dodge_cooldown_time_remaining <= 0.0:
		return

	dodge_cooldown_time_remaining = maxf(dodge_cooldown_time_remaining - delta, 0.0)


func _update_counter_cooldown(delta: float) -> void:
	if counter_cooldown_time_remaining <= 0.0:
		return

	counter_cooldown_time_remaining = maxf(counter_cooldown_time_remaining - delta, 0.0)


func _try_buffered_jump() -> void:
	if jump_buffer_remaining <= 0.0 or coyote_time_remaining <= 0.0:
		return

	velocity.y = jump_velocity
	jump_buffer_remaining = 0.0
	coyote_time_remaining = 0.0
	current_state = PlayerState.JUMP


func _apply_variable_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func _refresh_ground_state() -> void:
	if is_on_floor():
		coyote_time_remaining = coyote_time


func _update_locomotion_state(input_direction: float) -> void:
	if _is_dead():
		current_state = PlayerState.DEAD
		return

	if not is_on_floor():
		current_state = PlayerState.JUMP if velocity.y < 0.0 else PlayerState.FALL
		return

	if absf(velocity.x) > RUN_SPEED_THRESHOLD or not is_zero_approx(input_direction):
		current_state = PlayerState.RUN
	else:
		current_state = PlayerState.IDLE


func _handle_attack_input() -> void:
	if not Input.is_action_just_pressed("attack") or not _can_accept_attack_input():
		return

	if current_attack == null:
		if _can_start_combo():
			_clear_combo_buffer()
			_start_attack_at_index(0)
		return

	if _can_buffer_next_combo_attack():
		_buffer_next_combo_attack()


func _can_accept_attack_input() -> bool:
	if _is_gameplay_input_blocked():
		return false

	if current_state == PlayerState.DEAD or current_state == PlayerState.INTERACT or current_state == PlayerState.DODGE or current_state == PlayerState.HURT or current_state == PlayerState.COUNTER or current_state == PlayerState.TAUNT:
		return false

	return not _is_dead()


func _can_start_combo() -> bool:
	return is_on_floor() and _get_combo_attack(0) != null


func _can_buffer_next_combo_attack() -> bool:
	var next_attack_index := current_combo_index + 1
	return next_attack_index < combo_attacks.size() and _get_combo_attack(next_attack_index) != null and _is_in_combo_window()


func _buffer_next_combo_attack() -> void:
	buffered_combo_attack_index = current_combo_index + 1
	combo_input_buffer_time_remaining = attack_input_buffer_time


func _has_buffered_combo_input() -> bool:
	return buffered_combo_attack_index != NO_BUFFERED_ATTACK and combo_input_buffer_time_remaining > 0.0


func _clear_combo_buffer() -> void:
	buffered_combo_attack_index = NO_BUFFERED_ATTACK
	combo_input_buffer_time_remaining = 0.0


func _is_in_combo_window() -> bool:
	if current_attack == null or not current_attack.has_method("has_cancel_window") or not bool(current_attack.call("has_cancel_window")):
		return false

	return attack_elapsed_time >= float(current_attack.get("cancel_window_start")) and attack_elapsed_time <= float(current_attack.get("cancel_window_end"))


func _get_combo_attack(attack_index: int) -> Resource:
	if attack_index < 0 or attack_index >= combo_attacks.size():
		return null

	return combo_attacks[attack_index]


func _start_attack_at_index(attack_index: int) -> void:
	var attack_data := _get_combo_attack(attack_index)
	if attack_data == null:
		return

	current_combo_index = attack_index
	combo_reset_time_remaining = 0.0
	_start_attack(attack_data)


func _start_attack(attack_data: Resource) -> void:
	current_attack = attack_data
	attack_elapsed_time = 0.0
	attack_phase = AttackPhase.STARTUP
	attack_phase_time_remaining = maxf(float(current_attack.get("startup_time")), 0.0)
	current_state = PlayerState.ATTACK
	last_hit_target_name = "none"
	hitbox_component.call("clear_hit_targets")
	hitbox_component.call("deactivate")

	if is_executing_counter_attack:
		current_state = PlayerState.COUNTER
	elif is_executing_brand_breaker:
		current_state = PlayerState.ATTACK

	if attack_phase_time_remaining <= 0.0:
		_advance_attack_phase()


func _update_attack_timing(delta: float) -> void:
	if current_attack == null:
		return

	attack_elapsed_time += delta
	attack_phase_time_remaining -= delta

	while current_attack != null and attack_phase_time_remaining <= 0.0:
		var overflow := -attack_phase_time_remaining
		_advance_attack_phase()
		if current_attack == null:
			return
		attack_phase_time_remaining -= overflow


func _advance_attack_phase() -> void:
	match attack_phase:
		AttackPhase.STARTUP:
			attack_phase = AttackPhase.ACTIVE
			attack_phase_time_remaining = maxf(float(current_attack.get("active_time")), 0.0)
			hitbox_component.call("activate", current_attack, self, facing_direction)
		AttackPhase.ACTIVE:
			hitbox_component.call("deactivate")
			attack_phase = AttackPhase.RECOVERY
			attack_phase_time_remaining = maxf(float(current_attack.get("recovery_time")), 0.0)
		AttackPhase.RECOVERY:
			_finish_attack()
		_:
			_finish_attack()


func _finish_attack() -> void:
	var next_attack_index := buffered_combo_attack_index
	var finished_combo_index := current_combo_index
	var was_combo_finisher := finished_combo_index == combo_attacks.size() - 1
	hitbox_component.call("deactivate")
	current_attack = null
	attack_phase = AttackPhase.NONE
	attack_phase_time_remaining = 0.0
	attack_elapsed_time = 0.0

	if is_executing_counter_attack:
		is_executing_counter_attack = false
		_finish_counter()
		return

	if is_executing_brand_breaker:
		is_executing_brand_breaker = false
		brand_breaker_release_cost = 0.0
		brand_charge_level = 0
		_update_brand_hand_visual(false, 0)
		_update_locomotion_state(_get_input_direction())
		return

	if was_combo_finisher and not is_executing_brand_breaker:
		combo_completed.emit()

	if _can_start_buffered_attack(next_attack_index):
		_clear_combo_buffer()
		_start_attack_at_index(next_attack_index)
		return

	_clear_combo_buffer()
	combo_reset_time_remaining = combo_reset_time
	_update_locomotion_state(_get_input_direction())


func _can_start_buffered_attack(attack_index: int) -> bool:
	return attack_index != NO_BUFFERED_ATTACK and combo_input_buffer_time_remaining > 0.0 and attack_index == current_combo_index + 1 and attack_index < combo_attacks.size() and is_on_floor() and _can_accept_attack_input()


func _cancel_attack_sequence(next_state: int = PlayerState.IDLE) -> void:
	hitbox_component.call("deactivate")
	current_attack = null
	attack_phase = AttackPhase.NONE
	attack_phase_time_remaining = 0.0
	attack_elapsed_time = 0.0
	current_combo_index = 0
	combo_reset_time_remaining = 0.0
	last_hit_target_name = "none"
	_clear_combo_buffer()
	current_state = next_state


func _handle_dodge_input() -> void:
	if Input.is_action_just_pressed("dodge") and _can_start_ground_dodge():
		_start_ground_dodge()


func _can_start_ground_dodge() -> bool:
	return is_on_floor() and not _is_dead() and current_attack == null and not _is_countering() and not _is_taunting() and not _is_charging_brand_breaker() and dodge_phase == DodgePhase.NONE and dodge_cooldown_time_remaining <= 0.0 and _can_dodge_cancel_current_state()


func _can_dodge_cancel_current_state() -> bool:
	match current_state:
		PlayerState.IDLE, PlayerState.RUN, PlayerState.FALL:
			return true
		_:
			return false


func _start_ground_dodge() -> void:
	var input_direction := _get_input_direction()
	dodge_direction = facing_direction if is_zero_approx(input_direction) else (1 if input_direction > 0.0 else -1)
	set_facing_direction(dodge_direction)
	dodge_phase = DodgePhase.STARTUP
	dodge_phase_time_remaining = maxf(dodge_startup, 0.0)
	dodge_elapsed_time = 0.0
	was_invulnerable_before_dodge = _is_health_invulnerable()
	dodge_invulnerability_applied = false
	current_state = PlayerState.DODGE
	dodge_started.emit()
	_clear_combo_buffer()
	_update_dodge_invulnerability()
	_update_dodge_visual()

	if dodge_phase_time_remaining <= 0.0:
		_advance_dodge_phase()


func _update_dodge_timing(delta: float) -> void:
	if dodge_phase == DodgePhase.NONE:
		return

	dodge_elapsed_time += delta
	dodge_phase_time_remaining -= delta
	_update_dodge_invulnerability()

	while dodge_phase != DodgePhase.NONE and dodge_phase_time_remaining <= 0.0:
		var overflow := -dodge_phase_time_remaining
		_advance_dodge_phase()
		if dodge_phase == DodgePhase.NONE:
			return
		dodge_phase_time_remaining -= overflow
		_update_dodge_invulnerability()


func _advance_dodge_phase() -> void:
	match dodge_phase:
		DodgePhase.STARTUP:
			dodge_phase = DodgePhase.ACTIVE
			dodge_phase_time_remaining = maxf(dodge_duration, 0.0)
			velocity.x = dodge_speed * float(dodge_direction)
		DodgePhase.ACTIVE:
			dodge_phase = DodgePhase.RECOVERY
			dodge_phase_time_remaining = maxf(dodge_recovery, 0.0)
		DodgePhase.RECOVERY:
			_finish_dodge()
		_:
			_finish_dodge()


func _finish_dodge() -> void:
	dodge_phase = DodgePhase.NONE
	dodge_phase_time_remaining = 0.0
	dodge_elapsed_time = 0.0
	_restore_dodge_invulnerability()
	dodge_cooldown_time_remaining = maxf(dodge_cooldown, 0.0)
	dodge_finished.emit()
	_update_dodge_visual()
	_update_locomotion_state(_get_input_direction())


func _cancel_dodge(next_state: int = PlayerState.IDLE) -> void:
	dodge_phase = DodgePhase.NONE
	dodge_phase_time_remaining = 0.0
	dodge_elapsed_time = 0.0
	_restore_dodge_invulnerability()
	_update_dodge_visual()
	current_state = next_state


func _handle_counter_input() -> void:
	if Input.is_action_just_pressed("counter") and _can_start_counter():
		_start_counter()


func _handle_taunt_input() -> void:
	if Input.is_action_just_pressed("taunt") and _can_start_taunt():
		_start_taunt()


func _can_start_taunt() -> bool:
	if _is_dead() or _is_taunting() or _is_dodging() or _is_countering() or _is_charging_brand_breaker():
		return false

	if taunt_cooldown_time_remaining > 0.0:
		return false

	if not is_on_floor():
		return false

	match current_state:
		PlayerState.HURT, PlayerState.DEAD, PlayerState.INTERACT, PlayerState.COUNTER, PlayerState.TAUNT, PlayerState.DODGE:
			return false
		PlayerState.ATTACK:
			return attack_phase == AttackPhase.RECOVERY
		PlayerState.IDLE, PlayerState.RUN, PlayerState.FALL:
			return true
		_:
			return false


func _start_taunt() -> void:
	if _is_attacking():
		hitbox_component.call("deactivate")
		current_attack = null
		attack_phase = AttackPhase.NONE
		attack_phase_time_remaining = 0.0
		attack_elapsed_time = 0.0
		_clear_combo_buffer()

	current_taunt_phrase = _pick_taunt_phrase()
	current_taunt_line_id = StringName("taunt_%d" % _get_taunt_line_index(current_taunt_phrase))
	taunt_time_remaining = maxf(taunt_duration, 0.0)
	taunt_elapsed_time = 0.0
	was_invulnerable_before_taunt = _is_health_invulnerable()
	taunt_vulnerability_applied = false
	current_state = PlayerState.TAUNT
	velocity.x = 0.0
	_update_taunt_vulnerability()
	_update_taunt_visual()

	var context := {
		"line_id": current_taunt_line_id,
		"duration": taunt_duration,
		"vulnerable_start": taunt_vulnerable_start,
		"vulnerable_end": taunt_vulnerable_end,
		"response_tags": PackedStringArray(["provocation", "calder"]),
	}
	taunt_started.emit(current_taunt_phrase, current_taunt_line_id)
	taunt_performed.emit(current_taunt_phrase, context)

	if taunt_time_remaining <= 0.0:
		_finish_taunt()


func _update_taunt_cooldown(delta: float) -> void:
	if taunt_cooldown_time_remaining <= 0.0:
		return

	taunt_cooldown_time_remaining = maxf(taunt_cooldown_time_remaining - delta, 0.0)


func _update_taunt_timing(delta: float) -> void:
	if not _is_taunting():
		return

	taunt_elapsed_time += delta
	taunt_time_remaining -= delta
	_update_taunt_vulnerability()

	if taunt_time_remaining <= 0.0:
		_finish_taunt()


func _finish_taunt() -> void:
	taunt_time_remaining = 0.0
	taunt_elapsed_time = 0.0
	current_taunt_phrase = ""
	current_taunt_line_id = &""
	_restore_taunt_invulnerability()
	taunt_cooldown_time_remaining = maxf(taunt_cooldown, 0.0)
	_update_taunt_visual()
	_update_locomotion_state(_get_input_direction())


func _cancel_taunt(next_state: int = PlayerState.IDLE) -> void:
	if not _is_taunting():
		return

	taunt_time_remaining = 0.0
	taunt_elapsed_time = 0.0
	current_taunt_phrase = ""
	current_taunt_line_id = &""
	_restore_taunt_invulnerability()
	_update_taunt_visual()
	current_state = next_state


func _apply_taunt_movement(delta: float) -> void:
	var deceleration := ground_deceleration if is_on_floor() else air_deceleration
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _update_taunt_vulnerability() -> void:
	var should_be_vulnerable := _is_taunt_vulnerability_window_active()
	if should_be_vulnerable:
		_set_health_invulnerable(false)
		taunt_vulnerability_applied = true
	elif taunt_vulnerability_applied:
		_restore_taunt_invulnerability()


func _is_taunt_vulnerability_window_active() -> bool:
	return _is_taunting() and taunt_vulnerable_end > taunt_vulnerable_start and taunt_elapsed_time >= taunt_vulnerable_start and taunt_elapsed_time <= taunt_vulnerable_end


func _restore_taunt_invulnerability() -> void:
	if not taunt_vulnerability_applied:
		return

	_set_health_invulnerable(was_invulnerable_before_taunt)
	taunt_vulnerability_applied = false


func _is_taunting() -> bool:
	return taunt_time_remaining > 0.0


func _pick_taunt_phrase() -> String:
	var available_phrases := _get_valid_taunt_phrases()
	if available_phrases.is_empty():
		return "Vamos, eu ainda nem comecei."

	if _taunt_phrase_bag.is_empty():
		_taunt_phrase_bag = available_phrases.duplicate()
		_taunt_phrase_bag.shuffle()
		if _taunt_phrase_bag.size() > 1 and _taunt_phrase_bag[0] == _last_taunt_phrase:
			_taunt_phrase_bag.reverse()

	var phrase: String = _taunt_phrase_bag.pop_front()
	_last_taunt_phrase = phrase
	return phrase


func _get_valid_taunt_phrases() -> Array[String]:
	var phrases: Array[String] = []
	for phrase in taunt_phrases:
		if not String(phrase).strip_edges().is_empty():
			phrases.append(String(phrase))
	return phrases


func _get_taunt_line_index(phrase: String) -> int:
	for index in taunt_phrases.size():
		if String(taunt_phrases[index]) == phrase:
			return index
	return 0


func _update_taunt_visual() -> void:
	if body_visual == null or _is_dodging():
		return

	if _is_taunting():
		body_visual.color = TAUNT_BODY_COLOR
		body_visual.scale = Vector2(1.06, 0.96)
	elif _is_countering():
		_update_counter_visual()
	else:
		body_visual.color = PLAYER_BODY_COLOR
		body_visual.scale = Vector2.ONE


func _handle_brand_breaker_input(_delta: float) -> void:
	if brand_breaker_phase == BrandBreakerPhase.CHARGING:
		if not Input.is_action_pressed("special"):
			_release_brand_breaker()
		return

	if Input.is_action_just_pressed("special") and _can_start_brand_charge():
		_start_brand_charge()


func _can_start_brand_charge() -> bool:
	if _is_dead() or _is_charging_brand_breaker() or _is_dodging() or _is_countering() or _is_taunting():
		return false

	if red_brand_component == null or red_brand_component.config == null:
		return false

	if not red_brand_component.can_consume(red_brand_component.config.min_energy_to_charge):
		return false

	if not is_on_floor():
		return false

	match current_state:
		PlayerState.HURT, PlayerState.DEAD, PlayerState.INTERACT, PlayerState.COUNTER, PlayerState.TAUNT, PlayerState.DODGE:
			return false
		PlayerState.ATTACK:
			return attack_phase == AttackPhase.RECOVERY
		PlayerState.IDLE, PlayerState.RUN, PlayerState.FALL:
			return true
		_:
			return false


func _start_brand_charge() -> void:
	if _is_attacking():
		hitbox_component.call("deactivate")
		current_attack = null
		attack_phase = AttackPhase.NONE
		attack_phase_time_remaining = 0.0
		attack_elapsed_time = 0.0
		_clear_combo_buffer()

	brand_breaker_phase = BrandBreakerPhase.CHARGING
	brand_charge_time = 0.0
	brand_charge_level = 0
	brand_breaker_release_cost = 0.0
	velocity.x = 0.0
	brand_breaker_charge_started.emit()
	_update_brand_hand_visual(true, 0)


func _update_brand_breaker_charge(delta: float) -> void:
	if brand_breaker_phase != BrandBreakerPhase.CHARGING:
		return

	if not Input.is_action_pressed("special"):
		return

	brand_charge_time += delta
	var preview_level := _get_preview_charge_level(brand_charge_time)
	if preview_level != brand_charge_level:
		brand_charge_level = preview_level
		_update_brand_hand_visual(true, preview_level)

	brand_breaker_charge_updated.emit(brand_charge_time, preview_level)


func _release_brand_breaker() -> void:
	if brand_breaker_phase != BrandBreakerPhase.CHARGING:
		return

	var desired_level := _get_preview_charge_level(brand_charge_time)
	if desired_level <= 0:
		_cancel_brand_breaker_charge()
		return

	var resolved := _resolve_brand_breaker_release(desired_level)
	if resolved.is_empty():
		_cancel_brand_breaker_charge()
		return

	var level: int = resolved["level"]
	var attack_data: Resource = resolved["attack"]
	var cost: float = resolved["cost"]

	brand_breaker_phase = BrandBreakerPhase.NONE
	brand_charge_level = level
	brand_breaker_release_cost = cost

	if not red_brand_component.consume_energy(cost, &"brand_breaker"):
		_cancel_brand_breaker_charge()
		return

	brand_breaker_released.emit(level, cost)
	_start_brand_breaker_attack(attack_data, level)


func _resolve_brand_breaker_release(desired_level: int) -> Dictionary:
	# Insufficient energy: downgrade to the strongest affordable level instead of blocking entirely.
	if desired_level >= 2 and _can_pay_brand_breaker_cost(2):
		return {
			"level": 2,
			"attack": red_brand_breaker_level_2,
			"cost": _get_brand_breaker_cost(2),
		}

	if desired_level >= 1 and _can_pay_brand_breaker_cost(1):
		return {
			"level": 1,
			"attack": red_brand_breaker_level_1,
			"cost": _get_brand_breaker_cost(1),
		}

	return {}


func _can_pay_brand_breaker_cost(level: int) -> bool:
	if red_brand_component == null:
		return false

	return red_brand_component.can_consume(_get_brand_breaker_cost(level))


func _get_brand_breaker_cost(level: int) -> float:
	var attack_data := red_brand_breaker_level_2 if level >= 2 else red_brand_breaker_level_1
	if attack_data != null and float(attack_data.get("red_brand_cost")) > 0.0:
		return float(attack_data.get("red_brand_cost"))

	if red_brand_component == null or red_brand_component.config == null:
		return 0.0

	return red_brand_component.config.charge_level_2_cost if level >= 2 else red_brand_component.config.charge_level_1_cost


func _get_preview_charge_level(charge_time: float) -> int:
	if red_brand_component == null or red_brand_component.config == null:
		return 0

	var config := red_brand_component.config
	if charge_time >= config.charge_level_2_time and _can_pay_brand_breaker_cost(2):
		return 2
	if charge_time >= config.charge_level_1_time and _can_pay_brand_breaker_cost(1):
		return 1
	return 0


func _start_brand_breaker_attack(attack_data: Resource, level: int) -> void:
	if attack_data == null:
		return

	is_executing_brand_breaker = true
	brand_charge_level = level
	_clear_combo_buffer()
	_update_brand_hand_visual(false, level)
	_start_attack(attack_data)


func _cancel_brand_breaker_charge(next_state: int = PlayerState.IDLE) -> void:
	if brand_breaker_phase == BrandBreakerPhase.NONE and not is_executing_brand_breaker:
		return

	var was_charging := brand_breaker_phase == BrandBreakerPhase.CHARGING
	brand_breaker_phase = BrandBreakerPhase.NONE
	brand_charge_time = 0.0
	brand_charge_level = 0
	brand_breaker_release_cost = 0.0
	_update_brand_hand_visual(false, 0)

	if was_charging:
		brand_breaker_charge_cancelled.emit()

	if is_executing_brand_breaker:
		hitbox_component.call("deactivate")
		current_attack = null
		attack_phase = AttackPhase.NONE
		attack_phase_time_remaining = 0.0
		attack_elapsed_time = 0.0
		is_executing_brand_breaker = false

	current_state = next_state


func _apply_brand_charge_movement(delta: float) -> void:
	var deceleration := ground_deceleration if is_on_floor() else air_deceleration
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _is_charging_brand_breaker() -> bool:
	return brand_breaker_phase == BrandBreakerPhase.CHARGING


func _update_brand_hand_visual(is_charging: bool, preview_level: int) -> void:
	if brand_hand == null:
		return

	if not is_charging:
		brand_hand.color = DEFAULT_BRAND_HAND_COLOR
		brand_hand.scale = Vector2.ONE
		return

	if preview_level >= 2:
		brand_hand.color = MAX_CHARGE_BRAND_HAND_COLOR
		brand_hand.scale = Vector2(1.24, 1.24)
	elif preview_level >= 1:
		brand_hand.color = CHARGING_BRAND_HAND_COLOR
		brand_hand.scale = Vector2(1.12, 1.12)
	else:
		brand_hand.color = CHARGING_BRAND_HAND_COLOR
		brand_hand.scale = Vector2(1.04, 1.04)


func _request_brand_breaker_shake() -> void:
	if red_brand_component == null or red_brand_component.config == null:
		return

	for node in get_tree().get_nodes_in_group(CAMERA_CONTROLLER_GROUP):
		if node.has_method("request_shake"):
			node.call("request_shake", red_brand_component.config.breaker_shake_intensity, red_brand_component.config.breaker_shake_duration)
			return


func _can_start_counter() -> bool:
	if not is_on_floor() or _is_dead() or current_attack != null or _is_dodging() or _is_countering() or _is_taunting() or _is_charging_brand_breaker():
		return false

	if counter_cooldown_time_remaining > 0.0:
		return false

	match current_state:
		PlayerState.HURT, PlayerState.DEAD, PlayerState.INTERACT, PlayerState.COUNTER:
			return false
		_:
			return true


func _start_counter() -> void:
	counter_phase = CounterPhase.STARTUP
	counter_phase_time_remaining = maxf(counter_startup, 0.0)
	counter_elapsed_time = 0.0
	last_counter_result = "pending"
	last_incoming_attack_name = "none"
	last_incoming_counterable = false
	current_state = PlayerState.COUNTER
	_clear_combo_buffer()
	_update_counter_visual()

	if counter_phase_time_remaining <= 0.0:
		_advance_counter_phase()


func _update_counter_timing(delta: float) -> void:
	if counter_phase == CounterPhase.NONE or counter_phase == CounterPhase.COUNTER_ATTACK:
		return

	counter_elapsed_time += delta
	counter_phase_time_remaining -= delta

	while counter_phase != CounterPhase.NONE and counter_phase != CounterPhase.COUNTER_ATTACK and counter_phase_time_remaining <= 0.0:
		var overflow := -counter_phase_time_remaining
		_advance_counter_phase()
		if counter_phase == CounterPhase.NONE or counter_phase == CounterPhase.COUNTER_ATTACK:
			return
		counter_phase_time_remaining -= overflow


func _advance_counter_phase() -> void:
	match counter_phase:
		CounterPhase.STARTUP:
			counter_phase = CounterPhase.WINDOW
			counter_phase_time_remaining = maxf(counter_window, 0.0)
		CounterPhase.WINDOW:
			if last_counter_result != "success":
				last_counter_result = "miss"
				counter_resolved.emit(last_counter_result)
			counter_phase = CounterPhase.RECOVERY
			counter_phase_time_remaining = maxf(counter_recovery, 0.0)
		CounterPhase.RECOVERY:
			_finish_counter()
		_:
			_finish_counter()

	_update_counter_visual()


func _finish_counter() -> void:
	counter_phase = CounterPhase.NONE
	counter_phase_time_remaining = 0.0
	counter_elapsed_time = 0.0
	is_executing_counter_attack = false
	counter_cooldown_time_remaining = maxf(counter_cooldown, 0.0)
	_update_counter_visual()
	_update_locomotion_state(_get_input_direction())


func _cancel_counter(next_state: int = PlayerState.IDLE) -> void:
	if counter_phase == CounterPhase.NONE and not is_executing_counter_attack:
		return

	if is_executing_counter_attack:
		hitbox_component.call("deactivate")
		current_attack = null
		attack_phase = AttackPhase.NONE
		attack_phase_time_remaining = 0.0
		attack_elapsed_time = 0.0
		is_executing_counter_attack = false

	counter_phase = CounterPhase.NONE
	counter_phase_time_remaining = 0.0
	counter_elapsed_time = 0.0
	_update_counter_visual()
	current_state = next_state


func _apply_counter_movement(delta: float) -> void:
	var deceleration := ground_deceleration if is_on_floor() else air_deceleration
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _begin_counter_attack() -> void:
	if counter_attack == null:
		_finish_counter()
		return

	counter_phase = CounterPhase.COUNTER_ATTACK
	is_executing_counter_attack = true
	_update_counter_visual()
	_start_attack(counter_attack)


func _request_counter_hitstop(_attack_data: Resource) -> void:
	var duration := counter_hitstop_duration
	if duration <= 0.0:
		return

	for node in get_tree().get_nodes_in_group(HITSTOP_GROUP):
		if node.has_method("request_hitstop"):
			node.call("request_hitstop", duration)
			return


func _request_screen_shake() -> void:
	for node in get_tree().get_nodes_in_group(CAMERA_CONTROLLER_GROUP):
		if node.has_method("request_shake"):
			node.call("request_shake", counter_shake_intensity, counter_shake_duration)
			return


func _is_countering() -> bool:
	return counter_phase != CounterPhase.NONE


func _is_in_counter_window() -> bool:
	return counter_phase == CounterPhase.WINDOW


func _get_counter_phase_name(phase: int) -> String:
	match phase:
		CounterPhase.STARTUP:
			return "startup"
		CounterPhase.WINDOW:
			return "window"
		CounterPhase.RECOVERY:
			return "recovery"
		CounterPhase.COUNTER_ATTACK:
			return "counter_attack"
		_:
			return "none"


func _get_counter_recovery_time_remaining() -> float:
	return counter_phase_time_remaining if counter_phase == CounterPhase.RECOVERY else 0.0


func _update_counter_visual() -> void:
	if body_visual == null or _is_dodging():
		return

	match counter_phase:
		CounterPhase.WINDOW:
			body_visual.color = COUNTER_WINDOW_BODY_COLOR
			body_visual.scale = Vector2.ONE
		CounterPhase.RECOVERY:
			body_visual.color = COUNTER_RECOVERY_BODY_COLOR
			body_visual.scale = Vector2.ONE
		CounterPhase.COUNTER_ATTACK:
			body_visual.color = COUNTER_ATTACK_BODY_COLOR
			body_visual.scale = Vector2.ONE
		_:
			if not _is_dodging():
				body_visual.color = PLAYER_BODY_COLOR
				body_visual.scale = Vector2.ONE


func _on_hit_countered(attack_data: Resource, _hitbox: Area2D, attacker: Node) -> void:
	counter_success.emit(attack_data, attacker)
	_request_counter_hitstop(attack_data)
	_request_screen_shake()
	_begin_counter_attack()


func _update_dodge_invulnerability() -> void:
	var should_be_invulnerable := _is_dodge_invulnerability_window_active()
	if should_be_invulnerable:
		_set_health_invulnerable(true)
		dodge_invulnerability_applied = true
	elif dodge_invulnerability_applied:
		_restore_dodge_invulnerability()


func _is_dodge_invulnerability_window_active() -> bool:
	return dodge_phase != DodgePhase.NONE and invulnerability_end > invulnerability_start and dodge_elapsed_time >= invulnerability_start and dodge_elapsed_time <= invulnerability_end


func _restore_dodge_invulnerability() -> void:
	if not dodge_invulnerability_applied:
		return

	_set_health_invulnerable(was_invulnerable_before_dodge)
	dodge_invulnerability_applied = false


func _set_health_invulnerable(is_invulnerable: bool) -> void:
	if health_component != null:
		health_component.set("invulnerable", is_invulnerable)


func _is_health_invulnerable() -> bool:
	return health_component != null and bool(health_component.get("invulnerable"))


func _is_dodging() -> bool:
	return dodge_phase != DodgePhase.NONE


func _is_attacking() -> bool:
	return current_attack != null


func _is_dead() -> bool:
	return health_component != null and bool(health_component.get("is_dead"))


func _recover_if_out_of_arena() -> void:
	if global_position.y <= fall_recovery_y:
		return

	_recover_to_spawn()


func _recover_to_spawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	coyote_time_remaining = 0.0
	jump_buffer_remaining = 0.0
	_cancel_attack_sequence(PlayerState.IDLE)
	_cancel_dodge(PlayerState.IDLE)
	_cancel_counter(PlayerState.IDLE)
	_cancel_taunt(PlayerState.IDLE)
	_cancel_brand_breaker_charge(PlayerState.IDLE)


func _handle_debug_input() -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		_set_debug_visible(not debug_visible)

	if Input.is_action_just_pressed("debug_reset"):
		_recover_to_spawn()


func _set_debug_visible(is_visible: bool) -> void:
	debug_visible = is_visible
	debug_label.visible = debug_visible
	hitbox_component.call("set_debug_draw_enabled", debug_visible)
	hurtbox_component.call("set_debug_draw_enabled", debug_visible)
	_update_debug_label()


func _update_debug_label() -> void:
	if not debug_visible:
		return

	var interaction_debug := get_interaction_debug_info()
	debug_label.text = "state: %s\nvelocity.x: %.2f\nvelocity.y: %.2f\nis_on_floor: %s\ncoyote: %.3f\njump_buffer: %.3f\nfacing: %d\nattack: %s\ncombo_index: %d / %d\nbuffered_input: %s\nbuffer_time: %.3f\nattack_phase: %s\nattack_time: %.3f\nlast_hit: %s\ndodge_phase: %s\ndodge_time: %.3f\ndodge_invulnerable: %s\ndodge_recovery: %.3f\ndodge_cooldown: %.3f\ncounter_phase: %s\ncounter_window: %.3f\ncounter_recovery: %.3f\ncounter_cooldown: %.3f\nlast_counter: %s\nincoming_attack: %s\nincoming_counterable: %s\ntaunt_time: %.3f\ntaunt_vulnerable: %s\ntaunt_cooldown: %.3f\ntaunt_phrase: %s\nred_brand: %.0f / %.0f\nbrand_charge_level: %d\nbrand_cost: %.0f\nbrand_charge_time: %.3f\nbrand_breaker: %s\ninteract_id: %s\ninteract_distance: %.1f\ninteract_priority: %d" % [
		_get_state_name(current_state),
		velocity.x,
		velocity.y,
		str(is_on_floor()),
		coyote_time_remaining,
		jump_buffer_remaining,
		facing_direction,
		_get_attack_display_name(current_attack),
		current_combo_index + 1,
		combo_attacks.size(),
		_get_buffered_attack_display_name(),
		combo_input_buffer_time_remaining,
		_get_attack_phase_name(attack_phase),
		attack_phase_time_remaining,
		last_hit_target_name,
		_get_dodge_phase_name(dodge_phase),
		dodge_elapsed_time,
		str(_is_health_invulnerable()),
		_get_dodge_recovery_time_remaining(),
		dodge_cooldown_time_remaining,
		_get_counter_phase_name(counter_phase),
		counter_phase_time_remaining if _is_in_counter_window() else 0.0,
		_get_counter_recovery_time_remaining(),
		counter_cooldown_time_remaining,
		last_counter_result,
		last_incoming_attack_name,
		str(last_incoming_counterable),
		taunt_elapsed_time if _is_taunting() else 0.0,
		str(_is_taunt_vulnerability_window_active()),
		taunt_cooldown_time_remaining,
		current_taunt_phrase if not current_taunt_phrase.is_empty() else "none",
		float(red_brand_component.current_energy) if red_brand_component != null else 0.0,
		float(red_brand_component.max_energy) if red_brand_component != null else 0.0,
		brand_charge_level,
		brand_breaker_release_cost,
		brand_charge_time if _is_charging_brand_breaker() else 0.0,
		_get_brand_breaker_state_name(),
		String(interaction_debug.get("id", "none")),
		float(interaction_debug.get("distance", -1.0)),
		int(interaction_debug.get("priority", 0)),
	]


func _get_attack_display_name(attack_data: Resource) -> String:
	if attack_data == null:
		return "none"

	var display_name := String(attack_data.get("display_name"))
	if not display_name.is_empty():
		return display_name

	return String(attack_data.get("attack_id"))


func _get_buffered_attack_display_name() -> String:
	if not _has_buffered_combo_input():
		return "none"

	return _get_attack_display_name(_get_combo_attack(buffered_combo_attack_index))


func _get_dodge_recovery_time_remaining() -> float:
	return dodge_phase_time_remaining if dodge_phase == DodgePhase.RECOVERY else 0.0


func _get_brand_breaker_state_name() -> String:
	if is_executing_brand_breaker:
		return "attacking"
	if _is_charging_brand_breaker():
		return "charging"
	return "none"


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


func _get_attack_phase_name(phase: int) -> String:
	match phase:
		AttackPhase.STARTUP:
			return "startup"
		AttackPhase.ACTIVE:
			return "active"
		AttackPhase.RECOVERY:
			return "recovery"
		_:
			return "none"


func _get_dodge_phase_name(phase: int) -> String:
	match phase:
		DodgePhase.STARTUP:
			return "startup"
		DodgePhase.ACTIVE:
			return "active"
		DodgePhase.RECOVERY:
			return "recovery"
		_:
			return "none"


func _on_hit_landed(target: Node, _hurtbox: Area2D, attack_data: Resource) -> void:
	last_hit_target_name = target.name
	if is_executing_brand_breaker:
		_request_brand_breaker_shake()


func _on_player_damaged(_amount: float, _source: Node) -> void:
	if current_state == PlayerState.DEAD:
		return

	if _is_in_counter_window() and not last_incoming_counterable:
		counter_resolved.emit("not_counterable")

	interrupt_attack(PlayerState.HURT)


func _on_player_died() -> void:
	interrupt_attack(PlayerState.DEAD)
	_bind_lock_manager()
	if _lock_manager != null and (_death_lock_token == null or not _death_lock_token.valid):
		_death_lock_token = _lock_manager.acquire_lock(GameplayLockManager.LockReason.DEATH, self)


func _update_dodge_visual() -> void:
	if body_visual == null:
		return

	if _is_dodging():
		body_visual.color = DODGE_BODY_COLOR
		body_visual.scale = DODGE_BODY_SCALE
	elif _is_taunting():
		_update_taunt_visual()
	elif _is_countering():
		_update_counter_visual()
	else:
		body_visual.color = PLAYER_BODY_COLOR
		body_visual.scale = Vector2.ONE


func _apply_facing_direction() -> void:
	visual.scale.x = float(facing_direction)
	direction_marker.position.x = direction_marker_offset * float(facing_direction)
	direction_marker.scale.x = float(facing_direction)
