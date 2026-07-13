extends Resource
class_name CorruptionVisualState

## Named visual corruption / narrative lighting state for a region.

enum State {
	NORMAL,
	VERMILITE_NEAR,
	RED_RESONANCE,
	MOL_KHAR_APPEARANCE,
}

@export var state: State = State.NORMAL
@export var state_name: String = "normal"
@export var description: String = ""
@export var lighting_profile: LightingProfile


static func state_to_string(value: State) -> String:
	match value:
		State.NORMAL:
			return "normal"
		State.VERMILITE_NEAR:
			return "vermilite_near"
		State.RED_RESONANCE:
			return "red_resonance"
		State.MOL_KHAR_APPEARANCE:
			return "mol_khar"
		_:
			return "unknown"
