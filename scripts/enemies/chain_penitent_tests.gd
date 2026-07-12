extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const PenitentScene := preload("res://scenes/enemies/chain_penitent.tscn")
const SweepData := preload("res://resources/combat/chain_penitent_sweep.tres")
const HookData := preload("res://resources/combat/chain_penitent_hook.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "chain_penitent_tests")
	var failures: PackedStringArray = PackedStringArray()
	var root_node := Node2D.new()
	root.add_child(root_node)

	_test_attack_telegraphs(failures)
	await _test_spawn_and_defeat(failures, root_node)
	await _test_vulnerable_after_miss(failures, root_node)

	root_node.queue_free()
	suite.finish(failures, 3)


func _test_attack_telegraphs(failures: PackedStringArray) -> void:
	if float(SweepData.get("startup_time")) < 0.6:
		failures.append("Chain sweep should telegraph clearly (>= 0.6s startup).")
	if float(HookData.get("startup_time")) < 0.5:
		failures.append("Chain hook should telegraph clearly.")


func _test_spawn_and_defeat(failures: PackedStringArray, parent: Node2D) -> void:
	var penitent: Node = PenitentScene.instantiate()
	penitent.global_position = Vector2(500, 848)
	parent.add_child(penitent)
	var health: Node = penitent.get_node("Components/HealthComponent")
	var hurtbox: Node = penitent.get_node("Components/HurtboxComponent")

	while float(health.get("current_health")) > 0.0:
		hurtbox.call("receive_hit", SweepData, null, penitent)

	if not bool(health.get("is_dead")):
		failures.append("Chain Penitent should be defeatable.")
	penitent.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_vulnerable_after_miss(failures: PackedStringArray, parent: Node2D) -> void:
	var penitent: ChainPenitent = PenitentScene.instantiate() as ChainPenitent
	parent.add_child(penitent)
	penitent.call("_begin_attack", ChainPenitent.PenitentState.SWEEP, SweepData)
	penitent.call("_advance_attack_phase")
	penitent.call("_advance_attack_phase")
	penitent.state_time_remaining = 0.0
	penitent.call("_advance_timed_state")
	if penitent.current_state != ChainPenitent.PenitentState.VULNERABLE:
		failures.append("Penitent should enter VULNERABLE state after missing sweep.")
	penitent.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)
