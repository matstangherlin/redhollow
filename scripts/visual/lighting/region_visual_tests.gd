extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const ThemeFactory := preload("res://scripts/visual/lighting/chapter_zero_street_theme_factory.gd")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "region_visual_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_palette_groups(failures)
	_test_theme_factory(failures)
	_test_presentation_controller(failures)
	_test_state_transitions(failures)
	_test_accessibility_scaling(failures)
	_test_comparison_scene_exists(failures)

	suite.finish(failures, 6)


func _test_palette_groups(failures: PackedStringArray) -> void:
	var summary := RedHollowPalette.get_group_summary()
	if not summary.has("western_base"):
		failures.append("RedHollowPalette must define western_base group.")
	if not summary.has("vermilite"):
		failures.append("RedHollowPalette must define vermilite group.")
	if not summary.has("mol_khar"):
		failures.append("RedHollowPalette must define mol_khar group.")

	var wood := RedHollowPalette.get_color("western_base", "wood_dark")
	if wood == Color.MAGENTA:
		failures.append("western_base.wood_dark must resolve to a palette color.")


func _test_theme_factory(failures: PackedStringArray) -> void:
	var theme := ThemeFactory.build()
	if theme == null:
		failures.append("ChapterZeroStreetThemeFactory must build a RegionVisualTheme.")
		return
	if theme.region_id != &"vs_greybox_street":
		failures.append("North Star theme region_id must match street area.")
	for state in [
		CorruptionVisualState.State.NORMAL,
		CorruptionVisualState.State.VERMILITE_NEAR,
		CorruptionVisualState.State.RED_RESONANCE,
		CorruptionVisualState.State.MOL_KHAR_APPEARANCE,
	]:
		var profile := theme.get_lighting_profile(state)
		if profile == null:
			failures.append(
				"Theme missing lighting profile for state %s." % CorruptionVisualState.state_to_string(state)
			)


func _test_presentation_controller(failures: PackedStringArray) -> void:
	var presentation := StreetArtPresentation.new()
	presentation.build_on_ready = false
	presentation.build_layers()

	var controller := presentation.get_region_visual_controller()
	if controller == null:
		failures.append("StreetArtPresentation must attach RegionVisualController after build.")
	elif controller.theme == null:
		failures.append("RegionVisualController theme must be assigned on street presentation.")

	if presentation.get_node_or_null("SunsetModulate") == null:
		failures.append("Street presentation must retain SunsetModulate for lighting profiles.")

	presentation.free()


func _test_state_transitions(failures: PackedStringArray) -> void:
	var presentation := StreetArtPresentation.new()
	presentation.build_on_ready = false
	presentation.build_layers()
	var controller := presentation.get_region_visual_controller()
	if controller == null:
		failures.append("Cannot test transitions without RegionVisualController.")
		presentation.free()
		return

	controller.apply_state_immediate(CorruptionVisualState.State.NORMAL)
	if controller.get_current_state() != CorruptionVisualState.State.NORMAL:
		failures.append("Controller should start in NORMAL after immediate apply.")

	controller.transition_to_state(CorruptionVisualState.State.MOL_KHAR_APPEARANCE, 0.0)
	if controller.get_current_state() != CorruptionVisualState.State.MOL_KHAR_APPEARANCE:
		failures.append("Zero-duration transition must land on target state.")

	var overlay := presentation.get_node_or_null("RegionVisualOverlay")
	if overlay == null:
		failures.append("Mol-Khar profile should create RegionVisualOverlay.")
	elif overlay.get_node_or_null("Vignette") == null:
		failures.append("Region visual overlay must include Vignette control.")

	presentation.free()


func _test_accessibility_scaling(failures: PackedStringArray) -> void:
	var base := LightingProfile.new()
	base.distortion_strength = 1.0
	base.chromatic_aberration_strength = 1.0
	base.vermilite_accent_energy = 1.0
	base.vignette_strength = 0.4

	var scaled := base.apply_accessibility({
		"flash_scale": 0.55,
		"particle_scale": 0.4,
		"distortion_scale": 0.0,
		"contrast_scale": 0.75,
	})
	if scaled.distortion_strength > 0.001:
		failures.append("Accessibility distortion_scale 0 must zero distortion.")
	if scaled.chromatic_aberration_strength > 0.001:
		failures.append("Accessibility distortion_scale 0 must zero chromatic aberration.")
	if scaled.vermilite_accent_energy >= base.vermilite_accent_energy:
		failures.append("Reduced flashes should lower Vermilite accent energy.")


func _test_comparison_scene_exists(failures: PackedStringArray) -> void:
	var scene_path := "res://scenes/tests/region_visual_comparison_test.tscn"
	if not ResourceLoader.exists(scene_path):
		failures.append("Region visual comparison scene must exist at %s." % scene_path)
