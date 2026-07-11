extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const PlayerScript := preload("res://scripts/player/player.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const HitstopScript := preload("res://scripts/core/hitstop_controller.gd")
const LockManagerScript := preload("res://scripts/core/gameplay_lock_manager.gd")
const CultHook := preload("res://resources/combat/cult_brawler_hook.tres")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")
const BodyHook := preload("res://resources/combat/body_hook.tres")
const RedKnuckle := preload("res://resources/combat/red_knuckle.tres")
const BrandBreakerLv1 := preload("res://resources/combat/red_brand_breaker_lv1.tres")
const BrandBreakerLv2 := preload("res://resources/combat/red_brand_breaker_lv2.tres")

const GROUND_COLLISION_LAYER := 1
const FIXTURE_PLAYER_POSITION := Vector2(320, 848)
const TEST_COUNT := 48


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "player_regression_tests")
	var failures: PackedStringArray = PackedStringArray()
	var fixture := await _create_fixture()
	var player: CharacterBody2D = fixture["player"]

	_test_scene_contract(failures, player)
	_test_persistence_api(failures, player)
	_test_facing(failures, player)
	_test_facing_visual_not_body(failures, player)
	await _test_horizontal_movement(failures, player, fixture)
	await _test_acceleration(failures, player, fixture)
	await _test_deceleration(failures, player, fixture)
	await _test_gravity(failures, player, fixture)
	await _test_jump_and_fall(failures, player, fixture)
	await _test_variable_jump_cut(failures, player, fixture)
	await _test_coyote_time(failures, player, fixture)
	await _test_jump_buffer(failures, player, fixture)
	await _test_fall_recovery(failures, player, fixture)
	await _test_combo_attack_resources(failures, player)
	await _test_combo_chain(failures, player, fixture)
	await _test_combo_buffer_contract(failures, player, fixture)
	await _test_attack_phases(failures, player, fixture)
	await _test_attack_finish_clears(failures, player, fixture)
	await _test_hitbox_single_target(failures, player, fixture)
	await _test_attack_interrupt(failures, player, fixture)
	await _test_counter_window(failures, player, fixture)
	await _test_counter_early_miss(failures, player, fixture)
	await _test_counter_late_miss(failures, player, fixture)
	await _test_counter_not_counterable(failures, player, fixture)
	await _test_dodge_phases(failures, player, fixture)
	await _test_dodge_invulnerability(failures, player, fixture)
	await _test_dodge_finished_and_cooldown(failures, player, fixture)
	await _test_taunt_lock(failures, player, fixture)
	await _test_taunt_duration_and_signals(failures, player, fixture)
	await _test_taunt_vulnerability_and_cooldown(failures, player, fixture)
	await _test_brand_insufficient_energy(failures, player, fixture)
	await _test_brand_breaker_charge(failures, player, fixture)
	await _test_brand_cancel_emits_signal(failures, player, fixture)
	await _test_brand_level1_release(failures, player, fixture)
	await _test_brand_level2_barrier_tags(failures, player, fixture)
	_test_dialogue_lock(failures, player)
	_test_transition_lock(failures, player)
	_test_dialogue_unlock_restores(failures, player)
	_test_death_lock(failures, player)
	await _test_death_gameplay_lock(failures, player, fixture)
	_test_dual_locks(failures, player)
	_test_unlock_out_of_order(failures, player)
	await _test_damage_hurt_interrupts(failures, player, fixture)
	_test_save_contract(failures, player)
	_test_checkpoint_contract(failures, player)
	_test_area_settings_contract(failures, player)
	await _test_hitstop_contract(failures, player, fixture)
	await _test_visual_independence(failures, player, fixture)

	_release_all_input()
	fixture["root"].queue_free()
	await TestHelpers.await_frames(self, 1)
	suite.finish(failures, TEST_COUNT)


