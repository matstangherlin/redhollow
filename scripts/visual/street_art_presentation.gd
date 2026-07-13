extends Node2D
class_name StreetArtPresentation

## North-star street presentation — 12 visual layers, gameplay collision stays external.

const PROFILE_PATH := "res://resources/visual/chapter_zero_street_profile.tres"
const THEME_FACTORY := preload("res://scripts/visual/lighting/chapter_zero_street_theme_factory.gd")
const RegionVisualControllerScript := preload("res://scripts/visual/lighting/region_visual_controller.gd")
const BetaComposer := preload("res://scripts/visual/street_beta_composer.gd")

const LAYER_SKY := "Layer01_Sky"
const LAYER_FAR_MOUNTAINS := "Layer02_FarMountains"
const LAYER_DISTANT_TOWN := "Layer03_DistantTown"
const LAYER_MID_BUILDINGS := "Layer04_MidgroundBuildings"
const LAYER_GAMEPLAY_GROUND := "Layer05_GameplayGround"
const LAYER_GAMEPLAY_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACTABLES := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_ATMOSPHERE := "Layer10_Atmosphere"
const LAYER_FOREGROUND := "Layer11_Foreground"
const LAYER_DEBUG := "Layer12_Debug"

# Legacy aliases used by older tests/docs.
const LAYER_MOUNTAINS := LAYER_FAR_MOUNTAINS
const LAYER_CITY := LAYER_DISTANT_TOWN
const LAYER_PLAYFIELD := LAYER_GAMEPLAY_GROUND
const LAYER_PROPS_LEGACY := LAYER_PROPS
const LAYER_ATMOSPHERE_LEGACY := LAYER_ATMOSPHERE

@export var profile: EnvironmentVisualProfile
@export var region_theme: RegionVisualTheme
@export var build_on_ready: bool = true

var _profile: EnvironmentVisualProfile = null
var _visual_controller: RegionVisualController = null


func _ready() -> void:
	if build_on_ready:
		build_layers()


func build_layers() -> void:
	_profile = profile if profile != null else load(PROFILE_PATH) as EnvironmentVisualProfile
	_clear_generated_children()
	_build_modulate()
	_build_sky()
	_build_mountains()
	_build_distant_town()
	_build_mid_buildings()
	_build_gameplay_ground()
	_build_gameplay_structures()
	_build_props()
	_build_interactables()
	_build_lighting()
	_build_atmosphere()
	_build_foreground()
	_build_debug()
	_compose_beta_street()
	_setup_region_visual_controller()


func get_region_visual_controller() -> RegionVisualController:
	return _visual_controller


func _setup_region_visual_controller() -> void:
	if _visual_controller != null:
		return
	_visual_controller = RegionVisualControllerScript.new() as RegionVisualController
	_visual_controller.name = "RegionVisualController"
	_visual_controller.auto_bind_parent_presentation = false
	var theme := region_theme if region_theme != null else THEME_FACTORY.load_or_build()
	_visual_controller.theme = theme
	add_child(_visual_controller)
	_visual_controller.bind_presentation(self)


func _build_modulate() -> void:
	var modulate := CanvasModulate.new()
	modulate.name = "SunsetModulate"
	modulate.color = Color(0.92, 0.78, 0.66, 1.0)
	add_child(modulate)


func _clear_generated_children() -> void:
	_visual_controller = null
	for child in get_children():
		child.queue_free()


func get_debug_layer() -> Node2D:
	return get_node_or_null(LAYER_DEBUG) as Node2D


func _parallax(layer_name: String, scroll_scale: float, z: int) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = Vector2(scroll_scale, scroll_scale * 0.2)
	layer.z_index = z
	layer.repeat_size = Vector2(_profile.playfield_width_px, 0.0)
	layer.repeat_times = 1
	add_child(layer)
	return layer


func _build_sky() -> void:
	var layer := _parallax(LAYER_SKY, _profile.layer_scroll_scales.get("sky", 0.05), -120)
	StreetNorthStarFactory.build_enriched_sky(layer, _profile)


func _build_mountains() -> void:
	var layer := _parallax(LAYER_FAR_MOUNTAINS, _profile.layer_scroll_scales.get("mountains", 0.12), -100)
	StreetNorthStarFactory.build_enriched_mountains(layer, _profile)


func _build_distant_town() -> void:
	var layer := _parallax(LAYER_DISTANT_TOWN, _profile.layer_scroll_scales.get("city_silhouette", 0.22), -80)
	StreetNorthStarFactory.build_distant_town(layer, _profile)


