extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const ShotData := preload("res://resources/combat/gunslinger_shot.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "vermilite_gunslinger_asset_validation_tests")
	suite.allow_warning_contains("Sheet missing")
	suite.allow_warning_contains("procedural placeholder")
	var failures: PackedStringArray = PackedStringArray()

	_test_contract(failures)
	_test_pilot_manifest(failures)
	_test_missing_sheets(failures)
	_test_placeholder_and_timing(failures)

	suite.finish(failures, 4)


func _test_contract(failures: PackedStringArray) -> void:
	if VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE != Vector2i(32, 54):
		failures.append("Approved frame size must be 32x54.")
	if VermiliteGunslingerAnimationContract.GAMEPLAY_COLLISION_SIZE != Vector2i(32, 54):
		failures.append("Gameplay collision must remain 32x54.")
	if VermiliteGunslingerAnimationContract.PIVOT != Vector2(16, 54):
		failures.append("Pivot must be (16, 54).")


func _test_pilot_manifest(failures: PackedStringArray) -> void:
	var required := ["idle", "aim", "fire", "recoil", "reload", "reposition", "hurt", "death"]
	for anim_id in required:
		if not VermiliteGunslingerAnimationContract.PILOT_ANIMATION_IDS.has(anim_id):
			failures.append("Pilot manifest missing animation: %s." % anim_id)


func _test_missing_sheets(failures: PackedStringArray) -> void:
	var report: Dictionary = VermiliteGunslingerAssetValidator.validate_pilot_set()
	if not report.has("missing"):
		failures.append("Validation report must include missing list.")
	if int(report.get("missing", []).size()) < 1:
		failures.append("Expected missing production sheets until art is delivered.")


func _test_placeholder_and_timing(failures: PackedStringArray) -> void:
	var frames := VermiliteGunslingerPlaceholderFactory.create_pilot_sprite_frames()
	for anim_id in VermiliteGunslingerAnimationContract.PILOT_ANIMATION_IDS:
		if not frames.has_animation(StringName(anim_id)):
			failures.append("Placeholder missing clip: %s." % anim_id)
	var aim_duration := 0.0
	for i in range(frames.get_frame_count(&"aim")):
		aim_duration += frames.get_frame_duration(&"aim", i)
	var combat := float(ShotData.get("startup_time"))
	if is_equal_approx(aim_duration, combat):
		failures.append("Aim animation duration must not mirror AttackData startup exactly.")
