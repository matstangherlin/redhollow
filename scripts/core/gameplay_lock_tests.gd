extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const LockManagerScript := preload("res://scripts/core/gameplay_lock_manager.gd")
const HitstopScript := preload("res://scripts/core/hitstop_controller.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "gameplay_lock_tests")
	var failures: PackedStringArray = PackedStringArray()
	var fixture := await _create_fixture()

	await _test_two_locks(failures, fixture)
	await _test_three_locks(failures, fixture)
	await _test_release_out_of_order(failures, fixture)
	await _test_dialogue_during_transition(failures, fixture)
	await _test_pause_during_dialogue(failures, fixture)
	await _test_pause_during_hitstop(failures, fixture)
	await _test_death_during_hitstop(failures, fixture)
	await _test_save_load_session_locks(failures, fixture)
	await _test_boss_completion_lock(failures, fixture)
	await _test_demo_completion_lock(failures, fixture)

	fixture["root"].queue_free()
	await TestHelpers.await_frames(self, 1)
	suite.finish(failures, 10)


func _create_fixture() -> Dictionary:
	var root_node := Node.new()
	root_node.name = "GameplayLockTestRoot"
	root.add_child(root_node)

	var lock_manager: GameplayLockManager = LockManagerScript.new()
	lock_manager.name = "GameplayLockManager"
	root_node.add_child(lock_manager)

	var hitstop: Node = HitstopScript.new()
	hitstop.name = "HitstopController"
	root_node.add_child(hitstop)
	lock_manager.bind_hitstop_controller(hitstop)

	var player: CharacterBody2D = PlayerScene.instantiate() as CharacterBody2D
	player.global_position = Vector2(320, 848)
	root_node.add_child(player)

	await TestHelpers.await_physics_frames(self, 3)

	return {
		"root": root_node,
		"lock_manager": lock_manager,
		"hitstop": hitstop,
		"player": player,
	}


func _test_two_locks(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var owner_a := Node.new()
	var owner_b := Node.new()
	fixture["root"].add_child(owner_a)
	fixture["root"].add_child(owner_b)

	var dialogue := manager.acquire_lock(GameplayLockManager.LockReason.DIALOGUE, owner_a)
	var transition := manager.acquire_lock(GameplayLockManager.LockReason.AREA_TRANSITION, owner_b)

	if manager.get_lock_count() != 2:
		failures.append("Two independent locks should coexist.")

	if not manager.is_player_input_blocked():
		failures.append("Two blocking locks should block player input.")

	manager.release_lock(dialogue)
	if manager.has_lock(GameplayLockManager.LockReason.DIALOGUE):
		failures.append("Releasing dialogue should not keep dialogue lock active.")
	if not manager.has_lock(GameplayLockManager.LockReason.AREA_TRANSITION):
		failures.append("Releasing dialogue should not remove transition lock.")

	manager.release_lock(transition)
	if manager.is_player_input_blocked():
		failures.append("Player should recover control after all locks release.")


func _test_three_locks(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var owners: Array[Node] = []
	for i in 3:
		var owner := Node.new()
		owner.name = "LockOwner%d" % i
		fixture["root"].add_child(owner)
		owners.append(owner)

	var tokens: Array[GameplayLockToken] = [
		manager.acquire_lock(GameplayLockManager.LockReason.DIALOGUE, owners[0]),
		manager.acquire_lock(GameplayLockManager.LockReason.AREA_TRANSITION, owners[1]),
		manager.acquire_lock(GameplayLockManager.LockReason.PAUSE, owners[2]),
	]

	if manager.get_lock_count() != 3:
		failures.append("Three locks from different owners should coexist.")

	manager.release_lock(tokens[1])
	if manager.get_lock_count() != 2:
		failures.append("Removing one of three locks should leave the other two.")

	manager.release_lock(tokens[0])
	manager.release_lock(tokens[2])
	if manager.is_player_input_blocked() or manager.is_pause_active():
		failures.append("All three locks should release cleanly.")


func _test_release_out_of_order(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var owner_a := Node.new()
	var owner_b := Node.new()
	fixture["root"].add_child(owner_a)
	fixture["root"].add_child(owner_b)

	var transition := manager.acquire_lock(GameplayLockManager.LockReason.AREA_TRANSITION, owner_a)
	var dialogue := manager.acquire_lock(GameplayLockManager.LockReason.DIALOGUE, owner_b)

	manager.release_lock(dialogue)
	if not manager.has_lock(GameplayLockManager.LockReason.AREA_TRANSITION):
		failures.append("Out-of-order release should keep transition lock.")

	manager.release_lock(transition)
	if manager.is_player_input_blocked():
		failures.append("Out-of-order release should unblock player when final lock clears.")


func _test_dialogue_during_transition(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var player: Node = fixture["player"]
	var transition_owner := Node.new()
	var dialogue_owner := Node.new()
	fixture["root"].add_child(transition_owner)
	fixture["root"].add_child(dialogue_owner)

	manager.acquire_lock(GameplayLockManager.LockReason.AREA_TRANSITION, transition_owner)
	manager.acquire_lock(GameplayLockManager.LockReason.DIALOGUE, dialogue_owner)
	await TestHelpers.await_physics_frames(self, 1)

	if bool(player.call("can_interact_now")):
		failures.append("Player should stay blocked during dialogue plus transition.")

	manager.release_locks_for_reason(GameplayLockManager.LockReason.DIALOGUE)
	if not manager.has_lock(GameplayLockManager.LockReason.AREA_TRANSITION):
		failures.append("Ending dialogue during transition must keep transition lock.")

	manager.release_locks_for_reason(GameplayLockManager.LockReason.AREA_TRANSITION)


func _test_pause_during_dialogue(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var dialogue_owner := Node.new()
	var pause_owner := Node.new()
	fixture["root"].add_child(dialogue_owner)
	fixture["root"].add_child(pause_owner)

	manager.acquire_lock(GameplayLockManager.LockReason.DIALOGUE, dialogue_owner)
	manager.acquire_lock(GameplayLockManager.LockReason.PAUSE, pause_owner)
	await TestHelpers.await_frames(self, 1)

	if not paused:
		failures.append("Pause lock should pause the scene tree.")
	if not manager.is_player_input_blocked():
		failures.append("Pause lock should still count as blocking player input.")

	manager.release_locks_for_reason(GameplayLockManager.LockReason.PAUSE)
	await TestHelpers.await_frames(self, 1)
	if paused:
		failures.append("Releasing pause should unpause while dialogue remains.")

	manager.release_locks_for_reason(GameplayLockManager.LockReason.DIALOGUE)


func _test_pause_during_hitstop(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var hitstop: Node = fixture["hitstop"]
	var pause_owner := Node.new()
	fixture["root"].add_child(pause_owner)

	manager.request_hitstop(0.07)
	manager.acquire_lock(GameplayLockManager.LockReason.PAUSE, pause_owner)
	await TestHelpers.await_frames(self, 2)

	if not bool(hitstop.get("hitstop_active")):
		failures.append("Hitstop should remain active while pause is active.")
	if not paused:
		failures.append("Pause should remain active while hitstop is active.")

	manager.release_locks_for_reason(GameplayLockManager.LockReason.PAUSE)
	await TestHelpers.await_frames(self, 1)
	if paused:
		failures.append("Releasing pause should not break hitstop tracking.")

	hitstop.call("force_release")


func _test_death_during_hitstop(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var hitstop: Node = fixture["hitstop"]
	var player: Node = fixture["player"]

	manager.request_hitstop(0.07)
	player.call("_on_player_died")
	await TestHelpers.await_physics_frames(self, 2)

	if not manager.has_lock(GameplayLockManager.LockReason.DEATH):
		failures.append("Death during hitstop should acquire a death lock.")
	if not bool(hitstop.get("hitstop_active")):
		failures.append("Hitstop should continue while death lock is active.")

	var health: Node = player.get_node("%HealthComponent")
	health.call("reset_health")
	player.call("clear_input_locks")
	hitstop.call("force_release")


func _test_save_load_session_locks(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var old_owner := Node.new()
	fixture["root"].add_child(old_owner)

	manager.acquire_lock(GameplayLockManager.LockReason.DIALOGUE, old_owner)
	manager.begin_new_session()

	var new_owner := Node.new()
	fixture["root"].add_child(new_owner)
	var loading := manager.acquire_lock(GameplayLockManager.LockReason.LOADING, new_owner)

	if manager.has_lock(GameplayLockManager.LockReason.DIALOGUE):
		failures.append("New session should clear previous-session dialogue lock.")

	manager.release_lock(loading)
	if manager.is_player_input_blocked():
		failures.append("Loading lock from current session should release without stale locks.")


func _test_boss_completion_lock(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var boss_owner := Node.new()
	fixture["root"].add_child(boss_owner)

	var intro := manager.acquire_lock(GameplayLockManager.LockReason.BOSS_INTRO, boss_owner)
	if not manager.is_player_input_blocked():
		failures.append("Boss intro lock should block player control.")
	manager.release_lock(intro)


func _test_demo_completion_lock(failures: PackedStringArray, fixture: Dictionary) -> void:
	var manager: GameplayLockManager = fixture["lock_manager"]
	var demo_owner := Node.new()
	fixture["root"].add_child(demo_owner)

	manager.acquire_lock(GameplayLockManager.LockReason.COMPLETION, demo_owner)
	if not manager.is_player_input_blocked():
		failures.append("Demo completion lock should block player control.")

	manager.debug_force_release_all("test")
	if manager.is_player_input_blocked() or manager.is_pause_active():
		failures.append("Debug release should clear completion lock and pause state.")
