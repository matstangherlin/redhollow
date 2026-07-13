extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Layout := preload("res://scripts/visual/church_north_star_layout.gd")
const Factory := preload("res://scripts/visual/church_north_star_factory.gd")
const PresentationScript := preload("res://scripts/visual/church_art_presentation.gd")
const Profile := preload("res://resources/visual/chapter_zero_church_profile.tres")

const CHURCH_ART_SCENE_PATH := "res://scenes/areas/vertical_slice_church_art.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "church_beta_complete_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_district_layout(failures)
	_test_presentation_layers(failures)
	_test_interactable_markers_aligned(failures)
	_test_gameplay_preserved(failures)
	_test_continuity_with_street(failures)
	_test_map_registry(failures)

	suite.finish(failures, 6)


func _test_district_layout(failures: PackedStringArray) -> void:
	if Layout.get_districts().size() != 6:
		failures.append("Church district must define 6 zones.")


func _test_presentation_layers(failures: PackedStringArray) -> void:
	var presentation := PresentationScript.new() as ChurchArtPresentation
	presentation.build_on_ready = false
	presentation.profile = Profile as EnvironmentVisualProfile
	presentation.build_layers()

	for layer_name in [
		ChurchArtPresentation.LAYER_SKY,
		ChurchArtPresentation.LAYER_DISTANT_CHURCH,
		ChurchArtPresentation.LAYER_GAMEPLAY_GROUND,
		ChurchArtPresentation.LAYER_PROPS,
		ChurchArtPresentation.LAYER_LIGHTING,
	]:
		if presentation.get_node_or_null(layer_name) == null:
			failures.append("Church presentation missing layer: %s." % layer_name)

	if presentation.get_node_or_null("Layer06_GameplayStructures/BellTowerStructure") == null:
		failures.append("Church must build bell tower set piece.")
	if presentation.get_node_or_null("Layer07_Props/UndergroundPassageVisual") == null:
		failures.append("Church must build underground passage visual.")

	var props := presentation.get_node_or_null(ChurchArtPresentation.LAYER_PROPS) as Node2D
	var kit_count := 0
	if props != null:
		for child in props.get_children():
			if String(child.name).begins_with("Kit_"):
				kit_count += 1
	if kit_count < 8:
		failures.append("Church must spawn kit visual slots (>=8), got %d." % kit_count)

	if presentation.get_region_visual_controller() == null:
		failures.append("Church presentation must include RegionVisualController.")

	presentation.free()


func _test_interactable_markers_aligned(failures: PackedStringArray) -> void:
	var ground_y := Factory.ground_anchor_y(Profile as EnvironmentVisualProfile)
	var by_id: Dictionary = {}
	for entry in Layout.get_interactable_markers(ground_y):
		by_id[entry["id"]] = entry["pos"]

	if by_id.get("penitent", Vector2.ZERO) != Vector2(320, ground_y):
		failures.append("Penitent marker must align at x=320.")
	if by_id.get("underground_exit", Vector2.ZERO) != Vector2(1500, ground_y):
		failures.append("Underground exit marker must align at x=1500.")
	if by_id.get("cult_gate", Vector2.ZERO) != Vector2(1150, ground_y):
		failures.append("Cult gate marker must align at x=1150.")


func _test_gameplay_preserved(failures: PackedStringArray) -> void:
	var packed := load(CHURCH_ART_SCENE_PATH) as PackedScene
	if packed == null:
		failures.append("Church art scene must load.")
		return

	var area: ChurchArtArea = packed.instantiate() as ChurchArtArea
	for node_path in [
		"WorldObjects/ChurchYardArena",
		"WorldObjects/ChainPenitentAlcove",
		"WorldObjects/RedBrandPassage",
		"WorldObjects/CultRedBarrier",
		"WorldObjects/ShortcutToStreet",
		"Exits/ToStreetExit",
		"Exits/ToUndergroundExit",
	]:
		if area.get_node_or_null(node_path) == null:
			failures.append("Church art missing gameplay node: %s." % node_path)

	area.free()


func _test_continuity_with_street(failures: PackedStringArray) -> void:
	var street_packed := load("res://scenes/areas/vertical_slice_street_art.tscn") as PackedScene
	var church_packed := load(CHURCH_ART_SCENE_PATH) as PackedScene
	if street_packed == null or church_packed == null:
		failures.append("Street/church art scenes must load for continuity test.")
		return

	var street: StreetArtArea = street_packed.instantiate() as StreetArtArea
	var church: ChurchArtArea = church_packed.instantiate() as ChurchArtArea

	var street_exit: AreaExit = street.get_node_or_null("Exits/ToChurchExit") as AreaExit
	var church_exit: AreaExit = church.get_node_or_null("Exits/ToStreetExit") as AreaExit
	if street_exit == null or church_exit == null:
		failures.append("Street/church exits must exist.")
	else:
		if not String(church_exit.target_scene).ends_with("vertical_slice_street_art.tscn"):
			failures.append("Church exit must return to street art scene.")
		if not String(street_exit.target_scene).ends_with("vertical_slice_church_art.tscn"):
			failures.append("Street exit must lead to church art scene.")

	var street_profile := load("res://resources/visual/chapter_zero_street_profile.tres") as EnvironmentVisualProfile
	var church_profile := Profile as EnvironmentVisualProfile
	if street_profile.pixels_per_unit != church_profile.pixels_per_unit:
		failures.append("Church must keep same pixels_per_unit as street.")
	if street_profile.ground_surface_y != church_profile.ground_surface_y:
		failures.append("Church must keep same ground_surface_y as street for continuity.")

	street.free()
	church.free()


func _test_map_registry(failures: PackedStringArray) -> void:
	var graph := WorldGraphFactory.create_beta_graph()
	var church_node: AreaData = null
	for node in graph.nodes:
		if node.area_id == &"vs_greybox_church":
			church_node = node
			break
	if church_node == null:
		failures.append("World graph must include vs_greybox_church.")
	elif not String(church_node.scene_path).ends_with("vertical_slice_church_art.tscn"):
		failures.append("World graph church node must point to church art scene.")
