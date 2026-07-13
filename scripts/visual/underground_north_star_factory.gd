extends RefCounted
class_name UndergroundNorthStarFactory

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")
const Variants := preload("res://scripts/visual/underground_north_star_variants.gd")

const COLOR_STONE := Color(0.3, 0.26, 0.24, 1.0)
const COLOR_WOOD := Color(0.34, 0.24, 0.16, 1.0)
const COLOR_VERM := Color(0.92, 0.18, 0.12, 1.0)
const COLOR_CANDLE := Color(0.92, 0.58, 0.26, 0.5)
const COLOR_CHAIN := Color(0.42, 0.38, 0.36, 1.0)


static func ground_anchor_y(profile: EnvironmentVisualProfile) -> float:
	return profile.ground_surface_y


static func build_cavern_ceiling(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var ceiling := Polygon2D.new()
	ceiling.name = "CavernCeiling"
	ceiling.color = Color(0.06, 0.05, 0.07, 1.0)
	ceiling.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(width, 0), Vector2(width, 220), Vector2(0, 220),
	])
	layer.add_child(ceiling)

	for x in range(0, int(width), 80):
		var stalactite := Polygon2D.new()
		stalactite.color = Color(0.1, 0.08, 0.09, 1.0)
		stalactite.position = Vector2(x + 20, 180)
		stalactite.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(8, 0), Vector2(4, 28 + (x % 40)),
		])
		layer.add_child(stalactite)


