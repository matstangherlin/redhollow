extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const VisualTestPlayerStub := preload("res://scripts/visual/visual_test_player_stub.gd")

const PilotProfile := preload("res://resources/visual/calder_pilot_profile.tres")
const PlaceholderProfile := preload("res://resources/visual/calder_placeholder_profile.tres")
const CalderStraight := preload("res://resources/combat/calder_straight.tres")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "player_visual_pipeline_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_profile_mappings(failures)
	_test_pilot_sprite_frames(failures)
	await _test_placeholder_mode(failures)
	await _test_pilot_animations(failures)
	_test_attack_timing_independent(failures)

	suite.finish(failures, 5)


func _mount_visual_fixture(profile: PlayerVisualProfile) -> Dictionary:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var player: CharacterBody2D = VisualTestPlayerStub.new()
	player.name = "Player"
	test_root.add_child(player)

	var visual := Node2D.new()
	visual.name = "Visual"
	player.add_child(visual)

	var body_visual := Polygon2D.new()
	body_visual.name = "BodyVisual"
	visual.add_child(body_visual)

	var brand_hand := Polygon2D.new()
	brand_hand.name = "BrandHand"
	visual.add_child(brand_hand)

	var sprite := AnimatedSprite2D.new()
	sprite.name = "SpriteVisual"
	visual.add_child(sprite)

	var controllers := Node.new()
	controllers.name = "Controllers"
	player.add_child(controllers)

	var attack_controller := PlayerAttackController.new()
	attack_controller.name = "PlayerAttackController"
	controllers.add_child(attack_controller)

	var visual_controller := PlayerVisualController.new()
	visual_controller.name = "PlayerVisualController"
	visual_controller.profile = profile
	visual_controller.sprite_visual_path = NodePath("../../Visual/SpriteVisual")
	visual_controller.placeholder_body_path = NodePath("../../Visual/BodyVisual")
	visual_controller.placeholder_brand_path = NodePath("../../Visual/BrandHand")
	controllers.add_child(visual_controller)

	visual_controller.setup(player)
	await TestHelpers.await_frames(self, 1)

	return {
		"root": test_root,
		"player": player,
		"visual_controller": visual_controller,
		"attack_controller": attack_controller,
		"sprite": sprite,
		"body_visual": body_visual,
	}


func _teardown_fixture(fixture: Dictionary) -> void:
	var test_root: Node = fixture.get("root") as Node
	if test_root != null:
		test_root.queue_free()
	await TestHelpers.await_frames(self, 1)


func _test_profile_mappings(failures: PackedStringArray) -> void:
	if not PilotProfile.is_pilot_profile():
		failures.append("Pilot profile should be in PILOT mode.")
	if PilotProfile.get_attack_animation(&"calder_straight") != &"straight":
		failures.append("Pilot profile must map calder_straight -> straight.")
	if not PlaceholderProfile.uses_placeholder():
		failures.append("Default profile should remain PLACEHOLDER.")


func _test_pilot_sprite_frames(failures: PackedStringArray) -> void:
	var frames := PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()
	for anim_name in ["idle", "run", "jump", "straight"]:
		if not frames.has_animation(StringName(anim_name)):
			failures.append("Pilot SpriteFrames missing animation: %s." % anim_name)


func _test_placeholder_mode(failures: PackedStringArray) -> void:
	var fixture := await _mount_visual_fixture(PlaceholderProfile)

	if not (fixture["body_visual"] as CanvasItem).visible:
		failures.append("Placeholder body should remain visible in PLACEHOLDER mode.")
	if (fixture["sprite"] as CanvasItem).visible:
		failures.append("SpriteVisual should stay hidden in PLACEHOLDER mode.")

	await _teardown_fixture(fixture)


func _test_pilot_animations(failures: PackedStringArray) -> void:
	var fixture := await _mount_visual_fixture(PilotProfile)
	var player: CharacterBody2D = fixture["player"] as CharacterBody2D
	var visual_controller: PlayerVisualController = fixture["visual_controller"] as PlayerVisualController
	var attack_controller: PlayerAttackController = fixture["attack_controller"] as PlayerAttackController

	visual_controller.set_profile(PilotProfile)
	await TestHelpers.await_frames(self, 1)

	player.current_state = PlayerStateTypes.PlayerState.IDLE
	visual_controller.refresh_from_player(attack_controller)
	if visual_controller.get_current_animation() != &"idle":
		failures.append("Pilot idle state should request idle animation.")

	player.current_state = PlayerStateTypes.PlayerState.RUN
	visual_controller.refresh_from_player(attack_controller)
	if visual_controller.get_current_animation() != &"run":
		failures.append("Pilot run state should request run animation.")

	player.current_state = PlayerStateTypes.PlayerState.JUMP
	visual_controller.refresh_from_player(attack_controller)
	if visual_controller.get_current_animation() != &"jump":
		failures.append("Pilot jump state should request jump animation.")

	attack_controller.current_attack = CalderStraight
	visual_controller.refresh_from_player(attack_controller)
	if visual_controller.get_current_animation() != &"straight":
		failures.append("calder_straight attack should request straight animation.")

	await _teardown_fixture(fixture)


func _test_attack_timing_independent(failures: PackedStringArray) -> void:
	var frames := PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()
	var anim_duration := 0.0
	for index in range(frames.get_frame_count(&"straight")):
		anim_duration += frames.get_frame_duration(&"straight", index)

	var combat_duration := float(CalderStraight.get("startup_time"))
	combat_duration += float(CalderStraight.get("active_time"))
	combat_duration += float(CalderStraight.get("recovery_time"))

	if is_equal_approx(anim_duration, combat_duration):
		failures.append("Straight animation duration must not mirror AttackData timing exactly.")

	if combat_duration <= 0.0:
		failures.append("Calder straight AttackData must define combat phases.")
