extends Area2D
class_name HealthPickup

const PLAYER_GROUP := "player"

@export var heal_amount: float = 1.0
@export var lifetime: float = 20.0
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 4.0

var _base_position: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_base_position = position
	body_entered.connect(_on_body_entered)
	if lifetime > 0.0:
		var timer := get_tree().create_timer(lifetime, true)
		timer.timeout.connect(queue_free)


func configure(heal: float, orb_lifetime: float = 20.0) -> void:
	heal_amount = maxf(heal, 0.5)
	lifetime = orb_lifetime


func _physics_process(delta: float) -> void:
	_time += delta
	position.y = _base_position.y + sin(_time * bob_speed) * bob_amplitude


func _on_body_entered(body: Node) -> void:
	if _collected or body == null or not body.is_in_group(PLAYER_GROUP):
		return

	var health: HealthComponent = null
	if body.has_method("get_health_component"):
		health = body.call("get_health_component") as HealthComponent
	if health == null or health.is_dead:
		return

	if not health.heal(heal_amount):
		return

	_collected = true
	set_deferred("monitoring", false)
	visible = false
	queue_free()
