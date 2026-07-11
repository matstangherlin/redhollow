extends CharacterBody2D
class_name ChainPenitent

const PLAYER_GROUP := "player"
const STYLE_TRACKABLE_GROUP := "style_trackable"
const HURTBOX_LAYER := 64

signal combat_pressure_changed(is_active: bool)

enum PenitentState {
	IDLE,
	PATROL,
	ALERT,
	APPROACH,
	SWEEP,
	HOOK,
	RECOVERY,
	VULNERABLE,
	HURT,
	KNOCKED_BACK,
	DEAD,
}

const IDLE_COLOR := Color(0.34, 0.3, 0.38, 1.0)
const ATTACK_COLOR := Color(0.62, 0.18, 0.22, 1.0)
const VULNERABLE_COLOR := Color(0.78, 0.72, 0.28, 1.0)
const HURT_COLOR := Color(1.0, 0.64, 0.28, 1.0)
const DEAD_COLOR := Color(0.18, 0.16, 0.16, 1.0)

@export var max_health: float = 18.0
@export var move_speed: float = 82.0
@export var detection_range: float = 240.0
@export var attack_range: float = 96.0
@export var attack_cooldown: float = 1.65
@export var vulnerable_duration: float = 0.85
@export var patrol_distance: float = 120.0
@export var sweep_attack: Resource = preload("res://resources/combat/chain_penitent_sweep.tres")
@export var hook_attack: Resource = preload("res://resources/combat/chain_penitent_hook.tres")
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var ground_deceleration: float = 1600.0
@export var floor_snap_distance: float = 6.0
@export var edge_check_distance: float = 28.0
@export var knockback_state_duration: float = 0.14

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var chain_visual: Polygon2D = %ChainVisual
@onready var telegraph_visual: Polygon2D = %TelegraphVisual
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var hitbox_component: Area2D = %HitboxComponent
@onready var health_component: Node = %HealthComponent
@onready var floor_ahead_ray: RayCast2D = %FloorAheadRay

var current_state: int = PenitentState.IDLE
var spawn_position: Vector2 = Vector2.ZERO
var facing_direction: int = -1
var patrol_direction: int = 1
var state_time_remaining: float = 0.0
var cooldown_time_remaining: float = 0.0
var hitstun_remaining: float = 0.0
var attack_phase: String = "none"
var active_attack: Resource = null
var player_target: Node2D = null
var _combat_pressure_active: bool = false
var _attack_connected: bool = false


func _ready() -> void:
	add_to_group(STYLE_TRACKABLE_GROUP)
	spawn_position = global_position
	floor_snap_length = floor_snap_distance
	health_component.set("max_health", max_health)
	health_component.set("current_health", max_health)
	health_component.set("is_dead", false)
	hurtbox_component.connect("hit_received", Callable(self, "_on_hit_received"))
	health_component.connect("died", Callable(self, "_on_died"))
	hitbox_component.connect("hit_landed", Callable(self, "_on_hit_landed"))
	_update_visual()


func _physics_process(delta: float) -> void:
	_refresh_player_target()
	if cooldown_time_remaining > 0.0:
		cooldown_time_remaining = maxf(cooldown_time_remaining - delta, 0.0)
	_update_state_timers(delta)
	_update_behavior(delta)
	_apply_gravity(delta)
	_apply_movement_rules(delta)
	move_and_slide()
	_update_visual()


func reset_enemy() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_state = PenitentState.IDLE
	state_time_remaining = 0.0
	cooldown_time_remaining = 0.0
	hitstun_remaining = 0.0
	attack_phase = "none"
	active_attack = null
	_attack_connected = false
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	health_component.call("reset_health")
	_enable_hurtbox(true)
	_update_visual()


