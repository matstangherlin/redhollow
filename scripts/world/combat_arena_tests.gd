extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const CombatArenaScene := preload("res://scenes/world/combat_arena.tscn")
const CombatArenaGateScene := preload("res://scenes/world/combat_arena_gate.tscn")
const CultBrawlerScene := preload("res://scenes/enemies/cult_brawler.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const ProgressionScript := preload("res://scripts/progression/progression_component.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "combat_arena_tests")
	# Headless Godot 4.7 emits physics flush errors while arena gates/enemies toggle collision
	# during isolated SceneTree runs. Assertions still validate arena behavior.
	suite.allow_error_contains("Can't change this state while flushing queries")
	suite.allow_warning_contains("lost a living enemy from the scene tree")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	var fixture_player: Node = PlayerScene.instantiate()
	fixture_player.name = "Player"
	fixture_player.global_position = Vector2(720, 848)
	root_node.add_child(fixture_player)
	await TestHelpers.await_frames(self, 2)

	var style_manager: Node = await TestHelpers.mount_style_manager(root_node, self)
	var progression: Node = ProgressionScript.new()
	root_node.add_child(progression)
	progression.call("set_narrative_flag", &"arena_church_yard_01_complete", false)
	await TestHelpers.await_frames(self, 1)

	await _test_starts_inactive(failures, root_node)
	await _test_activation_and_blocking(failures, root_node, style_manager, progression)
	await _test_partial_defeat(failures, root_node)
	await _test_full_completion(failures, root_node, style_manager, progression)
	await _test_no_reactivation(failures, root_node, progression)
	await _test_scene_restart(failures, root_node)
	await _test_foreign_enemy_ignored(failures, root_node)

	fixture_player.queue_free()
	root_node.queue_free()
	await TestHelpers.await_frames(self, 2)

	suite.finish(failures, 7)


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
	await TestHelpers.await_frames(self, 2)
	return exit as AreaExit


func _wire_arena(
	arena: CombatArenaController,
	exits: Array[AreaExit],
	reset_state: bool = true
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
	if reset_state:
		arena._set_state(CombatArenaController.ArenaState.INACTIVE)
	if arena._activation_zone != null and not arena._activation_zone.body_entered.is_connected(
		arena._on_activation_body_entered
	):
		arena._activation_zone.body_entered.connect(arena._on_activation_body_entered)


func _defeat_tracked_enemies(arena: CombatArenaController, player: Node) -> void:
	for enemy in arena._tracked_enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var health: HealthComponent = arena._find_health_component(enemy)
		if health != null and not health.is_dead:
			if not health.apply_damage(health.max_health, player):
				health.set_health_values(0.0, health.max_health)
		arena._on_enemy_died(enemy)


func _activate_arena(arena: CombatArenaController, player: Node) -> void:
	arena.call_deferred("_on_activation_body_entered", player)
	await TestHelpers.await_physics_frames(self, 3)
	await TestHelpers.await_frames(self, 1)


func _free_arena_run(
	arena: CombatArenaController,
	player: Node,
	extra_nodes: Array = []
) -> void:
	_defeat_tracked_enemies(arena, player)
	await TestHelpers.await_physics_frames(self, 1)

	var was_paused := paused
	paused = true

	for enemy in arena._tracked_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.free()

	for node in extra_nodes:
		if node != null and is_instance_valid(node):
			node.free()

	if player != null and is_instance_valid(player):
		player.free()

	arena.free()
	paused = was_paused

	await TestHelpers.await_physics_frames(self, 2)
	await TestHelpers.await_frames(self, 1)


func _test_starts_inactive(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	await TestHelpers.await_frames(self, 1)

	if arena.state != CombatArenaController.ArenaState.INACTIVE:
		failures.append("Arena should start inactive.")
	if arena.is_blocking_exits():
		failures.append("Inactive arena should not block exits.")

	var was_paused := paused
	paused = true
	arena.free()
	paused = was_paused
	await TestHelpers.await_physics_frames(self, 1)


func _test_activation_and_blocking(
	failures: PackedStringArray,
	parent: Node2D,
	style_manager: Node,
	progression: Node
) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var messages: Array[String] = []
	arena.arena_message_shown.connect(func(message: String) -> void: messages.append(message))

	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(self, 2)

	await _activate_arena(arena, player)

	if arena.state != CombatArenaController.ArenaState.ACTIVE:
		failures.append("Arena should activate when Calder enters.")
	if arena.get_remaining_enemy_count() != 2:
		failures.append("Arena should spawn two Cult Brawlers.")
	if not arena.is_blocking_exits():
		failures.append("Active arena should block exits.")
	if not exit_left.is_arena_blocked():
		failures.append("Street exit should be blocked during combat.")
	if not exit_right.is_arena_blocked():
		failures.append("Underground exit should be blocked during combat.")
	if not messages.has("Derrote os cultistas para abrir as portas"):
		failures.append("Arena should show combat start hint.")

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_partial_defeat(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(self, 2)
	await _activate_arena(arena, player)

	var enemies := arena._tracked_enemies.duplicate()
	if enemies.is_empty():
		failures.append("Expected spawned arena enemies for partial defeat test.")
	else:
		var first_enemy: Node = enemies[0]
		var health: HealthComponent = arena._find_health_component(first_enemy)
		if health != null:
			health.apply_damage(health.max_health, player)
			await TestHelpers.await_frames(self, 1)

		if arena.state != CombatArenaController.ArenaState.ACTIVE:
			failures.append("Arena should stay active after one enemy dies.")
		if arena.get_remaining_enemy_count() != 1:
			failures.append("One arena enemy should remain alive.")

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
	_wire_arena(arena, [exit_left, exit_right])

	var completion_tracker := {"done": false}
	arena.arena_completed.connect(
		func(_arena_id: StringName) -> void: completion_tracker["done"] = true
	)

	var messages: Array[String] = []
	arena.arena_message_shown.connect(func(message: String) -> void: messages.append(message))

	var style_before: float = style_manager.get("style_score")
	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(self, 2)
	await _activate_arena(arena, player)

	for enemy in arena._tracked_enemies.duplicate():
		var health: HealthComponent = arena._find_health_component(enemy)
		if health != null and not health.is_dead:
			health.apply_damage(health.max_health, player)
			await TestHelpers.await_frames(self, 1)

	await TestHelpers.await_frames(self, 2)

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

	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_no_reactivation(failures: PackedStringArray, parent: Node2D, progression: Node) -> void:
	progression.call("set_narrative_flag", &"arena_church_yard_01_complete", true)

	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right], false)
	await TestHelpers.await_frames(self, 1)

	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Completed arena should restore as completed on load.")

	var player := _add_player(parent, Vector2(720, 848))
	await TestHelpers.await_frames(self, 1)
	await _activate_arena(arena, player)

	if arena.get_remaining_enemy_count() != 0:
		failures.append("Completed arena should not spawn enemies again.")
	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Completed arena should not reactivate.")

	progression.call("set_narrative_flag", &"arena_church_yard_01_complete", false)
	await _free_arena_run(arena, player, [exit_left, exit_right])


func _test_scene_restart(failures: PackedStringArray, parent: Node2D) -> void:
	var arena_a := _build_test_arena(parent)
	await TestHelpers.await_frames(self, 1)
	var initial_state := arena_a.state
	arena_a.queue_free()
	await TestHelpers.await_frames(self, 1)

	var arena_b := _build_test_arena(parent)
	await TestHelpers.await_frames(self, 1)

	if arena_b.state != initial_state:
		failures.append("Reinstantiating arena scene should restore initial inactive state.")
	if arena_b.get_remaining_enemy_count() != 0:
		failures.append("Fresh arena instance should have no tracked enemies.")

	arena_b.queue_free()
	await TestHelpers.await_frames(self, 1)


func _test_foreign_enemy_ignored(failures: PackedStringArray, parent: Node2D) -> void:
	var arena := _build_test_arena(parent)
	var exit_left := await _add_exit(parent, Vector2(40, 848), "ExitLeft")
	var exit_right := await _add_exit(parent, Vector2(960, 848), "ExitRight")
	_wire_arena(arena, [exit_left, exit_right])

	var foreign_brawler: Node = CultBrawlerScene.instantiate()
	foreign_brawler.global_position = Vector2(1200, 848)
	parent.add_child(foreign_brawler)
	await TestHelpers.await_frames(self, 1)

	var player := _add_player(parent, Vector2(720, 848))
	await _activate_arena(arena, player)

	if arena._spawned_count != 2:
		failures.append("Arena should only track its configured enemy count.")

	for enemy in arena._tracked_enemies.duplicate():
		var health: HealthComponent = arena._find_health_component(enemy)
		if health != null and not health.is_dead:
			health.apply_damage(health.max_health, player)
			await TestHelpers.await_frames(self, 1)

	await TestHelpers.await_frames(self, 2)

	if arena.state != CombatArenaController.ArenaState.COMPLETED:
		failures.append("Arena completion should ignore foreign enemies outside its roster.")

	var foreign_health: HealthComponent = arena._find_health_component(foreign_brawler)
	if foreign_health != null and foreign_health.is_dead:
		failures.append("Foreign enemy should not be counted by arena defeat logic.")

	await _free_arena_run(arena, player, [exit_left, exit_right, foreign_brawler])
