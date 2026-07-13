extends Node2D
class_name UndergroundArtPresentation

## North-star underground presentation — 12 visual layers + finale hooks.

const PROFILE_PATH := "res://resources/visual/chapter_zero_underground_profile.tres"
const THEME_FACTORY := preload("res://scripts/visual/lighting/chapter_zero_underground_theme_factory.gd")
const RegionVisualControllerScript := preload("res://scripts/visual/lighting/region_visual_controller.gd")
const BetaComposer := preload("res://scripts/visual/underground_beta_composer.gd")
const Factory := preload("res://scripts/visual/underground_north_star_factory.gd")
const PlaceholderSlot := preload("res://scripts/visual/art_placeholder_slot.gd")

const LAYER_SKY := "Layer01_CavernCeiling"
const LAYER_FAR_MOUNTAINS := "Layer02_RockStrata"
const LAYER_ANCIENT_DEPTH := "Layer03_AncientDepth"
const LAYER_MID_BUILDINGS := "Layer04_TunnelArches"
const LAYER_GAMEPLAY_GROUND := "Layer05_GameplayGround"
const LAYER_GAMEPLAY_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACTABLES := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_ATMOSPHERE := "Layer10_Atmosphere"
const LAYER_FOREGROUND := "Layer11_Foreground"
const LAYER_FINALE := "Layer12_FinaleHooks"
const LAYER_DEBUG := "Layer13_Debug"

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
	_build_ceiling()
	_build_strata()
	_build_ancient_depth()
	_build_tunnel_arches()
	_build_gameplay_ground()
	_build_gameplay_structures()
	_build_props()
	_build_interactables()
	_build_lighting()
	_build_atmosphere()
	_build_foreground()
	_build_finale_hooks()
	_build_debug()
	_compose_beta_underground()
	_setup_region_visual_controller()


func get_region_visual_controller() -> RegionVisualController:
	return _visual_controller


func get_debug_layer() -> Node2D:
	return get_node_or_null(LAYER_DEBUG) as Node2D


func _setup_region_visual_controller() -> void:
	if _visual_controller != null:
		return
	_visual_controller = RegionVisualControllerScript.new() as RegionVisualController
	_visual_controller.name = "RegionVisualController"
	_visual_controller.auto_bind_parent_presentation = false
	_visual_controller.theme = region_theme if region_theme != null else THEME_FACTORY.load_or_build()
	add_child(_visual_controller)
	_visual_controller.bind_presentation(self)


func _build_modulate() -> void:
	var modulate := CanvasModulate.new()
	modulate.name = "CatacombModulate"
	modulate.color = Color(0.58, 0.54, 0.56, 1.0)
	add_child(modulate)


func _clear_generated_children() -> void:
	_visual_controller = null
	for child in get_children():
		child.queue_free()


func _parallax(layer_name: String, scroll_scale: float, z: int) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = Vector2(scroll_scale, scroll_scale * 0.15)
	layer.z_index = z
	layer.repeat_size = Vector2(_profile.playfield_width_px, 0.0)
	layer.repeat_times = 1
	add_child(layer)
	return layer


func _build_ceiling() -> void:
	var layer := _parallax(LAYER_SKY, _profile.layer_scroll_scales.get("sky", 0.04), -120)
	Factory.build_cavern_ceiling(layer, _profile)


func _build_strata() -> void:
	var layer := _parallax(LAYER_FAR_MOUNTAINS, _profile.layer_scroll_scales.get("mountains", 0.1), -100)
	Factory.build_rock_strata(layer, _profile)


func _build_ancient_depth() -> void:
	var layer := _parallax(LAYER_ANCIENT_DEPTH, _profile.layer_scroll_scales.get("city_silhouette", 0.18), -80)
	Factory.build_ancient_depth(layer, _profile)


func _build_tunnel_arches() -> void:
	var layer := _parallax(LAYER_MID_BUILDINGS, _profile.layer_scroll_scales.get("mid_buildings", 0.32), -40)
	Factory.build_tunnel_arches(layer, _profile)


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
	_add_structure_slots(layer)


func _build_props() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_PROPS
	layer.z_index = 10
	add_child(layer)
	Factory.build_props_layer(layer, _profile)
	_add_prop_slots(layer)


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
	var layer := _parallax(LAYER_FOREGROUND, _profile.layer_scroll_scales.get("foreground", 1.02), 40)
	Factory.build_foreground(layer, _profile)


func _build_finale_hooks() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_FINALE
	layer.z_index = 55
	add_child(layer)


func _build_debug() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_DEBUG
	layer.z_index = 90
	add_child(layer)


func _compose_beta_underground() -> void:
	BetaComposer.compose(self, _profile)


func _add_structure_slots(layer: Node2D) -> void:
	var ground_y := Factory.ground_anchor_y(_profile)
	var slots: Array[Dictionary] = [
		{"id": &"colossal_statue", "name": "Slot_ColossalStatue", "path": "art/environments/chapter_zero/underground_colossal_statue.png", "size": Vector2(160, 200), "pos": Vector2(980, ground_y - 148)},
		{"id": &"boss_altar", "name": "Slot_BossAltar", "path": "art/environments/chapter_zero/underground_ritual_altar.png", "size": Vector2(64, 40), "pos": Vector2(880, ground_y - 16)},
	]
	for entry in slots:
		layer.add_child(PlaceholderSlot.create(String(entry["name"]), entry["id"], String(entry["path"]), entry["size"], Color(1, 1, 1, 0.0), entry["pos"], false))


func _add_prop_slots(layer: Node2D) -> void:
	var ground_y := Factory.ground_anchor_y(_profile)
	var slots: Array[Dictionary] = [
		{"id": &"passage", "name": "Slot_HiddenPassage", "path": "art/environments/chapter_zero/underground_hidden_passage.png", "size": Vector2(80, 56), "pos": Vector2(1080, ground_y - 28)},
		{"id": &"mol_shadow", "name": "Slot_MolShadow", "path": "art/environments/chapter_zero/underground_mol_shadow.png", "size": Vector2(240, 160), "pos": Vector2(600, ground_y - 200)},
	]
	for entry in slots:
		layer.add_child(PlaceholderSlot.create(String(entry["name"]), entry["id"], String(entry["path"]), entry["size"], Color(1, 1, 1, 0.0), entry["pos"], false))
