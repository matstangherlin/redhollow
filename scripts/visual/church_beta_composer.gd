extends RefCounted
class_name ChurchBetaComposer

const Layout := preload("res://scripts/visual/church_north_star_layout.gd")
const Variants := preload("res://scripts/visual/church_north_star_variants.gd")
const KitBridge := preload("res://scripts/visual/street_kit_visual_bridge.gd")
const Factory := preload("res://scripts/visual/church_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

const LAYER_GAMEPLAY_GROUND := "Layer05_GameplayGround"
const LAYER_GAMEPLAY_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACTABLES := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"


static func compose(presentation: Node2D, profile: EnvironmentVisualProfile) -> Dictionary:
	var ground_y := Factory.ground_anchor_y(profile)
	var stats := {
		"districts": Layout.get_districts().size(),
		"buildings": 0,
		"decals": 0,
		"kit_slots": 0,
		"set_pieces": 0,
	}

	var ground := presentation.get_node_or_null(LAYER_GAMEPLAY_GROUND) as Node2D
	var structures := presentation.get_node_or_null(LAYER_GAMEPLAY_STRUCTURES) as Node2D
	var props := presentation.get_node_or_null(LAYER_PROPS) as Node2D
	var interactables := presentation.get_node_or_null(LAYER_INTERACTABLES) as Node2D
	var lighting := presentation.get_node_or_null(LAYER_LIGHTING) as Node2D

	if ground != null:
		_build_district_ground_tints(ground, profile, ground_y)

	if structures != null:
		stats["buildings"] += _build_layout_facades(structures, ground_y)
		stats["set_pieces"] += _build_set_piece_markers(structures, ground_y)

	if props != null:
		stats["decals"] = _build_narrative_decals(props, ground_y)
		stats["kit_slots"] = KitBridge.spawn_kit_slots(props, Layout.get_kit_module_placements(ground_y))
		_build_cult_gate_visual(props, Vector2(1150, ground_y))
		_build_underground_passage_visual(props, Vector2(1500, ground_y - 16))

	if interactables != null:
		_build_interactable_markers(interactables, profile)

	if lighting != null:
		_add_district_lights(lighting, ground_y)

	return stats


static func _build_district_ground_tints(layer: Node2D, profile: EnvironmentVisualProfile, ground_y: float) -> void:
	var tints: Dictionary = Layout.get_district_ground_tints()
	for entry in Layout.get_districts():
		var district: int = int(entry["id"])
		var tint: Color = tints.get(district, Palette.STONE_GREY)
		var strip := Polygon2D.new()
		strip.name = "DistrictTint_%s" % String(entry["label"]).replace(" ", "")
		strip.color = tint.lightened(0.04)
		strip.modulate = Color(1, 1, 1, 0.2)
		strip.polygon = PackedVector2Array([
			Vector2(float(entry["x_min"]), ground_y + 2), Vector2(float(entry["x_max"]), ground_y + 2),
			Vector2(float(entry["x_max"]), ground_y + 18), Vector2(float(entry["x_min"]), ground_y + 18),
		])
		layer.add_child(strip)


static func _build_layout_facades(structures: Node2D, ground_y: float) -> int:
	var count := 0
	for spec in Layout.get_building_specs(ground_y):
		var variant: int = int(spec.get("variant", 0))
		var height: float = float(spec["h"]) * Variants.facade_height_multiplier(variant)
		var root := Node2D.new()
		root.name = String(spec.get("name", "Building"))
		root.position = spec["pos"]
		structures.add_child(root)
		_build_variant_facade(root, float(spec["w"]), height, float(spec["roof"]), variant, bool(spec.get("lit", false)))
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
	body.color = wall
	body.polygon = PackedVector2Array([
		Vector2(-half_w, 0), Vector2(half_w, 0), Vector2(half_w, -height), Vector2(-half_w, -height),
	])
	parent.add_child(body)

	var roof := Polygon2D.new()
	roof.color = roof_color
	roof.polygon = PackedVector2Array([
		Vector2(-half_w - 4, -height), Vector2(0, -height - roof_h - 16), Vector2(half_w + 4, -height),
	])
	parent.add_child(roof)

	for wx in Variants.window_offsets_for_variant(variant, width):
		var window := Polygon2D.new()
		window.color = Palette.VERMILITE_HALO if lit_windows else Palette.ORDER_BLACK.lightened(0.15)
		window.position = Vector2(wx, -height * 0.58)
		window.polygon = PackedVector2Array([
			Vector2(-5, -12), Vector2(5, -12), Vector2(5, 12), Vector2(-5, 12),
		])
		parent.add_child(window)


static func _build_set_piece_markers(structures: Node2D, ground_y: float) -> int:
	var positions: Dictionary = Layout.get_set_piece_positions(ground_y)
	for key in positions.keys():
		var marker := Polygon2D.new()
		marker.name = "SetPiece_%s" % String(key)
		marker.position = positions[key]
		marker.color = Palette.ORDER_BURNT_RED
		marker.modulate = Color(1, 1, 1, 0.08)
		marker.polygon = PackedVector2Array([
			Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
		])
		structures.add_child(marker)
	return positions.size()


static func _build_narrative_decals(props: Node2D, ground_y: float) -> int:
	var count := 0
	for entry in Layout.get_narrative_decals(ground_y):
		var root := Node2D.new()
		root.name = "Narrative_%s" % entry["id"]
		root.position = entry["pos"]
		props.add_child(root)
		_paint_decal(root, String(entry["kind"]))
		count += 1
	return count


static func _paint_decal(parent: Node2D, kind: String) -> void:
	match kind:
		"banner":
			_add_rect(parent, Palette.ORDER_DEEP_RED, Vector2(-8, -24), Vector2(16, 24))
		"guard":
			_add_rect(parent, Palette.ORDER_BLACK, Vector2(-4, -24), Vector2(8, 24))
		"chalk_circle":
			var ring := Polygon2D.new()
			ring.color = Palette.ORDER_BURNT_RED
			ring.modulate = Color(1, 1, 1, 0.45)
			ring.polygon = _ellipse_polygon(16, 6, 16)
			parent.add_child(ring)
		"vermilite_crack":
			for i in range(2):
				var shard := Polygon2D.new()
				shard.color = Palette.VERMILITE_SATURATED
				shard.position = Vector2(i * 10 - 4, 0)
				shard.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3, -12), Vector2(6, 0)])
				parent.add_child(shard)
		"chains":
			_add_rect(parent, Palette.METAL_COOL, Vector2(-16, -2), Vector2(32, 3))
		"candles":
			for i in range(3):
				_add_rect(parent, Palette.ORDER_AGED_CREAM, Vector2(i * 8 - 8, -12), Vector2(4, 12))
		"mining":
			_add_rect(parent, Palette.METAL_COOL, Vector2(-10, -6), Vector2(20, 8))
		"scratch":
			_add_rect(parent, Palette.ORDER_BURNT_RED, Vector2(-12, -1), Vector2(24, 2))
		_:
			_add_rect(parent, Palette.STONE_GREY, Vector2(-6, -6), Vector2(12, 12))


