extends RefCounted
class_name RedHollowPalette

## Canonical color groups for Red Hollow regions — presentation only.


# --- Base faroeste ---
const WOOD_DARK := Color(0.32, 0.22, 0.14, 1.0)
const WOOD_MID := Color(0.44, 0.3, 0.2, 1.0)
const EARTH_DARK := Color(0.28, 0.2, 0.14, 1.0)
const EARTH_MID := Color(0.36, 0.26, 0.18, 1.0)
const DUST_WARM := Color(0.62, 0.38, 0.2, 1.0)
const LEATHER := Color(0.42, 0.28, 0.18, 1.0)
const METAL_COOL := Color(0.38, 0.34, 0.32, 1.0)
const STONE_GREY := Color(0.38, 0.34, 0.32, 1.0)
const FABRIC_TAN := Color(0.52, 0.4, 0.28, 1.0)
const SUNSET_ORANGE := Color(0.96, 0.52, 0.18, 1.0)
const SUNSET_SKY_TOP := Color(0.18, 0.12, 0.22, 1.0)
const SUNSET_SKY_MID := Color(0.42, 0.2, 0.16, 1.0)

# --- Ordem do Coração Rubro ---
const ORDER_BLACK := Color(0.1, 0.08, 0.09, 1.0)
const ORDER_BURNT_RED := Color(0.78, 0.12, 0.1, 1.0)
const ORDER_DEEP_RED := Color(0.52, 0.1, 0.1, 1.0)
const ORDER_AGED_CREAM := Color(0.82, 0.72, 0.58, 1.0)
const ORDER_RITUAL_STONE := Color(0.34, 0.3, 0.28, 1.0)

# --- Vermilite ---
const VERMILITE_CORE := Color(0.98, 0.42, 0.22, 1.0)
const VERMILITE_SATURATED := Color(0.92, 0.18, 0.12, 1.0)
const VERMILITE_HALO := Color(0.95, 0.28, 0.14, 0.55)
const VERMILITE_SHADOW := Color(0.42, 0.08, 0.08, 1.0)

# --- Mol-Khar ---
const MOL_STONE_BLACK := Color(0.06, 0.04, 0.05, 1.0)
const MOL_INNER_RED := Color(0.62, 0.08, 0.06, 1.0)
const MOL_VOID := Color(0.04, 0.03, 0.04, 1.0)
const MOL_ABNORMAL_SHADOW := Color(0.12, 0.02, 0.04, 0.85)

# --- Combate / feedback (referência) ---
const COMBAT_FLASH := Color(0.95, 0.88, 0.72, 0.85)
const COMBAT_IMPACT_HEAVY := Color(0.98, 0.42, 0.18, 0.9)


static func get_group_summary() -> Dictionary:
	return {
		"western_base": [
			"wood_dark", "wood_mid", "earth_dark", "earth_mid", "dust_warm",
			"leather", "metal_cool", "stone_grey", "fabric_tan", "sunset_orange",
		],
		"order_of_red_heart": [
			"order_black", "order_burnt_red", "order_deep_red", "order_aged_cream", "order_ritual_stone",
		],
		"vermilite": ["vermilite_core", "vermilite_saturated", "vermilite_halo", "vermilite_shadow"],
		"mol_khar": ["mol_stone_black", "mol_inner_red", "mol_void", "mol_abnormal_shadow"],
	}


static func get_color(group: StringName, key: String) -> Color:
	match String(group):
		"western_base":
			match key:
				"wood_dark": return WOOD_DARK
				"wood_mid": return WOOD_MID
				"earth_dark": return EARTH_DARK
				"earth_mid": return EARTH_MID
				"dust_warm": return DUST_WARM
				"leather": return LEATHER
				"metal_cool": return METAL_COOL
				"stone_grey": return STONE_GREY
				"fabric_tan": return FABRIC_TAN
				"sunset_orange": return SUNSET_ORANGE
		"order":
			match key:
				"black": return ORDER_BLACK
				"burnt_red": return ORDER_BURNT_RED
				"deep_red": return ORDER_DEEP_RED
				"aged_cream": return ORDER_AGED_CREAM
				"ritual_stone": return ORDER_RITUAL_STONE
		"vermilite":
			match key:
				"core": return VERMILITE_CORE
				"saturated": return VERMILITE_SATURATED
				"halo": return VERMILITE_HALO
				"shadow": return VERMILITE_SHADOW
		"mol_khar":
			match key:
				"stone_black": return MOL_STONE_BLACK
				"inner_red": return MOL_INNER_RED
				"void": return MOL_VOID
				"abnormal_shadow": return MOL_ABNORMAL_SHADOW
	return Color.MAGENTA
