extends RefCounted
class_name StreetNorthStarFactory

const Layout := preload("res://scripts/visual/street_north_star_layout.gd")

## Procedural original silhouettes for the street north-star slice (no external art).

const COLOR_DIRT_DARK := Color(0.28, 0.2, 0.14, 1.0)
const COLOR_DIRT_MID := Color(0.36, 0.26, 0.18, 1.0)
const COLOR_WOOD_DARK := Color(0.32, 0.22, 0.14, 1.0)
const COLOR_WOOD_MID := Color(0.44, 0.3, 0.2, 1.0)
const COLOR_WOOD_LIGHT := Color(0.52, 0.36, 0.24, 1.0)
const COLOR_ROOF := Color(0.22, 0.16, 0.14, 1.0)
const COLOR_STONE := Color(0.38, 0.34, 0.32, 1.0)
const COLOR_VERMILITE := Color(0.92, 0.18, 0.12, 1.0)
const COLOR_HEART := Color(0.78, 0.12, 0.1, 1.0)
const COLOR_WINDOW_GLOW := Color(0.92, 0.58, 0.28, 0.55)
const COLOR_SHUTTER := Color(0.26, 0.18, 0.14, 1.0)
const COLOR_DRY_GRASS := Color(0.42, 0.34, 0.18, 1.0)


static func ground_anchor_y(profile: EnvironmentVisualProfile) -> float:
	return profile.ground_surface_y


