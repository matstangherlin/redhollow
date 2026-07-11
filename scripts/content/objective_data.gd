extends Resource
class_name ObjectiveData

## Objective template. Runtime states are tracked by ObjectiveTracker.

enum ObjectiveState {
	LOCKED,
	ACTIVE,
	COMPLETED,
}

@export var objective_id: StringName = &""
@export var order: int = 0
@export var title: String = ""
@export var text: String = ""
@export var complete_flags_any: PackedStringArray = []
@export var complete_flags_all: PackedStringArray = []


func to_dictionary() -> Dictionary:
	return {
		"id": String(objective_id),
		"order": order,
		"title": title,
		"text": text,
		"complete_flags_any": Array(complete_flags_any),
		"complete_flags_all": Array(complete_flags_all),
	}
