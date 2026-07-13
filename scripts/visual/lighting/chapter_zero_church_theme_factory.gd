extends RefCounted
class_name ChapterZeroChurchThemeFactory

const THEME_RESOURCE_PATH := "res://resources/visual/lighting/chapter_zero_church_theme.tres"
const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")


static func build() -> RegionVisualTheme:
	var theme := RegionVisualTheme.new()
	theme.theme_id = &"chapter_zero_church"
	theme.region_id = &"vs_greybox_church"
	theme.display_name = "Church District"
	theme.default_state = CorruptionVisualState.State.NORMAL
	theme.transition_duration = 1.0

	theme.normal_state = _make_state(
		CorruptionVisualState.State.NORMAL,
		"normal",
		"Silent church district — vertical stone, order dominance, restrained warmth.",
		_build_normal_profile()
	)
	theme.vermilite_near_state = _make_state(
		CorruptionVisualState.State.VERMILITE_NEAR,
		"vermilite_near",
		"Vermilite bleeding through ritual stone.",
		_build_vermilite_near_profile()
	)
	theme.red_resonance_state = _make_state(
		CorruptionVisualState.State.RED_RESONANCE,
		"red_resonance",
		"Order red concentrates on symbols and altar accents.",
		_build_red_resonance_profile()
	)
	theme.mol_khar_state = _make_state(
		CorruptionVisualState.State.MOL_KHAR_APPEARANCE,
		"mol_khar",
		"Controlled silhouette hint — no full Mol-Khar reveal.",
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
	profile.profile_id = &"church_normal"
	profile.display_name = "Church Normal"
	profile.canvas_modulate = Color(0.72, 0.66, 0.7, 1.0)
	profile.environment_saturation = 0.82
	profile.environment_value_scale = 0.92
	profile.key_light_color = Color(0.62, 0.58, 0.68, 1.0)
	profile.key_light_energy = 0.18
	profile.fill_light_color = Palette.ORDER_DEEP_RED.lerp(Palette.SUNSET_SKY_TOP, 0.35)
	profile.fill_light_energy = 0.14
	profile.lantern_color = Color(0.82, 0.55, 0.28, 1.0)
	profile.lantern_energy = 0.55
	profile.lantern_energy_scale = 0.85
	profile.window_glow_color = Palette.ORDER_AGED_CREAM
	profile.window_glow_energy = 0.22
	profile.vermilite_accent_color = Palette.VERMILITE_SATURATED
	profile.vermilite_accent_energy = 0.18
	profile.dust_alpha_scale = 0.55
	profile.vermilite_mote_alpha_scale = 0.65
	profile.particle_amount_scale = 0.75
	profile.vignette_strength = 0.18
	profile.ambient_audio_event = &"ambience_bell"
	return profile


static func _build_vermilite_near_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"church_vermilite_near"
	profile.display_name = "Church Vermilite Near"
	profile.canvas_modulate = Color(0.76, 0.64, 0.62, 1.0)
	profile.vermilite_accent_color = Palette.VERMILITE_CORE
	profile.vermilite_accent_energy = 0.42
	profile.vermilite_mote_alpha_scale = 1.05
	profile.particle_amount_scale = 0.9
	return profile


static func _build_red_resonance_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"church_red_resonance"
	profile.display_name = "Church Red Resonance"
	profile.canvas_modulate = Color(0.68, 0.58, 0.56, 1.0)
	profile.environment_saturation = 0.68
	profile.lantern_color = Palette.ORDER_BURNT_RED.lerp(Palette.ORDER_AGED_CREAM, 0.2)
	profile.vermilite_accent_color = Palette.ORDER_BURNT_RED
	profile.vermilite_accent_energy = 0.55
	profile.vignette_strength = 0.26
	return profile


static func _build_mol_khar_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"church_mol_khar"
	profile.display_name = "Church Mol-Khar Hint"
	profile.canvas_modulate = Color(0.48, 0.4, 0.44, 1.0)
	profile.environment_saturation = 0.45
	profile.environment_value_scale = 0.72
	profile.key_light_color = Palette.MOL_INNER_RED.lerp(Color(0.4, 0.36, 0.44, 1.0), 0.5)
	profile.key_light_energy = 0.12
	profile.fill_light_color = Palette.MOL_VOID
	profile.fill_light_energy = 0.2
	profile.lantern_energy_scale = 0.45
	profile.vermilite_accent_color = Palette.MOL_INNER_RED
	profile.vermilite_accent_energy = 0.32
	profile.particle_amount_scale = 0.55
	profile.vignette_strength = 0.38
	profile.silhouette_strength = 0.48
	profile.distortion_strength = 0.12
	profile.chromatic_aberration_strength = 0.06
	profile.ambient_audio_event = &"mol_khar_presence"
	return profile
