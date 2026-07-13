extends RefCounted
class_name UndergroundNorthStarVariants

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")


static func tunnel_wall_for_stage(stage: int) -> Color:
	match stage:
		1:
			return Palette.STONE_GREY
		2:
			return Palette.ORDER_RITUAL_STONE
		3:
			return Palette.EARTH_DARK
		4:
			return Palette.VERMILITE_SHADOW
		_:
			return Palette.MOL_STONE_BLACK


static func support_wood_for_stage(stage: int) -> Color:
	return Palette.WOOD_DARK if stage <= 2 else Palette.WOOD_MID.darkened(0.25)


static func vermilite_intensity_for_x(x: float) -> float:
	return clampf((x - 480.0) / 520.0, 0.0, 1.0)
