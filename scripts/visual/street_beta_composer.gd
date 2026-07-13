extends RefCounted
class_name StreetBetaComposer

## Beta-complete North Star street — districts, kit bridge, narrative decals, arena visual.

const Layout := preload("res://scripts/visual/street_north_star_layout.gd")
const Variants := preload("res://scripts/visual/street_north_star_variants.gd")
const KitBridge := preload("res://scripts/visual/street_kit_visual_bridge.gd")
const Factory := preload("res://scripts/visual/street_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

const LAYER_GAMEPLAY_GROUND := "Layer05_GameplayGround"
const LAYER_GAMEPLAY_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACTABLES := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"


static func compose(presentation: StreetArtPresentation, profile: EnvironmentVisualProfile) -> Dictionary:
	var ground_y := Factory.ground_anchor_y(profile)
	var stats := {
		"districts": Layout.get_districts().size(),
		"buildings": 0,
		"decals": 0,
		"kit_slots": 0,
		"arena": false,
		"entrance": false,
	}

	var ground := presentation.get_node_or_null(LAYER_GAMEPLAY_GROUND) as Node2D
	var structures := presentation.get_node_or_null(LAYER_GAMEPLAY_STRUCTURES) as Node2D
	var props := presentation.get_node_or_null(LAYER_PROPS) as Node2D
	var interactables := presentation.get_node_or_null(LAYER_INTERACTABLES) as Node2D
	var lighting := presentation.get_node_or_null(LAYER_LIGHTING) as Node2D

	if ground != null:
		_build_district_ground_tints(ground, profile, ground_y)
		_enhance_platform_edges(ground)

	if structures != null:
		stats["entrance"] = _build_entrance_gateway(structures, ground_y)
		stats["buildings"] += _build_layout_facades(structures, ground_y)
		stats["buildings"] += _build_church_approach(structures, ground_y, profile.playfield_width_px)

	if props != null:
		stats["decals"] = _build_narrative_decals(props, ground_y)
		stats["arena"] = _build_street_arena_ring(props, Vector2(1280, ground_y))
		stats["kit_slots"] = KitBridge.spawn_kit_slots(
			props,
			Layout.get_kit_module_placements(ground_y)
		)
		_build_tutorial_zone_markers(props, ground_y)

	if interactables != null:
		_rebuild_interactable_markers(interactables, profile)

	if lighting != null:
		_add_district_lights(lighting, ground_y)

	return stats


static func _build_district_ground_tints(layer: Node2D, profile: EnvironmentVisualProfile, ground_y: float) -> void:
	var width := profile.playfield_width_px
	var tints: Dictionary = Layout.get_district_ground_tints()
	for entry in Layout.get_districts():
		var district: int = int(entry["id"])
		var x_min := float(entry["x_min"])
		var x_max := float(entry["x_max"])
		var tint: Color = tints.get(district, Palette.EARTH_MID)
		var strip := Polygon2D.new()
		strip.name = "DistrictTint_%s" % String(entry["label"]).replace(" ", "")
		strip.color = tint.lightened(0.06)
		strip.modulate = Color(1, 1, 1, 0.22)
		strip.polygon = PackedVector2Array([
			Vector2(x_min, ground_y + 2), Vector2(x_max, ground_y + 2),
			Vector2(x_max, ground_y + 20), Vector2(x_min, ground_y + 20),
		])
		layer.add_child(strip)


static func _enhance_platform_edges(ground_layer: Node2D) -> void:
	for child in ground_layer.get_children():
		if not String(child.name).begins_with("GameplayPlatform_"):
			continue
		var edge := Polygon2D.new()
		edge.name = "PlatformEdgeHighlight"
		edge.color = Palette.DUST_WARM
		edge.modulate = Color(1, 1, 1, 0.55)
		edge.position = Vector2(0, -12)
		edge.polygon = PackedVector2Array([
			Vector2(-88, 0), Vector2(88, 0), Vector2(88, 2), Vector2(-88, 2),
		])
		child.add_child(edge)


static func _build_entrance_gateway(structures: Node2D, ground_y: float) -> bool:
	var root := Node2D.new()
	root.name = "CityEntranceGateway"
	root.position = Vector2(60, ground_y)
	structures.add_child(root)

	var arch := Polygon2D.new()
	arch.name = "EntranceArch"
	arch.color = Palette.STONE_GREY
	arch.polygon = PackedVector2Array([
		Vector2(-48, 0), Vector2(48, 0), Vector2(48, -56), Vector2(24, -72),
		Vector2(-24, -72), Vector2(-48, -56),
	])
	root.add_child(arch)

	var sign := Polygon2D.new()
	sign.name = "EntranceSignBoard"
	sign.color = Palette.WOOD_DARK
	sign.position = Vector2(-20, -88)
	sign.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(40, 0), Vector2(40, 16), Vector2(0, 16),
	])
	root.add_child(sign)

	var welcome := Polygon2D.new()
	welcome.name = "EntranceDustVeil"
	welcome.color = Palette.DUST_WARM
	welcome.modulate = Color(1, 1, 1, 0.18)
	welcome.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(80, 0), Vector2(120, 24), Vector2(-120, 24),
	])
	root.add_child(welcome)
	return true


