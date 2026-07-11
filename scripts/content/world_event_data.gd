extends Resource
class_name WorldEventData

## Narrative event with optional conditions. JSON events map to the same fields at runtime.

@export var event_id: StringName = &""
@export var sets_flags: PackedStringArray = []
@export var requires_flags_all: PackedStringArray = []
@export var requires_flags_any: PackedStringArray = []
@export var excludes_flags: PackedStringArray = []


func to_event_dictionary() -> Dictionary:
	return {
		"sets_flags": Array(sets_flags),
		"requires_flags_all": Array(requires_flags_all),
		"requires_flags_any": Array(requires_flags_any),
		"excludes_flags": Array(excludes_flags),
	}
