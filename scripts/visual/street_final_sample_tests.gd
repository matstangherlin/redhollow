extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")
const STREET_ART_SCENE := "res://scenes/areas/vertical_slice_street_art.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "street_final_sample_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_band_definition(failures)
	await _test_three_modes(failures)
	await _test_final_candidate_only_band(failures)

	suite.finish(failures, 3)


func _test_band_definition(failures: PackedStringArray) -> void:
	var width := Spec.SAMPLE_X_MAX - Spec.SAMPLE_X_MIN
	if width < 600.0 or width > 900.0:
		failures.append("Sample band width must be 600–900 px (got %.0f)." % width)
	if Spec.SAMPLE_X_MIN != 100.0 or Spec.SAMPLE_X_MAX != 900.0:
		failures.append("Documented band must be X 100–900.")
	var required := ["calder_spawn", "elias", "saloon_facade", "lamp", "elevated_platform", "statue", "secret_cache", "cult_brawler_showcase"]
	var checklist := Spec.get_element_checklist()
	for need in required:
		var found := false
		for entry in checklist:
			if String(entry.get("id", "")) == need and bool(entry.get("in_band", false)):
				found = true
				break
		if not found:
			failures.append("Checklist missing in-band element: %s." % need)


func _test_three_modes(failures: PackedStringArray) -> void:
	var packed := load(STREET_ART_SCENE) as PackedScene
	if packed == null:
		failures.append("Street art scene must load.")
		return
	var area: StreetArtArea = packed.instantiate() as StreetArtArea
	root.add_child(area)
	await TestHelpers.await_frames(get_tree(), 3)

	area.set_presentation_mode(Spec.MODE_GREYBOX)
	await TestHelpers.await_frames(get_tree(), 2)
	if area.get_presentation_mode() != Spec.MODE_GREYBOX:
		failures.append("Mode greybox failed.")
	if area.show_art_presentation:
		failures.append("Greybox must hide art presentation.")

	area.set_presentation_mode(Spec.MODE_NORTH_STAR)
	await TestHelpers.await_frames(get_tree(), 2)
	if area.get_art_presentation() == null:
		failures.append("North Star must build art presentation.")
	if area.get_node_or_null("WorldObjects/CultBrawlerFinalSample") != null:
		failures.append("North Star must not spawn sample brawler.")

	area.set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	await TestHelpers.await_frames(get_tree(), 3)
	if area.get_presentation_mode() != Spec.MODE_FINAL_CANDIDATE:
		failures.append("Final candidate mode failed.")
	var presentation := area.get_art_presentation()
	if presentation == null or presentation.get_node_or_null("FinalMoldRoot") == null:
		failures.append("Final candidate must attach FinalMoldRoot (full street mold).")
	var sample_brawler := area.get_node_or_null("WorldObjects/CultBrawlerFinalSample")
	if sample_brawler == null:
		failures.append("Final candidate must spawn CultBrawlerFinalSample in band.")
	var stats := area.get_final_sample_stats()
	if int(stats.get("placeholder_tags", 0)) <= 0:
		failures.append("Final mold geometry must be tagged PLACEHOLDER_CANDIDATE.")
	if int(stats.get("districts", 0)) < 9:
		failures.append("Final mold must cover all 9 districts (got %d)." % int(stats.get("districts", 0)))
	if int(stats.get("facades", 0)) < 8:
		failures.append("Final mold should vary multiple facades (got %d)." % int(stats.get("facades", 0)))

	# Church / underground untouched — spot-check scene IDs remain street.
	if String(area.area_id) != "vs_greybox_street":
		failures.append("Sample must not change area_id.")

	area.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_final_candidate_only_band(failures: PackedStringArray) -> void:
	var packed := load(STREET_ART_SCENE) as PackedScene
	var area: StreetArtArea = packed.instantiate() as StreetArtArea
	root.add_child(area)
	area.set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	await TestHelpers.await_frames(get_tree(), 3)

	var production := area.get_node_or_null("WorldObjects/CultBrawlerStreet")
	if production == null:
		failures.append("Production CultBrawlerStreet must remain.")
	elif production is Node2D:
		var px := (production as Node2D).position.x
		# Arena district — must stay outside the final sample band (100–900).
		if Spec.contains_x(px):
			failures.append("Production brawler must stay outside sample band (x=%.1f)." % px)
		if px < 1100.0:
			failures.append("Production brawler should remain in arena approach (x>=1100, got %.1f)." % px)

	var sample := area.get_node_or_null("WorldObjects/CultBrawlerFinalSample")
	if sample is Node2D:
		var sx := (sample as Node2D).position.x
		if not Spec.contains_x(sx):
			failures.append("Sample brawler must be inside X 100–900.")

	area.set_presentation_mode(Spec.MODE_NORTH_STAR)
	await TestHelpers.await_frames(get_tree(), 2)
	if area.get_node_or_null("WorldObjects/CultBrawlerFinalSample") != null:
		failures.append("Leaving final candidate must remove sample brawler.")
	if area.get_art_presentation() != null and area.get_art_presentation().get_node_or_null("FinalMoldRoot") != null:
		failures.append("Leaving final candidate must remove FinalMoldRoot.")

	area.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)
