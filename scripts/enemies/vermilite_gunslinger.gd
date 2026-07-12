extends CharacterBody2D
class_name VermiliteGunslinger

const PLAYER_GROUP := "player"
const STYLE_TRACKABLE_GROUP := "style_trackable"
const HURTBOX_LAYER := 64
const PROJECTILE_SCENE := preload("res://scenes/combat/physical_projectile.tscn")
const HealthDropSpawner := preload("res://scripts/combat/health_drop_spawner.gd")

signal combat_pressure_changed(is_active: bool)

enum GunslingerState {
	IDLE,
	PATROL,
	ALERT,
	REPOSITION,
	AIM,
	SHOOT,
	RELOAD,
	WHIP,
	RECOVERY,
	HURT,
	KNOCKED_BACK,
	DEAD,
}

const IDLE_COLOR := Color(0.38, 0.22, 0.14, 1.0)
const AIM_COLOR := Color(0.92, 0.48, 0.16, 1.0)
const RELOAD_COLOR := Color(0.52, 0.38, 0.22, 1.0)
const HURT_COLOR := Color(1.0, 0.64, 0.28, 1.0)
const DEAD_COLOR := Color(0.18, 0.16, 0.16, 1.0)

@export var max_health: float = 12.0
@export var move_speed: float = 110.0
@export var detection_range: float = 340.0
@export var preferred_range_min: float = 180.0
@export var preferred_range_max: float = 300.0
@export var close_range: float = 68.0
@export var attack_cooldown: float = 1.5
@export var reload_duration: float = 1.15
@export var patrol_distance: float = 140.0
@export var shot_attack: Resource = preload("res://resources/combat/gunslinger_shot.tres")
@export var whip_attack: Resource = preload("res://resources/combat/gunslinger_whip.tres")
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var ground_deceleration: float = 1800.0
@export var floor_snap_distance: float = 6.0
@export var edge_check_distance: float = 28.0
@export var knockback_state_duration: float = 0.12

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var aim_visual: Polygon2D = %AimVisual
@onready var alert_visual: Polygon2D = %AlertVisual
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var hitbox_component: Area2D = %HitboxComponent
@onready var health_component: Node = %HealthComponent
@onready var floor_ahead_ray: RayCast2D = %FloorAheadRay
@onready var debug_label: Label = %DebugLabel

var current_state: int = GunslingerState.IDLE
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


func _ready() -> void:
	add_to_group(STYLE_TRACKABLE_GROUP)
	spawn_position = global_position
	floor_snap_length = floor_snap_distance
	health_component.set("max_health", max_health)
	health_component.set("current_health", max_health)
	health_component.set("is_dead", false)
	hurtbox_component.connect("hit_received", Callable(self, "_on_hit_received"))
	health_component.connect("damaged", Callable(self, "_on_damaged"))
	health_component.connect("died", Callable(self, "_on_died"))
	_update_visual()


func _physics_process(delta: float) -> void:
	_refresh_player_target()
	_update_cooldown(delta)
	_update_state_timers(delta)
	_update_behavior(delta)
	_apply_gravity(delta)
	_apply_movement_rules(delta)
	move_and_slide()
	_update_visual()


func reset_enemy() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_state = GunslingerState.IDLE
	state_time_remaining = 0.0
	cooldown_time_remaining = 0.0
	hitstun_remaining = 0.0
	attack_phase = "none"
	active_attack = null
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	health_component.call("reset_health")
	_enable_hurtbox(true)
	_update_visual()


func _update_cooldown(delta: float) -> void:
	if cooldown_time_remaining > 0.0:
		cooldown_time_remaining = maxf(cooldown_time_remaining - delta, 0.0)


