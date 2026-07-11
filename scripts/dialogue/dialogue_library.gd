extends RefCounted
class_name DialogueLibrary

const REQUIRED_DIALOGUE_FIELDS := ["dialogue_id", "speaker", "lines"]

var locale: String = ""
var version: int = 0
var _dialogues: Dictionary = {}
var _load_error: String = ""


func get_load_error() -> String:
	return _load_error


func is_loaded() -> bool:
	return not _dialogues.is_empty()


func load_from_file(path: String) -> bool:
	_dialogues.clear()
	locale = ""
	version = 0
	_load_error = ""

	if not FileAccess.file_exists(path):
		_load_error = "Dialogue file not found: %s" % path
		push_warning(_load_error)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_error = "Failed to open dialogue file: %s (error %s)" % [path, error_string(FileAccess.get_open_error())]
		push_warning(_load_error)
		return false

	var raw_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null:
		_load_error = "Invalid JSON in dialogue file: %s" % path
		push_warning(_load_error)
		return false

	if typeof(parsed) != TYPE_DICTIONARY:
		_load_error = "Dialogue root must be a JSON object."
		push_warning(_load_error)
		return false

	return _import_root(parsed as Dictionary, path)


func get_dialogue(dialogue_id: StringName) -> Dictionary:
	if dialogue_id == &"":
		return {}

	if not _dialogues.has(dialogue_id):
		push_warning("Dialogue id not found: %s" % String(dialogue_id))
		return {}

	return (_dialogues[dialogue_id] as Dictionary).duplicate(true)


func has_dialogue(dialogue_id: StringName) -> bool:
	return dialogue_id != &"" and _dialogues.has(dialogue_id)


func get_dialogue_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for dialogue_id in _dialogues.keys():
		ids.append(StringName(dialogue_id))
	return ids


func _import_root(root: Dictionary, source_path: String) -> bool:
	version = int(root.get("version", 0))
	locale = String(root.get("locale", ""))

	var dialogues_variant: Variant = root.get("dialogues")
	if typeof(dialogues_variant) != TYPE_DICTIONARY:
		_load_error = "Missing or invalid 'dialogues' object in %s" % source_path
		push_warning(_load_error)
		return false

	var dialogues := dialogues_variant as Dictionary
	for key in dialogues.keys():
		var entry_variant: Variant = dialogues[key]
		if typeof(entry_variant) != TYPE_DICTIONARY:
			push_warning("Skipping invalid dialogue entry for key '%s' in %s" % [String(key), source_path])
			continue

		var normalized := _normalize_dialogue_entry(StringName(key), entry_variant as Dictionary)
		if normalized.is_empty():
			continue

		var entry_id := normalized["dialogue_id"] as StringName
		if _dialogues.has(entry_id):
			push_warning("Duplicate dialogue id '%s' in %s. Keeping the first entry." % [String(entry_id), source_path])
			continue

		_dialogues[entry_id] = normalized

	if _dialogues.is_empty():
		_load_error = "No valid dialogues found in %s" % source_path
		push_warning(_load_error)
		return false

	return true


func _normalize_dialogue_entry(fallback_id: StringName, raw_entry: Dictionary) -> Dictionary:
	for field_name in REQUIRED_DIALOGUE_FIELDS:
		if not raw_entry.has(field_name):
			push_warning("Dialogue '%s' is missing required field '%s'." % [String(fallback_id), field_name])
			return {}

	var dialogue_id := StringName(String(raw_entry.get("dialogue_id", String(fallback_id))))
	var speaker := String(raw_entry.get("speaker", "")).strip_edges()
	var lines := _normalize_lines(raw_entry.get("lines"))
	if speaker.is_empty():
		push_warning("Dialogue '%s' has an empty speaker." % String(dialogue_id))
		return {}
	if lines.is_empty():
		push_warning("Dialogue '%s' has no valid lines." % String(dialogue_id))
		return {}

	return {
		"dialogue_id": dialogue_id,
		"speaker": speaker,
		"lines": lines,
		"portrait": _normalize_optional_string(raw_entry.get("portrait")),
		"actions_on_start": _normalize_actions(raw_entry.get("actions_on_start")),
		"actions_on_end": _normalize_actions(raw_entry.get("actions_on_end")),
		"conditions": _normalize_conditions(raw_entry.get("conditions")),
		"choices": _normalize_choices(raw_entry.get("choices")),
	}


func _normalize_lines(raw_lines: Variant) -> PackedStringArray:
	var lines := PackedStringArray()
	if typeof(raw_lines) != TYPE_ARRAY:
		return lines

	for line_variant in raw_lines as Array:
		if typeof(line_variant) != TYPE_STRING:
			continue
		var line := String(line_variant).strip_edges()
		if not line.is_empty():
			lines.append(line)

	return lines


func _normalize_optional_string(value: Variant) -> String:
	if value == null:
		return ""
	if typeof(value) != TYPE_STRING:
		return ""
	return String(value).strip_edges()


func _normalize_actions(raw_actions: Variant) -> Array:
	var actions: Array = []
	if typeof(raw_actions) != TYPE_ARRAY:
		return actions

	for action_variant in raw_actions as Array:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		actions.append((action_variant as Dictionary).duplicate(true))

	return actions


func _normalize_conditions(raw_conditions: Variant) -> Dictionary:
	if typeof(raw_conditions) != TYPE_DICTIONARY:
		return {}
	return (raw_conditions as Dictionary).duplicate(true)


func _normalize_choices(raw_choices: Variant) -> Array:
	var choices: Array = []
	if typeof(raw_choices) != TYPE_ARRAY:
		return choices

	for choice_variant in raw_choices as Array:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			continue
		choices.append((choice_variant as Dictionary).duplicate(true))

	return choices
