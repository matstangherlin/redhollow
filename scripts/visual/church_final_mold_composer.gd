extends RefCounted
class_name ChurchFinalMoldComposer

## Applies the approved North Star FINAL MOLD across the Cap. Zero church (0–1800).
## Visual-only. Does NOT touch Solids collision, AttackData, street, or catacombs.
## All generated geometry is PLACEHOLDER_CANDIDATE until manifesto-approved PNGs land.

const Spec := preload("res://scripts/visual/church_final_mold_spec.gd")
const Layout := preload("res://scripts/visual/church_north_star_layout.gd")
const Variants := preload("res://scripts/visual/church_north_star_variants.gd")
const Factory := preload("res://scripts/visual/church_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")
const KitBridge := preload("res://scripts/visual/street_kit_visual_bridge.gd")

const ROOT_NAME := "FinalMoldRoot"
const LAYER_DEBUG := "Layer12_Debug"


static func apply(presentation: ChurchArtPresentation, profile: EnvironmentVisualProfile) -> Dictionary:
	remove(presentation)
	var ground_y := Factory.ground_anchor_y(profile)
	var root := Node2D.new()
	root.name = ROOT_NAME
	root.z_index = 9
	presentation.add_child(root)

	var stats := {
		"districts": 0,
		"facades": 0,
		"props": 0,
		"decals": 0,
		"kit_slots": 0,
		"set_pieces": 0,
		"lights": 0,
		"particles": 0,
		"placeholder_tags": 0,
		"playfield_width": profile.playfield_width_px,
		"mold": Spec.MOLD_ID,
	}

	for entry in Layout.get_districts():
		_build_district(root, entry, ground_y, stats)
		stats["districts"] = int(stats["districts"]) + 1

	_build_ground_materials(root, ground_y, profile.playfield_width_px, stats)
	_build_set_pieces(root, ground_y, stats)
	_build_narrative(root, ground_y, stats)
	_build_kit_reuse(root, ground_y, stats)
	_build_atmosphere_budget(root, ground_y, stats)
	_build_catacombs_direction_cue(root, ground_y, stats)
	_build_debug_badge(presentation, ground_y, stats)
	return stats


static func remove(presentation: ChurchArtPresentation) -> void:
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
	node.set_meta("area", "church")


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


static func _build_district(
	root: Node2D,
	entry: Dictionary,
	ground_y: float,
	stats: Dictionary
) -> void:
	var district_id: int = int(entry["id"])
	var x_min := float(entry["x_min"])
	var x_max := float(entry["x_max"])
	var theme := String(entry.get("theme", ""))
	var node := Node2D.new()
	node.name = "District_%d_%s" % [district_id, theme]
	root.add_child(node)

	_poly(
		node,
		"Wash",
		_theme_wash(theme),
		PackedVector2Array([
			Vector2(x_min, ground_y - 4),
			Vector2(x_max, ground_y - 4),
			Vector2(x_max, ground_y + 16),
			Vector2(x_min, ground_y + 16),
		]),
		"district_wash_%s" % theme,
		stats
	)

	for spec in Layout.get_mold_facades_for_district(district_id, ground_y):
		_build_stone_facade(node, spec, ground_y, stats)

	for prop in Layout.get_mold_props_for_district(district_id, ground_y):
		_build_prop(node, prop, stats)


static func _theme_wash(theme: String) -> Color:
	match theme:
		"threshold":
			return Color(Palette.STONE_GREY.r, Palette.STONE_GREY.g, Palette.STONE_GREY.b, 0.12)
		"punishment":
			return Color(Palette.ORDER_RITUAL_STONE.r, Palette.ORDER_RITUAL_STONE.g, Palette.ORDER_RITUAL_STONE.b, 0.14)
		"ritual":
			return Color(Palette.ORDER_AGED_CREAM.r, Palette.ORDER_AGED_CREAM.g, Palette.ORDER_AGED_CREAM.b, 0.1)
		"combat":
			return Color(Palette.EARTH_DARK.r, Palette.EARTH_DARK.g, Palette.EARTH_DARK.b, 0.12)
		"vermilite":
			return Color(Palette.VERMILITE_SHADOW.r, Palette.VERMILITE_SHADOW.g, Palette.VERMILITE_SHADOW.b, 0.14)
		"descent":
			return Color(Palette.ORDER_BLACK.r, Palette.ORDER_BLACK.g, Palette.ORDER_BLACK.b, 0.16)
		_:
			return Color(0.2, 0.16, 0.18, 0.08)