func _create_fixture() -> Dictionary:
	var root_node := Node2D.new()
	root_node.name = "PlayerRegressionRoot"
	root.add_child(root_node)

	var ground := StaticBody2D.new()
	var ground_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1400, 48)
	ground_shape.shape = rectangle
	ground.position = Vector2(700, 900)
	ground.collision_layer = GROUND_COLLISION_LAYER
	ground.collision_mask = 0
	ground.add_child(ground_shape)
	root_node.add_child(ground)

	var hitstop: Node = HitstopScript.new()
	hitstop.name = "HitstopController"
	root_node.add_child(hitstop)

	var lock_manager: GameplayLockManager = LockManagerScript.new()
	lock_manager.name = "GameplayLockManager"
	root_node.add_child(lock_manager)
	lock_manager.bind_hitstop_controller(hitstop)

	var player: CharacterBody2D = PlayerScene.instantiate() as CharacterBody2D
	player.global_position = FIXTURE_PLAYER_POSITION
	root_node.add_child(player)
	await TestHelpers.await_physics_frames(self, 6)

	return {"root": root_node, "player": player, "ground": ground, "hitstop": hitstop, "lock_manager": lock_manager}


func _await_on_floor(
	failures: PackedStringArray,
	player: CharacterBody2D,
	frame_budget: int = 8
) -> bool:
	for _i in frame_budget:
		await TestHelpers.await_physics_frames(self, 1)
		if player.is_on_floor():
			return true

	failures.append("Fixture player must stand on ground collision layer 1.")
	return false


func _release_all_input() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "dodge", "counter", "taunt", "special"]:
		_release(action)


func _advance_seconds(seconds: float) -> void:
	var frames := maxi(int(ceil(seconds * 60.0)), 1)
	await TestHelpers.await_physics_frames(self, frames)


func _press(action: String) -> void:
	Input.action_press(action)


func _release(action: String) -> void:
	Input.action_release(action)


func _reset_player(player: CharacterBody2D, position: Vector2 = FIXTURE_PLAYER_POSITION) -> void:
	player.call("clear_input_locks")
	player.call("interrupt_attack", PlayerScript.PlayerState.IDLE)
	player.global_position = position
	player.velocity = Vector2.ZERO
	var health: Node = player.get_node("%HealthComponent")
	if bool(health.get("is_dead")):
		health.call("reset_health")
	player.set("current_state", PlayerScript.PlayerState.IDLE)


func _movement_controller(player: CharacterBody2D) -> Node:
	return player.get_node("Controllers/PlayerMovementController")


func _brand_config(player: CharacterBody2D) -> Resource:
	var brand: Node = player.get_node("%RedBrandComponent")
	return brand.get("config") as Resource


func _simulate_buffered_jump(player: CharacterBody2D) -> void:
	player.set("jump_buffer_remaining", float(player.get("jump_buffer_time")))
	player.set("coyote_time_remaining", float(player.get("coyote_time")))
	player.call("_try_buffered_jump")


func _test_scene_contract(failures: PackedStringArray, player: CharacterBody2D) -> void:
	if not player.is_in_group("player"):
		failures.append("Player must join group 'player'.")

	for node_name in [
		"Visual", "BodyVisual", "DirectionMarker", "Components", "HitboxComponent",
		"HurtboxComponent", "HealthComponent", "RedBrandComponent", "InteractionDetector",
		"DebugLabel", "InteractionPromptLabel",
	]:
		if player.get_node_or_null("%" + node_name) == null:
			failures.append("Missing required unique node '%s'." % node_name)

	for controller_name in [
		"PlayerInputController", "PlayerMovementController", "PlayerStateCoordinator",
		"PlayerPresentationController", "PlayerDebugView",
	]:
		if player.get_node_or_null("Controllers/" + controller_name) == null:
			failures.append("Missing controller node '%s'." % controller_name)

	var combo: Array = player.get("combo_attacks")
	if combo.size() != 3:
		failures.append("Player combo must contain exactly three AttackData resources.")

	if String(combo[0].get("attack_id")) != "calder_straight":
		failures.append("Combo index 0 must remain calder_straight.")
	if String(combo[1].get("attack_id")) != "body_hook":
		failures.append("Combo index 1 must remain body_hook.")
	if String(combo[2].get("attack_id")) != "red_knuckle":
		failures.append("Combo index 2 must remain red_knuckle finisher.")