func _update_state_timers(delta: float) -> void:
	if current_state == PenitentState.HURT:
		hitstun_remaining = maxf(hitstun_remaining - delta, 0.0)
		if hitstun_remaining <= 0.0 and not _is_dead():
			_enter_state(PenitentState.APPROACH if _is_player_detected() else PenitentState.IDLE)
		return

	if current_state == PenitentState.KNOCKED_BACK:
		state_time_remaining = maxf(state_time_remaining - delta, 0.0)
		if state_time_remaining <= 0.0 and not _is_dead():
			current_state = PenitentState.HURT if hitstun_remaining > 0.0 else PenitentState.APPROACH
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
		PenitentState.ALERT:
			_enter_state(PenitentState.APPROACH)
		PenitentState.SWEEP, PenitentState.HOOK:
			_advance_attack_phase()
		PenitentState.RECOVERY:
			if _attack_connected:
				_finish_attack_cycle()
			else:
				_enter_state(PenitentState.VULNERABLE)
		PenitentState.VULNERABLE:
			_finish_attack_cycle()
		_:
			pass


func _update_behavior(_delta: float) -> void:
	if _is_dead() or current_state in [PenitentState.HURT, PenitentState.KNOCKED_BACK, PenitentState.DEAD]:
		return

	match current_state:
		PenitentState.IDLE:
			velocity.x = 0.0
			if _is_player_detected():
				_enter_state(PenitentState.ALERT)
			else:
				_enter_state(PenitentState.PATROL)
		PenitentState.PATROL:
			_update_patrol()
		PenitentState.ALERT:
			_face_target()
			velocity.x = 0.0
		PenitentState.APPROACH:
			_update_approach()
		PenitentState.SWEEP, PenitentState.HOOK, PenitentState.RECOVERY, PenitentState.VULNERABLE:
			velocity.x = 0.0
			_face_target()
		_:
			pass


func _update_patrol() -> void:
	if _is_player_detected():
		_enter_state(PenitentState.ALERT)
		return
	if not _has_floor_ahead(patrol_direction):
		patrol_direction *= -1
	facing_direction = patrol_direction
	_apply_facing()
	velocity.x = float(patrol_direction) * move_speed * 0.5


func _update_approach() -> void:
	if player_target == null:
		_enter_state(PenitentState.IDLE)
		return
	_face_target()
	var distance := _get_target_distance()
	if distance <= attack_range and cooldown_time_remaining <= 0.0:
		if distance > 64.0:
			_begin_attack(PenitentState.SWEEP, sweep_attack)
		else:
			_begin_attack(PenitentState.HOOK, hook_attack)
		return
	if distance > detection_range * 1.15:
		_enter_state(PenitentState.PATROL)
		return
	var direction := _get_direction_to_target()
	if direction == 0 or not _has_floor_ahead(direction):
		velocity.x = 0.0
		return
	facing_direction = direction
	_apply_facing()
	velocity.x = float(direction) * move_speed


func _begin_attack(state: int, data: Resource) -> void:
	active_attack = data
	_attack_connected = false
	current_state = state
	attack_phase = "startup"
	state_time_remaining = maxf(float(data.get("startup_time")), 0.0)
	hitbox_component.call("deactivate")
	_set_combat_pressure(true)
	if state_time_remaining <= 0.0:
		_advance_attack_phase()


func _advance_attack_phase() -> void:
	if active_attack == null:
		_finish_attack_cycle()
		return

	match attack_phase:
		"startup":
			attack_phase = "active"
			state_time_remaining = maxf(float(active_attack.get("active_time")), 0.0)
			hitbox_component.call("clear_hit_targets")
			hitbox_component.call("activate", active_attack, self, facing_direction)
			if state_time_remaining <= 0.0:
				_advance_attack_phase()
		"active":
			hitbox_component.call("deactivate")
			attack_phase = "recovery"
			current_state = PenitentState.RECOVERY
			state_time_remaining = maxf(float(active_attack.get("recovery_time")), 0.0)
			if state_time_remaining <= 0.0:
				_advance_attack_phase()
		_:
			_finish_attack_cycle()