static func _build_cult_gate_visual(props: Node2D, pos: Vector2) -> void:
	var root := Node2D.new()
	root.name = "CultGateVisual"
	root.position = pos
	props.add_child(root)

	var posts: Array[float] = [-24, 24]
	for x in posts:
		var post := Polygon2D.new()
		post.color = Palette.ORDER_BLACK
		post.position = Vector2(x, 0)
		post.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0), Vector2(2, -56), Vector2(-2, -56),
		])
		root.add_child(post)

	var bar := Polygon2D.new()
	bar.color = Palette.ORDER_BURNT_RED
	bar.position = Vector2(-24, -40)
	bar.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(48, 0), Vector2(48, 6), Vector2(0, 6),
	])
	root.add_child(bar)


static func _build_underground_passage_visual(props: Node2D, pos: Vector2) -> void:
	var root := Node2D.new()
	root.name = "UndergroundPassageVisual"
	root.position = pos
	props.add_child(root)

	var arch := Polygon2D.new()
	arch.color = Palette.ORDER_BLACK
	arch.polygon = PackedVector2Array([
		Vector2(-40, 16), Vector2(40, 16), Vector2(32, -24), Vector2(0, -40), Vector2(-32, -24),
	])
	root.add_child(arch)

	var glow := Polygon2D.new()
	glow.color = Palette.VERMILITE_SHADOW
	glow.modulate = Color(1, 1, 1, 0.35)
	glow.position = Vector2(0, 8)
	glow.polygon = PackedVector2Array([
		Vector2(-20, 0), Vector2(20, 0), Vector2(12, 16), Vector2(-12, 16),
	])
	root.add_child(glow)


static func _build_interactable_markers(layer: Node2D, profile: EnvironmentVisualProfile) -> void:
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
	for index in range(4):
		var x_positions: Array[float] = [200.0, 640.0, 1020.0, 1460.0]
		var point := PointLight2D.new()
		point.name = "DistrictRitualLight_%d" % (index + 1)
		point.position = Vector2(x_positions[index], ground_y - 12)
		point.color = Color(0.78, 0.42, 0.24, 1.0)
		point.energy = 0.32
		point.texture_scale = 0.34
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
