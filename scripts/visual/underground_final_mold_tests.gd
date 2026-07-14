extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Spec := preload("res://scripts/visual/underground_final_mold_spec.gd")
const Layout := preload("res://scripts/visual/underground_north_star_layout.gd")
const UNDER_ART := "res://scenes/areas/vertical_slice_underground_art.tscn"
const STREET_ART := "res://scenes/areas/vertical_slice_street_art.tscn"
const CHURCH_ART := "res://scenes/areas/vertical_slice_church_art.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "underground_final_mold_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_five_stages(failures)
	_test_set_pieces(failures)
	await _test_full_mold(failures)
	_test_neighbors_untouched(failures)

	suite.finish(failures, 4)


func _test_five_stages(failures: PackedStringArray) -> void:
	if Layout.get_zones().size() != 5:
		failures.append("Must preserve exactly 5 progression zones.")
	if Spec.get_progression_stages().size() != 5:
		failures.append("Spec must list 5 progression stages.")


func _test_set_pieces(failures: PackedStringArray) -> void:
	for key in Spec.get_set_piece_checklist():
		if String(key).is_empty():
			failures.append("Empty set piece id.")


func _test_full_mold(failures: PackedStringArray) -> void:
	var packed := load(UNDER_ART) as PackedScene
	var area: UndergroundArtArea = packed.instantiate() as UndergroundArtArea
	root.add_child(area)
	area.set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	await TestHelpers.await_frames(get_tree(), 4)

	var stats := area.get_final_sample_stats()
	if int(stats.get("districts", 0)) != 5:
		failures.append("Mold must process 5 zones.")
	if String(stats.get("mold", "")) != Spec.MOLD_ID:
		failures.append("Mold id mismatch.")
	var presentation := area.get_art_presentation()
	if presentation == null or presentation.get_node_or_null("FinalMoldRoot") == null:
		failures.append("FinalMoldRoot missing.")
	else:
		var mold := presentation.get_node("FinalMoldRoot")
		if mold.get_node_or_null("MoldBossArena") == null:
			failures.append("Boss arena mold missing.")
		if mold.get_node_or_null("MoldSetPieces/Mold_ColossalStatue") == null:
			failures.append("Colossal statue mold missing.")
		if mold.get_node_or_null("MoldFinaleBeats/Mold_MolKharShadow") == null:
			failures.append("Mol-Khar silhouette tease missing.")

	for node_path in [
		"WorldObjects/DeaconRusk",
		"WorldObjects/DeaconRuskEncounter",
		"WorldObjects/UndergroundCheckpoint",
		"Exits/ToChurchExit",
		"Solids/Ground",
	]:
		if area.get_node_or_null(node_path) == null:
			failures.append("Gameplay node must remain: %s." % node_path)

	if area.get_node_or_null("Solids/FinalMoldRoot") != null:
		failures.append("FinalMoldRoot must never live under Solids.")

	area.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_neighbors_untouched(failures: PackedStringArray) -> void:
	for path in [STREET_ART, CHURCH_ART]:
		var packed := load(path) as PackedScene
		var scene: Node = packed.instantiate()
		if scene.find_child("Mold_MolKharShadow", true, false) != null:
			failures.append("%s must not receive underground finale mold nodes." % path)
		if scene.get_node_or_null("FinalMoldRoot") != null:
			failures.append("%s must not have FinalMoldRoot as area-root child." % path)
		scene.free()
