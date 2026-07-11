extends Area2D
class_name HurtboxComponent

signal hit_received(attack_data: Resource, hitbox: Area2D, attacker: Node)
signal hit_countered(attack_data: Resource, hitbox: Area2D, attacker: Node)

@export var owner_node_path: NodePath
@export var health_component_path: NodePath
@export var debug_draw_enabled: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var owning_node: Node
var health_component: Node


func _ready() -> void:
	owning_node = get_node_or_null(owner_node_path)
	health_component = get_node_or_null(health_component_path)
	queue_redraw()


func get_owner_node() -> Node:
	return owning_node if owning_node != null else owner


func receive_hit(attack_data: Resource, hitbox: Area2D, attacker: Node) -> bool:
	if attack_data == null:
		return false

	var target_owner := get_owner_node()
	if target_owner != null and target_owner.has_method("should_block_damage"):
		if bool(target_owner.call("should_block_damage", attack_data)):
			return false

	if target_owner != null and target_owner.has_method("try_counter_hit"):
		if bool(target_owner.call("try_counter_hit", attack_data, hitbox, attacker)):
			hit_countered.emit(attack_data, hitbox, attacker)
			return true

	if health_component != null and health_component.has_method("apply_damage"):
		if not bool(health_component.call("apply_damage", float(attack_data.get("damage")), attacker)):
			return false

	hit_received.emit(attack_data, hitbox, attacker)
	return true


func set_debug_draw_enabled(is_enabled: bool) -> void:
	debug_draw_enabled = is_enabled
	queue_redraw()


func _draw() -> void:
	if not debug_draw_enabled or collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return

	var rect := Rect2(-rectangle_shape.size * 0.5, rectangle_shape.size)
	draw_rect(rect, Color(0.15, 0.55, 1.0, 0.20), true)
	draw_rect(rect, Color(0.15, 0.55, 1.0, 0.85), false, 2.0)