static func build_enriched_sky(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var top := Polygon2D.new()
	top.name = "SkyTop"
	top.color = Color(0.18, 0.12, 0.22, 1.0)
	top.polygon = PackedVector2Array([
		Vector2(0, 80), Vector2(width, 80), Vector2(width, 260), Vector2(0, 260),
	])
	layer.add_child(top)

	var mid := Polygon2D.new()
	mid.name = "SkyMid"
	mid.color = Color(0.42, 0.2, 0.16, 1.0)
	mid.polygon = PackedVector2Array([
		Vector2(0, 220), Vector2(width, 220), Vector2(width, 360), Vector2(0, 360),
	])
	layer.add_child(mid)

	var sun := Polygon2D.new()
	sun.name = "SettingSun"
	sun.color = Color(0.96, 0.52, 0.18, 0.85)
	sun.position = Vector2(width * 0.72, 300)
	sun.polygon = _circle_polygon(28, 16)
	layer.add_child(sun)

	var mol_glow := Polygon2D.new()
	mol_glow.name = "MolKharDistantGlow"
	mol_glow.color = Color(0.62, 0.08, 0.06, 0.22)
	mol_glow.polygon = PackedVector2Array([
		Vector2(width * 0.55, 340), Vector2(width * 0.95, 340),
		Vector2(width * 0.88, 420), Vector2(width * 0.48, 420),
	])
	layer.add_child(mol_glow)


static func build_enriched_mountains(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var ridge := Polygon2D.new()
	ridge.name = "MountainRange"
	ridge.color = Color(0.14, 0.11, 0.13, 1.0)
	ridge.polygon = PackedVector2Array([
		Vector2(0, 420), Vector2(140, 290), Vector2(320, 350), Vector2(500, 250),
		Vector2(720, 320), Vector2(940, 220), Vector2(1160, 300), Vector2(1380, 230),
		Vector2(1620, 310), Vector2(1860, 240), Vector2(2100, 320), Vector2(width, 260),
		Vector2(width, 420), Vector2(0, 420),
	])
	layer.add_child(ridge)

	var mine := Polygon2D.new()
	mine.name = "MineScar"
	mine.color = Color(0.2, 0.12, 0.1, 0.65)
	mine.polygon = PackedVector2Array([
		Vector2(880, 420), Vector2(940, 340), Vector2(1020, 420),
	])
	layer.add_child(mine)


static func build_distant_town(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var skyline := Polygon2D.new()
	skyline.name = "DistantTownSilhouette"
	skyline.color = Color(0.1, 0.08, 0.09, 1.0)
	skyline.polygon = PackedVector2Array([
		Vector2(0, 460), Vector2(0, 380), Vector2(60, 380), Vector2(60, 340),
		Vector2(120, 340), Vector2(120, 380), Vector2(220, 380), Vector2(220, 320),
		Vector2(300, 320), Vector2(300, 380), Vector2(420, 380), Vector2(420, 300),
		Vector2(520, 300), Vector2(520, 380), Vector2(640, 380), Vector2(640, 330),
		Vector2(760, 330), Vector2(760, 380), Vector2(900, 380), Vector2(900, 290),
		Vector2(1020, 290), Vector2(1020, 380), Vector2(1180, 380), Vector2(1180, 310),
		Vector2(1320, 310), Vector2(1320, 380), Vector2(1480, 380), Vector2(1480, 280),
		Vector2(1620, 280), Vector2(1620, 380), Vector2(1760, 380), Vector2(1760, 330),
		Vector2(1880, 330), Vector2(1880, 380), Vector2(2060, 380), Vector2(2060, 300),
		Vector2(2200, 300), Vector2(2200, 380), Vector2(width, 380), Vector2(width, 460),
	])
	layer.add_child(skyline)

	var church_spire := Polygon2D.new()
	church_spire.name = "DistantChurchSpire"
	church_spire.color = Color(0.08, 0.06, 0.07, 1.0)
	church_spire.polygon = PackedVector2Array([
		Vector2(2060, 380), Vector2(2088, 250), Vector2(2116, 380),
	])
	layer.add_child(church_spire)

	var smoke := Polygon2D.new()
	smoke.name = "DistantSmelterSmoke"
	smoke.color = Color(0.28, 0.2, 0.16, 0.2)
	smoke.polygon = PackedVector2Array([
		Vector2(1240, 320), Vector2(1280, 280), Vector2(1320, 320), Vector2(1280, 340),
	])
	layer.add_child(smoke)


static func build_mid_buildings(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	# Backdrop facades — bases sit on the street line; parallax separates them from gameplay structures.
	var specs: Array[Dictionary] = [
		{"pos": Vector2(120, ground_y), "w": 120, "h": 108, "roof": 16},
		{"pos": Vector2(1180, ground_y), "w": 150, "h": 118, "roof": 18},
		{"pos": Vector2(1860, ground_y), "w": 140, "h": 112, "roof": 16},
	]
	for index in range(specs.size()):
		var data: Dictionary = specs[index]
		var root := Node2D.new()
		root.name = "MidBuilding_%02d" % (index + 1)
		root.position = data["pos"]
		layer.add_child(root)
		_build_simple_facade(
			root,
			float(data["w"]),
			float(data["h"]),
			float(data["roof"]),
			Color(0.26, 0.19, 0.15, 1.0),
			true
		)


static func build_gameplay_ground(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var ground_y := ground_anchor_y(profile)

	var dirt := Polygon2D.new()
	dirt.name = "DirtGround"
	dirt.color = COLOR_DIRT_MID
	dirt.polygon = PackedVector2Array([
		Vector2(0, ground_y), Vector2(width, ground_y),
		Vector2(width, ground_y + 52), Vector2(0, ground_y + 52),
	])
	layer.add_child(dirt)

	for x in range(0, int(width), 32):
		if x % 64 == 0:
			continue
		var patch := Polygon2D.new()
		patch.color = COLOR_DIRT_DARK if x % 96 == 32 else Color(0.4, 0.28, 0.2, 1.0)
		patch.position = Vector2(x, ground_y + 8)
		patch.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(24, 0), Vector2(20, 16), Vector2(4, 16),
		])
		layer.add_child(patch)

	var sidewalk := Polygon2D.new()
	sidewalk.name = "WoodenSidewalk"
	sidewalk.color = COLOR_WOOD_MID
	sidewalk.polygon = PackedVector2Array([
		Vector2(0, ground_y - 10), Vector2(width, ground_y - 10),
		Vector2(width, ground_y + 2), Vector2(0, ground_y + 2),
	])
	layer.add_child(sidewalk)

	for x in range(0, int(width), 16):
		var plank := Polygon2D.new()
		plank.color = COLOR_WOOD_DARK if int(x / 16) % 2 == 0 else COLOR_WOOD_LIGHT
		plank.polygon = PackedVector2Array([
			Vector2(x, ground_y - 10), Vector2(x + 14, ground_y - 10),
			Vector2(x + 14, ground_y + 2), Vector2(x, ground_y + 2),
		])
		layer.add_child(plank)

	var platforms: Array[Dictionary] = [
		{"pos": Vector2(560, 820), "half_w": 90.0},
		{"pos": Vector2(860, 760), "half_w": 90.0},
		{"pos": Vector2(1160, 700), "half_w": 90.0},
		{"pos": Vector2(1360, 780), "half_w": 90.0},
	]
	for index in range(platforms.size()):
		var data: Dictionary = platforms[index]
		_build_elevated_platform(layer, data["pos"], float(data["half_w"]), index)


static func build_gameplay_structures(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	_build_saloon(layer, Vector2(300, ground_y - 64))
	_build_abandoned_building(layer, Vector2(700, ground_y - 56))
	_build_roof_awning(layer, Vector2(1180, ground_y - 40))


static func build_props_layer(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	_build_lamp_post(layer, Vector2(180, ground_y))
	_build_lamp_post(layer, Vector2(920, ground_y))
	_build_lamp_post(layer, Vector2(1640, ground_y))
	_build_wagon(layer, Vector2(1080, ground_y - 20))
	_build_barrel_cluster(layer, Vector2(1240, ground_y - 4))
	_build_crate_stack(layer, Vector2(1320, ground_y - 4))
	_build_fence_section(layer, Vector2(1480, ground_y - 8))
	_build_dry_vegetation(layer, Vector2(1560, ground_y), 3)
	_build_dry_vegetation(layer, Vector2(380, ground_y), 2)
	_build_order_statue(layer, Vector2(520, ground_y - 28))
	_build_heart_symbol_decal(layer, Vector2(420, ground_y - 2))
	_build_vermilite_cluster(layer, Vector2(980, ground_y - 6), 2)
	_build_vermilite_cluster(layer, Vector2(1720, ground_y - 4), 1)


static func build_interactable_markers(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	for entry in Layout.get_interactable_markers(ground_y):
		var ring := Polygon2D.new()
		ring.name = "InteractMarker_%s" % entry["id"]
		ring.position = entry["pos"]
		ring.color = entry["color"]
		ring.polygon = _circle_polygon(10, 12)
		layer.add_child(ring)


static func build_lighting(layer: Node2D) -> void:
	if DisplayServer.get_name() == "headless":
		return

	var ambient := DirectionalLight2D.new()
	ambient.name = "SunsetDirectional"
	ambient.color = Color(0.95, 0.58, 0.28, 1.0)
	ambient.energy = 0.32
	ambient.shadow_enabled = false
	layer.add_child(ambient)

	var fill := DirectionalLight2D.new()
	fill.name = "CoolShadowFill"
	fill.color = Color(0.22, 0.16, 0.24, 1.0)
	fill.energy = 0.12
	fill.rotation = PI
	fill.shadow_enabled = false
	layer.add_child(fill)

	var lantern_positions: Array[Vector2] = [Vector2(180, 792), Vector2(920, 792), Vector2(1640, 792)]
	for index in range(lantern_positions.size()):
		var point := PointLight2D.new()
		point.name = "LanternLight_%d" % (index + 1)
		point.position = lantern_positions[index]
		point.color = Color(1.0, 0.68, 0.28, 1.0)
		point.energy = 0.85
		point.texture_scale = 0.42
		point.shadow_enabled = false
		layer.add_child(point)

	var saloon_interior := PointLight2D.new()
	saloon_interior.name = "SaloonWindowGlow"
	saloon_interior.position = Vector2(300, 800)
	saloon_interior.color = Color(0.95, 0.55, 0.22, 1.0)
	saloon_interior.energy = 0.35
	saloon_interior.texture_scale = 0.55
	saloon_interior.shadow_enabled = false
	layer.add_child(saloon_interior)

	var verm := PointLight2D.new()
	verm.name = "VermiliteAccent"
	verm.position = Vector2(980, 820)
	verm.color = Color(0.95, 0.2, 0.12, 1.0)
	verm.energy = 0.28
	verm.texture_scale = 0.35
	verm.shadow_enabled = false
	layer.add_child(verm)


static func build_atmosphere(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	if DisplayServer.get_name() == "headless":
		return

	var center_x := profile.playfield_width_px * 0.5
	_add_particles(layer, "DustMotes", Vector2(center_x, 640), 80, Color(0.86, 0.62, 0.34, 0.16), 6.0, 0.12)
	_add_particles(layer, "DryDebris", Vector2(center_x, 700), 36, Color(0.52, 0.38, 0.22, 0.2), 5.0, 0.18)
	_add_particles(layer, "DryLeaves", Vector2(center_x, 620), 28, Color(0.62, 0.42, 0.18, 0.22), 7.0, 0.08)
	_add_particles(layer, "Smokerise", Vector2(1240, 500), 18, Color(0.42, 0.32, 0.28, 0.12), 8.0, 0.04)
	_add_particles(layer, "VermiliteMotes", Vector2(980, 760), 12, Color(0.95, 0.22, 0.14, 0.28), 4.0, 0.02)


static func build_foreground(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var beam := Polygon2D.new()
	beam.name = "ForegroundPorchShadow"
	beam.color = Color(0.05, 0.04, 0.04, 0.42)
	beam.position = Vector2(180, 520)
	beam.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(36, 0), Vector2(72, 360), Vector2(-16, 360),
	])
	layer.add_child(beam)

	var fence_fg := Polygon2D.new()
	fence_fg.name = "ForegroundFence"
	fence_fg.color = Color(0.06, 0.05, 0.05, 0.55)
	fence_fg.position = Vector2(40, 760)
	fence_fg.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(120, 0), Vector2(120, 48), Vector2(0, 60),
	])
	layer.add_child(fence_fg)

	var veil := Polygon2D.new()
	veil.name = "SunsetDustVeil"
	veil.color = Color(0.62, 0.38, 0.2, 0.07)
	veil.polygon = PackedVector2Array([
		Vector2(0, 520), Vector2(width, 520), Vector2(width, 680), Vector2(0, 680),
	])
	layer.add_child(veil)


static func _build_elevated_platform(layer: Node2D, center: Vector2, half_w: float, index: int) -> void:
	var root := Node2D.new()
	root.name = "GameplayPlatform_%d" % (index + 1)
	root.position = center
	layer.add_child(root)

	var top_y := -12.0
	var beam := Polygon2D.new()
	beam.name = "PlatformDeck"
	beam.color = COLOR_WOOD_MID
	beam.polygon = PackedVector2Array([
		Vector2(-half_w, top_y), Vector2(half_w, top_y),
		Vector2(half_w, top_y + 12), Vector2(-half_w, top_y + 12),
	])
	root.add_child(beam)

	for x in range(int(-half_w), int(half_w), 16):
		var plank := Polygon2D.new()
		plank.color = COLOR_WOOD_DARK if int(x / 16) % 2 == 0 else COLOR_WOOD_LIGHT
		plank.polygon = PackedVector2Array([
			Vector2(x, top_y), Vector2(x + 14, top_y),
			Vector2(x + 14, top_y + 12), Vector2(x, top_y + 12),
		])
		root.add_child(plank)

	var support := Polygon2D.new()
	support.name = "PlatformSupport"
	support.color = COLOR_WOOD_DARK
	support.polygon = PackedVector2Array([
		Vector2(-8, top_y + 12), Vector2(8, top_y + 12), Vector2(4, 40), Vector2(-4, 40),
	])
	root.add_child(support)


static func _build_saloon(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "SaloonStructure"
	root.position = base
	parent.add_child(root)
	_build_simple_facade(root, 192, 128, 24, COLOR_WOOD_MID, true)
	_add_polygon(root, COLOR_WOOD_DARK, PackedVector2Array([
		Vector2(-72, 0), Vector2(72, 0), Vector2(72, 18), Vector2(-72, 18),
	]), Vector2(0, 0))

	var porch := Polygon2D.new()
	porch.color = COLOR_WOOD_LIGHT
	porch.polygon = PackedVector2Array([
		Vector2(-84, 0), Vector2(84, 0), Vector2(84, 10), Vector2(-84, 10),
	])
	root.add_child(porch)

	var sign := Polygon2D.new()
	sign.name = "SaloonSign"
	sign.color = Color(0.62, 0.34, 0.16, 1.0)
	sign.position = Vector2(-40, -92)
	sign.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(64, 0), Vector2(64, 20), Vector2(0, 20),
	])
	root.add_child(sign)


static func _build_abandoned_building(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "AbandonedBuilding"
	root.position = base
	parent.add_child(root)
	_build_simple_facade(root, 160, 112, 18, COLOR_STONE, false)

	for wx in [-48, -16, 16, 48]:
		var shutter := Polygon2D.new()
		shutter.color = COLOR_SHUTTER
		shutter.position = Vector2(wx, -48)
		shutter.polygon = PackedVector2Array([
			Vector2(-10, -12), Vector2(10, -12), Vector2(10, 12), Vector2(-10, 12),
		])
		root.add_child(shutter)


static func _build_roof_awning(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "RoofAwning"
	root.position = base
	parent.add_child(root)
	var awning := Polygon2D.new()
	awning.color = COLOR_ROOF
	awning.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(60, 0), Vector2(48, -16), Vector2(-48, -16),
	])
	root.add_child(awning)


static func _build_simple_facade(
	parent: Node2D,
	width: float,
	height: float,
	roof_h: float,
	wall_color: Color,
	lit_windows: bool
) -> void:
	var half_w := width * 0.5
	var body := Polygon2D.new()
	body.name = "FacadeBody"
	body.color = wall_color
	body.polygon = PackedVector2Array([
		Vector2(-half_w, 0), Vector2(half_w, 0), Vector2(half_w, -height), Vector2(-half_w, -height),
	])
	parent.add_child(body)

	var roof := Polygon2D.new()
	roof.name = "FacadeRoof"
	roof.color = COLOR_ROOF
	roof.polygon = PackedVector2Array([
		Vector2(-half_w - 6, -height), Vector2(half_w + 6, -height),
		Vector2(half_w, -height - roof_h), Vector2(-half_w, -height - roof_h),
	])
	parent.add_child(roof)

	if lit_windows:
		for wx in [-36, 12, 48]:
			var window := Polygon2D.new()
			window.color = COLOR_WINDOW_GLOW
			window.position = Vector2(wx, -height * 0.55)
			window.polygon = PackedVector2Array([
				Vector2(-8, -10), Vector2(8, -10), Vector2(8, 10), Vector2(-8, 10),
			])
			parent.add_child(window)

	var door := Polygon2D.new()
	door.name = "FacadeDoor"
	door.color = COLOR_WOOD_DARK
	door.position = Vector2(-14, -22)
	door.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(12, -44), Vector2(-12, -44),
	])
	parent.add_child(door)


static func _build_lamp_post(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "LampPost"
	root.position = base
	parent.add_child(root)

	var post := Polygon2D.new()
	post.color = COLOR_WOOD_DARK
	post.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0), Vector2(2, -72), Vector2(-2, -72),
	])
	root.add_child(post)

	var lamp := Polygon2D.new()
	lamp.color = Color(0.92, 0.62, 0.28, 0.9)
	lamp.position = Vector2(0, -76)
	lamp.polygon = _circle_polygon(6, 10)
	root.add_child(lamp)


