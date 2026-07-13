extends RefCounted
class_name EnvironmentKitFactory

const ART_BASE := "res://art/environments/chapter_zero/"
const MODULES_BASE := "res://scenes/environment/modules/"


static func create_street_kit() -> EnvironmentKit:
	var kit := EnvironmentKit.new()
	kit.kit_id = &"chapter_zero_street"
	kit.display_name = "Capítulo Zero — Kit da Rua"
	kit.region_theme_id = &"chapter_zero_street"
	populate_street_kit(kit)
	return kit


static func populate_street_kit(kit: EnvironmentKit) -> void:
	kit.tile_size_px = 16
	kit.atlas_path = ART_BASE + "street_tileset_atlas.png"
	kit.tile_specs = _street_tile_specs()
	kit.modules = _street_modules()


static func _street_tile_specs() -> Array[EnvironmentTileSpec]:
	var specs: Array[EnvironmentTileSpec] = []
	_add_tile(specs, &"dirt_ground", "Chão de terra", EnvironmentTileSpec.TileRole.TERRAIN, &"dirt", Vector2i(0, 0))
	_add_tile(specs, &"wood_sidewalk", "Calçada de madeira", EnvironmentTileSpec.TileRole.TERRAIN, &"wood", Vector2i(1, 0))
	_add_tile(specs, &"platform_wood", "Plataforma", EnvironmentTileSpec.TileRole.TERRAIN, &"wood", Vector2i(2, 0), true)
	_add_tile(specs, &"roof_shingle", "Telhado", EnvironmentTileSpec.TileRole.DECORATION, &"wood", Vector2i(3, 0))
	_add_tile(specs, &"wall_wood", "Parede de madeira", EnvironmentTileSpec.TileRole.TERRAIN, &"wood", Vector2i(0, 1), true)
	_add_tile(specs, &"wall_stone", "Parede de pedra", EnvironmentTileSpec.TileRole.TERRAIN, &"stone", Vector2i(1, 1), true)
	_add_tile(specs, &"dirt_to_wood", "Transição terra→madeira", EnvironmentTileSpec.TileRole.TRANSITION, &"dirt", Vector2i(2, 1))
	_add_tile(specs, &"corner_stone", "Canto pedra", EnvironmentTileSpec.TileRole.CORNER, &"stone", Vector2i(3, 1), true)
	_add_tile(specs, &"border_ground", "Borda de chão", EnvironmentTileSpec.TileRole.BORDER, &"dirt", Vector2i(0, 2))
	_add_tile(specs, &"autotile_stone_wall", "Autotile parede pedra", EnvironmentTileSpec.TileRole.AUTOTILE, &"stone", Vector2i(1, 2), true)
	return specs


