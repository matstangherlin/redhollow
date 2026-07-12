@tool
extends EditorScript
class_name EnvironmentEditorHelper

## Editor utility: validate modular area and print missing asset report.
## Run via Editor > Run Script or call static methods from tests.


static func validate_scene(scene_path: String) -> Dictionary:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return {"passed": false, "failures": PackedStringArray(["Cannot load scene: %s" % scene_path])}

	var instance: Node = packed.instantiate()
	var report: Dictionary = {}
	if instance is ModularArea:
		report = EnvironmentKitValidator.validate_area(instance as ModularArea)
	else:
		report = {"passed": false, "failures": PackedStringArray(["Scene root is not ModularArea."])}

	instance.free()
	return report


static func print_report(report: Dictionary) -> void:
	print("=== Environment Kit Validation ===")
	print("Passed: %s" % str(report.get("passed", false)))
	for failure in report.get("failures", PackedStringArray()):
		print("FAIL: %s" % failure)
	for warning in report.get("warnings", PackedStringArray()):
		print("WARN: %s" % warning)
	var missing: PackedStringArray = report.get("missing_assets", PackedStringArray())
	print("Missing assets: %d" % missing.size())
	for path in missing:
		print("  - %s" % path)


func _run() -> void:
	var paths := [
		"res://scenes/environment/modular/kit_room_saloon_front.tscn",
		"res://scenes/environment/modular/kit_room_alley_corner.tscn",
	]
	for path in paths:
		print_report(validate_scene(path))
