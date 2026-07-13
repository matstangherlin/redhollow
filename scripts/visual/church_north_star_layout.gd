extends RefCounted
class_name ChurchNorthStarLayout

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

## Districts and placements for the church North Star slice (1800px).

enum District {
	STREET_APPROACH,
	PENITENT_ALCOVE,
	ORDER_PLAZA,
	ARENA_SQUARE,
	RED_BRAND_CORRIDOR,
	UNDERGROUND_GATE,
}


static func get_districts() -> Array[Dictionary]:
	return [
		{"id": District.STREET_APPROACH, "x_min": 0.0, "x_max": 180.0, "label": "Chegada da rua", "theme": "threshold"},
		{"id": District.PENITENT_ALCOVE, "x_min": 160.0, "x_max": 420.0, "label": "Alcova do Penitente", "theme": "punishment"},
		{"id": District.ORDER_PLAZA, "x_min": 400.0, "x_max": 720.0, "label": "Praça da Ordem", "theme": "ritual"},
		{"id": District.ARENA_SQUARE, "x_min": 700.0, "x_max": 1120.0, "label": "Pátio da arena", "theme": "combat"},
		{"id": District.RED_BRAND_CORRIDOR, "x_min": 1100.0, "x_max": 1400.0, "label": "Corredor Red Brand", "theme": "vermilite"},
		{"id": District.UNDERGROUND_GATE, "x_min": 1380.0, "x_max": 1800.0, "label": "Portão subterrâneo", "theme": "descent"},
	]


static func get_interactable_markers(ground_y: float) -> Array[Dictionary]:
	return [
		{"id": "street_exit", "pos": Vector2(40, ground_y), "color": Color(0.48, 0.42, 0.38, 0.2)},
		{"id": "penitent", "pos": Vector2(320, ground_y), "color": Color(0.62, 0.22, 0.18, 0.22)},
		{"id": "checkpoint", "pos": Vector2(480, ground_y), "color": Color(0.72, 0.62, 0.42, 0.18)},
		{"id": "order_document", "pos": Vector2(640, ground_y), "color": Color(0.58, 0.48, 0.38, 0.2)},
		{"id": "arena", "pos": Vector2(500, ground_y), "color": Color(0.82, 0.32, 0.22, 0.2)},
		{"id": "red_brand_passage", "pos": Vector2(880, ground_y), "color": Color(0.78, 0.18, 0.12, 0.24)},
		{"id": "red_brand_cache", "pos": Vector2(1020, ground_y), "color": Color(0.72, 0.28, 0.16, 0.22)},
		{"id": "cult_gate", "pos": Vector2(1150, ground_y), "color": Color(0.52, 0.1, 0.1, 0.24)},
		{"id": "shortcut", "pos": Vector2(1260, ground_y), "color": Color(0.55, 0.42, 0.32, 0.2)},
		{"id": "underground_exit", "pos": Vector2(1500, ground_y), "color": Color(0.38, 0.28, 0.24, 0.26)},
	]


static func get_building_specs(ground_y: float) -> Array[Dictionary]:
	return [
		{"name": "ClosedRectory", "pos": Vector2(220, ground_y - 52), "w": 112.0, "h": 128.0, "roof": 20.0, "variant": 0, "lit": false},
		{"name": "ClosedScriptorium", "pos": Vector2(760, ground_y - 48), "w": 136.0, "h": 140.0, "roof": 22.0, "variant": 1, "lit": false},
		{"name": "GuardPost", "pos": Vector2(1320, ground_y - 36), "w": 72.0, "h": 96.0, "roof": 14.0, "variant": 2, "lit": true},
	]


static func get_narrative_decals(ground_y: float) -> Array[Dictionary]:
	return [
		{"id": "order_banner", "pos": Vector2(120, ground_y - 64), "kind": "banner", "theme": "order"},
		{"id": "guard_shadow", "pos": Vector2(400, ground_y - 4), "kind": "guard", "theme": "order"},
		{"id": "chalk_ritual", "pos": Vector2(580, ground_y - 6), "kind": "chalk_circle", "theme": "ritual"},
		{"id": "vermilite_stone", "pos": Vector2(900, ground_y - 8), "kind": "vermilite_crack", "theme": "vermilite"},
		{"id": "closed_door_chain", "pos": Vector2(720, ground_y - 4), "kind": "chains", "theme": "fear"},
		{"id": "whisper_candle", "pos": Vector2(1080, ground_y - 40), "kind": "candles", "theme": "silence"},
		{"id": "mining_relic", "pos": Vector2(1420, ground_y - 6), "kind": "mining", "theme": "mining"},
		{"id": "resistance_scratch", "pos": Vector2(280, ground_y - 48), "kind": "scratch", "theme": "resistance"},
	]


static func get_kit_module_placements(ground_y: float) -> Array[Dictionary]:
	var art_base := "res://art/environments/chapter_zero/modules/"
	return [
		{"module": &"bell", "pos": Vector2(900, ground_y - 180), "path": art_base + "church_mod_bell.png", "size": Vector2(32, 48)},
		{"module": &"spire", "pos": Vector2(860, ground_y - 220), "path": art_base + "church_mod_spire.png", "size": Vector2(64, 160)},
		{"module": &"gate", "pos": Vector2(1150, ground_y - 8), "path": art_base + "church_mod_gate.png", "size": Vector2(48, 72)},
		{"module": &"altar", "pos": Vector2(680, ground_y - 12), "path": art_base + "church_mod_altar.png", "size": Vector2(56, 40)},
		{"module": &"statue", "pos": Vector2(560, ground_y - 8), "path": art_base + "church_mod_statue.png", "size": Vector2(32, 64)},
		{"module": &"entrance", "pos": Vector2(820, ground_y), "path": art_base + "church_mod_entrance.png", "size": Vector2(96, 120)},
		{"module": &"passage", "pos": Vector2(1500, ground_y - 16), "path": art_base + "church_mod_passage.png", "size": Vector2(64, 56)},
		{"module": &"lantern", "pos": Vector2(480, ground_y), "path": art_base + "street_mod_lantern.png", "size": Vector2(16, 24)},
		{"module": &"fence", "pos": Vector2(360, ground_y - 8), "path": art_base + "street_mod_fence.png", "size": Vector2(64, 32)},
		{"module": &"sign", "pos": Vector2(140, ground_y - 56), "path": art_base + "street_mod_sign.png", "size": Vector2(32, 16)},
	]


static func get_district_ground_tints() -> Dictionary:
	return {
		District.STREET_APPROACH: Palette.STONE_GREY,
		District.PENITENT_ALCOVE: Palette.ORDER_RITUAL_STONE,
		District.ORDER_PLAZA: Palette.ORDER_AGED_CREAM,
		District.ARENA_SQUARE: Palette.EARTH_DARK,
		District.RED_BRAND_CORRIDOR: Palette.VERMILITE_SHADOW,
		District.UNDERGROUND_GATE: Palette.ORDER_BLACK,
	}


static func get_set_piece_positions(ground_y: float) -> Dictionary:
	return {
		"bell_tower": Vector2(900, ground_y - 200),
		"main_entrance": Vector2(820, ground_y),
		"order_statue": Vector2(560, ground_y - 8),
		"external_altar": Vector2(680, ground_y - 12),
		"cult_gate": Vector2(1150, ground_y),
		"underground_passage": Vector2(1500, ground_y - 16),
	}
