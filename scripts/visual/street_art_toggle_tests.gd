extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const PROFILE_PATH := "res://resources/visual/chapter_zero_street_profile.tres"
const PRESENTATION_SCENE := preload("res://scenes/environment/chapter_zero/street_art_presentation.tscn")
const STREET_ART_SCENE := preload("res://scenes/areas/vertical_slice_street_art.tscn")
const STREET_GREYBOX_SCENE := preload("res://scenes/areas/vertical_slice_street.tscn")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "street_art_toggle_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_profile_contract(failures)
	_test_presentation_layers(failures)
	_test_art_area_toggle(failures)
	_test_gameplay_preserved(failures)

	suite.finish(failures, 4)


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
	if profile.calder_sprite_size != Vector2i(32, 56):
		failures.append("Calder sprite contract must remain 32x56.")


func _test_presentation_layers(failures: PackedStringArray) -> void:
	var presentation: StreetArtPresentation = PRESENTATION_SCENE.instantiate()
	get_tree().root.add_child(presentation)
	await TestHelpers.await_frames(get_tree(), 2)

	for layer_name in [
		StreetArtPresentation.LAYER_SKY,
		StreetArtPresentation.LAYER_MOUNTAINS,
		StreetArtPresentation.LAYER_CITY,
		StreetArtPresentation.LAYER_MID_BUILDINGS,
		StreetArtPresentation.LAYER_PLAYFIELD,
		StreetArtPresentation.LAYER_PROPS,
		StreetArtPresentation.LAYER_LIGHTING,
		StreetArtPresentation.LAYER_FOREGROUND,
		StreetArtPresentation.LAYER_ATMOSPHERE,
	]:
		if presentation.get_node_or_null(layer_name) == null:
			failures.append("Street art presentation missing layer: %s." % layer_name)

	if presentation.get_node_or_null("SunsetModulate") == null:
		failures.append("Street art presentation missing CanvasModulate.")

	presentation.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_art_area_toggle(failures: PackedStringArray) -> void:
	var area: StreetArtArea = STREET_ART_SCENE.instantiate()
	get_tree().root.add_child(area)
	await TestHelpers.await_frames(get_tree(), 2)

	area.set_visual_mode(true)
	await TestHelpers.await_frames(get_tree(), 1)
	if area.get_art_presentation() == null:
		failures.append("Art area should spawn StreetArtPresentation in art mode.")

	area.set_visual_mode(false)
	await TestHelpers.await_frames(get_tree(), 1)
	if area.get_art_presentation() != null and area.get_art_presentation().visible:
		failures.append("Art presentation should hide when greybox mode is active.")

	area.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_gameplay_preserved(failures: PackedStringArray) -> void:
	var greybox: AreaRoot = STREET_GREYBOX_SCENE.instantiate()
	var art: StreetArtArea = STREET_ART_SCENE.instantiate()

	for area in [greybox, art]:
		if area.get_node_or_null("Solids/Ground/CollisionShape2D") == null:
			failures.append("Street area missing ground collision: %s." % area.name)
		if area.get_node_or_null("WorldObjects/Elias") == null:
			failures.append("Street area missing Elias: %s." % area.name)
		if area.get_node_or_null("Exits/ToChurchExit") == null:
			failures.append("Street area missing church exit: %s." % area.name)

	greybox.queue_free()
	art.queue_free()
