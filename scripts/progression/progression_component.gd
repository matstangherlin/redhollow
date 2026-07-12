extends Node
class_name ProgressionComponent

signal progression_changed(property: StringName, value: Variant)

const PROGRESSION_GROUP := "progression_component"

@export var can_break_red_barriers: bool = true

var active_checkpoint_id: StringName = &""
var unlocked_abilities: Array[String] = []
var narrative_flags: Dictionary = {}
var activated_checkpoints: Array[String] = []
var persistent_settings: Dictionary = {}
var world_map_state: WorldMapState = WorldMapState.new()


func _ready() -> void:
	add_to_group(PROGRESSION_GROUP)


func can_break_barriers() -> bool:
	return can_break_red_barriers


func set_can_break_red_barriers(is_enabled: bool) -> void:
	if can_break_red_barriers == is_enabled:
		return

	can_break_red_barriers = is_enabled
	progression_changed.emit(&"can_break_red_barriers", is_enabled)


func register_checkpoint_activation(checkpoint_id: StringName) -> void:
	if checkpoint_id == &"":
		return

	active_checkpoint_id = checkpoint_id
	var checkpoint_key := String(checkpoint_id)
	if not activated_checkpoints.has(checkpoint_key):
		activated_checkpoints.append(checkpoint_key)

	progression_changed.emit(&"active_checkpoint_id", checkpoint_id)


func set_narrative_flag(flag_id: StringName, value: Variant = true) -> void:
	narrative_flags[String(flag_id)] = value
	progression_changed.emit(&"narrative_flags", narrative_flags.duplicate())


func unlock_ability(ability_id: StringName) -> void:
	var ability_key := String(ability_id)
	if ability_key.is_empty() or unlocked_abilities.has(ability_key):
		return

	unlocked_abilities.append(ability_key)
	progression_changed.emit(&"unlocked_abilities", unlocked_abilities.duplicate())


func export_save_state() -> Dictionary:
	return {
		"active_checkpoint_id": String(active_checkpoint_id),
		"unlocked_abilities": unlocked_abilities.duplicate(),
		"narrative_flags": narrative_flags.duplicate(),
		"activated_checkpoints": activated_checkpoints.duplicate(),
		"settings": persistent_settings.duplicate(),
		"can_break_red_barriers": can_break_red_barriers,
		"world_map": world_map_state.export_dict(),
	}


func reset_for_demo() -> void:
	active_checkpoint_id = &""
	unlocked_abilities.clear()
	narrative_flags.clear()
	activated_checkpoints.clear()
	persistent_settings.clear()
	can_break_red_barriers = true
	world_map_state.reset()
	progression_changed.emit(&"reset_for_demo", true)


func import_save_state(state: Dictionary) -> void:
	active_checkpoint_id = StringName(String(state.get("active_checkpoint_id", "")))
	unlocked_abilities = _to_string_array(state.get("unlocked_abilities", []))
	narrative_flags = _duplicate_dictionary(state.get("narrative_flags", {}))
	activated_checkpoints = _to_string_array(state.get("activated_checkpoints", []))
	persistent_settings = _duplicate_dictionary(state.get("settings", {}))

	if state.has("can_break_red_barriers"):
		can_break_red_barriers = bool(state.get("can_break_red_barriers"))

	world_map_state.import_dict(state.get("world_map", {}))

	progression_changed.emit(&"import_save_state", state)


func _to_string_array(raw_value: Variant) -> Array[String]:
	var values: Array[String] = []
	if typeof(raw_value) != TYPE_ARRAY:
		return values

	for entry in raw_value as Array:
		if typeof(entry) == TYPE_STRING:
			values.append(entry)

	return values


func _duplicate_dictionary(raw_value: Variant) -> Dictionary:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}
	return (raw_value as Dictionary).duplicate(true)
