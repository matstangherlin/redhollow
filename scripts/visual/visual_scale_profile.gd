extends Resource
class_name VisualScaleProfile

## Lab-only scale candidate. Does NOT affect gameplay collision or AttackData.

@export var profile_id: StringName = &"scale_32x56"
@export var display_name: String = "32 × 56 (baseline)"
@export var frame_size: Vector2i = Vector2i(32, 56)
@export var pivot: Vector2 = Vector2(16, 56)
@export var sprite_visual_offset: Vector2 = Vector2(0, -28)
@export var red_brand_zone_px: Vector2i = Vector2i(12, 12)
@export var hat_readable_min_px: int = 4
@export var coat_hem_extra_px: int = 4

## Base enemy sprite heights at 56 px Calder reference (CHARACTER_SCALE_GUIDE).
@export var enemy_height_brawler: int = 56
@export var enemy_height_gunslinger: int = 54
@export var enemy_height_deacon: int = 72

## Relative animation pixel cost vs 32×56 baseline (frames × canvas area).
@export var animation_cost_multiplier: float = 1.0

@export_multiline var study_notes: String = ""


func get_scale_factor_vs_baseline() -> float:
	return float(frame_size.y) / 56.0


func get_enemy_height(enemy_id: StringName) -> int:
	var base_h := enemy_height_brawler
	match enemy_id:
		&"gunslinger":
			base_h = enemy_height_gunslinger
		&"deacon":
			base_h = enemy_height_deacon
	return int(round(float(base_h) * get_scale_factor_vs_baseline()))


func get_collision_mismatch_px() -> Vector2i:
	var gameplay_collision := Vector2i(32, 56)
	return Vector2i(
		frame_size.x - gameplay_collision.x,
		frame_size.y - gameplay_collision.y
	)
