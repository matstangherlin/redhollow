extends RefCounted
class_name EnvironmentKitAssembler

## Ensures modular layer folders and spawns module instances for an area.


static func ensure_layer_folders(area: ModularArea) -> Node2D:
	var root := area.get_node_or_null("ModularLayers") as Node2D
	if root == null:
		root = Node2D.new()
		root.name = "ModularLayers"
		area.add_child(root)
		area.move_child(root, 0)

	for index in range(EnvironmentLayerCategory.LAYER_FOLDER_NAMES.size()):
		var folder_name: String = EnvironmentLayerCategory.LAYER_FOLDER_NAMES[index]
		if root.get_node_or_null(folder_name) == null:
			var layer := Node2D.new()
			layer.name = folder_name
			layer.z_index = _z_for_category(index)
			root.add_child(layer)

	return root


static func assemble_modules(area: ModularArea) -> void:
	if area.environment_kit == null:
		return

	area.environment_kit.ensure_built_in()
	var layers_root := ensure_layer_folders(area)

	for node in area.find_children("*", "EnvironmentModuleInstance", true, false):
		if node is EnvironmentModuleInstance:
			var instance := node as EnvironmentModuleInstance
			instance.spawn_from_kit(area.environment_kit, layers_root)


static func _z_for_category(category_index: int) -> int:
	match category_index:
		EnvironmentLayerCategory.Category.BACKGROUND:
			return -80
		EnvironmentLayerCategory.Category.VISUAL:
			return 0
		EnvironmentLayerCategory.Category.DECORATION:
			return 10
		EnvironmentLayerCategory.Category.COLLISION:
			return 0
		EnvironmentLayerCategory.Category.LIGHTING:
			return 20
		EnvironmentLayerCategory.Category.FOREGROUND:
			return 40
		EnvironmentLayerCategory.Category.INTERACTION:
			return 15
		_:
			return 0
