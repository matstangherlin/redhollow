extends RefCounted
class_name StreetNorthStarVariants

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

## Deterministic visual variants for North Star procedural modules.


static func pick_variant(seed_key: String, count: int) -> int:
	if count <= 1:
		return 0
	return int(abs(seed_key.hash()) % count)


static func wall_color_for_variant(variant: int) -> Color:
	match variant % 4:
		0:
			return Palette.WOOD_MID
		1:
			return Palette.WOOD_DARK
		2:
			return Palette.STONE_GREY
		_:
			return Palette.ORDER_RITUAL_STONE


static func roof_color_for_variant(variant: int) -> Color:
	match variant % 3:
		0:
			return Color(0.22, 0.16, 0.14, 1.0)
		1:
			return Color(0.18, 0.12, 0.11, 1.0)
		_:
			return Palette.ORDER_BLACK.lightened(0.08)


static func roof_height_for_variant(variant: int) -> float:
	return 12.0 + float(variant % 3) * 4.0


static func window_offsets_for_variant(variant: int, width: float) -> Array[float]:
	match variant % 3:
		0:
			return [-width * 0.28, width * 0.08, width * 0.32]
		1:
			return [-width * 0.22, width * 0.22]
		_:
			return [-width * 0.35, 0.0, width * 0.35]
	return [0.0]


static func door_offset_for_variant(variant: int) -> float:
	return -14.0 + float(variant % 3) * 8.0
