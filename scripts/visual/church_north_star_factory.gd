extends RefCounted
class_name ChurchNorthStarFactory

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

const COLOR_STONE_LIGHT := Color(0.42, 0.38, 0.36, 1.0)
const COLOR_STONE_MID := Color(0.34, 0.3, 0.28, 1.0)
const COLOR_STONE_DARK := Color(0.22, 0.18, 0.17, 1.0)
const COLOR_COBBLE_A := Color(0.3, 0.26, 0.24, 1.0)
const COLOR_COBBLE_B := Color(0.26, 0.22, 0.21, 1.0)
const COLOR_VERMILITE := Color(0.92, 0.18, 0.12, 1.0)
const COLOR_HEART := Color(0.78, 0.12, 0.1, 1.0)
const COLOR_CANDLE := Color(0.92, 0.62, 0.28, 0.45)


static func ground_anchor_y(profile: EnvironmentVisualProfile) -> float:
	return profile.ground_surface_y


static func build_enriched_sky(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var top := Polygon2D.new()
	top.name = "ChurchSkyTop"
	top.color = Color(0.1, 0.08, 0.14, 1.0)
	top.polygon = PackedVector2Array([
		Vector2(0, 60), Vector2(width, 60), Vector2(width, 240), Vector2(0, 240),
	])
	layer.add_child(top)

	var haze := Polygon2D.new()
	haze.name = "ChurchVioletHaze"
	haze.color = Color(0.28, 0.14, 0.18, 0.55)
	haze.polygon = PackedVector2Array([
		Vector2(0, 180), Vector2(width, 180), Vector2(width, 320), Vector2(0, 320),
	])
	layer.add_child(haze)

	var moon := Polygon2D.new()
	moon.name = "PaleMoon"
	moon.color = Color(0.72, 0.68, 0.62, 0.35)
	moon.position = Vector2(width * 0.78, 140)
	moon.polygon = _circle_polygon(18, 14)
	layer.add_child(moon)


static func build_enriched_mountains(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var ridge := Polygon2D.new()
	ridge.name = "ChurchHillSilhouette"
	ridge.color = Color(0.08, 0.06, 0.08, 1.0)
	ridge.polygon = PackedVector2Array([
		Vector2(0, 400), Vector2(200, 300), Vector2(420, 360), Vector2(640, 260),
		Vector2(900, 320), Vector2(1180, 240), Vector2(1460, 300), Vector2(width, 280),
		Vector2(width, 400), Vector2(0, 400),
	])
	layer.add_child(ridge)


static func build_distant_church(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var center_x := width * 0.52

	var nave := Polygon2D.new()
	nave.name = "DistantChurchNave"
	nave.color = Color(0.06, 0.05, 0.06, 1.0)
	nave.position = Vector2(center_x, 380)
	nave.polygon = PackedVector2Array([
		Vector2(-120, 0), Vector2(120, 0), Vector2(110, -160), Vector2(-110, -160),
	])
	layer.add_child(nave)

	var spire := Polygon2D.new()
	spire.name = "DistantChurchSpire"
	spire.color = Color(0.05, 0.04, 0.05, 1.0)
	spire.position = Vector2(center_x + 40, 380)
	spire.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0), Vector2(0, -220),
	])
	layer.add_child(spire)

	var bell_glow := Polygon2D.new()
	bell_glow.name = "DistantBellGlow"
	bell_glow.color = Color(0.62, 0.22, 0.14, 0.12)
	bell_glow.position = Vector2(center_x + 40, 200)
	bell_glow.polygon = _circle_polygon(22, 12)
	layer.add_child(bell_glow)

	var flank := Polygon2D.new()
	flank.name = "DistantClosedWing"
	flank.color = Color(0.07, 0.06, 0.07, 1.0)
	flank.position = Vector2(center_x - 200, 380)
	flank.polygon = PackedVector2Array([
		Vector2(-60, 0), Vector2(60, 0), Vector2(50, -100), Vector2(-50, -100),
	])
	layer.add_child(flank)


