extends RefCounted
class_name UndergroundFinalMoldComposer

## Full catacombs final mold (0–1200). Visual-only. No Solids / AI / street / church edits.
## Silhouette tease only — never full Mol-Khar or Ruby Palace.

const Spec := preload("res://scripts/visual/underground_final_mold_spec.gd")
const Layout := preload("res://scripts/visual/underground_north_star_layout.gd")
const Factory := preload("res://scripts/visual/underground_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")
const KitBridge := preload("res://scripts/visual/street_kit_visual_bridge.gd")

const ROOT_NAME := "FinalMoldRoot"
const LAYER_DEBUG := "Layer13_Debug"


static func apply(presentation: UndergroundArtPresentation, profile: EnvironmentVisualProfile) -> Dictionary:
	remove(presentation)
	var ground_y := Factory.ground_anchor_y(profile)
	var root := Node2D.new()
	root.name = ROOT_NAME
	root.z_index = 9
	presentation.add_child(root)

	var stats := {
		"districts": 0,
		"structures": 0,
		"props": 0,
		"set_pieces": 0,
		"kit_slots": 0,
		"particles": 0,
		"placeholder_tags": 0,
		"playfield_width": profile.playfield_width_px,
		"mold": Spec.MOLD_ID,
	}

	for entry in Layout.get_zones():
		_build_zone(root, entry, ground_y, stats)
		stats["districts"] = int(stats["districts"]) + 1

	_build_ground_materials(root, ground_y, profile.playfield_width_px, stats)
	_build_boss_arena(root, ground_y, stats)
	_build_set_pieces(root, ground_y, stats)
	_build_finale_enhancements(root, ground_y, stats)
	_build_kit_reuse(root, ground_y, stats)
	_build_atmosphere(root, ground_y, stats)
	_build_debug_badge(presentation, ground_y, stats)
	return stats


static func remove(presentation: UndergroundArtPresentation) -> void:
	var existing := presentation.get_node_or_null(ROOT_NAME)
	if existing != null:
		existing.free()
	var debug_layer := presentation.get_node_or_null(LAYER_DEBUG) as Node2D
	if debug_layer != null:
		var badge := debug_layer.get_node_or_null("FinalMoldBandBadge")
		if badge != null:
			badge.free()


static func _tag(node: Node, label: String) -> void:
	node.set_meta("asset_kind", Spec.PLACEHOLDER_TAG)
	node.set_meta("candidate_label", label)
	node.set_meta("mold", true)
	node.set_meta("area", "underground")


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
	stats["placeholder_tags"] = int(stats.get("placeholder_tags", 0)) + 1
	return poly


static func _build_zone(root: Node2D, entry: Dictionary, ground_y: float, stats: Dictionary) -> void:
	var zone_id: int = int(entry["id"])
	var stage: int = int(entry.get("stage", 1))
	var x_min := float(entry["x_min"])
	var x_max := float(entry["x_max"])
	var node := Node2D.new()
	node.name = "Zone_%d_stage%d" % [zone_id, stage]
	root.add_child(node)

	_poly(
		node,
		"Wash",
		_stage_wash(stage),
		PackedVector2Array([
			Vector2(x_min, ground_y - 4), Vector2(x_max, ground_y - 4),
			Vector2(x_max, ground_y + 14), Vector2(x_min, ground_y + 14),
		]),
		"stage_wash_%d" % stage,
		stats
	)

	for spec in Layout.get_mold_structures_for_zone(zone_id, ground_y):
		_build_structure(node, spec, stats)
	for prop in Layout.get_mold_props_for_zone(zone_id, ground_y):
		_build_prop(node, prop, stats)


static func _stage_wash(stage: int) -> Color:
	match stage:
		1:
			return Color(Palette.WOOD_MID.r, Palette.WOOD_MID.g, Palette.WOOD_MID.b, 0.1)
		2:
			return Color(Palette.ORDER_RITUAL_STONE.r, Palette.ORDER_RITUAL_STONE.g, Palette.ORDER_RITUAL_STONE.b, 0.12)
		3:
			return Color(Palette.EARTH_DARK.r, Palette.EARTH_DARK.g, Palette.EARTH_DARK.b, 0.14)
		4:
			return Color(Palette.VERMILITE_SHADOW.r, Palette.VERMILITE_SHADOW.g, Palette.VERMILITE_SHADOW.b, 0.16)
		_:
			return Color(Palette.MOL_STONE_BLACK.r, Palette.MOL_STONE_BLACK.g, Palette.MOL_STONE_BLACK.b, 0.18)


