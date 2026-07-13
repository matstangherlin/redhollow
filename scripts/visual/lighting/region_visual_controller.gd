extends Node
class_name RegionVisualController

## Applies RegionVisualTheme lighting states with controlled transitions.

signal visual_state_changed(state: CorruptionVisualState.State)
signal transition_started(from_state: CorruptionVisualState.State, to_state: CorruptionVisualState.State)
signal transition_finished(state: CorruptionVisualState.State)

const GROUP_ID := "region_visual_controller"

const LAYER_LIGHTING := "Layer09_Lighting"
const LAYER_ATMOSPHERE := "Layer10_Atmosphere"

@export var theme: RegionVisualTheme
@export var auto_bind_parent_presentation: bool = true

var _presentation: Node2D = null
var _current_state: CorruptionVisualState.State = CorruptionVisualState.State.NORMAL
var _transition_tween: Tween = null
var _bound_nodes: Dictionary = {}
var _settings_manager: Node = null


func _ready() -> void:
	add_to_group(GROUP_ID)
	_connect_settings()
	if auto_bind_parent_presentation:
		call_deferred("_try_bind_parent")


func _exit_tree() -> void:
	_disconnect_settings()


func bind_presentation(presentation: Node2D) -> void:
	_presentation = presentation
	_cache_presentation_nodes()
	if theme != null:
		apply_state_immediate(theme.default_state)


func get_current_state() -> CorruptionVisualState.State:
	return _current_state


func apply_state_immediate(state: CorruptionVisualState.State) -> void:
	if theme == null:
		return
	_current_state = state
	_kill_transition()
	var profile := _resolve_profile(state)
	if profile != null:
		_apply_profile_immediate(profile)
	visual_state_changed.emit(state)


func transition_to_state(state: CorruptionVisualState.State, duration: float = -1.0) -> void:
	if theme == null or state == _current_state:
		return

	var target_profile := _resolve_profile(state)
	if target_profile == null:
		return

	var from_state := _current_state
	_current_state = state
	_kill_transition()

	var blend_duration := duration if duration > 0.0 else theme.transition_duration
	transition_started.emit(from_state, state)

	if blend_duration <= 0.01:
		_apply_profile_immediate(target_profile)
		transition_finished.emit(state)
		visual_state_changed.emit(state)
		return

	var start_profile := _capture_current_profile()
	_transition_tween = create_tween()
	_transition_tween.set_trans(Tween.TRANS_SINE)
	_transition_tween.set_ease(Tween.EASE_IN_OUT)
	_transition_tween.tween_method(
		_blend_to_profile.bind(start_profile, target_profile),
		0.0,
		1.0,
		blend_duration
	)
	_transition_tween.finished.connect(
		func() -> void:
			_apply_profile_immediate(target_profile)
			transition_finished.emit(state)
			visual_state_changed.emit(state),
		CONNECT_ONE_SHOT
	)


func _try_bind_parent() -> void:
	var parent := get_parent()
	if parent is Node2D and parent.get_script() != null:
		var script_path := String(parent.get_script().resource_path)
		if script_path.ends_with("street_art_presentation.gd"):
			bind_presentation(parent as Node2D)


func _connect_settings() -> void:
	_settings_manager = FeedbackSettingsAccess.get_manager()
	if _settings_manager != null and _settings_manager.has_signal("settings_changed"):
		if not _settings_manager.settings_changed.is_connected(_on_settings_changed):
			_settings_manager.settings_changed.connect(_on_settings_changed)


func _disconnect_settings() -> void:
	if _settings_manager != null and _settings_manager.has_signal("settings_changed"):
		if _settings_manager.settings_changed.is_connected(_on_settings_changed):
			_settings_manager.settings_changed.disconnect(_on_settings_changed)
	_settings_manager = null


func _on_settings_changed() -> void:
	if theme == null:
		return
	apply_state_immediate(_current_state)


