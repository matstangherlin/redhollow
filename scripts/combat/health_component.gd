extends Node
class_name HealthComponent

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, source: Node)
signal died()

@export var max_health: float = 10.0
@export var current_health: float = 10.0
@export var invulnerable: bool = false

var is_dead: bool = false


func _ready() -> void:
	current_health = clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)


func apply_damage(amount: float, source: Node = null) -> bool:
	if invulnerable or is_dead or amount <= 0.0:
		return false

	current_health = clampf(current_health - amount, 0.0, max_health)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		is_dead = true
		died.emit()

	return true


func reset_health() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)


func set_health_values(current: float, max_value: float) -> void:
	max_health = maxf(max_value, 0.0)
	current_health = clampf(current, 0.0, max_health)
	is_dead = current_health <= 0.0
	health_changed.emit(current_health, max_health)