extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const CultBrawlerScene := preload("res://scenes/enemies/cult_brawler.tscn")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")
const BodyHook := preload("res://resources/combat/body_hook.tres")
const RedKnuckle := preload("res://resources/combat/red_knuckle.tres")
const RedBrandBreaker := preload("res://resources/combat/red_brand_breaker_lv1.tres")
const CultBrawlerHook := preload("res://resources/combat/cult_brawler_hook.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "cult_brawler_visual_tests")
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

	_test_visual_controller_present(failures, root_node)
	_test_sprite_mode_active(failures, root_node)
	_test_attack_phase_animations(failures, root_node)
	await _test_hit_reactions(failures, root_node)
	await _test_death_visual(failures, root_node)
	_test_contract_summary(failures)

	root_node.queue_free()
	suite.finish(failures, 6)


func _spawn_brawler(parent: Node2D, position: Vector2) -> Node:
	var brawler: Node = CultBrawlerScene.instantiate()
	brawler.global_position = position
	parent.add_child(brawler)
	await TestHelpers.await_frames(get_tree(), 2)
	return brawler


func _test_visual_controller_present(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler: Node = CultBrawlerScene.instantiate()
	parent.add_child(brawler)
	var controller: Node = brawler.get_node_or_null("%CultBrawlerVisualController")
	if controller == null:
		failures.append("Cult Brawler scene must include CultBrawlerVisualController.")
	var sprite: Node = brawler.get_node_or_null("%SpriteVisual")
	if sprite == null:
		failures.append("Cult Brawler scene must include SpriteVisual.")
	brawler.queue_free()


func _test_sprite_mode_active(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler: Node = CultBrawlerScene.instantiate()
	parent.add_child(brawler)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: CultBrawlerVisualController = brawler.get_node("%CultBrawlerVisualController")
	if not controller.is_sprite_active():
		failures.append("Pilot profile should activate sprite visual mode.")
	brawler.queue_free()


func _test_attack_phase_animations(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler: Node = CultBrawlerScene.instantiate()
	parent.add_child(brawler)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: CultBrawlerVisualController = brawler.get_node("%CultBrawlerVisualController")

	brawler.set("current_state", 4)
	brawler.set("attack_phase", "startup")
	controller.refresh(brawler, 0.016)
	if controller.get_current_animation() != &"attack_startup":
		failures.append("Startup phase should map to attack_startup animation.")

	brawler.set("attack_phase", "active")
	controller.refresh(brawler, 0.016)
	if controller.get_current_animation() != &"attack_active":
		failures.append("Active phase should map to attack_active animation.")

	brawler.queue_free()


func _test_hit_reactions(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler: Node = await _spawn_brawler(parent, Vector2(500, 848))
	var controller: CultBrawlerVisualController = brawler.get_node("%CultBrawlerVisualController")
	var hurtbox: Node = brawler.get_node("%HurtboxComponent")

	controller.apply_hit_reaction(CalderStraight)
	if controller.get_current_animation() != &"hurt":
		failures.append("Calder Straight should trigger hurt reaction clip.")

	controller.apply_hit_reaction(BodyHook)
	if controller.get_current_animation() != &"heavy_hurt":
		failures.append("Body Hook should trigger heavy_hurt reaction clip.")

	controller.apply_hit_reaction(RedKnuckle)
	if controller.get_current_animation() != &"knocked_back":
		failures.append("Red Knuckle should trigger knocked_back reaction clip.")

	controller.apply_hit_reaction(RedBrandBreaker)
	if controller.get_current_animation() != &"stagger":
		failures.append("Red Brand Breaker should trigger stagger reaction clip.")

	brawler.queue_free()


func _test_death_visual(failures: PackedStringArray, parent: Node2D) -> void:
	var brawler: Node = await _spawn_brawler(parent, Vector2(560, 848))
	var controller: CultBrawlerVisualController = brawler.get_node("%CultBrawlerVisualController")
	var hurtbox: Node = brawler.get_node("%HurtboxComponent")
	var health: Node = brawler.get_node("%HealthComponent")
	var hitbox: Node = brawler.get_node("%HitboxComponent")

	controller.play_death()
	if controller.get_current_animation() != &"death":
		failures.append("Death should play death animation.")

	while float(health.get("current_health")) > 0.0:
		hurtbox.call("receive_hit", CultBrawlerHook, null, null)

	if not bool(health.get("is_dead")):
		failures.append("Brawler should be dead after lethal hits.")

	brawler.queue_free()


func _test_contract_summary(failures: PackedStringArray) -> void:
	var summary: Dictionary = CultBrawlerAnimationContract.get_visual_contract_summary()
	if summary.get("approved_frame_size") != Vector2i(34, 56):
		failures.append("Contract summary frame size mismatch.")
	if int(summary.get("attack_visual_reach_px", 0)) != 46:
		failures.append("Contract attack visual reach should be 46 px.")
