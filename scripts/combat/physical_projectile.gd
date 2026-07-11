extends Area2D
class_name PhysicalProjectile

## Vermilite-tipped physical slug. Not magic — moves in 2D plane, dodgeable.

signal projectile_expired
signal projectile_hit(target: Node, hurtbox: Area2D)

const PROJECTILE_GROUP := "physical_projectile"

@export var speed: float = 520.0
@export var lifetime: float = 2.4
@export var attack_data: Resource

@onready var _hitbox: HitboxComponent = %HitboxComponent
@onready var _visual: Polygon2D = %Visual

var direction: int = 1
var owner_node: Node = null
var _time_alive: float = 0.0
var _launched: bool = false


func _ready() -> void:
	add_to_group(PROJECTILE_GROUP)
	monitoring = false
	if _hitbox != null:
		_hitbox.hit_landed.connect(_on_hit_landed)


func launch(from_owner: Node, travel_direction: int, data: Resource) -> void:
	owner_node = from_owner
	direction = 1 if travel_direction >= 0 else -1
	attack_data = data
	_launched = true
	_time_alive = 0.0

	if _visual != null:
		_visual.scale.x = float(direction)

	if _hitbox != null and attack_data != null:
		_hitbox.clear_hit_targets()
		_hitbox.activate(attack_data, owner_node if owner_node != null else self, direction)


func _physics_process(delta: float) -> void:
	if not _launched:
		return

	global_position.x += float(direction) * speed * delta
	_time_alive += delta

	if _time_alive >= lifetime:
		_expire()


func _on_hit_landed(_target: Node, _hurtbox: Area2D, _data: Resource) -> void:
	projectile_hit.emit(_target, _hurtbox)
	_expire()


func _expire() -> void:
	if not _launched:
		return
	_launched = false
	if _hitbox != null:
		_hitbox.deactivate()
	projectile_expired.emit()
	queue_free()
