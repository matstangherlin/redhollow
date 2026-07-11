extends CharacterBody2D

const PLAYER_GROUP := "player"
const HURTBOX_LAYER := 64
const ENEMY_HITBOX_LAYER := 16
const FLOOR_VELOCITY_RESET_THRESHOLD := 0.0
const IDLE_BODY_COLOR := Color(0.42, 0.14, 0.38, 1.0)
const TELEGRAPH_BODY_COLOR := Color(1.0, 0.78, 0.18, 1.0)
const ATTACK_BODY_COLOR := Color(0.92, 0.22, 0.18, 1.0)
const HITSTUN_BODY_COLOR := Color(1.0, 0.64, 0.28, 1.0)
const DEAD_BODY_COLOR := Color(0.18, 0.16, 0.16, 1.0)
const STYLE_TRACKABLE_GROUP := "style_trackable"

signal combat_pressure_changed(is_active: bool)

enum AttackerState {
	IDLE,
	TELEGRAPH,
	ATTACKING,
	RECOVERY,
	COOLDOWN,
	HITSTUN,
	DEAD,
}

@export var max_health: float = 12.0
@export var attack_data: Resource = preload("res://resources/combat/enemy_test_slash.tres")
@export var detection_range: float = 160.0
@export var patrol_half_width: float = 72.0
@export var telegraph_time: float = 0.60
@export var attack_cooldown: float = 1.40
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var ground_deceleration: float = 1600.0
@export var hitstun_deceleration: float = 520.0
@export var floor_snap_distance: float = 6.0

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var telegraph_visual: Polygon2D = %TelegraphVisual
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var hitbox_component: Area2D = %HitboxComponent
@onready var health_component: Node = %HealthComponent
@onready var debug_label: Label = %DebugLabel

var current_state: int = AttackerState.IDLE
var spawn_position: Vector2 = Vector2.ZERO
var facing_direction: int = -1
var state_time_remaining: float = 0.0
var cooldown_time_remaining: float = 0.0
var hitstun_remaining: float = 0.0
var last_damage: float = 0.0
var debug_visible: bool = false
var player_target: Node2D
var _combat_pressure_active: bool = false


func _ready() -> void:
	add_to_group(STYLE_TRACKABLE_GROUP)
	spawn_position = global_position
	floor_snap_length = floor_snap_distance
	_initialize_health()
	_connect_components()
	_set_debug_visible(false)
	_update_visual()


func _physics_process(delta: float) -> void:
	_handle_debug_input()
	_refresh_player_target()
	_update_cooldown(delta)
	_update_state_timers(delta)
	_update_behavior(delta)
	_apply_gravity(delta)
	_apply_horizontal_slowdown(delta)
	_clamp_to_patrol_area()
	move_and_slide()
	_update_visual()
	_update_debug_label()


func reset_enemy() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_state = AttackerState.IDLE
	state_time_remaining = 0.0
	cooldown_time_remaining = 0.0
	hitstun_remaining = 0.0
	last_damage = 0.0
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	if health_component != null:
		health_component.call("reset_health")
	_enable_hurtbox(true)
	_update_visual()
	_update_debug_label()


func _initialize_health() -> void:
	if health_component == null:
		return

	health_component.set("max_health", max_health)
	health_component.set("current_health", max_health)
	health_component.set("is_dead", false)


func _connect_components() -> void:
	if hurtbox_component != null:
		hurtbox_component.connect("hit_received", Callable(self, "_on_hit_received"))

	if health_component != null:
		health_component.connect("damaged", Callable(self, "_on_damaged"))
		health_component.connect("died", Callable(self, "_on_died"))


func _refresh_player_target() -> void:
	if player_target != null and is_instance_valid(player_target):
		return

	player_target = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D


func _update_cooldown(delta: float) -> void:
	if cooldown_time_remaining <= 0.0:
		return

	cooldown_time_remaining = maxf(cooldown_time_remaining - delta, 0.0)
	if cooldown_time_remaining <= 0.0 and current_state == AttackerState.COOLDOWN:
		current_state = AttackerState.IDLE


