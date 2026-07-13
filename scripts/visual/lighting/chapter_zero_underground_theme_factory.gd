extends RefCounted
class_name ChapterZeroUndergroundThemeFactory

const Palette := preload("res://scripts/visual/lighting/red_hollow_palette.gd")


static func build() -> RegionVisualTheme:
	var theme := RegionVisualTheme.new()
	theme.theme_id = &"chapter_zero_underground"
	theme.region_id = &"vs_greybox_underground"
	theme.display_name = "Catacumbas"
	theme.default_state = CorruptionVisualState.State.NORMAL
	theme.transition_duration = 1.1

	theme.normal_state = _make_state(
		CorruptionVisualState.State.NORMAL,
		"normal",
		"Human mining supports fading into ritual tunnels.",
		_build_normal_profile()
	)
	theme.vermilite_near_state = _make_state(
		CorruptionVisualState.State.VERMILITE_NEAR,
		"vermilite_near",
		"Vermilite veins brighten near the prison chamber.",
		_build_vermilite_near_profile()
	)
	theme.red_resonance_state = _make_state(
		CorruptionVisualState.State.RED_RESONANCE,
		"red_resonance",
		"Red Brand and order symbols pulse during boss.",
		_build_red_resonance_profile()
	)
	theme.mol_khar_state = _make_state(
		CorruptionVisualState.State.MOL_KHAR_APPEARANCE,
		"mol_khar",
		"Mol-Khar presence as shadow and inner red — not full form.",
		_build_mol_khar_profile()
	)
	return theme


static func load_or_build() -> RegionVisualTheme:
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
	profile.profile_id = &"underground_normal"
	profile.display_name = "Catacomb Normal"
	profile.canvas_modulate = Color(0.58, 0.54, 0.56, 1.0)
	profile.environment_saturation = 0.7
	profile.environment_value_scale = 0.82
	profile.key_light_color = Color(0.48, 0.42, 0.46, 1.0)
	profile.key_light_energy = 0.14
	profile.fill_light_color = Palette.ORDER_DEEP_RED.lerp(Palette.MOL_VOID, 0.4)
	profile.fill_light_energy = 0.16
	profile.lantern_color = Color(0.92, 0.62, 0.28, 1.0)
	profile.lantern_energy = 0.42
	profile.lantern_energy_scale = 0.75
	profile.vermilite_accent_color = Palette.VERMILITE_SATURATED
	profile.vermilite_accent_energy = 0.22
	profile.dust_alpha_scale = 0.65
	profile.vermilite_mote_alpha_scale = 0.8
	profile.particle_amount_scale = 0.85
	profile.vignette_strength = 0.28
	profile.ambient_audio_event = &"ambience_mines"
	return profile


static func _build_vermilite_near_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"underground_vermilite_near"
	profile.vermilite_accent_energy = 0.48
	profile.vermilite_mote_alpha_scale = 1.2
	return profile


static func _build_red_resonance_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"underground_red_resonance"
	profile.canvas_modulate = Color(0.62, 0.5, 0.48, 1.0)
	profile.vermilite_accent_color = Palette.ORDER_BURNT_RED
	profile.vermilite_accent_energy = 0.62
	profile.vignette_strength = 0.34
	return profile


static func _build_mol_khar_profile() -> LightingProfile:
	var profile := _build_normal_profile()
	profile.profile_id = &"underground_mol_khar"
	profile.canvas_modulate = Color(0.38, 0.32, 0.34, 1.0)
	profile.environment_saturation = 0.42
	profile.environment_value_scale = 0.68
	profile.key_light_color = Palette.MOL_INNER_RED.lerp(Color(0.3, 0.26, 0.3, 1.0), 0.45)
	profile.fill_light_color = Palette.MOL_VOID
	profile.fill_light_energy = 0.26
	profile.lantern_energy_scale = 0.4
	profile.vermilite_accent_color = Palette.MOL_INNER_RED
	profile.vermilite_accent_energy = 0.38
	profile.particle_amount_scale = 0.6
	profile.vignette_strength = 0.45
	profile.silhouette_strength = 0.55
	profile.distortion_strength = 0.16
	profile.chromatic_aberration_strength = 0.08
	profile.ambient_audio_event = &"mol_khar_presence"
	return profile
