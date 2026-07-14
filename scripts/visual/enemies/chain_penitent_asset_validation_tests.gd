extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const SweepData := preload("res://resources/combat/chain_penitent_sweep.tres")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "chain_penitent_asset_validation_tests")
	suite.allow_warning_contains("Sheet missing")
	suite.allow_warning_contains("procedural placeholder")
	var failures: PackedStringArray = PackedStringArray()

	_test_contract(failures)
	_test_pilot_manifest(failures)
	_test_missing_sheets(failures)
	_test_placeholder_and_timing(failures)

	suite.finish(failures, 4)


func _test_contract(failures: PackedStringArray) -> void:
	if ChainPenitentAnimationContract.APPROVED_FRAME_SIZE != Vector2i(38, 58):
		failures.append("Approved frame size must be 38x58.")
	if ChainPenitentAnimationContract.GAMEPLAY_COLLISION_SIZE != Vector2i(38, 58):
		failures.append("Gameplay collision must remain 38x58.")
	if ChainPenitentAnimationContract.PIVOT != Vector2(19, 58):
		failures.append("Pivot must be (19, 58).")


func _test_pilot_manifest(failures: PackedStringArray) -> void:
	var required := [
		"idle", "walk", "chain_startup", "chain_active", "chain_recovery",
		"pull", "hurt", "stagger", "death",
	]
	for anim_id in required:
		if not ChainPenitentAnimationContract.PILOT_ANIMATION_IDS.has(anim_id):
			failures.append("Pilot manifest missing animation: %s." % anim_id)


func _test_missing_sheets(failures: PackedStringArray) -> void:
	var report: Dictionary = ChainPenitentAssetValidator.validate_pilot_set()
	if not report.has("missing"):
		failures.append("Validation report must include missing list.")
	if int(report.get("missing", []).size()) < 1:
		failures.append("Expected missing production sheets until art is delivered.")


func _test_placeholder_and_timing(failures: PackedStringArray) -> void:
	var frames := ChainPenitentPlaceholderFactory.create_pilot_sprite_frames()
	for anim_id in ChainPenitentAnimationContract.PILOT_ANIMATION_IDS:
		if not frames.has_animation(StringName(anim_id)):
			failures.append("Placeholder missing clip: %s." % anim_id)
	var startup_duration := 0.0
	for i in range(frames.get_frame_count(&"chain_startup")):
		startup_duration += frames.get_frame_duration(&"chain_startup", i)
	var combat := float(SweepData.get("startup_time"))
	if is_equal_approx(startup_duration, combat):
		failures.append("Chain startup animation duration must not mirror AttackData startup exactly.")