func _update_state_timers(delta: float) -> void:
	if current_state == AttackerState.HITSTUN:
		hitstun_remaining = maxf(hitstun_remaining - delta, 0.0)
		if hitstun_remaining <= 0.0 and not _is_dead():
			current_state = AttackerState.IDLE
		return

	if state_time_remaining <= 0.0:
		return

	state_time_remaining = maxf(state_time_remaining - delta, 0.0)
	if state_time_remaining > 0.0:
		return

	match current_state:
		AttackerState.TELEGRAPH:
			_begin_attack()
		AttackerState.ATTACKING:
			_begin_attack_recovery()
		AttackerState.RECOVERY:
			_begin_attack_cooldown()
		_:
			pass


func _update_behavior(_delta: float) -> void:
	if _is_dead() or current_state == AttackerState.HITSTUN:
		return

	if current_state != AttackerState.IDLE:
		_face_player_if_detected()
		return

	_face_player_if_detected()
	if _can_start_telegraphed_attack():
		_begin_telegraph()


func _can_start_telegraphed_attack() -> bool:
	return attack_data != null and cooldown_time_remaining <= 0.0 and _is_player_in_detection_range()


func _is_player_in_detection_range() -> bool:
	if player_target == null:
		return false

	return global_position.distance_to(player_target.global_position) <= detection_range


func _begin_telegraph() -> void:
	current_state = AttackerState.TELEGRAPH
	state_time_remaining = maxf(telegraph_time, 0.0)
	hitbox_component.call("deactivate")
	_set_combat_pressure(true)
	_face_player_if_detected()

	if state_time_remaining <= 0.0:
		_begin_attack()


func _begin_attack() -> void:
	current_state = AttackerState.ATTACKING
	state_time_remaining = maxf(float(attack_data.get("active_time")), 0.0)
	hitbox_component.call("clear_hit_targets")
	hitbox_component.call("activate", attack_data, self, facing_direction)

	if state_time_remaining <= 0.0:
		_begin_attack_recovery()


func _begin_attack_recovery() -> void:
	hitbox_component.call("deactivate")
	current_state = AttackerState.RECOVERY
	state_time_remaining = maxf(float(attack_data.get("recovery_time")), 0.0)

	if state_time_remaining <= 0.0:
		_begin_attack_cooldown()


func _begin_attack_cooldown() -> void:
	current_state = AttackerState.COOLDOWN
	cooldown_time_remaining = maxf(attack_cooldown, 0.0)
	state_time_remaining = 0.0
	_set_combat_pressure(false)


func _face_player_if_detected() -> void:
	if player_target == null:
		return

	var direction := signi(int(player_target.global_position.x - global_position.x))
	if direction != 0:
		facing_direction = direction
		visual.scale.x = float(facing_direction)


func _clamp_to_patrol_area() -> void:
	var min_x := spawn_position.x - patrol_half_width
	var max_x := spawn_position.x + patrol_half_width
	global_position.x = clampf(global_position.x, min_x, max_x)

	if global_position.x <= min_x or global_position.x >= max_x:
		velocity.x = 0.0


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y > FLOOR_VELOCITY_RESET_THRESHOLD:
		velocity.y = 0.0
		return

	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _apply_horizontal_slowdown(delta: float) -> void:
	var deceleration := hitstun_deceleration if current_state == AttackerState.HITSTUN else ground_deceleration
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _on_hit_received(attack_data_received: Resource, hitbox: Area2D, attacker: Node) -> void:
	last_damage = float(attack_data_received.get("damage"))
	if _is_dead():
		return

	if current_state == AttackerState.TELEGRAPH or current_state == AttackerState.ATTACKING or current_state == AttackerState.RECOVERY:
		hitbox_component.call("deactivate")
		_set_combat_pressure(false)
		current_state = AttackerState.HITSTUN

	hitstun_remaining = maxf(float(attack_data_received.get("hitstun_time")), 0.0)
	current_state = AttackerState.HITSTUN if hitstun_remaining > 0.0 else AttackerState.IDLE
	_apply_knockback(attack_data_received.get("knockback") as Vector2, hitbox, attacker)
	_update_visual()
	_update_debug_label()


func _on_damaged(amount: float, _source: Node) -> void:
	last_damage = amount
	_update_debug_label()


