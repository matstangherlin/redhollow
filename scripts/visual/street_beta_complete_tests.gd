extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Layout := preload("res://scripts/visual/street_north_star_layout.gd")
const Factory := preload("res://scripts/visual/street_north_star_factory.gd")
const PresentationScript := preload("res://scripts/visual/street_art_presentation.gd")

const STREET_ART_SCENE_PATH := "res://scenes/areas/vertical_slice_street_art.tscn"
const PROFILE_PATH := "res://resources/visual/chapter_zero_street_profile.tres"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "street_beta_complete_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_district_layout(failures)
	_test_beta_composer_stats(failures)
	_test_interactable_markers_aligned(failures)
	_test_beta_gameplay_nodes(failures)
	_test_narrative_decals_present(failures)

	suite.finish(failures, 5)


func _test_district_layout(failures: PackedStringArray) -> void:
	var districts := Layout.get_districts()
	if districts.size() != 9:
		failures.append("Beta street must define 9 districts, got %d." % districts.size())

	var labels: PackedStringArray = PackedStringArray()
	for entry in districts:
		labels.append(String(entry["label"]))
	for required in [
		"Entrada da cidade",
		"Encontro com Elias",
		"Saloon",
		"Estátua e pista",
		"Segredo elevado",
		"Rota opcional",
		"Arena da rua",
		"Beco do duo",
		"Saída para igreja",
	]:
		if not labels.has(required):
			failures.append("Beta street missing district label: %s." % required)


func _test_beta_composer_stats(failures: PackedStringArray) -> void:
	var profile := load(PROFILE_PATH) as EnvironmentVisualProfile
	if profile == null:
		failures.append("Street profile must load for beta composer test.")
		return

	var presentation := PresentationScript.new() as StreetArtPresentation
	presentation.build_on_ready = false
	presentation.profile = profile
	presentation.build_layers()

	if presentation.get_node_or_null("Layer06_GameplayStructures/CityEntranceGateway") == null:
		failures.append("Composer must build city entrance gateway.")
	if presentation.get_node_or_null("Layer07_Props/StreetArenaVisual") == null:
		failures.append("Composer must build street arena visual.")

	var props := presentation.get_node_or_null(PresentationScript.LAYER_PROPS) as Node2D
	var kit_count := 0
	var decal_count := 0
	if props != null:
		for child in props.get_children():
			if String(child.name).begins_with("Kit_"):
				kit_count += 1
			if String(child.name).begins_with("Narrative_"):
				decal_count += 1
	if kit_count < 8:
		failures.append("Composer must spawn kit visual slots (>=8), got %d." % kit_count)
	if decal_count < 8:
		failures.append("Composer must place narrative decals (>=8), got %d." % decal_count)

	presentation.free()


func _test_interactable_markers_aligned(failures: PackedStringArray) -> void:
	var profile := load(PROFILE_PATH) as EnvironmentVisualProfile
	if profile == null:
		failures.append("Street profile must load for marker alignment test.")
		return

	var ground_y := Factory.ground_anchor_y(profile)
	var markers := Layout.get_interactable_markers(ground_y)
	var by_id: Dictionary = {}
	for entry in markers:
		by_id[entry["id"]] = entry["pos"]

	if by_id.get("elias", Vector2.ZERO) != Vector2(260, ground_y):
		failures.append("Elias marker must align with WorldObjects/Elias at x=260.")
	if by_id.get("secret", Vector2.ZERO) != Vector2(560, ground_y - 88):
		failures.append("Secret marker must align with elevated cartridge platform.")
	if by_id.get("statue", Vector2.ZERO) != Vector2(520, ground_y):
		failures.append("Statue marker must align with NightStatue at x=520.")
	if by_id.get("combat", Vector2.ZERO) != Vector2(1280, ground_y):
		failures.append("Combat marker must align with CultBrawler at x=1280.")
	if by_id.get("partner_clue", Vector2.ZERO) != Vector2(1380, ground_y):
		failures.append("Partner clue marker must align with medallion at x=1380.")
	if by_id.get("church_exit", Vector2.ZERO) != Vector2(2320, ground_y):
		failures.append("Church exit marker must align with ToChurchExit at x=2320.")


func _test_beta_gameplay_nodes(failures: PackedStringArray) -> void:
	var packed := load(STREET_ART_SCENE_PATH) as PackedScene
	if packed == null:
		failures.append("Street art scene must load.")
		return

	var area: StreetArtArea = packed.instantiate() as StreetArtArea
	if area == null:
		failures.append("Street art area must instantiate.")
		return

	var required_nodes: Array[String] = [
		"WorldObjects/Elias",
		"WorldObjects/TownEntranceSign",
		"WorldObjects/SaloonFacade",
		"WorldObjects/NightStatue",
		"WorldObjects/MarkedCartridge",
		"WorldObjects/PartnerMedallion",
		"WorldObjects/CultBrawlerStreet",
		"WorldObjects/GunslingerOptional",
		"Exits/ToChurchExit",
		"Solids/PlatformA",
		"Solids/PlatformB",
	]
	for node_path in required_nodes:
		if area.get_node_or_null(node_path) == null:
			failures.append("Beta street missing gameplay node: %s." % node_path)

	area.free()


func _test_narrative_decals_present(failures: PackedStringArray) -> void:
	var profile := load(PROFILE_PATH) as EnvironmentVisualProfile
	if profile == null:
		failures.append("Street profile must load for narrative decal test.")
		return

	var presentation := PresentationScript.new() as StreetArtPresentation
	presentation.build_on_ready = false
	presentation.profile = profile
	presentation.build_layers()

	var props := presentation.get_node_or_null(PresentationScript.LAYER_PROPS) as Node2D
	if props == null:
		failures.append("Props layer must exist after beta build.")
		presentation.free()
		return

	var themes: Dictionary = {}
	for child in props.get_children():
		if not String(child.name).begins_with("Narrative_"):
			continue
		for entry in Layout.get_narrative_decals(
			Factory.ground_anchor_y(profile)
		):
			if child.name == "Narrative_%s" % entry["id"]:
				themes[entry["theme"]] = true

	for required_theme in ["fear", "order", "partner", "mining", "vermilite", "resistance"]:
		if not themes.has(required_theme):
			failures.append("Beta street missing narrative decal theme: %s." % required_theme)

	presentation.free()
