extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const PenitentScene := preload("res://scenes/enemies/chain_penitent.tscn")
const SweepData := preload("res://resources/combat/chain_penitent_sweep.tres")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")
const RedBrandBreaker := preload("res://resources/combat/red_brand_breaker_lv1.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "chain_penitent_visual_tests")
	suite.allow_warning_contains("PenitentVisual")
	suite.allow_warning_contains("procedural")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	_test_visual_nodes(failures, root_node)
	await _test_sprite_mode_and_clips(failures, root_node)
	await _test_telegraph_hit_death(failures, root_node)
	_test_contract(failures)

	root_node.queue_free()
	suite.finish(failures, 4)


func _test_visual_nodes(failures: PackedStringArray, parent: Node2D) -> void:
	var enemy: Node = PenitentScene.instantiate()
	parent.add_child(enemy)
	if enemy.get_node_or_null("%ChainPenitentVisualController") == null:
		failures.append("Penitent must include ChainPenitentVisualController.")
	if enemy.get_node_or_null("%SpriteVisual") == null:
		failures.append("Penitent must include SpriteVisual.")
	if enemy.get_node_or_null("%TelegraphVisual") == null:
		failures.append("Penitent must include TelegraphVisual.")
	if enemy.get_node_or_null("%ReachMarker") == null:
		failures.append("Penitent must include ReachMarker.")
	enemy.queue_free()


func _test_sprite_mode_and_clips(failures: PackedStringArray, parent: Node2D) -> void:
	var enemy: Node = PenitentScene.instantiate()
	parent.add_child(enemy)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: ChainPenitentVisualController = enemy.get_node("%ChainPenitentVisualController")
	if not controller.is_sprite_active():
		failures.append("Pilot profile should activate Penitent sprite mode.")

	enemy.set("current_state", 4) # SWEEP
	enemy.set("attack_phase", "startup")
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"chain_startup":
		failures.append("Sweep startup should map to chain_startup.")

	enemy.set("attack_phase", "active")
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"chain_active":
		failures.append("Sweep active should map to chain_active.")

	enemy.set("current_state", 5) # HOOK
	enemy.set("attack_phase", "active")
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"pull":
		failures.append("Hook active should map to pull.")

	enemy.set("current_state", 1) # PATROL
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"walk":
		failures.append("Patrol should map to walk.")

	enemy.set("current_state", 7) # VULNERABLE
	controller.refresh(enemy, 0.016)
	if controller.get_current_animation() != &"stagger":
		failures.append("Vulnerable should map to stagger.")

	enemy.queue_free()


func _test_telegraph_hit_death(failures: PackedStringArray, parent: Node2D) -> void:
	var enemy: Node = PenitentScene.instantiate()
	enemy.global_position = Vector2(520, 848)
	parent.add_child(enemy)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: ChainPenitentVisualController = enemy.get_node("%ChainPenitentVisualController")

	controller.notify_attack_telegraph(SweepData)
	if controller.get_current_animation() != &"chain_startup":
		failures.append("Telegraph should play chain_startup.")

	controller.apply_hit_reaction(CalderStraight)
	if controller.get_current_animation() != &"hurt":
		failures.append("Light hit should play hurt.")

	controller.apply_hit_reaction(RedBrandBreaker)
	if controller.get_current_animation() != &"stagger":
		failures.append("Breaker should play stagger.")

	controller.play_death()
	if controller.get_current_animation() != &"death":
		failures.append("Death should play death clip.")

	enemy.call("reset_enemy")
	await TestHelpers.await_frames(get_tree(), 2)
	if controller.get_debug_info().get("death_playing", true):
		failures.append("reset_enemy should clear death visual state.")

	enemy.queue_free()


func _test_contract(failures: PackedStringArray) -> void:
	if ChainPenitentAnimationContract.APPROVED_FRAME_SIZE != Vector2i(38, 58):
		failures.append("Penitent approved frame must be 38x58.")
	if ChainPenitentAnimationContract.PILOT_ANIMATION_IDS.size() != 9:
		failures.append("Penitent pilot set must include 9 clips.")
	var summary := ChainPenitentAnimationContract.get_visual_contract_summary()
	if String(summary.get("weapon_rule", "")) != "metal_chain_reach_not_magic":
		failures.append("Weapon rule must forbid generic magic chain VFX.")