func _build_mid_buildings() -> void:
	var layer := _parallax(LAYER_MID_BUILDINGS, _profile.layer_scroll_scales.get("mid_buildings", 0.38), -40)
	StreetNorthStarFactory.build_mid_buildings(layer, _profile)


func _build_gameplay_ground() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_GAMEPLAY_GROUND
	layer.z_index = 0
	add_child(layer)
	StreetNorthStarFactory.build_gameplay_ground(layer, _profile)


func _build_gameplay_structures() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_GAMEPLAY_STRUCTURES
	layer.z_index = 5
	add_child(layer)
	StreetNorthStarFactory.build_gameplay_structures(layer, _profile)
	_add_structure_asset_slots(layer)


func _build_props() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_PROPS
	layer.z_index = 10
	add_child(layer)
	StreetNorthStarFactory.build_props_layer(layer, _profile)
	_add_prop_asset_slots(layer)


func _build_interactables() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_INTERACTABLES
	layer.z_index = 12
	add_child(layer)


func _build_lighting() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_LIGHTING
	layer.z_index = 20
	add_child(layer)
	StreetNorthStarFactory.build_lighting(layer)


func _build_atmosphere() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_ATMOSPHERE
	layer.z_index = 50
	add_child(layer)
	StreetNorthStarFactory.build_atmosphere(layer, _profile)


func _build_foreground() -> void:
	var layer := _parallax(LAYER_FOREGROUND, _profile.layer_scroll_scales.get("foreground", 1.05), 40)
	StreetNorthStarFactory.build_foreground(layer, _profile)


func _build_debug() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_DEBUG
	layer.z_index = 90
	add_child(layer)


func _compose_beta_street() -> void:
	BetaComposer.compose(self, _profile)


func _add_structure_asset_slots(layer: Node2D) -> void:
	var ground_y: float = StreetNorthStarFactory.ground_anchor_y(_profile)
	var slots: Array[Dictionary] = [
		{"id": &"saloon", "name": "Slot_Saloon", "path": "art/environments/chapter_zero/street_saloon.png", "size": Vector2(192, 128), "pos": Vector2(300, ground_y - 64)},
		{"id": &"closed_building", "name": "Slot_ClosedBuilding", "path": "art/environments/chapter_zero/street_closed_building.png", "size": Vector2(160, 112), "pos": Vector2(700, ground_y - 56)},
	]
	for entry in slots:
		var slot := ArtPlaceholderSlot.create(
			String(entry["name"]),
			entry["id"],
			String(entry["path"]),
			entry["size"],
			Color(1, 1, 1, 0.0),
			entry["pos"],
			false
		)
		layer.add_child(slot)


func _add_prop_asset_slots(layer: Node2D) -> void:
	var ground_y: float = StreetNorthStarFactory.ground_anchor_y(_profile)
	var slots: Array[Dictionary] = [
		{"id": &"wagon", "name": "Slot_Wagon", "path": "art/environments/chapter_zero/street_wagon.png", "size": Vector2(96, 64), "pos": Vector2(1080, ground_y - 20)},
		{"id": &"barrels", "name": "Slot_Barrels", "path": "art/environments/chapter_zero/street_barrels.png", "size": Vector2(48, 40), "pos": Vector2(1240, ground_y - 4)},
		{"id": &"fence", "name": "Slot_Fence", "path": "art/environments/chapter_zero/street_fence.png", "size": Vector2(128, 48), "pos": Vector2(1480, ground_y - 8)},
		{"id": &"statue", "name": "Slot_Statue", "path": "art/environments/chapter_zero/street_statue_small.png", "size": Vector2(32, 56), "pos": Vector2(520, ground_y - 28)},
		{"id": &"sign_saloon", "name": "Slot_SignSaloon", "path": "art/environments/chapter_zero/street_sign_saloon.png", "size": Vector2(64, 32), "pos": Vector2(260, ground_y - 100)},
		{"id": &"sign_order", "name": "Slot_SignOrder", "path": "art/environments/chapter_zero/street_sign_order.png", "size": Vector2(56, 28), "pos": Vector2(1680, ground_y - 86)},
		{"id": &"lamp_post", "name": "Slot_LampPost", "path": "art/environments/chapter_zero/street_lamp_post.png", "size": Vector2(24, 96), "pos": Vector2(180, ground_y)},
	]
	for entry in slots:
		layer.add_child(
			ArtPlaceholderSlot.create(
				String(entry["name"]),
				entry["id"],
				String(entry["path"]),
				entry["size"],
				Color(1, 1, 1, 0.0),
				entry["pos"],
				false
			)
		)
