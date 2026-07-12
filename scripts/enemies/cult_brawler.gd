extends CharacterBody2D

const PLAYER_GROUP := "player"
const STYLE_TRACKABLE_GROUP := "style_trackable"
const HURTBOX_LAYER := 64
const FLOOR_VELOCITY_RESET_THRESHOLD := 0.0
const HealthDropSpawner := preload("res://scripts/combat/health_drop_spawner.gd")

signal combat_pressure_changed(is_active: bool)

enum BrawlerState {
	IDLE,
	PATROL,
	ALERT,
	APPROACH,
	ATTACK,
	RECOVERY,
	HURT,
	KNOCKED_BACK,
	DEAD,
}

const IDLE_BODY_COLOR := Color(0.52, 0.12, 0.14, 1.0)
const PATROL_BODY_COLOR := Color(0.58, 0.16, 0.18, 1.0)
const ALERT_BODY_COLOR := Color(0.92, 0.28, 0.18, 1.0)
const APPROACH_BODY_COLOR := Color(0.68, 0.18, 0.16, 1.0)
const ATTACK_BODY_COLOR := Color(0.96, 0.22, 0.14, 1.0)
const RECOVERY_BODY_COLOR := Color(0.44, 0.14, 0.16, 1.0)
const HURT_BODY_COLOR := Color(1.0, 0.64, 0.28, 1.0)
const DEAD_BODY_COLOR := Color(0.18, 0.16, 0.16, 1.0)

@export var max_health: float = 14.0
@export var move_speed: float = 120.0
@export var detection_range: float = 220.0
@export var attack_range: float = 72.0
@export var attack_cooldown: float = 1.35
@export var patrol_distance: float = 160.0
@export var alert_duration: float = 0.35
@export var knockback_state_duration: float = 0.12
@export var attack_data: Resource = preload("res://resources/combat/cult_brawler_hook.tres")
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var ground_deceleration: float = 1800.0
@export var floor_snap_distance: float = 6.0
@export var edge_check_distance: float = 28.0

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var telegraph_visual: Polygon2D = %TelegraphVisual
@onready var alert_visual: Polygon2D = %AlertVisual
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var hitbox_component: Area2D = %HitboxComponent
@onready var health_component: Node = %HealthComponent
@onready var floor_ahead_ray: RayCast2D = %FloorAheadRay
@onready var debug_label: Label = %DebugLabel

var current_state: int = BrawlerState.IDLE
var spawn_position: Vector2 = Vector2.ZERO
var facing_direction: int = -1
var patrol_direction: int = 1
var state_time_remaining: float = 0.0
var cooldown_time_remaining: float = 0.0
var hitstun_remaining: float = 0.0
var attack_phase: String = "none"
var last_damage: float = 0.0
var debug_visible: bool = false
var player_target: Node2D = null
var _combat_pressure_active: bool = false
var _attack_startup_done: bool = false


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
	_apply_movement_rules(delta)
	move_and_slide()
	_update_visual()
	_update_debug_label()


func reset_enemy() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_state = BrawlerState.IDLE
	state_time_remaining = 0.0
	cooldown_time_remaining = 0.0
	hitstun_remaining = 0.0
	attack_phase = "none"
	last_damage = 0.0
	patrol_direction = 1
	_attack_startup_done = false
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


func _update_state_timers(delta: float) -> void:
	if current_state == BrawlerState.HURT:
		hitstun_remaining = maxf(hitstun_remaining - delta, 0.0)
		if hitstun_remaining <= 0.0 and not _is_dead():
			_enter_state(BrawlerState.IDLE)
		return

	if current_state == BrawlerState.KNOCKED_BACK:
		state_time_remaining = maxf(state_time_remaining - delta, 0.0)
		if state_time_remaining <= 0.0 and not _is_dead():
			current_state = BrawlerState.HURT if hitstun_remaining > 0.0 else BrawlerState.IDLE
			velocity.x = 0.0
		return

	if state_time_remaining <= 0.0:
		_advance_timed_state()
		return

	state_time_remaining = maxf(state_time_remaining - delta, 0.0)
	if state_time_remaining <= 0.0:
		_advance_timed_state()


func _advance_timed_state() -> void:
	match current_state:
		BrawlerState.ALERT:
			_enter_state(BrawlerState.APPROACH)
		BrawlerState.ATTACK:
			_advance_attack_phase()
		BrawlerState.RECOVERY:
			_finish_attack_cycle()
		_:
			pass


func _update_behavior(delta: float) -> void:
	if _is_dead() or current_state in [BrawlerState.HURT, BrawlerState.KNOCKED_BACK, BrawlerState.DEAD]:
		return

	match current_state:
		BrawlerState.IDLE:
			_update_idle()
		BrawlerState.PATROL:
			_update_patrol(delta)
		BrawlerState.ALERT:
			_face_target()
			velocity.x = 0.0
		BrawlerState.APPROACH:
			_update_approach(delta)
		BrawlerState.ATTACK, BrawlerState.RECOVERY:
			velocity.x = 0.0
			_face_target()
		_:
			pass