static func _build_stone_facade(
	parent: Node2D,
	spec: Dictionary,
	_ground_y: float,
	stats: Dictionary
) -> void:
	var variant: int = int(spec.get("variant", 0))
	var width: float = float(spec.get("w", 80.0))
	var height: float = float(spec.get("h", 100.0)) * Variants.facade_height_multiplier(variant)
	var lit: bool = bool(spec.get("lit", false))
	var pos: Vector2 = spec.get("pos", Vector2.ZERO)
	var seed_key := "%s_%d_%.0f" % [String(spec.get("name", "F")), variant, pos.x]

	var facade := Node2D.new()
	facade.name = String(spec.get("name", "MoldFacade"))
	facade.position = pos
	parent.add_child(facade)

	var half_w := width * 0.5
	var wall := Variants.wall_color_for_variant(variant)
	var roof_h := Variants.roof_height_for_variant(variant)
	var roof_color := Variants.roof_color_for_variant(variant)

	_poly(
		facade,
		"Body",
		wall,
		PackedVector2Array([
			Vector2(-half_w, 0), Vector2(half_w, 0),
			Vector2(half_w, -height), Vector2(-half_w, -height),
		]),
		"material_ritual_stone",
		stats
	)

	# Stone courses — vertical church language.
	for i in range(4):
		var y := -height * (0.2 + 0.18 * float(i))
		_poly(
			facade,
			"Course_%d" % i,
			wall.lightened(0.04 if i % 2 == 0 else 0.0).darkened(0.02),
			PackedVector2Array([
				Vector2(-half_w + 3, y), Vector2(half_w - 3, y),
				Vector2(half_w - 3, y + 2), Vector2(-half_w + 3, y + 2),
			]),
			"material_stone_course",
			stats
		)

	# Pointed roof / buttress tip
	_poly(
		facade,
		"Roof",
		roof_color,
		PackedVector2Array([
			Vector2(-half_w - 4, -height),
			Vector2(0, -height - roof_h - 16),
			Vector2(half_w + 4, -height),
		]),
		"roof_variant_%d" % (variant % 3),
		stats
	)

	for wx in Variants.window_offsets_for_variant(variant, width):
		var win_col := Palette.VERMILITE_HALO if lit else Palette.ORDER_BLACK.lightened(0.12)
		_poly(
			facade,
			"Window_%.0f" % wx,
			win_col,
			PackedVector2Array([
				Vector2(wx - 5, -height * 0.55 - 14),
				Vector2(wx + 5, -height * 0.55 - 14),
				Vector2(wx + 5, -height * 0.55 + 10),
				Vector2(wx - 5, -height * 0.55 + 10),
			]),
			"window_arched",
			stats
		)

	# Order heart on some facades
	if Variants.pick_variant(seed_key + "_mark", 3) == 0:
		_poly(
			facade,
			"OrderHeart",
			Color(Palette.ORDER_BURNT_RED.r, Palette.ORDER_BURNT_RED.g, Palette.ORDER_BURNT_RED.b, 0.6),
			_heart(Vector2(0, -height * 0.42), 6.0),
			"narrative_order",
			stats
		)

	# Banner hanging
	if Variants.pick_variant(seed_key + "_banner", 4) == 0:
		_poly(
			facade,
			"Banner",
			Palette.ORDER_DEEP_RED,
			PackedVector2Array([
				Vector2(half_w * 0.55, -height * 0.85),
				Vector2(half_w * 0.55 + 10, -height * 0.85),
				Vector2(half_w * 0.55 + 10, -height * 0.45),
				Vector2(half_w * 0.55, -height * 0.5),
			]),
			"prop_banner",
			stats
		)

	stats["facades"] = int(stats.get("facades", 0)) + 1