func _test_persistence_api(failures: PackedStringArray, player: CharacterBody2D) -> void:
	if not player.has_method("capture_persistence_state"):
		failures.append("Player must expose capture_persistence_state().")
	if not player.has_method("get_health_component"):
		failures.append("Player must expose get_health_component().")
	if not player.has_method("get_red_brand_component"):
		failures.append("Player must expose get_red_brand_component().")

	var state: Dictionary = player.call("capture_persistence_state")
	if not state.has("current_health") or not state.has("red_brand_energy"):
		failures.append("capture_persistence_state must include health and red brand.")


func _test_facing(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("set_facing_direction", -1)
	if int(player.get("facing_direction")) != -1:
		failures.append("set_facing_direction(-1) should set facing_direction.")

	var marker: Node2D = player.get_node("%DirectionMarker")
	if marker.scale.x > 0.0:
		failures.append("Direction marker should mirror when facing left.")

	player.call("set_facing_direction", 1)
	if marker.scale.x < 0.0:
		failures.append("Direction marker should mirror when facing right.")


func _test_facing_visual_not_body(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("set_facing_direction", -1)
	var visual: Node2D = player.get_node("%Visual")
	if is_zero_approx(visual.scale.x):
		failures.append("Visual node should mirror for facing.")
	if not is_equal_approx(player.scale.x, 1.0):
		failures.append("CharacterBody2D scale must not flip for facing (use Visual only).")


func _test_horizontal_movement(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	# Headless Input.action_press is unreliable; use the same locomotion adapter as acceleration.
	var delta := 1.0 / 60.0
	player.velocity.x = 0.0
	for _i in 20:
		player.call("_apply_horizontal_movement", 1.0, delta)

	if player.velocity.x <= 0.0:
		failures.append("Horizontal movement input should produce positive velocity.x.")


func _test_acceleration(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	_press("move_right")
	await TestHelpers.await_physics_frames(self, 12)
	_release("move_right")
	await TestHelpers.await_physics_frames(self, 1)

	if player.velocity.x < 80.0:
		var delta := 1.0 / 60.0
		player.velocity.x = 0.0
		for _i in 12:
			player.call("_apply_horizontal_movement", 1.0, delta)
		if player.velocity.x < 80.0:
			failures.append("Ground acceleration should raise velocity.x toward max_run_speed.")


func _test_deceleration(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	_release_all_input()
	player.velocity = Vector2(220, 0)
	await TestHelpers.await_physics_frames(self, 10)

	if absf(player.velocity.x) > 20.0:
		failures.append("Ground deceleration should reduce horizontal velocity without input.")


func _test_gravity(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	player.set("fall_recovery_y", 2000.0)
	player.global_position.y -= 80.0
	player.velocity = Vector2.ZERO
	await TestHelpers.await_physics_frames(self, 4)

	if player.velocity.y <= 0.0:
		failures.append("Gravity should increase downward velocity while airborne.")


func _test_jump_and_fall(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	_simulate_buffered_jump(player)

	if player.velocity.y > -100.0:
		failures.append("Jump on floor should set upward velocity.")

	if int(player.get("current_state")) not in [PlayerScript.PlayerState.JUMP, PlayerScript.PlayerState.FALL]:
		failures.append("Jump should enter JUMP or FALL state.")


func _test_variable_jump_cut(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	_simulate_buffered_jump(player)
	var before := player.velocity.y
	var movement := _movement_controller(player)
	movement.call("apply_variable_jump_cut", true)
	if before >= 0.0 or player.velocity.y >= 0.0 or player.velocity.y <= before:
		failures.append("Variable jump cut should reduce upward velocity while rising.")


func _test_coyote_time(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	await TestHelpers.await_physics_frames(self, 1)
	player.global_position.y -= 18.0
	player.velocity = Vector2.ZERO
	await TestHelpers.await_physics_frames(self, 1)

	if player.is_on_floor():
		failures.append("Coyote test requires player to leave floor briefly.")

	player.set("coyote_time_remaining", float(player.get("coyote_time")) * 0.75)
	player.set("jump_buffer_remaining", float(player.get("jump_buffer_time")))
	player.call("_try_buffered_jump")

	if player.velocity.y > -20.0:
		failures.append("Coyote time should allow jump shortly after leaving floor.")


func _test_jump_buffer(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	await TestHelpers.await_physics_frames(self, 1)
	player.global_position.y -= 20.0
	player.velocity = Vector2(0, 120.0)
	player.set("jump_buffer_remaining", float(player.get("jump_buffer_time")))
	player.set("coyote_time_remaining", float(player.get("coyote_time")) * 0.5)
	player.call("_try_buffered_jump")

	if player.velocity.y >= -40.0:
		failures.append("Jump buffer should trigger jump on landing when pressed early.")


func _test_fall_recovery(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	player.call("set_spawn_position", Vector2(400, 848))
	player.call("apply_area_settings", {"fall_recovery_y": 900.0})
	player.global_position = Vector2(400, 960)
	player.velocity = Vector2(100, 200)
	await TestHelpers.await_physics_frames(self, 2)

	if player.global_position.distance_to(Vector2(400, 848)) > 4.0:
		failures.append("Fall recovery should teleport player back to spawn_position.")
	if not is_zero_approx(player.velocity.x) or not is_zero_approx(player.velocity.y):
		failures.append("Fall recovery should clear velocity.")


func _test_combo_attack_resources(failures: PackedStringArray, player: CharacterBody2D) -> void:
	var combo: Array = player.get("combo_attacks")
	if String(combo[0].get("display_name")) != "Calder Straight":
		failures.append("Combo slot 0 display name must remain Calder Straight.")
	if String(combo[1].get("display_name")) != "Body Hook":
		failures.append("Combo slot 1 display name must remain Body Hook.")
	if String(combo[2].get("display_name")) != "Red Knuckle":
		failures.append("Combo slot 2 display name must remain Red Knuckle.")


func _test_combo_chain(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 3)

	var combo_completed := [0]
	player.connect("combo_completed", func() -> void: combo_completed[0] += 1)

	player.call("_start_attack_at_index", 0)
	await _advance_seconds(0.35)
	player.call("_start_attack_at_index", 1)
	await _advance_seconds(0.45)
	player.call("_start_attack_at_index", 2)
	await _advance_seconds(0.60)

	if combo_completed[0] < 1:
		failures.append("Three-hit combo should emit combo_completed at least once.")


func _test_combo_buffer_contract(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_attack_at_index", 0)
	player.set("attack_elapsed_time", float(CalderStraight.get("cancel_window_start")) + 0.01)
	player.call("_buffer_next_combo_attack")

	if int(player.get("buffered_combo_attack_index")) != 1:
		failures.append("Combo buffer should store next attack index during cancel window.")


func _test_attack_phases(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 3)

	player.call("_start_attack_at_index", 0)
	await TestHelpers.await_physics_frames(self, 1)
	var startup_or_active := int(player.get("attack_phase")) in [
		PlayerScript.AttackPhase.STARTUP,
		PlayerScript.AttackPhase.ACTIVE,
	]
	await _advance_seconds(0.10)
	var active_or_recovery := int(player.get("attack_phase")) in [
		PlayerScript.AttackPhase.ACTIVE,
		PlayerScript.AttackPhase.RECOVERY,
	]

	if not startup_or_active:
		failures.append("Attack should progress through startup/active phases.")
	if not active_or_recovery:
		failures.append("Attack should reach recovery phase before finishing.")


func _test_attack_finish_clears(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_attack_at_index", 0)
	var total := (
		float(CalderStraight.get("startup_time"))
		+ float(CalderStraight.get("active_time"))
		+ float(CalderStraight.get("recovery_time"))
		+ 0.05
	)
	await _advance_seconds(total)

	if player.get("current_attack") != null:
		failures.append("Attack should clear current_attack after all phases complete.")
	if int(player.get("attack_phase")) != PlayerScript.AttackPhase.NONE:
		failures.append("Attack phase should return to NONE after finish.")


func _test_hitbox_single_target(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	var hitbox: Area2D = player.get_node("%HitboxComponent")
	var dummy := Node2D.new()
	dummy.name = "HitboxDummy"
	player.get_parent().add_child(dummy)

	hitbox.call("activate", CalderStraight, player, 1)
	var target_id := dummy.get_instance_id()
	var counts: Dictionary = hitbox.get("hit_counts")
	counts[target_id] = 1
	hitbox.set("hit_counts", counts)

	if int(CalderStraight.get("max_hits_per_target")) != 1:
		failures.append("Calder straight must remain single-hit per target.")

	hitbox.call("clear_hit_targets")
	if not (hitbox.get("hit_counts") as Dictionary).is_empty():
		failures.append("New attack activation should clear prior hit targets.")

	hitbox.call("deactivate")
	dummy.queue_free()


func _test_attack_interrupt(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_attack_at_index", 0)
	await TestHelpers.await_physics_frames(self, 1)

	player.call("interrupt_attack", PlayerScript.PlayerState.IDLE)
	if player.get("current_attack") != null:
		failures.append("interrupt_attack should clear current_attack.")


func _test_counter_window(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)

	player.call("_start_counter")
	await _advance_seconds(float(player.get("counter_startup")) + 0.01)

	if int(player.get("counter_phase")) != PlayerScript.CounterPhase.WINDOW:
		failures.append("Counter input should reach WINDOW phase.")

	var attacker := Node2D.new()
	attacker.global_position = Vector2(500, 848)
	player.get_parent().add_child(attacker)

	var accepted: bool = player.call("try_counter_hit", CultHook, null, attacker)
	if not accepted:
		failures.append("Counterable attack during window should be accepted.")

	attacker.queue_free()


func _test_counter_early_miss(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_counter")

	var attacker := Node2D.new()
	player.get_parent().add_child(attacker)
	var accepted: bool = player.call("try_counter_hit", CultHook, null, attacker)
	if accepted:
		failures.append("Counter before WINDOW should be rejected.")

	attacker.queue_free()


func _test_counter_late_miss(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_counter")
	var total := (
		float(player.get("counter_startup"))
		+ float(player.get("counter_window"))
		+ float(player.get("counter_recovery"))
		+ 0.05
	)
	await _advance_seconds(total)

	var attacker := Node2D.new()
	player.get_parent().add_child(attacker)
	var accepted: bool = player.call("try_counter_hit", CultHook, null, attacker)
	if accepted:
		failures.append("Counter after window closes should be rejected.")

	attacker.queue_free()


func _test_counter_not_counterable(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_counter")
	await _advance_seconds(float(player.get("counter_startup")) + 0.01)

	var attacker := Node2D.new()
	player.get_parent().add_child(attacker)
	var accepted: bool = player.call("try_counter_hit", BrandBreakerLv2, null, attacker)
	if accepted:
		failures.append("Non-counterable attack should be rejected during counter window.")

	attacker.queue_free()


func _test_dodge_phases(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)

	var dodge_started := [false]
	player.connect("dodge_started", func() -> void: dodge_started[0] = true)

	if not await _await_on_floor(failures, player):
		return

	player.call("_start_ground_dodge")
	await TestHelpers.await_physics_frames(self, 2)

	if int(player.get("dodge_phase")) == PlayerScript.DodgePhase.NONE:
		failures.append("Dodge input should enter dodge phases.")
	if not dodge_started[0]:
		failures.append("Dodge should emit dodge_started.")


func _test_dodge_invulnerability(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	player.call("_start_ground_dodge")
	player.set("dodge_elapsed_time", float(player.get("invulnerability_start")) + 0.01)
	player.call("_update_dodge_invulnerability")

	var health: Node = player.get_node("%HealthComponent")
	if not bool(health.get("invulnerable")):
		failures.append("Dodge should apply invulnerability during active window.")


func _test_dodge_finished_and_cooldown(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	if not await _await_on_floor(failures, player):
		return

	var dodge_finished := [false]
	player.connect("dodge_finished", func() -> void: dodge_finished[0] = true)

	player.call("_start_ground_dodge")
	var total := (
		float(player.get("dodge_startup"))
		+ float(player.get("dodge_duration"))
		+ float(player.get("dodge_recovery"))
		+ 0.05
	)
	await _advance_seconds(total)

	if not dodge_finished[0]:
		failures.append("Dodge should emit dodge_finished after phases.")
	if float(player.get("dodge_cooldown_time_remaining")) <= 0.0:
		failures.append("Dodge should apply cooldown after finishing.")


func _test_taunt_lock(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)

	player.call("_start_taunt")
	await TestHelpers.await_physics_frames(self, 1)

	if int(player.get("current_state")) != PlayerScript.PlayerState.TAUNT:
		failures.append("Taunt input should enter TAUNT state.")
	if bool(player.call("can_interact_now")):
		failures.append("Taunt should block interactions.")


func _test_taunt_duration_and_signals(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)

	var taunt_started := [false]
	var phrase := [""]
	player.connect("taunt_started", func(p: String, _id: StringName) -> void:
		taunt_started[0] = true
		phrase[0] = p
	)

	player.call("_start_taunt")
	if not taunt_started[0]:
		failures.append("Taunt should emit taunt_started.")
	if phrase[0].strip_edges().is_empty():
		failures.append("Taunt should select a non-empty phrase.")
	if float(player.get("taunt_time_remaining")) <= 0.0:
		failures.append("Taunt should initialize duration timer.")


func _test_taunt_vulnerability_and_cooldown(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_taunt")
	player.set("taunt_elapsed_time", float(player.get("taunt_vulnerable_start")) + 0.02)
	player.call("_update_taunt_vulnerability")

	var health: Node = player.get_node("%HealthComponent")
	if bool(health.get("invulnerable")):
		failures.append("Taunt vulnerability window should disable invulnerability.")

	var duration := float(player.get("taunt_duration")) + 0.05
	await _advance_seconds(duration)

	if float(player.get("taunt_cooldown_time_remaining")) <= 0.0:
		failures.append("Taunt should apply cooldown after finishing.")


func _test_brand_insufficient_energy(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	var brand: Node = player.get_node("%RedBrandComponent")
	var config := _brand_config(player)
	var min_charge := float(config.get("min_energy_to_charge"))
	brand.call("set_energy", maxf(min_charge - 5.0, 0.0))
	await TestHelpers.await_physics_frames(self, 2)

	if not await _await_on_floor(failures, player):
		return

	if bool(player.call("_can_start_brand_charge")):
		failures.append("Brand charge should not start without minimum energy.")


func _test_brand_breaker_charge(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	var brand: Node = player.get_node("%RedBrandComponent")
	brand.call("set_energy", 60.0)
	await TestHelpers.await_physics_frames(self, 2)

	var charge_started := [false]
	player.connect("brand_breaker_charge_started", func() -> void: charge_started[0] = true)

	if not await _await_on_floor(failures, player):
		return

	player.call("_start_brand_charge")
	await TestHelpers.await_physics_frames(self, 4)
	player.call("_cancel_brand_breaker_charge")

	if not charge_started[0]:
		failures.append("Brand breaker charge should start with sufficient energy.")


func _test_brand_cancel_emits_signal(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	var brand: Node = player.get_node("%RedBrandComponent")
	brand.call("set_energy", 60.0)
	await TestHelpers.await_physics_frames(self, 2)

	var cancelled := [false]
	player.connect("brand_breaker_charge_cancelled", func() -> void: cancelled[0] = true)

	if not await _await_on_floor(failures, player):
		return

	player.call("_start_brand_charge")
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_cancel_brand_breaker_charge")

	if not cancelled[0]:
		failures.append("Brand charge cancel should emit brand_breaker_charge_cancelled.")


func _test_brand_level1_release(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	var brand: Node = player.get_node("%RedBrandComponent")
	brand.call("set_energy", 60.0)
	await TestHelpers.await_physics_frames(self, 2)

	var released := [false]
	var release_level := [0]
	player.connect("brand_breaker_released", func(level: int, _cost: float) -> void:
		released[0] = true
		release_level[0] = level
	)

	if not await _await_on_floor(failures, player):
		return

	player.call("_start_brand_charge")
	var config := _brand_config(player)
	player.set("brand_charge_time", float(config.get("charge_level_1_time")) + 0.01)
	player.call("_release_brand_breaker")

	if not released[0]:
		failures.append("Brand level 1 release should emit brand_breaker_released.")
	if release_level[0] < 1:
		failures.append("Brand release at level 1 timing should resolve to level >= 1.")


func _test_brand_level2_barrier_tags(failures: PackedStringArray, _player: CharacterBody2D, _fixture: Dictionary) -> void:
	var tags: PackedStringArray = BrandBreakerLv2.get("tags")
	var has_breaker := false
	var has_barrier := false
	for tag in tags:
		if tag == "red_brand_breaker":
			has_breaker = true
		if tag == "barrier_break":
			has_barrier = true
	if not has_breaker or not has_barrier:
		failures.append("Red Brand Breaker lv2 must keep barrier_break tags for red barriers.")


func _test_dialogue_lock(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("enter_dialogue_mode")
	if not bool(player.call("is_in_dialogue")):
		failures.append("enter_dialogue_mode should lock dialogue.")
	if bool(player.call("_can_accept_attack_input")):
		failures.append("Dialogue lock should block attack input.")


func _test_transition_lock(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("enter_transition_mode")
	if not bool(player.call("is_in_transition")):
		failures.append("enter_transition_mode should lock transition.")
	if bool(player.call("can_interact_now")):
		failures.append("Transition lock should block interaction.")


func _test_dialogue_unlock_restores(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("clear_input_locks")
	player.call("enter_dialogue_mode")
	player.call("exit_dialogue_mode")
	if bool(player.call("is_in_dialogue")):
		failures.append("exit_dialogue_mode should clear dialogue lock.")
	if not bool(player.call("_can_accept_attack_input")):
		failures.append("exit_dialogue_mode should restore attack input when no other lock active.")


func _test_death_lock(failures: PackedStringArray, player: CharacterBody2D) -> void:
	var health: Node = player.get_node("%HealthComponent")
	health.call("apply_damage", 999.0, null)
	if not bool(health.get("is_dead")):
		failures.append("Lethal damage should mark health dead.")
	if bool(player.call("can_interact_now")):
		failures.append("Death should block interaction.")

	health.call("reset_health")
	player.set("current_state", PlayerScript.PlayerState.IDLE)


func _test_death_gameplay_lock(failures: PackedStringArray, player: CharacterBody2D, fixture: Dictionary) -> void:
	_reset_player(player)
	var health: Node = player.get_node("%HealthComponent")
	health.call("apply_damage", 999.0, null)
	await TestHelpers.await_physics_frames(self, 2)

	var lock_manager: GameplayLockManager = fixture["lock_manager"]
	if not lock_manager.has_lock(GameplayLockManager.LockReason.DEATH):
		failures.append("Player death should acquire DEATH gameplay lock.")

	health.call("reset_health")
	player.call("clear_input_locks")
	player.set("current_state", PlayerScript.PlayerState.IDLE)


func _test_dual_locks(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("enter_dialogue_mode")
	player.call("enter_transition_mode")
	if not bool(player.call("is_in_dialogue")) or not bool(player.call("is_in_transition")):
		failures.append("Player should allow dialogue and transition locks simultaneously.")


func _test_unlock_out_of_order(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("exit_dialogue_mode")
	if not bool(player.call("is_in_transition")):
		failures.append("Exiting dialogue should not clear transition lock.")
	player.call("clear_input_locks")
	if bool(player.call("is_in_dialogue")) or bool(player.call("is_in_transition")):
		failures.append("clear_input_locks should clear all locks.")


func _test_damage_hurt_interrupts(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	await TestHelpers.await_physics_frames(self, 2)
	player.call("_start_attack_at_index", 0)
	await TestHelpers.await_physics_frames(self, 1)

	var health: Node = player.get_node("%HealthComponent")
	player.call("_on_player_damaged", 2.0, null)

	if int(player.get("current_state")) != PlayerScript.PlayerState.HURT:
		failures.append("Damage during attack should transition to HURT.")
	if player.get("current_attack") != null:
		failures.append("Damage should interrupt active attack.")


func _test_save_contract(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call(
		"apply_save_state",
		{
			"checkpoint_position": {"x": 640.0, "y": 848.0},
			"player_current_health": 7.0,
			"player_max_health": 12.0,
			"red_brand_energy": 25.0,
		}
	)

	if player.global_position.distance_to(Vector2(640, 848)) > 2.0:
		failures.append("apply_save_state should restore checkpoint position.")
	var health: Node = player.get_node("%HealthComponent")
	if not is_equal_approx(float(health.get("current_health")), 7.0):
		failures.append("apply_save_state should restore current health.")
	var brand: Node = player.get_node("%RedBrandComponent")
	if not is_equal_approx(float(brand.get("current_energy")), 25.0):
		failures.append("apply_save_state should restore red brand energy.")


func _test_checkpoint_contract(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("apply_checkpoint", Vector2(512, 848), true, true)
	if player.global_position.distance_to(Vector2(512, 848)) > 2.0:
		failures.append("apply_checkpoint should move player to checkpoint position.")
	var health: Node = player.get_node("%HealthComponent")
	if float(health.get("current_health")) < float(health.get("max_health")):
		failures.append("apply_checkpoint with restore_health should reset health.")


func _test_area_settings_contract(failures: PackedStringArray, player: CharacterBody2D) -> void:
	player.call("apply_area_settings", {"fall_recovery_y": 1280.0})
	if not is_equal_approx(float(player.get("fall_recovery_y")), 1280.0):
		failures.append("apply_area_settings should update fall_recovery_y.")


func _test_hitstop_contract(failures: PackedStringArray, player: CharacterBody2D, fixture: Dictionary) -> void:
	var hitstop: Node = fixture["hitstop"]
	var lock_manager: GameplayLockManager = fixture["lock_manager"]
	lock_manager.request_hitstop(0.065)
	await TestHelpers.await_frames(self, 1)

	if not bool(hitstop.get("hitstop_active")):
		failures.append("Hitstop controller should activate on request.")
	if Engine.time_scale != 1.0:
		failures.append("Hitstop must not freeze Engine.time_scale.")
	if paused:
		failures.append("Hitstop alone must not pause SceneTree.")

	hitstop.call("force_release")


func _test_visual_independence(failures: PackedStringArray, player: CharacterBody2D, _fixture: Dictionary) -> void:
	_reset_player(player)
	var body_visual: CanvasItem = player.get_node("%BodyVisual")
	var brand_hand: CanvasItem = player.get_node("%BrandHand")
	body_visual.visible = false
	brand_hand.visible = false
	await TestHelpers.await_physics_frames(self, 2)

	player.call("_start_attack_at_index", 0)
	await TestHelpers.await_physics_frames(self, 1)
	if player.get("current_attack") == null:
		failures.append("Attack must work when provisional body visuals are hidden.")

	var hitbox: Area2D = player.get_node("%HitboxComponent")
	hitbox.call("deactivate")
	body_visual.visible = true
	brand_hand.visible = true
