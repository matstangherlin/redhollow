extends RefCounted
class_name EnvironmentKitValidator

## Validates modular areas: layers, collision separation, missing assets.


static func validate_area(area: ModularArea) -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()

	if area == null:
		failures.append("Area is null.")
		return _report(failures, warnings, [])

	_validate_layer_folders(area, failures)
	_validate_area_contract(area, failures)
	_validate_collision_separation(area, failures, warnings)
	_validate_module_instances(area, warnings)

	var kit := area.get_environment_kit()
	var missing_assets: PackedStringArray = []
	if kit != null:
		missing_assets = find_missing_assets(kit)

	return _report(failures, warnings, missing_assets)


static func find_missing_assets(kit: EnvironmentKit) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	if kit == null:
		return missing

	kit.ensure_built_in()
	for path in kit.list_expected_asset_paths():
		if not path.is_empty() and not ResourceLoader.exists(path):
			missing.append(path)

	var catalog := PropCatalog.new()
	catalog.ensure_built_in()
	for entry in catalog.get_scene_required_modules():
		if not entry.scene_path.is_empty() and not ResourceLoader.exists(entry.scene_path):
			missing.append(entry.scene_path)

	return missing


static func _validate_layer_folders(area: ModularArea, failures: PackedStringArray) -> void:
	var root := area.get_node_or_null("ModularLayers")
	if root == null:
		failures.append("ModularLayers root missing.")
		return

	for folder_name in EnvironmentLayerCategory.LAYER_FOLDER_NAMES:
		if root.get_node_or_null(folder_name) == null:
			failures.append("Missing layer folder: %s." % folder_name)


static func _validate_area_contract(area: ModularArea, failures: PackedStringArray) -> void:
	if area.get_node_or_null("Solids") == null:
		failures.append("Area missing Solids folder (AreaRoot contract).")
	if area.get_node_or_null("Spawns") == null:
		failures.append("Area missing Spawns folder.")
	if area.get_node_or_null("Exits") == null:
		failures.append("Area missing Exits folder.")


static func _validate_collision_separation(
	area: ModularArea,
	failures: PackedStringArray,
	warnings: PackedStringArray
) -> void:
	var visual := area.get_node_or_null("ModularLayers/LayerVisual")
	if visual == null:
		return

	for child in visual.get_children():
		if child is StaticBody2D or child is CollisionShape2D:
			failures.append("Collision node found inside LayerVisual: %s." % child.name)

	var collision := area.get_node_or_null("ModularLayers/LayerCollision")
	if collision != null and collision.get_child_count() == 0:
		warnings.append("LayerCollision is empty — verify Solids or module collision.")


static func _validate_module_instances(area: ModularArea, warnings: PackedStringArray) -> void:
	var kit := area.get_environment_kit()
	var count := 0
	for node in area.find_children("*", "EnvironmentModuleInstance", true, false):
		if node is EnvironmentModuleInstance:
			count += 1
			var instance := node as EnvironmentModuleInstance
			if kit != null and kit.get_module(instance.module_id) == null:
				warnings.append("Unknown module_id on instance: %s." % String(instance.module_id))

	if count == 0:
		warnings.append("No EnvironmentModuleInstance markers found.")


static func _report(
	failures: PackedStringArray,
	warnings: PackedStringArray,
	missing_assets: PackedStringArray
) -> Dictionary:
	return {
		"passed": failures.is_empty(),
		"failures": failures,
		"warnings": warnings,
		"missing_assets": missing_assets,
		"missing_asset_count": missing_assets.size(),
	}
