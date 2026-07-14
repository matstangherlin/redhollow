extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Spec := preload("res://scripts/visual/church_final_mold_spec.gd")
const Layout := preload("res://scripts/visual/church_north_star_layout.gd")
const CHURCH_ART_SCENE := "res://scenes/areas/vertical_slice_church_art.tscn"
const UNDERGROUND_ART_SCENE := "res://scenes/areas/vertical_slice_underground_art.tscn"
const STREET_ART_SCENE := "res://scenes/areas/vertical_slice_street_art.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "church_final_mold_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_six_districts(failures)
	_test_mold_facade_variants(failures)
	_test_set_piece_checklist(failures)
	await _test_full_church_mold(failures)
	_test_underground_and_street_untouched(failures)

	suite.finish(failures, 5)


func _test_six_districts(failures: PackedStringArray) -> void:
	var districts := Layout.get_districts()
	if districts.size() != 6:
		failures.append("Must preserve exactly 6 church districts (got %d)." % districts.size())
	var labels := [
		"Chegada da rua",
		"Alcova do Penitente",
		"Praça da Ordem",
		"Pátio da arena",
		"Corredor Red Brand",
		"Portão subterrâneo",
	]
	for i in range(mini(labels.size(), districts.size())):
		if String(districts[i].get("label", "")) != labels[i]:
			failures.append("District %d label mismatch." % i)


func _test_mold_facade_variants(failures: PackedStringArray) -> void:
	var total := 0
	var variant_ids: Dictionary = {}
	for d in range(6):
		for spec in Layout.get_mold_facades_for_district(d, 876.0):
			total += 1
			variant_ids[int(spec.get("variant", 0))] = true
	if total < 8:
		failures.append("Expected fuller church facade set (got %d)." % total)
	if variant_ids.size() < 3:
		failures.append("Facades must use multiple variants (got %d)." % variant_ids.size())


func _test_set_piece_checklist(failures: PackedStringArray) -> void:
	var required := Spec.get_set_piece_checklist()
	var positions: Dictionary = Layout.get_set_piece_positions(876.0)
	for key in required:
		if not positions.has(String(key)):
			failures.append("Missing set piece position: %s." % key)


func _test_full_church_mold(failures: PackedStringArray) -> void:
	var packed := load(CHURCH_ART_SCENE) as PackedScene
	var area: ChurchArtArea = packed.instantiate() as ChurchArtArea
	root.add_child(area)
	area.set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	await TestHelpers.await_frames(get_tree(), 4)

	var stats := area.get_final_sample_stats()
	if int(stats.get("districts", 0)) != 6:
		failures.append("Mold must process 6 districts.")
	if String(stats.get("mold", "")) != Spec.MOLD_ID:
		failures.append("Mold id must be %s." % Spec.MOLD_ID)
	if int(stats.get("set_pieces", 0)) != 6:
		failures.append("Mold must finalize 6 set pieces.")

	var presentation := area.get_art_presentation()
	if presentation == null or presentation.get_node_or_null("FinalMoldRoot") == null:
		failures.append("FinalMoldRoot missing on church presentation.")
	else:
		var mold := presentation.get_node("FinalMoldRoot")
		for piece in [
			"MoldSetPieces/Mold_BellTower",
			"MoldSetPieces/Mold_MainEntrance",
			"MoldSetPieces/Mold_OrderStatue",
			"MoldSetPieces/Mold_ExternalAltar",
			"MoldSetPieces/Mold_CultGate",
			"MoldSetPieces/Mold_UndergroundPassage",
		]:
			if mold.get_node_or_null(piece) == null:
				failures.append("Missing mold set piece: %s." % piece)

	# Collisions + gameplay remain.
	if area.get_node_or_null("Solids/Ground/CollisionShape2D") == null:
		failures.append("Ground collision must remain.")
	for node_path in [
		"WorldObjects/ChurchYardArena",
		"WorldObjects/ChainPenitentAlcove",
		"WorldObjects/ChurchCheckpoint",
		"WorldObjects/OrderDocument",
		"WorldObjects/RedBrandPassage",
		"WorldObjects/CultRedBarrier",
		"WorldObjects/ShortcutToStreet",
		"Exits/ToStreetExit",
		"Exits/ToUndergroundExit",
	]:
		if area.get_node_or_null(node_path) == null:
			failures.append("Gameplay node must remain: %s." % node_path)

	# Mold must not parent under Solids.
	if area.get_node_or_null("Solids/FinalMoldRoot") != null:
		failures.append("FinalMoldRoot must never live under Solids.")

	area.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_underground_and_street_untouched(failures: PackedStringArray) -> void:
	var under := load(UNDERGROUND_ART_SCENE) as PackedScene
	if under == null:
		failures.append("Underground art scene must still load.")
	else:
		var scene: Node = under.instantiate()
		if scene.get_node_or_null("FinalMoldRoot") != null:
			failures.append("Underground must not contain church FinalMoldRoot.")
		# No church mold composer side effects.
		if scene.find_child("Mold_BellTower", true, false) != null:
			failures.append("Underground must not receive church mold set pieces.")
		scene.free()

	var street := load(STREET_ART_SCENE) as PackedScene
	if street == null:
		failures.append("Street art scene must still load.")
	else:
		var s: Node = street.instantiate()
		if s.find_child("Mold_BellTower", true, false) != null:
			failures.append("Street must not receive church-only mold set pieces.")
		s.free()
