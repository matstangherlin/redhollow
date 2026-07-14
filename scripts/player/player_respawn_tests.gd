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
	await _test_boss_deferred_activation_and_no_duplicate(failures, root_node, player)
	await _test_boss_completion_is_idempotent(failures, root_node, player)
	await _test_save_load_checkpoint_contract(failures, player)

	player.queue_free()
	root_node.queue_free()
	await TestHelpers.await_frames(get_tree(), 2)

	suite.finish(failures, 8)


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

	if arena.get_remaining_enemy_count() != 0:
		failures.append("Arena should remove the previous roster after player death.")
	if arena.state != CombatArenaController.ArenaState.INACTIVE:
		failures.append("Arena should return to INACTIVE after player death.")
	if gate_left.is_closed() or gate_right.is_closed():
		failures.append("Player respawn must not leave arena gates closed.")

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
	if encounter.state != BossEncounterController.EncounterState.INACTIVE:
		failures.append("Boss encounter should return to INACTIVE after player death.")
	if bool(boss.get("is_boss_active")):
		failures.append("Deacon Rusk should be dormant until the encounter is re-entered.")
	if boss_hud.panel != null and boss_hud.panel.visible:
		failures.append("Boss HUD should remain hidden after encounter reset.")

	encounter.queue_free()
	boss_hud.queue_free()


func _test_boss_deferred_activation_and_no_duplicate(
	failures: PackedStringArray,
	root_node: Node2D,
	player: CharacterBody2D
) -> void:
	var fixture := await _build_boss_fixture(root_node)
	var encounter := fixture["encounter"] as BossEncounterController
	var boss := fixture["boss"] as DeaconRusk
	var boss_hud := fixture["hud"] as BossHealthHud
	var start_tracker := {"count": 0}
	encounter.encounter_started.connect(
		func(_encounter_id: StringName) -> void: start_tracker["count"] += 1
	)

	var first_request := encounter.request_activation(player)
	var duplicate_request := encounter.request_activation(player)
	if not first_request or duplicate_request:
		failures.append("Boss encounter should accept only one activation request per entry.")
	if encounter.state != BossEncounterController.EncounterState.ACTIVATION_REQUESTED:
		failures.append("Boss body_entered should stop at ACTIVATION_REQUESTED on the callback stack.")
	if boss.is_boss_active:
		failures.append("Deacon Rusk must not activate before the deferred physics boundary.")

	await TestHelpers.await_physics_frames(get_tree(), 5)
	await TestHelpers.await_frames(get_tree(), 2)
	if encounter.state != BossEncounterController.EncounterState.ACTIVE:
		failures.append("Deferred boss encounter should reach ACTIVE.")
	if not boss.is_boss_active or int(start_tracker["count"]) != 1:
		failures.append("Boss activation should start exactly once.")

	encounter.reset_active_encounter_for_player_death()
	await TestHelpers.await_physics_frames(get_tree(), 6)
	await TestHelpers.await_frames(get_tree(), 2)
	if encounter.state != BossEncounterController.EncounterState.INACTIVE:
		failures.append("Boss reset should reopen the encounter in INACTIVE.")
	if boss.is_boss_active or (boss_hud.panel != null and boss_hud.panel.visible):
		failures.append("Boss and HUD should remain dormant after reset.")

	encounter._on_activation_body_exited(player)
	encounter.request_activation(player)
	await TestHelpers.await_physics_frames(get_tree(), 5)
	await TestHelpers.await_frames(get_tree(), 2)
	if int(start_tracker["count"]) != 2:
		failures.append("Re-entry after reset should start one new boss cycle.")
	if encounter.get_children().filter(func(node: Node) -> bool: return node is DeaconRusk).size() != 1:
		failures.append("Deacon Rusk must not duplicate after respawn.")

	encounter.on_area_unloading()
	encounter.queue_free()
	boss_hud.queue_free()
	await TestHelpers.await_frames(get_tree(), 2)


func _test_boss_completion_is_idempotent(
	failures: PackedStringArray,
	root_node: Node2D,
	player: CharacterBody2D
) -> void:
	var fixture := await _build_boss_fixture(root_node)
	var encounter := fixture["encounter"] as BossEncounterController
	var boss := fixture["boss"] as DeaconRusk
	var boss_hud := fixture["hud"] as BossHealthHud
	var completion_tracker := {"count": 0}
	encounter.encounter_completed.connect(
		func(_encounter_id: StringName) -> void: completion_tracker["count"] += 1
	)

	encounter.request_activation(player)
	await TestHelpers.await_physics_frames(get_tree(), 5)
	await TestHelpers.await_frames(get_tree(), 2)
	var health := boss.get_node("%HealthComponent") as HealthComponent
	health.apply_damage(health.max_health, player)
	await TestHelpers.await_frames(get_tree(), 4)
	encounter._on_boss_defeated(boss.boss_id)

	if encounter.state != BossEncounterController.EncounterState.COMPLETED:
		failures.append("Boss encounter should complete after Deacon Rusk is defeated.")
	if int(completion_tracker["count"]) != 1:
		failures.append("Boss completion must be idempotent.")
	if boss_hud.panel != null and boss_hud.panel.visible:
		failures.append("Boss HUD should hide when the encounter completes.")

	encounter.queue_free()
	boss_hud.queue_free()
	await TestHelpers.await_frames(get_tree(), 2)


func _build_boss_fixture(parent: Node2D) -> Dictionary:
	var encounter: BossEncounterController = BossEncounterScene.instantiate()
	parent.add_child(encounter)
	var boss: DeaconRusk = DeaconRuskScene.instantiate()
	encounter.add_child(boss)
	boss.global_position = Vector2(820, 848)
	encounter.boss_path = boss.get_path()
	encounter._resolve_nodes()
	var boss_hud: BossHealthHud = BossHealthHudScene.instantiate()
	parent.add_child(boss_hud)
	encounter.bind_encounter_services(null, null, boss_hud)
	await TestHelpers.await_frames(get_tree(), 2)
	return {"encounter": encounter, "boss": boss, "hud": boss_hud}


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
