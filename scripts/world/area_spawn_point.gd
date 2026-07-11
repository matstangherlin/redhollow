extends Marker2D
class_name AreaSpawnPoint

const SPAWN_POINT_GROUP := "area_spawn_point"

@export var spawn_id: StringName = &"default"


func _ready() -> void:
	add_to_group(SPAWN_POINT_GROUP)