func _resolve_profile(state: CorruptionVisualState.State) -> LightingProfile:
	if theme == null:
		return null
	var base := theme.get_lighting_profile(state)
	if base == null:
		return null
	return base.apply_accessibility(_get_accessibility_scale())


func _get_accessibility_scale() -> Dictionary:
	var flash_scale := 1.0
	if FeedbackSettingsAccess.is_reduced_flashes_enabled():
		flash_scale = 0.55
	var particle_scale := FeedbackSettingsAccess.get_particle_multiplier()
	var distortion_scale := 1.0
	if FeedbackSettingsAccess.is_reduced_distortion_enabled():
		distortion_scale = 0.35
	var contrast_scale := 1.0
	if FeedbackSettingsAccess.is_reduced_extreme_contrast_enabled():
		contrast_scale = 0.75
	if FeedbackSettingsAccess.is_chromatic_aberration_disabled():
		distortion_scale = 0.0
	return {
		"flash_scale": flash_scale,
		"particle_scale": particle_scale,
		"distortion_scale": distortion_scale,
		"contrast_scale": contrast_scale,
	}


func _cache_presentation_nodes() -> void:
	_bound_nodes.clear()
	if _presentation == null:
		return

	_bound_nodes["canvas_modulate"] = _presentation.get_node_or_null("SunsetModulate") as CanvasModulate
	var lighting_layer := _presentation.get_node_or_null(LAYER_LIGHTING) as Node2D
	if lighting_layer != null:
		_bound_nodes["key_light"] = lighting_layer.get_node_or_null("SunsetDirectional") as DirectionalLight2D
		_bound_nodes["fill_light"] = lighting_layer.get_node_or_null("CoolShadowFill") as DirectionalLight2D
		_bound_nodes["vermilite_light"] = lighting_layer.get_node_or_null("VermiliteAccent") as PointLight2D
		_bound_nodes["window_light"] = lighting_layer.get_node_or_null("SaloonWindowGlow") as PointLight2D
		var lanterns: Array[PointLight2D] = []
		for child in lighting_layer.get_children():
			if child is PointLight2D and String(child.name).begins_with("LanternLight"):
				lanterns.append(child as PointLight2D)
		_bound_nodes["lanterns"] = lanterns

	var atmosphere_layer := _presentation.get_node_or_null(LAYER_ATMOSPHERE) as Node2D
	if atmosphere_layer != null:
		_bound_nodes["dust"] = atmosphere_layer.get_node_or_null("DustMotes") as CPUParticles2D
		_bound_nodes["verm_motes"] = atmosphere_layer.get_node_or_null("VermiliteMotes") as CPUParticles2D

	if _bound_nodes.get("overlay_root") == null:
		_ensure_overlay_nodes()


func _ensure_overlay_nodes() -> void:
	if _presentation == null:
		return

	var overlay := _presentation.get_node_or_null("RegionVisualOverlay") as CanvasLayer
	if overlay == null:
		overlay = CanvasLayer.new()
		overlay.name = "RegionVisualOverlay"
		overlay.layer = 85
		overlay.follow_viewport_enabled = true
		_presentation.add_child(overlay)

	var vignette := overlay.get_node_or_null("Vignette") as ColorRect
	if vignette == null:
		vignette = ColorRect.new()
		vignette.name = "Vignette"
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
		vignette.color = Color(0, 0, 0, 0)
		overlay.add_child(vignette)

	var silhouette := overlay.get_node_or_null("MolSilhouette") as ColorRect
	if silhouette == null:
		silhouette = ColorRect.new()
		silhouette.name = "MolSilhouette"
		silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		silhouette.set_anchors_preset(Control.PRESET_FULL_RECT)
		silhouette.color = Color(0, 0, 0, 0)
		overlay.add_child(silhouette)

	var distortion := overlay.get_node_or_null("DistortionVeil") as ColorRect
	if distortion == null:
		distortion = ColorRect.new()
		distortion.name = "DistortionVeil"
		distortion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		distortion.set_anchors_preset(Control.PRESET_FULL_RECT)
		distortion.color = Color(0, 0, 0, 0)
		overlay.add_child(distortion)

	_bound_nodes["overlay_root"] = overlay
	_bound_nodes["vignette"] = vignette
	_bound_nodes["silhouette"] = silhouette
	_bound_nodes["distortion"] = distortion


