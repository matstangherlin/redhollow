extends HeadlessSuiteRunner

const RespawnServiceScript := preload("res://scripts/core/respawn_service.gd")
const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const CombatArenaScene := preload("res://scenes/world/combat_arena.tscn")
const CombatArenaGateScene := preload("res://scenes/world/combat_arena_gate.tscn")
const CultBrawlerScene := preload("res://scenes/enemies/cult_brawler.tscn")
const BossEncounterScene := preload("res://scenes/world/boss_encounter.tscn")
const BossHealthHudScene := preload("res://scenes/ui/boss_health_hud.tscn")
const DeaconRuskScene := preload("res://scenes/enemies/deacon_rusk.tscn")
const ProgressionScript := preload("res://scripts/progression/progression_component.gd")
const SaveManagerScript := preload("res://scripts/save/save_manager.gd")
const SaveDataScript := preload("res://scripts/save/save_data.gd")
const PlayerScript := preload("res://scripts/player/player.gd")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "player_respawn_tests")
	suite.allow_error_contains("CombatArena 'church_yard_01' integrity failure")

	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)
	await TestHelpers.await_frames(get_tree(), 2)

	var lock_manager: GameplayLockManager = await _mount_lock_manager(root_node)
	var player: CharacterBody2D = await _mount_player(root_node)
	var respawn_service: RespawnServiceScript = _mount_respawn_service(root_node, lock_manager, player)
	await TestHelpers.await_frames(get_tree(), 2)

	await _test_death_lock_and_respawn(failures, player, lock_manager, respawn_service)
	await _test_checkpoint_respawn_position(failures, player, respawn_service)
	await _test_fall_recovery_without_death(failures, player)
	await _test_arena_reset_on_death(failures, root_node, player, respawn_service)
	await _test_boss_reset_on_death(failures, root_node, player, respawn_service)
	await _test_save_load_checkpoint_contract(failures, player)

	player.queue_free()
	root_node.queue_free()
	await TestHelpers.await_frames(get_tree(), 2)

	suite.finish(failures, 6)


func _mount_lock_manager(parent: Node) -> GameplayLockManager:
	var manager := GameplayLockManager.new()
	parent.add_child(manager)
	return manager


func _mount_respawn_service(parent: Node, lock_manager: GameplayLockManager, player: CharacterBody2D) -> RespawnServiceScript:
	var service: RespawnServiceScript = RespawnServiceScript.new()
	service.death_respawn_delay = 0.02
	service.fade_duration = 0.01
	parent.add_child(service)

	var services := GameServices.new()
	parent.add_child(services)
	services.gameplay_lock_manager = lock_manager
	services.player = player
	services.respawn_service = service
	service.bind_from_services(services)
	return service


func _mount_player(parent: Node) -> CharacterBody2D:
	var player: CharacterBody2D = PlayerScene.instantiate()
	player.global_position = Vector2(320, 848)
	parent.add_child(player)
	await TestHelpers.await_frames(get_tree(), 1)
	player.call("set_spawn_position", Vector2(320, 848))
	return player


func _kill_player(player: CharacterBody2D) -> void:
	var health: Node = player.get_node("%HealthComponent")
	health.call("apply_damage", 999.0, null)


func _test_death_lock_and_respawn(
	failures: PackedStringArray,
	player: CharacterBody2D,
	lock_manager: GameplayLockManager,
	respawn_service: RespawnServiceScript
) -> void:
	_reset_player(player)
	_kill_player(player)

	var health: Node = player.get_node("%HealthComponent")
	if not bool(health.get("is_dead")):
		failures.append("Lethal damage should mark player health as dead.")
	if not lock_manager.has_lock(GameplayLockManager.LockReason.DEATH):
		failures.append("Death should acquire DEATH gameplay lock.")

	await TestHelpers.await_seconds(get_tree(), 0.2)
	await TestHelpers.await_frames(get_tree(), 5)

	if bool(health.get("is_dead")):
		failures.append("RespawnService should restore player health after death sequence.")
	if lock_manager.has_lock(GameplayLockManager.LockReason.DEATH):
		failures.append("RespawnService should release DEATH lock after fade completes.")
	if respawn_service.is_respawn_pending():
		failures.append("Respawn sequence should clear pending flag when finished.")


func _test_checkpoint_respawn_position(
	failures: PackedStringArray,
	player: CharacterBody2D,
	respawn_service: RespawnServiceScript
) -> void:
	_reset_player(player)
	player.call("set_spawn_position", Vector2(640, 800))
	player.global_position = Vector2(900, 848)
	_kill_player(player)
	await TestHelpers.await_seconds(get_tree(), 0.2)
	await TestHelpers.await_frames(get_tree(), 5)

	if player.global_position.distance_to(Vector2(640, 800)) > 2.0:
		failures.append("Death respawn should return player to checkpoint spawn_position.")


func _test_fall_recovery_without_death(
	failures: PackedStringArray,
	player: CharacterBody2D
) -> void:
	_reset_player(player)
	player.call("set_spawn_position", Vector2(400, 848))
	player.global_position = Vector2(500, 1400)
	var health: Node = player.get_node("%HealthComponent")
	var health_before := float(health.get("current_health"))

	var movement: Node = player.get_node("Controllers/PlayerMovementController")
	movement.call("recover_if_out_of_arena")
	await TestHelpers.await_physics_frames(get_tree(), 2)

	if bool(health.get("is_dead")):
		failures.append("Fall recovery should not kill the player.")
	if float(health.get("current_health")) < health_before:
		failures.append("Fall recovery should not reduce player health.")
	if player.global_position.distance_to(Vector2(400, 848)) > 2.0:
		failures.append("Fall recovery should teleport player to spawn_position.")