func _update_idle() -> void:
	velocity.x = 0.0
	if _is_player_detected():
		_enter_state(BrawlerState.ALERT)
		return

	_enter_state(BrawlerState.PATROL)


func _update_patrol(_delta: float) -> void:
	if _is_player_detected():
		_enter_state(BrawlerState.ALERT)
		return

	if not _has_floor_ahead(patrol_direction):
		patrol_direction *= -1
		facing_direction = patrol_direction
		_apply_facing()

	var min_x := spawn_position.x - patrol_distance * 0.5
	var max_x := spawn_position.x + patrol_distance * 0.5
	if global_position.x <= min_x:
		patrol_direction = 1
	elif global_position.x >= max_x:
		patrol_direction = -1

	facing_direction = patrol_direction
	_apply_facing()
	velocity.x = float(patrol_direction) * move_speed * 0.65


func _update_approach(_delta: float) -> void:
	if player_target == null:
		_enter_state(BrawlerState.IDLE)
		return

	_face_target()

	if _get_target_distance() <= attack_range and cooldown_time_remaining <= 0.0:
		_begin_attack()
		return

	if _get_target_distance() > detection_range * 1.15:
		_enter_state(BrawlerState.PATROL)
		return

	var direction := _get_direction_to_target()
	if direction == 0:
		velocity.x = 0.0
		return

	if not _has_floor_ahead(direction):
		velocity.x = 0.0
		return

	facing_direction = direction
	_apply_facing()
	velocity.x = float(direction) * move_speed


func _begin_attack() -> void:
	if attack_data == null:
		return

	_enter_state(BrawlerState.ATTACK)
	attack_phase = "startup"
	state_time_remaining = maxf(float(attack_data.get("startup_time")), 0.0)
	_attack_startup_done = false
	hitbox_component.call("deactivate")
	_set_combat_pressure(true)
	_face_target()

	if state_time_remaining <= 0.0:
		_advance_attack_phase()


func _advance_attack_phase() -> void:
	if attack_data == null:
		_finish_attack_cycle()
		return

	match attack_phase:
		"startup":
			attack_phase = "active"
			state_time_remaining = maxf(float(attack_data.get("active_time")), 0.0)
			hitbox_component.call("clear_hit_targets")
			hitbox_component.call("activate", attack_data, self, facing_direction)
			if state_time_remaining <= 0.0:
				_advance_attack_phase()
		"active":
			hitbox_component.call("deactivate")
			attack_phase = "recovery"
			current_state = BrawlerState.RECOVERY
			state_time_remaining = maxf(float(attack_data.get("recovery_time")), 0.0)
			if state_time_remaining <= 0.0:
				_finish_attack_cycle()
		_:
			_finish_attack_cycle()


func _finish_attack_cycle() -> void:
	hitbox_component.call("deactivate")
	attack_phase = "none"
	cooldown_time_remaining = maxf(attack_cooldown, 0.0)
	_set_combat_pressure(false)
	_enter_state(BrawlerState.PATROL if _is_player_detected() else BrawlerState.IDLE)


func _enter_state(next_state: int) -> void:
	if _is_dead() and next_state != BrawlerState.DEAD:
		return

	current_state = next_state
	match next_state:
		BrawlerState.ALERT:
			state_time_remaining = maxf(alert_duration, 0.0)
			velocity.x = 0.0
			_face_target()
		BrawlerState.APPROACH:
			state_time_remaining = 0.0
		BrawlerState.IDLE, BrawlerState.PATROL:
			state_time_remaining = 0.0
			if next_state == BrawlerState.IDLE:
				velocity.x = 0.0
		_:
			pass


func _on_hit_received(attack_data_received: Resource, hitbox: Area2D, attacker: Node) -> void:
	last_damage = float(attack_data_received.get("damage"))
	if _is_dead():
		return

	_interrupt_attack()
	hitstun_remaining = maxf(float(attack_data_received.get("hitstun_time")), 0.0)
	_apply_knockback(attack_data_received.get("knockback") as Vector2, hitbox, attacker)

	var knockback_vector := attack_data_received.get("knockback") as Vector2
	if knockback_vector != Vector2.ZERO:
		current_state = BrawlerState.KNOCKED_BACK
		state_time_remaining = maxf(knockback_state_duration, 0.0)
	else:
		current_state = BrawlerState.HURT if hitstun_remaining > 0.0 else BrawlerState.IDLE
		velocity.x = 0.0

	_update_visual()
	_update_debug_label()


func _on_damaged(amount: float, _source: Node) -> void:
	last_damage = amount
	_update_debug_label()


