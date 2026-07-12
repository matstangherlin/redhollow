extends RefCounted
class_name WorldMapState

## Serializable discovery / visit state for the world map. No node references.

var discovered_areas: Array[String] = []
var visited_areas: Array[String] = []
var found_secrets: Array[String] = []
var unlocked_shortcuts: Array[String] = []
var known_barriers: Array[String] = []
var current_area_id: StringName = &""
var objective_area_id: StringName = &""


func export_dict() -> Dictionary:
	return {
		"discovered_areas": discovered_areas.duplicate(),
		"visited_areas": visited_areas.duplicate(),
		"found_secrets": found_secrets.duplicate(),
		"unlocked_shortcuts": unlocked_shortcuts.duplicate(),
		"known_barriers": known_barriers.duplicate(),
		"current_area_id": String(current_area_id),
		"objective_area_id": String(objective_area_id),
	}


func import_dict(data: Dictionary) -> void:
	discovered_areas = _to_string_array(data.get("discovered_areas", []))
	visited_areas = _to_string_array(data.get("visited_areas", []))
	found_secrets = _to_string_array(data.get("found_secrets", []))
	unlocked_shortcuts = _to_string_array(data.get("unlocked_shortcuts", []))
	known_barriers = _to_string_array(data.get("known_barriers", []))
	current_area_id = StringName(String(data.get("current_area_id", "")))
	objective_area_id = StringName(String(data.get("objective_area_id", "")))


func reset() -> void:
	discovered_areas.clear()
	visited_areas.clear()
	found_secrets.clear()
	unlocked_shortcuts.clear()
	known_barriers.clear()
	current_area_id = &""
	objective_area_id = &""


func is_discovered(area_id: StringName) -> bool:
	return discovered_areas.has(String(area_id))


func is_visited(area_id: StringName) -> bool:
	return visited_areas.has(String(area_id))


func mark_discovered(area_id: StringName) -> void:
	var key := String(area_id)
	if key.is_empty() or discovered_areas.has(key):
		return
	discovered_areas.append(key)


func mark_visited(area_id: StringName) -> void:
	var key := String(area_id)
	if key.is_empty():
		return
	mark_discovered(area_id)
	if not visited_areas.has(key):
		visited_areas.append(key)


func mark_secret(secret_id: StringName) -> void:
	var key := String(secret_id)
	if key.is_empty() or found_secrets.has(key):
		return
	found_secrets.append(key)


func mark_shortcut(shortcut_id: StringName) -> void:
	var key := String(shortcut_id)
	if key.is_empty() or unlocked_shortcuts.has(key):
		return
	unlocked_shortcuts.append(key)


func mark_barrier(barrier_id: StringName) -> void:
	var key := String(barrier_id)
	if key.is_empty() or known_barriers.has(key):
		return
	known_barriers.append(key)


static func _to_string_array(raw_value: Variant) -> Array[String]:
	var values: Array[String] = []
	if typeof(raw_value) != TYPE_ARRAY:
		return values
	for entry in raw_value as Array:
		if typeof(entry) == TYPE_STRING:
			values.append(entry)
	return values
