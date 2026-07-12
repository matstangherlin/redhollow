extends Resource
class_name EnvironmentVisualProfile

## Canonical visual + performance contract for an environment art slice.

@export var profile_id: StringName = &"chapter_zero_street"
@export var area_display_name: String = "Rua de Red Hollow — Art Slice"
@export var target_area_id: StringName = &"vs_greybox_street"

@export_group("Resolution")
@export var logical_resolution: Vector2i = Vector2i(480, 270)
@export var window_reference_size: Vector2i = Vector2i(1920, 1080)
@export var pixels_per_unit: int = 1
@export var tile_size_px: int = 16
@export var texture_filter: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_NEAREST
@export var stretch_mode: String = "canvas_items"
@export var stretch_aspect: String = "expand"

@export_group("Characters")
@export var calder_sprite_size: Vector2i = Vector2i(32, 56)
@export var enemy_scale_notes: String = (
	"Brawler 56h, Gunslinger 54h, Penitent 58h — ver CHARACTER_SCALE_GUIDE.md"
)

@export_group("Playfield")
@export var playfield_width_px: float = 2400.0
@export var ground_surface_y: float = 876.0
@export var camera_limits: Rect2 = Rect2(0.0, 200.0, 2400.0, 1000.0)

@export_group("Parallax")
@export var parallax_scroll_limits: Vector2 = Vector2(0.45, 0.0)
@export var layer_scroll_scales: Dictionary = {
	"sky": 0.05,
	"mountains": 0.12,
	"city_silhouette": 0.22,
	"mid_buildings": 0.38,
	"playfield": 1.0,
	"props": 1.0,
	"foreground": 1.05,
	"atmosphere": 1.0,
}

@export_group("Performance Budget")
@export var max_draw_calls: int = 80
@export var max_point_lights: int = 6
@export var max_particle_count: int = 180
@export var max_texture_atlas_size: int = 2048
@export var max_parallax_layers: int = 5
@export var max_art_layers: int = 9


func get_performance_budget() -> Dictionary:
	return {
		"draw_calls": max_draw_calls,
		"point_lights": max_point_lights,
		"particles": max_particle_count,
		"texture_atlas_px": max_texture_atlas_size,
		"parallax_layers": max_parallax_layers,
		"art_layers": max_art_layers,
	}


func get_resolution_contract() -> Dictionary:
	return {
		"logical_resolution": logical_resolution,
		"window_reference_size": window_reference_size,
		"pixels_per_unit": pixels_per_unit,
		"tile_size_px": tile_size_px,
		"texture_filter": "nearest",
		"stretch_mode": stretch_mode,
		"stretch_aspect": stretch_aspect,
		"calder_sprite_size": calder_sprite_size,
	}
