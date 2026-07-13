extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const CombatFeedbackResolverScript := preload("res://scripts/feedback/combat_feedback_resolver.gd")
const CombatFeedbackProfileLibraryScript := preload("res://scripts/feedback/combat_feedback_profile_library.gd")
const PlaceholderAudioFactoryScript := preload("res://scripts/audio/placeholder_audio_factory.gd")
const AudioEventIdScript := preload("res://scripts/audio/audio_event_id.gd")
const CombatVfxSpawnerScript := preload("res://scripts/feedback/combat_vfx_spawner.gd")
const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
const SettingsManagerScript := preload("res://scripts/settings/settings_manager.gd")

const CalderStraight := preload("res://resources/combat/calder_straight.tres")
const BodyHook := preload("res://resources/combat/body_hook.tres")
const RedKnuckle := preload("res://resources/combat/red_knuckle.tres")
const CalderCounter := preload("res://resources/combat/calder_counter.tres")
const RedBrandBreakerLv1 := preload("res://resources/combat/red_brand_breaker_lv1.tres")
const RedBrandBreakerLv2 := preload("res://resources/combat/red_brand_breaker_lv2.tres")
const CameraScene := preload("res://scenes/core/camera_controller.tscn")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "feedback_system_tests")
	suite.allow_warning_contains("CameraController target was not found")
	var failures: PackedStringArray = PackedStringArray()

	_test_profiles_registered(failures)
	_test_attack_tier_order(failures)
	_test_body_hook_medium_tier(failures)
	_test_attack_data_unchanged(failures)
	_test_profile_hitstop_mirrors_attack_data(failures)
	_test_placeholder_audio_library(failures)
	await _test_audio_volume_settings(failures)
	await _test_camera_shake_zero(failures)
	await _test_reduced_flashes(failures)
	await _test_reduced_particles(failures)
	await _test_vfx_pool_performance(failures)

	suite.finish(failures, 10)


func _test_profiles_registered(failures: PackedStringArray) -> void:
	var required := [
		"calder_straight",
		"body_hook",
		"red_knuckle",
		"calder_counter",
		"red_brand_breaker_lv1",
		"red_brand_breaker_lv2",
	]
	for attack_id in required:
		var profile: CombatFeedbackProfile = CombatFeedbackProfileLibraryScript.get_profile(StringName(attack_id))
		if profile == null:
			failures.append("Missing feedback profile for %s." % attack_id)


func _test_attack_tier_order(failures: PackedStringArray) -> void:
	var straight := CombatFeedbackResolverScript.resolve_hit_feedback(CalderStraight, null, null)
	var hook := CombatFeedbackResolverScript.resolve_hit_feedback(BodyHook, null, null)
	var knuckle := CombatFeedbackResolverScript.resolve_hit_feedback(RedKnuckle, null, null)
	var counter := CombatFeedbackResolverScript.resolve_hit_feedback(CalderCounter, null, null)
	var breaker := CombatFeedbackResolverScript.resolve_hit_feedback(RedBrandBreakerLv2, null, null)

	var straight_rank := CombatFeedbackResolverScript.tier_rank(straight.get("tier"))
	var hook_rank := CombatFeedbackResolverScript.tier_rank(hook.get("tier"))
	var knuckle_rank := CombatFeedbackResolverScript.tier_rank(knuckle.get("tier"))
	var breaker_rank := CombatFeedbackResolverScript.tier_rank(breaker.get("tier"))

	if hook_rank <= straight_rank:
		failures.append("Body Hook should outrank Calder Straight feedback tier.")
	if knuckle_rank <= hook_rank:
		failures.append("Red Knuckle should outrank Body Hook feedback tier.")
	if breaker_rank <= knuckle_rank:
		failures.append("Red Brand Breaker should outrank Red Knuckle feedback tier.")

	if float(knuckle.get("shake_intensity", 0.0)) <= float(straight.get("shake_intensity", 0.0)):
		failures.append("Red Knuckle shake should exceed Calder Straight shake.")
	if float(breaker.get("shake_intensity", 0.0)) <= float(knuckle.get("shake_intensity", 0.0)):
		failures.append("Red Brand Breaker shake should exceed Red Knuckle shake.")

	if int(counter.get("tier")) != CombatFeedbackResolverScript.ImpactTier.COUNTER:
		failures.append("Calder Counter should resolve to COUNTER tier.")


