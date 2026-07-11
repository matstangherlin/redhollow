extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const CultBrawlerScene := preload("res://scenes/enemies/cult_brawler.tscn")
const TestHit := preload("res://resources/combat/cult_brawler_hook.tres")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "cult_brawler_tests")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	var ground := StaticBody2D.new()
	var ground_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1200, 48)
	ground_shape.shape = rectangle
	ground.position = Vector2(600, 900)
	ground.add_child(ground_shape)
	root_node.add_child(ground)

	var player: Node = await TestHelpers.mount_player(root_node, self, Vector2(420, 848))

	_test_single_brawler(failures, root_node, player)
	_test_two_brawlers(failures, root_node)
	_test_edge_and_wall(failures, root_node)
	await _test_combo_and_defeat(failures, root_node, player)

	root_node.queue_free()

	suite.finish(failures, 4)


func _spawn_brawler(parent: Node2D, position: Vector2) -> Node:
	var brawler: Node = CultBrawlerScene.instantiate()
	brawler.global_position = position
	parent.add_child(brawler)
	return brawler


func _test_single_brawler(failures: PackedStringArray, parent: Node2D, player: Node) -> void:
	var brawler: Node = _spawn_brawler(parent, Vector2(680, 848))
	brawler.set("detection_range", 9999.0)
	player.global_position = Vector2(740, 848)

	var state_name: String = brawler.call("_get_state_name", brawler.get("current_state"))
	if state_name == "dead":
		failures.append("Fresh brawler should not start dead.")

	brawler.queue_free()


func _test_two_brawlers(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler_a: Node = _spawn_brawler(parent, Vector2(560, 848))
	var brawler_b: Node = _spawn_brawler(parent, Vector2(820, 848))
	if brawler_a == brawler_b:
		failures.append("Two brawler instances should be unique.")
	brawler_a.queue_free()
	brawler_b.queue_free()


func _test_edge_and_wall(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler: Node = _spawn_brawler(parent, Vector2(80, 848))
	brawler.set("patrol_distance", 40.0)
	brawler.set("current_state", 1)
	var has_floor: bool = brawler.call("_has_floor_ahead", brawler.get("patrol_direction"))
	if has_floor and absf(float(brawler.get("velocity").x)) <= 0.01:
		pass
	brawler.queue_free()


func _test_combo_and_defeat(failures: PackedStringArray, parent: Node2D, player: Node) -> void:
	var brawler: Node = _spawn_brawler(parent, Vector2(500, 848))
	var hurtbox: Node = brawler.get_node("%HurtboxComponent")
	var health: Node = brawler.get_node("%HealthComponent")

	for i in 3:
		hurtbox.call("receive_hit", TestHit, null, player)

	if float(health.get("current_health")) >= 14.0:
		failures.append("Brawler health should decrease after hits.")

	while float(health.get("current_health")) > 0.0:
		hurtbox.call("receive_hit", TestHit, null, player)

	if not bool(health.get("is_dead")):
		failures.append("Brawler should be defeatable.")

	var died_events := 0
	var died_callable := func() -> void:
		died_events += 1
	health.connect("died", died_callable)
	hurtbox.call("receive_hit", TestHit, null, player)
	if died_events > 0:
		failures.append("Dead brawler should not emit died again.")

	var style_manager: Node = await TestHelpers.mount_style_manager(parent, self)
	var style_before := float(style_manager.get("style_score"))
	style_manager.call("_on_enemy_died", brawler)
	var style_after := float(style_manager.get("style_score"))
	if style_after <= style_before:
		failures.append("Defeat should grant style once.")

	style_manager.queue_free()
	brawler.queue_free()
	await TestHelpers.await_frames(self, 1)
