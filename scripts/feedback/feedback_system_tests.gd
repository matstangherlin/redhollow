extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const CombatFeedbackResolverScript := preload("res://scripts/feedback/combat_feedback_resolver.gd")
const PlaceholderAudioFactoryScript := preload("res://scripts/audio/placeholder_audio_factory.gd")
const AudioEventIdScript := preload("res://scripts/audio/audio_event_id.gd")
const CombatVfxSpawnerScript := preload("res://scripts/feedback/combat_vfx_spawner.gd")
const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
const SettingsManagerScript := preload("res://scripts/settings/settings_manager.gd")

const CalderStraight := preload("res://resources/combat/calder_straight.tres")
const RedKnuckle := preload("res://resources/combat/red_knuckle.tres")
const RedBrandBreaker := preload("res://resources/combat/red_brand_breaker_lv2.tres")
const FeedbackSystemScene := preload("res://scenes/core/feedback_system.tscn")
const CameraScene := preload("res://scenes/core/camera_controller.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "feedback_system_tests")
	suite.allow_warning_contains("CameraController target was not found")
	var failures: PackedStringArray = PackedStringArray()

	_test_attack_tier_order(failures)
	_test_placeholder_audio_library(failures)
	await _test_audio_volume_settings(failures)
	await _test_camera_shake_zero(failures)
	await _test_reduced_flashes(failures)
	await _test_vfx_pool_performance(failures)

	suite.finish(failures, 6)


func _test_attack_tier_order(failures: PackedStringArray) -> void:
	var straight := CombatFeedbackResolverScript.resolve_hit_feedback(CalderStraight, null, null)
	var knuckle := CombatFeedbackResolverScript.resolve_hit_feedback(RedKnuckle, null, null)
	var breaker := CombatFeedbackResolverScript.resolve_hit_feedback(RedBrandBreaker, null, null)

	var straight_rank := CombatFeedbackResolverScript.tier_rank(straight.get("tier"))
	var knuckle_rank := CombatFeedbackResolverScript.tier_rank(knuckle.get("tier"))
	var breaker_rank := CombatFeedbackResolverScript.tier_rank(breaker.get("tier"))

	if knuckle_rank <= straight_rank:
		failures.append("Red Knuckle should outrank Calder Straight feedback tier.")
	if breaker_rank <= knuckle_rank:
		failures.append("Red Brand Breaker should outrank Red Knuckle feedback tier.")

	if float(knuckle.get("shake_intensity", 0.0)) <= float(straight.get("shake_intensity", 0.0)):
		failures.append("Red Knuckle shake should exceed Calder Straight shake.")
	if float(breaker.get("shake_intensity", 0.0)) <= float(knuckle.get("shake_intensity", 0.0)):
		failures.append("Red Brand Breaker shake should exceed Red Knuckle shake.")


func _test_placeholder_audio_library(failures: PackedStringArray) -> void:
	var library := PlaceholderAudioFactoryScript.build_library()
	for event_id in [
		AudioEventIdScript.FOOTSTEP,
		AudioEventIdScript.PUNCH,
		AudioEventIdScript.IMPACT_FLESH,
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
	await TestHelpers.await_frames(self, 1)

	var settings := _ensure_settings_manager()
	await TestHelpers.await_frames(self, 1)
	if settings == null:
		failures.append("SettingsManager autoload required for volume tests.")
		test_root.queue_free()
		await TestHelpers.await_frames(self, 1)
		return

	var previous: Dictionary = settings.call("get_audio")
	settings.call("set_audio_field", "sfx", 0.25)

	var bus_index := AudioServer.get_bus_index("SFX")
	var volume_db: float = AudioServer.get_bus_volume_db(bus_index)
	if volume_db > -6.0:
		failures.append("SFX bus volume should drop when sfx slider is reduced.")

	settings.call("set_audio_field", "sfx", float(previous.get("sfx", 1.0)))
	test_root.queue_free()
	await TestHelpers.await_frames(self, 1)


func _test_camera_shake_zero(failures: PackedStringArray) -> void:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var camera_rig: Node = CameraScene.instantiate()
	test_root.add_child(camera_rig)
	await TestHelpers.await_frames(self, 1)

	var settings_shake := _ensure_settings_manager()
	await TestHelpers.await_frames(self, 1)
	if settings_shake == null:
		failures.append("SettingsManager autoload required for shake tests.")
		test_root.queue_free()
		await TestHelpers.await_frames(self, 1)
		return

	var previous_shake: float = float(settings_shake.call("get_accessibility").get("screen_shake_intensity", 1.0))
	settings_shake.call("set_accessibility_field", "screen_shake_intensity", 0.0)

	camera_rig.request_shake(12.0, 0.2)
	camera_rig.request_punch_zoom(0.04, 0.12)
	await TestHelpers.await_frames(self, 2)

	if not camera_rig.get("active_shakes").is_empty():
		failures.append("Screen shake intensity 0 should suppress camera shake requests.")
	var camera_node: Camera2D = camera_rig.get_node("%Camera2D")
	if camera_node.zoom.x > 1.001:
		failures.append("Screen shake intensity 0 should suppress punch zoom.")

	settings_shake.call("set_accessibility_field", "screen_shake_intensity", previous_shake)
	test_root.queue_free()
	await TestHelpers.await_frames(self, 1)


func _test_reduced_flashes(failures: PackedStringArray) -> void:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var vfx: Node = CombatVfxSpawnerScript.new()
	test_root.add_child(vfx)
	await TestHelpers.await_frames(self, 1)

	var settings_flash := _ensure_settings_manager()
	await TestHelpers.await_frames(self, 1)
	if settings_flash == null:
		failures.append("SettingsManager autoload required for flash tests.")
		test_root.queue_free()
		await TestHelpers.await_frames(self, 1)
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
	await TestHelpers.await_frames(self, 1)


func _test_vfx_pool_performance(failures: PackedStringArray) -> void:
	var test_root := Node2D.new()
	root.add_child(test_root)

	var vfx: Node = CombatVfxSpawnerScript.new()
	test_root.add_child(vfx)
	await TestHelpers.await_frames(self, 1)

	var started_ms := Time.get_ticks_msec()
	for index in range(40):
		vfx.spawn(&"hit_normal", Vector2(100 + index, 200), 1.0)
	await TestHelpers.await_frames(self, 2)
	var elapsed_ms := Time.get_ticks_msec() - started_ms

	if elapsed_ms > 500:
		failures.append("Spawning 40 hit VFX should stay under 500ms (took %dms)." % elapsed_ms)

	test_root.queue_free()
	await TestHelpers.await_frames(self, 1)


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
