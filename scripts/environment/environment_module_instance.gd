extends Node2D
class_name EnvironmentModuleInstance

## Editor-placed marker for a kit module. Spawns visual/collision in the correct layer.

@export var kit_id: StringName = &"chapter_zero_street"
@export var module_id: StringName = &""
@export var flip_h: bool = false
@export var spawn_collision: bool = true
@export var spawn_visual: bool = true

var _spawned: bool = false


func spawn_from_kit(kit: EnvironmentKit, layers_root: Node2D) -> void:
	if _spawned or kit == null or layers_root == null:
		return

	var module := kit.get_module(module_id)
	if module == null:
		push_warning("EnvironmentModuleInstance: unknown module '%s'." % String(module_id))
		return

	EnvironmentModuleFactory.spawn_module(self, module, kit, layers_root)
	_spawned = true
