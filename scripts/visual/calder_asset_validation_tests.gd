extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "calder_asset_validation_tests")
	suite.allow_warning_contains("Sheet missing")
	suite.allow_warning_contains("procedural placeholder")
	suite.allow_warning_contains("Import sidecar missing")
	var failures: PackedStringArray = PackedStringArray()

	_test_approved_scale_reference(failures)
	_test_pilot_manifest(failures)
	_test_missing_sheets_do_not_fail_build(failures)
	_test_fixture_sheet_validation(failures)
	_test_gameplay_timing_independent(failures)
	_test_placeholder_fallback_still_works(failures)

	suite.finish(failures, 6)


func _test_approved_scale_reference(failures: PackedStringArray) -> void:
	if CalderAnimationContract.APPROVED_FRAME_SIZE != Vector2i(40, 72):
		failures.append("Approved frame size must be 40x72 per VISUAL_SCALE_STUDY.md.")
	if CalderAnimationContract.APPROVED_FRAME_SIZE_DOC != "docs/VISUAL_SCALE_STUDY.md":
		failures.append("Approved frame size doc pointer must reference VISUAL_SCALE_STUDY.md.")
	if CalderAnimationContract.GAMEPLAY_COLLISION_SIZE != Vector2i(32, 56):
		failures.append("Gameplay collision must remain 32x56.")
	if CalderAnimationContract.PLACEHOLDER_FRAME_SIZE != Vector2i(32, 56):
		failures.append("Placeholder frame size must remain 32x56 until procedural re-export.")


func _test_pilot_manifest(failures: PackedStringArray) -> void:
	if CalderAnimationContract.PILOT_ANIMATION_IDS.size() != 11:
		failures.append("Pilot animation set must contain 11 clips (includes jump_start).")
	var required := [
		"idle", "run", "jump_start", "jump_rise", "fall", "land",
		"straight", "body_hook", "red_knuckle", "dodge", "hurt",
	]
	for anim_id in required:
		if not CalderAnimationContract.PILOT_ANIMATION_IDS.has(anim_id):
			failures.append("Pilot manifest missing animation: %s." % anim_id)
		var spec: Dictionary = CalderAnimationContract.get_clip_specs().get(anim_id, {})
		if spec.is_empty():
			failures.append("Pilot clip spec missing for %s." % anim_id)
		var expected_path := CalderAnimationContract.get_sheet_path(StringName(anim_id))
		if not expected_path.begins_with(CalderAnimationContract.SHEET_BASE_PATH):
			failures.append("Sheet path for %s must live under sheets/." % anim_id)


func _test_missing_sheets_do_not_fail_build(failures: PackedStringArray) -> void:
	var report: Dictionary = CalderAssetValidator.validate_pilot_set()
	if not report.has("missing"):
		failures.append("Validation report must include missing list.")
	if not report.has("warnings"):
		failures.append("Validation report must include warnings list.")
	if report.get("found", []).size() > 0 and report.get("failed", []).size() > 0:
		failures.append("Failed sheets should not be silently ignored in report.")


func _test_fixture_sheet_validation(failures: PackedStringArray) -> void:
	var fixture_path := _write_idle_fixture_sheet()
	if fixture_path.is_empty():
		failures.append("Failed to create Calder validation fixture image.")
		return

	var entry: Dictionary = _validate_fixture_at_path(fixture_path)
	if not bool(entry.get("found", false)):
		failures.append("Fixture sheet should be detected.")
	if not bool(entry.get("passed", false)):
		failures.append("Fixture sheet should pass dimensional validation.")
	var checks: Dictionary = entry.get("checks", {})
	if not bool(checks.get("width_divisible", false)):
		failures.append("Fixture width divisibility check failed.")
	if not bool(checks.get("height_exact", false)):
		failures.append("Fixture height check failed.")
	if not bool(checks.get("frame_count", false)):
		failures.append("Fixture frame count check failed.")


func _test_gameplay_timing_independent(failures: PackedStringArray) -> void:
	var frames := PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()
	var anim_duration := 0.0
	for index in range(frames.get_frame_count(&"straight")):
		anim_duration += frames.get_frame_duration(&"straight", index)

	var combat_duration := float(CalderStraight.get("startup_time"))
	combat_duration += float(CalderStraight.get("active_time"))
	combat_duration += float(CalderStraight.get("recovery_time"))

	if is_equal_approx(anim_duration, combat_duration):
		failures.append("Straight animation duration must not mirror AttackData timing exactly.")


func _test_placeholder_fallback_still_works(failures: PackedStringArray) -> void:
	var profile := preload("res://resources/visual/calder_pilot_profile.tres")
	var frames := CalderSpriteFramesBuilder.build_for_profile(profile)
	if frames == null:
		failures.append("Pilot profile must still build SpriteFrames without real sheets.")
		return
	for anim_id in CalderAnimationContract.PILOT_ANIMATION_IDS:
		if not frames.has_animation(StringName(anim_id)):
			failures.append("Fallback SpriteFrames missing animation: %s." % anim_id)


func _write_idle_fixture_sheet() -> String:
	var frame_size := CalderAnimationContract.APPROVED_FRAME_SIZE
	var spec: Dictionary = CalderAnimationContract.get_clip_specs().get("idle", {})
	var frame_count: int = int(spec.get("frames", 6))
	var width := frame_size.x * frame_count
	var height := frame_size.y

	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for frame_index in range(frame_count):
		var origin_x := frame_index * frame_size.x
		for y in range(8, frame_size.y - 2):
			for x in range(origin_x + 8, origin_x + frame_size.x - 8):
				image.set_pixel(x, y, Color(0.78, 0.2, 0.14, 1.0))

	var global_dir := ProjectSettings.globalize_path("user://")
	var file_path := "%s/calder_idle_fixture_sheet.png" % global_dir
	var err := image.save_png(file_path)
	if err != OK:
		return ""

	return "user://calder_idle_fixture_sheet.png"


func _validate_fixture_at_path(resource_path: String) -> Dictionary:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(resource_path))
	if err != OK:
		return {"found": false, "passed": false}

	var frame_size := CalderAnimationContract.APPROVED_FRAME_SIZE
	var spec: Dictionary = CalderAnimationContract.get_clip_specs().get("idle", {})
	var expected_frames: int = int(spec.get("frames", 6))
	var computed_frames := image.get_width() / frame_size.x if frame_size.x > 0 else 0

	return {
		"found": true,
		"passed": (
			image.get_width() % frame_size.x == 0
			and image.get_height() == frame_size.y
			and computed_frames == expected_frames
		),
		"checks": {
			"width_divisible": image.get_width() % frame_size.x == 0,
			"height_exact": image.get_height() == frame_size.y,
			"frame_count": computed_frames == expected_frames,
		},
	}
