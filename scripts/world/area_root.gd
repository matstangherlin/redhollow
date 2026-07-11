extends Node2D
class_name AreaRoot

const AREA_ROOT_GROUP := "area_root"

@export var area_id: StringName = &""
@export var area_display_name: String = "Area"
@export var camera_limits: Rect2 = Rect2(0.0, 0.0, 1400.0, 900.0)
@export var fall_recovery_y: float = 1320.0
@export var area_tint: Color = Color(0.42, 0.42, 0.44, 1.0)


func _ready() -> void:
	add_to_group(AREA_ROOT_GROUP)
	if area_id == &"":
		push_warning("AreaRoot is missing area_id on %s" % name)


func get_area_scene_path() -> String:
	return scene_file_path


func get_spawn_position(spawn_id: StringName) -> Vector2:
	var spawn_point := get_spawn_point(spawn_id)
	if spawn_point != null:
		return spawn_point.global_position

	push_warning("Spawn id '%s' not found in area '%s'. Using area origin." % [String(spawn_id), String(area_id)])
	return global_position


func get_spawn_point(spawn_id: StringName) -> AreaSpawnPoint:
	for node in get_spawn_points():
		if node.spawn_id == spawn_id:
			return node

	if spawn_id != &"default":
		return get_spawn_point(&"default")

	return null


func get_spawn_points() -> Array[AreaSpawnPoint]:
	var points: Array[AreaSpawnPoint] = []
	for node in find_children("*", "AreaSpawnPoint", true, false):
		if node is AreaSpawnPoint:
			points.append(node)
	return points


func get_exits() -> Array[AreaExit]:
	var exits: Array[AreaExit] = []
	for node in find_children("*", "AreaExit", true, false):
		if node is AreaExit:
			exits.append(node)
	return exits