static func _build_layout_facades(structures: Node2D, ground_y: float) -> int:
	var count := 0
	for spec in Layout.get_building_specs(ground_y):
		var variant: int = int(spec.get("variant", 0))
		var root := Node2D.new()
		root.name = String(spec.get("name", "Building"))
		root.position = spec["pos"]
		structures.add_child(root)
		_build_variant_facade(
			root,
			float(spec["w"]),
			float(spec["h"]),
			float(spec["roof"]),
			variant,
			bool(spec.get("lit", false))
		)
		count += 1
	return count


static func _build_variant_facade(
	parent: Node2D,
	width: float,
	height: float,
	roof_h: float,
	variant: int,
	lit_windows: bool
) -> void:
	var half_w := width * 0.5
	var wall := Variants.wall_color_for_variant(variant)
	var roof_color := Variants.roof_color_for_variant(variant)

	var body := Polygon2D.new()
	body.name = "FacadeBody"
	body.color = wall
	body.polygon = PackedVector2Array([
		Vector2(-half_w, 0), Vector2(half_w, 0), Vector2(half_w, -height), Vector2(-half_w, -height),
	])
	parent.add_child(body)

	var roof := Polygon2D.new()
	roof.name = "FacadeRoof"
	roof.color = roof_color
	match variant % 3:
		0:
			roof.polygon = PackedVector2Array([
				Vector2(-half_w - 6, -height), Vector2(half_w + 6, -height),
				Vector2(half_w, -height - roof_h), Vector2(-half_w, -height - roof_h),
			])
		1:
			roof.polygon = PackedVector2Array([
				Vector2(-half_w - 4, -height), Vector2(half_w + 4, -height),
				Vector2(0, -height - roof_h - 8), Vector2(-half_w - 4, -height),
			])
		_:
			roof.polygon = PackedVector2Array([
				Vector2(-half_w, -height), Vector2(half_w, -height),
				Vector2(half_w, -height - roof_h * 0.5), Vector2(-half_w, -height - roof_h),
			])
	parent.add_child(roof)

	for wx in Variants.window_offsets_for_variant(variant, width):
		var window := Polygon2D.new()
		window.color = Palette.VERMILITE_HALO if lit_windows else Palette.ORDER_BLACK.lightened(0.2)
		window.position = Vector2(wx, -height * 0.55)
		window.polygon = PackedVector2Array([
			Vector2(-7, -9), Vector2(7, -9), Vector2(7, 9), Vector2(-7, 9),
		])
		parent.add_child(window)

	var door_x := Variants.door_offset_for_variant(variant)
	var door := Polygon2D.new()
	door.name = "FacadeDoor"
	door.color = Palette.WOOD_DARK
	door.position = Vector2(door_x, -22)
	door.polygon = PackedVector2Array([
		Vector2(-11, 0), Vector2(11, 0), Vector2(11, -42), Vector2(-11, -42),
	])
	parent.add_child(door)

	if variant % 2 == 0:
		var balcony := Polygon2D.new()
		balcony.name = "FacadeBalcony"
		balcony.color = Palette.WOOD_MID
		balcony.position = Vector2(half_w * 0.35, -height * 0.42)
		balcony.polygon = PackedVector2Array([
			Vector2(-18, 0), Vector2(18, 0), Vector2(18, 6), Vector2(-18, 6),
		])
		parent.add_child(balcony)


static func _build_church_approach(structures: Node2D, ground_y: float, width: float) -> int:
	var root := Node2D.new()
	root.name = "ChurchApproach"
	root.position = Vector2(width - 120, ground_y)
	structures.add_child(root)

	var steps := Polygon2D.new()
	steps.color = Palette.ORDER_RITUAL_STONE
	steps.polygon = PackedVector2Array([
		Vector2(-64, 0), Vector2(64, 0), Vector2(48, -12), Vector2(-48, -12),
	])
	root.add_child(steps)

	var candles := Polygon2D.new()
	candles.name = "ChurchCandleGlow"
	candles.color = Palette.ORDER_BURNT_RED
	candles.modulate = Color(1, 1, 1, 0.45)
	candles.position = Vector2(-32, -28)
	candles.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(8, -16), Vector2(16, 0),
		Vector2(48, 0), Vector2(56, -16), Vector2(64, 0),
	])
	root.add_child(candles)
	return 1


static func _build_narrative_decals(props: Node2D, ground_y: float) -> int:
	var count := 0
	for entry in Layout.get_narrative_decals(ground_y):
		var root := Node2D.new()
		root.name = "Narrative_%s" % entry["id"]
		root.position = entry["pos"]
		props.add_child(root)
		_paint_decal(root, String(entry["kind"]), String(entry["theme"]))
		count += 1
	return count


