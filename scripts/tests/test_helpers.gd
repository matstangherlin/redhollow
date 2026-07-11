extends RefCounted

const RuntimeErrorMonitorScript := preload("res://scripts/tests/runtime_error_monitor.gd")
const StyleManagerScene := preload("res://scenes/core/style_manager.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const DialogueSystemScene := preload("res://scenes/core/dialogue_system.tscn")
const ProgressionScript := preload("res://scripts/progression/progression_component.gd")


static func begin_suite(tree: SceneTree, suite_name: String) -> HeadlessTestSuite:
	return HeadlessTestSuite.new().begin(tree, suite_name)


class HeadlessTestSuite:
	var tree: SceneTree
	var suite_name: String
	var monitor: RuntimeErrorMonitorScript
	var started_at_ms: int = 0

	func begin(p_tree: SceneTree, p_suite_name: String) -> HeadlessTestSuite:
		tree = p_tree
		suite_name = p_suite_name
		monitor = RuntimeErrorMonitorScript.new()
		monitor.install()
		started_at_ms = Time.get_ticks_msec()
		return self

	func allow_warning_contains(fragment: String) -> void:
		monitor.allow_contains(fragment)

	func allow_error_contains(fragment: String) -> void:
		monitor.allow_contains(fragment)

	func finish(failures: PackedStringArray, test_count: int = -1) -> void:
		monitor.uninstall()

		var unexpected: Array = monitor.get_unexpected_issues()
		var exit_code := 0
		var failed_assertions := failures.size()
		var unexpected_count: int = unexpected.size()

		if failed_assertions > 0 or unexpected_count > 0:
			exit_code = 1

		var elapsed_sec := (Time.get_ticks_msec() - started_at_ms) / 1000.0
		var passed_tests := 0
		if test_count >= 0:
			passed_tests = maxi(test_count - failed_assertions, 0)

		print("")
		print("=== %s ===" % suite_name)
		if test_count >= 0:
			print("Tests: %d" % test_count)
			print("Passed assertions: %d" % passed_tests)
		print("Assertion failures: %d" % failed_assertions)
		print("Unexpected issues: %d" % unexpected_count)
		print("Allowed issues: %d" % monitor.allowed_count())
		print("Time: %.2fs" % elapsed_sec)
		print("Exit code: %d" % exit_code)

		if failed_assertions > 0:
			for failure in failures:
				push_error(failure)

		if unexpected_count > 0:
			for issue in unexpected:
				var kind := String(issue.get("kind", "error"))
				var message := String(issue.get("message", ""))
				push_error("[%s] Unexpected %s: %s" % [suite_name, kind, message])

		if exit_code == 0:
			print("%s passed." % suite_name)
		else:
			print("%s failed." % suite_name)

		tree.quit(exit_code)


static func await_frames(tree: SceneTree, frame_count: int = 1) -> void:
	for _i in frame_count:
		await tree.process_frame


static func await_physics_frames(tree: SceneTree, frame_count: int = 1) -> void:
	for _i in frame_count:
		await tree.physics_frame


static func mount_style_manager(parent: Node, tree: SceneTree, frame_count: int = 2) -> Node:
	var style_manager: Node = StyleManagerScene.instantiate()
	parent.add_child(style_manager)
	await await_frames(tree, frame_count)
	return style_manager


static func mount_player(parent: Node, tree: SceneTree, position: Vector2 = Vector2.ZERO) -> Node:
	var player: Node = PlayerScene.instantiate()
	player.global_position = position
	parent.add_child(player)
	await await_frames(tree, 2)
	return player


static func mount_dialogue_system(parent: Node, tree: SceneTree) -> Node:
	var dialogue_root: Node = DialogueSystemScene.instantiate()
	parent.add_child(dialogue_root)
	await await_frames(tree, 2)
	return dialogue_root


static func mount_gameplay_lock_manager(parent: Node, tree: SceneTree) -> GameplayLockManager:
	var lock_manager := GameplayLockManager.new()
	lock_manager.name = "GameplayLockManager"
	parent.add_child(lock_manager)
	await await_frames(tree, 1)
	return lock_manager


static func mount_progression(parent: Node, tree: SceneTree) -> Node:
	var progression: Node = ProgressionScript.new()
	parent.add_child(progression)
	await await_frames(tree, 1)
	return progression

