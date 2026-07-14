extends RefCounted
class_name StreetFinalSampleSpec

## Localized near-final visual sample for Cap. Zero street.
## Does NOT finalize the full 2400 px road, church, or catacombs.

## Inclusive sample band (world X). Width = 800 px (within 600–900 requirement).
const SAMPLE_X_MIN := 100.0
const SAMPLE_X_MAX := 900.0
const SAMPLE_WIDTH_PX := 800.0

## Camera crop for comparison screenshots / sample test scene.
const SAMPLE_CAMERA_LIMITS := Rect2(100, 200, 800, 1000)

## Clear label prefix so candidates are never mistaken for shipped PNG art.
const PLACEHOLDER_TAG := "PLACEHOLDER_CANDIDATE"

const MODE_GREYBOX := &"greybox"
const MODE_NORTH_STAR := &"north_star"
const MODE_FINAL_CANDIDATE := &"final_candidate"

## Approved mold: sample band remains the readability reference; full street uses FinalMoldComposer.
const MOLD_APPROVED := true
const MOLD_DOC := "docs/ART_VERTICAL_SLICE_GATE.md"

const MODE_CYCLE: PackedStringArray = [
	MODE_GREYBOX,
	MODE_NORTH_STAR,
	MODE_FINAL_CANDIDATE,
]


static func contains_x(world_x: float) -> bool:
	return world_x >= SAMPLE_X_MIN and world_x <= SAMPLE_X_MAX


static func get_band_rect(ground_y: float) -> Rect2:
	return Rect2(SAMPLE_X_MIN, ground_y - 420.0, SAMPLE_WIDTH_PX, 460.0)


static func get_element_checklist() -> Array[Dictionary]:
	## Coordinates match vertical_slice_street_art + North Star layout,
	## except Cult Brawler showcase which is sample-only at X=820.
	return [
		{"id": "calder_spawn", "x": 120.0, "in_band": true, "source": "Spawns/DefaultSpawn"},
		{"id": "lamp", "x": 180.0, "in_band": true, "source": "factory lamp + sample upgrade"},
		{"id": "elias", "x": 260.0, "in_band": true, "source": "WorldObjects/Elias"},
		{"id": "saloon_facade", "x": 300.0, "in_band": true, "source": "SaloonFacade + sample wood detail"},
		{"id": "secret_cache", "x": 480.0, "in_band": true, "source": "WorldObjects/SecretCache"},
		{"id": "statue", "x": 520.0, "in_band": true, "source": "NightStatue"},
		{"id": "elevated_platform", "x": 560.0, "in_band": true, "source": "Solids/PlatformA"},
		{"id": "interactive_saloon", "x": 300.0, "in_band": true, "source": "cz_saloon_facade"},
		{"id": "cult_brawler_showcase", "x": 740.0, "in_band": true, "source": "sample silhouette (production brawler stays at 1280)"},
		{"id": "mountains_sunset", "x": 500.0, "in_band": true, "source": "Layer01/02 parallax (visible anywhere)"},
		{"id": "production_brawler_arena", "x": 1280.0, "in_band": false, "source": "CultBrawlerStreet remains for full street"},
	]


static func get_mood_targets() -> PackedStringArray:
	return PackedStringArray([
		"faroeste_decadente",
		"anime",
		"ordem_coracao_rubro",
		"vermilite",
		"misterio",
		"terror_religioso",
		"combate_estilizado",
	])


static func mode_display_name(mode: StringName) -> String:
	match mode:
		MODE_GREYBOX:
			return "GREYBOX"
		MODE_NORTH_STAR:
			return "NORTH STAR (procedural)"
		MODE_FINAL_CANDIDATE:
			return "FINAL MOLD (full street 0–2400)"
		_:
			return String(mode)


static func next_mode(current: StringName) -> StringName:
	var idx := MODE_CYCLE.find(String(current))
	if idx < 0:
		return MODE_NORTH_STAR
	return StringName(MODE_CYCLE[(idx + 1) % MODE_CYCLE.size()])
