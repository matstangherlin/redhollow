extends Resource
class_name AreaData

## Playable region metadata. Scene is loaded on demand — never the full world at once.

@export var area_id: StringName = &""
@export var display_name: String = ""
@export var chapter_id: StringName = &""
@export var scene_path: String = ""
@export var sort_order: int = 0
@export var checkpoint_ids: PackedStringArray = []


func get_scene() -> PackedScene:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return null
	return load(scene_path) as PackedScene


func is_valid() -> bool:
	return area_id != &"" and not scene_path.is_empty() and ResourceLoader.exists(scene_path)