func _update_state_timers(delta: float) -> void:
	if current_state == GunslingerState.HURT:
		hitstun_remaining = maxf(hitstun_remaining - delta, 0.0)
		if hitstun_remaining <= 0.0 and not _is_dead():
			_enter_state(GunslingerState.REPOSITION if _is_player_detected() else GunslingerState.IDLE)
		return

	if current_state == GunslingerState.KNOCKED_BACK:
		state_time_remaining = maxf(state_time_remaining - delta, 0.0)
		if state_time_remaining <= 0.0 and not _is_dead():
			current_state = GunslingerState.HURT if hitstun_remaining > 0.0 else GunslingerState.REPOSITION
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
		GunslingerState.ALERT:
			_enter_state(GunslingerState.REPOSITION)
		GunslingerState.AIM, GunslingerState.WHIP:
			_advance_attack_phase()
		GunslingerState.SHOOT:
			_enter_state(GunslingerState.RELOAD)
		GunslingerState.RELOAD:
			_finish_attack_cycle()
		GunslingerState.RECOVERY:
			_finish_attack_cycle()
		_:
			pass


func _update_behavior(_delta: float) -> void:
	if _is_dead() or current_state in [GunslingerState.HURT, GunslingerState.KNOCKED_BACK, GunslingerState.DEAD]:
		return

	match current_state:
		GunslingerState.IDLE:
			velocity.x = 0.0
			if _is_player_detected():
				_enter_state(GunslingerState.ALERT)
			else:
				_enter_state(GunslingerState.PATROL)
		GunslingerState.PATROL:
			_update_patrol()
		GunslingerState.ALERT:
			_face_target()
			velocity.x = 0.0
		GunslingerState.REPOSITION:
			_update_reposition()
		GunslingerState.AIM, GunslingerState.SHOOT, GunslingerState.RELOAD, GunslingerState.WHIP, GunslingerState.RECOVERY:
			velocity.x = 0.0
			_face_target()
		_:
			pass


func _update_patrol() -> void:
	if _is_player_detected():
		_enter_state(GunslingerState.ALERT)
		return
	if not _has_floor_ahead(patrol_direction):
		patrol_direction *= -1
	var min_x := spawn_position.x - patrol_distance * 0.5
	var max_x := spawn_position.x + patrol_distance * 0.5
	if global_position.x <= min_x:
		patrol_direction = 1
	elif global_position.x >= max_x:
		patrol_direction = -1
	facing_direction = patrol_direction
	_apply_facing()
	velocity.x = float(patrol_direction) * move_speed * 0.55


func _update_reposition() -> void:
	if player_target == null:
		_enter_state(GunslingerState.IDLE)
		return

	_face_target()
	var distance := _get_target_distance()

	if distance > detection_range * 1.2:
		_enter_state(GunslingerState.PATROL)
		return

	if distance <= close_range and cooldown_time_remaining <= 0.0:
		_begin_whip()
		return

	if distance >= preferred_range_min and distance <= preferred_range_max and cooldown_time_remaining <= 0.0:
		_begin_shot()
		return

	var direction := _get_direction_to_target()
	if distance < preferred_range_min:
		direction *= -1
	if direction == 0 or not _has_floor_ahead(direction):
		velocity.x = 0.0
		return

	facing_direction = direction if distance >= preferred_range_min else _get_direction_to_target()
	_apply_facing()
	velocity.x = float(direction) * move_speed


func _begin_shot() -> void:
	if shot_attack == null:
		return
	active_attack = shot_attack
	_enter_state(GunslingerState.AIM)
	attack_phase = "startup"
	state_time_remaining = maxf(float(shot_attack.get("startup_time")), 0.0)
	hitbox_component.call("deactivate")
	_set_combat_pressure(true)
	if state_time_remaining <= 0.0:
		_advance_attack_phase()


func _begin_whip() -> void:
	if whip_attack == null:
		return
	active_attack = whip_attack
	_enter_state(GunslingerState.WHIP)
	attack_phase = "startup"
	state_time_remaining = maxf(float(whip_attack.get("startup_time")), 0.0)
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
			if current_state == GunslingerState.AIM:
				_fire_projectile()
				current_state = GunslingerState.SHOOT
				state_time_remaining = 0.08
			else:
				hitbox_component.call("clear_hit_targets")
				hitbox_component.call("activate", active_attack, self, facing_direction)
			if state_time_remaining <= 0.0:
				_advance_attack_phase()
		"active":
			hitbox_component.call("deactivate")
			attack_phase = "recovery"
			current_state = GunslingerState.RECOVERY
			state_time_remaining = maxf(float(active_attack.get("recovery_time")), 0.0)
			if state_time_remaining <= 0.0:
				_finish_attack_cycle()
		_:
			_finish_attack_cycle()