func _test_arena_reset_on_death(
	failures: PackedStringArray,
	root_node: Node2D,
	player: CharacterBody2D,
	respawn_service: RespawnServiceScript
) -> void:
	_reset_player(player)
	var arena: CombatArenaController = CombatArenaScene.instantiate()
	root_node.add_child(arena)
	var gate_left: CombatArenaGate = CombatArenaGateScene.instantiate()
	var gate_right: CombatArenaGate = CombatArenaGateScene.instantiate()
	arena.add_child(gate_left)
	arena.add_child(gate_right)
	gate_left.global_position = Vector2(60, 848)
	gate_right.global_position = Vector2(940, 848)
	arena.gate_paths = [gate_left.get_path(), gate_right.get_path()]
	arena.enemy_scene = CultBrawlerScene
	var enemies_container := Node2D.new()
	arena.add_child(enemies_container)
	arena.enemies_container_path = enemies_container.get_path()
	var spawn_point := Node2D.new()
	spawn_point.global_position = Vector2(720, 848)
	arena.add_child(spawn_point)
	arena.enemy_spawn_paths = [spawn_point.get_path()]
	arena._resolve_nodes()
	arena._set_state(CombatArenaController.ArenaState.ACTIVE)
	arena.call_deferred("_spawn_configured_enemies")
	await TestHelpers.await_frames(get_tree(), 3)

	var before_count := arena.get_remaining_enemy_count()
	if before_count <= 0:
		failures.append("Arena fixture should spawn at least one enemy before death reset test.")

	_kill_player(player)
	await TestHelpers.await_seconds(get_tree(), 0.2)
	await TestHelpers.await_frames(get_tree(), 8)

	if arena.get_remaining_enemy_count() < before_count:
		failures.append("Arena should respawn living enemies after player death.")
	if arena.state != CombatArenaController.ArenaState.ACTIVE:
		failures.append("Arena should remain active after player death reset.")

	arena.queue_free()


func _test_boss_reset_on_death(
	failures: PackedStringArray,
	root_node: Node2D,
	player: CharacterBody2D,
	respawn_service: RespawnServiceScript
) -> void:
	_reset_player(player)
	var encounter: BossEncounterController = BossEncounterScene.instantiate()
	root_node.add_child(encounter)
	var boss: Node = DeaconRuskScene.instantiate()
	encounter.add_child(boss)
	boss.global_position = Vector2(820, 848)
	encounter.boss_path = boss.get_path()
	encounter._resolve_nodes()

	var boss_hud: BossHealthHud = BossHealthHudScene.instantiate()
	root_node.add_child(boss_hud)
	encounter.bind_encounter_services(null, null, boss_hud)
	encounter._set_state(BossEncounterController.EncounterState.ACTIVE)
	boss.call("activate_boss")
	encounter._bind_boss_hud()
	await TestHelpers.await_frames(get_tree(), 2)

	var boss_health: Node = boss.get_node("%HealthComponent")
	boss_health.call("apply_damage", float(boss_health.get("max_health")) * 0.5, null)
	_kill_player(player)
	await TestHelpers.await_seconds(get_tree(), 0.2)
	await TestHelpers.await_frames(get_tree(), 5)

	if bool(boss_health.get("is_dead")):
		failures.append("Boss should be reset to alive state after player death.")
	if float(boss_health.get("current_health")) < float(boss_health.get("max_health")):
		failures.append("Boss health should be fully restored after player death reset.")
	if boss_hud.panel == null or not boss_hud.panel.visible:
		failures.append("Boss HUD should be rebound and visible after player death reset.")

	encounter.queue_free()
	boss_hud.queue_free()


func _test_save_load_checkpoint_contract(failures: PackedStringArray, player: CharacterBody2D) -> void:
	_reset_player(player)
	player.call(
		"apply_save_state",
		{
			"checkpoint_position": {"x": 512.0, "y": 848.0},
			"player_current_health": 6.0,
			"player_max_health": 10.0,
			"red_brand_energy": 18.0,
		}
	)

	if player.global_position.distance_to(Vector2(512, 848)) > 2.0:
		failures.append("Save restore should position player at checkpoint coordinates.")

	var health: Node = player.get_node("%HealthComponent")
	if float(health.get("current_health")) != 6.0:
		failures.append("Save restore should keep non-full health values.")

	_kill_player(player)
	await TestHelpers.await_seconds(get_tree(), 0.2)
	await TestHelpers.await_frames(get_tree(), 5)

	if float(health.get("current_health")) < float(health.get("max_health")):
		failures.append("Death respawn after save restore should reset health to max.")


func _reset_player(player: CharacterBody2D) -> void:
	var health: Node = player.get_node("%HealthComponent")
	health.call("reset_health")
	player.call("clear_input_locks")
	player.call("set_death_vulnerability", false)
	player.set("current_state", PlayerScript.PlayerState.IDLE)
	player.velocity = Vector2.ZERO
