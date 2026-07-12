extends Resource
class_name AreaData

## Playable region metadata. Scene is loaded on demand — never the full world at once.

@export var area_id: StringName = &""
@export var display_name: String = ""
@export var chapter_id: StringName = &""
@export var scene_path: String = ""
@export var sort_order: int = 0
@export var checkpoint_ids: PackedStringArray = []

@export_group("World Graph")
@export var map_position: Vector2i = Vector2i.ZERO
@export var visual_category: StringName = &"street"
@export var is_graph_node: bool = true
@export var is_playable_in_build: bool = true
@export var primary_checkpoint_id: StringName = &""
@export var shortcut_ids: PackedStringArray = []
@export var secret_ids: PackedStringArray = []
@export var barrier_ids: PackedStringArray = []
@export var optional_completion_percent: float = -1.0


func get_scene() -> PackedScene:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return null
	return load(scene_path) as PackedScene


func is_valid() -> bool:
	return area_id != &"" and not scene_path.is_empty() and ResourceLoader.exists(scene_path)


func is_playable_in_graph() -> bool:
	if not is_graph_node:
		return false
	if not is_playable_in_build:
		return false
	return is_valid()