static func _paint_decal(parent: Node2D, kind: String, theme: String) -> void:
	match kind:
		"poster":
			_add_rect(parent, Palette.FABRIC_TAN, Vector2(-10, -18), Vector2(20, 18))
			_add_rect(parent, Palette.ORDER_DEEP_RED, Vector2(-6, -14), Vector2(12, 4))
		"chalk_heart":
			var heart := Polygon2D.new()
			heart.color = Palette.ORDER_BURNT_RED
			heart.polygon = PackedVector2Array([
				Vector2(0, -4), Vector2(4, -8), Vector2(8, -4), Vector2(0, 4), Vector2(-8, -4), Vector2(-4, -8),
			])
			parent.add_child(heart)
		"tracks":
			for i in range(3):
				_add_rect(parent, Palette.EARTH_DARK, Vector2(i * 10 - 8, -2), Vector2(6, 3))
		"mining":
			_add_rect(parent, Palette.METAL_COOL, Vector2(-12, -6), Vector2(24, 8))
			var ore := Polygon2D.new()
			ore.color = Palette.VERMILITE_SATURATED
			ore.position = Vector2(6, -4)
			ore.polygon = PackedVector2Array([Vector2(0, 0), Vector2(4, -8), Vector2(8, 0)])
			parent.add_child(ore)
		"scratch":
			_add_rect(parent, Palette.ORDER_BURNT_RED, Vector2(-14, -2), Vector2(28, 2))
		"vermilite":
			for i in range(2):
				var shard := Polygon2D.new()
				shard.color = Palette.VERMILITE_SATURATED
				shard.position = Vector2(i * 10 - 4, 0)
				shard.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3, -10), Vector2(6, 0)])
				parent.add_child(shard)
		"debris":
			_add_rect(parent, Palette.WOOD_DARK, Vector2(-16, -8), Vector2(14, 10))
			_add_rect(parent, Palette.WOOD_MID, Vector2(4, -6), Vector2(12, 8))
		"ritual":
			for i in range(3):
				_add_rect(parent, Palette.ORDER_AGED_CREAM, Vector2(i * 8 - 8, -12), Vector2(4, 12))
		"scuff":
			_add_rect(parent, Palette.EARTH_DARK, Vector2(-20, -1), Vector2(40, 3))
		"sign_order":
			_add_rect(parent, Palette.ORDER_BLACK, Vector2(-14, -12), Vector2(28, 16))
			_add_rect(parent, Palette.ORDER_BURNT_RED, Vector2(-8, -8), Vector2(16, 6))
		_:
			_add_rect(parent, Palette.EARTH_MID, Vector2(-6, -6), Vector2(12, 12))


static func _build_street_arena_ring(props: Node2D, center: Vector2) -> bool:
	var root := Node2D.new()
	root.name = "StreetArenaVisual"
	root.position = center
	props.add_child(root)

	var ring := Polygon2D.new()
	ring.name = "ArenaDustRing"
	ring.color = Palette.DUST_WARM
	ring.modulate = Color(1, 1, 1, 0.28)
	ring.polygon = _ellipse_polygon(72, 20, 24)
	root.add_child(ring)

	var posts: Array[float] = [-56, -28, 0, 28, 56]
	for x in posts:
		var post := Polygon2D.new()
		post.color = Palette.WOOD_DARK
		post.position = Vector2(x, 0)
		post.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(2, 0), Vector2(2, -24), Vector2(-2, -24),
		])
		root.add_child(post)
	return true


static func _build_tutorial_zone_markers(props: Node2D, ground_y: float) -> void:
	var root := Node2D.new()
	root.name = "TutorialZoneVisual"
	root.position = Vector2(1180, ground_y - 48)
	props.add_child(root)

	var banner := Polygon2D.new()
	banner.color = Palette.LEATHER
	banner.modulate = Color(1, 1, 1, 0.35)
	banner.polygon = PackedVector2Array([
		Vector2(-48, 0), Vector2(48, 0), Vector2(40, -16), Vector2(-40, -16),
	])
	root.add_child(banner)


static func _rebuild_interactable_markers(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
	for child in layer.get_children():
		layer.remove_child(child)
		child.free()
	var ground_y := Factory.ground_anchor_y(profile)
	for entry in Layout.get_interactable_markers(ground_y):
		var ring := Polygon2D.new()
		ring.name = "InteractMarker_%s" % entry["id"]
		ring.position = entry["pos"]
		ring.color = entry["color"]
		ring.polygon = _ellipse_polygon(10, 12, 12)
		layer.add_child(ring)


static func _add_district_lights(lighting: Node2D, ground_y: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var extra_positions: Array[Vector2] = [
		Vector2(100, ground_y - 8),
		Vector2(520, ground_y - 12),
		Vector2(1380, ground_y - 8),
		Vector2(2180, ground_y - 16),
	]
	for index in range(extra_positions.size()):
		var point := PointLight2D.new()
		point.name = "DistrictLantern_%d" % (index + 1)
		point.position = extra_positions[index]
		point.color = Color(0.95, 0.58, 0.26, 1.0)
		point.energy = 0.42
		point.texture_scale = 0.38
		point.shadow_enabled = false
		lighting.add_child(point)


static func _add_rect(parent: Node2D, color: Color, pos: Vector2, size: Vector2) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.position = pos
	poly.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y),
	])
	parent.add_child(poly)


static func _ellipse_polygon(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