static func _build_structure(parent: Node2D, spec: Dictionary, stats: Dictionary) -> void:
	var kind := String(spec.get("kind", "timber"))
	var pos: Vector2 = spec.get("pos", Vector2.ZERO)
	var w: float = float(spec.get("w", 40.0))
	var h: float = float(spec.get("h", 100.0))
	var n := Node2D.new()
	n.name = String(spec.get("name", "Struct"))
	n.position = pos
	parent.add_child(n)
	var hw := w * 0.5
	match kind:
		"timber":
			_poly(n, "Post", Palette.WOOD_DARK, PackedVector2Array([
				Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw, -h), Vector2(-hw, -h),
			]), "set_timber_shoring", stats)
			_poly(n, "Beam", Palette.WOOD_MID, PackedVector2Array([
				Vector2(-hw - 8, -h), Vector2(hw + 8, -h), Vector2(hw + 4, -h + 10), Vector2(-hw - 4, -h + 10),
			]), "set_timber_beam", stats)
		"arch":
			_poly(n, "L", Palette.ORDER_RITUAL_STONE, _rect(-hw, -h, 12, h), "set_order_tunnel_arch", stats)
			_poly(n, "R", Palette.ORDER_RITUAL_STONE, _rect(hw - 12, -h, 12, h), "set_order_tunnel_arch", stats)
			_poly(n, "Top", Palette.STONE_GREY, PackedVector2Array([
				Vector2(-hw, -h), Vector2(hw, -h), Vector2(hw * 0.5, -h - 28), Vector2(-hw * 0.5, -h - 28),
			]), "set_order_tunnel_arch", stats)
			_poly(n, "Heart", Palette.ORDER_BURNT_RED, _heart(Vector2(0, -h * 0.5), 5.0), "narrative_order", stats)
		"ruin":
			_poly(n, "Body", Palette.EARTH_DARK.lightened(0.08), PackedVector2Array([
				Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw - 4, -h), Vector2(-hw + 6, -h * 0.92),
			]), "set_ancient_ruin", stats)
			_poly(n, "Glyph", Color(Palette.ORDER_AGED_CREAM.r, Palette.ORDER_AGED_CREAM.g, Palette.ORDER_AGED_CREAM.b, 0.35), _rect(-8, -h * 0.55, 16, 20), "set_ancient_ruin_glyph", stats)
		"prison", "vermilite_wall":
			_poly(n, "Body", Palette.ORDER_BLACK.lightened(0.08), PackedVector2Array([
				Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw, -h), Vector2(-hw, -h),
			]), "set_prison_wall", stats)
			_poly(n, "Vein", Palette.VERMILITE_SATURATED, PackedVector2Array([
				Vector2(-4, -h * 0.2), Vector2(4, -h * 0.35), Vector2(2, -h * 0.8), Vector2(-2, -h * 0.55),
			]), "narrative_vermilite", stats)
		_:
			_poly(n, "Body", Palette.MOL_STONE_BLACK.lightened(0.1), PackedVector2Array([
				Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw, -h), Vector2(-hw, -h),
			]), "set_ritual_flank", stats)
	stats["structures"] = int(stats.get("structures", 0)) + 1


