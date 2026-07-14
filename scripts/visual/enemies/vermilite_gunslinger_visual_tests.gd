extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const GunslingerScene := preload("res://scenes/enemies/vermilite_gunslinger.tscn")
const ShotData := preload("res://resources/combat/gunslinger_shot.tres")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "vermilite_gunslinger_visual_tests")
	suite.allow_warning_contains("GunslingerVisual")
	suite.allow_warning_contains("procedural")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	_test_visual_nodes(failures, root_node)
	await _test_sprite_mode_and_clips(failures, root_node)
	await _test_telegraph_and_death(failures, root_node)
	_test_contract(failures)

	root_node.queue_free()
	suite.finish(failures, 4)


func _test_visual_nodes(failures: PackedStringArray, parent: Node2D) -> void:
	var enemy: Node = GunslingerScene.instantiate()
	parent.add_child(enemy)
	if enemy.get_node_or_null("%VermiliteGunslingerVisualController") == null:
		failures.append("Gunslinger must include VermiliteGunslingerVisualController.")
	if enemy.get_node_or_null("%SpriteVisual") == null:
		failures.append("Gunslinger must include SpriteVisual.")
	if enemy.get_node_or_null("%AimVisual") == null:
		failures.append("Gunslinger must include AimVisual telegraph.")
	if enemy.get_node_or_null("%MuzzleGlow") == null:
		failures.append("Gunslinger must include MuzzleGlow telegraph.")
	enemy.queue_free()


func _test_sprite_mode_and_clips(failures: PackedStringArray, parent: Node2D) -> void:
	var enemy: Node = GunslingerScene.instantiate()
	parent.add_child(enemy)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: VermiliteGunslingerVisualController = enemy.get_node("%VermiliteGunslingerVisualController")
	if not controller.is_sprite_active():
		failures.append("Pilot profile should activate Gunslinger sprite mode.")

	enemy.set("current_state", 4) # AIM
	enemy.set("attack_phase", "startup")
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"aim":
		failures.append("AIM startup should map to aim.")

	enemy.set("current_state", 5) # SHOOT
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"fire":
		failures.append("SHOOT should map to fire.")

	enemy.set("current_state", 6) # RELOAD
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"reload":
		failures.append("RELOAD should map to reload.")

	enemy.set("current_state", 3) # REPOSITION
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"reposition":
		failures.append("REPOSITION should map to reposition.")

	enemy.queue_free()


func _test_telegraph_and_death(failures: PackedStringArray, parent: Node2D) -> void:
	var enemy: Node = GunslingerScene.instantiate()
	enemy.global_position = Vector2(500, 848)
	parent.add_child(enemy)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: VermiliteGunslingerVisualController = enemy.get_node("%VermiliteGunslingerVisualController")

	controller.notify_attack_telegraph(ShotData)
	if controller.get_current_animation() != &"aim":
		failures.append("Telegraph should play aim pose.")

	controller.apply_hit_reaction(CalderStraight)
	if controller.get_current_animation() != &"hurt":
		failures.append("Hit reaction should play hurt.")

	controller.play_death()
	if controller.get_current_animation() != &"death":
		failures.append("Death should play death clip.")

	enemy.call("reset_enemy")
	await TestHelpers.await_frames(get_tree(), 2)
	if controller.get_debug_info().get("death_playing", true):
		failures.append("reset_enemy should clear death visual state.")

	enemy.queue_free()


func _test_contract(failures: PackedStringArray) -> void:
	if VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE != Vector2i(32, 54):
		failures.append("Gunslinger approved frame must be 32x54.")
	if VermiliteGunslingerAnimationContract.PILOT_ANIMATION_IDS.size() != 8:
		failures.append("Gunslinger pilot set must include 8 clips.")
	var summary := VermiliteGunslingerAnimationContract.get_visual_contract_summary()
	if String(summary.get("ammo_rule", "")) != "physical_vermilite_slug_not_magic":
		failures.append("Ammo rule must forbid generic magic projectiles.")