static func _street_modules() -> Array[EnvironmentModuleDef]:
	var modules: Array[EnvironmentModuleDef] = []
	_add_module(modules, &"dirt_ground", "Chão de terra", EnvironmentModuleDef.ModuleKind.TILE_STRIP,
		EnvironmentLayerCategory.Category.VISUAL, Vector2i(4, 1), &"dirt_ground", "street_mod_dirt_ground.png")
	_add_module(modules, &"wood_sidewalk", "Calçada de madeira", EnvironmentModuleDef.ModuleKind.TILE_STRIP,
		EnvironmentLayerCategory.Category.VISUAL, Vector2i(4, 1), &"wood_sidewalk", "street_mod_wood_sidewalk.png")
	_add_module(modules, &"platform", "Plataforma", EnvironmentModuleDef.ModuleKind.HYBRID,
		EnvironmentLayerCategory.Category.COLLISION, Vector2i(3, 1), &"platform_wood", "street_mod_platform.png", true)
	_add_module(modules, &"roof", "Telhado", EnvironmentModuleDef.ModuleKind.TILE_STRIP,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(4, 2), &"roof_shingle", "street_mod_roof.png")
	_add_module(modules, &"wall_wood", "Parede de madeira", EnvironmentModuleDef.ModuleKind.HYBRID,
		EnvironmentLayerCategory.Category.COLLISION, Vector2i(1, 3), &"wall_wood", "street_mod_wall_wood.png", true)
	_add_module(modules, &"wall_stone", "Parede de pedra", EnvironmentModuleDef.ModuleKind.HYBRID,
		EnvironmentLayerCategory.Category.COLLISION, Vector2i(1, 3), &"wall_stone", "street_mod_wall_stone.png", true)
	_add_module(modules, &"door", "Porta", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.INTERACTION, Vector2i(1, 2), &"", "street_mod_door.png", false,
		MODULES_BASE + "kit_door.tscn", false, true)
	_add_module(modules, &"window", "Janela", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(1, 1), &"", "street_mod_window.png", false,
		MODULES_BASE + "kit_window.tscn")
	_add_module(modules, &"balcony", "Varanda", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(3, 1), &"", "street_mod_balcony.png", false,
		MODULES_BASE + "kit_balcony.tscn")
	_add_module(modules, &"lamp_post", "Poste", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(1, 3), &"", "street_mod_lamp_post.png", false,
		MODULES_BASE + "kit_lamp_post.tscn")
	_add_module(modules, &"fence", "Cerca", EnvironmentModuleDef.ModuleKind.HYBRID,
		EnvironmentLayerCategory.Category.COLLISION, Vector2i(2, 1), &"", "street_mod_fence.png", true,
		MODULES_BASE + "kit_fence.tscn")
	_add_module(modules, &"barrel", "Barril", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(1, 1), &"", "street_mod_barrel.png", false,
		MODULES_BASE + "kit_barrel.tscn", false, false, true)
	_add_module(modules, &"crate", "Caixa", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(1, 1), &"", "street_mod_crate.png", false,
		MODULES_BASE + "kit_crate.tscn", false, false, true)
	_add_module(modules, &"wagon", "Carroça", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(3, 2), &"", "street_mod_wagon.png", false,
		MODULES_BASE + "kit_wagon.tscn")
	_add_module(modules, &"sign", "Placa", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.DECORATION, Vector2i(2, 1), &"", "street_mod_sign.png", false,
		MODULES_BASE + "kit_sign.tscn")
	_add_module(modules, &"lantern", "Lampião", EnvironmentModuleDef.ModuleKind.PROP_SCENE,
		EnvironmentLayerCategory.Category.LIGHTING, Vector2i(1, 2), &"", "street_mod_lantern.png", false,
		MODULES_BASE + "kit_lantern.tscn", true)
	_add_module(modules, &"stairs", "Escada", EnvironmentModuleDef.ModuleKind.HYBRID,
		EnvironmentLayerCategory.Category.COLLISION, Vector2i(2, 2), &"", "street_mod_stairs.png", true,
		MODULES_BASE + "kit_stairs.tscn")
	_add_module(modules, &"blocked_entrance", "Entrada bloqueada", EnvironmentModuleDef.ModuleKind.GAMEPLAY_PREFAB,
		EnvironmentLayerCategory.Category.GAMEPLAY, Vector2i(2, 3), &"", "street_mod_blocked_entrance.png", false,
		"res://scenes/world/narrative_gate.tscn", false, true)
	_add_module(modules, &"secret_passage", "Passagem secreta", EnvironmentModuleDef.ModuleKind.GAMEPLAY_PREFAB,
		EnvironmentLayerCategory.Category.GAMEPLAY, Vector2i(2, 2), &"", "street_mod_secret_passage.png", false,
		MODULES_BASE + "kit_secret_passage.tscn", false, true)
	_add_module(modules, &"vermilite_barrier", "Barreira Vermilite", EnvironmentModuleDef.ModuleKind.GAMEPLAY_PREFAB,
		EnvironmentLayerCategory.Category.GAMEPLAY, Vector2i(1, 4), &"", "street_mod_vermilite_barrier.png", false,
		"res://scenes/world/red_barrier.tscn", false, false, false, true)
	return modules


static func _add_tile(
	specs: Array[EnvironmentTileSpec],
	tile_id: StringName,
	display_name: String,
	role: EnvironmentTileSpec.TileRole,
	terrain_id: StringName,
	atlas_coords: Vector2i,
	has_collision: bool = false
) -> void:
	var spec := EnvironmentTileSpec.new()
	spec.tile_id = tile_id
	spec.display_name = display_name
	spec.role = role
	spec.terrain_id = terrain_id
	spec.atlas_coords = atlas_coords
	spec.size_px = Vector2i(16, 16)
	spec.expected_texture_path = ART_BASE + "street_tileset_atlas.png"
	spec.has_collision = has_collision
	specs.append(spec)


static func _add_module(
	modules: Array[EnvironmentModuleDef],
	module_id: StringName,
	display_name: String,
	kind: EnvironmentModuleDef.ModuleKind,
	category: EnvironmentLayerCategory.Category,
	footprint_tiles: Vector2i,
	tile_spec_id: StringName = &"",
	asset_file: String = "",
	has_collision: bool = false,
	prop_scene_path: String = "",
	has_light: bool = false,
	has_interaction: bool = false,
	has_destruction: bool = false,
	has_audio: bool = false
) -> void:
	var module := EnvironmentModuleDef.new()
	module.module_id = module_id
	module.display_name = display_name
	module.kind = kind
	module.category = category
	module.footprint_tiles = footprint_tiles
	module.footprint_px = Vector2(footprint_tiles) * 16.0
	module.tile_spec_id = tile_spec_id
	if not asset_file.is_empty():
		module.expected_asset_path = ART_BASE + "modules/" + asset_file
	module.has_collision = has_collision
	module.prop_scene_path = prop_scene_path
	module.has_light = has_light
	module.has_interaction = has_interaction
	module.has_destruction = has_destruction
	module.has_audio = has_audio
	module.reusable = true
	modules.append(module)
