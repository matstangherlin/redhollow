extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")
const Layout := preload("res://scripts/visual/street_north_star_layout.gd")
const STREET_ART_SCENE := "res://scenes/areas/vertical_slice_street_art.tscn"
const CHURCH_ART_SCENE := "res://scenes/areas/vertical_slice_church_art.tscn"
const UNDERGROUND_ART_SCENE := "res://scenes/areas/vertical_slice_underground_art.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "street_final_mold_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_nine_districts(failures)
	_test_facade_variants_not_clones(failures)
	await _test_full_street_mold(failures)
	_test_church_underground_untouched(failures)

	suite.finish(failures, 4)


func _test_nine_districts(failures: PackedStringArray) -> void:
	var districts := Layout.get_districts()
	if districts.size() != 9:
		failures.append("Must preserve exactly 9 districts (got %d)." % districts.size())
	var labels := [
		"Entrada da cidade",
		"Encontro com Elias",
		"Saloon",
		"Estátua e pista",
		"Segredo elevado",
		"Rota opcional",
		"Arena da rua",
		"Beco do duo",
		"Saída para igreja",
	]
	for i in range(mini(labels.size(), districts.size())):
		if String(districts[i].get("label", "")) != labels[i]:
			failures.append("District %d label mismatch." % i)


func _test_facade_variants_not_clones(failures: PackedStringArray) -> void:
	var variants: Dictionary = {}
	var total := 0
	for d in range(9):
		for spec in Layout.get_mold_facades_for_district(d, 876.0):
			total += 1
			var key := "%s_%.0f_%.0f_v%d" % [
				String(spec.get("name", "")),
				float((spec.get("pos", Vector2.ZERO) as Vector2).x),
				float(spec.get("w", 0.0)),
				int(spec.get("variant", 0)),
			]
			if variants.has(key):
				failures.append("Duplicate facade fingerprint: %s" % key)
			variants[key] = true
	if total < 12:
		failures.append("Expected fuller street facade set (got %d)." % total)
	var variant_ids: Dictionary = {}
	for d in range(9):
		for spec in Layout.get_mold_facades_for_district(d, 876.0):
			variant_ids[int(spec.get("variant", 0))] = true
	if variant_ids.size() < 3:
		failures.append("Facades must use multiple variants (got %d)." % variant_ids.size())


func _test_full_street_mold(failures: PackedStringArray) -> void:
	var packed := load(STREET_ART_SCENE) as PackedScene
	var area: StreetArtArea = packed.instantiate() as StreetArtArea
	root.add_child(area)
	area.set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	await TestHelpers.await_frames(get_tree(), 4)

	var stats := area.get_final_sample_stats()
	if int(stats.get("districts", 0)) != 9:
		failures.append("Mold must process 9 districts.")
	if String(stats.get("mold", "")) != "north_star_final_mold_v1":
		failures.append("Mold id must be north_star_final_mold_v1.")
	var presentation := area.get_art_presentation()
	if presentation == null or presentation.get_node_or_null("FinalMoldRoot") == null:
		failures.append("FinalMoldRoot missing.")
	# Collisions still present.
	if area.get_node_or_null("Solids/Ground/CollisionShape2D") == null:
		failures.append("Ground collision must remain.")
	if area.get_node_or_null("Solids/PlatformA") == null:
		failures.append("PlatformA must remain.")
	# Production encounters remain.
	if area.get_node_or_null("WorldObjects/CultBrawlerStreet") == null:
		failures.append("Production Brawler must remain.")
	if area.get_node_or_null("WorldObjects/GunslingerOptional") == null:
		failures.append("Optional Gunslinger must remain.")
	if area.get_node_or_null("WorldObjects/Elias") == null:
		failures.append("Elias must remain.")

	area.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_church_underground_untouched(failures: PackedStringArray) -> void:
	## Street mold must not inject into other areas. Church may have its own FinalMoldRoot
	## under presentation when final_candidate is enabled — never at area root here.
	for path in [CHURCH_ART_SCENE, UNDERGROUND_ART_SCENE]:
		var packed := load(path) as PackedScene
		if packed == null:
			failures.append("Scene must still load: %s" % path)
			continue
		var scene: Node = packed.instantiate()
		if scene.get_node_or_null("FinalMoldRoot") != null:
			failures.append("%s must not contain FinalMoldRoot as area-root child." % path)
		scene.free()
