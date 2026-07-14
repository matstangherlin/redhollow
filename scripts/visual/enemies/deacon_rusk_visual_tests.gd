extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const DeaconScene := preload("res://scenes/enemies/deacon_rusk.tscn")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")
const Jab1 := preload("res://resources/combat/rusk_jab_1.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "deacon_rusk_visual_tests")
	suite.allow_warning_contains("DeaconVisual")
	suite.allow_warning_contains("procedural")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	_test_nodes(failures, root_node)
	await _test_clips(failures, root_node)
	_test_contract(failures)

	root_node.queue_free()
	suite.finish(failures, 3)


func _test_nodes(failures: PackedStringArray, parent: Node2D) -> void:
	var boss: Node = DeaconScene.instantiate()
	parent.add_child(boss)
	if boss.get_node_or_null("%DeaconRuskVisualController") == null:
		failures.append("Deacon must include visual controller.")
	if boss.get_node_or_null("%SpriteVisual") == null:
		failures.append("Deacon must include SpriteVisual.")
	# Collision unchanged.
	var shape := boss.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or shape.shape == null:
		failures.append("Body collision must remain.")
	elif (shape.shape as RectangleShape2D).size != Vector2(42, 68):
		failures.append("Deacon collision must remain 42x68.")
	boss.queue_free()


func _test_clips(failures: PackedStringArray, parent: Node2D) -> void:
	var boss: Node = DeaconScene.instantiate()
	parent.add_child(boss)
	await TestHelpers.await_frames(get_tree(), 2)
	var controller: DeaconRuskVisualController = boss.get_node("%DeaconRuskVisualController")
	if not controller.is_sprite_active():
		failures.append("Pilot profile should activate Deacon sprite mode.")

	boss.set("current_state", 2) # REPOSITION
	controller.refresh(boss, 0.016)
	if controller.get_current_animation() != &"reposition":
		failures.append("REPOSITION should map to reposition.")

	boss.set("current_state", 4) # ATTACK
	boss.set("current_attack_kind", 1) # DOUBLE_JAB
	boss.set("attack_phase", "startup")
	controller.notify_attack_telegraph(Jab1)
	if controller.get_current_animation() != &"punch_combo":
		failures.append("Double jab should map to punch_combo.")

	boss.set("current_attack_kind", 3) # PUNISH_SWEEP
	controller.refresh(boss, 0.016)
	if controller.get_current_animation() != &"counterable_attack":
		failures.append("Punish sweep should map to counterable_attack.")

	boss.set("current_attack_kind", 6) # ARMORED
	controller.refresh(boss, 0.016)
	if controller.get_current_animation() != &"armor_attack":
		failures.append("Armored charge should map to armor_attack.")

	controller.apply_hit_reaction(CalderStraight)
	if controller.get_current_animation() != &"hurt":
		failures.append("Hit reaction should play hurt.")

	controller.play_death()
	if controller.get_current_animation() != &"death":
		failures.append("Death should play death.")

	boss.queue_free()


func _test_contract(failures: PackedStringArray) -> void:
	if DeaconRuskAnimationContract.APPROVED_FRAME_SIZE != Vector2i(42, 72):
		failures.append("Approved frame must be 42x72.")
	if DeaconRuskAnimationContract.PILOT_ANIMATION_IDS.size() != 11:
		failures.append("Pilot set must include 11 clips.")
	if DeaconRuskAnimationContract.GAMEPLAY_COLLISION_SIZE != Vector2i(42, 68):
		failures.append("Gameplay collision must remain 42x68.")