static func _build_prop(parent: Node2D, prop: Dictionary, stats: Dictionary) -> void:
	var kind := String(prop.get("kind", "crate"))
	var pos: Vector2 = prop.get("pos", Vector2.ZERO)
	var node := Node2D.new()
	node.name = "Prop_%s_%.0f" % [kind, pos.x]
	node.position = pos
	parent.add_child(node)
	match kind:
		"banner":
			_poly(node, "Pole", Palette.METAL_COOL, _rect(-2, -56, 4, 56), "prop_banner_pole", stats)
			_poly(node, "Cloth", Palette.ORDER_DEEP_RED, _rect(0, -52, 18, 36), "prop_banner", stats)
			_poly(node, "Heart", Palette.ORDER_BURNT_RED, _heart(Vector2(9, -36), 4.0), "narrative_order", stats)
		"candle":
			_poly(node, "Wax", Palette.ORDER_AGED_CREAM, _rect(-2, -14, 4, 14), "prop_candle", stats)
			_poly(node, "Flame", Color(1.0, 0.7, 0.3, 0.7), _rect(-3, -22, 6, 8), "prop_candle_flame", stats)
		"chains":
			for i in range(3):
				_poly(node, "Link_%d" % i, Palette.METAL_COOL, _rect(i * 5 - 6, -i * 8 - 8, 4, 10), "prop_chain", stats)
		"lamp":
			_poly(node, "Pole", Palette.METAL_COOL, _rect(-2, -72, 4, 72), "prop_lamp_metal", stats)
			_poly(node, "Glow", Color(0.85, 0.55, 0.28, 0.4), _rect(-6, -84, 12, 12), "prop_lamp_glow", stats)
		"fence":
			_poly(node, "F", Palette.ORDER_RITUAL_STONE, _rect(-28, -22, 56, 22), "prop_fence_stone", stats)
		"crate":
			_poly(node, "C", Palette.WOOD_MID, _rect(-10, -14, 20, 14), "prop_crate", stats)
		"vermilite":
			_poly(node, "Shard", Palette.VERMILITE_SATURATED, PackedVector2Array([
				Vector2(0, 0), Vector2(5, -14), Vector2(10, 0),
			]), "narrative_vermilite", stats)
		_:
			_poly(node, "G", Palette.STONE_GREY, _rect(-6, -6, 12, 12), "prop_generic", stats)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_ground_materials(
	root: Node2D,
	ground_y: float,
	width: float,
	stats: Dictionary
) -> void:
	var ground := Node2D.new()
	ground.name = "MoldGround"
	root.add_child(ground)

	_poly(
		ground,
		"StoneBase",
		Palette.ORDER_RITUAL_STONE,
		PackedVector2Array([
			Vector2(0, ground_y), Vector2(width, ground_y),
			Vector2(width, ground_y + 20), Vector2(0, ground_y + 20),
		]),
		"material_ritual_stone",
		stats
	)

	# Plaza cobbles denser under Order plaza (400–720) and arena (700–1120).
	for i in range(int(width / 28.0)):
		var x0 := 12.0 + float(i) * 28.0
		var in_plaza := x0 >= 400.0 and x0 <= 1120.0
		var col := Palette.ORDER_AGED_CREAM.darkened(0.35) if in_plaza else Palette.STONE_GREY.darkened(0.1)
		_poly(
			ground,
			"Cobble_%d" % i,
			col,
			PackedVector2Array([
				Vector2(x0, ground_y - 2), Vector2(x0 + 18, ground_y - 2),
				Vector2(x0 + 16, ground_y + 8), Vector2(x0 + 2, ground_y + 8),
			]),
			"material_cobble",
			stats
		)

	# Ritual plaza ring visibility
	_poly(
		ground,
		"PlazaRing",
		Color(Palette.ORDER_BURNT_RED.r, Palette.ORDER_BURNT_RED.g, Palette.ORDER_BURNT_RED.b, 0.18),
		PackedVector2Array([
			Vector2(420, ground_y - 4), Vector2(700, ground_y - 4),
			Vector2(700, ground_y + 2), Vector2(420, ground_y + 2),
		]),
		"plaza_ritual_ring",
		stats
	)