func _finish_attack_cycle() -> void:
	hitbox_component.call("deactivate")
	attack_phase = "none"
	active_attack = null
	cooldown_time_remaining = maxf(attack_cooldown, 0.0)
	_set_combat_pressure(false)
	_enter_state(PenitentState.APPROACH if _is_player_detected() else PenitentState.IDLE)


func _enter_state(next_state: int) -> void:
	if _is_dead() and next_state != PenitentState.DEAD:
		return
	current_state = next_state
	match next_state:
		PenitentState.ALERT:
			state_time_remaining = 0.45
			velocity.x = 0.0
			_face_target()
		PenitentState.VULNERABLE:
			state_time_remaining = vulnerable_duration
			velocity.x = 0.0
		_:
			pass


func _on_hit_landed(_target: Node, _hurtbox: Area2D, _data: Resource) -> void:
	_attack_connected = true


func _on_hit_received(attack_data_received: Resource, hitbox: Area2D, attacker: Node) -> void:
	if _is_dead():
		return
	_interrupt_attack()
	hitstun_remaining = maxf(float(attack_data_received.get("hitstun_time")), 0.0)
	var knockback := attack_data_received.get("knockback") as Vector2
	if knockback != Vector2.ZERO and attacker is Node2D:
		var direction := 1 if global_position.x > (attacker as Node2D).global_position.x else -1
		velocity.x = knockback.x * float(direction)
		velocity.y = knockback.y
		current_state = PenitentState.KNOCKED_BACK
		state_time_remaining = knockback_state_duration
	else:
		current_state = PenitentState.HURT
	_update_visual()


func _on_died() -> void:
	current_state = PenitentState.DEAD
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	_enable_hurtbox(false)
	CorpseCollisionHelper.disable_body_collision(self)
	velocity = Vector2.ZERO
	_update_visual()


func _interrupt_attack() -> void:
	if current_state in [PenitentState.SWEEP, PenitentState.HOOK, PenitentState.RECOVERY, PenitentState.VULNERABLE]:
		hitbox_component.call("deactivate")
		attack_phase = "none"
		active_attack = null
		_set_combat_pressure(false)


func _apply_movement_rules(delta: float) -> void:
	if current_state in [PenitentState.HURT, PenitentState.SWEEP, PenitentState.HOOK, PenitentState.RECOVERY, PenitentState.VULNERABLE]:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y > 0.0:
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


func _refresh_player_target() -> void:
	if player_target == null or not is_instance_valid(player_target):
		player_target = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D


func _enable_hurtbox(is_enabled: bool) -> void:
	hurtbox_component.set_deferred("monitorable", is_enabled)
	hurtbox_component.set_deferred("collision_layer", HURTBOX_LAYER if is_enabled else 0)


func _is_dead() -> bool:
	return bool(health_component.get("is_dead"))


func _set_combat_pressure(is_active: bool) -> void:
	if _combat_pressure_active == is_active:
		return
	_combat_pressure_active = is_active
	combat_pressure_changed.emit(is_active)


func _update_visual() -> void:
	telegraph_visual.visible = current_state in [PenitentState.SWEEP, PenitentState.HOOK] and attack_phase == "startup"
	chain_visual.visible = current_state in [PenitentState.SWEEP, PenitentState.HOOK, PenitentState.RECOVERY]

	match current_state:
		PenitentState.DEAD:
			body_visual.color = DEAD_COLOR
		PenitentState.HURT, PenitentState.KNOCKED_BACK:
			body_visual.color = HURT_COLOR
		PenitentState.VULNERABLE:
			body_visual.color = VULNERABLE_COLOR
		PenitentState.SWEEP, PenitentState.HOOK, PenitentState.RECOVERY:
			body_visual.color = ATTACK_COLOR
		_:
			body_visual.color = IDLE_COLOR