static func _build_prop(parent: Node2D, prop: Dictionary, stats: Dictionary) -> void:
	var kind := String(prop.get("kind", "crate"))
	var pos: Vector2 = prop.get("pos", Vector2.ZERO)
	var n := Node2D.new()
	n.name = "Prop_%s_%.0f" % [kind, pos.x]
	n.position = pos
	parent.add_child(n)
	match kind:
		"crate":
			_poly(n, "C", Palette.WOOD_MID, _rect(-10, -14, 20, 14), "prop_crate", stats)
		"lamp":
			_poly(n, "Pole", Palette.METAL_COOL, _rect(-2, -56, 4, 56), "prop_lamp", stats)
			_poly(n, "Glow", Color(1.0, 0.65, 0.3, 0.4), _rect(-6, -68, 12, 12), "prop_lamp_glow", stats)
		"chains":
			for i in range(3):
				_poly(n, "L%d" % i, Palette.METAL_COOL, _rect(i * 5 - 6, -i * 8 - 8, 4, 10), "prop_chain", stats)
		"candle":
			_poly(n, "Wax", Palette.ORDER_AGED_CREAM, _rect(-2, -14, 4, 14), "prop_candle", stats)
			_poly(n, "Flame", Color(1.0, 0.7, 0.3, 0.7), _rect(-3, -22, 6, 8), "prop_candle_flame", stats)
		"banner":
			_poly(n, "Cloth", Palette.ORDER_DEEP_RED, _rect(-4, -36, 12, 36), "prop_banner", stats)
		"glyph":
			_poly(n, "G", Color(0.7, 0.55, 0.4, 0.45), _rect(-10, -12, 20, 16), "set_ancient_ruin_glyph", stats)
		"bones":
			_poly(n, "B", Palette.ORDER_AGED_CREAM.darkened(0.2), _rect(-12, -6, 24, 6), "prop_bones", stats)
		"roots":
			_poly(n, "R", Palette.EARTH_DARK, PackedVector2Array([
				Vector2(-16, 0), Vector2(-4, -16), Vector2(8, -8), Vector2(14, 0),
			]), "prop_roots", stats)
		"vermilite":
			_poly(n, "V", Palette.VERMILITE_SATURATED, PackedVector2Array([
				Vector2(0, 0), Vector2(5, -14), Vector2(10, 0),
			]), "narrative_vermilite", stats)
		"altar":
			_poly(n, "Table", Palette.ORDER_RITUAL_STONE, _rect(-22, -16, 44, 18), "set_prison_altar", stats)
			_poly(n, "Cloth", Palette.ORDER_DEEP_RED, _rect(-16, -12, 32, 8), "set_prison_altar", stats)
		_:
			_poly(n, "X", Palette.STONE_GREY, _rect(-6, -6, 12, 12), "prop_generic", stats)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_ground_materials(root: Node2D, ground_y: float, width: float, stats: Dictionary) -> void:
	var ground := Node2D.new()
	ground.name = "MoldGround"
	root.add_child(ground)
	_poly(
		ground,
		"CavernFloor",
		Palette.EARTH_DARK,
		PackedVector2Array([
			Vector2(0, ground_y), Vector2(width, ground_y),
			Vector2(width, ground_y + 18), Vector2(0, ground_y + 18),
		]),
		"material_cavern_floor",
		stats
	)
	for i in range(int(width / 40.0)):
		var x0 := 16.0 + float(i) * 40.0
		var stage := 1
		if x0 > 940.0:
			stage = 5
		elif x0 > 700.0:
			stage = 4
		elif x0 > 460.0:
			stage = 3
		elif x0 > 220.0:
			stage = 2
		var col := Palette.STONE_GREY if stage <= 2 else Palette.ORDER_BLACK.lightened(0.1)
		if stage >= 4:
			col = Palette.VERMILITE_SHADOW.lightened(0.15)
		_poly(
			ground,
			"Tile_%d" % i,
			col,
			PackedVector2Array([
				Vector2(x0, ground_y - 2), Vector2(x0 + 28, ground_y - 2),
				Vector2(x0 + 26, ground_y + 8), Vector2(x0 + 2, ground_y + 8),
			]),
			"material_zone_tile",
			stats
		)


