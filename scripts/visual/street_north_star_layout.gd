extends RefCounted
class_name StreetNorthStarLayout

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

## Data-driven districts and placements for the beta North Star street (2400px).

enum District {
	ENTRANCE,
	ELIAS_SQUARE,
	SALOON_ROW,
	STATUE_ALLEY,
	SECRET_ROUTE,
	OPTIONAL_ROUTE,
	STREET_ARENA,
	DUO_ALLEY,
	CHURCH_APPROACH,
}


static func get_districts() -> Array[Dictionary]:
	return [
		{
			"id": District.ENTRANCE,
			"x_min": 0.0,
			"x_max": 220.0,
			"label": "Entrada da cidade",
			"theme": "arrival",
		},
		{
			"id": District.ELIAS_SQUARE,
			"x_min": 200.0,
			"x_max": 420.0,
			"label": "Encontro com Elias",
			"theme": "resistance",
		},
		{
			"id": District.SALOON_ROW,
			"x_min": 240.0,
			"x_max": 520.0,
			"label": "Saloon",
			"theme": "decay",
		},
		{
			"id": District.STATUE_ALLEY,
			"x_min": 460.0,
			"x_max": 620.0,
			"label": "Estátua e pista",
			"theme": "order",
		},
		{
			"id": District.SECRET_ROUTE,
			"x_min": 520.0,
			"x_max": 760.0,
			"label": "Segredo elevado",
			"theme": "partner",
		},
		{
			"id": District.OPTIONAL_ROUTE,
			"x_min": 760.0,
			"x_max": 1180.0,
			"label": "Rota opcional",
			"theme": "vermilite",
		},
		{
			"id": District.STREET_ARENA,
			"x_min": 1180.0,
			"x_max": 1520.0,
			"label": "Arena da rua",
			"theme": "combat",
		},
		{
			"id": District.DUO_ALLEY,
			"x_min": 1500.0,
			"x_max": 2080.0,
			"label": "Beco do duo",
			"theme": "cult",
		},
		{
			"id": District.CHURCH_APPROACH,
			"x_min": 2040.0,
			"x_max": 2400.0,
			"label": "Saída para igreja",
			"theme": "church",
		},
	]


static func district_at_x(x: float) -> District:
	for entry in get_districts():
		if x >= float(entry["x_min"]) and x < float(entry["x_max"]):
			return entry["id"] as District
	return District.CHURCH_APPROACH


static func get_interactable_markers(ground_y: float) -> Array[Dictionary]:
	return [
		{"id": "elias", "pos": Vector2(260, ground_y), "color": Color(0.72, 0.62, 0.42, 0.22)},
		{"id": "secret", "pos": Vector2(560, ground_y - 88), "color": Color(0.55, 0.42, 0.62, 0.2)},
		{"id": "statue", "pos": Vector2(520, ground_y), "color": Color(0.62, 0.52, 0.38, 0.18)},
		{"id": "combat", "pos": Vector2(1280, ground_y), "color": Color(0.82, 0.32, 0.22, 0.18)},
		{"id": "partner_clue", "pos": Vector2(1380, ground_y), "color": Color(0.78, 0.55, 0.32, 0.2)},
		{"id": "church_exit", "pos": Vector2(2320, ground_y), "color": Color(0.48, 0.38, 0.32, 0.22)},
	]


static func get_building_specs(ground_y: float) -> Array[Dictionary]:
	return [
		{
			"name": "EntranceGate",
			"pos": Vector2(100, ground_y),
			"w": 96.0,
			"h": 72.0,
			"roof": 12.0,
			"variant": 0,
			"lit": false,
			"district": District.ENTRANCE,
		},
		{
			"name": "ClosedShopA",
			"pos": Vector2(1680, ground_y - 48),
			"w": 128.0,
			"h": 96.0,
			"roof": 14.0,
			"variant": 1,
			"lit": false,
			"district": District.DUO_ALLEY,
		},
		{
			"name": "ClosedShopB",
			"pos": Vector2(1920, ground_y - 52),
			"w": 112.0,
			"h": 104.0,
			"roof": 16.0,
			"variant": 2,
			"lit": false,
			"district": District.CHURCH_APPROACH,
		},
		{
			"name": "MiningOffice",
			"pos": Vector2(1480, ground_y - 44),
			"w": 136.0,
			"h": 88.0,
			"roof": 12.0,
			"variant": 3,
			"lit": true,
			"district": District.STREET_ARENA,
		},
	]


