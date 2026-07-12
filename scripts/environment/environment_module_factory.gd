extends RefCounted
class_name EnvironmentModuleFactory

const DEFAULT_GROUND_Y := 876.0


static func spawn_module(
	instance: EnvironmentModuleInstance,
	module: EnvironmentModuleDef,
	kit: EnvironmentKit,
	layers_root: Node2D
) -> void:
	var should_spawn_visual := instance.spawn_visual
	if module.kind == EnvironmentModuleDef.ModuleKind.PROP_SCENE and not module.prop_scene_path.is_empty():
		should_spawn_visual = false

	if should_spawn_visual:
		_spawn_visual(instance, module, layers_root)
	if instance.spawn_collision and module.has_collision:
		_spawn_collision(instance, module, layers_root)
	if not module.prop_scene_path.is_empty() and module.kind != EnvironmentModuleDef.ModuleKind.TILE_STRIP:
		_spawn_prop_scene(instance, module, layers_root)


static func _spawn_visual(
	instance: EnvironmentModuleInstance,
	module: EnvironmentModuleDef,
	layers_root: Node2D
) -> void:
	var layer := _get_layer(layers_root, module.category)
	if layer == null:
		return

	if module.kind == EnvironmentModuleDef.ModuleKind.GAMEPLAY_PREFAB:
		return

	var slot := ArtPlaceholderSlot.create(
		String(module.module_id),
		module.module_id,
		module.expected_asset_path,
		module.footprint_px,
		_color_for_category(module.category),
		instance.position,
		false
	)
	if instance.flip_h:
		slot.scale.x = -1.0
	layer.add_child(slot)


static func _spawn_collision(
	instance: EnvironmentModuleInstance,
	module: EnvironmentModuleDef,
	layers_root: Node2D
) -> void:
	var layer := _get_layer(layers_root, EnvironmentLayerCategory.Category.COLLISION)
	if layer == null:
		return

	var body := StaticBody2D.new()
	body.name = "Collision_%s" % module.module_id
	body.position = instance.position

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = module.footprint_px
	shape.shape = rect
	shape.position = Vector2(0, -module.footprint_px.y * 0.5)
	body.add_child(shape)
	layer.add_child(body)


static func _spawn_prop_scene(
	instance: EnvironmentModuleInstance,
	module: EnvironmentModuleDef,
	layers_root: Node2D
) -> void:
	if not ResourceLoader.exists(module.prop_scene_path):
		return

	var layer := _get_layer(layers_root, module.category)
	if layer == null:
		layer = _get_layer(layers_root, EnvironmentLayerCategory.Category.DECORATION)
	if layer == null:
		return

	var scene: PackedScene = load(module.prop_scene_path) as PackedScene
	if scene == null:
		return

	var prop: Node2D = scene.instantiate() as Node2D
	prop.name = String(module.module_id)
	prop.position = instance.position
	if instance.flip_h:
		prop.scale.x = -1.0
	layer.add_child(prop)


static func _get_layer(layers_root: Node2D, category: EnvironmentLayerCategory.Category) -> Node2D:
	var folder := EnvironmentLayerCategory.folder_for(category)
	return layers_root.get_node_or_null(folder) as Node2D


static func _color_for_category(category: EnvironmentLayerCategory.Category) -> Color:
	match category:
		EnvironmentLayerCategory.Category.COLLISION:
			return Color(0.34, 0.26, 0.2, 0.85)
		EnvironmentLayerCategory.Category.LIGHTING:
			return Color(0.92, 0.62, 0.22, 0.9)
		EnvironmentLayerCategory.Category.INTERACTION:
			return Color(0.55, 0.42, 0.3, 0.9)
		EnvironmentLayerCategory.Category.GAMEPLAY:
			return Color(0.72, 0.18, 0.12, 0.9)
		EnvironmentLayerCategory.Category.FOREGROUND:
			return Color(0.2, 0.16, 0.14, 0.55)
		EnvironmentLayerCategory.Category.BACKGROUND:
			return Color(0.28, 0.22, 0.2, 0.75)
		_:
			return Color(0.48, 0.36, 0.28, 0.88)