static func build_mid_buildings(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	var specs: Array[Dictionary] = [
		{"pos": Vector2(280, ground_y), "w": 100, "h": 148, "roof": 24},
		{"pos": Vector2(1180, ground_y), "w": 110, "h": 156, "roof": 26},
	]
	for index in range(specs.size()):
		var data: Dictionary = specs[index]
		var root := Node2D.new()
		root.name = "MidChurchBuilding_%02d" % (index + 1)
		root.position = data["pos"]
		layer.add_child(root)
		_build_vertical_facade(
			root,
			float(data["w"]),
			float(data["h"]),
			float(data["roof"]),
			COLOR_STONE_DARK,
			false
		)


static func build_gameplay_ground(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var ground_y := ground_anchor_y(profile)

	var stone := Polygon2D.new()
	stone.name = "PlazaStone"
	stone.color = COLOR_STONE_MID
	stone.polygon = PackedVector2Array([
		Vector2(0, ground_y), Vector2(width, ground_y),
		Vector2(width, ground_y + 52), Vector2(0, ground_y + 52),
	])
	layer.add_child(stone)

	for x in range(0, int(width), 24):
		var cobble := Polygon2D.new()
		cobble.color = COLOR_COBBLE_A if int(x / 24) % 2 == 0 else COLOR_COBBLE_B
		cobble.position = Vector2(x, ground_y - 8)
		cobble.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(20, 0), Vector2(18, 14), Vector2(2, 14),
		])
		layer.add_child(cobble)

	var plaza_ring := Polygon2D.new()
	plaza_ring.name = "ArenaPlazaRing"
	plaza_ring.color = Palette.ORDER_RITUAL_STONE
	plaza_ring.modulate = Color(1, 1, 1, 0.35)
	plaza_ring.polygon = PackedVector2Array([
		Vector2(320, ground_y - 6), Vector2(1080, ground_y - 6),
		Vector2(1080, ground_y + 2), Vector2(320, ground_y + 2),
	])
	layer.add_child(plaza_ring)