func _on_died() -> void:
	_enter_state(BrawlerState.DEAD)
	hitstun_remaining = 0.0
	state_time_remaining = 0.0
	attack_phase = "none"
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	_enable_hurtbox(false)
	CorpseCollisionHelper.disable_body_collision(self)
	velocity = Vector2.ZERO
	_update_visual()
	HealthDropSpawner.try_spawn_from_defeat(self, HealthDropSpawner.PROFILE_STANDARD)
	_update_debug_label()


func _interrupt_attack() -> void:
	if current_state in [BrawlerState.ATTACK, BrawlerState.RECOVERY]:
		hitbox_component.call("deactivate")
		attack_phase = "none"
		_set_combat_pressure(false)


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


func _apply_movement_rules(delta: float) -> void:
	if current_state == BrawlerState.HURT:
		velocity.x = 0.0
		return

	if current_state in [BrawlerState.IDLE, BrawlerState.ALERT, BrawlerState.ATTACK, BrawlerState.RECOVERY, BrawlerState.DEAD]:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y > FLOOR_VELOCITY_RESET_THRESHOLD:
		velocity.y = 0.0
		return

	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _has_floor_ahead(direction: int) -> bool:
	if floor_ahead_ray == null:
		return true

	floor_ahead_ray.target_position = Vector2(float(direction) * edge_check_distance, 48.0)
	floor_ahead_ray.force_raycast_update()
	return floor_ahead_ray.is_colliding()


func _is_player_detected() -> bool:
	return _get_target_distance() <= detection_range


func _get_target_distance() -> float:
	if player_target == null:
		return INF
	return global_position.distance_to(player_target.global_position)


func _get_direction_to_target() -> int:
	if player_target == null:
		return 0
	return signi(int(player_target.global_position.x - global_position.x))


func _face_target() -> void:
	var direction := _get_direction_to_target()
	if direction != 0:
		facing_direction = direction
		_apply_facing()


func _apply_facing() -> void:
	visual.scale.x = float(facing_direction)


func _enable_hurtbox(is_enabled: bool) -> void:
	if hurtbox_component == null:
		return

	hurtbox_component.set_deferred("monitorable", is_enabled)
	hurtbox_component.set_deferred("monitoring", false)
	hurtbox_component.set_deferred("collision_layer", HURTBOX_LAYER if is_enabled else 0)


func _is_dead() -> bool:
	return health_component != null and bool(health_component.get("is_dead"))


func _set_combat_pressure(is_active: bool) -> void:
	if _combat_pressure_active == is_active:
		return

	_combat_pressure_active = is_active
	combat_pressure_changed.emit(is_active)


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
	telegraph_visual.visible = current_state == BrawlerState.ATTACK and attack_phase == "startup"
	alert_visual.visible = current_state == BrawlerState.ALERT

	match current_state:
		BrawlerState.DEAD:
			body_visual.color = DEAD_BODY_COLOR
			visual.rotation = -0.18
		BrawlerState.HURT, BrawlerState.KNOCKED_BACK:
			body_visual.color = HURT_BODY_COLOR
			visual.rotation = 0.08 * -signf(velocity.x)
		BrawlerState.ALERT:
			body_visual.color = ALERT_BODY_COLOR
			visual.rotation = 0.0
		BrawlerState.APPROACH:
			body_visual.color = APPROACH_BODY_COLOR
			visual.rotation = 0.0
		BrawlerState.ATTACK:
			body_visual.color = ATTACK_BODY_COLOR
			visual.rotation = 0.0
		BrawlerState.RECOVERY:
			body_visual.color = RECOVERY_BODY_COLOR
			visual.rotation = 0.0
		BrawlerState.PATROL:
			body_visual.color = PATROL_BODY_COLOR
			visual.rotation = 0.0
		_:
			body_visual.color = IDLE_BODY_COLOR
			visual.rotation = 0.0


func _update_debug_label() -> void:
	if not debug_visible:
		return

	var target_name := "none"
	if player_target != null:
		target_name = player_target.name

	debug_label.text = "hp: %.1f / %.1f\nstate: %s\nphase: %s\ntarget: %s\ndistance: %.1f\ncooldown: %.2f\nrange: %.0f / %.0f\nlast_damage: %.1f" % [
		float(health_component.get("current_health")) if health_component != null else 0.0,
		float(health_component.get("max_health")) if health_component != null else 0.0,
		_get_state_name(current_state),
		attack_phase,
		target_name,
		_get_target_distance(),
		cooldown_time_remaining,
		attack_range,
		detection_range,
		last_damage,
	]


func _get_state_name(state: int) -> String:
	match state:
		BrawlerState.IDLE:
			return "idle"
		BrawlerState.PATROL:
			return "patrol"
		BrawlerState.ALERT:
			return "alert"
		BrawlerState.APPROACH:
			return "approach"
		BrawlerState.ATTACK:
			return "attack"
		BrawlerState.RECOVERY:
			return "recovery"
		BrawlerState.HURT:
			return "hurt"
		BrawlerState.KNOCKED_BACK:
			return "knocked_back"
		BrawlerState.DEAD:
			return "dead"
		_:
			return "unknown"
