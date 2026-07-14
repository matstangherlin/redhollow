extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const CombatArenaScene := preload("res://scenes/world/combat_arena.tscn")
const CombatArenaGateScene := preload("res://scenes/world/combat_arena_gate.tscn")
const CultBrawlerScene := preload("res://scenes/enemies/cult_brawler.tscn")
const GunslingerScene := preload("res://scenes/enemies/vermilite_gunslinger.tscn")
const ChainPenitentScene := preload("res://scenes/enemies/chain_penitent.tscn")
const ProjectileScene := preload("res://scenes/combat/physical_projectile.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const ProgressionScript := preload("res://scripts/progression/progression_component.gd")
const ShotData := preload("res://resources/combat/gunslinger_shot.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "combat_arena_tests")
	suite.allow_warning_contains("CombatArena 'church_yard_01' integrity failure")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)
	await TestHelpers.await_frames(get_tree(), 2)

	var style_manager: Node = await TestHelpers.mount_style_manager(root_node, get_tree())
	var progression: Node = ProgressionScript.new()
	root_node.add_child(progression)
	progression.call("set_narrative_flag", &"arena_church_yard_01_complete", false)
	await TestHelpers.await_frames(get_tree(), 1)

	await _test_starts_inactive(failures, root_node)
	await _test_gate_physics_state_is_deferred(failures, root_node)
	await _test_activation_request_is_deferred(failures, root_node)
	await _test_activation_and_blocking(failures, root_node, style_manager, progression)
	await _test_combined_three_archetypes(failures, root_node)
	await _test_isolated_brawler_spawn(failures, root_node)
	await _test_isolated_gunslinger_spawn(failures, root_node)
	await _test_isolated_chain_penitent_spawn(failures, root_node)
	await _test_partial_defeat(failures, root_node)
	await _test_full_completion(failures, root_node, style_manager, progression)
	await _test_no_double_activation(failures, root_node)
	await _test_quick_entry_exit_does_not_duplicate(failures, root_node)
	await _test_no_reactivation(failures, root_node, progression)
	await _test_scene_restart(failures, root_node)
	await _test_foreign_enemy_ignored(failures, root_node)
	await _test_integrity_failure_on_despawn(failures, root_node)
	await _test_enemy_death_counted_once(failures, root_node)
	await _test_death_reset_respawns_enemies(failures, root_node)
	await _test_projectile_cleanup_on_reset(failures, root_node)
	await _test_area_unload_opens_gates(failures, root_node)
	await _test_completion_is_idempotent(failures, root_node)
	await _test_two_consecutive_cycles(failures, root_node)

	root_node.queue_free()
	await TestHelpers.await_frames(get_tree(), 2)

	suite.finish(failures, 22)


func _build_test_arena(parent: Node2D) -> CombatArenaController:
	var arena: CombatArenaController = CombatArenaScene.instantiate()
	parent.add_child(arena)
	return arena


func _add_player(parent: Node2D, position: Vector2) -> Node:
	var player: Node = PlayerScene.instantiate()
	player.global_position = position
	parent.add_child(player)
	return player


func _add_exit(parent: Node2D, position: Vector2, exit_name: String) -> AreaExit:
	var exit := AreaExit.new()
	exit.name = exit_name
	exit.position = position
	exit.target_scene = "res://scenes/areas/street_test.tscn"
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(24, 96)
	shape.shape = rectangle
	exit.add_child(shape)
	parent.add_child(exit)
	await TestHelpers.await_frames(get_tree(), 2)
	return exit as AreaExit


func _wire_arena(
	arena: CombatArenaController,
	exits: Array[AreaExit],
	reset_state: bool = true,
	style_manager: StyleManager = null,
	progression: ProgressionComponent = null
) -> void:
	var gate_left: CombatArenaGate = CombatArenaGateScene.instantiate()
	var gate_right: CombatArenaGate = CombatArenaGateScene.instantiate()
	arena.add_child(gate_left)
	arena.add_child(gate_right)
	gate_left.global_position = Vector2(60, 848)
	gate_right.global_position = Vector2(940, 848)

	arena.gate_paths = [gate_left.get_path(), gate_right.get_path()]
	arena.blocked_exit_paths = [
		NodePath(exits[0].get_path()),
		NodePath(exits[1].get_path()),
	]
	arena._resolve_nodes()
	arena.bind_combat_services(style_manager, progression)
	if reset_state:
		arena._set_state(CombatArenaController.ArenaState.INACTIVE)
	if arena._activation_zone != null and not arena._activation_zone.body_entered.is_connected(
		arena._on_activation_body_entered
	):
		arena._activation_zone.body_entered.connect(arena._on_activation_body_entered)


func _activate_arena(arena: CombatArenaController, player: Node) -> void:
	arena.arm_activation_monitoring()
	await TestHelpers.await_physics_frames(get_tree(), 2)
	arena.call_deferred("_on_activation_body_entered", player)
	await TestHelpers.await_seconds(get_tree(), 0.5)


func _free_arena_run(
	arena: CombatArenaController,
	player: Node,
	extra_nodes: Array = [],
	progression: ProgressionComponent = null
) -> void:
	if is_instance_valid(arena) and arena.state == CombatArenaController.ArenaState.ACTIVE:
		arena.on_area_unloading()
		await TestHelpers.await_physics_frames(get_tree(), 2)
		await TestHelpers.await_frames(get_tree(), 2)

	var was_paused := paused
	paused = true

	for node in extra_nodes:
		if node != null and is_instance_valid(node):
			node.free()

	if player != null and is_instance_valid(player):
		player.free()

	if is_instance_valid(arena):
		arena.free()

	if progression != null and is_instance_valid(progression):
		progression.set_narrative_flag(&"arena_church_yard_01_complete", false)

	paused = was_paused

	await TestHelpers.await_physics_frames(get_tree(), 2)
	await TestHelpers.await_frames(get_tree(), 1)


func _test_starts_inactive(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	await TestHelpers.await_frames(get_tree(), 1)

	if arena.state != CombatArenaController.ArenaState.INACTIVE:
		failures.append("Arena should start inactive.")
	if arena.is_blocking_exits():
		failures.append("Inactive arena should not block exits.")

	var was_paused := paused
	paused = true
	arena.free()
	paused = was_paused
	await TestHelpers.await_physics_frames(get_tree(), 1)


func _test_gate_physics_state_is_deferred(failures: PackedStringArray, parent: Node2D) -> void:
	var gate: CombatArenaGate = CombatArenaGateScene.instantiate()
	parent.add_child(gate)
	await TestHelpers.await_frames(get_tree(), 2)

	gate.set_closed(true)
	if not gate.is_closed():
		failures.append("Gate should expose the requested closed state immediately.")
	if gate.is_physics_closed():
		failures.append("Gate collision must not change on the requesting call stack.")
	await TestHelpers.await_frames(get_tree(), 1)
	if not gate.is_physics_closed() or gate.collision_layer == 0:
		failures.append("Gate collision should close in the deferred callback.")

	gate.set_closed(false)
	if not gate.is_physics_closed():
		failures.append("Gate physics should remain closed until deferred opening applies.")
	await TestHelpers.await_frames(get_tree(), 1)
	if gate.is_physics_closed() or gate.collision_layer != 0:
		failures.append("Gate collision should reopen in the deferred callback.")

	gate.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_activation_request_is_deferred(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(get_tree(), 2)

	var accepted := arena.request_activation(player)
	if not accepted:
		failures.append("Inactive arena should accept one activation request.")
	if arena.state != CombatArenaController.ArenaState.ACTIVATION_REQUESTED:
		failures.append("body_entered should only move arena to ACTIVATION_REQUESTED.")
	if arena._spawned_count != 0 or not arena._tracked_enemies.is_empty():
		failures.append("Activation request must not add enemies on the physics callback stack.")
	if arena.is_blocking_exits():
		failures.append("ACTIVATION_REQUESTED should not close gates before the safe boundary.")

	await TestHelpers.await_physics_frames(get_tree(), 5)
	await TestHelpers.await_frames(get_tree(), 2)
	if arena.state != CombatArenaController.ArenaState.ACTIVE:
		failures.append("Deferred activation should deterministically reach ACTIVE.")

	await _free_arena_run(arena, player)


func _test_activation_and_blocking(
	failures: PackedStringArray,
	parent: Node2D,
	style_manager: Node,
	progression: Node
) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right], true, style_manager as StyleManager, progression as ProgressionComponent)

	var messages: Array[String] = []
	arena.arena_message_shown.connect(func(message: String) -> void: messages.append(message))

	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(get_tree(), 2)
	await _activate_arena(arena, player)

	if arena.state != CombatArenaController.ArenaState.ACTIVE:
		failures.append("Arena should activate when Calder enters.")
	if arena.get_remaining_enemy_count() != 3:
		failures.append("Combined arena should spawn three archetype enemies.")
	if not arena.is_blocking_exits():
		failures.append("Active arena should block exits.")
	if not exit_left.is_arena_blocked():
		failures.append("Street exit should be blocked during combat.")
	if not exit_right.is_arena_blocked():
		failures.append("Underground exit should be blocked during combat.")
	if not messages.has("Um de cada vez — leia o telegraph"):
		failures.append("Arena should show combat start hint.")

	await _free_arena_run(arena, player, [exit_left, exit_right], progression as ProgressionComponent)


func _test_combined_three_archetypes(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	var script_paths: Dictionary = {}
	for enemy in arena._tracked_enemies:
		var script := enemy.get_script() as Script
		if script != null:
			script_paths[script.resource_path] = true

	if not script_paths.has("res://scripts/enemies/cult_brawler.gd"):
		failures.append("Combined arena should include a Cult Brawler.")
	if not script_paths.has("res://scripts/enemies/vermilite_gunslinger.gd"):
		failures.append("Combined arena should include a Vermilite Gunslinger.")
	if not script_paths.has("res://scripts/enemies/chain_penitent.gd"):
		failures.append("Combined arena should include a Chain Penitent.")

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_isolated_brawler_spawn(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := await _build_single_enemy_arena(parent, CultBrawlerScene)
	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._spawned_count != 1:
		failures.append("Isolated brawler arena should spawn exactly one enemy.")
	if arena._tracked_enemies.is_empty() or not _enemy_uses_script(arena._tracked_enemies[0], "cult_brawler.gd"):
		failures.append("Isolated brawler arena should spawn CultBrawler.")

	await _free_arena_run(arena, player)


func _test_isolated_gunslinger_spawn(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := await _build_single_enemy_arena(parent, GunslingerScene)
	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._spawned_count != 1:
		failures.append("Isolated gunslinger arena should spawn exactly one enemy.")
	if arena._tracked_enemies.is_empty() or not (arena._tracked_enemies[0] is VermiliteGunslinger):
		failures.append("Isolated gunslinger arena should spawn VermiliteGunslinger.")

	await _free_arena_run(arena, player)


func _test_isolated_chain_penitent_spawn(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := await _build_single_enemy_arena(parent, ChainPenitentScene)
	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._spawned_count != 1:
		failures.append("Isolated penitent arena should spawn exactly one enemy.")
	if arena._tracked_enemies.is_empty() or not (arena._tracked_enemies[0] is ChainPenitent):
		failures.append("Isolated penitent arena should spawn ChainPenitent.")

	await _free_arena_run(arena, player)


func _build_single_enemy_arena(parent: Node2D, enemy_scene: PackedScene) -> CombatArenaController:
	var arena := _build_test_arena(parent)
	await TestHelpers.await_frames(get_tree(), 1)

	var spawn := arena.get_node("EnemySpawns/SpawnA") as CombatArenaSpawnPoint
	spawn.enemy_scene = enemy_scene
	arena.enemy_spawn_paths = [NodePath("EnemySpawns/SpawnA")]
	arena.enemy_scene = enemy_scene
	arena._resolve_nodes()
	arena._set_state(CombatArenaController.ArenaState.INACTIVE)
	arena._spawned_count = 0
	arena._tracked_enemies.clear()
	arena._defeated_instance_ids.clear()
	if arena._activation_zone != null and not arena._activation_zone.body_entered.is_connected(
		arena._on_activation_body_entered
	):
		arena._activation_zone.body_entered.connect(arena._on_activation_body_entered)
	await TestHelpers.await_frames(get_tree(), 1)
	return arena


func _test_partial_defeat(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right], true, null, null)

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	var enemies := arena._tracked_enemies.duplicate()
	if enemies.is_empty():
		failures.append("Expected spawned arena enemies for partial defeat test.")
	else:
		var first_enemy: Node = enemies[0]
		var health: HealthComponent = arena._find_health_component(first_enemy)
		if health != null:
			health.apply_damage(health.max_health, player)
			await TestHelpers.await_frames(get_tree(), 2)

		if arena.state != CombatArenaController.ArenaState.ACTIVE:
			failures.append("Arena should stay active after one enemy dies.")
		if arena.get_remaining_enemy_count() != 2:
			failures.append("Two arena enemies should remain alive after one defeat.")

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_full_completion(
	failures: PackedStringArray,
	parent: Node2D,
	style_manager: Node,
	progression: Node
) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right], true, style_manager as StyleManager, progression as ProgressionComponent)

	var completion_tracker := {"done": false}
	arena.arena_completed.connect(
		func(_arena_id: StringName) -> void: completion_tracker["done"] = true
	)

	var messages: Array[String] = []
	arena.arena_message_shown.connect(func(message: String) -> void: messages.append(message))

	var style_before: float = style_manager.get("style_score")
	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	for enemy in arena._tracked_enemies.duplicate():
		var health: HealthComponent = arena._find_health_component(enemy)
		if health != null and not health.is_dead:
			health.apply_damage(health.max_health, player)
			await TestHelpers.await_frames(get_tree(), 1)

	await TestHelpers.await_frames(get_tree(), 3)

	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Arena should complete after all enemies are defeated.")
	if not completion_tracker["done"]:
		failures.append("Arena should emit arena_completed.")
	if not messages.has("Portas abertas — arena concluída"):
		failures.append("Arena should show completion hint.")
	if arena.is_blocking_exits():
		failures.append("Completed arena should unblock exits.")
	if exit_left.is_arena_blocked():
		failures.append("Street exit should reopen after arena completion.")
	if style_manager.get("style_score") <= style_before:
		failures.append("Arena completion should grant a style bonus.")
	if not bool(progression.get("narrative_flags").get("arena_church_yard_01_complete", false)):
		failures.append("Arena should set completion flag in progression.")

	await _free_arena_run(arena, player, [exit_left, exit_right], progression as ProgressionComponent)


func _test_no_double_activation(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var player := _add_player(parent, Vector2(720, 848))
	arena.call_deferred("_on_activation_body_entered", player)
	arena.call_deferred("_on_activation_body_entered", player)
	arena.call_deferred("_on_activation_body_entered", player)
	await TestHelpers.await_physics_frames(get_tree(), 5)
	await TestHelpers.await_frames(get_tree(), 2)

	if arena._spawned_count != 3:
		failures.append("Rapid activation should not duplicate arena enemies.")
	if arena.get_remaining_enemy_count() != 3:
		failures.append("Rapid activation should keep exactly three living arena enemies.")

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_quick_entry_exit_does_not_duplicate(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(get_tree(), 2)

	var first_request := arena.request_activation(player)
	player.global_position = Vector2(-1000, 848)
	var repeated_request := arena.request_activation(player)
	await TestHelpers.await_physics_frames(get_tree(), 5)
	await TestHelpers.await_frames(get_tree(), 2)

	if not first_request or repeated_request:
		failures.append("A quick exit must not register a second activation request.")
	if arena._spawned_count != 3 or arena.get_remaining_enemy_count() != 3:
		failures.append("Quick entry and exit should still create exactly one arena roster.")

	await _free_arena_run(arena, player)


func _test_no_reactivation(failures: PackedStringArray, parent: Node2D, progression: Node) -> void:
	progression.call("set_narrative_flag", &"arena_church_yard_01_complete", true)

	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right], false, null, progression as ProgressionComponent)
	await TestHelpers.await_frames(get_tree(), 1)

	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Completed arena should restore as completed on load.")

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena.get_remaining_enemy_count() != 0:
		failures.append("Completed arena should not spawn enemies again.")
	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Completed arena should not reactivate.")

	progression.call("set_narrative_flag", &"arena_church_yard_01_complete", false)
	await _free_arena_run(arena, player, [exit_left, exit_right], progression as ProgressionComponent)


func _test_scene_restart(failures: PackedStringArray, parent: Node2D) -> void:
	var arena_a := _build_test_arena(parent)
	await TestHelpers.await_frames(get_tree(), 1)
	var initial_state := arena_a.state
	arena_a.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)

	var arena_b := _build_test_arena(parent)
	await TestHelpers.await_frames(get_tree(), 1)

	if arena_b.state != initial_state:
		failures.append("Reinstantiating arena scene should restore initial inactive state.")
	if arena_b.get_remaining_enemy_count() != 0:
		failures.append("Fresh arena instance should have no tracked enemies.")

	arena_b.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_foreign_enemy_ignored(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right], true, null, null)

	var foreign_brawler: Node = CultBrawlerScene.instantiate()
	foreign_brawler.global_position = Vector2(1200, 848)
	parent.add_child(foreign_brawler)
	await TestHelpers.await_frames(get_tree(), 1)

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._spawned_count != 3:
		failures.append("Arena should only track its configured enemy count.")

	for enemy in arena._tracked_enemies.duplicate():
		var health: HealthComponent = arena._find_health_component(enemy)
		if health != null and not health.is_dead:
			health.apply_damage(health.max_health, player)
			arena._on_enemy_died(enemy)

	await TestHelpers.await_frames(get_tree(), 4)

	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Arena completion should ignore foreign enemies outside its roster.")

	var foreign_health: HealthComponent = arena._find_health_component(foreign_brawler)
	if foreign_health != null and foreign_health.is_dead:
		failures.append("Foreign enemy should not be counted by arena defeat logic.")

	await _free_arena_run(arena, player, [exit_left, exit_right, foreign_brawler])


