extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const BOOTSTRAP_SCENE := "res://scenes/tests/test_bootstrap.tscn"
const DEFAULT_SUITE_TIMEOUT_SEC := 180.0
const TIMEOUT_EXIT_CODE := 124

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
		"timeout_sec": 300.0,
	},
	{
		"name": "vertical_slice_regression_tests",
		"path": "res://scripts/demo/vertical_slice_regression_tests.gd",
	},
	{
		"name": "product_shell_tests",
		"path": "res://scripts/product/product_shell_tests.gd",
	},
	{
		"name": "narrative_chapter_zero_tests",
		"path": "res://scripts/narrative/narrative_chapter_zero_tests.gd",
	},
	{
		"name": "vermilite_gunslinger_tests",
		"path": "res://scripts/enemies/vermilite_gunslinger_tests.gd",
	},
	{
		"name": "chain_penitent_tests",
		"path": "res://scripts/enemies/chain_penitent_tests.gd",
	},
	{
		"name": "enemy_encounter_tests",
		"path": "res://scripts/demo/enemy_encounter_tests.gd",
	},
	{
		"name": "player_visual_pipeline_tests",
		"path": "res://scripts/visual/player_visual_pipeline_tests.gd",
	},
	{
		"name": "feedback_system_tests",
		"path": "res://scripts/feedback/feedback_system_tests.gd",
	},
	{
		"name": "player_respawn_tests",
		"path": "res://scripts/player/player_respawn_tests.gd",
	},
	{
		"name": "content_registry_tests",
		"path": "res://scripts/content/content_registry_tests.gd",
	},
	{
		"name": "beta_integration_smoke_tests",
		"path": "res://scripts/demo/beta_integration_smoke_tests.gd",
	},
	{
		"name": "street_art_toggle_tests",
		"path": "res://scripts/visual/street_art_toggle_tests.gd",
	},
	{
		"name": "modular_kit_tests",
		"path": "res://scripts/environment/modular_kit_tests.gd",
	},
	{
		"name": "world_map_graph_tests",
		"path": "res://scripts/world/world_map_graph_tests.gd",
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
	print("Bootstrap: %s" % BOOTSTRAP_SCENE)
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
		var timeout_note := " TIMEOUT" if bool(result.get("timed_out", false)) else ""
		print(
			"[%s] %s (exit=%d, unexpected=%d, allowed=%d)%s"
			% [
				status,
				String(result.get("name", "")),
				int(result.get("exit_code", 1)),
				int(result.get("unexpected_issues", 0)),
				int(result.get("allowed_issues", 0)),
				timeout_note,
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
	var timeout_sec := float(suite.get("timeout_sec", DEFAULT_SUITE_TIMEOUT_SEC))
	print("--- Running %s ---" % suite_name)

	var args: PackedStringArray = PackedStringArray([
		"--headless",
		"--path",
		project_path,
		"--main-scene",
		BOOTSTRAP_SCENE,
		"--",
		script_path,
	])

	var output: Array = []
	var exec_result := await _execute_with_timeout(godot_executable, args, output, timeout_sec)
	var exit_code := int(exec_result.get("exit_code", -1))
	var timed_out := bool(exec_result.get("timed_out", false))

	var combined_output := "\n".join(output)
	if not combined_output.is_empty():
		print(combined_output)

	if timed_out:
		push_error("Suite %s exceeded timeout (%.0fs)." % [suite_name, timeout_sec])

	var parsed := _parse_suite_output(combined_output)
	parsed["name"] = suite_name
	parsed["exit_code"] = exit_code
	parsed["timed_out"] = timed_out
	return parsed


func _execute_with_timeout(
	godot_executable: String,
	args: PackedStringArray,
	output: Array,
	timeout_sec: float
) -> Dictionary:
	var worker := {
		"done": false,
		"exit_code": 1,
		"output": [] as Array,
	}
	var thread := Thread.new()
	var err := thread.start(_execute_worker.bind(worker, godot_executable, args))
	if err != OK:
		push_error("Failed to start suite worker thread (error %d)." % err)
		return {"exit_code": -1, "timed_out": false}

	var deadline_ms := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not bool(worker.get("done", false)):
		if Time.get_ticks_msec() >= deadline_ms:
			thread.wait_to_finish()
			return {"exit_code": TIMEOUT_EXIT_CODE, "timed_out": true}
		await self.process_frame

	thread.wait_to_finish()
	for line in worker.get("output", []):
		output.append(line)
	return {"exit_code": int(worker.get("exit_code", 1)), "timed_out": false}


func _execute_worker(worker: Dictionary, godot_executable: String, args: PackedStringArray) -> void:
	worker["exit_code"] = OS.execute(godot_executable, args, worker["output"], true, false)
	worker["done"] = true


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
