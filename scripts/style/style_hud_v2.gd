extends StyleHud
class_name StyleHudV2

## Reorganized StyleHud layout — same bindings, compact vitals, combat-aware style cluster.

const COMBAT_FADE_SECONDS := 5.0
const EXPLORATION_STYLE_ALPHA := 0.42

@onready var _style_cluster: Control = %StyleCluster
@onready var _vitals_cluster: Control = %VitalsCluster

var _combat_pulse_timer: float = 0.0


func _ready() -> void:
	_apply_theme()
	_apply_style_cluster_visibility()


func _apply_theme() -> void:
	if _vitals_cluster is PanelContainer:
		(_vitals_cluster as PanelContainer).add_theme_stylebox_override("panel", HudThemeV2.make_panel_style(5))
	if _style_cluster is PanelContainer:
		(_style_cluster as PanelContainer).add_theme_stylebox_override("panel", HudThemeV2.make_panel_style(6, 2))
	if health_bar != null:
		HudThemeV2.apply_progress_fill(health_bar, HudThemeV2.COLOR_HEALTH)
	if red_brand_bar != null:
		HudThemeV2.apply_progress_fill(red_brand_bar, HudThemeV2.COLOR_BRAND)
	if progress_bar != null:
		HudThemeV2.apply_progress_fill(progress_bar, HudThemeV2.COLOR_STYLE)
	if rank_label != null:
		rank_label.add_theme_color_override("font_color", HudThemeV2.COLOR_STYLE)
	if multiplier_label != null:
		multiplier_label.add_theme_color_override("font_color", HudThemeV2.COLOR_VERMILITE)


func _process(delta: float) -> void:
	super._process(delta)
	if _combat_pulse_timer > 0.0:
		_combat_pulse_timer = maxf(_combat_pulse_timer - delta, 0.0)
	_apply_style_cluster_visibility()


func _on_style_feedback(message: String, amount: float) -> void:
	super._on_style_feedback(message, amount)
	_combat_pulse_timer = COMBAT_FADE_SECONDS


func _refresh_from_manager() -> void:
	super._refresh_from_manager()
	if _style_manager != null and _style_manager.style_score > 0.01:
		_combat_pulse_timer = maxf(_combat_pulse_timer, 2.0)
	_apply_style_cluster_visibility()


func _refresh_health_values(current_health: float, max_health: float) -> void:
	super._refresh_health_values(current_health, max_health)
	if health_bar == null:
		return
	var ratio := 0.0
	if max_health > 0.0:
		ratio = current_health / max_health
	var fill_color := HudThemeV2.COLOR_HEALTH
	if ratio <= 0.3:
		fill_color = HudThemeV2.COLOR_VERMILITE
	HudThemeV2.apply_progress_fill(health_bar, fill_color)


func preview_vitals(current_health: float, max_health: float, brand_energy: float = -1.0) -> void:
	_refresh_health_values(current_health, max_health)
	if brand_energy < 0.0:
		return
	if red_brand_bar != null:
		red_brand_bar.value = brand_energy
	if red_brand_value_label != null:
		red_brand_value_label.text = "%.0f / 100" % brand_energy


func set_combat_highlight(active: bool) -> void:
	if active:
		_combat_pulse_timer = COMBAT_FADE_SECONDS
	else:
		_combat_pulse_timer = 0.0
	_apply_style_cluster_visibility()


func _apply_style_cluster_visibility() -> void:
	if _style_cluster == null:
		return

	var in_combat := _combat_pulse_timer > 0.0
	var ranked := false
	if _style_manager != null and String(_style_manager.style_rank) != "DUST":
		ranked = true
		in_combat = true

	if in_combat:
		_style_cluster.visible = true
		_style_cluster.modulate.a = 1.0 if _combat_pulse_timer > 0.0 else 0.85
	elif ranked:
		_style_cluster.visible = true
		_style_cluster.modulate.a = EXPLORATION_STYLE_ALPHA
	else:
		_style_cluster.visible = false
		_style_cluster.modulate.a = 0.0
