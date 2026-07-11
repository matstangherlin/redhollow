extends Resource
class_name PlayerVisualProfile

## Data-only mapping from gameplay states/attacks to animation clip names.
## Does NOT define combat timing — AttackData remains authoritative.

enum VisualMode {
	PLACEHOLDER,
	PILOT,
	FINAL,
}

@export var profile_id: StringName = &"calder_default"
@export var visual_mode: VisualMode = VisualMode.PLACEHOLDER
@export var sprite_frames_path: String = ""
@export var use_procedural_pilot_frames: bool = true

## attack_id (String) -> animation name (String)
@export var attack_animation_map: Dictionary = {
	"calder_straight": "straight",
}

## Full production target list (documentation + validation helpers).
static var PRODUCTION_ANIMATION_IDS: PackedStringArray = PackedStringArray([
	"idle",
	"run",
	"turn",
	"jump_start",
	"jump_rise",
	"fall",
	"land",
	"straight",
	"body_hook",
	"red_knuckle",
	"dodge",
	"counter_window",
	"counter_attack",
	"taunt_01",
	"taunt_02",
	"hurt",
	"knockdown",
	"death",
	"respawn",
	"interact",
	"red_brand_charge",
	"red_brand_breaker",
])


func get_attack_animation(attack_id: StringName) -> StringName:
	var mapped: Variant = attack_animation_map.get(String(attack_id), "")
	if String(mapped).is_empty():
		return &""
	return StringName(String(mapped))


func is_pilot_profile() -> bool:
	return visual_mode == VisualMode.PILOT


func is_final_profile() -> bool:
	return visual_mode == VisualMode.FINAL


func uses_placeholder() -> bool:
	return visual_mode == VisualMode.PLACEHOLDER
