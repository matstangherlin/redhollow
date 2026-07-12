extends Resource
class_name EnvironmentTileSpec

## Data-only tile definition for modular environment kits.

enum TileRole {
	TERRAIN,
	TRANSITION,
	VARIATION,
	BORDER,
	CORNER,
	AUTOTILE,
	DECORATION,
}

@export var tile_id: StringName = &""
@export var display_name: String = ""
@export var role: TileRole = TileRole.TERRAIN
@export var terrain_id: StringName = &""
@export var atlas_coords: Vector2i = Vector2i.ZERO
@export var size_px: Vector2i = Vector2i(16, 16)
@export var autotile_terrain_set: int = 0
@export var autotile_terrain: int = 0
@export var variation_index: int = 0
@export var expected_texture_path: String = ""
@export var has_collision: bool = false
@export var notes: String = ""
