extends RefCounted
class_name ChapterZeroStreetThemeFactory

## Builds the North Star street RegionVisualTheme + lighting profiles at runtime.

const THEME_RESOURCE_PATH := "res://resources/visual/lighting/chapter_zero_street_theme.tres"


static func build() -> RegionVisualTheme:
	var theme := RegionVisualTheme.new()
	theme.theme_id = &"chapter_zero_north_star"
	theme.region_id = &"vs_greybox_street"
	theme.display_name = "North Star Street"
	theme.default_state = CorruptionVisualState.State.NORMAL
	theme.transition_duration = 0.85

	theme.normal_state = _make_state(
		CorruptionVisualState.State.NORMAL,
		"normal",
		"Decadent frontier town at sunset — no cult dominance.",
		_build_normal_profile()
	)
	theme.vermilite_near_state = _make_state(
		CorruptionVisualState.State.VERMILITE_NEAR,
		"vermilite_near",
		"Local Vermilite glow, motes and restrained accent light.",
		_build_vermilite_near_profile()
	)
	theme.red_resonance_state = _make_state(
		CorruptionVisualState.State.RED_RESONANCE,
		"red_resonance",
		"Muted environment; red concentrates on marked elements.",
		_build_red_resonance_profile()
	)
	theme.mol_khar_state = _make_state(
		CorruptionVisualState.State.MOL_KHAR_APPEARANCE,
		"mol_khar",
		"Controlled darkness, silhouette and inner red — not full-screen wash.",
		_build_mol_khar_profile()
	)
	return theme


static func load_or_build() -> RegionVisualTheme:
	if ResourceLoader.exists(THEME_RESOURCE_PATH):
		var loaded := load(THEME_RESOURCE_PATH) as RegionVisualTheme
		if loaded != null:
			return loaded
	return build()


static func _make_state(
	state: CorruptionVisualState.State,
	state_name: String,
	description: String,
	profile: LightingProfile
) -> CorruptionVisualState:
	var resource := CorruptionVisualState.new()
	resource.state = state
	resource.state_name = state_name
	resource.description = description
	resource.lighting_profile = profile
	return resource


static func _build_normal_profile() -> LightingProfile:
	var profile := LightingProfile.new()
	profile.profile_id = &"north_star_normal"
	profile.display_name = "Normal"
	profile.canvas_modulate = Color(0.92, 0.78, 0.66, 1.0)
	profile.environment_saturation = 1.0
	profile.environment_value_scale = 1.0
	profile.key_light_color = RedHollowPalette.SUNSET_ORANGE.lerp(Color.WHITE, 0.15)
	profile.key_light_energy = 0.32
	profile.fill_light_color = RedHollowPalette.SUNSET_SKY_TOP
	profile.fill_light_energy = 0.12
	profile.lantern_color = Color(1.0, 0.68, 0.28, 1.0)
	profile.lantern_energy = 0.85
	profile.lantern_energy_scale = 1.0
	profile.window_glow_color = RedHollowPalette.SUNSET_ORANGE.lerp(RedHollowPalette.FABRIC_TAN, 0.35)
	profile.window_glow_energy = 0.35
	profile.vermilite_accent_color = RedHollowPalette.VERMILITE_SATURATED
	profile.vermilite_accent_energy = 0.28
	profile.dust_alpha_scale = 1.0
	profile.vermilite_mote_alpha_scale = 0.85
	profile.particle_amount_scale = 1.0
	return profile


static func _build_vermilite_near_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"north_star_vermilite_near"
	profile.display_name = "Vermilite Near"
	profile.canvas_modulate = Color(0.94, 0.76, 0.64, 1.0)
	profile.vermilite_accent_color = RedHollowPalette.VERMILITE_CORE
	profile.vermilite_accent_energy = 0.52
	profile.window_glow_color = RedHollowPalette.VERMILITE_HALO
	profile.window_glow_energy = 0.42
	profile.vermilite_mote_alpha_scale = 1.35
	profile.particle_amount_scale = 1.15
	profile.lantern_color = RedHollowPalette.SUNSET_ORANGE.lerp(RedHollowPalette.VERMILITE_CORE, 0.18)
	return profile


static func _build_red_resonance_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"north_star_red_resonance"
	profile.display_name = "Red Resonance"
	profile.canvas_modulate = Color(0.82, 0.68, 0.6, 1.0)
	profile.environment_saturation = 0.72
	profile.environment_value_scale = 0.9
	profile.fill_light_color = RedHollowPalette.ORDER_DEEP_RED.lerp(RedHollowPalette.SUNSET_SKY_TOP, 0.55)
	profile.fill_light_energy = 0.16
	profile.lantern_energy_scale = 0.82
	profile.lantern_color = RedHollowPalette.ORDER_AGED_CREAM.lerp(RedHollowPalette.ORDER_BURNT_RED, 0.22)
	profile.vermilite_accent_color = RedHollowPalette.ORDER_BURNT_RED
	profile.vermilite_accent_energy = 0.62
	profile.vermilite_mote_alpha_scale = 1.1
	profile.dust_alpha_scale = 0.75
	profile.vignette_strength = 0.12
	return profile


static func _build_mol_khar_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"north_star_mol_khar"
	profile.display_name = "Mol-Khar Appearance"
	profile.canvas_modulate = Color(0.58, 0.48, 0.5, 1.0)
	profile.environment_saturation = 0.55
	profile.environment_value_scale = 0.78
	profile.key_light_color = RedHollowPalette.MOL_INNER_RED.lerp(RedHollowPalette.SUNSET_ORANGE, 0.25)
	profile.key_light_energy = 0.2
	profile.fill_light_color = RedHollowPalette.MOL_VOID
	profile.fill_light_energy = 0.22
	profile.lantern_energy_scale = 0.55
	profile.lantern_color = RedHollowPalette.MOL_INNER_RED.lerp(RedHollowPalette.ORDER_BLACK, 0.4)
	profile.window_glow_color = RedHollowPalette.MOL_INNER_RED
	profile.window_glow_energy = 0.28
	profile.vermilite_accent_color = RedHollowPalette.MOL_INNER_RED
	profile.vermilite_accent_energy = 0.48
	profile.vermilite_mote_alpha_scale = 0.65
	profile.dust_alpha_scale = 0.5
	profile.particle_amount_scale = 0.7
	profile.vignette_strength = 0.34
	profile.silhouette_strength = 0.42
	profile.distortion_strength = 0.22
	profile.chromatic_aberration_strength = 0.1
	profile.ambient_audio_event = &"mol_khar_presence"
	return profile