static func _build_set_pieces(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Finalized visual dressings for required set pieces — non-colliding overlays.
	var host := Node2D.new()
	host.name = "MoldSetPieces"
	root.add_child(host)
	var positions: Dictionary = Layout.get_set_piece_positions(ground_y)

	_build_bell_tower_mold(host, positions["bell_tower"], stats)
	_build_main_entrance_mold(host, positions["main_entrance"], stats)
	_build_statue_mold(host, positions["order_statue"], stats)
	_build_altar_mold(host, positions["external_altar"], stats)
	_build_gate_mold(host, positions["cult_gate"], stats)
	_build_underground_passage_mold(host, positions["underground_passage"], stats)
	stats["set_pieces"] = 6


static func _build_bell_tower_mold(parent: Node2D, pos: Vector2, stats: Dictionary) -> void:
	var n := Node2D.new()
	n.name = "Mold_BellTower"
	n.position = pos
	parent.add_child(n)
	_poly(n, "Shaft", Palette.ORDER_RITUAL_STONE, _rect(-28, -40, 56, 200), "set_bell_tower", stats)
	_poly(n, "Belfry", Palette.STONE_GREY, _rect(-36, -80, 72, 48), "set_bell_tower_belfry", stats)
	_poly(n, "Spire", Palette.ORDER_BLACK, PackedVector2Array([
		Vector2(-20, -80), Vector2(20, -80), Vector2(0, -150),
	]), "set_bell_tower_spire", stats)
	_poly(n, "Bell", Color(0.55, 0.42, 0.2, 1.0), _rect(-10, -64, 20, 18), "set_bell", stats)
	_poly(n, "BellGlow", Color(0.92, 0.35, 0.18, 0.25), _rect(-16, -70, 32, 28), "set_bell_glow", stats)


static func _build_main_entrance_mold(parent: Node2D, pos: Vector2, stats: Dictionary) -> void:
	var n := Node2D.new()
	n.name = "Mold_MainEntrance"
	n.position = pos
	parent.add_child(n)
	_poly(n, "ArchL", Palette.ORDER_RITUAL_STONE, _rect(-48, -120, 18, 120), "set_entrance_pillar", stats)
	_poly(n, "ArchR", Palette.ORDER_RITUAL_STONE, _rect(30, -120, 18, 120), "set_entrance_pillar", stats)
	_poly(n, "ArchTop", Palette.STONE_GREY, PackedVector2Array([
		Vector2(-48, -120), Vector2(48, -120), Vector2(28, -160), Vector2(-28, -160),
	]), "set_entrance_arch", stats)
	_poly(n, "Door", Palette.ORDER_BLACK, _rect(-22, -90, 44, 90), "set_entrance_door", stats)
	_poly(n, "Heart", Palette.ORDER_BURNT_RED, _heart(Vector2(0, -70), 8.0), "narrative_order", stats)


static func _build_statue_mold(parent: Node2D, pos: Vector2, stats: Dictionary) -> void:
	var n := Node2D.new()
	n.name = "Mold_OrderStatue"
	n.position = pos
	parent.add_child(n)
	_poly(n, "Plinth", Palette.STONE_GREY, _rect(-18, -8, 36, 12), "set_statue_plinth", stats)
	_poly(n, "Body", Palette.ORDER_AGED_CREAM.darkened(0.25), _rect(-12, -56, 24, 48), "set_statue", stats)
	_poly(n, "Head", Palette.ORDER_AGED_CREAM.darkened(0.2), _rect(-8, -72, 16, 16), "set_statue_head", stats)
	_poly(n, "Heart", Palette.ORDER_BURNT_RED, _heart(Vector2(0, -40), 5.0), "narrative_order", stats)


static func _build_altar_mold(parent: Node2D, pos: Vector2, stats: Dictionary) -> void:
	var n := Node2D.new()
	n.name = "Mold_ExternalAltar"
	n.position = pos
	parent.add_child(n)
	_poly(n, "Table", Palette.ORDER_RITUAL_STONE, _rect(-28, -18, 56, 22), "set_altar", stats)
	_poly(n, "Cloth", Palette.ORDER_DEEP_RED, _rect(-22, -14, 44, 10), "set_altar_cloth", stats)
	for i in range(3):
		_poly(n, "Candle_%d" % i, Palette.ORDER_AGED_CREAM, _rect(-12 + i * 12, -30, 4, 12), "prop_candle", stats)
		_poly(n, "Flame_%d" % i, Color(1.0, 0.65, 0.28, 0.65), _rect(-13 + i * 12, -38, 6, 8), "prop_candle_flame", stats)


static func _build_gate_mold(parent: Node2D, pos: Vector2, stats: Dictionary) -> void:
	## Dressing only — CultRedBarrier gameplay node stays authoritative.
	var n := Node2D.new()
	n.name = "Mold_CultGate"
	n.position = pos
	parent.add_child(n)
	_poly(n, "FrameL", Palette.ORDER_BLACK, _rect(-40, -80, 12, 80), "set_gate_frame", stats)
	_poly(n, "FrameR", Palette.ORDER_BLACK, _rect(28, -80, 12, 80), "set_gate_frame", stats)
	_poly(n, "Lintil", Palette.ORDER_RITUAL_STONE, _rect(-40, -88, 80, 12), "set_gate_lintel", stats)
	_poly(n, "Bars", Color(Palette.VERMILITE_SATURATED.r, Palette.VERMILITE_SATURATED.g, Palette.VERMILITE_SATURATED.b, 0.35), _rect(-26, -72, 52, 64), "set_gate_vermilite", stats)
	_poly(n, "Seal", Palette.ORDER_BURNT_RED, _heart(Vector2(0, -48), 7.0), "narrative_order", stats)


static func _build_underground_passage_mold(parent: Node2D, pos: Vector2, stats: Dictionary) -> void:
	## Visual cue at church→catacombs boundary. Does not edit underground scenes.
	var n := Node2D.new()
	n.name = "Mold_UndergroundPassage"
	n.position = pos
	parent.add_child(n)
	_poly(n, "Mouth", Palette.ORDER_BLACK, PackedVector2Array([
		Vector2(-36, 0), Vector2(36, 0), Vector2(28, -48), Vector2(-28, -48),
	]), "set_underground_mouth", stats)
	_poly(n, "Steps", Palette.STONE_GREY, _rect(-28, -8, 56, 12), "set_underground_steps", stats)
	_poly(n, "Depth", Color(0.05, 0.04, 0.06, 0.8), _rect(-20, -40, 40, 28), "set_underground_depth", stats)
	_poly(n, "Arrow", Palette.ORDER_BURNT_RED, PackedVector2Array([
		Vector2(-8, -28), Vector2(8, -28), Vector2(0, -16),
	]), "narrative_descent", stats)


static func _build_narrative(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var narr := Node2D.new()
	narr.name = "MoldNarrative"
	root.add_child(narr)
	for entry in Layout.get_narrative_decals(ground_y):
		var n := Node2D.new()
		n.name = "Narr_%s" % entry["id"]
		n.position = entry["pos"]
		narr.add_child(n)
		_paint_narrative(n, String(entry["kind"]), String(entry["theme"]), stats)
		stats["decals"] = int(stats.get("decals", 0)) + 1
	for extra in Layout.get_mold_extra_narrative(ground_y):
		var n2 := Node2D.new()
		n2.name = "NarrExtra_%s" % extra["id"]
		n2.position = extra["pos"]
		narr.add_child(n2)
		_paint_narrative(n2, String(extra["kind"]), String(extra["theme"]), stats)
		stats["decals"] = int(stats.get("decals", 0)) + 1


static func _paint_narrative(parent: Node2D, kind: String, theme: String, stats: Dictionary) -> void:
	match kind:
		"banner":
			_poly(parent, "Cloth", Palette.ORDER_DEEP_RED, _rect(-6, -28, 12, 28), "narrative_order", stats)
		"guard":
			_poly(parent, "Sil", Color(0.12, 0.1, 0.12, 0.55), _rect(-8, -40, 16, 40), "narrative_order", stats)
		"chalk_circle":
			_poly(parent, "Ring", Color(Palette.ORDER_AGED_CREAM.r, Palette.ORDER_AGED_CREAM.g, Palette.ORDER_AGED_CREAM.b, 0.35), _rect(-16, -2, 32, 4), "narrative_ritual", stats)
		"vermilite_crack", "vermilite":
			_poly(parent, "V", Palette.VERMILITE_SATURATED, PackedVector2Array([
				Vector2(0, 0), Vector2(4, -10), Vector2(8, 0),
			]), "narrative_vermilite", stats)
		"chains":
			_poly(parent, "C", Palette.METAL_COOL, _rect(-10, -16, 20, 4), "narrative_fear", stats)
		"candles", "ritual":
			for i in range(3):
				_poly(parent, "C%d" % i, Palette.ORDER_AGED_CREAM, _rect(i * 8 - 8, -12, 4, 12), "narrative_ritual", stats)
		"mining":
			_poly(parent, "Cart", Palette.METAL_COOL, _rect(-12, -6, 24, 8), "narrative_mining", stats)
		"scratch":
			_poly(parent, "S", Palette.ORDER_BURNT_RED, _rect(-14, -2, 28, 2), "narrative_resistance", stats)
		"sign_order":
			_poly(parent, "Sign", Palette.ORDER_BLACK, _rect(-14, -12, 28, 16), "narrative_order", stats)
			_poly(parent, "H", Palette.ORDER_BURNT_RED, _rect(-8, -8, 16, 6), "narrative_order", stats)
		"fear_curtain":
			_poly(parent, "Cloth", Color(0.2, 0.12, 0.14, 0.55), _rect(-6, -28, 12, 28), "narrative_fear", stats)
		"scuff":
			_poly(parent, "Sc", Palette.EARTH_DARK, _rect(-20, -1, 40, 3), "narrative_combat", stats)
		_:
			_poly(parent, "X", Palette.STONE_GREY, _rect(-6, -6, 12, 12), "narrative_%s" % theme, stats)


static func _build_kit_reuse(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var kit_host := Node2D.new()
	kit_host.name = "MoldKitSlots"
	root.add_child(kit_host)
	stats["kit_slots"] = KitBridge.spawn_kit_slots(kit_host, Layout.get_mold_kit_placements(ground_y))


static func _build_atmosphere_budget(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Modest particles — respect church profile budgets (not a second lighting system).
	var mist := GPUParticles2D.new()
	mist.name = "MoldChurchMist"
	mist.position = Vector2(900, ground_y - 60)
	mist.amount = 20
	mist.lifetime = 4.0
	mist.visibility_rect = Rect2(-1000, -160, 2000, 240)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.35, -0.1, 0)
	mat.spread = 18.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3(0, 2, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	mat.color = Color(0.45, 0.38, 0.48, 0.22)
	mist.process_material = mat
	_tag(mist, "atmosphere_mist")
	root.add_child(mist)
	stats["particles"] = int(stats.get("particles", 0)) + 1

	var ash := GPUParticles2D.new()
	ash.name = "MoldAshMotes"
	ash.position = Vector2(600, ground_y - 80)
	ash.amount = 10
	ash.lifetime = 3.2
	var ash_mat := ParticleProcessMaterial.new()
	ash_mat.direction = Vector3(0.1, -1, 0)
	ash_mat.spread = 12.0
	ash_mat.initial_velocity_min = 3.0
	ash_mat.initial_velocity_max = 9.0
	ash_mat.gravity = Vector3(0, -2, 0)
	ash_mat.scale_min = 0.3
	ash_mat.scale_max = 0.8
	ash_mat.color = Color(0.55, 0.4, 0.32, 0.2)
	ash.process_material = ash_mat
	_tag(ash, "atmosphere_ash")
	root.add_child(ash)
	stats["particles"] = int(stats.get("particles", 0)) + 1


static func _build_catacombs_direction_cue(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Boundary cue only — does not modify underground scenes.
	var cue := Node2D.new()
	cue.name = "CatacombsDirection"
	cue.position = Vector2(1700, ground_y - 36)
	root.add_child(cue)
	_poly(cue, "Post", Palette.STONE_GREY, _rect(-3, -48, 6, 48), "catacombs_waypost", stats)
	_poly(cue, "Board", Palette.ORDER_AGED_CREAM, _rect(0, -44, 44, 14), "catacombs_sign", stats)
	_poly(cue, "Arrow", Palette.ORDER_BURNT_RED, PackedVector2Array([
		Vector2(28, -37), Vector2(42, -37), Vector2(42, -33), Vector2(28, -33),
	]), "narrative_descent", stats)


static func _build_debug_badge(
	presentation: ChurchArtPresentation,
	ground_y: float,
	stats: Dictionary
) -> void:
	var debug_layer := presentation.get_node_or_null(LAYER_DEBUG) as Node2D
	if debug_layer == null:
		return
	var badge := Label.new()
	badge.name = "FinalMoldBandBadge"
	badge.position = Vector2(16, ground_y - 420)
	badge.text = (
		"%s | FULL CHURCH MOLD 0–1800 | 6 districts | not PNG-final"
		% Spec.PLACEHOLDER_TAG
	)
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.85, 0.75, 0.9, 0.85))
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
