extends Node2D
class_name StreetArtPresentation

const ArtPlaceholderSlotScript := preload("res://scripts/visual/art_placeholder_slot.gd")
const PROFILE_PATH := "res://resources/visual/chapter_zero_street_profile.tres"

const LAYER_SKY := "Layer01_Sky"
const LAYER_MOUNTAINS := "Layer02_Mountains"
const LAYER_CITY := "Layer03_CitySilhouette"
const LAYER_MID_BUILDINGS := "Layer04_MidBuildings"
const LAYER_PLAYFIELD := "Layer05_Playfield"
const LAYER_PROPS := "Layer06_Props"
const LAYER_LIGHTING := "Layer07_Lighting"
const LAYER_FOREGROUND := "Layer08_Foreground"
const LAYER_ATMOSPHERE := "Layer09_Atmosphere"

@export var profile: EnvironmentVisualProfile
@export var build_on_ready: bool = true

var _profile: EnvironmentVisualProfile = null


func _ready() -> void:
	if build_on_ready:
		build_layers()


func build_layers() -> void:
	_profile = profile if profile != null else load(PROFILE_PATH) as EnvironmentVisualProfile
	_clear_generated_children()
	_build_modulate()
	_build_sky()
	_build_mountains()
	_build_city_silhouette()
	_build_mid_buildings()
	_build_playfield()
	_build_props()
	_build_lighting()
	_build_foreground()
	_build_atmosphere()


func _clear_generated_children() -> void:
	for child in get_children():
		child.queue_free()


func _build_modulate() -> void:
	var modulate := CanvasModulate.new()
	modulate.name = "SunsetModulate"
	modulate.color = Color(0.94, 0.82, 0.72, 1.0)
	add_child(modulate)


func _parallax(name: String, scroll_scale: float, z: int) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.name = name
	layer.scroll_scale = Vector2(scroll_scale, scroll_scale * 0.25)
	layer.z_index = z
	layer.repeat_size = Vector2(_profile.playfield_width_px, 0.0)
	layer.repeat_times = 1
	add_child(layer)
	return layer


func _build_sky() -> void:
	var layer := _parallax(LAYER_SKY, _profile.layer_scroll_scales.get("sky", 0.05), -120)
	var sky := Polygon2D.new()
	sky.name = "SkyGradient"
	sky.color = Color(0.42, 0.22, 0.18, 1.0)
	sky.polygon = PackedVector2Array([
		Vector2(0, 120), Vector2(_profile.playfield_width_px, 120),
		Vector2(_profile.playfield_width_px, 420), Vector2(0, 420),
	])
	layer.add_child(sky)

	var horizon := Polygon2D.new()
	horizon.name = "SunsetHorizon"
	horizon.color = Color(0.86, 0.42, 0.18, 0.55)
	horizon.polygon = PackedVector2Array([
		Vector2(0, 360), Vector2(_profile.playfield_width_px, 360),
		Vector2(_profile.playfield_width_px, 456), Vector2(0, 456),
	])
	layer.add_child(horizon)


func _build_mountains() -> void:
	var layer := _parallax(LAYER_MOUNTAINS, _profile.layer_scroll_scales.get("mountains", 0.12), -100)
	var mountains := Polygon2D.new()
	mountains.name = "MountainRange"
	mountains.color = Color(0.18, 0.14, 0.16, 1.0)
	mountains.polygon = PackedVector2Array([
		Vector2(0, 420), Vector2(180, 300), Vector2(360, 360), Vector2(520, 260),
		Vector2(760, 340), Vector2(980, 240), Vector2(1180, 320), Vector2(1420, 250),
		Vector2(1660, 330), Vector2(1900, 270), Vector2(2140, 350), Vector2(2400, 280),
		Vector2(2400, 420), Vector2(0, 420),
	])
	layer.add_child(mountains)


func _build_city_silhouette() -> void:
	var layer := _parallax(LAYER_CITY, _profile.layer_scroll_scales.get("city_silhouette", 0.22), -80)
	var skyline := Polygon2D.new()
	skyline.name = "CitySilhouette"
	skyline.color = Color(0.12, 0.1, 0.11, 1.0)
	skyline.polygon = PackedVector2Array([
		Vector2(0, 460), Vector2(0, 390), Vector2(80, 390), Vector2(80, 350),
		Vector2(160, 350), Vector2(160, 390), Vector2(300, 390), Vector2(300, 330),
		Vector2(420, 330), Vector2(420, 390), Vector2(620, 390), Vector2(620, 310),
		Vector2(760, 310), Vector2(760, 390), Vector2(980, 390), Vector2(980, 340),
		Vector2(1120, 340), Vector2(1120, 390), Vector2(1380, 390), Vector2(1380, 320),
		Vector2(1540, 320), Vector2(1540, 390), Vector2(1760, 390), Vector2(1760, 350),
		Vector2(1900, 350), Vector2(1900, 390), Vector2(2100, 390), Vector2(2100, 300),
		Vector2(2260, 300), Vector2(2260, 390), Vector2(2400, 390), Vector2(2400, 460),
	])
	layer.add_child(skyline)


