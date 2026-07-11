extends RefCounted
class_name FeedbackSettingsAccess

## Runtime settings access without compile-time autoload dependency.


static func get_manager() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not (tree is SceneTree):
		return null
	return (tree as SceneTree).root.get_node_or_null("SettingsManager")


static func get_screen_shake_multiplier() -> float:
	var manager := get_manager()
	if manager != null and manager.has_method("get_screen_shake_multiplier"):
		return float(manager.call("get_screen_shake_multiplier"))
	return 1.0


static func is_reduced_flashes_enabled() -> bool:
	var manager := get_manager()
	if manager != null and manager.has_method("is_reduced_flashes_enabled"):
		return bool(manager.call("is_reduced_flashes_enabled"))
	return false


static func get_telegraph_contrast_multiplier() -> float:
	var manager := get_manager()
	if manager != null and manager.has_method("get_telegraph_contrast_multiplier"):
		return float(manager.call("get_telegraph_contrast_multiplier"))
	return 1.0


static func apply_audio() -> void:
	var manager := get_manager()
	if manager != null and manager.has_method("apply_audio"):
		manager.call("apply_audio")
