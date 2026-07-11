extends RefCounted
class_name ObjectiveTracker

signal objective_changed(objective_id: String, title: String, text: String)
signal all_objectives_completed

var _library: ObjectiveLibrary = ObjectiveLibrary.new()
var _current_index: int = 0


func load_objectives(path: String = ObjectiveLibrary.DEFAULT_PATH) -> bool:
	return _library.load_from_file(path)


func refresh_from_flags(flags: Dictionary) -> void:
	if not _library.is_loaded():
		return

	var objectives := _library.get_objectives()
	if objectives.is_empty():
		return

	while _current_index < objectives.size():
		var objective: Dictionary = objectives[_current_index]
		if _is_objective_complete(objective, flags):
			_current_index += 1
			continue
		objective_changed.emit(
			String(objective.get("id", "")),
			String(objective.get("title", "")),
			String(objective.get("text", ""))
		)
		return

	objective_changed.emit("", "Capítulo Zero concluído", "Red Hollow aguarda além desta passagem.")
	all_objectives_completed.emit()


func _is_objective_complete(objective: Dictionary, flags: Dictionary) -> bool:
	var any_flags: Array = objective.get("complete_flags_any", [])
	if not any_flags.is_empty():
		for flag_variant in any_flags:
			if bool(flags.get(String(flag_variant), false)):
				return true
		return false

	var all_flags: Array = objective.get("complete_flags_all", [])
	if not all_flags.is_empty():
		for flag_variant in all_flags:
			if not bool(flags.get(String(flag_variant), false)):
				return false
		return true

	return false