func _build_mid_buildings() -> void:
	var layer := _parallax(LAYER_MID_BUILDINGS, _profile.layer_scroll_scales.get("mid_buildings", 0.38), -40)
	var buildings := [
		{"pos": Vector2(220, 460), "size": Vector2(140, 120), "color": Color(0.28, 0.2, 0.16, 1.0)},
		{"pos": Vector2(520, 460), "size": Vector2(180, 140), "color": Color(0.3, 0.22, 0.18, 1.0)},
		{"pos": Vector2(980, 460), "size": Vector2(160, 130), "color": Color(0.26, 0.19, 0.15, 1.0)},
		{"pos": Vector2(1560, 460), "size": Vector2(200, 150), "color": Color(0.24, 0.18, 0.14, 1.0)},
		{"pos": Vector2(1980, 460), "size": Vector2(150, 125), "color": Color(0.27, 0.2, 0.16, 1.0)},
	]
	for index in range(buildings.size()):
		var data: Dictionary = buildings[index]
		var size: Vector2 = data["size"]
		var block := Polygon2D.new()
		block.name = "MidBuilding_%02d" % (index + 1)
		block.color = data["color"]
		block.position = data["pos"]
		block.polygon = PackedVector2Array([
			Vector2(-size.x * 0.5, 0.0),
			Vector2(size.x * 0.5, 0.0),
			Vector2(size.x * 0.5, -size.y),
			Vector2(-size.x * 0.5, -size.y),
		])
		layer.add_child(block)


func _build_playfield() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_PLAYFIELD
	layer.z_index = 0
	add_child(layer)

	var ground_strip := Polygon2D.new()
	ground_strip.name = "GroundTileStrip"
	ground_strip.color = Color(0.34, 0.26, 0.2, 1.0)
	ground_strip.polygon = PackedVector2Array([
		Vector2(0, _profile.ground_surface_y),
		Vector2(_profile.playfield_width_px, _profile.ground_surface_y),
		Vector2(_profile.playfield_width_px, _profile.ground_surface_y + 48.0),
		Vector2(0, _profile.ground_surface_y + 48.0),
	])
	layer.add_child(ground_strip)

	var sidewalk := Polygon2D.new()
	sidewalk.name = "WoodenSidewalk"
	sidewalk.color = Color(0.42, 0.3, 0.22, 1.0)
	sidewalk.polygon = PackedVector2Array([
		Vector2(0, _profile.ground_surface_y - 8.0),
		Vector2(_profile.playfield_width_px, _profile.ground_surface_y - 8.0),
		Vector2(_profile.playfield_width_px, _profile.ground_surface_y + 4.0),
		Vector2(0, _profile.ground_surface_y + 4.0),
	])
	layer.add_child(sidewalk)

	var tile_hint := Label.new()
	tile_hint.name = "TileHint"
	tile_hint.position = Vector2(24.0, _profile.ground_surface_y + 52.0)
	tile_hint.theme_override_colors/font_color = Color(0.72, 0.68, 0.62, 0.65)
	tile_hint.theme_override_font_sizes/font_size = 10
	tile_hint.text = "TileMapLayer slot: art/environments/chapter_zero/street_ground_tileset.png (16px)"
	layer.add_child(tile_hint)