static func build_gameplay_structures(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	_build_bell_tower(layer, Vector2(900, ground_y - 200))
	_build_main_entrance_arch(layer, Vector2(820, ground_y))
	_build_penitent_alcove_wall(layer, Vector2(320, ground_y - 48))


static func build_props_layer(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	_build_order_statue(layer, Vector2(560, ground_y - 8))
	_build_external_altar(layer, Vector2(680, ground_y - 12))
	_build_guard_silhouette(layer, Vector2(400, ground_y))
	_build_guard_silhouette(layer, Vector2(1240, ground_y))
	_build_candle_row(layer, Vector2(1080, ground_y - 36), 4)
	_build_heart_symbol_decal(layer, Vector2(600, ground_y - 2))
	_build_vermilite_in_stone(layer, Vector2(900, ground_y - 6))
	_build_closed_building_sign(layer, Vector2(760, ground_y - 120))


static func build_lighting(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	if DisplayServer.get_name() == "headless":
		return

	var ground_y := ground_anchor_y(profile)

	var ambient := DirectionalLight2D.new()
	ambient.name = "ChurchCoolFill"
	ambient.color = Color(0.32, 0.26, 0.34, 1.0)
	ambient.energy = 0.22
	ambient.shadow_enabled = false
	layer.add_child(ambient)

	var key := DirectionalLight2D.new()
	key.name = "ChurchMoonKey"
	key.color = Color(0.68, 0.62, 0.72, 1.0)
	key.energy = 0.14
	key.rotation = -0.4
	key.shadow_enabled = false
	layer.add_child(key)

	var lantern_positions: Array[Vector2] = [
		Vector2(480, ground_y - 8),
		Vector2(680, ground_y - 8),
		Vector2(1260, ground_y - 8),
	]
	for index in range(lantern_positions.size()):
		var point := PointLight2D.new()
		point.name = "ChurchLantern_%d" % (index + 1)
		point.position = lantern_positions[index]
		point.color = Color(0.82, 0.55, 0.28, 1.0)
		point.energy = 0.55
		point.texture_scale = 0.36
		point.shadow_enabled = false
		layer.add_child(point)

	var bell := PointLight2D.new()
	bell.name = "BellTowerGlow"
	bell.position = Vector2(900, ground_y - 180)
	bell.color = Color(0.78, 0.28, 0.16, 1.0)
	bell.energy = 0.22
	bell.texture_scale = 0.48
	bell.shadow_enabled = false
	layer.add_child(bell)

	var verm := PointLight2D.new()
	verm.name = "VermiliteStoneGlow"
	verm.position = Vector2(900, ground_y - 4)
	verm.color = Palette.VERMILITE_SATURATED
	verm.energy = 0.18
	verm.texture_scale = 0.32
	verm.shadow_enabled = false
	layer.add_child(verm)


static func build_atmosphere(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	if DisplayServer.get_name() == "headless":
		return

	var center_x := profile.playfield_width_px * 0.5
	_add_particles(layer, "ChurchMist", Vector2(center_x, 620), 24, Color(0.42, 0.36, 0.44, 0.1), 9.0, 0.04)
	_add_particles(layer, "AshMotes", Vector2(center_x, 680), 16, Color(0.52, 0.38, 0.32, 0.12), 7.0, 0.06)
	_add_particles(layer, "VermiliteWhisper", Vector2(900, 760), 8, Color(0.95, 0.22, 0.14, 0.18), 5.0, 0.02)


static func build_foreground(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var pillar := Polygon2D.new()
	pillar.name = "ForegroundPillarShadow"
	pillar.color = Color(0.04, 0.03, 0.04, 0.5)
	pillar.position = Vector2(160, 520)
	pillar.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(28, 0), Vector2(20, 360), Vector2(-8, 360),
	])
	layer.add_child(pillar)

	var veil := Polygon2D.new()
	veil.name = "ThreatVeil"
	veil.color = Color(0.18, 0.08, 0.1, 0.08)
	veil.polygon = PackedVector2Array([
		Vector2(0, 520), Vector2(profile.playfield_width_px, 520),
		Vector2(profile.playfield_width_px, 680), Vector2(0, 680),
	])
	layer.add_child(veil)


static func _build_vertical_facade(
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
	roof.color = Palette.ORDER_BLACK
	roof.polygon = PackedVector2Array([
		Vector2(-half_w - 4, -height), Vector2(0, -height - roof_h - 12), Vector2(half_w + 4, -height),
	])
	parent.add_child(roof)

	if lit_windows:
		for wx in [-width * 0.25, width * 0.25]:
			var window := Polygon2D.new()
			window.color = COLOR_CANDLE
			window.position = Vector2(wx, -height * 0.62)
			window.polygon = PackedVector2Array([
				Vector2(-6, -14), Vector2(6, -14), Vector2(6, 14), Vector2(-6, 14),
			])
			parent.add_child(window)

	var heart := Polygon2D.new()
	heart.name = "OrderHeartMark"
	heart.color = COLOR_HEART
	heart.modulate = Color(1, 1, 1, 0.55)
	heart.position = Vector2(0, -height * 0.42)
	heart.polygon = PackedVector2Array([
		Vector2(0, -4), Vector2(4, -8), Vector2(8, -4), Vector2(0, 4), Vector2(-8, -4), Vector2(-4, -8),
	])
	parent.add_child(heart)


static func _build_bell_tower(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "BellTowerStructure"
	root.position = base
	parent.add_child(root)

	var shaft := Polygon2D.new()
	shaft.color = COLOR_STONE_DARK
	shaft.polygon = PackedVector2Array([
		Vector2(-20, 200), Vector2(20, 200), Vector2(14, 0), Vector2(-14, 0),
	])
	root.add_child(shaft)

	var belfry := Polygon2D.new()
	belfry.color = COLOR_STONE_MID
	belfry.position = Vector2(0, -8)
	belfry.polygon = PackedVector2Array([
		Vector2(-28, 0), Vector2(28, 0), Vector2(22, -36), Vector2(-22, -36),
	])
	root.add_child(belfry)

	var bell_shape := Polygon2D.new()
	bell_shape.name = "BellSilhouette"
	bell_shape.color = Palette.METAL_COOL
	bell_shape.position = Vector2(0, -20)
	bell_shape.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(10, 0), Vector2(6, -16), Vector2(-6, -16),
	])
	root.add_child(bell_shape)


static func _build_main_entrance_arch(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "MainChurchEntrance"
	root.position = base
	parent.add_child(root)

	var frame := Polygon2D.new()
	frame.color = COLOR_STONE_LIGHT
	frame.polygon = PackedVector2Array([
		Vector2(-56, 0), Vector2(56, 0), Vector2(48, -96), Vector2(32, -112), Vector2(-32, -112), Vector2(-48, -96),
	])
	root.add_child(frame)

	var doors := Polygon2D.new()
	doors.color = Palette.ORDER_BLACK
	doors.position = Vector2(-24, -88)
	doors.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(48, 0), Vector2(48, -88), Vector2(0, -88),
	])
	root.add_child(doors)


static func _build_penitent_alcove_wall(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "PenitentAlcoveWall"
	root.position = base
	parent.add_child(root)
	_add_polygon(root, COLOR_STONE_DARK, PackedVector2Array([
		Vector2(-80, 0), Vector2(80, 0), Vector2(72, -72), Vector2(-72, -72),
	]), Vector2.ZERO)


static func _build_order_statue(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "OrderStatueLarge"
	root.position = base
	parent.add_child(root)
	_add_polygon(root, COLOR_STONE_LIGHT, PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0), Vector2(6, -48), Vector2(-6, -48),
	]), Vector2.ZERO)
	_add_polygon(root, COLOR_STONE_MID, PackedVector2Array([
		Vector2(-14, -48), Vector2(14, -48), Vector2(10, -58), Vector2(-10, -58),
	]), Vector2.ZERO)


static func _build_external_altar(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "ExternalAltar"
	root.position = base
	parent.add_child(root)
	_add_polygon(root, Palette.ORDER_RITUAL_STONE, PackedVector2Array([
		Vector2(-32, 0), Vector2(32, 0), Vector2(28, -20), Vector2(-28, -20),
	]), Vector2.ZERO)
	_add_polygon(root, COLOR_HEART, PackedVector2Array([
		Vector2(0, -24), Vector2(6, -32), Vector2(10, -24), Vector2(0, -14), Vector2(-10, -24), Vector2(-6, -32),
	]), Vector2.ZERO)


static func _build_guard_silhouette(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "GuardSilhouette"
	root.position = base
	parent.add_child(root)
	_add_polygon(root, Palette.ORDER_BLACK, PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0), Vector2(4, -28), Vector2(-4, -28),
	]), Vector2.ZERO)
	_add_polygon(root, Palette.ORDER_BLACK, PackedVector2Array([
		Vector2(-10, -28), Vector2(10, -28), Vector2(8, -36), Vector2(-8, -36),
	]), Vector2.ZERO)


