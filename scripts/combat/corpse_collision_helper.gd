extends RefCounted
class_name CorpseCollisionHelper

## Removes physical blocking from defeated enemies so the player cannot get stuck on corpses.


static func disable_body_collision(body: CharacterBody2D) -> void:
	if body == null or not is_instance_valid(body):
		return

	body.set_deferred("collision_layer", 0)
	body.set_deferred("collision_mask", 0)

	var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", true)
