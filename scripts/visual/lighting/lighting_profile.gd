extends Resource
class_name LightingProfile

## Per-state lighting and atmosphere tuning — presentation only.

@export var profile_id: StringName = &""
@export var display_name: String = ""

@export_group("Global")
@export var canvas_modulate: Color = Color(0.92, 0.78, 0.66, 1.0)
@export var environment_saturation: float = 1.0
@export var environment_value_scale: float = 1.0

@export_group("Directional Lights")
@export var key_light_color: Color = Color(0.95, 0.58, 0.28, 1.0)
@export var key_light_energy: float = 0.32
@export var fill_light_color: Color = Color(0.22, 0.16, 0.24, 1.0)
@export var fill_light_energy: float = 0.12

@export_group("Point Lights")
@export var lantern_color: Color = Color(1.0, 0.68, 0.28, 1.0)
@export var lantern_energy: float = 0.85
@export var lantern_energy_scale: float = 1.0
@export var window_glow_color: Color = Color(0.95, 0.55, 0.22, 1.0)
@export var window_glow_energy: float = 0.35
@export var vermilite_accent_color: Color = Color(0.95, 0.2, 0.12, 1.0)
@export var vermilite_accent_energy: float = 0.28

@export_group("Atmosphere")
@export var dust_alpha_scale: float = 1.0
@export var vermilite_mote_alpha_scale: float = 1.0
@export var particle_amount_scale: float = 1.0

@export_group("Mol-Khar / Narrative")
@export var vignette_strength: float = 0.0
@export var silhouette_strength: float = 0.0
@export var distortion_strength: float = 0.0
@export var chromatic_aberration_strength: float = 0.0
@export var ambient_audio_event: StringName = &""


func apply_accessibility(scale: Dictionary) -> LightingProfile:
	var copy := duplicate(true) as LightingProfile
	var flash_scale: float = float(scale.get("flash_scale", 1.0))
	var particle_scale: float = float(scale.get("particle_scale", 1.0))
	var distortion_scale: float = float(scale.get("distortion_scale", 1.0))
	var contrast_scale: float = float(scale.get("contrast_scale", 1.0))

	copy.dust_alpha_scale *= particle_scale
	copy.vermilite_mote_alpha_scale *= flash_scale * particle_scale
	copy.particle_amount_scale *= particle_scale
	copy.distortion_strength *= distortion_scale
	copy.chromatic_aberration_strength *= distortion_scale
	copy.vignette_strength = lerpf(copy.vignette_strength, copy.vignette_strength * 0.65, 1.0 - contrast_scale)
	copy.vermilite_accent_energy *= lerpf(1.0, 0.72, 1.0 - flash_scale)
	return copy
