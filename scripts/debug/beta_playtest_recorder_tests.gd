extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const RecorderScript := preload("res://scripts/debug/beta_playtest_recorder.gd")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "beta_playtest_recorder_tests")
	var failures: PackedStringArray = PackedStringArray()

	await _test_release_policy(failures)
	await _test_session_file_shape(failures)
	_test_no_network_constants(failures)

	suite.finish(failures, 3)


func _test_release_policy(failures: PackedStringArray) -> void:
	# Recorder always self-disables when not a debug build.
	if not OS.is_debug_build():
		var recorder: Node = RecorderScript.new()
		root.add_child(recorder)
		await TestHelpers.await_frames(get_tree(), 2)
		if is_instance_valid(recorder) and not recorder.is_queued_for_deletion():
			failures.append("Release builds must free BetaPlaytestRecorder.")
		if is_instance_valid(recorder):
			recorder.queue_free()


func _test_session_file_shape(failures: PackedStringArray) -> void:
	if not OS.is_debug_build():
		return

	var recorder: BetaPlaytestRecorder = RecorderScript.new() as BetaPlaytestRecorder
	recorder.enabled = true
	root.add_child(recorder)
	await TestHelpers.await_frames(get_tree(), 2)

	if recorder.get_session_path().is_empty():
		failures.append("Debug recorder must create a session path.")
		recorder.queue_free()
		return

	recorder.record_event("unit_test_ping", {"ok": true})
	var path := recorder.get_session_path()
	var snap: Dictionary = recorder.get_snapshot()
	for key in [
		"duration_sec",
		"deaths",
		"damage_taken",
		"dodge_uses",
		"counter_uses",
		"red_brand_uses",
		"boss_attempts",
		"checkpoints_used",
		"secrets_found",
	]:
		if not snap.has(key):
			failures.append("Snapshot missing metric key: %s" % key)
	if not FileAccess.file_exists(path):
		failures.append("Session JSONL file must exist under user://playtests/.")
		recorder.queue_free()
		return

	if not path.begins_with("user://playtests/"):
		failures.append("Playtest files must stay under user://playtests/.")

	var file := FileAccess.open(path, FileAccess.READ)
	var first_line := file.get_line()
	file.close()
	var parsed: Variant = JSON.parse_string(first_line)
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("First JSONL line must be a dictionary.")
	else:
		var data := parsed as Dictionary
		if String(data.get("type", "")) != "session_start":
			failures.append("First event must be session_start.")
		if not data.has("game_version"):
			failures.append("session_start must include game_version.")
		if data.has("email") or data.has("player_name") or data.has("account"):
			failures.append("Recorder must not store personal identifiers.")

	recorder.queue_free()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _test_no_network_constants(failures: PackedStringArray) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/debug/beta_playtest_recorder.gd")
	for forbidden in ["http://", "https://", "UDPServer", "HTTPRequest", "PacketPeer"]:
		if source.find(forbidden) != -1:
			failures.append("Recorder must not reference network APIs (%s)." % forbidden)
