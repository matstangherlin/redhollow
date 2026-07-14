extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "deacon_rusk_asset_validation_tests")
	suite.allow_warning_contains("Sheet missing")
	suite.allow_warning_contains("procedural")
	var failures: PackedStringArray = PackedStringArray()

	if DeaconRuskAnimationContract.APPROVED_FRAME_SIZE != Vector2i(42, 72):
		failures.append("Frame size must be 42x72.")
	var required := [
		"idle", "reposition", "punch_combo", "charge", "counterable_attack",
		"ground_attack", "armor_attack", "hurt", "stagger", "phase_transition", "death",
	]
	for anim_id in required:
		if not DeaconRuskAnimationContract.PILOT_ANIMATION_IDS.has(anim_id):
			failures.append("Missing clip: %s." % anim_id)
	var report: Dictionary = DeaconRuskAssetValidator.validate_pilot_set()
	if int(report.get("missing", []).size()) < 1:
		failures.append("Expected missing production sheets until art arrives.")
	var frames := DeaconRuskPlaceholderFactory.create_pilot_sprite_frames()
	for anim_id in DeaconRuskAnimationContract.PILOT_ANIMATION_IDS:
		if not frames.has_animation(StringName(anim_id)):
			failures.append("Placeholder missing: %s." % anim_id)

	suite.finish(failures, 4)
