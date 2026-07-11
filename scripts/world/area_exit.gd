extends Area2D
class_name AreaExit

signal exit_triggered(exit: AreaExit, body: Node)

const AREA_EXIT_GROUP := "area_exit"

enum TransitionType {
	INSTANT,
	FADE,
}

@export var exit_id: StringName = &""
@export var target_scene: String = ""
@export var target_spawn_id: StringName = &"default"
@export var transition_type: TransitionType = TransitionType.INSTANT
@export var required_ability_id: StringName = &""
@export var required_flag: StringName = &""
@export var one_shot: bool = false

var _has_triggered: bool = false
var _arena_blocked: bool = false


func _ready() -> void:
	add_to_group(AREA_EXIT_GROUP)
	body_entered.connect(_on_body_entered)
	monitoring = true


func set_arena_blocked(blocked: bool) -> void:
	_arena_blocked = blocked
	set_deferred("monitoring", not blocked)


func is_arena_blocked() -> bool:
	return _arena_blocked


func can_be_used(progression: ProgressionComponent = null) -> bool:
	if _arena_blocked:
		return false

	if _has_triggered and one_shot:
		return false

	if target_scene.is_empty():
		return false

	var registry := ContentRegistry.get_active()
	if registry != null and not registry.can_load_area_scene(target_scene):
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


func get_blocked_reason(progression: ProgressionComponent = null) -> String:
	if not can_be_used(progression):
		var registry := ContentRegistry.get_active()
		if registry != null and not target_scene.is_empty() and not registry.can_load_area_scene(target_scene):
			return "Area not available in this build"
		if required_ability_id != &"":
			return "Requires ability: %s" % String(required_ability_id)
		if required_flag != &"":
			return "Requires flag: %s" % String(required_flag)
		return "Exit unavailable"
	return ""


func _on_body_entered(body: Node) -> void:
	if _arena_blocked:
		return
	if not body.is_in_group("player"):
		return

	exit_triggered.emit(self, body)
