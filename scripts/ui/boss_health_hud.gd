extends CanvasLayer
class_name BossHealthHud

const HUD_GROUP := "boss_health_hud"

@onready var panel: PanelContainer = %Panel
@onready var boss_name_label: Label = %BossNameLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var taunt_label: Label = %TauntLabel

var _bound_boss: DeaconRusk = null
var _health_component: HealthComponent = null
var _taunt_timer: SceneTreeTimer = null


func _ready() -> void:
	add_to_group(HUD_GROUP)
	if panel != null:
		UiThemeHelper.style_panel(panel)
	if boss_name_label != null:
		HudThemeV2.apply_label_cream(boss_name_label, 14)
	if health_bar != null:
		HudThemeV2.apply_progress_fill(health_bar, HudThemeV2.COLOR_BRAND)
	if taunt_label != null:
		HudThemeV2.apply_label_muted(taunt_label, 11)
	hide_boss()


func bind_boss(boss: DeaconRusk) -> void:
	unbind_boss()
	if boss == null:
		return

	_bound_boss = boss
	_health_component = boss.health_component
	if boss_name_label != null:
		boss_name_label.text = boss.display_name

	if _health_component != null:
		_health_component.health_changed.connect(_on_health_changed)
		_on_health_changed(_health_component.current_health, _health_component.max_health)

	if boss.has_signal("taunt_spoken"):
		boss.taunt_spoken.connect(_on_taunt_spoken)
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)

	if panel != null:
		panel.visible = true


func unbind_boss() -> void:
	if _health_component != null and _health_component.health_changed.is_connected(_on_health_changed):
		_health_component.health_changed.disconnect(_on_health_changed)

	if _bound_boss != null:
		if _bound_boss.taunt_spoken.is_connected(_on_taunt_spoken):
			_bound_boss.taunt_spoken.disconnect(_on_taunt_spoken)
		if _bound_boss.boss_defeated.is_connected(_on_boss_defeated):
			_bound_boss.boss_defeated.disconnect(_on_boss_defeated)

	_bound_boss = null
	_health_component = null
	hide_boss()


func hide_boss() -> void:
	if panel != null:
		panel.visible = false
	if taunt_label != null:
		taunt_label.text = ""


func _on_health_changed(current_health: float, max_health: float) -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_health
	health_bar.value = current_health


func _on_taunt_spoken(line: String) -> void:
	if taunt_label == null:
		return
	taunt_label.text = "\"%s\"" % line

	if _taunt_timer != null and is_instance_valid(_taunt_timer):
		_taunt_timer.timeout.disconnect(_clear_taunt)

	_taunt_timer = get_tree().create_timer(2.6)
	_taunt_timer.timeout.connect(_clear_taunt, CONNECT_ONE_SHOT)


func _clear_taunt() -> void:
	if taunt_label != null:
		taunt_label.text = ""


func _on_boss_defeated(_boss_id: StringName) -> void:
	call_deferred("hide_boss")