static func _build_wagon(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "Wagon"
	root.position = base
	parent.add_child(root)
	_add_polygon(root, COLOR_WOOD_MID, PackedVector2Array([
		Vector2(-48, -8), Vector2(48, -8), Vector2(40, -32), Vector2(-40, -32),
	]), Vector2.ZERO)
	for wheel_x in [-28, 28]:
		var wheel := Polygon2D.new()
		wheel.color = Color(0.18, 0.14, 0.12, 1.0)
		wheel.position = Vector2(wheel_x, 0)
		wheel.polygon = _circle_polygon(10, 12)
		root.add_child(wheel)


static func _build_barrel_cluster(parent: Node2D, base: Vector2) -> void:
	_build_barrel(parent, base + Vector2(-12, 0))
	_build_barrel(parent, base + Vector2(10, 0))


static func _build_barrel(parent: Node2D, pos: Vector2) -> void:
	var barrel := Node2D.new()
	barrel.position = pos
	parent.add_child(barrel)
	_add_polygon(barrel, COLOR_WOOD_DARK, PackedVector2Array([
		Vector2(-10, 0), Vector2(10, 0), Vector2(8, -20), Vector2(-8, -20),
	]), Vector2.ZERO)


static func _build_crate_stack(parent: Node2D, base: Vector2) -> void:
	for i in range(2):
		_add_polygon(parent, COLOR_WOOD_MID, PackedVector2Array([
			Vector2(0, 0), Vector2(24, 0), Vector2(24, -18), Vector2(0, -18),
		]), base + Vector2(i * 20 - 10, 0))


static func _build_fence_section(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "FenceSection"
	root.position = base
	parent.add_child(root)
	for x in range(0, 128, 16):
		var post := Polygon2D.new()
		post.color = COLOR_WOOD_DARK
		post.position = Vector2(x - 64, 0)
		post.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(2, 0), Vector2(2, -32), Vector2(-2, -32),
		])
		root.add_child(post)
	var rail := Polygon2D.new()
	rail.color = COLOR_WOOD_MID
	rail.position = Vector2(-64, -20)
	rail.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(128, 0), Vector2(128, 4), Vector2(0, 4),
	])
	root.add_child(rail)


