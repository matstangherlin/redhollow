extends RefCounted
class_name StreetFinalMoldComposer

## Applies the approved North Star FINAL MOLD across the full Cap. Zero street (0–2400).
## Visual-only. Does NOT touch Solids collision, AttackData, church, or catacombs.
## All generated geometry is PLACEHOLDER_CANDIDATE until manifesto-approved PNGs land.

const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")
const Layout := preload("res://scripts/visual/street_north_star_layout.gd")
const Variants := preload("res://scripts/visual/street_north_star_variants.gd")
const Factory := preload("res://scripts/visual/street_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")
const KitBridge := preload("res://scripts/visual/street_kit_visual_bridge.gd")

const ROOT_NAME := "FinalMoldRoot"
const LAYER_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_GROUND := "Layer05_GameplayGround"
const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_ATMOSPHERE := "Layer10_Atmosphere"
const LAYER_FOREGROUND := "Layer11_Foreground"
const LAYER_DEBUG := "Layer12_Debug"


static func apply(presentation: StreetArtPresentation, profile: EnvironmentVisualProfile) -> Dictionary:
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
		"lights": 0,
		"particles": 0,
		"placeholder_tags": 0,
		"playfield_width": profile.playfield_width_px,
		"mold": "north_star_final_mold_v1",
	}

	for entry in Layout.get_districts():
		_build_district(root, entry, ground_y, stats)
		stats["districts"] = int(stats["districts"]) + 1

	_build_ground_materials_full(root, ground_y, profile.playfield_width_px, stats)
	_build_platform_readability(root, ground_y, stats)
	_build_narrative_full(root, ground_y, stats)
	_build_kit_reuse(root, ground_y, stats)
	_build_atmosphere_budget(root, ground_y, stats)
	_build_church_direction_cue(root, ground_y, stats)
	_build_debug_badge(presentation, ground_y, stats)
	return stats


static func remove(presentation: StreetArtPresentation) -> void:
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
	var label := String(entry.get("label", "district"))
	var node := Node2D.new()
	node.name = "District_%d_%s" % [district_id, theme]
	root.add_child(node)

	# Subtle district wash — not a flat solid facade replacement.
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

	var facades := Layout.get_mold_facades_for_district(district_id, ground_y)
	for spec in facades:
		_build_varied_facade(node, spec, ground_y, stats)

	var props := Layout.get_mold_props_for_district(district_id, ground_y)
	for prop in props:
		_build_prop(node, prop, stats)


static func _theme_wash(theme: String) -> Color:
	match theme:
		"arrival":
			return Color(Palette.EARTH_MID.r, Palette.EARTH_MID.g, Palette.EARTH_MID.b, 0.12)
		"resistance":
			return Color(Palette.WOOD_MID.r, Palette.WOOD_MID.g, Palette.WOOD_MID.b, 0.1)
		"decay":
			return Color(Palette.WOOD_DARK.r, Palette.WOOD_DARK.g, Palette.WOOD_DARK.b, 0.12)
		"order":
			return Color(Palette.ORDER_RITUAL_STONE.r, Palette.ORDER_RITUAL_STONE.g, Palette.ORDER_RITUAL_STONE.b, 0.14)
		"partner":
			return Color(0.2, 0.14, 0.22, 0.1)
		"vermilite":
			return Color(Palette.DUST_WARM.r, Palette.DUST_WARM.g, Palette.DUST_WARM.b, 0.1)
		"combat":
			return Color(Palette.EARTH_DARK.r, Palette.EARTH_DARK.g, Palette.EARTH_DARK.b, 0.12)
		"cult":
			return Color(Palette.ORDER_BLACK.r, Palette.ORDER_BLACK.g, Palette.ORDER_BLACK.b, 0.16)
		"church":
			return Color(Palette.STONE_GREY.r, Palette.STONE_GREY.g, Palette.STONE_GREY.b, 0.14)
		_:
			return Color(0.2, 0.15, 0.12, 0.08)


