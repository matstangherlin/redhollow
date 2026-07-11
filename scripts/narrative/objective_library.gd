extends RefCounted
class_name ObjectiveLibrary

const DEFAULT_PATH := "res://data/narrative/chapter_zero_objectives.json"

var _objectives: Array[Dictionary] = []
var _loaded: bool = false


func load_from_file(path: String = DEFAULT_PATH) -> bool:
	_loaded = false
	_objectives.clear()

	if not FileAccess.file_exists(path):
		push_warning("ObjectiveLibrary: file not found %s" % path)
		return false

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("ObjectiveLibrary: invalid JSON at %s" % path)
		return false

	var root := parsed as Dictionary
	var entries: Array = root.get("objectives", [])
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		if not entry.has("id"):
			continue
		_objectives.append(entry.duplicate(true))

	_objectives.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	_loaded = true
	return true


func is_loaded() -> bool:
	return _loaded


func get_objectives() -> Array[Dictionary]:
	return _objectives.duplicate(true)