static func get_narrative_decals(ground_y: float) -> Array[Dictionary]:
	return [
		{"id": "missing_poster", "pos": Vector2(150, ground_y - 58), "kind": "poster", "theme": "fear"},
		{"id": "order_chalk", "pos": Vector2(340, ground_y - 6), "kind": "chalk_heart", "theme": "order"},
		{"id": "boot_prints", "pos": Vector2(200, ground_y - 2), "kind": "tracks", "theme": "partner"},
		{"id": "mine_cart_wheel", "pos": Vector2(920, ground_y - 4), "kind": "mining", "theme": "mining"},
		{"id": "resistance_scratch", "pos": Vector2(440, ground_y - 40), "kind": "scratch", "theme": "resistance"},
		{"id": "vermilite_splinter", "pos": Vector2(1020, ground_y - 8), "kind": "vermilite", "theme": "vermilite"},
		{"id": "poverty_crate", "pos": Vector2(1560, ground_y - 6), "kind": "debris", "theme": "poverty"},
		{"id": "church_candles", "pos": Vector2(2180, ground_y - 36), "kind": "ritual", "theme": "order"},
		{"id": "arena_scuff", "pos": Vector2(1260, ground_y - 4), "kind": "scuff", "theme": "combat"},
		{"id": "duo_warning", "pos": Vector2(1620, ground_y - 50), "kind": "sign_order", "theme": "cult"},
	]


static func get_kit_module_placements(ground_y: float) -> Array[Dictionary]:
	var art_base := "res://art/environments/chapter_zero/modules/"
	return [
		{"module": &"sign", "pos": Vector2(88, ground_y), "path": art_base + "street_mod_sign.png", "size": Vector2(32, 16)},
		{"module": &"balcony", "pos": Vector2(300, ground_y - 64), "path": art_base + "street_mod_balcony.png", "size": Vector2(48, 24)},
		{"module": &"door", "pos": Vector2(286, ground_y), "path": art_base + "street_mod_door.png", "size": Vector2(24, 44)},
		{"module": &"window", "pos": Vector2(330, ground_y - 40), "path": art_base + "street_mod_window.png", "size": Vector2(16, 20)},
		{"module": &"window", "pos": Vector2(690, ground_y - 36), "path": art_base + "street_mod_window.png", "size": Vector2(16, 20)},
		{"module": &"barrel", "pos": Vector2(1220, ground_y - 2), "path": art_base + "street_mod_barrel.png", "size": Vector2(16, 20)},
		{"module": &"crate", "pos": Vector2(1340, ground_y - 2), "path": art_base + "street_mod_crate.png", "size": Vector2(24, 18)},
		{"module": &"fence", "pos": Vector2(1510, ground_y - 8), "path": art_base + "street_mod_fence.png", "size": Vector2(64, 32)},
		{"module": &"lantern", "pos": Vector2(1780, ground_y), "path": art_base + "street_mod_lantern.png", "size": Vector2(16, 24)},
		{"module": &"wagon", "pos": Vector2(1080, ground_y - 20), "path": art_base + "street_mod_wagon.png", "size": Vector2(96, 64)},
		{"module": &"lamp_post", "pos": Vector2(2050, ground_y), "path": art_base + "street_mod_lamp_post.png", "size": Vector2(24, 96)},
	]


static func get_district_ground_tints() -> Dictionary:
	return {
		District.ENTRANCE: Palette.EARTH_MID,
		District.ELIAS_SQUARE: Palette.WOOD_MID,
		District.SALOON_ROW: Palette.WOOD_DARK,
		District.STATUE_ALLEY: Palette.ORDER_RITUAL_STONE,
		District.SECRET_ROUTE: Palette.EARTH_DARK,
		District.OPTIONAL_ROUTE: Palette.DUST_WARM,
		District.STREET_ARENA: Palette.EARTH_DARK,
		District.DUO_ALLEY: Palette.ORDER_BLACK,
		District.CHURCH_APPROACH: Palette.STONE_GREY,
	}