func _test_integrity_failure_on_despawn(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var integrity_tracker := {"reason": ""}
	arena.arena_integrity_failed.connect(
		func(_arena_id: StringName, reason: String) -> void:
			integrity_tracker["reason"] = reason
	)

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._tracked_enemies.is_empty():
		failures.append("Integrity test expected spawned enemies.")
	else:
		var living_enemy: Node = arena._tracked_enemies[0]
		living_enemy.free()
		await TestHelpers.await_physics_frames(get_tree(), 6)
		await TestHelpers.await_frames(get_tree(), 3)

		if arena.state != CombatArenaController.ArenaState.INACTIVE:
			failures.append("Living enemy despawn should abort arena to inactive state (got %s)." % CombatArenaController.ArenaState.keys()[arena.state])
		if String(integrity_tracker.get("reason", "")).is_empty():
			failures.append("Living enemy despawn should emit arena_integrity_failed.")
		if exit_left.is_arena_blocked():
			failures.append("Integrity failure should reopen blocked exits.")

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_enemy_death_counted_once(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := await _build_single_enemy_arena(parent, CultBrawlerScene)
	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._tracked_enemies.is_empty():
		failures.append("Death idempotency fixture expected one arena enemy.")
	else:
		var enemy: Node = arena._tracked_enemies[0]
		var health := arena._find_health_component(enemy)
		if health != null:
			health.apply_damage(health.max_health, player)
		arena._on_enemy_died(enemy)
		arena._on_enemy_died(enemy)
		await TestHelpers.await_frames(get_tree(), 3)
		if arena._defeated_instance_ids.size() != 1:
			failures.append("A defeated enemy must be counted exactly once.")
		if enemy is CharacterBody2D:
			var body := enemy as CharacterBody2D
			if body.collision_layer != 0 or body.collision_mask != 0:
				failures.append("A defeated arena enemy must stop blocking after deferred cleanup.")

	await _free_arena_run(arena, player)


func _test_death_reset_respawns_enemies(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)
	var before_count := arena._spawned_count

	arena.reset_active_encounter_for_player_death()
	if arena.state != CombatArenaController.ArenaState.RESETTING:
		failures.append("Death reset request should synchronously enter RESETTING (got %s)." % CombatArenaController.ArenaState.keys()[arena.state])
	await TestHelpers.await_physics_frames(get_tree(), 6)
	await TestHelpers.await_frames(get_tree(), 2)

	if arena.state != CombatArenaController.ArenaState.INACTIVE:
		failures.append("Death reset should return arena to INACTIVE (got %s)." % CombatArenaController.ArenaState.keys()[arena.state])
	if arena._spawned_count != 0 or arena.get_remaining_enemy_count() != 0:
		failures.append("Death reset should remove the previous arena roster.")
	if exit_left.is_arena_blocked():
		failures.append("Death reset should reopen exits before Calder respawns.")

	player.global_position = Vector2(-1000, 848)
	arena._on_activation_body_exited(player)
	player.global_position = Vector2(720, 848)
	await _activate_arena(arena, player)
	if arena._spawned_count != before_count or arena.get_remaining_enemy_count() != before_count:
		failures.append("Re-entering after death should create one fresh full roster.")

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_projectile_cleanup_on_reset(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := await _build_single_enemy_arena(parent, GunslingerScene)
	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._tracked_enemies.is_empty():
		failures.append("Projectile cleanup test expected a gunslinger enemy.")
	else:
		var gunslinger: Node = arena._tracked_enemies[0]
		var projectile := ProjectileScene.instantiate() as PhysicalProjectile
		parent.add_child(projectile)
		projectile.global_position = Vector2(720, 848)
		projectile.launch(gunslinger, 1, ShotData)
		await TestHelpers.await_frames(get_tree(), 1)

		arena.reset_active_encounter_for_player_death()
		await TestHelpers.await_physics_frames(get_tree(), 6)
		await TestHelpers.await_frames(get_tree(), 2)

		if not get_tree().get_nodes_in_group("physical_projectile").is_empty():
			failures.append("Arena reset should clear projectiles owned by arena enemies.")

	await _free_arena_run(arena, player)


func _test_area_unload_opens_gates(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	arena.on_area_unloading()
	await TestHelpers.await_frames(get_tree(), 3)

	if exit_left.is_arena_blocked():
		failures.append("Area unload should unblock exits.")
	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_completion_is_idempotent(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := await _build_single_enemy_arena(parent, CultBrawlerScene)
	var player := _add_player(parent, Vector2(720, 848))
	var completion_tracker := {"count": 0}
	arena.arena_completed.connect(
		func(_arena_id: StringName) -> void: completion_tracker["count"] += 1
	)
	await _activate_arena(arena, player)

	var enemy: Node = arena._tracked_enemies[0] if not arena._tracked_enemies.is_empty() else null
	var health := arena._find_health_component(enemy)
	if health != null:
		health.apply_damage(health.max_health, player)
	await TestHelpers.await_frames(get_tree(), 3)
	arena.try_complete_if_enemies_cleared()
	arena._complete_arena()

	if arena.state != CombatArenaController.ArenaState.COMPLETED or int(completion_tracker["count"]) != 1:
		failures.append("Arena completion must be idempotent and emit exactly once.")

	await _free_arena_run(arena, player)


func _test_two_consecutive_cycles(failures: PackedStringArray, parent: Node2D) -> void:
	for cycle in range(2):
		var arena := await _build_single_enemy_arena(parent, CultBrawlerScene)
		var player := _add_player(parent, Vector2(720, 848))
		await _activate_arena(arena, player)
		if arena._spawned_count != 1 or arena.get_remaining_enemy_count() != 1:
			failures.append("Arena cycle %d should spawn exactly one owned enemy." % (cycle + 1))
		else:
			var enemy: Node = arena._tracked_enemies[0]
			var health := arena._find_health_component(enemy)
			if health != null:
				health.apply_damage(health.max_health, player)
			await TestHelpers.await_frames(get_tree(), 3)
			if arena.state != CombatArenaController.ArenaState.COMPLETED:
				failures.append("Arena cycle %d should complete normally." % (cycle + 1))
		await _free_arena_run(arena, player)


func _enemy_uses_script(enemy: Node, script_suffix: String) -> bool:
	var script := enemy.get_script() as Script
	return script != null and String(script.resource_path).ends_with(script_suffix)