static func _build_boss_arena(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Clean read floor — no collision; bounds match BossEncounter gates.
	var bounds: Dictionary = Layout.get_boss_arena_bounds()
	var arena := Node2D.new()
	arena.name = "MoldBossArena"
	root.add_child(arena)
	var x_min := float(bounds["x_min"])
	var x_max := float(bounds["x_max"])
	_poly(
		arena,
		"FloorMark",
		Color(Palette.ORDER_BURNT_RED.r, Palette.ORDER_BURNT_RED.g, Palette.ORDER_BURNT_RED.b, 0.18),
		PackedVector2Array([
			Vector2(x_min, ground_y - 3), Vector2(x_max, ground_y - 3),
			Vector2(x_max, ground_y + 3), Vector2(x_min, ground_y + 3),
		]),
		"set_boss_arena_floor",
		stats
	)
	_poly(arena, "PostL", Palette.ORDER_RITUAL_STONE, _rect(x_min - 4, ground_y - 48, 10, 48), "set_boss_arena_post", stats)
	_poly(arena, "PostR", Palette.ORDER_RITUAL_STONE, _rect(x_max - 6, ground_y - 48, 10, 48), "set_boss_arena_post", stats)
	# Phase 2 Vermilite rim (always drawn faintly; intensifies visually with theme, not AI).
	_poly(
		arena,
		"Phase2Rim",
		Color(Palette.VERMILITE_SATURATED.r, Palette.VERMILITE_SATURATED.g, Palette.VERMILITE_SATURATED.b, 0.12),
		PackedVector2Array([
			Vector2(x_min + 20, ground_y - 6), Vector2(x_max - 20, ground_y - 6),
			Vector2(x_max - 24, ground_y - 4), Vector2(x_min + 24, ground_y - 4),
		]),
		"set_boss_arena_phase2_rim",
		stats
	)
	stats["set_pieces"] = int(stats.get("set_pieces", 0)) + 1


static func _build_set_pieces(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var host := Node2D.new()
	host.name = "MoldSetPieces"
	root.add_child(host)

	# Colossal statue (silhouette — not full Mol-Khar body)
	var statue := Node2D.new()
	statue.name = "Mold_ColossalStatue"
	statue.position = Vector2(980, ground_y)
	host.add_child(statue)
	_poly(statue, "Base", Palette.ORDER_RITUAL_STONE, _rect(-50, -20, 100, 24), "set_colossal_statue", stats)
	_poly(statue, "Body", Palette.MOL_STONE_BLACK.lightened(0.08), PackedVector2Array([
		Vector2(-40, -20), Vector2(40, -20), Vector2(36, -180), Vector2(-36, -180),
	]), "set_colossal_statue", stats)
	_poly(statue, "Head", Palette.ORDER_AGED_CREAM.darkened(0.35), _rect(-22, -220, 44, 40), "set_colossal_statue", stats)
	_poly(statue, "Eyes", Color(0.95, 0.2, 0.12, 0.15), _rect(-14, -206, 28, 8), "set_statue_eyes", stats)

	# Hidden passage mouth
	var passage := Node2D.new()
	passage.name = "Mold_HiddenPassage"
	passage.position = Vector2(1080, ground_y - 16)
	host.add_child(passage)
	_poly(passage, "Mouth", Palette.ORDER_BLACK, PackedVector2Array([
		Vector2(-32, 0), Vector2(32, 0), Vector2(24, -44), Vector2(-24, -44),
	]), "set_hidden_passage", stats)
	_poly(passage, "Glow", Color(Palette.VERMILITE_SATURATED.r, Palette.VERMILITE_SATURATED.g, Palette.VERMILITE_SATURATED.b, 0.2), _rect(-16, -36, 32, 24), "set_hidden_passage_glow", stats)

	stats["set_pieces"] = int(stats.get("set_pieces", 0)) + 2


static func _build_finale_enhancements(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Softens finale hooks — still silhouette only.
	var fin := Node2D.new()
	fin.name = "MoldFinaleBeats"
	root.add_child(fin)

	var brand := Polygon2D.new()
	brand.name = "Mold_RedBrandPulse"
	brand.position = Vector2(900, ground_y - 40)
	brand.color = Color(0.95, 0.25, 0.12, 0.0)
	brand.polygon = PackedVector2Array([
		Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20),
	])
	brand.add_to_group("chapter_zero_finale_red_brand_glow")
	_tag(brand, "finale_red_brand")
	fin.add_child(brand)

	var mol := Polygon2D.new()
	mol.name = "Mold_MolKharShadow"
	mol.position = Vector2(1000, ground_y - 120)
	mol.color = Color(0.05, 0.02, 0.04, 0.0)
	mol.polygon = PackedVector2Array([
		Vector2(-60, 80), Vector2(60, 80), Vector2(40, -40), Vector2(0, -90), Vector2(-40, -40),
	])
	mol.add_to_group("chapter_zero_finale_mol_shadow")
	_tag(mol, "finale_mol_shadow_tease")
	fin.add_child(mol)

	var arc := Polygon2D.new()
	arc.name = "Mold_ArcturusSilhouette"
	arc.position = Vector2(1140, ground_y)
	arc.color = Color(0.08, 0.08, 0.1, 0.0)
	arc.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(14, 0), Vector2(12, -56), Vector2(0, -70), Vector2(-12, -56),
	])
	arc.add_to_group("chapter_zero_finale_arcturus")
	_tag(arc, "finale_arcturus_silhouette")
	fin.add_child(arc)

	stats["set_pieces"] = int(stats.get("set_pieces", 0)) + 3


