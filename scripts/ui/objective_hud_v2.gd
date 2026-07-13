extends ObjectiveHud
class_name ObjectiveHudV2

const PULSE_SECONDS := 0.45

@onready var _pulse_panel: PanelContainer = %ObjectivePanel
@onready var _update_badge: Label = %ObjectiveUpdateBadge

var _pulse_tween: Tween = null


func _ready() -> void:
	super._ready()
	if _pulse_panel != null:
		_pulse_panel.add_theme_stylebox_override("panel", HudThemeV2.make_panel_style(5))
	if _title_label != null:
		HudThemeV2.apply_label_cream(_title_label, 12)
	if _body_label != null:
		HudThemeV2.apply_label_muted(_body_label, 11)
	if _update_badge != null:
		_update_badge.visible = false
		_update_badge.add_theme_color_override("font_color", HudThemeV2.COLOR_VERMILITE)


func update_objective(objective_id: String, title: String, text: String) -> void:
	var previous_title := _title_label.text if _title_label != null else ""
	super.update_objective(objective_id, title, text)
	if title != previous_title and not title.is_empty():
		_play_update_pulse()


func _play_update_pulse() -> void:
	if _pulse_panel == null:
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_panel.modulate = Color(1.15, 1.05, 0.95, 1.0)
	_pulse_tween.tween_property(_pulse_panel, "modulate", Color.WHITE, PULSE_SECONDS)
	if _update_badge != null:
		_update_badge.visible = true
		_update_badge.modulate.a = 1.0
		_pulse_tween.parallel().tween_property(_update_badge, "modulate:a", 0.0, PULSE_SECONDS)
		_pulse_tween.tween_callback(func() -> void:
			if _update_badge != null:
				_update_badge.visible = false
		)
