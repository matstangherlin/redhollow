extends RefCounted
class_name UndergroundNorthStarLayout

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

## Five visual progression zones for Chapter Zero catacombs (1200px).

enum Zone {
	HUMAN_INFRA,
	ORDER_TUNNELS,
	ANCIENT_RUINS,
	MOL_PRISON,
	SPIRITUAL_MANIFESTATION,
}


static func get_zones() -> Array[Dictionary]:
	return [
		{"id": Zone.HUMAN_INFRA, "x_min": 0.0, "x_max": 240.0, "label": "Infraestrutura humana", "stage": 1},
		{"id": Zone.ORDER_TUNNELS, "x_min": 220.0, "x_max": 480.0, "label": "Túneis da Ordem", "stage": 2},
		{"id": Zone.ANCIENT_RUINS, "x_min": 460.0, "x_max": 720.0, "label": "Ruínas antigas", "stage": 3},
		{"id": Zone.MOL_PRISON, "x_min": 700.0, "x_max": 960.0, "label": "Prisão de Mol-Khar", "stage": 4},
		{"id": Zone.SPIRITUAL_MANIFESTATION, "x_min": 940.0, "x_max": 1200.0, "label": "Manifestação espiritual", "stage": 5},
	]


static func get_interactable_markers(ground_y: float) -> Array[Dictionary]:
	return [
		{"id": "church_exit", "pos": Vector2(40, ground_y), "color": Color(0.48, 0.38, 0.32, 0.2)},
		{"id": "checkpoint", "pos": Vector2(220, ground_y), "color": Color(0.72, 0.62, 0.42, 0.18)},
		{"id": "partner_clue", "pos": Vector2(420, ground_y), "color": Color(0.78, 0.55, 0.32, 0.2)},
		{"id": "boss_arena", "pos": Vector2(520, ground_y), "color": Color(0.82, 0.32, 0.22, 0.22)},
		{"id": "deacon_rusk", "pos": Vector2(780, ground_y), "color": Color(0.62, 0.18, 0.14, 0.24)},
		{"id": "colossal_statue", "pos": Vector2(980, ground_y - 148), "color": Color(0.55, 0.12, 0.1, 0.22)},
		{"id": "hidden_passage", "pos": Vector2(1080, ground_y - 28), "color": Color(0.72, 0.28, 0.16, 0.24)},
	]


static func get_narrative_decals(ground_y: float) -> Array[Dictionary]:
	return [
		{"id": "wood_shoring", "pos": Vector2(140, ground_y - 48), "kind": "wood_support", "theme": "infra"},
		{"id": "order_chains", "pos": Vector2(320, ground_y - 40), "kind": "chains", "theme": "order"},
		{"id": "candle_niche", "pos": Vector2(380, ground_y - 56), "kind": "candles", "theme": "ritual"},
		{"id": "ancient_glyph", "pos": Vector2(540, ground_y - 44), "kind": "glyph", "theme": "ancient"},
		{"id": "bone_vestige", "pos": Vector2(620, ground_y - 4), "kind": "bones", "theme": "fear"},
		{"id": "root_intrusion", "pos": Vector2(500, ground_y - 20), "kind": "roots", "theme": "ancient"},
		{"id": "vermilite_vein", "pos": Vector2(820, ground_y - 8), "kind": "vermilite", "theme": "vermilite"},
		{"id": "prison_altar", "pos": Vector2(880, ground_y - 16), "kind": "altar", "theme": "mol"},
		{"id": "heart_symbol", "pos": Vector2(700, ground_y - 6), "kind": "heart", "theme": "order"},
	]


static func get_kit_module_placements(ground_y: float) -> Array[Dictionary]:
	var art_base := "res://art/environments/chapter_zero/modules/"
	return [
		{"module": &"timber", "pos": Vector2(120, ground_y - 32), "path": art_base + "underground_mod_timber.png", "size": Vector2(48, 32)},
		{"module": &"chain", "pos": Vector2(300, ground_y - 24), "path": art_base + "underground_mod_chain.png", "size": Vector2(32, 48)},
		{"module": &"candle", "pos": Vector2(360, ground_y - 48), "path": art_base + "underground_mod_candle.png", "size": Vector2(12, 20)},
		{"module": &"root", "pos": Vector2(580, ground_y - 16), "path": art_base + "underground_mod_root.png", "size": Vector2(40, 24)},
		{"module": &"bone", "pos": Vector2(640, ground_y - 4), "path": art_base + "underground_mod_bone.png", "size": Vector2(24, 12)},
		{"module": &"vermilite", "pos": Vector2(840, ground_y - 12), "path": art_base + "underground_mod_vermilite.png", "size": Vector2(16, 24)},
		{"module": &"altar", "pos": Vector2(900, ground_y - 20), "path": art_base + "underground_mod_altar.png", "size": Vector2(48, 32)},
		{"module": &"statue", "pos": Vector2(980, ground_y - 120), "path": art_base + "underground_mod_colossal_statue.png", "size": Vector2(160, 200)},
		{"module": &"passage", "pos": Vector2(1080, ground_y - 24), "path": art_base + "underground_mod_passage.png", "size": Vector2(64, 56)},
	]


static func get_zone_ground_tints() -> Dictionary:
	return {
		Zone.HUMAN_INFRA: Palette.STONE_GREY,
		Zone.ORDER_TUNNELS: Palette.ORDER_RITUAL_STONE,
		Zone.ANCIENT_RUINS: Palette.EARTH_DARK,
		Zone.MOL_PRISON: Palette.VERMILITE_SHADOW,
		Zone.SPIRITUAL_MANIFESTATION: Palette.MOL_STONE_BLACK,
	}
