extends RefCounted
class_name HealthDropSpawner

const PICKUP_SCENE := preload("res://scenes/combat/health_pickup.tscn")

const PROFILE_STANDARD := {
	"chance": 0.28,
	"heal_min": 1.0,
	"heal_max": 2.0,
	"count_max": 1,
	"extra_orb_chance": 0.0,
	"spread": 14.0,
}

const PROFILE_ELITE := {
	"chance": 0.38,
	"heal_min": 1.0,
	"heal_max": 3.0,
	"count_max": 2,
	"extra_orb_chance": 0.45,
	"spread": 18.0,
}

const PROFILE_BOSS := {
	"chance": 0.55,
	"heal_min": 2.0,
	"heal_max": 4.0,
	"count_max": 3,
	"extra_orb_chance": 0.5,
	"spread": 22.0,
}


static func try_spawn_from_defeat(defeated: Node2D, profile: Dictionary = PROFILE_STANDARD) -> void:
	if defeated == null or not is_instance_valid(defeated):
		return

	var chance := float(profile.get("chance", 0.25))
	if randf() > chance:
		return

	var parent := _resolve_spawn_parent(defeated)
	if parent == null:
		return

	var count_max := maxi(int(profile.get("count_max", 1)), 1)
	var orb_count := 1
	if count_max > 1 and randf() <= float(profile.get("extra_orb_chance", 0.35)):
		orb_count = randi_range(2, count_max)

	var heal_min := float(profile.get("heal_min", 1.0))
	var heal_max := maxf(float(profile.get("heal_max", heal_min)), heal_min)
	var spread := float(profile.get("spread", 16.0))
	var origin := defeated.global_position + Vector2(0.0, -24.0)

	for index in range(orb_count):
		var heal_amount := randf_range(heal_min, heal_max)
		var offset := Vector2(randf_range(-spread, spread), randf_range(-6.0, -spread * 0.35))
		_spawn_orb(parent, origin + offset, heal_amount)


static func _resolve_spawn_parent(defeated: Node2D) -> Node:
	var tree := defeated.get_tree()
	if tree == null:
		return null

	var world_host := tree.get_first_node_in_group("world_host")
	if world_host != null:
		return world_host

	var game_root := tree.get_first_node_in_group("game_root")
	if game_root != null:
		var host := game_root.get_node_or_null("WorldHost")
		if host != null:
			return host

	if tree.current_scene != null:
		return tree.current_scene

	return null


static func _spawn_orb(parent: Node, global_position: Vector2, heal_amount: float) -> void:
	var pickup := PICKUP_SCENE.instantiate()
	if pickup == null:
		return

	parent.add_child(pickup)
	pickup.global_position = global_position
	if pickup.has_method("configure"):
		pickup.call("configure", heal_amount)