static func build_rock_strata(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var strata := Polygon2D.new()
	strata.name = "RockStrata"
	strata.color = Color(0.08, 0.06, 0.07, 1.0)
	strata.polygon = PackedVector2Array([
		Vector2(0, 280), Vector2(180, 240), Vector2(360, 300), Vector2(540, 220),
		Vector2(720, 280), Vector2(900, 210), Vector2(1080, 260), Vector2(width, 230),
		Vector2(width, 420), Vector2(0, 420),
	])
	layer.add_child(strata)


static func build_ancient_depth(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var arch := Polygon2D.new()
	arch.name = "AncientDepthArch"
	arch.color = Color(0.05, 0.04, 0.05, 1.0)
	arch.position = Vector2(width * 0.72, 380)
	arch.polygon = PackedVector2Array([
		Vector2(-100, 0), Vector2(100, 0), Vector2(72, -80), Vector2(0, -120), Vector2(-72, -80),
	])
	layer.add_child(arch)

	var glow := Polygon2D.new()
	glow.name = "MolKharDistantGlow"
	glow.color = Color(0.52, 0.08, 0.06, 0.15)
	glow.position = Vector2(width * 0.82, 320)
	glow.polygon = _circle_polygon(48, 16)
	layer.add_child(glow)


static func build_tunnel_arches(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	var positions: Array[float] = [200.0, 520.0, 880.0]
	for index in range(positions.size()):
		var root := Node2D.new()
		root.name = "TunnelArch_%d" % (index + 1)
		root.position = Vector2(positions[index], ground_y - 40)
		layer.add_child(root)
		var stage := index + 1
		var arch := Polygon2D.new()
		arch.color = Variants.tunnel_wall_for_stage(stage)
		arch.polygon = PackedVector2Array([
			Vector2(-64, 0), Vector2(64, 0), Vector2(48, -72), Vector2(-48, -72),
		])
		root.add_child(arch)
		if stage <= 2:
			_build_wood_beam(root, Vector2(-56, -20))


static func build_gameplay_ground(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var width := profile.playfield_width_px
	var ground_y := ground_anchor_y(profile)

	var floor_stone := Polygon2D.new()
	floor_stone.name = "CatacombFloor"
	floor_stone.color = COLOR_STONE
	floor_stone.polygon = PackedVector2Array([
		Vector2(0, ground_y), Vector2(width, ground_y),
		Vector2(width, ground_y + 48), Vector2(0, ground_y + 48),
	])
	layer.add_child(floor_stone)

	for x in range(0, int(width), 20):
		var tile := Polygon2D.new()
		tile.color = Color(0.26, 0.22, 0.2, 1.0) if int(x / 20) % 2 == 0 else Color(0.22, 0.18, 0.17, 1.0)
		tile.position = Vector2(x, ground_y - 6)
		tile.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(18, 0), Vector2(16, 12), Vector2(2, 12),
		])
		layer.add_child(tile)

	var arena := Polygon2D.new()
	arena.name = "BossArenaFloorMark"
	arena.color = Palette.ORDER_DEEP_RED
	arena.modulate = Color(1, 1, 1, 0.2)
	arena.polygon = PackedVector2Array([
		Vector2(60, ground_y - 4), Vector2(1140, ground_y - 4),
		Vector2(1140, ground_y + 2), Vector2(60, ground_y + 2),
	])
	layer.add_child(arena)


static func build_gameplay_structures(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	_build_colossal_statue_art(layer, Vector2(980, ground_y - 148))
	_build_ritual_altar(layer, Vector2(880, ground_y - 16))
	_build_wood_shoring_wall(layer, Vector2(160, ground_y - 36))
	_build_hidden_passage_frame(layer, Vector2(1080, ground_y - 28))


static func build_props_layer(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)
	_build_chain_drape(layer, Vector2(300, ground_y - 32))
	_build_candle_cluster(layer, Vector2(360, ground_y - 48), 4)
	_build_root_cluster(layer, Vector2(560, ground_y - 12))
	_build_bone_vestige(layer, Vector2(640, ground_y - 4))
	_build_vermilite_vein(layer, Vector2(820, ground_y - 6))
	_build_boss_arena_posts(layer, Vector2(600, ground_y))


static func build_lighting(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var ground_y := ground_anchor_y(profile)

	var fill := DirectionalLight2D.new()
	fill.name = "CavernCoolFill"
	fill.color = Color(0.22, 0.18, 0.24, 1.0)
	fill.energy = 0.16
	fill.shadow_enabled = false
	layer.add_child(fill)

	for index in range(5):
		var x_positions: Array[float] = [180.0, 360.0, 540.0, 820.0, 1020.0]
		var candle := PointLight2D.new()
		candle.name = "CandleLight_%d" % (index + 1)
		candle.position = Vector2(x_positions[index], ground_y - 40)
		candle.color = Color(0.95, 0.62, 0.28, 1.0)
		candle.energy = 0.38 - float(index) * 0.04
		candle.texture_scale = 0.32
		candle.shadow_enabled = false
		layer.add_child(candle)

	var verm := PointLight2D.new()
	verm.name = "VermilitePrisonGlow"
	verm.position = Vector2(900, ground_y - 24)
	verm.color = Palette.VERMILITE_SATURATED
	verm.energy = 0.28
	verm.texture_scale = 0.45
	verm.shadow_enabled = false
	layer.add_child(verm)

	var statue := PointLight2D.new()
	statue.name = "StatueBacklight"
	statue.position = Vector2(980, ground_y - 120)
	statue.color = Palette.MOL_INNER_RED
	statue.energy = 0.18
	statue.texture_scale = 0.55
	statue.shadow_enabled = false
	layer.add_child(statue)


static func build_atmosphere(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var center_x := profile.playfield_width_px * 0.5
	_add_particles(layer, "CavernDust", Vector2(center_x, 640), 28, Color(0.42, 0.36, 0.32, 0.12), 8.0, 0.03)
	_add_particles(layer, "VermiliteMotes", Vector2(900, 700), 14, Color(0.95, 0.22, 0.14, 0.22), 5.0, 0.02)
	_add_particles(layer, "SpiritWhisper", Vector2(1000, 620), 10, Color(0.62, 0.12, 0.1, 0.15), 6.0, 0.01)


static func build_foreground(layer: Parallax2D, profile: EnvironmentVisualProfile) -> void:
	var pillar := Polygon2D.new()
	pillar.name = "ForegroundStalagmite"
	pillar.color = Color(0.04, 0.03, 0.04, 0.55)
	pillar.position = Vector2(80, 560)
	pillar.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(24, 0), Vector2(12, 320),
	])
	layer.add_child(pillar)

	var veil := Polygon2D.new()
	veil.name = "MolThreatVeil"
	veil.color = Color(0.22, 0.04, 0.06, 0.1)
	veil.polygon = PackedVector2Array([
		Vector2(700, 520), Vector2(profile.playfield_width_px, 520),
		Vector2(profile.playfield_width_px, 700), Vector2(700, 700),
	])
	layer.add_child(veil)


static func build_finale_visual_hooks(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	var ground_y := ground_anchor_y(profile)

	var brand_glow := Polygon2D.new()
	brand_glow.name = "FinaleRedBrandGlow"
	brand_glow.add_to_group("chapter_zero_finale_red_brand_glow")
	brand_glow.modulate = Color(1, 1, 1, 0)
	brand_glow.position = Vector2(780, ground_y - 60)
	brand_glow.color = Palette.ORDER_BURNT_RED
	brand_glow.polygon = _circle_polygon(36, 16)
	layer.add_child(brand_glow)

	var mol_shadow := Polygon2D.new()
	mol_shadow.name = "FinaleMolKharShadow"
	mol_shadow.add_to_group("chapter_zero_finale_mol_shadow")
	mol_shadow.modulate = Color(1, 1, 1, 0)
	mol_shadow.position = Vector2(600, ground_y - 200)
	mol_shadow.color = Palette.MOL_ABNORMAL_SHADOW
	mol_shadow.polygon = PackedVector2Array([
		Vector2(-120, 80), Vector2(120, 80), Vector2(80, -40), Vector2(40, -160),
		Vector2(-40, -160), Vector2(-80, -40),
	])
	layer.add_child(mol_shadow)

	var arcturus := Polygon2D.new()
	arcturus.name = "FinaleArcturusSilhouette"
	arcturus.add_to_group("chapter_zero_finale_arcturus")
	arcturus.modulate = Color(1, 1, 1, 0)
	arcturus.position = Vector2(920, ground_y - 80)
	arcturus.color = Palette.ORDER_BLACK
	arcturus.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0), Vector2(6, -48), Vector2(-6, -48),
		Vector2(-14, -52), Vector2(14, -52),
	])
	layer.add_child(arcturus)


static func _build_colossal_statue_art(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "ColossalStatueArt"
	root.position = base
	parent.add_child(root)

	var body := Polygon2D.new()
	body.color = Color(0.14, 0.12, 0.14, 1.0)
	body.polygon = PackedVector2Array([
		Vector2(-72, 148), Vector2(72, 148), Vector2(56, 40), Vector2(24, -52),
		Vector2(-24, -52), Vector2(-56, 40),
	])
	root.add_child(body)

	var heart_void := Polygon2D.new()
	heart_void.color = Palette.MOL_VOID
	heart_void.position = Vector2(0, 20)
	heart_void.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(10, -18), Vector2(18, -8), Vector2(0, 12), Vector2(-18, -8), Vector2(-10, -18),
	])
	root.add_child(heart_void)