static func _build_varied_facade(
	parent: Node2D,
	spec: Dictionary,
	ground_y: float,
	stats: Dictionary
) -> void:
	var variant: int = int(spec.get("variant", 0))
	var width: float = float(spec.get("w", 96.0))
	var height: float = float(spec.get("h", 88.0))
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
		"material_wood_or_stone",
		stats
	)

	# Siding or stone joints — variation, not clone.
	var board_style := Variants.pick_variant(seed_key + "_board", 3)
	if board_style == 0:
		for i in range(int(width / 16.0)):
			var x := -half_w + 4.0 + float(i) * 16.0
			_poly(
				facade,
				"Siding_%d" % i,
				wall.darkened(0.08),
				PackedVector2Array([
					Vector2(x, -height + 4), Vector2(x + 1.5, -height + 4),
					Vector2(x + 1.5, -4), Vector2(x, -4),
				]),
				"material_wood_siding",
				stats
			)
	elif board_style == 1:
		for i in range(3):
			var y := -height * (0.3 + 0.2 * float(i))
			_poly(
				facade,
				"StoneCourse_%d" % i,
				wall.lightened(0.05),
				PackedVector2Array([
					Vector2(-half_w + 4, y), Vector2(half_w - 4, y),
					Vector2(half_w - 4, y + 2), Vector2(-half_w + 4, y + 2),
				]),
				"material_stone_course",
				stats
			)

	_build_roof(facade, half_w, height, roof_h, roof_color, variant, stats)

	for wx in Variants.window_offsets_for_variant(variant, width):
		var window_style := Variants.pick_variant(seed_key + "_win_%.0f" % wx, 2)
		var win_col := Palette.VERMILITE_HALO if lit else Palette.ORDER_BLACK.lightened(0.18)
		_poly(
			facade,
			"Window_%.0f" % wx,
			win_col,
			PackedVector2Array([
				Vector2(wx - 7, -height * 0.55 - 9),
				Vector2(wx + 7, -height * 0.55 - 9),
				Vector2(wx + 7, -height * 0.55 + 9),
				Vector2(wx - 7, -height * 0.55 + 9),
			]),
			"window_variant_%d" % window_style,
			stats
		)
		if window_style == 1:
			_poly(
				facade,
				"Shutter_%.0f" % wx,
				Palette.WOOD_DARK,
				PackedVector2Array([
					Vector2(wx - 11, -height * 0.55 - 8),
					Vector2(wx - 7, -height * 0.55 - 8),
					Vector2(wx - 7, -height * 0.55 + 8),
					Vector2(wx - 11, -height * 0.55 + 8),
				]),
				"window_shutter",
				stats
			)

	var door_x := Variants.door_offset_for_variant(variant)
	var door_style := Variants.pick_variant(seed_key + "_door", 3)
	var door_w := 10.0 + float(door_style) * 2.0
	_poly(
		facade,
		"Door",
		Palette.WOOD_DARK.darkened(0.05 * door_style),
		PackedVector2Array([
			Vector2(door_x - door_w, 0), Vector2(door_x + door_w, 0),
			Vector2(door_x + door_w, -40 - door_style * 2),
			Vector2(door_x - door_w, -40 - door_style * 2),
		]),
		"door_variant_%d" % door_style,
		stats
	)

	if variant % 2 == 0:
		_poly(
			facade,
			"Balcony",
			Palette.WOOD_MID,
			PackedVector2Array([
				Vector2(half_w * 0.2, -height * 0.42),
				Vector2(half_w * 0.55, -height * 0.42),
				Vector2(half_w * 0.55, -height * 0.42 + 6),
				Vector2(half_w * 0.2, -height * 0.42 + 6),
			]),
			"balcony_kit",
			stats
		)

	# Order / fear marks on some facades — narrative, not copy-paste.
	if Variants.pick_variant(seed_key + "_mark", 5) == 0:
		_poly(
			facade,
			"OrderHeart",
			Color(Palette.ORDER_BURNT_RED.r, Palette.ORDER_BURNT_RED.g, Palette.ORDER_BURNT_RED.b, 0.55),
			_heart(Vector2(-half_w * 0.35, -height * 0.7), 5.0),
			"narrative_order",
			stats
		)

	stats["facades"] = int(stats.get("facades", 0)) + 1


