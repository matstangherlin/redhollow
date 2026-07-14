extends CanvasLayer
class_name ControlsTutorialOverlay

## Compact boot tutorial. Full reference lives in Pause → Controles.

const MAX_VIEWPORT_HEIGHT_RATIO := 0.12
const COMPACT_LINES_KEYBOARD := (
	"A/D · Espaço · J atacar · K esquivar · L counter · E falar\n"
	+ "U Red Brand · Esc pausa (controles completos na pausa)"
)
const COMPACT_LINES_GAMEPAD := (
	"Stick · A pular · X atacar · B esquivar · Y counter · RB falar\n"
	+ "RT Red Brand · Start pausa (lista completa na pausa)"
)

@export var intro_visible_seconds: float = 5.5
@export var fade_seconds: float = 0.55
@export var show_on_first_area_only: bool = true

@onready var _panel: PanelContainer = %TutorialPanel
@onready var _label: Label = %TutorialLabel

var _visible_timer: float = 0.0
var _dismissed: bool = false
var _force_visible: bool = false
var _suppressed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 6
	if _panel != null:
		_panel.add_theme_stylebox_override("panel", HudThemeV2.make_panel_style(4))
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _label != null:
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		HudThemeV2.apply_label_muted(_label, 10)
	if InputDeviceManager != null and not InputDeviceManager.device_changed.is_connected(_on_device_changed):
		InputDeviceManager.device_changed.connect(_on_device_changed)
	_refresh_label_text()
	_apply_height_budget()
	_visible_timer = intro_visible_seconds
	_update_visibility(1.0)


func _on_device_changed(_device_kind: int) -> void:
	_refresh_label_text()


static func get_controls_reference() -> String:
	if InputDeviceManager != null and InputDeviceManager.is_using_gamepad():
		return _build_device_aware_reference(true)
	return _build_device_aware_reference(false)


static func _build_device_aware_reference(gamepad: bool) -> String:
	if InputDeviceManager == null:
		return COMPACT_LINES_GAMEPAD if gamepad else COMPACT_LINES_KEYBOARD
	var move := "Stick" if gamepad else "A/D"
	var map_label := "Select" if gamepad else "M"
	return "%s mover · %s pular · %s atacar · %s esquivar · %s counter\n%s interagir · %s Red Brand · %s provocar · %s mapa · %s pausa" % [
		move,
		InputDeviceManager.get_action_prompt(&"jump", false),
		InputDeviceManager.get_action_prompt(&"attack", false),
		InputDeviceManager.get_action_prompt(&"dodge", false),
		InputDeviceManager.get_action_prompt(&"counter", false),
		InputDeviceManager.get_action_prompt(&"interact", false),
		InputDeviceManager.get_action_prompt(&"special", false),
		InputDeviceManager.get_action_prompt(&"taunt", false),
		map_label,
		InputDeviceManager.get_action_prompt(&"pause", false),
	]


func show_reference(force: bool = true) -> void:
	_force_visible = force
	_dismissed = false
	_visible_timer = intro_visible_seconds
	_refresh_label_text()
	_apply_height_budget()
	_update_visibility(1.0)


func dismiss() -> void:
	_dismissed = true
	_force_visible = false
	_update_visibility(0.0)


func notify_new_command_unlocked() -> void:
	## Reappear briefly for a newly introduced command; still respects suppress.
	_dismissed = false
	_force_visible = false
	_visible_timer = maxf(intro_visible_seconds * 0.75, 4.0)
	_refresh_label_text()
	_apply_height_budget()
	_update_visibility(1.0)


func _process(delta: float) -> void:
	_apply_height_budget()
	_suppressed = _should_suppress_overlay()
	if _suppressed:
		_update_visibility(0.0)
		return

	if _force_visible:
		_update_visibility(1.0)
		return

	if _dismissed:
		_update_visibility(0.0)
		return

	if _visible_timer > 0.0:
		_visible_timer = maxf(_visible_timer - delta, 0.0)
		if _visible_timer <= fade_seconds:
			_update_visibility(_visible_timer / maxf(fade_seconds, 0.001))
		else:
			_update_visibility(1.0)
		if _visible_timer <= 0.0:
			_dismissed = true
			_update_visibility(0.0)


func _should_suppress_overlay() -> bool:
	if not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node is DialogueController and (node as DialogueController).is_blocking_interactions():
			return true
	for node in get_tree().get_nodes_in_group(BossHealthHud.HUD_GROUP):
		if node is BossHealthHud:
			var boss_hud := node as BossHealthHud
			if boss_hud.panel != null and boss_hud.panel.visible:
				return true
	return false


func _refresh_label_text() -> void:
	if _label == null:
		return
	_label.text = get_controls_reference()


func _apply_height_budget() -> void:
	if _panel == null:
		return
	var viewport_h := get_viewport().get_visible_rect().size.y
	if viewport_h <= 1.0:
		return
	var max_h := viewport_h * MAX_VIEWPORT_HEIGHT_RATIO
	_panel.custom_minimum_size = Vector2(0.0, 0.0)
	_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	if _panel.size.y > max_h + 1.0:
		_panel.offset_top = -max_h
	if _label != null:
		_label.clip_text = false
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _update_visibility(alpha: float) -> void:
	if _panel == null:
		return
	var show_panel := alpha > 0.01 and not _suppressed
	_panel.visible = show_panel
	_panel.modulate.a = clampf(alpha, 0.0, 1.0)
	visible = true
