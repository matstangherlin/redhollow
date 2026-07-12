extends RefCounted
class_name TestRuntimeContext

## Validates project autoloads in a normal SceneTree (--main-scene bootstrap).

const REQUIRED_AUTOLOADS: Array[String] = [
	"SettingsManager",
	"GameBootState",
	"InputDeviceManager",
	"InputSetup",
]

const AUTOLOAD_PATHS: Dictionary = {
	"SettingsManager": "res://scripts/settings/settings_manager.gd",
	"GameBootState": "res://scripts/product/game_boot_state.gd",
	"InputDeviceManager": "res://scripts/input/input_device_manager.gd",
	"InputSetup": "res://scripts/input/input_setup.gd",
}


static func validate_autoloads(tree: SceneTree) -> PackedStringArray:
	var failures: PackedStringArray = PackedStringArray()
	if tree == null or tree.root == null:
		failures.append("SceneTree root unavailable for autoload validation.")
		return failures

	for autoload_name in REQUIRED_AUTOLOADS:
		var node: Node = tree.root.get_node_or_null(NodePath(autoload_name))
		if node == null:
			failures.append(
				"Autoload missing at runtime: %s (run suites via test_bootstrap.tscn)." % autoload_name
			)
		elif not node.is_inside_tree():
			failures.append("Autoload not inside tree: %s." % autoload_name)
	return failures


static func get_autoload_or_null(tree: SceneTree, autoload_name: StringName) -> Node:
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(NodePath(String(autoload_name)))
