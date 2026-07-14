extends RefCounted
class_name ChurchNorthStarVariants

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

## Vertical, ritual-heavy facade variants for the church district.


static func pick_variant(seed_key: String, count: int) -> int:
	if count <= 1:
		return 0
	var h := 0
	for i in range(seed_key.length()):
		h = (h * 31 + seed_key.unicode_at(i)) & 0x7fffffff
	return h % count


static func door_offset_for_variant(variant: int) -> float:
	match variant % 3:
		0:
			return 0.0
		1:
			return -8.0
		_:
			return 10.0


static func wall_color_for_variant(variant: int) -> Color:
	match variant % 4:
		0:
			return Palette.ORDER_RITUAL_STONE
		1:
			return Palette.STONE_GREY
		2:
			return Palette.ORDER_BLACK.lightened(0.12)
		_:
			return Palette.ORDER_AGED_CREAM.darkened(0.18)


static func roof_color_for_variant(variant: int) -> Color:
	match variant % 3:
		0:
			return Palette.ORDER_BLACK
		1:
			return Color(0.14, 0.1, 0.11, 1.0)
		_:
			return Palette.ORDER_DEEP_RED.darkened(0.2)


static func roof_height_for_variant(variant: int) -> float:
	return 18.0 + float(variant % 3) * 8.0


static func facade_height_multiplier(variant: int) -> float:
	return 1.0 + float(variant % 3) * 0.18


static func window_offsets_for_variant(variant: int, width: float) -> Array[float]:
	match variant % 3:
		0:
			return [-width * 0.22, width * 0.22]
		1:
			return [-width * 0.3, 0.0, width * 0.3]
		_:
			return [-width * 0.18, width * 0.18]


static func spire_height_for_variant(variant: int) -> float:
	return 120.0 + float(variant % 2) * 40.0
