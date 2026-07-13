extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const CultBrawlerHook := preload("res://resources/combat/cult_brawler_hook.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "cult_brawler_asset_validation_tests")
	suite.allow_warning_contains("Sheet missing")
	suite.allow_warning_contains("procedural placeholder")
	var failures: PackedStringArray = PackedStringArray()

	_test_contract_reference(failures)
	_test_pilot_manifest(failures)
	_test_missing_sheets_do_not_fail_build(failures)
	_test_fixture_sheet_validation(failures)
	_test_gameplay_timing_independent(failures)
	_test_placeholder_fallback_still_works(failures)

	suite.finish(failures, 6)


func _test_contract_reference(failures: PackedStringArray) -> void:
	if CultBrawlerAnimationContract.APPROVED_FRAME_SIZE != Vector2i(34, 56):
		failures.append("Approved frame size must be 34x56 per CULT_BRAWLER_VISUAL_SPEC.")
	if CultBrawlerAnimationContract.GAMEPLAY_COLLISION_SIZE != Vector2i(34, 56):
		failures.append("Gameplay collision must remain 34x56.")
	if CultBrawlerAnimationContract.HEIGHT_RATIO_TO_CALDER_GAMEPLAY != 1.0:
		failures.append("Brawler height ratio to Calder gameplay must be 1.0x.")


func _test_pilot_manifest(failures: PackedStringArray) -> void:
	if CultBrawlerAnimationContract.PILOT_ANIMATION_IDS.size() != 12:
		failures.append("Pilot animation set must contain 12 clips.")
	var required := [
		"idle", "patrol", "alert", "approach",
		"attack_startup", "attack_active", "attack_recovery",
		"hurt", "heavy_hurt", "knocked_back", "stagger", "death",
	]
	for anim_id in required:
		if not CultBrawlerAnimationContract.PILOT_ANIMATION_IDS.has(anim_id):
			failures.append("Pilot manifest missing animation: %s." % anim_id)


func _test_missing_sheets_do_not_fail_build(failures: PackedStringArray) -> void:
	var report: Dictionary = CultBrawlerAssetValidator.validate_pilot_set()
	if not report.has("missing"):
		failures.append("Validation report must include missing list.")
	if not report.has("warnings"):
		failures.append("Validation report must include warnings list.")


func _test_fixture_sheet_validation(failures: PackedStringArray) -> void:
	var fixture_path := _write_idle_fixture_sheet()
	if fixture_path.is_empty():
		failures.append("Failed to create Cult Brawler validation fixture image.")
		return

	var entry: Dictionary = _validate_fixture_at_path(fixture_path)
	if not bool(entry.get("found", false)):
		failures.append("Fixture sheet should be detected.")
	if not bool(entry.get("passed", false)):
		failures.append("Fixture sheet should pass dimensional validation.")


func _test_gameplay_timing_independent(failures: PackedStringArray) -> void:
	var frames := CultBrawlerPlaceholderFactory.create_pilot_sprite_frames()
	var anim_duration := 0.0
	for index in range(frames.get_frame_count(&"attack_startup")):
		anim_duration += frames.get_frame_duration(&"attack_startup", index)

	var combat_duration := float(CultBrawlerHook.get("startup_time"))
	combat_duration += float(CultBrawlerHook.get("active_time"))
	combat_duration += float(CultBrawlerHook.get("recovery_time"))

	if is_equal_approx(anim_duration, combat_duration):
		failures.append("Attack startup animation duration must not mirror AttackData timing exactly.")


func _test_placeholder_fallback_still_works(failures: PackedStringArray) -> void:
	var profile := preload("res://resources/visual/enemies/cult_brawler_pilot_profile.tres")
	var frames := CultBrawlerSpriteFramesBuilder.build_for_profile(profile)
	if frames == null:
		failures.append("Pilot profile must build SpriteFrames without real sheets.")
		return
	for anim_id in CultBrawlerAnimationContract.PILOT_ANIMATION_IDS:
		if not frames.has_animation(StringName(anim_id)):
			failures.append("Fallback SpriteFrames missing animation: %s." % anim_id)


func _write_idle_fixture_sheet() -> String:
	var frame_size := CultBrawlerAnimationContract.APPROVED_FRAME_SIZE
	var spec: Dictionary = CultBrawlerAnimationContract.get_clip_specs().get("idle", {})
	var frame_count: int = int(spec.get("frames", 6))
	var width := frame_size.x * frame_count
	var height := frame_size.y

	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for frame_index in range(frame_count):
		var origin_x := frame_index * frame_size.x
		for y in range(8, frame_size.y - 2):
			for x in range(origin_x + 6, origin_x + frame_size.x - 6):
				image.set_pixel(x, y, Color(0.52, 0.12, 0.14, 1.0))

	var global_dir := ProjectSettings.globalize_path("user://")
	var file_path := "%s/cult_brawler_idle_fixture_sheet.png" % global_dir
	var err := image.save_png(file_path)
	if err != OK:
		return ""

	return "user://cult_brawler_idle_fixture_sheet.png"


func _validate_fixture_at_path(resource_path: String) -> Dictionary:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(resource_path))
	if err != OK:
		return {"found": false, "passed": false}

	var frame_size := CultBrawlerAnimationContract.APPROVED_FRAME_SIZE
	var spec: Dictionary = CultBrawlerAnimationContract.get_clip_specs().get("idle", {})
	var expected_frames: int = int(spec.get("frames", 6))
	var computed_frames := image.get_width() / frame_size.x if frame_size.x > 0 else 0

	return {
		"found": true,
		"passed": (
			image.get_width() % frame_size.x == 0
			and image.get_height() == frame_size.y
			and computed_frames == expected_frames
		),
	}
