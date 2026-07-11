extends CharacterBody2D

const FLOOR_VELOCITY_RESET_THRESHOLD := 0.0
const HURTBOX_LAYER := 64
const STYLE_TRACKABLE_GROUP := "style_trackable"

# All timing values are seconds. Movement values are pixels per second or pixels per second squared.
enum DummyState {
	IDLE,
	HITSTUN,
	DEAD,
}

@export var max_health: float = 9.0
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var ground_deceleration: float = 1600.0
@export var hitstun_deceleration: float = 520.0
@export var floor_snap_distance: float = 6.0

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var health_component: Node = %HealthComponent
@onready var debug_label: Label = %DebugLabel

var current_state: int = DummyState.IDLE
var spawn_position: Vector2 = Vector2.ZERO
var hitstun_remaining: float = 0.0
var last_damage: float = 0.0
var debug_visible: bool = false


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
	_update_state_timers(delta)
	_apply_gravity(delta)
	_apply_horizontal_slowdown(delta)
	move_and_slide()
	_update_visual()
	_update_debug_label()


func reset_dummy() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_state = DummyState.IDLE
	hitstun_remaining = 0.0
	last_damage = 0.0
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


func _handle_debug_input() -> void:
	if Input.is_action_just_pressed("debug_toggle"):
		_set_debug_visible(not debug_visible)

	if Input.is_action_just_pressed("debug_reset"):
		reset_dummy()


func _update_state_timers(delta: float) -> void:
	if current_state != DummyState.HITSTUN:
		return

	hitstun_remaining = maxf(hitstun_remaining - delta, 0.0)
	if hitstun_remaining <= 0.0 and not _is_dead():
		current_state = DummyState.IDLE


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y > FLOOR_VELOCITY_RESET_THRESHOLD:
		velocity.y = 0.0
		return

	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _apply_horizontal_slowdown(delta: float) -> void:
	var deceleration := hitstun_deceleration if current_state == DummyState.HITSTUN else ground_deceleration
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)


func _on_hit_received(attack_data: Resource, hitbox: Area2D, attacker: Node) -> void:
	last_damage = float(attack_data.get("damage"))
	if _is_dead():
		return

	hitstun_remaining = maxf(float(attack_data.get("hitstun_time")), 0.0)
	current_state = DummyState.HITSTUN if hitstun_remaining > 0.0 else DummyState.IDLE
	_apply_knockback(attack_data.get("knockback") as Vector2, hitbox, attacker)
	_update_visual()
	_update_debug_label()


func _on_damaged(amount: float, _source: Node) -> void:
	last_damage = amount
	_update_debug_label()


func _on_died() -> void:
	current_state = DummyState.DEAD
	hitstun_remaining = 0.0
	_enable_hurtbox(false)
	CorpseCollisionHelper.disable_body_collision(self)
	velocity = Vector2.ZERO
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


func _set_debug_visible(is_visible: bool) -> void:
	debug_visible = is_visible
	debug_label.visible = debug_visible
	if hurtbox_component != null:
		hurtbox_component.call("set_debug_draw_enabled", debug_visible)
	_update_debug_label()


func _update_visual() -> void:
	match current_state:
		DummyState.DEAD:
			body_visual.color = Color(0.18, 0.16, 0.16, 1.0)
			visual.rotation = -0.18
		DummyState.HITSTUN:
			body_visual.color = Color(1.0, 0.64, 0.28, 1.0)
			visual.rotation = 0.08 * -signf(velocity.x)
		_:
			body_visual.color = Color(0.56, 0.18, 0.13, 1.0)
			visual.rotation = 0.0


func _update_debug_label() -> void:
	if not debug_visible:
		return

	debug_label.text = "hp: %.1f / %.1f\nstate: %s\nhitstun: %.3f\nvelocity: %.1f, %.1f\nlast_damage: %.1f" % [
		float(health_component.get("current_health")) if health_component != null else 0.0,
		float(health_component.get("max_health")) if health_component != null else 0.0,
		_get_state_name(current_state),
		hitstun_remaining,
		velocity.x,
		velocity.y,
		last_damage,
	]


func _get_state_name(state: int) -> String:
	match state:
		DummyState.IDLE:
			return "idle"
		DummyState.HITSTUN:
			return "hitstun"
		DummyState.DEAD:
			return "dead"
		_:
			return "unknown"