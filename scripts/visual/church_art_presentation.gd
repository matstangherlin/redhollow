extends Node2D
class_name ChurchArtPresentation

## North-star church presentation — 12 visual layers, gameplay collision stays external.

const PROFILE_PATH := "res://resources/visual/chapter_zero_church_profile.tres"
const THEME_FACTORY := preload("res://scripts/visual/lighting/chapter_zero_church_theme_factory.gd")
const RegionVisualControllerScript := preload("res://scripts/visual/lighting/region_visual_controller.gd")
const BetaComposer := preload("res://scripts/visual/church_beta_composer.gd")
const Factory := preload("res://scripts/visual/church_north_star_factory.gd")
const PlaceholderSlot := preload("res://scripts/visual/art_placeholder_slot.gd")

const LAYER_SKY := "Layer01_Sky"
const LAYER_FAR_MOUNTAINS := "Layer02_FarMountains"
const LAYER_DISTANT_CHURCH := "Layer03_DistantChurch"
const LAYER_MID_BUILDINGS := "Layer04_MidgroundBuildings"
const LAYER_GAMEPLAY_GROUND := "Layer05_GameplayGround"
const LAYER_GAMEPLAY_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACTABLES := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_ATMOSPHERE := "Layer10_Atmosphere"
const LAYER_FOREGROUND := "Layer11_Foreground"
const LAYER_DEBUG := "Layer12_Debug"

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
	_build_distant_church()
	_build_mid_buildings()
	_build_gameplay_ground()
	_build_gameplay_structures()
	_build_props()
	_build_interactables()
	_build_lighting()
	_build_atmosphere()
	_build_foreground()
	_build_debug()
	_compose_beta_church()
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
	modulate.name = "ChurchModulate"
	modulate.color = Color(0.72, 0.66, 0.7, 1.0)
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
	Factory.build_enriched_sky(layer, _profile)


func _build_mountains() -> void:
	var layer := _parallax(LAYER_FAR_MOUNTAINS, _profile.layer_scroll_scales.get("mountains", 0.12), -100)
	Factory.build_enriched_mountains(layer, _profile)


func _build_distant_church() -> void:
	var layer := _parallax(LAYER_DISTANT_CHURCH, _profile.layer_scroll_scales.get("city_silhouette", 0.22), -80)
	Factory.build_distant_church(layer, _profile)


func _build_mid_buildings() -> void:
	var layer := _parallax(LAYER_MID_BUILDINGS, _profile.layer_scroll_scales.get("mid_buildings", 0.38), -40)
	Factory.build_mid_buildings(layer, _profile)


func _build_gameplay_ground() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_GAMEPLAY_GROUND
	layer.z_index = 0
	add_child(layer)
	Factory.build_gameplay_ground(layer, _profile)


func _build_gameplay_structures() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_GAMEPLAY_STRUCTURES
	layer.z_index = 5
	add_child(layer)
	Factory.build_gameplay_structures(layer, _profile)
	_add_structure_asset_slots(layer)


func _build_props() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_PROPS
	layer.z_index = 10
	add_child(layer)
	Factory.build_props_layer(layer, _profile)
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
	Factory.build_lighting(layer, _profile)


func _build_atmosphere() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_ATMOSPHERE
	layer.z_index = 50
	add_child(layer)
	Factory.build_atmosphere(layer, _profile)


func _build_foreground() -> void:
	var layer := _parallax(LAYER_FOREGROUND, _profile.layer_scroll_scales.get("foreground", 1.05), 40)
	Factory.build_foreground(layer, _profile)


func _build_debug() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_DEBUG
	layer.z_index = 90
	add_child(layer)


func _compose_beta_church() -> void:
	BetaComposer.compose(self, _profile)


func _add_structure_asset_slots(layer: Node2D) -> void:
	var ground_y: float = Factory.ground_anchor_y(_profile)
	var slots: Array[Dictionary] = [
		{"id": &"bell_tower", "name": "Slot_BellTower", "path": "art/environments/chapter_zero/church_bell_tower.png", "size": Vector2(64, 200), "pos": Vector2(900, ground_y - 200)},
		{"id": &"main_entrance", "name": "Slot_MainEntrance", "path": "art/environments/chapter_zero/church_main_entrance.png", "size": Vector2(112, 120), "pos": Vector2(820, ground_y)},
	]
	for entry in slots:
		layer.add_child(
			PlaceholderSlot.create(
				String(entry["name"]),
				entry["id"],
				String(entry["path"]),
				entry["size"],
				Color(1, 1, 1, 0.0),
				entry["pos"],
				false
			)
		)


func _add_prop_asset_slots(layer: Node2D) -> void:
	var ground_y: float = Factory.ground_anchor_y(_profile)
	var slots: Array[Dictionary] = [
		{"id": &"statue", "name": "Slot_OrderStatue", "path": "art/environments/chapter_zero/church_order_statue.png", "size": Vector2(32, 64), "pos": Vector2(560, ground_y - 8)},
		{"id": &"altar", "name": "Slot_ExternalAltar", "path": "art/environments/chapter_zero/church_external_altar.png", "size": Vector2(64, 40), "pos": Vector2(680, ground_y - 12)},
		{"id": &"gate", "name": "Slot_CultGate", "path": "art/environments/chapter_zero/church_cult_gate.png", "size": Vector2(56, 72), "pos": Vector2(1150, ground_y)},
		{"id": &"passage", "name": "Slot_UndergroundPassage", "path": "art/environments/chapter_zero/church_underground_passage.png", "size": Vector2(80, 56), "pos": Vector2(1500, ground_y - 16)},
	]
	for entry in slots:
		layer.add_child(
			PlaceholderSlot.create(
				String(entry["name"]),
				entry["id"],
				String(entry["path"]),
				entry["size"],
				Color(1, 1, 1, 0.0),
				entry["pos"],
				false
			)
		)