func _apply_profile_immediate(profile: LightingProfile) -> void:
	var canvas_modulate := _bound_nodes.get("canvas_modulate") as CanvasModulate
	if canvas_modulate != null:
		canvas_modulate.color = _scaled_modulate(profile)

	var key_light := _bound_nodes.get("key_light") as DirectionalLight2D
	if key_light != null:
		key_light.color = profile.key_light_color
		key_light.energy = profile.key_light_energy

	var fill_light := _bound_nodes.get("fill_light") as DirectionalLight2D
	if fill_light != null:
		fill_light.color = profile.fill_light_color
		fill_light.energy = profile.fill_light_energy

	var lanterns: Array = _bound_nodes.get("lanterns", [])
	for lantern in lanterns:
		if lantern is PointLight2D:
			lantern.color = profile.lantern_color
			lantern.energy = profile.lantern_energy * profile.lantern_energy_scale

	var window_light := _bound_nodes.get("window_light") as PointLight2D
	if window_light != null:
		window_light.color = profile.window_glow_color
		window_light.energy = profile.window_glow_energy

	var verm_light := _bound_nodes.get("vermilite_light") as PointLight2D
	if verm_light != null:
		verm_light.color = profile.vermilite_accent_color
		verm_light.energy = profile.vermilite_accent_energy

	var dust := _bound_nodes.get("dust") as CPUParticles2D
	if dust != null:
		var dust_color := dust.color
		dust_color.a = clampf(0.16 * profile.dust_alpha_scale, 0.0, 0.35)
		dust.color = dust_color
		dust.amount = int(80 * profile.particle_amount_scale)

	var verm_motes := _bound_nodes.get("verm_motes") as CPUParticles2D
	if verm_motes != null:
		var mote_color := verm_motes.color
		mote_color.a = clampf(0.28 * profile.vermilite_mote_alpha_scale, 0.0, 0.55)
		verm_motes.color = mote_color
		verm_motes.amount = int(12 * profile.particle_amount_scale)

	var vignette := _bound_nodes.get("vignette") as ColorRect
	if vignette != null:
		vignette.color = Color(0.02, 0.01, 0.02, clampf(profile.vignette_strength, 0.0, 0.55))

	var silhouette := _bound_nodes.get("silhouette") as ColorRect
	if silhouette != null:
		silhouette.color = RedHollowPalette.MOL_ABNORMAL_SHADOW
		silhouette.modulate.a = clampf(profile.silhouette_strength, 0.0, 0.72)

	var distortion := _bound_nodes.get("distortion") as ColorRect
	if distortion != null:
		var ca := profile.chromatic_aberration_strength
		distortion.color = Color(
			RedHollowPalette.MOL_INNER_RED.r,
			RedHollowPalette.MOL_INNER_RED.g,
			RedHollowPalette.MOL_INNER_RED.b,
			clampf(profile.distortion_strength * 0.12, 0.0, 0.18)
		)
		distortion.visible = ca > 0.001 or profile.distortion_strength > 0.001


func _scaled_modulate(profile: LightingProfile) -> Color:
	var color := profile.canvas_modulate
	var saturation := profile.environment_saturation
	var value_scale := profile.environment_value_scale
	var hue := color.h
	var sat := clampf(color.s * saturation, 0.0, 1.0)
	var value := clampf(color.v * value_scale, 0.0, 1.0)
	return Color.from_hsv(hue, sat, value, color.a)


