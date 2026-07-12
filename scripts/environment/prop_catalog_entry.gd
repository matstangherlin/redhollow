extends Resource
class_name PropCatalogEntry

@export var entry_id: StringName = &""
@export var display_name: String = ""
@export var module_id: StringName = &""
@export var scene_path: String = ""
@export var category: EnvironmentLayerCategory.Category = EnvironmentLayerCategory.Category.DECORATION
@export var requires_scene: bool = true
@export var notes: String = ""


func needs_scene() -> bool:
	return requires_scene and not scene_path.is_empty()
