extends Resource
class_name EnemyVisualProfile

## Data-only mapping from enemy gameplay states to animation clip names.
## Does NOT define combat timing — AttackData remains authoritative.

enum VisualMode {
	PLACEHOLDER,
	PILOT,
	FINAL,
}

@export var profile_id: StringName = &"enemy_default"
@export var enemy_id: StringName = &""
@export var visual_mode: VisualMode = VisualMode.PILOT
@export var sprite_frames_path: String = ""
@export var use_procedural_pilot_frames: bool = true

## BrawlerState name (String) -> animation clip name (String)
@export var state_animation_map: Dictionary = {
	"idle": "idle",
	"patrol": "patrol",
	"alert": "alert",
	"approach": "approach",
	"attack_startup": "attack_startup",
	"attack_active": "attack_active",
	"attack_recovery": "attack_recovery",
	"hurt": "hurt",
	"heavy_hurt": "heavy_hurt",
	"knocked_back": "knocked_back",
	"stagger": "stagger",
	"dead": "death",
}

## attack_phase (String) during ATTACK/RECOVERY -> clip override
@export var attack_phase_map: Dictionary = {
	"startup": "attack_startup",
	"active": "attack_active",
	"recovery": "attack_recovery",
}


func get_state_animation(state_name: String) -> StringName:
	var mapped: Variant = state_animation_map.get(state_name, "")
	if String(mapped).is_empty():
		return &""
	return StringName(String(mapped))


func get_attack_phase_animation(phase_name: String) -> StringName:
	var mapped: Variant = attack_phase_map.get(phase_name, "")
	if String(mapped).is_empty():
		return &""
	return StringName(String(mapped))


func is_pilot_profile() -> bool:
	return visual_mode == VisualMode.PILOT


func is_final_profile() -> bool:
	return visual_mode == VisualMode.FINAL


func uses_placeholder() -> bool:
	return visual_mode == VisualMode.PLACEHOLDER