func _capture_current_profile() -> LightingProfile:
	var snapshot := LightingProfile.new()
	var canvas_modulate := _bound_nodes.get("canvas_modulate") as CanvasModulate
	if canvas_modulate != null:
		snapshot.canvas_modulate = canvas_modulate.color
	var key_light := _bound_nodes.get("key_light") as DirectionalLight2D
	if key_light != null:
		snapshot.key_light_color = key_light.color
		snapshot.key_light_energy = key_light.energy
	var fill_light := _bound_nodes.get("fill_light") as DirectionalLight2D
	if fill_light != null:
		snapshot.fill_light_color = fill_light.color
		snapshot.fill_light_energy = fill_light.energy
	var verm_light := _bound_nodes.get("vermilite_light") as PointLight2D
	if verm_light != null:
		snapshot.vermilite_accent_color = verm_light.color
		snapshot.vermilite_accent_energy = verm_light.energy
	var canvas_color := snapshot.canvas_modulate
	snapshot.environment_saturation = 1.0
	snapshot.environment_value_scale = canvas_color.v
	return snapshot


func _blend_to_profile(weight: float, from_profile: LightingProfile, to_profile: LightingProfile) -> void:
	var blended := LightingProfile.new()
	blended.canvas_modulate = from_profile.canvas_modulate.lerp(to_profile.canvas_modulate, weight)
	blended.environment_saturation = lerpf(
		from_profile.environment_saturation, to_profile.environment_saturation, weight
	)
	blended.environment_value_scale = lerpf(
		from_profile.environment_value_scale, to_profile.environment_value_scale, weight
	)
	blended.key_light_color = from_profile.key_light_color.lerp(to_profile.key_light_color, weight)
	blended.key_light_energy = lerpf(from_profile.key_light_energy, to_profile.key_light_energy, weight)
	blended.fill_light_color = from_profile.fill_light_color.lerp(to_profile.fill_light_color, weight)
	blended.fill_light_energy = lerpf(from_profile.fill_light_energy, to_profile.fill_light_energy, weight)
	blended.lantern_color = from_profile.lantern_color.lerp(to_profile.lantern_color, weight)
	blended.lantern_energy = lerpf(from_profile.lantern_energy, to_profile.lantern_energy, weight)
	blended.lantern_energy_scale = lerpf(from_profile.lantern_energy_scale, to_profile.lantern_energy_scale, weight)
	blended.window_glow_color = from_profile.window_glow_color.lerp(to_profile.window_glow_color, weight)
	blended.window_glow_energy = lerpf(from_profile.window_glow_energy, to_profile.window_glow_energy, weight)
	blended.vermilite_accent_color = from_profile.vermilite_accent_color.lerp(to_profile.vermilite_accent_color, weight)
	blended.vermilite_accent_energy = lerpf(
		from_profile.vermilite_accent_energy, to_profile.vermilite_accent_energy, weight
	)
	blended.dust_alpha_scale = lerpf(from_profile.dust_alpha_scale, to_profile.dust_alpha_scale, weight)
	blended.vermilite_mote_alpha_scale = lerpf(
		from_profile.vermilite_mote_alpha_scale, to_profile.vermilite_mote_alpha_scale, weight
	)
	blended.particle_amount_scale = lerpf(
		from_profile.particle_amount_scale, to_profile.particle_amount_scale, weight
	)
	blended.vignette_strength = lerpf(from_profile.vignette_strength, to_profile.vignette_strength, weight)
	blended.silhouette_strength = lerpf(from_profile.silhouette_strength, to_profile.silhouette_strength, weight)
	blended.distortion_strength = lerpf(from_profile.distortion_strength, to_profile.distortion_strength, weight)
	blended.chromatic_aberration_strength = lerpf(
		from_profile.chromatic_aberration_strength, to_profile.chromatic_aberration_strength, weight
	)
	_apply_profile_immediate(blended)


func _kill_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
