extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const GunslingerScene := preload("res://scenes/enemies/vermilite_gunslinger.tscn")
const ProjectileScene := preload("res://scenes/combat/physical_projectile.tscn")
const ShotData := preload("res://resources/combat/gunslinger_shot.tres")
const WhipData := preload("res://resources/combat/gunslinger_whip.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "vermilite_gunslinger_tests")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	_test_shot_resource(failures)
	_test_whip_counterable(failures)
	await _test_spawn_and_defeat(failures, root_node)
	await _test_projectile_launch(failures, root_node)

	root_node.queue_free()
	suite.finish(failures, 4)


func _test_shot_resource(failures: PackedStringArray) -> void:
	if not bool(ShotData.get("counterable")) == false:
		failures.append("Gunslinger shot should not be counterable at range.")
	var tags: PackedStringArray = ShotData.get("tags")
	if not tags.has("physical"):
		failures.append("Gunslinger shot must use physical tag.")


func _test_whip_counterable(failures: PackedStringArray) -> void:
	if not bool(WhipData.get("counterable")):
		failures.append("Gunslinger whip should remain counterable.")


func _test_spawn_and_defeat(failures: PackedStringArray, parent: Node2D) -> void:
	var gunslinger: Node = GunslingerScene.instantiate()
	gunslinger.global_position = Vector2(400, 848)
	parent.add_child(gunslinger)
	var health: Node = gunslinger.get_node("Components/HealthComponent")
	var hurtbox: Node = gunslinger.get_node("Components/HurtboxComponent")

	while float(health.get("current_health")) > 0.0:
		hurtbox.call("receive_hit", WhipData, null, gunslinger)

	if not bool(health.get("is_dead")):
		failures.append("Gunslinger should be defeatable.")
	gunslinger.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_projectile_launch(failures: PackedStringArray, parent: Node2D) -> void:
	var projectile := ProjectileScene.instantiate() as PhysicalProjectile
	parent.add_child(projectile)
	projectile.global_position = Vector2(200, 848)
	projectile.launch(parent, 1, ShotData)
	await TestHelpers.await_frames(get_tree(), 1)
	if not is_instance_valid(projectile):
		failures.append("Projectile should remain valid after launch.")
	projectile.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)