func _build_props() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_PROPS
	layer.z_index = 10
	add_child(layer)

	var slots: Array[Dictionary] = [
		{"id": &"saloon", "name": "Saloon", "path": "art/environments/chapter_zero/street_saloon.png", "size": Vector2(192, 128), "pos": Vector2(320, 848), "color": Color(0.48, 0.3, 0.2, 1.0)},
		{"id": &"closed_building", "name": "ClosedBuilding", "path": "art/environments/chapter_zero/street_closed_building.png", "size": Vector2(160, 112), "pos": Vector2(720, 848), "color": Color(0.36, 0.28, 0.24, 1.0)},
		{"id": &"wagon", "name": "Wagon", "path": "art/environments/chapter_zero/street_wagon.png", "size": Vector2(96, 64), "pos": Vector2(1080, 860), "color": Color(0.4, 0.28, 0.18, 1.0)},
		{"id": &"barrels", "name": "BarrelCluster", "path": "art/environments/chapter_zero/street_barrels.png", "size": Vector2(48, 40), "pos": Vector2(1240, 868), "color": Color(0.34, 0.22, 0.14, 1.0)},
		{"id": &"fence", "name": "FenceSection", "path": "art/environments/chapter_zero/street_fence.png", "size": Vector2(128, 48), "pos": Vector2(1480, 864), "color": Color(0.38, 0.26, 0.18, 1.0)},
		{"id": &"statue", "name": "SmallStatue", "path": "art/environments/chapter_zero/street_statue_small.png", "size": Vector2(32, 56), "pos": Vector2(520, 848), "color": Color(0.5, 0.46, 0.42, 1.0)},
		{"id": &"sign_saloon", "name": "SignSaloon", "path": "art/environments/chapter_zero/street_sign_saloon.png", "size": Vector2(64, 32), "pos": Vector2(280, 780), "color": Color(0.62, 0.38, 0.18, 1.0)},
		{"id": &"sign_order", "name": "SignOrder", "path": "art/environments/chapter_zero/street_sign_order.png", "size": Vector2(56, 28), "pos": Vector2(1680, 790), "color": Color(0.58, 0.34, 0.2, 1.0)},
		{"id": &"lamp_post", "name": "LampPost_A", "path": "art/environments/chapter_zero/street_lamp_post.png", "size": Vector2(24, 96), "pos": Vector2(180, 848), "color": Color(0.3, 0.24, 0.18, 1.0)},
		{"id": &"lamp_post_b", "name": "LampPost_B", "path": "art/environments/chapter_zero/street_lamp_post.png", "size": Vector2(24, 96), "pos": Vector2(920, 848), "color": Color(0.3, 0.24, 0.18, 1.0)},
		{"id": &"lamp_post_c", "name": "LampPost_C", "path": "art/environments/chapter_zero/street_lamp_post.png", "size": Vector2(24, 96), "pos": Vector2(1640, 848), "color": Color(0.3, 0.24, 0.18, 1.0)},
	]
	for entry in slots:
		layer.add_child(
			ArtPlaceholderSlotScript.create(
				String(entry["name"]),
				entry["id"],
				String(entry["path"]),
				entry["size"],
				entry["color"],
				entry["pos"],
				false
			)
		)


func _build_lighting() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_LIGHTING
	layer.z_index = 20
	add_child(layer)

	var ambient := DirectionalLight2D.new()
	ambient.name = "SunsetDirectional"
	ambient.color = Color(0.95, 0.62, 0.34, 1.0)
	ambient.energy = 0.35
	ambient.shadow_enabled = false
	layer.add_child(ambient)

	var lantern_positions: Array[Vector2] = [Vector2(180, 800), Vector2(920, 800), Vector2(1640, 800)]
	for index in range(lantern_positions.size()):
		var point := PointLight2D.new()
		point.name = "LanternLight_%d" % (index + 1)
		point.position = lantern_positions[index]
		point.color = Color(1.0, 0.72, 0.34, 1.0)
		point.energy = 0.9
		point.texture_scale = 0.45
		point.shadow_enabled = false
		layer.add_child(point)


func _build_foreground() -> void:
	var layer := _parallax(LAYER_FOREGROUND, _profile.layer_scroll_scales.get("foreground", 1.05), 40)
	var beam := Polygon2D.new()
	beam.name = "ForegroundBeam"
	beam.color = Color(0.08, 0.06, 0.05, 0.35)
	beam.position = Vector2(200, 520)
	beam.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(28, 0), Vector2(64, 360), Vector2(-12, 360),
	])
	layer.add_child(beam)

	var dust_veil := Polygon2D.new()
	dust_veil.name = "ForegroundDustVeil"
	dust_veil.color = Color(0.62, 0.42, 0.24, 0.08)
	dust_veil.polygon = PackedVector2Array([
		Vector2(0, 520), Vector2(_profile.playfield_width_px, 520),
		Vector2(_profile.playfield_width_px, 640), Vector2(0, 640),
	])
	layer.add_child(dust_veil)


func _build_atmosphere() -> void:
	var layer := Node2D.new()
	layer.name = LAYER_ATMOSPHERE
	layer.z_index = 50
	add_child(layer)

	var particles := GPUParticles2D.new()
	particles.name = "DustParticles"
	particles.position = Vector2(_profile.playfield_width_px * 0.5, 640.0)
	particles.amount = 120
	particles.lifetime = 6.0
	particles.preprocess = 2.0
	particles.visibility_rect = Rect2(-1400, -200, 2800, 400)
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.15, -0.05, 0.0)
	mat.spread = 18.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3(0.0, -2.0, 0.0)
	mat.scale_min = 0.4
	mat.scale_max = 1.2
	mat.color = Color(0.86, 0.62, 0.34, 0.18)
	particles.process_material = mat
	layer.add_child(particles)