static func _build_roof(
	facade: Node2D,
	half_w: float,
	height: float,
	roof_h: float,
	roof_color: Color,
	variant: int,
	stats: Dictionary
) -> void:
	var pts: PackedVector2Array
	match variant % 3:
		0:
			pts = PackedVector2Array([
				Vector2(-half_w - 6, -height), Vector2(half_w + 6, -height),
				Vector2(half_w, -height - roof_h), Vector2(-half_w, -height - roof_h),
			])
		1:
			pts = PackedVector2Array([
				Vector2(-half_w - 4, -height), Vector2(half_w + 4, -height),
				Vector2(0, -height - roof_h - 8),
			])
		_:
			pts = PackedVector2Array([
				Vector2(-half_w, -height), Vector2(half_w, -height),
				Vector2(half_w, -height - roof_h * 0.45),
				Vector2(-half_w, -height - roof_h),
			])
	_poly(facade, "Roof", roof_color, pts, "roof_variant_%d" % (variant % 3), stats)


static func _build_prop(parent: Node2D, prop: Dictionary, stats: Dictionary) -> void:
	var kind := String(prop.get("kind", "crate"))
	var pos: Vector2 = prop.get("pos", Vector2.ZERO)
	var node := Node2D.new()
	node.name = "Prop_%s_%.0f" % [kind, pos.x]
	node.position = pos
	parent.add_child(node)
	match kind:
		"barrel":
			_poly(node, "B", Palette.WOOD_DARK, _rect(-8, -16, 16, 16), "prop_barrel", stats)
		"crate":
			_poly(node, "C", Palette.WOOD_MID, _rect(-10, -14, 20, 14), "prop_crate", stats)
		"fence":
			_poly(node, "F", Palette.WOOD_DARK, _rect(-24, -20, 48, 20), "prop_fence", stats)
		"lamp":
			_poly(node, "Pole", Palette.METAL_COOL, _rect(-2, -72, 4, 72), "prop_lamp_metal", stats)
			_poly(node, "Glow", Color(1.0, 0.65, 0.3, 0.45), _rect(-6, -84, 12, 12), "prop_lamp_glow", stats)
		"wagon":
			_poly(node, "Bed", Palette.WOOD_MID, _rect(-40, -28, 80, 28), "prop_wagon", stats)
			_poly(node, "WheelL", Palette.METAL_COOL, _rect(-28, -12, 12, 12), "prop_wagon_wheel", stats)
			_poly(node, "WheelR", Palette.METAL_COOL, _rect(16, -12, 12, 12), "prop_wagon_wheel", stats)
		"poster":
			_poly(node, "P", Palette.FABRIC_TAN, _rect(-8, -16, 16, 16), "narrative_disappear", stats)
			_poly(node, "X", Palette.ORDER_DEEP_RED, _rect(-4, -12, 8, 4), "narrative_missing", stats)
		"sign_church":
			_poly(node, "Board", Palette.STONE_GREY, _rect(-18, -14, 36, 14), "narrative_church_dir", stats)
			_poly(node, "Arrow", Palette.ORDER_BURNT_RED, PackedVector2Array([
				Vector2(4, -7), Vector2(16, -7), Vector2(16, -3), Vector2(4, -3),
			]), "narrative_church_arrow", stats)
		_:
			_poly(node, "G", Palette.EARTH_MID, _rect(-6, -6, 12, 12), "prop_generic", stats)
	stats["props"] = int(stats.get("props", 0)) + 1


static func _build_ground_materials_full(
	root: Node2D,
	ground_y: float,
	width: float,
	stats: Dictionary
) -> void:
	var ground := Node2D.new()
	ground.name = "MoldGround"
	root.add_child(ground)
	# Dirt base with irregular cracks — not one flat rectangle only.
	_poly(
		ground,
		"Dirt",
		Palette.EARTH_MID,
		PackedVector2Array([
			Vector2(0, ground_y), Vector2(width, ground_y),
			Vector2(width, ground_y + 22), Vector2(0, ground_y + 22),
		]),
		"material_earth",
		stats
	)
	var crack_count := int(width / 110.0)
	for i in range(crack_count):
		var x0 := 40.0 + float(i) * 110.0 + float(i % 3) * 7.0
		_poly(
			ground,
			"Crack_%d" % i,
			Color(0.18, 0.12, 0.08, 0.5),
			PackedVector2Array([
				Vector2(x0, ground_y + 3), Vector2(x0 + 32, ground_y + 5),
				Vector2(x0 + 28, ground_y + 7), Vector2(x0 - 2, ground_y + 6),
			]),
			"material_earth_crack",
			stats
		)
	# Boardwalk near saloon only (reuse kit language).
	for i in range(6):
		var px := 240.0 + float(i) * 18.0
		_poly(
			ground,
			"Plank_%d" % i,
			Palette.WOOD_MID.darkened(0.05 * (i % 2)),
			_rect_abs(px, ground_y - 2, 16, 8),
			"material_wood_boardwalk",
			stats
		)


