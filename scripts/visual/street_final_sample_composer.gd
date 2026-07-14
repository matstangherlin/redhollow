extends RefCounted
class_name StreetFinalSampleComposer

## Upgrades ONLY the sample X band to a near-final visual candidate.
## Original procedural silhouettes — not internet art, not moodboard copies.
## All geometry tagged PLACEHOLDER_CANDIDATE until real PNGs are approved.

const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")
const Factory := preload("res://scripts/visual/street_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

const LAYER_SKY := "Layer01_Sky"
const LAYER_MOUNTAINS := "Layer02_FarMountains"
const LAYER_TOWN := "Layer03_DistantTown"
const LAYER_MID := "Layer04_MidgroundBuildings"
const LAYER_GROUND := "Layer05_GameplayGround"
const LAYER_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACT := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_ATMOSPHERE := "Layer10_Atmosphere"
const LAYER_FOREGROUND := "Layer11_Foreground"
const LAYER_DEBUG := "Layer12_Debug"

const ROOT_NAME := "FinalSampleRoot"


static func apply(presentation: StreetArtPresentation, profile: EnvironmentVisualProfile) -> Dictionary:
	remove(presentation)
	var ground_y := Factory.ground_anchor_y(profile)
	var root := Node2D.new()
	root.name = ROOT_NAME
	root.z_index = 8
	presentation.add_child(root)

	var stats := {
		"band_x_min": Spec.SAMPLE_X_MIN,
		"band_x_max": Spec.SAMPLE_X_MAX,
		"width_px": Spec.SAMPLE_WIDTH_PX,
		"materials": 0,
		"props": 0,
		"lights": 0,
		"particles": 0,
		"placeholder_tags": 0,
	}

	_build_band_frame(root, ground_y, stats)
	_build_ground_materials(root, ground_y, stats)
	_build_saloon_wood_detail(root, ground_y, stats)
	_build_statue_stone_detail(root, ground_y, stats)
	_build_lamp_metal_cloth(root, ground_y, stats)
	_build_platform_edge(root, ground_y, stats)
	_build_secret_cue(root, ground_y, stats)
	_build_order_heart_mark(root, ground_y, stats)
	_build_vermilite_accent(root, ground_y, stats)
	_build_brawler_showcase_silhouette(root, ground_y, stats)
	_build_calder_highlight_ring(root, ground_y, stats)
	_build_elias_cue(root, ground_y, stats)
	_build_sample_lighting(root, ground_y, stats)
	_build_sample_atmosphere(root, ground_y, stats)
	_build_foreground_shadow(root, ground_y, stats)
	_build_debug_overlay(presentation, ground_y, stats)
	_nudge_sky_mountains_for_sample(presentation, stats)
	return stats


static func remove(presentation: StreetArtPresentation) -> void:
	var existing := presentation.get_node_or_null(ROOT_NAME)
	if existing != null:
		existing.free()
	var debug_layer := presentation.get_node_or_null(LAYER_DEBUG) as Node2D
	if debug_layer != null:
		var badge := debug_layer.get_node_or_null("FinalSampleBandBadge")
		if badge != null:
			badge.free()
	var sky := presentation.get_node_or_null(LAYER_SKY) as Node2D
	if sky != null:
		var bloom := sky.get_node_or_null("SampleSunsetBloom")
		if bloom != null:
			bloom.free()


static func _tag(node: Node, label: String) -> void:
	node.set_meta("asset_kind", Spec.PLACEHOLDER_TAG)
	node.set_meta("candidate_label", label)
	if node is CanvasItem:
		(node as CanvasItem).set_meta("placeholder_candidate", true)


static func _poly(
	parent: Node2D,
	name: String,
	color: Color,
	points: PackedVector2Array,
	label: String,
	stats: Dictionary
) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = name
	poly.color = color
	poly.polygon = points
	_tag(poly, label)
	parent.add_child(poly)
	stats["materials"] = int(stats.get("materials", 0)) + 1
	stats["placeholder_tags"] = int(stats.get("placeholder_tags", 0)) + 1
	return poly


static func _build_band_frame(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var frame := Node2D.new()
	frame.name = "BandFrame"
	root.add_child(frame)
	# Soft vignette edges so sample vs rest of street is readable without ending the world.
	_poly(
		frame,
		"BandFloorTint",
		Color(0.22, 0.14, 0.1, 0.18),
		PackedVector2Array([
			Vector2(Spec.SAMPLE_X_MIN, ground_y - 2),
			Vector2(Spec.SAMPLE_X_MAX, ground_y - 2),
			Vector2(Spec.SAMPLE_X_MAX, ground_y + 28),
			Vector2(Spec.SAMPLE_X_MIN, ground_y + 28),
		]),
		"band_tint",
		stats
	)


static func _build_ground_materials(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var dirt := Node2D.new()
	dirt.name = "DirtEarth"
	root.add_child(dirt)
	# Layered dirt with cracks — not a single flat rect.
	_poly(
		dirt,
		"DirtBase",
		Palette.EARTH_MID,
		PackedVector2Array([
			Vector2(110, ground_y), Vector2(890, ground_y),
			Vector2(890, ground_y + 22), Vector2(110, ground_y + 22),
		]),
		"material_earth",
		stats
	)
	for i in range(8):
		var x0 := 140.0 + float(i) * 90.0
		_poly(
			dirt,
			"DirtCrack_%d" % i,
			Color(0.18, 0.12, 0.08, 0.55),
			PackedVector2Array([
				Vector2(x0, ground_y + 4), Vector2(x0 + 28, ground_y + 6),
				Vector2(x0 + 24, ground_y + 8), Vector2(x0 - 2, ground_y + 7),
			]),
			"material_earth_crack",
			stats
		)
	# Boardwalk planks near saloon
	for i in range(5):
		var px := 250.0 + float(i) * 18.0
		_poly(
			dirt,
			"WoodPlank_%d" % i,
			Color(0.4, 0.26, 0.16, 1.0).darkened(0.04 * (i % 2)),
			PackedVector2Array([
				Vector2(px, ground_y - 2), Vector2(px + 16, ground_y - 2),
				Vector2(px + 16, ground_y + 6), Vector2(px, ground_y + 6),
			]),
			"material_wood_boardwalk",
			stats
		)
		_poly(
			dirt,
			"WoodGrain_%d" % i,
			Color(0.28, 0.16, 0.1, 0.45),
			PackedVector2Array([
				Vector2(px + 2, ground_y), Vector2(px + 14, ground_y + 1),
				Vector2(px + 14, ground_y + 2), Vector2(px + 2, ground_y + 1),
			]),
			"material_wood_grain",
			stats
		)


static func _build_saloon_wood_detail(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var saloon := Node2D.new()
	saloon.name = "SaloonCandidate"
	saloon.position = Vector2(300, ground_y - 64)
	root.add_child(saloon)
	_poly(
		saloon,
		"FacadeBody",
		Color(0.42, 0.28, 0.18, 1.0),
		PackedVector2Array([
			Vector2(-96, -64), Vector2(96, -64), Vector2(96, 64), Vector2(-96, 64),
		]),
		"material_wood_facade",
		stats
	)
	# Vertical siding
	for i in range(10):
		var x := -90.0 + float(i) * 18.0
		_poly(
			saloon,
			"Siding_%d" % i,
			Color(0.36, 0.22, 0.14, 0.55),
			PackedVector2Array([
				Vector2(x, -60), Vector2(x + 2, -60), Vector2(x + 2, 60), Vector2(x, 60),
			]),
			"material_wood_siding",
			stats
		)
	_poly(
		saloon,
		"Roof",
		Color(0.2, 0.14, 0.12, 1.0),
		PackedVector2Array([
			Vector2(-108, -64), Vector2(0, -92), Vector2(108, -64),
		]),
		"material_wood_roof",
		stats
	)
	_poly(
		saloon,
		"Door",
		Color(0.22, 0.14, 0.1, 1.0),
		PackedVector2Array([
			Vector2(-18, 8), Vector2(18, 8), Vector2(18, 64), Vector2(-18, 64),
		]),
		"material_wood_door",
		stats
	)
	_poly(
		saloon,
		"WindowGlow",
		Color(0.95, 0.55, 0.22, 0.5),
		PackedVector2Array([
			Vector2(36, -20), Vector2(68, -20), Vector2(68, 12), Vector2(36, 12),
		]),
		"material_glow_window",
		stats
	)
	_poly(
		saloon,
		"CurtainCloth",
		Color(0.55, 0.18, 0.16, 0.85),
		PackedVector2Array([
			Vector2(40, -18), Vector2(50, -18), Vector2(48, 10), Vector2(42, 10),
		]),
		"material_cloth",
		stats
	)
	_poly(
		saloon,
		"SignBoard",
		Color(0.3, 0.18, 0.12, 1.0),
		PackedVector2Array([
			Vector2(-40, -78), Vector2(40, -78), Vector2(40, -58), Vector2(-40, -58),
		]),
		"material_wood_sign",
		stats
	)
	_poly(
		saloon,
		"SignHeart",
		Palette.ORDER_BURNT_RED,
		_heart_poly(Vector2(0, -68), 7.0),
		"ordem_coracao_rubro",
		stats
	)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_statue_stone_detail(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var statue := Node2D.new()
	statue.name = "StatueCandidate"
	statue.position = Vector2(520, ground_y)
	root.add_child(statue)
	_poly(
		statue,
		"Pedestal",
		Color(0.36, 0.32, 0.3, 1.0),
		PackedVector2Array([
			Vector2(-18, -8), Vector2(18, -8), Vector2(16, 0), Vector2(-16, 0),
		]),
		"material_stone_pedestal",
		stats
	)
	_poly(
		statue,
		"BodyStone",
		Color(0.42, 0.38, 0.36, 1.0),
		PackedVector2Array([
			Vector2(-10, -48), Vector2(10, -48), Vector2(12, -8), Vector2(-12, -8),
		]),
		"material_stone_body",
		stats
	)
	_poly(
		statue,
		"Hood",
		Color(0.28, 0.24, 0.26, 1.0),
		PackedVector2Array([
			Vector2(-12, -56), Vector2(12, -56), Vector2(8, -44), Vector2(-8, -44),
		]),
		"material_stone_hood",
		stats
	)
	_poly(
		statue,
		"HeartInset",
		Color(0.72, 0.1, 0.08, 0.9),
		_heart_poly(Vector2(0, -30), 5.0),
		"terror_religioso",
		stats
	)
	# Mortar cracks
	_poly(
		statue,
		"Crack",
		Color(0.18, 0.14, 0.12, 0.7),
		PackedVector2Array([
			Vector2(-2, -44), Vector2(0, -20), Vector2(1, -20), Vector2(-1, -44),
		]),
		"material_stone_crack",
		stats
	)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_lamp_metal_cloth(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var lamp := Node2D.new()
	lamp.name = "LampCandidate"
	lamp.position = Vector2(180, ground_y)
	root.add_child(lamp)
	_poly(
		lamp,
		"PoleMetal",
		Color(0.22, 0.22, 0.24, 1.0),
		PackedVector2Array([
			Vector2(-3, -92), Vector2(3, -92), Vector2(4, 0), Vector2(-4, 0),
		]),
		"material_metal_pole",
		stats
	)
	for y in [ -70.0, -50.0, -30.0 ]:
		_poly(
			lamp,
			"Rivet_%d" % int(absf(y)),
			Color(0.55, 0.5, 0.4, 1.0),
			PackedVector2Array([
				Vector2(-5, y), Vector2(-2, y - 2), Vector2(0, y), Vector2(-2, y + 2),
			]),
			"material_metal_rivet",
			stats
		)
	_poly(
		lamp,
		"LanternCage",
		Color(0.35, 0.28, 0.18, 1.0),
		PackedVector2Array([
			Vector2(-10, -104), Vector2(10, -104), Vector2(8, -88), Vector2(-8, -88),
		]),
		"material_metal_cage",
		stats
	)
	_poly(
		lamp,
		"FlameGlow",
		Color(1.0, 0.62, 0.28, 0.65),
		PackedVector2Array([
			Vector2(-5, -100), Vector2(5, -100), Vector2(4, -90), Vector2(-4, -90),
		]),
		"lampiao_glow",
		stats
	)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_platform_edge(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var plat := Node2D.new()
	plat.name = "PlatformCandidate"
	# PlatformA center ~560, top ~808 visually; ground surface 876, platform y=820 body.
	plat.position = Vector2(560, 808)
	root.add_child(plat)
	_poly(
		plat,
		"DeckWood",
		Color(0.38, 0.26, 0.16, 1.0),
		PackedVector2Array([
			Vector2(-90, -8), Vector2(90, -8), Vector2(90, 8), Vector2(-90, 8),
		]),
		"material_wood_platform",
		stats
	)
	for i in range(7):
		var x := -80.0 + float(i) * 24.0
		_poly(
			plat,
			"PlankGap_%d" % i,
			Color(0.2, 0.12, 0.08, 0.8),
			PackedVector2Array([
				Vector2(x, -6), Vector2(x + 2, -6), Vector2(x + 2, 6), Vector2(x, 6),
			]),
			"material_wood_gap",
			stats
		)
	_poly(
		plat,
		"SupportBeam",
		Color(0.28, 0.18, 0.12, 1.0),
		PackedVector2Array([
			Vector2(-70, 8), Vector2(-58, 8), Vector2(-62, 68), Vector2(-74, 68),
		]),
		"material_wood_support",
		stats
	)
	_poly(
		plat,
		"EdgeHighlight",
		Color(0.72, 0.55, 0.32, 0.55),
		PackedVector2Array([
			Vector2(-90, -8), Vector2(90, -8), Vector2(90, -5), Vector2(-90, -5),
		]),
		"legibility_platform_edge",
		stats
	)


static func _build_secret_cue(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var secret := Node2D.new()
	secret.name = "SecretCue"
	secret.position = Vector2(480, ground_y - 96)
	root.add_child(secret)
	# Discrete chalk chevron — mystery without HUD clutter.
	_poly(
		secret,
		"ChalkMark",
		Color(0.85, 0.78, 0.62, 0.35),
		PackedVector2Array([
			Vector2(-6, 0), Vector2(0, -10), Vector2(6, 0), Vector2(0, -4),
		]),
		"misterio_pista",
		stats
	)
	_poly(
		secret,
		"Scratch",
		Color(0.15, 0.1, 0.08, 0.4),
		PackedVector2Array([
			Vector2(-12, 12), Vector2(14, 8), Vector2(14, 9), Vector2(-12, 13),
		]),
		"misterio_risco",
		stats
	)


static func _build_order_heart_mark(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	_poly(
		root,
		"WallHeart",
		Color(0.68, 0.1, 0.08, 0.55),
		_heart_poly(Vector2(340, ground_y - 48), 6.0),
		"ordem_coracao_rubro",
		stats
	)


static func _build_vermilite_accent(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var node := Node2D.new()
	node.name = "VermiliteAccent"
	node.position = Vector2(400, ground_y - 6)
	root.add_child(node)
	_poly(
		node,
		"Vein",
		Color(0.9, 0.16, 0.1, 0.7),
		PackedVector2Array([
			Vector2(-20, 0), Vector2(-8, -4), Vector2(6, 2), Vector2(18, -2),
			Vector2(16, 2), Vector2(4, 6), Vector2(-10, 2), Vector2(-22, 2),
		]),
		"material_vermilite",
		stats
	)
	_poly(
		node,
		"CoreGlow",
		Color(1.0, 0.35, 0.22, 0.35),
		PackedVector2Array([
			Vector2(-4, -2), Vector2(4, -2), Vector2(3, 3), Vector2(-3, 3),
		]),
		"vermilite_glow",
		stats
	)


static func _build_brawler_showcase_silhouette(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Foot telegraph cue under live sample brawler (X=740). Actor spawned by StreetArtArea.
	var marker := Node2D.new()
	marker.name = "CultBrawlerSampleCue"
	marker.position = Vector2(740, ground_y)
	root.add_child(marker)
	_poly(
		marker,
		"TelegraphGround",
		Color(0.95, 0.45, 0.2, 0.22),
		PackedVector2Array([
			Vector2(-48, -2), Vector2(-8, -2), Vector2(-8, 2), Vector2(-48, 2),
		]),
		"telegraph_ground_contrast",
		stats
	)
	_poly(
		marker,
		"TelegraphPoseMarker",
		Color(0.92, 0.92, 0.88, 0.5),
		PackedVector2Array([
			Vector2(-40, -6), Vector2(-32, -10), Vector2(-34, -2),
		]),
		"telegraph_pose_not_color_only",
		stats
	)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_calder_highlight_ring(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	# Soft foot contact ring so Calder reads against dirt — does not change gameplay.
	_poly(
		root,
		"CalderFootReadability",
		Color(0.08, 0.05, 0.04, 0.28),
		PackedVector2Array([
			Vector2(104, ground_y - 1), Vector2(136, ground_y - 1),
			Vector2(138, ground_y + 3), Vector2(102, ground_y + 3),
		]),
		"legibility_calder",
		stats
	)


static func _build_elias_cue(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	_poly(
		root,
		"EliasCoatAccent",
		Color(0.45, 0.4, 0.48, 0.35),
		PackedVector2Array([
			Vector2(248, ground_y - 40), Vector2(272, ground_y - 40),
			Vector2(270, ground_y - 4), Vector2(250, ground_y - 4),
		]),
		"legibility_elias",
		stats
	)


static func _build_sample_lighting(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var light := PointLight2D.new()
	light.name = "SampleLanternLight"
	light.position = Vector2(180, ground_y - 94)
	light.color = Color(1.0, 0.7, 0.35, 1.0)
	light.energy = 0.55
	light.texture_scale = 0.7
	light.shadow_enabled = false
	_tag(light, "lampiao_light")
	root.add_child(light)
	stats["lights"] = int(stats.get("lights", 0)) + 1

	var verm := PointLight2D.new()
	verm.name = "SampleVermiliteLight"
	verm.position = Vector2(400, ground_y - 10)
	verm.color = Color(0.95, 0.22, 0.14, 1.0)
	verm.energy = 0.28
	verm.texture_scale = 0.35
	verm.shadow_enabled = false
	_tag(verm, "vermilite_light")
	root.add_child(verm)
	stats["lights"] = int(stats.get("lights", 0)) + 1


static func _build_sample_atmosphere(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var dust := GPUParticles2D.new()
	dust.name = "SampleDust"
	dust.position = Vector2(500, ground_y - 40)
	dust.amount = 18
	dust.lifetime = 3.2
	dust.preprocess = 1.0
	dust.visibility_rect = Rect2(-420, -120, 840, 200)
	var dust_mat := ParticleProcessMaterial.new()
	dust_mat.direction = Vector3(1, -0.15, 0)
	dust_mat.spread = 18.0
	dust_mat.initial_velocity_min = 8.0
	dust_mat.initial_velocity_max = 22.0
	dust_mat.gravity = Vector3(0, 4, 0)
	dust_mat.scale_min = 0.4
	dust_mat.scale_max = 1.1
	dust_mat.color = Color(0.72, 0.58, 0.4, 0.35)
	dust.process_material = dust_mat
	_tag(dust, "poeira")
	root.add_child(dust)
	stats["particles"] = int(stats.get("particles", 0)) + 1

	var paper := GPUParticles2D.new()
	paper.name = "SamplePaper"
	paper.position = Vector2(320, ground_y - 70)
	paper.amount = 5
	paper.lifetime = 4.5
	paper.visibility_rect = Rect2(-200, -100, 400, 180)
	var paper_mat := ParticleProcessMaterial.new()
	paper_mat.direction = Vector3(1, -0.4, 0)
	paper_mat.spread = 40.0
	paper_mat.initial_velocity_min = 12.0
	paper_mat.initial_velocity_max = 28.0
	paper_mat.gravity = Vector3(0, 12, 0)
	paper_mat.angular_velocity_min = -40.0
	paper_mat.angular_velocity_max = 40.0
	paper_mat.scale_min = 0.8
	paper_mat.scale_max = 1.4
	paper_mat.color = Color(0.82, 0.74, 0.58, 0.45)
	paper.process_material = paper_mat
	_tag(paper, "papel_vento")
	root.add_child(paper)
	stats["particles"] = int(stats.get("particles", 0)) + 1

	var smoke := GPUParticles2D.new()
	smoke.name = "SampleSaloonSmoke"
	smoke.position = Vector2(300, ground_y - 150)
	smoke.amount = 8
	smoke.lifetime = 3.8
	var smoke_mat := ParticleProcessMaterial.new()
	smoke_mat.direction = Vector3(0.2, -1, 0)
	smoke_mat.spread = 12.0
	smoke_mat.initial_velocity_min = 6.0
	smoke_mat.initial_velocity_max = 14.0
	smoke_mat.gravity = Vector3(0, -6, 0)
	smoke_mat.scale_min = 1.0
	smoke_mat.scale_max = 2.2
	smoke_mat.color = Color(0.35, 0.3, 0.28, 0.25)
	smoke.process_material = smoke_mat
	_tag(smoke, "fumaca")
	root.add_child(smoke)
	stats["particles"] = int(stats.get("particles", 0)) + 1


static func _build_foreground_shadow(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	_poly(
		root,
		"ForegroundPostShadow",
		Color(0.05, 0.03, 0.04, 0.35),
		PackedVector2Array([
			Vector2(860, ground_y - 110), Vector2(900, ground_y - 120),
			Vector2(900, ground_y + 10), Vector2(870, ground_y + 10),
		]),
		"foreground_shadow",
		stats
	)


static func _build_debug_overlay(
	presentation: StreetArtPresentation,
	ground_y: float,
	stats: Dictionary
) -> void:
	var debug_layer := presentation.get_node_or_null(LAYER_DEBUG) as Node2D
	if debug_layer == null:
		return
	var badge := Label.new()
	badge.name = "FinalSampleBandBadge"
	badge.position = Vector2(Spec.SAMPLE_X_MIN + 8, ground_y - 400)
	badge.text = (
		"%s | sample X %d–%d | not full-street final"
		% [Spec.PLACEHOLDER_TAG, int(Spec.SAMPLE_X_MIN), int(Spec.SAMPLE_X_MAX)]
	)
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55, 0.85))
	_tag(badge, "debug_badge")
	debug_layer.add_child(badge)
	stats["placeholder_tags"] = int(stats.get("placeholder_tags", 0)) + 1


static func _nudge_sky_mountains_for_sample(presentation: StreetArtPresentation, stats: Dictionary) -> void:
	## Extra sunset / ridge read near the sample band without replacing full sky.
	var sky := presentation.get_node_or_null(LAYER_SKY) as Node2D
	if sky == null:
		return
	var sun_boost := Polygon2D.new()
	sun_boost.name = "SampleSunsetBloom"
	sun_boost.color = Color(0.98, 0.45, 0.18, 0.2)
	sun_boost.polygon = PackedVector2Array([
		Vector2(520, 250), Vector2(780, 250), Vector2(760, 340), Vector2(540, 340),
	])
	_tag(sun_boost, "por_do_sol")
	sky.add_child(sun_boost)
	stats["materials"] = int(stats.get("materials", 0)) + 1


static func _heart_poly(center: Vector2, scale: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -0.6) * scale,
		center + Vector2(0.7, -1.2) * scale,
		center + Vector2(1.4, -0.4) * scale,
		center + Vector2(0, 1.4) * scale,
		center + Vector2(-1.4, -0.4) * scale,
		center + Vector2(-0.7, -1.2) * scale,
	])