func _test_body_hook_medium_tier(failures: PackedStringArray) -> void:
	var hook := CombatFeedbackResolverScript.resolve_hit_feedback(BodyHook, null, null)
	if int(hook.get("tier")) != CombatFeedbackResolverScript.ImpactTier.MEDIUM:
		failures.append("Body Hook should use MEDIUM impact tier profile.")
	if float(hook.get("lateral_impact_bias", 0.0)) <= 0.0:
		failures.append("Body Hook profile should include lateral impact bias.")


func _test_attack_data_unchanged(failures: PackedStringArray) -> void:
	_assert_attack_data(failures, CalderStraight, {
		"damage": 3.0,
		"startup_time": 0.08,
		"active_time": 0.08,
		"recovery_time": 0.18,
		"hitbox_size": Vector2(44, 28),
	})
	_assert_attack_data(failures, BodyHook, {
		"damage": 5.0,
		"startup_time": 0.11,
		"active_time": 0.09,
		"recovery_time": 0.22,
		"hitbox_size": Vector2(50, 32),
	})
	_assert_attack_data(failures, RedKnuckle, {
		"damage": 8.0,
		"startup_time": 0.16,
		"active_time": 0.10,
		"recovery_time": 0.30,
	})
	_assert_attack_data(failures, CalderCounter, {
		"damage": 10.0,
		"startup_time": 0.05,
		"active_time": 0.1,
		"recovery_time": 0.2,
	})
	_assert_attack_data(failures, RedBrandBreakerLv1, {
		"damage": 12.0,
		"startup_time": 0.10,
		"active_time": 0.12,
		"recovery_time": 0.28,
	})


func _assert_attack_data(failures: PackedStringArray, attack_data: Resource, expected: Dictionary) -> void:
	for key in expected.keys():
		var actual: Variant = attack_data.get(key)
		var wanted: Variant = expected[key]
		if actual is float and wanted is float:
			if not is_equal_approx(float(actual), float(wanted)):
				failures.append("AttackData %s field %s changed (%.4f != %.4f)." % [
					attack_data.get("attack_id"), key, float(actual), float(wanted)
				])
		elif actual != wanted:
			failures.append("AttackData %s field %s changed." % [attack_data.get("attack_id"), key])


func _test_profile_hitstop_mirrors_attack_data(failures: PackedStringArray) -> void:
	var pairs := [
		[CalderStraight, &"calder_straight"],
		[BodyHook, &"body_hook"],
		[RedKnuckle, &"red_knuckle"],
		[CalderCounter, &"calder_counter"],
		[RedBrandBreakerLv1, &"red_brand_breaker_lv1"],
	]
	for pair in pairs:
		var attack_data: Resource = pair[0]
		var profile: CombatFeedbackProfile = CombatFeedbackProfileLibraryScript.get_profile(pair[1])
		if profile == null:
			continue
		if not is_equal_approx(profile.attacker_hitstop, float(attack_data.get("attacker_hitstop"))):
			failures.append("Profile attacker_hitstop should mirror AttackData for %s." % pair[1])
		if not is_equal_approx(profile.target_hitstop, float(attack_data.get("target_hitstop"))):
			failures.append("Profile target_hitstop should mirror AttackData for %s." % pair[1])


func _test_placeholder_audio_library(failures: PackedStringArray) -> void:
	var library := PlaceholderAudioFactoryScript.build_library()
	for event_id in [
		AudioEventIdScript.FOOTSTEP,
		AudioEventIdScript.PUNCH,
		AudioEventIdScript.KICK,
		AudioEventIdScript.IMPACT_FLESH,
		AudioEventIdScript.IMPACT_VERMILITE,
		AudioEventIdScript.DODGE,
		AudioEventIdScript.COUNTER,
		AudioEventIdScript.RED_BRAND_BREAKER,
		AudioEventIdScript.CHECKPOINT,
		AudioEventIdScript.UI_CONFIRM,
		AudioEventIdScript.AMBIENCE_WIND,
	]:
		if not library.has(event_id):
			failures.append("Placeholder audio library missing event: %s." % String(event_id))