static func _build_platform_readability(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Visual edges for elevated platforms — Solids remain authoritative.
	var platforms: Array[Dictionary] = [
		{"name": "PlatA", "x": 560.0, "y": 808.0, "w": 180.0},
		{"name": "PlatB", "x": 860.0, "y": 748.0, "w": 160.0},
		{"name": "PlatC", "x": 1160.0, "y": 688.0, "w": 140.0},
		{"name": "Return", "x": 1360.0, "y": 768.0, "w": 120.0},
	]
	for p in platforms:
		var node := Node2D.new()
		node.name = String(p["name"])
		node.position = Vector2(float(p["x"]), float(p["y"]))
		root.add_child(node)
		var hw := float(p["w"]) * 0.5
		_poly(
			node,
			"Deck",
			Palette.WOOD_MID,
			PackedVector2Array([
				Vector2(-hw, -6), Vector2(hw, -6), Vector2(hw, 6), Vector2(-hw, 6),
			]),
			"platform_deck",
			stats
		)
		_poly(
			node,
			"Edge",
			Color(0.75, 0.55, 0.32, 0.55),
			PackedVector2Array([
				Vector2(-hw, -6), Vector2(hw, -6), Vector2(hw, -3), Vector2(-hw, -3),
			]),
			"legibility_platform_edge",
			stats
		)


static func _build_narrative_full(root: Node2D, ground_y: float, stats: Dictionary) -> void:
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
	# Extra full-street beats from mold plan.
	for extra in Layout.get_mold_extra_narrative(ground_y):
		var n2 := Node2D.new()
		n2.name = "NarrExtra_%s" % extra["id"]
		n2.position = extra["pos"]
		narr.add_child(n2)
		_paint_narrative(n2, String(extra["kind"]), String(extra["theme"]), stats)
		stats["decals"] = int(stats.get("decals", 0)) + 1


static func _paint_narrative(parent: Node2D, kind: String, theme: String, stats: Dictionary) -> void:
	match kind:
		"poster", "missing_poster":
			_poly(parent, "Poster", Palette.FABRIC_TAN, _rect(-10, -18, 20, 18), "narrative_disappear", stats)
			_poly(parent, "Mark", Palette.ORDER_DEEP_RED, _rect(-6, -14, 12, 4), "narrative_disappear", stats)
		"chalk_heart":
			_poly(parent, "Heart", Palette.ORDER_BURNT_RED, _heart(Vector2.ZERO, 6.0), "narrative_order", stats)
		"tracks":
			for i in range(3):
				_poly(parent, "T%d" % i, Palette.EARTH_DARK, _rect(i * 10 - 8, -2, 6, 3), "narrative_partner", stats)
		"mining":
			_poly(parent, "Cart", Palette.METAL_COOL, _rect(-12, -6, 24, 8), "narrative_mining", stats)
			_poly(parent, "Ore", Palette.VERMILITE_SATURATED, PackedVector2Array([
				Vector2(4, 0), Vector2(8, -8), Vector2(12, 0),
			]), "narrative_vermilite", stats)
		"scratch":
			_poly(parent, "S", Palette.ORDER_BURNT_RED, _rect(-14, -2, 28, 2), "narrative_resistance", stats)
		"vermilite":
			_poly(parent, "V", Palette.VERMILITE_SATURATED, PackedVector2Array([
				Vector2(0, 0), Vector2(4, -10), Vector2(8, 0),
			]), "narrative_vermilite", stats)
		"debris":
			_poly(parent, "D1", Palette.WOOD_DARK, _rect(-16, -8, 14, 10), "narrative_poverty", stats)
			_poly(parent, "D2", Palette.WOOD_MID, _rect(4, -6, 12, 8), "narrative_poverty", stats)
		"ritual":
			for i in range(3):
				_poly(parent, "C%d" % i, Palette.ORDER_AGED_CREAM, _rect(i * 8 - 8, -12, 4, 12), "narrative_fear", stats)
		"scuff":
			_poly(parent, "Sc", Palette.EARTH_DARK, _rect(-20, -1, 40, 3), "narrative_combat", stats)
		"sign_order":
			_poly(parent, "Sign", Palette.ORDER_BLACK, _rect(-14, -12, 28, 16), "narrative_order", stats)
			_poly(parent, "H", Palette.ORDER_BURNT_RED, _rect(-8, -8, 16, 6), "narrative_order", stats)
		"partner_token":
			_poly(parent, "Med", Palette.LEATHER, _rect(-8, -8, 16, 16), "narrative_partner", stats)
			_poly(parent, "Dot", Palette.ORDER_BURNT_RED, _rect(-3, -3, 6, 6), "narrative_partner", stats)
		"fear_curtain":
			_poly(parent, "Cloth", Color(0.2, 0.12, 0.14, 0.55), _rect(-6, -28, 12, 28), "narrative_fear", stats)
		_:
			_poly(parent, "X", Palette.EARTH_MID, _rect(-6, -6, 12, 12), "narrative_%s" % theme, stats)


static func _build_kit_reuse(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var kit_host := Node2D.new()
	kit_host.name = "MoldKitSlots"
	root.add_child(kit_host)
	stats["kit_slots"] = KitBridge.spawn_kit_slots(kit_host, Layout.get_mold_kit_placements(ground_y))


static func _build_atmosphere_budget(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	## Modest particles — respect street profile budgets.
	var dust := GPUParticles2D.new()
	dust.name = "MoldStreetDust"
	dust.position = Vector2(1200, ground_y - 48)
	dust.amount = 24
	dust.lifetime = 3.5
	dust.visibility_rect = Rect2(-1300, -140, 2600, 220)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, -0.12, 0)
	mat.spread = 16.0
	mat.initial_velocity_min = 6.0
	mat.initial_velocity_max = 18.0
	mat.gravity = Vector3(0, 3, 0)
	mat.scale_min = 0.4
	mat.scale_max = 1.0
	mat.color = Color(0.7, 0.55, 0.38, 0.28)
	dust.process_material = mat
	_tag(dust, "atmosphere_dust")
	root.add_child(dust)
	stats["particles"] = int(stats.get("particles", 0)) + 1

	var smoke := GPUParticles2D.new()
	smoke.name = "MoldSaloonSmoke"
	smoke.position = Vector2(300, ground_y - 150)
	smoke.amount = 6
	smoke.lifetime = 3.5
	var smoke_mat := ParticleProcessMaterial.new()
	smoke_mat.direction = Vector3(0.15, -1, 0)
	smoke_mat.spread = 10.0
	smoke_mat.initial_velocity_min = 5.0
	smoke_mat.initial_velocity_max = 12.0
	smoke_mat.gravity = Vector3(0, -5, 0)
	smoke_mat.scale_min = 1.0
	smoke_mat.scale_max = 2.0
	smoke_mat.color = Color(0.32, 0.28, 0.26, 0.22)
	smoke.process_material = smoke_mat
	_tag(smoke, "atmosphere_smoke")
	root.add_child(smoke)
	stats["particles"] = int(stats.get("particles", 0)) + 1


static func _build_church_direction_cue(root: Node2D, ground_y: float, stats: Dictionary) -> void:
	var cue := Node2D.new()
	cue.name = "ChurchDirection"
	cue.position = Vector2(2140, ground_y - 40)
	root.add_child(cue)
	_poly(cue, "Post", Palette.STONE_GREY, _rect(-3, -48, 6, 48), "church_waypost", stats)
	_poly(cue, "Board", Palette.ORDER_AGED_CREAM, _rect(0, -44, 40, 14), "church_sign", stats)
	_poly(cue, "Arrow", Palette.ORDER_BURNT_RED, PackedVector2Array([
		Vector2(28, -37), Vector2(40, -37), Vector2(40, -33), Vector2(28, -33),
	]), "narrative_church_dir", stats)


static func _build_debug_badge(
	presentation: StreetArtPresentation,
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
		"%s | FULL STREET MOLD 0–2400 | 9 districts | not PNG-final"
		% Spec.PLACEHOLDER_TAG
	)
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55, 0.85))
	_tag(badge, "debug_badge")
	debug_layer.add_child(badge)


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h),
	])


static func _rect_abs(x: float, y: float, w: float, h: float) -> PackedVector2Array:
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
