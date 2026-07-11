extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const DeaconRuskScene := preload("res://scenes/enemies/deacon_rusk.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const RedBrandBreaker := preload("res://resources/combat/red_brand_breaker_lv1.tres")
const BodyHook := preload("res://resources/combat/body_hook.tres")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "deacon_rusk_tests")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	var ground := StaticBody2D.new()
	var ground_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1400, 48)
	ground_shape.shape = rectangle
	ground.position = Vector2(700, 900)
	ground.add_child(ground_shape)
	root_node.add_child(ground)

	var player: Node = await TestHelpers.mount_player(root_node, self, Vector2(560, 848))

	var boss: DeaconRusk = DeaconRuskScene.instantiate()
	boss.global_position = Vector2(780, 848)
	root_node.add_child(boss)
	await process_frame

	_prepare_active_boss(boss, player)
	await _test_attack_patterns(failures, boss)
	await _test_counterable_attacks(failures, boss)
	await _test_non_counterable_attacks(failures, boss)
	await _test_phase_transition(failures, boss)
	await _test_stagger_and_red_brand(failures, boss, player)
	await _test_stagger_immunity(failures, boss, player)
	await _test_boss_death(failures, boss, player)

	boss.queue_free()
	player.queue_free()
	root_node.queue_free()

	suite.finish(failures, 7)


func _prepare_active_boss(boss: DeaconRusk, player: Node) -> void:
	boss.player_target = player as Node2D
	boss.is_boss_active = true
	boss.current_state = DeaconRusk.RuskState.CHOOSE_ATTACK
	boss._set_dormant(false)


func _test_attack_patterns(failures: PackedStringArray, boss: DeaconRusk) -> void:
	var kinds := [
		DeaconRusk.AttackKind.DOUBLE_JAB,
		DeaconRusk.AttackKind.CHARGE,
		DeaconRusk.AttackKind.PUNISH_SWEEP,
		DeaconRusk.AttackKind.DEFENSIVE_RETREAT,
		DeaconRusk.AttackKind.GROUND_SLAM,
		DeaconRusk.AttackKind.ARMORED_CHARGE,
		DeaconRusk.AttackKind.TAUNT,
	]

	for kind in kinds:
		boss.current_phase = 2 if kind in [
			DeaconRusk.AttackKind.GROUND_SLAM,
			DeaconRusk.AttackKind.ARMORED_CHARGE,
		] else 1
		boss._begin_attack(kind)
		await process_frame
		if boss.current_state != DeaconRusk.RuskState.ATTACK:
			failures.append("Attack kind %s should enter ATTACK state." % kind)
		boss._interrupt_attack()
		boss.current_state = DeaconRusk.RuskState.CHOOSE_ATTACK
		await process_frame


func _test_counterable_attacks(failures: PackedStringArray, boss: DeaconRusk) -> void:
	if not boss._is_attack_counterable(boss.jab_1_data):
		failures.append("Jab 1 should be counterable.")
	if not boss._is_attack_counterable(boss.punish_sweep_data):
		failures.append("Punish sweep should be counterable.")
	if not bool(boss.jab_1_data.get("counterable")):
		failures.append("Jab 1 AttackData should expose counterable=true.")


func _test_non_counterable_attacks(failures: PackedStringArray, boss: DeaconRusk) -> void:
	if boss._is_attack_counterable(boss.charge_data):
		failures.append("Charge should not be counterable.")
	if boss._is_attack_counterable(boss.ground_slam_data):
		failures.append("Ground slam should not be counterable.")
	if boss._is_attack_counterable(boss.armored_charge_data):
		failures.append("Armored charge should not be counterable.")

	boss._begin_attack(DeaconRusk.AttackKind.CHARGE)
	await process_frame
	if boss.warning_visual == null or not boss.warning_visual.visible:
		failures.append("Non-counterable charge should show warning telegraph.")
	boss._interrupt_attack()


func _test_phase_transition(failures: PackedStringArray, boss: DeaconRusk) -> void:
	boss.current_phase = 1
	boss._phase_transition_triggered = false
	boss.health_component.current_health = boss.max_health * 0.49
	boss.health_component.invulnerable = false
	boss._begin_attack(DeaconRusk.AttackKind.CHARGE)
	await process_frame
	boss._interrupt_attack()
	boss._check_phase_transition()
	await process_frame

	if boss.current_state != DeaconRusk.RuskState.PHASE_TRANSITION:
		failures.append("Boss should enter phase transition below 50% HP.")
	if boss.health_component.invulnerable:
		pass
	else:
		failures.append("Boss should be invulnerable during phase transition.")

	boss.state_time_remaining = 0.0
	boss._advance_timed_state()
	await process_frame

	if boss.current_phase != 2:
		failures.append("Boss should reach phase 2 after transition.")
	if boss.health_component.current_health >= boss.max_health:
		failures.append("Phase transition must not restore full health.")
	if boss.health_component.current_health > boss.max_health * 0.51:
		failures.append("Phase transition should keep current health.")


func _test_stagger_and_red_brand(
	failures: PackedStringArray,
	boss: DeaconRusk,
	player: Node
) -> void:
	boss.current_state = DeaconRusk.RuskState.CHOOSE_ATTACK
	boss._stagger_meter = 0.0
	boss._stagger_immunity_remaining = 0.0
	boss.health_component.invulnerable = false

	boss._apply_stagger_from_attack(BodyHook)
	if boss.current_state == DeaconRusk.RuskState.STAGGERED:
		failures.append("Single normal hit should not instantly stagger the boss.")

	boss.current_state = DeaconRusk.RuskState.CHOOSE_ATTACK
	boss._stagger_meter = 0.0
	boss._apply_stagger_from_attack(RedBrandBreaker)
	await process_frame
	if boss.current_state != DeaconRusk.RuskState.STAGGERED:
		failures.append("Red Brand should cause a major stagger.")
	if boss.get_stagger_ratio() < 0.99:
		failures.append("Red Brand should fill stagger meter.")


func _test_stagger_immunity(
	failures: PackedStringArray,
	boss: DeaconRusk,
	player: Node
) -> void:
	boss.current_state = DeaconRusk.RuskState.CHOOSE_ATTACK
	boss._stagger_immunity_remaining = 2.0
	boss._stagger_meter = 0.0
	boss._apply_stagger_from_attack(RedBrandBreaker)
	if boss.current_state == DeaconRusk.RuskState.STAGGERED:
		failures.append("Stagger immunity should prevent immediate re-stagger.")


func _test_boss_death(failures: PackedStringArray, boss: DeaconRusk, player: Node) -> void:
	var defeated_tracker := {"done": false}
	boss.boss_defeated.connect(func(_id: StringName) -> void: defeated_tracker["done"] = true)

	boss.current_state = DeaconRusk.RuskState.CHOOSE_ATTACK
	boss.health_component.invulnerable = false
	boss.health_component.current_health = 8.0
	boss.health_component.apply_damage(999.0, player)
	await process_frame
	await process_frame

	if not boss.health_component.is_dead:
		failures.append("Boss should die from lethal damage.")
	if not defeated_tracker["done"]:
		failures.append("Boss should emit boss_defeated on death.")
	if boss.current_state != DeaconRusk.RuskState.DEAD:
		failures.append("Boss should enter dead state.")
