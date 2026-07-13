extends Resource
class_name CombatFeedbackProfile

## Per-attack combat presentation profile. Gameplay timing stays in AttackData.

enum ImpactTier {
	LIGHT,
	MEDIUM,
	HEAVY,
	BREAKER,
	COUNTER,
	SPECIAL,
}

enum CameraEffect {
	NONE,
	PUNCH_ZOOM,
}

@export var profile_id: StringName = &""
@export var attack_id: StringName = &""
@export var impact_tier: ImpactTier = ImpactTier.LIGHT

## Mirrors AttackData hitstop for documentation — gameplay hitstop remains on AttackData.
@export var attacker_hitstop: float = 0.0
@export var target_hitstop: float = 0.0

@export var shake_intensity: float = 0.0
@export var shake_duration: float = 0.0
@export var camera_effect: CameraEffect = CameraEffect.NONE
@export var zoom_amount: float = 0.0
@export var zoom_duration: float = 0.10

@export var vfx_kind: StringName = &"hit_normal"
@export var particle_count: int = 6
@export var particle_lifetime: float = 0.18
@export var impact_color: Color = Color(0.95, 0.88, 0.72, 0.85)
@export var flash_strength: float = 0.18
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@export var swing_trail_enabled: bool = false
@export var swing_trail_particles: int = 4
@export var swing_trail_on_active: bool = true
@export var shockwave_enabled: bool = false
@export var lateral_impact_bias: float = 0.0

@export var sfx_id: StringName = &""
@export var sfx_volume_scale: float = 1.0
@export var pitch_min: float = 0.98
@export var pitch_max: float = 1.02

@export var reaction_intensity: float = 1.0

## Counter parry window — separate from hit impact.
@export var parry_shake_intensity: float = 0.0
@export var parry_shake_duration: float = 0.0
@export var parry_flash_strength: float = 0.0
@export var parry_sfx_id: StringName = &""

@export var respect_shake_setting: bool = true
@export var respect_flash_setting: bool = true
@export var respect_particle_setting: bool = true

@export var vibration_intensity: float = 0.0
@export var vibration_duration: float = 0.0


func get_random_pitch() -> float:
	if pitch_max < pitch_min:
		return pitch_min
	return randf_range(pitch_min, pitch_max)


func to_feedback_dict(attacker: Node = null, target: Node = null) -> Dictionary:
	var zoom := zoom_amount
	var zoom_dur := zoom_duration
	if camera_effect == CameraEffect.NONE:
		zoom = 0.0
		zoom_dur = 0.0

	return {
		"profile_id": profile_id,
		"attack_id": attack_id,
		"tier": impact_tier,
		"sfx_id": sfx_id,
		"sfx_volume_scale": sfx_volume_scale,
		"pitch_min": pitch_min,
		"pitch_max": pitch_max,
		"vfx_kind": vfx_kind,
		"particle_count": particle_count,
		"particle_lifetime": particle_lifetime,
		"impact_color": impact_color,
		"flash_strength": flash_strength,
		"flash_color": flash_color,
		"shake_intensity": shake_intensity,
		"shake_duration": shake_duration,
		"zoom_amount": zoom,
		"zoom_duration": zoom_dur,
		"swing_trail_enabled": swing_trail_enabled,
		"swing_trail_particles": swing_trail_particles,
		"swing_trail_on_active": swing_trail_on_active,
		"shockwave_enabled": shockwave_enabled,
		"lateral_impact_bias": lateral_impact_bias,
		"reaction_intensity": reaction_intensity,
		"vibration_intensity": vibration_intensity,
		"vibration_duration": vibration_duration,
		"attacker_hitstop": attacker_hitstop,
		"target_hitstop": target_hitstop,
		"respect_flash_setting": respect_flash_setting,
		"respect_particle_setting": respect_particle_setting,
		"attacker_is_player": _is_player(attacker),
		"target_is_player": _is_player(target),
	}


func _is_player(node: Node) -> bool:
	return node != null and node.is_in_group("player")