static func _build_ritual_altar(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "RitualAltar"
	root.position = base
	parent.add_child(root)
	_add_rect(root, Palette.ORDER_RITUAL_STONE, Vector2(-28, -16), Vector2(56, 16))
	_add_rect(root, Palette.ORDER_BURNT_RED, Vector2(-8, -24), Vector2(16, 8))


static func _build_wood_shoring_wall(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "WoodShoring"
	root.position = base
	parent.add_child(root)
	for i in range(3):
		_build_wood_beam(root, Vector2(i * 28 - 28, 0))


static func _build_wood_beam(parent: Node2D, pos: Vector2) -> void:
	var beam := Polygon2D.new()
	beam.color = COLOR_WOOD
	beam.position = pos
	beam.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(4, 0), Vector2(3, -48), Vector2(-3, -48),
	])
	parent.add_child(beam)


static func _build_hidden_passage_frame(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "HiddenPassageFrame"
	root.position = base
	parent.add_child(root)
	var frame := Polygon2D.new()
	frame.color = Palette.ORDER_BLACK
	frame.polygon = PackedVector2Array([
		Vector2(-44, 44), Vector2(44, 44), Vector2(36, -20), Vector2(0, -36), Vector2(-36, -20),
	])
	root.add_child(frame)


static func _build_chain_drape(parent: Node2D, base: Vector2) -> void:
	for i in range(4):
		var link := Polygon2D.new()
		link.color = COLOR_CHAIN
		link.position = base + Vector2(i * 6 - 9, -i * 10)
		link.polygon = PackedVector2Array([
			Vector2(-4, 0), Vector2(4, 0), Vector2(4, -8), Vector2(-4, -8),
		])
		parent.add_child(link)


static func _build_candle_cluster(parent: Node2D, base: Vector2, count: int) -> void:
	for i in range(count):
		var candle := Polygon2D.new()
		candle.color = COLOR_CANDLE
		candle.position = base + Vector2(i * 10 - 15, 0)
		candle.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3, -12), Vector2(6, 0)])
		parent.add_child(candle)


static func _build_root_cluster(parent: Node2D, base: Vector2) -> void:
	for i in range(3):
		var root := Polygon2D.new()
		root.color = Color(0.28, 0.2, 0.14, 1.0)
		root.position = base + Vector2(i * 14 - 14, 0)
		root.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(8, -18), Vector2(16, 0),
		])
		parent.add_child(root)


static func _build_bone_vestige(parent: Node2D, base: Vector2) -> void:
	_add_rect(parent, Color(0.62, 0.58, 0.52, 0.65), base + Vector2(-12, -4), Vector2(24, 4))
	_add_rect(parent, Color(0.62, 0.58, 0.52, 0.55), base + Vector2(-4, -8), Vector2(4, 8))


static func _build_vermilite_vein(parent: Node2D, base: Vector2) -> void:
	for i in range(3):
		var shard := Polygon2D.new()
		shard.color = COLOR_VERM
		shard.position = base + Vector2(i * 10 - 10, 0)
		shard.polygon = PackedVector2Array([Vector2(0, 0), Vector2(4, -14), Vector2(8, 0)])
		parent.add_child(shard)


static func _build_boss_arena_posts(parent: Node2D, base: Vector2) -> void:
	var root := Node2D.new()
	root.name = "BossArenaPosts"
	root.position = base
	parent.add_child(root)
	for x in [-240, -120, 0, 120, 240, 360, 480]:
		var post := Polygon2D.new()
		post.color = Palette.ORDER_BLACK
		post.position = Vector2(x, 0)
		post.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(2, 0), Vector2(2, -20), Vector2(-2, -20),
		])
		root.add_child(post)


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
	particles.visibility_rect = Rect2(-800, -260, 1600, 520)
	particles.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(drift, -0.02, 0.0)
	mat.spread = 12.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0.0, -0.5, 0.0)
	mat.scale_min = 0.2
	mat.scale_max = 0.7
	mat.color = tint
	particles.process_material = mat
	parent.add_child(particles)


static func _add_rect(parent: Node2D, color: Color, pos: Vector2, size: Vector2) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = pos
	poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y),
	])
	parent.add_child(poly)


static func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