static func _build_kit_reuse(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var kit_host := Node2D.new()
	kit_host.name = "MoldKitSlots"
	root.add_child(kit_host)
	stats["kit_slots"] = KitBridge.spawn_kit_slots(kit_host, Layout.get_mold_kit_placements(ground_y))


static func _build_atmosphere(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var dust := GPUParticles2D.new()
	dust.name = "MoldCavernDust"
	dust.position = Vector2(600, ground_y - 80)
	dust.amount = 18
	dust.lifetime = 4.0
	dust.visibility_rect = Rect2(-700, -160, 1400, 240)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.2, -0.15, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, 4, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.0
	mat.color = Color(0.35, 0.28, 0.3, 0.2)
	dust.process_material = mat
	_tag(dust, "atmosphere_dust")
	root.add_child(dust)
	stats["particles"] = int(stats.get("particles", 0)) + 1

	var verm := GPUParticles2D.new()
	verm.name = "MoldVermiliteMotes"
	verm.position = Vector2(860, ground_y - 40)
	verm.amount = 8
	verm.lifetime = 3.0
	var vmat := ParticleProcessMaterial.new()
	vmat.direction = Vector3(0, -1, 0)
	vmat.spread = 30.0
	vmat.initial_velocity_min = 2.0
	vmat.initial_velocity_max = 8.0
	vmat.gravity = Vector3(0, -3, 0)
	vmat.scale_min = 0.3
	vmat.scale_max = 0.7
	vmat.color = Color(0.95, 0.25, 0.14, 0.25)
	verm.process_material = vmat
	_tag(verm, "atmosphere_vermilite")
	root.add_child(verm)
	stats["particles"] = int(stats.get("particles", 0)) + 1


static func _build_debug_badge(presentation: UndergroundArtPresentation, ground_y: float, stats: Dictionary) -> void:
	var debug_layer := presentation.get_node_or_null(LAYER_DEBUG) as Node2D
	if debug_layer == null:
		# Some presentations use Layer12_Debug naming — try alternate.
		debug_layer = presentation.get_debug_layer() if presentation.has_method("get_debug_layer") else null
	if debug_layer == null:
		return
	var badge := Label.new()
	badge.name = "FinalMoldBandBadge"
	badge.position = Vector2(16, ground_y - 420)
	badge.text = "%s | FULL CATACOMBS MOLD 0–1200 | 5 stages | not PNG-final" % Spec.PLACEHOLDER_TAG
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.85, 0.55, 0.55, 0.85))
	_tag(badge, "debug_badge")
	debug_layer.add_child(badge)


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h),
	])


static func _heart(center: Vector2, scale: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0, -0.6) * scale,
		center + Vector2(0.7, -1.2) * scale,
		center + Vector2(1.4, -0.4) * scale,
		center + Vector2(0, 1.4) * scale,
		center + Vector2(-1.4, -0.4) * scale,
		center + Vector2(-0.7, -1.2) * scale,
	])
