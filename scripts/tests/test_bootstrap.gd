extends Node

## Headless entry scene: loads one suite script after project autoloads initialize.


func _ready() -> void:
	var suite_path := _resolve_suite_path()
	if suite_path.is_empty():
		push_error("No suite path provided. Pass res://... after '--' on the command line.")
		get_tree().quit(1)
		return

	var autoload_failures := TestRuntimeContext.validate_autoloads(get_tree())
	if not autoload_failures.is_empty():
		for failure in autoload_failures:
			push_error(failure)
		get_tree().quit(1)
		return

	var script: Variant = load(suite_path)
	if script == null or not (script is GDScript):
		push_error("Failed to load suite script: %s" % suite_path)
		get_tree().quit(1)
		return

	var instance: Object = (script as GDScript).new()
	if instance == null or not (instance is HeadlessSuiteRunner):
		push_error("Suite must extend HeadlessSuiteRunner: %s" % suite_path)
		get_tree().quit(1)
		return

	add_child(instance as Node)


func _resolve_suite_path() -> String:
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		return String(user_args[0])

	var env_path := OS.get_environment("RH_TEST_SUITE")
	if not env_path.is_empty():
		return env_path

	return ""
