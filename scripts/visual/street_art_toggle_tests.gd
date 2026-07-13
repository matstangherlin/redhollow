extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const PROFILE_PATH := "res://resources/visual/chapter_zero_street_profile.tres"
const STREET_ART_SCENE_PATH := "res://scenes/areas/vertical_slice_street_art.tscn"
const STREET_GREYBOX_SCENE_PATH := "res://scenes/areas/vertical_slice_street.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "street_art_toggle_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_profile_contract(failures)
	_test_presentation_layers(failures)
	_test_art_area_contract(failures)
	_test_gameplay_preserved(failures)
	_test_npc_visuals_not_hidden_in_art_mode(failures)

	suite.finish(failures, 5)


func _test_profile_contract(failures: PackedStringArray) -> void:
	var profile := load(PROFILE_PATH) as EnvironmentVisualProfile
	if profile == null:
		failures.append("EnvironmentVisualProfile street resource must load.")
		return

	if profile.logical_resolution != Vector2i(480, 270):
		failures.append("Logical resolution must remain 480x270.")
	if profile.pixels_per_unit != 1:
		failures.append("Pixels per unit must remain 1.")
	if profile.tile_size_px != 16:
		failures.append("Tile size must remain 16px.")
	if profile.calder_sprite_size != Vector2i(40, 72):
		failures.append("Calder production sprite contract must be 40x72 per VISUAL_SCALE_STUDY.md.")


func _test_presentation_layers(failures: PackedStringArray) -> void:
	var presentation_script: GDScript = load(
		"res://scripts/visual/street_art_presentation.gd"
	) as GDScript
	if presentation_script == null:
		failures.append("Street art presentation script must load.")
		return
	if not presentation_script.can_instantiate():
		failures.append("Street art presentation script cannot instantiate.")
		return

	var presentation: StreetArtPresentation = presentation_script.new() as StreetArtPresentation
	if presentation == null:
		failures.append("Street art presentation instance must be created.")
		return

	presentation.build_on_ready = false
	presentation.build_layers()

	for layer_name in [
		StreetArtPresentation.LAYER_SKY,
		StreetArtPresentation.LAYER_FAR_MOUNTAINS,
		StreetArtPresentation.LAYER_DISTANT_TOWN,
		StreetArtPresentation.LAYER_MID_BUILDINGS,
		StreetArtPresentation.LAYER_GAMEPLAY_GROUND,
		StreetArtPresentation.LAYER_GAMEPLAY_STRUCTURES,
		StreetArtPresentation.LAYER_PROPS,
		StreetArtPresentation.LAYER_INTERACTABLES,
		StreetArtPresentation.LAYER_LIGHTING,
		StreetArtPresentation.LAYER_ATMOSPHERE,
		StreetArtPresentation.LAYER_FOREGROUND,
		StreetArtPresentation.LAYER_DEBUG,
	]:
		if presentation.get_node_or_null(layer_name) == null:
			failures.append("Street art presentation missing layer: %s." % layer_name)

	if presentation.get_node_or_null("SunsetModulate") == null:
		failures.append("Street art presentation missing CanvasModulate.")

	if presentation.get_region_visual_controller() == null:
		failures.append("Street art presentation must include RegionVisualController.")

	presentation.free()


func _test_art_area_contract(failures: PackedStringArray) -> void:
	if not ResourceLoader.exists(STREET_ART_SCENE_PATH):
		failures.append("Street art area scene file must exist.")
		return

	var packed := load(STREET_ART_SCENE_PATH) as PackedScene
	if packed == null:
		failures.append("Street art area scene must load as PackedScene.")


func _test_gameplay_preserved(failures: PackedStringArray) -> void:
	var greybox_packed := load(STREET_GREYBOX_SCENE_PATH) as PackedScene
	if greybox_packed == null:
		failures.append("Street greybox scene must load.")
		return
	if load(STREET_ART_SCENE_PATH) as PackedScene == null:
		failures.append("Street art scene must load.")

	var greybox: AreaRoot = greybox_packed.instantiate() as AreaRoot
	if greybox.get_node_or_null("Solids/Ground/CollisionShape2D") == null:
		failures.append("Street area missing ground collision: %s." % greybox.name)
	if greybox.get_node_or_null("WorldObjects/Elias") == null:
		failures.append("Street area missing Elias: %s." % greybox.name)
	if greybox.get_node_or_null("Exits/ToChurchExit") == null:
		failures.append("Street area missing church exit: %s." % greybox.name)

	greybox.free()


func _test_npc_visuals_not_hidden_in_art_mode(failures: PackedStringArray) -> void:
	var packed := load(STREET_ART_SCENE_PATH) as PackedScene
	if packed == null:
		failures.append("Street art scene must load for NPC visibility test.")
		return

	var area: StreetArtArea = packed.instantiate() as StreetArtArea
	if area == null:
		failures.append("Street art area must instantiate.")
		return

	area.show_art_presentation = true
	area.show_greybox_visuals = false
	get_tree().root.add_child(area)
	await TestHelpers.await_frames(get_tree(), 2)

	var elias_body: Polygon2D = area.get_node_or_null("WorldObjects/Elias/Visual/BodyVisual") as Polygon2D
	if elias_body == null:
		failures.append("Elias BodyVisual must exist in street art area.")
	elif not elias_body.visible:
		failures.append("Art mode must not hide Elias polygon visuals.")

	area.queue_free()