static func _build_candle_row(parent: Node2D, base: Vector2, count: int) -> void:
	for i in range(count):
		var candle := Polygon2D.new()
		candle.color = COLOR_CANDLE
		candle.position = base + Vector2(i * 12 - 18, 0)
		candle.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(4, -12), Vector2(8, 0),
		])
		parent.add_child(candle)


static func _build_heart_symbol_decal(parent: Node2D, base: Vector2) -> void:
	var heart := Polygon2D.new()
	heart.name = "PlazaHeartSymbol"
	heart.position = base
	heart.color = COLOR_HEART
	heart.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(6, -12), Vector2(10, -6), Vector2(0, 4), Vector2(-10, -6), Vector2(-6, -12),
	])
	parent.add_child(heart)


static func _build_vermilite_in_stone(parent: Node2D, base: Vector2) -> void:
	for i in range(3):
		var shard := Polygon2D.new()
		shard.color = COLOR_VERMILITE
		shard.position = base + Vector2(i * 8 - 8, 0)
		shard.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3, -10), Vector2(6, 0)])
		parent.add_child(shard)


static func _build_closed_building_sign(parent: Node2D, base: Vector2) -> void:
	var sign := Polygon2D.new()
	sign.name = "ClosedBuildingSign"
	sign.position = base
	sign.color = Palette.ORDER_DEEP_RED
	sign.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(20, 0), Vector2(20, 14), Vector2(-20, 14),
	])
	parent.add_child(sign)


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
	particles.visibility_rect = Rect2(-1000, -260, 2000, 520)
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(drift, -0.02, 0.0)
	mat.spread = 10.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0.0, -0.8, 0.0)
	mat.scale_min = 0.25
	mat.scale_max = 0.8
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