func _on_died() -> void:
	current_state = AttackerState.DEAD
	hitstun_remaining = 0.0
	state_time_remaining = 0.0
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	_enable_hurtbox(false)
	_update_visual()
	_update_debug_label()


func _apply_knockback(knockback: Vector2, hitbox: Area2D, attacker: Node) -> void:
	var direction := _get_knockback_direction(hitbox, attacker)
	velocity.x = knockback.x * float(direction)
	velocity.y = knockback.y


func _get_knockback_direction(hitbox: Area2D, attacker: Node) -> int:
	var attacker_node := attacker as Node2D
	if attacker_node != null and not is_equal_approx(attacker_node.global_position.x, global_position.x):
		return 1 if global_position.x > attacker_node.global_position.x else -1

	if hitbox != null and not is_equal_approx(hitbox.global_position.x, global_position.x):
		return 1 if global_position.x > hitbox.global_position.x else -1

	return 1


func _enable_hurtbox(is_enabled: bool) -> void:
	if hurtbox_component == null:
		return

	hurtbox_component.set_deferred("monitorable", is_enabled)
	hurtbox_component.set_deferred("monitoring", false)
	hurtbox_component.set_deferred("collision_layer", HURTBOX_LAYER if is_enabled else 0)


func _is_dead() -> bool:
	return health_component != null and bool(health_component.get("is_dead"))


func _handle_debug_input() -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		_set_debug_visible(not debug_visible)

	if Input.is_action_just_pressed("debug_reset"):
		reset_enemy()


func _set_debug_visible(is_visible: bool) -> void:
	debug_visible = is_visible
	debug_label.visible = debug_visible
	if hurtbox_component != null:
		hurtbox_component.call("set_debug_draw_enabled", debug_visible)
	if hitbox_component != null:
		hitbox_component.call("set_debug_draw_enabled", debug_visible)
	_update_debug_label()


func _update_visual() -> void:
	telegraph_visual.visible = current_state == AttackerState.TELEGRAPH

	match current_state:
		AttackerState.DEAD:
			body_visual.color = DEAD_BODY_COLOR
			visual.rotation = -0.18
		AttackerState.HITSTUN:
			body_visual.color = HITSTUN_BODY_COLOR
			visual.rotation = 0.08 * -signf(velocity.x)
		AttackerState.TELEGRAPH:
			body_visual.color = TELEGRAPH_BODY_COLOR
			visual.rotation = 0.0
		AttackerState.ATTACKING:
			body_visual.color = ATTACK_BODY_COLOR
			visual.rotation = 0.0
		_:
			body_visual.color = IDLE_BODY_COLOR
			visual.rotation = 0.0


func _update_debug_label() -> void:
	if not debug_visible:
		return

	var attack_name := "none"
	if attack_data != null:
		attack_name = String(attack_data.get("display_name"))
		if attack_name.is_empty():
			attack_name = String(attack_data.get("attack_id"))

	debug_label.text = "hp: %.1f / %.1f\nstate: %s\nattack: %s\ncounterable: %s\ntelegraph: %.3f\ncooldown: %.3f\nplayer_in_range: %s\nlast_damage: %.1f" % [
		float(health_component.get("current_health")) if health_component != null else 0.0,
		float(health_component.get("max_health")) if health_component != null else 0.0,
		_get_state_name(current_state),
		attack_name,
		str(attack_data.get("counterable")) if attack_data != null else "n/a",
		state_time_remaining if current_state == AttackerState.TELEGRAPH else 0.0,
		cooldown_time_remaining,
		str(_is_player_in_detection_range()),
		last_damage,
	]


func _get_state_name(state: int) -> String:
	match state:
		AttackerState.IDLE:
			return "idle"
		AttackerState.TELEGRAPH:
			return "telegraph"
		AttackerState.ATTACKING:
			return "attacking"
		AttackerState.RECOVERY:
			return "recovery"
		AttackerState.COOLDOWN:
			return "cooldown"
		AttackerState.HITSTUN:
			return "hitstun"
		AttackerState.DEAD:
			return "dead"
		_:
			return "unknown"


func _set_combat_pressure(is_active: bool) -> void:
	if _combat_pressure_active == is_active:
		return

	_combat_pressure_active = is_active
	combat_pressure_changed.emit(is_active)
