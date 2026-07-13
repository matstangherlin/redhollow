extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Layout := preload("res://scripts/visual/underground_north_star_layout.gd")
const Factory := preload("res://scripts/visual/underground_north_star_factory.gd")
const PresentationScript := preload("res://scripts/visual/underground_art_presentation.gd")
const Profile := preload("res://resources/visual/chapter_zero_underground_profile.tres")

const UNDERGROUND_ART_SCENE := "res://scenes/areas/vertical_slice_underground_art.tscn"
const CHURCH_ART_SCENE := "res://scenes/areas/vertical_slice_church_art.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "underground_beta_complete_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_progression_zones(failures)
	_test_presentation_and_finale_hooks(failures)
	await _test_gameplay_preserved_async(failures)
	_test_church_continuity(failures)
	_test_world_graph(failures)
	_test_scale_continuity(failures)

	suite.finish(failures, 6)


func _test_progression_zones(failures: PackedStringArray) -> void:
	var zones := Layout.get_zones()
	if zones.size() != 5:
		failures.append("Underground must define 5 progression zones.")
	var stages: Array[int] = []
	for entry in zones:
		stages.append(int(entry["stage"]))
	for required in [1, 2, 3, 4, 5]:
		if not stages.has(required):
			failures.append("Missing progression stage %d." % required)


func _test_presentation_and_finale_hooks(failures: PackedStringArray) -> void:
	var presentation := PresentationScript.new() as UndergroundArtPresentation
	presentation.build_on_ready = false
	presentation.profile = Profile as EnvironmentVisualProfile
	presentation.build_layers()

	if presentation.get_node_or_null("Layer06_GameplayStructures/ColossalStatueArt") == null:
		failures.append("Colossal statue art must be built.")
	if presentation.get_node_or_null("Layer12_FinaleHooks/FinaleMolKharShadow") == null:
		failures.append("Finale Mol-Khar shadow hook must exist.")
	if presentation.get_node_or_null("Layer12_FinaleHooks/FinaleArcturusSilhouette") == null:
		failures.append("Finale Arcturus silhouette hook must exist.")

	var props := presentation.get_node_or_null(UndergroundArtPresentation.LAYER_PROPS) as Node2D
	var kit_count := 0
	if props != null:
		for child in props.get_children():
			if String(child.name).begins_with("Kit_"):
				kit_count += 1
	if kit_count < 8:
		failures.append("Underground kit slots expected >=8, got %d." % kit_count)

	if presentation.get_region_visual_controller() == null:
		failures.append("Underground presentation needs RegionVisualController.")

	presentation.free()


func _test_gameplay_preserved_async(failures: PackedStringArray) -> void:
	var packed := load(UNDERGROUND_ART_SCENE) as PackedScene
	if packed == null:
		failures.append("Underground art scene must load.")
		return

	var area: UndergroundArtArea = packed.instantiate() as UndergroundArtArea
	root.add_child(area)
	await TestHelpers.await_frames(get_tree(), 3)

	for path in [
		"WorldObjects/UndergroundCheckpoint",
		"WorldObjects/DeaconRusk",
		"WorldObjects/DeaconRuskEncounter",
		"WorldObjects/PartnerDiaryPage",
		"WorldObjects/StatueEyes",
		"WorldObjects/HiddenPassage",
		"Exits/ToChurchExit",
	]:
		if area.get_node_or_null(path) == null:
			failures.append("Missing gameplay node: %s." % path)

	if area.get_art_presentation() == null:
		failures.append("Underground art presentation must spawn after deferred visual apply.")

	area.queue_free()


func _test_church_continuity(failures: PackedStringArray) -> void:
	var church_packed := load(CHURCH_ART_SCENE) as PackedScene
	var under_packed := load(UNDERGROUND_ART_SCENE) as PackedScene
	if church_packed == null or under_packed == null:
		failures.append("Church/underground art scenes must load.")
		return

	var church: ChurchArtArea = church_packed.instantiate() as ChurchArtArea
	var under: UndergroundArtArea = under_packed.instantiate() as UndergroundArtArea
	var church_exit: AreaExit = church.get_node_or_null("Exits/ToUndergroundExit") as AreaExit
	var under_exit: AreaExit = under.get_node_or_null("Exits/ToChurchExit") as AreaExit
	if church_exit == null or under_exit == null:
		failures.append("Church/underground exits must exist.")
	else:
		if not String(church_exit.target_scene).ends_with("vertical_slice_underground_art.tscn"):
			failures.append("Church must exit to underground art.")
		if not String(under_exit.target_scene).ends_with("vertical_slice_church_art.tscn"):
			failures.append("Underground must exit to church art.")
	church.free()
	under.free()


func _test_world_graph(failures: PackedStringArray) -> void:
	var graph := WorldGraphFactory.create_beta_graph()
	for node in graph.nodes:
		if node.area_id == &"vs_greybox_underground":
			if not String(node.scene_path).ends_with("vertical_slice_underground_art.tscn"):
				failures.append("World graph underground must use art scene.")
			return
	failures.append("World graph missing underground node.")


func _test_scale_continuity(failures: PackedStringArray) -> void:
	var street_profile := load("res://resources/visual/chapter_zero_street_profile.tres") as EnvironmentVisualProfile
	var under_profile := Profile as EnvironmentVisualProfile
	if street_profile.ground_surface_y != under_profile.ground_surface_y:
		failures.append("Underground ground_surface_y must match street/church.")
	if street_profile.calder_sprite_size != under_profile.calder_sprite_size:
		failures.append("Underground Calder contract must match.")