func _fire_projectile() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as PhysicalProjectile
	if projectile == null:
		return
	var host := get_tree().get_first_node_in_group("world_host")
	var parent_node: Node = host if host != null else get_parent()
	if parent_node == null:
		parent_node = get_tree().current_scene
	parent_node.add_child(projectile)
	projectile.global_position = global_position + Vector2(float(facing_direction) * 24.0, -8.0)
	projectile.launch(self, facing_direction, shot_attack)


func _finish_attack_cycle() -> void:
	hitbox_component.call("deactivate")
	attack_phase = "none"
	active_attack = null
	cooldown_time_remaining = maxf(attack_cooldown, 0.0)
	_set_combat_pressure(false)
	if current_state == GunslingerState.SHOOT:
		state_time_remaining = reload_duration
		current_state = GunslingerState.RELOAD
		return
	_enter_state(GunslingerState.REPOSITION if _is_player_detected() else GunslingerState.IDLE)


func _enter_state(next_state: int) -> void:
	if _is_dead() and next_state != GunslingerState.DEAD:
		return
	current_state = next_state
	match next_state:
		GunslingerState.ALERT:
			state_time_remaining = 0.35
			velocity.x = 0.0
			_face_target()
		_:
			pass


func _on_hit_received(attack_data_received: Resource, hitbox: Area2D, attacker: Node) -> void:
	if _is_dead():
		return
	_interrupt_attack()
	hitstun_remaining = maxf(float(attack_data_received.get("hitstun_time")), 0.0)
	var knockback := attack_data_received.get("knockback") as Vector2
	if knockback != Vector2.ZERO:
		var direction := 1 if global_position.x > (attacker as Node2D).global_position.x else -1
		velocity.x = knockback.x * float(direction)
		velocity.y = knockback.y
		current_state = GunslingerState.KNOCKED_BACK
		state_time_remaining = knockback_state_duration
	else:
		current_state = GunslingerState.HURT
	_update_visual()


func _on_damaged(_amount: float, _source: Node) -> void:
	pass


func _on_died() -> void:
	current_state = GunslingerState.DEAD
	_set_combat_pressure(false)
	hitbox_component.call("deactivate")
	_enable_hurtbox(false)
	CorpseCollisionHelper.disable_body_collision(self)
	velocity = Vector2.ZERO
	_update_visual()
	HealthDropSpawner.try_spawn_from_defeat(self, HealthDropSpawner.PROFILE_ELITE)


func _interrupt_attack() -> void:
	if current_state in [GunslingerState.AIM, GunslingerState.SHOOT, GunslingerState.WHIP, GunslingerState.RECOVERY, GunslingerState.RELOAD]:
		hitbox_component.call("deactivate")
		attack_phase = "none"
		active_attack = null
		_set_combat_pressure(false)


func _apply_movement_rules(delta: float) -> void:
	if current_state in [GunslingerState.HURT, GunslingerState.AIM, GunslingerState.SHOOT, GunslingerState.WHIP, GunslingerState.RELOAD, GunslingerState.RECOVERY]:
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
	alert_visual.visible = current_state == GunslingerState.ALERT
	aim_visual.visible = current_state in [GunslingerState.AIM, GunslingerState.SHOOT]

	match current_state:
		GunslingerState.DEAD:
			body_visual.color = DEAD_COLOR
			visual.rotation = -0.15
		GunslingerState.HURT, GunslingerState.KNOCKED_BACK:
			body_visual.color = HURT_COLOR
		GunslingerState.AIM, GunslingerState.SHOOT:
			body_visual.color = AIM_COLOR
		GunslingerState.RELOAD:
			body_visual.color = RELOAD_COLOR
		_:
			body_visual.color = IDLE_COLOR
			visual.rotation = 0.0

	if debug_label.visible:
		debug_label.text = "gunslinger hp: %.1f state: %d dist: %.0f" % [
			float(health_component.get("current_health")),
			current_state,
			_get_target_distance(),
		]
