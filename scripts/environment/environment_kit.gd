extends Resource
class_name EnvironmentKit

## Reusable environment module catalog for a biome / district kit.

@export var kit_id: StringName = &"chapter_zero_street"
@export var display_name: String = "Capítulo Zero — Kit da Rua"
@export var parent_kit_id: StringName = &""
@export var region_theme_id: StringName = &"chapter_zero_street"
@export var tile_size_px: int = 16
@export var atlas_path: String = "res://art/environments/chapter_zero/street_tileset_atlas.png"
@export var modules: Array[EnvironmentModuleDef] = []
@export var tile_specs: Array[EnvironmentTileSpec] = []


func ensure_built_in() -> void:
	if not modules.is_empty():
		return
	EnvironmentKitFactory.populate_street_kit(self)


func get_module(module_id: StringName) -> EnvironmentModuleDef:
	ensure_built_in()
	for module in modules:
		if module.module_id == module_id:
			return module
	return null


func get_modules_for_category(category: EnvironmentLayerCategory.Category) -> Array[EnvironmentModuleDef]:
	ensure_built_in()
	var result: Array[EnvironmentModuleDef] = []
	for module in modules:
		if module.category == category:
			result.append(module)
	return result


func get_tile_spec(tile_id: StringName) -> EnvironmentTileSpec:
	ensure_built_in()
	for spec in tile_specs:
		if spec.tile_id == tile_id:
			return spec
	return null


func list_expected_asset_paths() -> PackedStringArray:
	ensure_built_in()
	var paths: PackedStringArray = PackedStringArray()
	if not atlas_path.is_empty():
		paths.append(atlas_path)
	for module in modules:
		if not module.expected_asset_path.is_empty():
			paths.append(module.expected_asset_path)
	for spec in tile_specs:
		if not spec.expected_texture_path.is_empty():
			paths.append(spec.expected_texture_path)
	return paths
