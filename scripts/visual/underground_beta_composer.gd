extends RefCounted
class_name UndergroundBetaComposer

const Layout := preload("res://scripts/visual/underground_north_star_layout.gd")
const KitBridge := preload("res://scripts/visual/street_kit_visual_bridge.gd")
const Factory := preload("res://scripts/visual/underground_north_star_factory.gd")
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")

const LAYER_GAMEPLAY_GROUND := "Layer05_GameplayGround"
const LAYER_GAMEPLAY_STRUCTURES := "Layer06_GameplayStructures"
const LAYER_PROPS := "Layer07_Props"
const LAYER_INTERACTABLES := "Layer08_Interactables"
const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_FINALE := "Layer12_FinaleHooks"


static func compose(presentation: Node2D, profile: EnvironmentVisualProfile) -> Dictionary:
	var ground_y := Factory.ground_anchor_y(profile)
	var stats := {"zones": Layout.get_zones().size(), "decals": 0, "kit_slots": 0}

	var ground := presentation.get_node_or_null(LAYER_GAMEPLAY_GROUND) as Node2D
	var props := presentation.get_node_or_null(LAYER_PROPS) as Node2D
	var interactables := presentation.get_node_or_null(LAYER_INTERACTABLES) as Node2D
	var finale := presentation.get_node_or_null(LAYER_FINALE) as Node2D

	if ground != null:
		_build_zone_tints(ground, profile, ground_y)

	if props != null:
		stats["decals"] = _build_narrative_decals(props, ground_y)
		stats["kit_slots"] = KitBridge.spawn_kit_slots(props, Layout.get_kit_module_placements(ground_y))

	if interactables != null:
		_build_interactable_markers(interactables, profile)

	if finale != null:
		Factory.build_finale_visual_hooks(finale, profile)

	return stats


static func _build_zone_tints(layer: Node2D, profile: EnvironmentVisualProfile, ground_y: float) -> void:
	var tints: Dictionary = Layout.get_zone_ground_tints()
	for entry in Layout.get_zones():
		var zone: int = int(entry["id"])
		var tint: Color = tints.get(zone, Palette.STONE_GREY)
		var strip := Polygon2D.new()
		strip.name = "ZoneTint_%d" % int(entry["stage"])
		strip.color = tint.lightened(0.03)
		strip.modulate = Color(1, 1, 1, 0.24)
		strip.polygon = PackedVector2Array([
			Vector2(float(entry["x_min"]), ground_y + 2), Vector2(float(entry["x_max"]), ground_y + 2),
			Vector2(float(entry["x_max"]), ground_y + 16), Vector2(float(entry["x_min"]), ground_y + 16),
		])
		layer.add_child(strip)


static func _build_narrative_decals(props: Node2D, ground_y: float) -> int:
	var count := 0
	for entry in Layout.get_narrative_decals(ground_y):
		var root := Node2D.new()
		root.name = "Narrative_%s" % entry["id"]
		root.position = entry["pos"]
		props.add_child(root)
		count += 1
	return count


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


static func _ellipse_polygon(radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
