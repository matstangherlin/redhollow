extends Resource
class_name AreaConnectionData

## Directed edge in the world area graph. Does not load scenes by itself.

@export var connection_id: StringName = &""
@export var from_area_id: StringName = &""
@export var to_area_id: StringName = &""
@export var from_exit_id: StringName = &""
@export var to_spawn_id: StringName = &"default"
@export var required_ability_id: StringName = &""
@export var required_flag: StringName = &""
@export var is_shortcut: bool = false
@export var is_secret_passage: bool = false
@export var is_blocked_display: bool = false
@export var is_playable_edge: bool = true
@export var display_label: String = ""


func is_available(progression: ProgressionComponent) -> bool:
	if not is_playable_edge:
		return false
	if required_ability_id != &"":
		if progression == null:
			return false
		if not progression.unlocked_abilities.has(String(required_ability_id)):
			return false
	if required_flag != &"":
		if progression == null:
			return false
		if not bool(progression.narrative_flags.get(String(required_flag), false)):
			return false
	return true


func get_block_reason(progression: ProgressionComponent) -> String:
	if not is_playable_edge:
		return "Área futura"
	if required_ability_id != &"":
		if progression == null or not progression.unlocked_abilities.has(String(required_ability_id)):
			return "Requer habilidade: %s" % String(required_ability_id)
	if required_flag != &"":
		if progression == null or not bool(progression.narrative_flags.get(String(required_flag), false)):
			return "Requer progresso"
	return ""
