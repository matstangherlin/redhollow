extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const SUITES: Array[Dictionary] = [
	{
		"name": "vertical_slice_verification",
		"path": "res://scripts/demo/vertical_slice_verification.gd",
	},
	{
		"name": "dialogue_tests",
		"path": "res://scripts/dialogue/dialogue_tests.gd",
	},
	{
		"name": "save_tests",
		"path": "res://scripts/save/save_tests.gd",
	},
	{
		"name": "area_transition_tests",
		"path": "res://scripts/world/area_transition_tests.gd",
	},
	{
		"name": "combat_arena_tests",
		"path": "res://scripts/world/combat_arena_tests.gd",
	},
	{
		"name": "cult_brawler_tests",
		"path": "res://scripts/enemies/cult_brawler_tests.gd",
	},
	{
		"name": "deacon_rusk_tests",
		"path": "res://scripts/enemies/deacon_rusk_tests.gd",
	},
	{
		"name": "gameplay_lock_tests",
		"path": "res://scripts/core/gameplay_lock_tests.gd",
	},
	{
		"name": "player_regression_tests",
		"path": "res://scripts/player/player_regression_tests.gd",
	},
	{
		"name": "vertical_slice_regression_tests",
		"path": "res://scripts/demo/vertical_slice_regression_tests.gd",
	},
]


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var started_at_ms := Time.get_ticks_msec()
	var godot_executable := OS.get_executable_path()
	var project_path := _resolve_project_path()

	var suite_results: Array[Dictionary] = []
	var total_tests := SUITES.size()
	var suites_passed := 0
	var suites_failed := 0
	var total_unexpected := 0
	var total_allowed := 0

	print("Red Hollow headless test runner")
	print("Project: %s" % project_path)
	print("Godot: %s" % godot_executable)
	print("Suites: %d" % total_tests)
	print("")

	for suite in SUITES:
		var result := await _run_suite(godot_executable, project_path, suite)
		suite_results.append(result)
		if int(result.get("exit_code", 1)) == 0:
			suites_passed += 1
		else:
			suites_failed += 1
		total_unexpected += int(result.get("unexpected_issues", 0))
		total_allowed += int(result.get("allowed_issues", 0))

	var elapsed_sec := (Time.get_ticks_msec() - started_at_ms) / 1000.0
	var exit_code := 0 if suites_failed == 0 else 1

	print("")
	print("=== Headless Test Runner Summary ===")
	print("Suites: %d" % total_tests)
	print("Suites passed: %d" % suites_passed)
	print("Suites failed: %d" % suites_failed)
	print("Unexpected issues (parsed): %d" % total_unexpected)
	print("Allowed issues (parsed): %d" % total_allowed)
	print("Time: %.2fs" % elapsed_sec)
	print("Exit code: %d" % exit_code)
	print("")

	for result in suite_results:
		var status := "PASS" if int(result.get("exit_code", 1)) == 0 else "FAIL"
		print(
			"[%s] %s (exit=%d, unexpected=%d, allowed=%d)"
			% [
				status,
				String(result.get("name", "")),
				int(result.get("exit_code", 1)),
				int(result.get("unexpected_issues", 0)),
				int(result.get("allowed_issues", 0)),
			]
		)

	quit(exit_code)


func _resolve_project_path() -> String:
	var resource_path := ProjectSettings.globalize_path("res://")
	if resource_path.ends_with("/"):
		return resource_path.substr(0, resource_path.length() - 1)
	return resource_path


func _run_suite(godot_executable: String, project_path: String, suite: Dictionary) -> Dictionary:
	var suite_name := String(suite.get("name", "unknown"))
	var script_path := String(suite.get("path", ""))
	print("--- Running %s ---" % suite_name)

	var output: Array = []
	var exit_code := OS.execute(
		godot_executable,
		["--headless", "--path", project_path, "--script", script_path],
		output,
		true,
		false
	)

	var combined_output := "\n".join(output)
	if not combined_output.is_empty():
		print(combined_output)

	var parsed := _parse_suite_output(combined_output)
	parsed["name"] = suite_name
	parsed["exit_code"] = exit_code
	return parsed


func _parse_suite_output(output: String) -> Dictionary:
	var unexpected_issues := 0
	var allowed_issues := 0
	var test_count := -1
	var assertion_failures := -1

	for line in output.split("\n", false):
		if line.begins_with("Tests: "):
			test_count = int(line.substr(7))
		elif line.begins_with("Assertion failures: "):
			assertion_failures = int(line.substr(20))
		elif line.begins_with("Unexpected issues: "):
			unexpected_issues = int(line.substr(19))
		elif line.begins_with("Allowed issues: "):
			allowed_issues = int(line.substr(16))

	return {
		"test_count": test_count,
		"assertion_failures": assertion_failures,
		"unexpected_issues": unexpected_issues,
		"allowed_issues": allowed_issues,
	}
