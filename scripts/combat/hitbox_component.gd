extends Area2D
class_name HitboxComponent

signal hit_landed(target: Node, hurtbox: Area2D, attack_data: Resource)
signal attack_activated(attack_data: Resource, owner: Node, facing_direction: int)

const HITSTOP_GROUP := "hitstop_controller"

@export var owner_node_path: NodePath
@export var debug_draw_enabled: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var owning_node: Node
var attack_data: Resource
var facing_direction: int = 1
var is_active: bool = false
var hit_counts: Dictionary = {}


func _ready() -> void:
	owning_node = get_node_or_null(owner_node_path)
	area_entered.connect(_on_area_entered)
	deactivate()


func activate(new_attack_data: Resource, new_owner: Node, new_facing_direction: int) -> void:
	if new_attack_data == null:
		return

	attack_data = new_attack_data
	owning_node = new_owner
	facing_direction = 1 if new_facing_direction >= 0 else -1
	hit_counts.clear()
	_apply_attack_shape()
	is_active = true
	monitoring = true
	if collision_shape != null:
		collision_shape.disabled = false
	queue_redraw()
	attack_activated.emit(attack_data, owning_node, facing_direction)


func deactivate() -> void:
	# Often called from hit callbacks while the physics server is flushing
	# queries, when monitoring/shape changes are blocked. is_active gates
	# _on_area_entered immediately; the physics state is applied deferred.
	is_active = false
	call_deferred("_apply_deactivation")
	queue_redraw()


func _apply_deactivation() -> void:
	if is_active:
		return
	monitoring = false
	if collision_shape != null:
		collision_shape.disabled = true


func clear_hit_targets() -> void:
	hit_counts.clear()


func set_debug_draw_enabled(is_enabled: bool) -> void:
	debug_draw_enabled = is_enabled
	queue_redraw()


func _apply_attack_shape() -> void:
	if collision_shape == null or attack_data == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		rectangle_shape.size = attack_data.get("hitbox_size") as Vector2

	var hitbox_offset := attack_data.get("hitbox_offset") as Vector2
	position = Vector2(hitbox_offset.x * float(facing_direction), hitbox_offset.y)


func _on_area_entered(area: Area2D) -> void:
	if not is_active or attack_data == null or not area.has_method("receive_hit"):
		return

	var target: Node = area.call("get_owner_node")
	if target == null or target == owning_node:
		return

	if not _can_hit_target(target):
		return

	if not _register_target_hit(target):
		return

	if bool(area.call("receive_hit", attack_data, self, owning_node)):
		_request_hitstop()
		hit_landed.emit(target, area, attack_data)


func _can_hit_target(target: Node) -> bool:
	var can_hit_ground := bool(attack_data.get("can_hit_ground_targets"))
	var can_hit_air := bool(attack_data.get("can_hit_air_targets"))
	var body := target as CharacterBody2D
	if body == null:
		return can_hit_ground

	if body.is_on_floor():
		return can_hit_ground

	return can_hit_air


func _register_target_hit(target: Node) -> bool:
	var target_id := target.get_instance_id()
	var current_hits := int(hit_counts.get(target_id, 0))
	var allowed_hits := maxi(int(attack_data.get("max_hits_per_target")), 1)

	if current_hits >= allowed_hits:
		return false

	hit_counts[target_id] = current_hits + 1
	return true


func _request_hitstop() -> void:
	var attacker_hitstop := float(attack_data.get("attacker_hitstop"))
	var target_hitstop := float(attack_data.get("target_hitstop"))
	var duration := maxf(attacker_hitstop, target_hitstop)
	if duration <= 0.0:
		return

	for node in get_tree().get_nodes_in_group(HITSTOP_GROUP):
		if node.has_method("request_hitstop"):
			node.call("request_hitstop", duration)
			return


func _draw() -> void:
	if not debug_draw_enabled or not is_active or collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return

	var rect := Rect2(-rectangle_shape.size * 0.5, rectangle_shape.size)
	draw_rect(rect, Color(1.0, 0.1, 0.05, 0.25), true)
	draw_rect(rect, Color(1.0, 0.1, 0.05, 0.95), false, 2.0)
