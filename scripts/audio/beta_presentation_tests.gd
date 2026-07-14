extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const PlaceholderAudioFactoryScript := preload("res://scripts/audio/placeholder_audio_factory.gd")
const AudioEventIdScript := preload("res://scripts/audio/audio_event_id.gd")
const MusicSlotIdScript := preload("res://scripts/audio/music_slot_id.gd")
const AudioAssetRegistryScript := preload("res://scripts/audio/audio_asset_registry.gd")
const MusicControllerScript := preload("res://scripts/audio/music_controller.gd")
const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
const CombatVfxSpawnerScript := preload("res://scripts/feedback/combat_vfx_spawner.gd")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "beta_presentation_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_priority_sfx_registered(failures)
	_test_music_slots(failures)
	_test_asset_registry(failures)
	await _test_vfx_kinds(failures)
	await _test_audio_music_preloaded(failures)
	_test_accessibility_helpers(failures)

	suite.finish(failures, 6)


func _test_priority_sfx_registered(failures: PackedStringArray) -> void:
	var library: Dictionary = PlaceholderAudioFactoryScript.build_library()
	for event_id in [
		AudioEventIdScript.FOOTSTEP,
		AudioEventIdScript.PUNCH,
		AudioEventIdScript.KICK,
		AudioEventIdScript.IMPACT_FLESH,
		AudioEventIdScript.IMPACT_STONE,
		AudioEventIdScript.IMPACT_VERMILITE,
		AudioEventIdScript.COUNTER,
		AudioEventIdScript.RED_BRAND_CHARGE,
		AudioEventIdScript.RED_BRAND_BREAKER,
		AudioEventIdScript.GUNSHOT,
		AudioEventIdScript.CHAIN,
		AudioEventIdScript.DOOR,
		AudioEventIdScript.CHECKPOINT,
		AudioEventIdScript.BARRIER_HIT,
		AudioEventIdScript.BARRIER_BREAK,
		AudioEventIdScript.BOSS_HIT,
		AudioEventIdScript.BOSS_STINGER,
		AudioEventIdScript.AMBIENCE_WIND,
		AudioEventIdScript.AMBIENCE_WOOD,
		AudioEventIdScript.AMBIENCE_BELL,
		AudioEventIdScript.AMBIENCE_MINES,
		AudioEventIdScript.AMBIENCE_MOL_KHAR,
		AudioEventIdScript.UI_CONFIRM,
		AudioEventIdScript.UI_NAVIGATE,
	]:
		if not library.has(event_id):
			failures.append("Missing priority SFX event: %s" % String(event_id))
		elif library[event_id] == null:
			failures.append("Null stream for SFX event: %s" % String(event_id))


func _test_music_slots(failures: PackedStringArray) -> void:
	var music_library: Dictionary = PlaceholderAudioFactoryScript.build_music_library()
	for slot_id in MusicSlotIdScript.ALL_SLOTS:
		if not music_library.has(slot_id):
			failures.append("Missing music slot: %s" % String(slot_id))


func _test_asset_registry(failures: PackedStringArray) -> void:
	var entries: Dictionary = AudioAssetRegistryScript.build_entries()
	var required := [
		AudioEventIdScript.FOOTSTEP,
		AudioEventIdScript.DOOR,
		AudioEventIdScript.GUNSHOT,
		AudioEventIdScript.AMBIENCE_MOL_KHAR,
		MusicSlotIdScript.MENU,
		MusicSlotIdScript.DEACON_RUSK,
		MusicSlotIdScript.FINALE,
	]
	for event_id in required:
		if not entries.has(event_id):
			failures.append("AudioAssetRegistry missing %s" % String(event_id))
			continue
		var entry: Dictionary = entries[event_id]
		for field in ["origin", "license", "author", "file", "version"]:
			if String(entry.get(field, "")).is_empty():
				failures.append("Registry entry %s missing %s" % [String(event_id), field])


func _test_vfx_kinds(failures: PackedStringArray) -> void:
	var root := Node2D.new()
	self.root.add_child(root)
	var spawner: Node2D = CombatVfxSpawnerScript.new()
	root.add_child(spawner)
	await TestHelpers.await_frames(get_tree(), 1)
	for kind in [&"gunshot", &"chain", &"vermilite", &"boss", &"mol_khar", &"checkpoint"]:
		spawner.call("spawn", kind, Vector2.ZERO, 0.5)
	await TestHelpers.await_frames(get_tree(), 1)
	var child_count := spawner.get_child_count()
	# Pool (24) + flash CanvasLayer (1) — must not leak extra one-shots per spawn.
	if child_count > 30:
		failures.append("VFX spawner child count grew unexpectedly (%d)." % child_count)
	root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_audio_music_preloaded(failures: PackedStringArray) -> void:
	var root := Node.new()
	self.root.add_child(root)

	var music: Node = MusicControllerScript.new()
	root.add_child(music)
	var audio: Node = AudioManagerScript.new()
	root.add_child(audio)
	await TestHelpers.await_frames(get_tree(), 2)

	if music.call("get_stream", MusicSlotIdScript.STREET) == null:
		failures.append("MusicController should preload street slot at ready.")
	if audio.call("get_stream", AudioEventIdScript.PUNCH) == null:
		failures.append("AudioManager should preload punch at ready (no mid-combat synth).")
	if audio.call("get_stream", AudioEventIdScript.DOOR) == null:
		failures.append("AudioManager should preload door at ready.")

	root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_accessibility_helpers(failures: PackedStringArray) -> void:
	var settings: Node = Engine.get_main_loop().root.get_node_or_null("SettingsManager")
	if settings == null:
		return

	var previous_shake := float(settings.call("get_screen_shake_multiplier"))
	settings.call("set_accessibility_field", "screen_shake_intensity", 0.0)
	if float(settings.call("get_screen_shake_multiplier")) > 0.0:
		failures.append("shake 0% should zero camera multiplier.")
	settings.call("set_accessibility_field", "screen_shake_intensity", previous_shake)

	settings.call("set_accessibility_field", "instant_text", true)
	if not bool(settings.call("is_instant_text_enabled")):
		failures.append("instant_text accessibility should read true.")
	settings.call("set_accessibility_field", "instant_text", false)

	settings.call("set_accessibility_field", "subtitle_size", 1.5)
	if not is_equal_approx(float(settings.call("get_subtitle_scale")), 1.5):
		failures.append("subtitle_size should scale dialogue.")
	settings.call("set_accessibility_field", "subtitle_size", 1.0)
