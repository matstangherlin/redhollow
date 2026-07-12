extends Resource
class_name EnvironmentModuleDef

## One reusable environment module (tile strip, prop prefab, or hybrid).

enum ModuleKind {
	TILE_STRIP,
	PROP_SCENE,
	HYBRID,
	GAMEPLAY_PREFAB,
}

@export var module_id: StringName = &""
@export var display_name: String = ""
@export var kind: ModuleKind = ModuleKind.TILE_STRIP
@export var category: EnvironmentLayerCategory.Category = EnvironmentLayerCategory.Category.VISUAL
@export var footprint_tiles: Vector2i = Vector2i(1, 1)
@export var footprint_px: Vector2 = Vector2(16, 16)
@export var expected_asset_path: String = ""
@export var prop_scene_path: String = ""
@export var tile_spec_id: StringName = &""
@export var has_collision: bool = false
@export var has_light: bool = false
@export var has_interaction: bool = false
@export var has_destruction: bool = false
@export var has_audio: bool = false
@export var reusable: bool = true
@export var notes: String = ""
