extends Node
class_name HeadlessSuiteRunner

## Base node for headless suites executed through test_bootstrap.tscn (--main-scene).
## Subclasses override _run_suite() and use get_tree() instead of self as SceneTree.

var root: Window:
	get:
		return get_tree().root


var paused: bool:
	get:
		return get_tree().paused
	set(value):
		get_tree().paused = value


func _ready() -> void:
	call_deferred("_begin")


func _begin() -> void:
	await _run_suite()


func _run_suite() -> void:
	push_error("HeadlessSuiteRunner._run_suite() must be overridden.")
	get_tree().quit(1)
