extends Area2D
class_name BarrierHurtboxComponent

signal hit_received(attack_data: Resource, hitbox: Area2D, attacker: Node)

@export var owner_node_path: NodePath
@export var debug_draw_enabled: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var owning_node: Node


func _ready() -> void:
	owning_node = get_node_or_null(owner_node_path)
	queue_redraw()


func get_owner_node() -> Node:
	return owning_node if owning_node != null else owner


func receive_hit(attack_data: Resource, hitbox: Area2D, attacker: Node) -> bool:
	if attack_data == null:
		return false

	var target_owner := get_owner_node()
	if target_owner != null and target_owner.has_method("handle_barrier_hit"):
		return bool(target_owner.call("handle_barrier_hit", attack_data, hitbox, attacker))

	return false


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
	draw_rect(rect, Color(0.92, 0.18, 0.08, 0.22), true)
	draw_rect(rect, Color(0.92, 0.18, 0.08, 0.9), false, 2.0)