func _test_audio_volume_settings(failures: PackedStringArray) -> void:
	var test_root := Node.new()
	root.add_child(test_root)

	var audio: Node = AudioManagerScript.new()
	test_root.add_child(audio)
	await TestHelpers.await_frames(get_tree(), 1)

	var settings := _ensure_settings_manager()
	await TestHelpers.await_frames(get_tree(), 1)
	if settings == null:
		failures.append("SettingsManager autoload required for volume tests.")
		test_root.queue_free()
		await TestHelpers.await_frames(get_tree(), 1)
		return

	var previous: Dictionary = settings.call("get_audio")
	settings.call("set_audio_field", "sfx", 0.25)

	var bus_index := AudioServer.get_bus_index("SFX")
	var volume_db: float = AudioServer.get_bus_volume_db(bus_index)
	if volume_db > -6.0:
		failures.append("SFX bus volume should drop when sfx slider is reduced.")

	settings.call("set_audio_field", "sfx", float(previous.get("sfx", 1.0)))
	test_root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_camera_shake_zero(failures: PackedStringArray) -> void:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var camera_rig: Node = CameraScene.instantiate()
	test_root.add_child(camera_rig)
	await TestHelpers.await_frames(get_tree(), 1)

	var settings_shake := _ensure_settings_manager()
	await TestHelpers.await_frames(get_tree(), 1)
	if settings_shake == null:
		failures.append("SettingsManager autoload required for shake tests.")
		test_root.queue_free()
		await TestHelpers.await_frames(get_tree(), 1)
		return

	var previous_shake: float = float(settings_shake.call("get_accessibility").get("screen_shake_intensity", 1.0))
	settings_shake.call("set_accessibility_field", "screen_shake_intensity", 0.0)

	camera_rig.request_shake(12.0, 0.2)
	camera_rig.request_punch_zoom(0.04, 0.12)
	await TestHelpers.await_frames(get_tree(), 2)

	if not camera_rig.get("active_shakes").is_empty():
		failures.append("Screen shake intensity 0 should suppress camera shake requests.")
	var camera_node: Camera2D = camera_rig.get_node("%Camera2D")
	if camera_node.zoom.x > 1.001:
		failures.append("Screen shake intensity 0 should suppress punch zoom.")

	settings_shake.call("set_accessibility_field", "screen_shake_intensity", previous_shake)
	test_root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_reduced_flashes(failures: PackedStringArray) -> void:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var vfx: Node = CombatVfxSpawnerScript.new()
	test_root.add_child(vfx)
	await TestHelpers.await_frames(get_tree(), 1)

	var settings_flash := _ensure_settings_manager()
	await TestHelpers.await_frames(get_tree(), 1)
	if settings_flash == null:
		failures.append("SettingsManager autoload required for flash tests.")
		test_root.queue_free()
		await TestHelpers.await_frames(get_tree(), 1)
		return

	var previous: bool = bool(settings_flash.call("get_accessibility").get("reduced_flashes", false))
	settings_flash.call("set_accessibility_field", "reduced_flashes", true)
	var reduced: float = vfx.call("get_scaled_strength", 1.0)
	settings_flash.call("set_accessibility_field", "reduced_flashes", false)
	var full: float = vfx.call("get_scaled_strength", 1.0)

	if reduced >= full:
		failures.append("Reduced flashes should lower VFX strength multiplier.")

	settings_flash.call("set_accessibility_field", "reduced_flashes", previous)
	test_root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_reduced_particles(failures: PackedStringArray) -> void:
	var settings := _ensure_settings_manager()
	await TestHelpers.await_frames(get_tree(), 1)
	if settings == null:
		failures.append("SettingsManager autoload required for particle tests.")
		return

	var previous: bool = bool(settings.call("get_accessibility").get("reduced_particles", false))
	settings.call("set_accessibility_field", "reduced_particles", true)
	var reduced: float = FeedbackSettingsAccess.get_particle_multiplier()
	settings.call("set_accessibility_field", "reduced_particles", false)
	var full: float = FeedbackSettingsAccess.get_particle_multiplier()

	if reduced >= full:
		failures.append("Reduced particles setting should lower particle multiplier.")
	if reduced > 0.5:
		failures.append("Reduced particles multiplier should be <= 0.5.")

	settings.call("set_accessibility_field", "reduced_particles", previous)


func _test_vfx_pool_performance(failures: PackedStringArray) -> void:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var vfx: Node = CombatVfxSpawnerScript.new()
	test_root.add_child(vfx)
	await TestHelpers.await_frames(get_tree(), 1)

	var started_ms := Time.get_ticks_msec()
	for index in range(40):
		vfx.spawn(&"hit_normal", Vector2(100 + index, 200), 1.0)
	await TestHelpers.await_frames(get_tree(), 2)
	var elapsed_ms := Time.get_ticks_msec() - started_ms

	if elapsed_ms > 500:
		failures.append("Spawning 40 hit VFX should stay under 500ms (took %dms)." % elapsed_ms)

	test_root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _get_settings_manager() -> Node:
	return root.get_node_or_null("SettingsManager")


func _ensure_settings_manager() -> Node:
	var existing := _get_settings_manager()
	if existing != null:
		return existing
	var settings: Node = SettingsManagerScript.new()
	settings.name = "SettingsManager"
	root.add_child(settings)
	return settings
