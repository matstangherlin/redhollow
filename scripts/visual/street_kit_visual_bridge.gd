extends RefCounted
class_name StreetKitVisualBridge

const PlaceholderSlot := preload("res://scripts/visual/art_placeholder_slot.gd")

## Visual-only kit module slots on North Star presentation layers (no collision).


static func spawn_kit_slots(layer: Node2D, placements: Array[Dictionary]) -> int:
	var count := 0
	for entry in placements:
		var module_id: StringName = entry.get("module", &"")
		var pos: Vector2 = entry.get("pos", Vector2.ZERO)
		var path: String = String(entry.get("path", ""))
		var size: Vector2 = entry.get("size", Vector2(32, 32))
		if path.is_empty():
			continue
		var slot := PlaceholderSlot.create(
			"Kit_%s_%d" % [String(module_id), count],
			module_id,
			path,
			size,
			Color(1, 1, 1, 0.0),
			pos,
			false
		)
		layer.add_child(slot)
		count += 1
	return count