static func _build_dry_vegetation(parent: Node2D, base: Vector2, count: int) -> void:
	for i in range(count):
		var tuft := Polygon2D.new()
		tuft.color = COLOR_DRY_GRASS
		tuft.position = base + Vector2(i * 14 - 8, 0)
		tuft.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(6, -16), Vector2(12, 0),
		])
		parent.add_child(tuft)


static func _build_order_statue(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "OrderStatue"
	root.position = base
	parent.add_child(root)
	_add_polygon(root, COLOR_STONE, PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0), Vector2(5, -20), Vector2(-5, -20),
	]), Vector2.ZERO)
	_add_polygon(root, COLOR_STONE.lightened(0.08), PackedVector2Array([
		Vector2(-10, -20), Vector2(10, -20), Vector2(8, -28), Vector2(-8, -28),
	]), Vector2.ZERO)


static func _build_heart_symbol_decal(parent: Node2D, base: Vector2) -> void:
	var heart := Polygon2D.new()
	heart.name = "RedHeartSymbol"
	heart.position = base
	heart.color = COLOR_HEART
	heart.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(6, -12), Vector2(10, -6), Vector2(0, 4), Vector2(-10, -6), Vector2(-6, -12),
	])
	parent.add_child(heart)


static func _build_vermilite_cluster(parent: Node2D, base: Vector2, count: int) -> void:
	for i in range(count):
		var crystal := Polygon2D.new()
		crystal.color = COLOR_VERMILITE
		crystal.position = base + Vector2(i * 8 - 4, 0)
		crystal.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(4, -10), Vector2(8, 0),
		])
		parent.add_child(crystal)


static func _add_particles(
	parent: Node2D,
	particle_name: String,
	pos: Vector2,
	amount: int,
	tint: Color,
	lifetime: float,
	drift: float
) -> void:
	var particles := GPUParticles2D.new()
	particles.name = particle_name
	particles.position = pos
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = 2.0
	particles.visibility_rect = Rect2(-1400, -260, 2800, 520)
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(drift, -0.04, 0.0)
	mat.spread = 16.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0.0, -1.5, 0.0)
	mat.scale_min = 0.35
	mat.scale_max = 1.1
	mat.color = tint
	particles.process_material = mat
	parent.add_child(particles)


static func _add_polygon(parent: Node2D, color: Color, points: PackedVector2Array, pos: Vector2) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = pos
	poly.polygon = points
	parent.add_child(poly)
	return poly


static func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
