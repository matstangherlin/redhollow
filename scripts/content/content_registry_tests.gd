extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const ContentRegistryScript := preload("res://scripts/content/content_registry.gd")
const ContentManifestScript := preload("res://scripts/content/content_manifest.gd")

const BETA_MANIFEST_PATH := "res://resources/content/manifests/beta_demo.tres"
const FULL_MANIFEST_PATH := "res://resources/content/manifests/full_game.tres"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "content_registry_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_manifests_load(failures)
	_test_beta_demo_scope(failures)
	_test_full_game_stubs(failures)
	_test_save_compatibility_policy(failures)
	_test_area_gate(failures)
	_test_chapter_zero_metadata(failures)

	ContentRegistryScript.clear_active()
	suite.finish(failures, 18)


func _test_manifests_load(failures: PackedStringArray) -> void:
	var beta = ContentRegistryScript.load_manifest(BETA_MANIFEST_PATH)
	_assert_true(failures, beta != null, "beta_demo manifest loads")
	_assert_eq(failures, String(beta.manifest_id), "beta_demo", "beta_demo id")

	var full = ContentRegistryScript.load_manifest(FULL_MANIFEST_PATH)
	_assert_true(failures, full != null, "full_game manifest loads")
	_assert_eq(failures, String(full.manifest_id), "full_game", "full_game id")
	_assert_false(failures, full.migrate_beta_saves_to_full, "full_game does not auto-migrate beta saves")


func _test_beta_demo_scope(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	_assert_true(failures, registry != null, "beta registry activates")
	_assert_true(
		failures,
		registry.is_chapter_available(&"chapter_zero_bell_before_nightfall"),
		"chapter zero playable in beta"
	)
	_assert_false(failures, registry.is_chapter_available(&"act1_silas_crow"), "act I not playable in beta")
	_assert_true(
		failures,
		registry.can_load_area_scene("res://scenes/areas/vertical_slice_street_art.tscn"),
		"street scene allowed"
	)
	_assert_true(
		failures,
		registry.can_load_area_scene("res://scenes/areas/vertical_slice_underground_art.tscn"),
		"underground scene allowed"
	)

	var end_chapter = registry.get_beta_end_chapter()
	_assert_true(failures, end_chapter != null, "beta end chapter defined")
	_assert_eq(
		failures,
		String(end_chapter.chapter_id),
		"chapter_zero_bell_before_nightfall",
		"beta ends at chapter zero"
	)


func _test_full_game_stubs(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(FULL_MANIFEST_PATH)
	_assert_true(failures, registry != null, "full registry activates")
	_assert_true(
		failures,
		registry.is_chapter_available(&"chapter_zero_bell_before_nightfall"),
		"chapter zero playable in full_game profile"
	)
	_assert_false(
		failures,
		registry.is_chapter_available(&"act2_rosa_la_serpiente"),
		"act II stub not playable"
	)

	var act3 = registry.get_chapter(&"act3_magnus_vane")
	_assert_true(failures, act3 != null, "act III registered as stub")
	_assert_false(failures, act3.is_playable, "act III stub not marked playable")

	var finale = registry.get_chapter(&"finale_mol_khar")
	_assert_true(failures, finale != null, "finale registered")
	_assert_eq(failures, String(finale.title), "Mol-Khar", "finale title")


func _test_save_compatibility_policy(failures: PackedStringArray) -> void:
	var beta = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	var legacy_save := {
		"content_manifest_id": "",
		"current_scene": "res://scenes/areas/vertical_slice_church_art.tscn",
	}
	_assert_true(failures, beta.is_save_compatible_with_manifest(legacy_save), "legacy save works on beta")

	var full = ContentRegistryScript.activate_from_path(FULL_MANIFEST_PATH)
	_assert_true(failures, full.is_save_compatible_with_manifest(legacy_save), "legacy save works on full_game")

	var beta_tagged_save := {
		"content_manifest_id": "beta_demo",
		"current_scene": "res://scenes/areas/vertical_slice_street_art.tscn",
	}
	_assert_false(
		failures,
		full.is_save_compatible_with_manifest(beta_tagged_save),
		"beta-tagged save blocked on full_game without migration"
	)


func _test_area_gate(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	_assert_false(
		failures,
		registry.can_load_area_scene("res://scenes/areas/street_test.tscn"),
		"legacy test area not in manifest"
	)
	_assert_eq(
		failures,
		String(registry.get_chapter_id_for_area(&"vs_greybox_church")),
		"chapter_zero_bell_before_nightfall",
		"area maps to chapter zero"
	)


func _test_chapter_zero_metadata(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	var chapter = registry.get_starting_chapter()
	_assert_true(failures, chapter != null, "starting chapter resolved")
	_assert_eq(failures, String(chapter.completion_flag_id), "cz_chapter_zero_completed", "completion flag")
	_assert_false(failures, chapter.dialogue_data_path.is_empty(), "dialogue path set")
	_assert_eq(failures, chapter.get_playable_areas().size(), 3, "three playable areas")

	var boss = chapter.bosses[0] if chapter.bosses.size() > 0 else null
	_assert_true(failures, boss != null, "boss registered")
	_assert_eq(failures, String(boss.boss_id), "deacon_rusk", "deacon rusk boss id")


func _assert_true(failures: PackedStringArray, condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _assert_false(failures: PackedStringArray, condition: bool, label: String) -> void:
	if condition:
		failures.append(label)


func _assert_eq(failures: PackedStringArray, actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [label, str(expected), str(actual)])
