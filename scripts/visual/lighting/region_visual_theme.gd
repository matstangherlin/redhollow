extends Resource
class_name RegionVisualTheme

## Region-wide palette + lighting / corruption states. Gameplay collision unaffected.
## Distinct from EnvironmentRegionTheme (kit inheritance stubs under scripts/environment/).

@export var theme_id: StringName = &""
@export var region_id: StringName = &""
@export var display_name: String = ""
@export var default_state: CorruptionVisualState.State = CorruptionVisualState.State.NORMAL
@export var transition_duration: float = 0.85

@export var normal_state: CorruptionVisualState
@export var vermilite_near_state: CorruptionVisualState
@export var red_resonance_state: CorruptionVisualState
@export var mol_khar_state: CorruptionVisualState


func get_state_resource(state: CorruptionVisualState.State) -> CorruptionVisualState:
	match state:
		CorruptionVisualState.State.VERMILITE_NEAR:
			return vermilite_near_state
		CorruptionVisualState.State.RED_RESONANCE:
			return red_resonance_state
		CorruptionVisualState.State.MOL_KHAR_APPEARANCE:
			return mol_khar_state
		_:
			return normal_state


func get_lighting_profile(state: CorruptionVisualState.State) -> LightingProfile:
	var state_resource := get_state_resource(state)
	if state_resource != null and state_resource.lighting_profile != null:
		return state_resource.lighting_profile
	return null
