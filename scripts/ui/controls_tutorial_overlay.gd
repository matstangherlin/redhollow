extends CanvasLayer
class_name ControlsTutorialOverlay

const CONTROLS_REFERENCE := (
	"A/D mover  |  Espaço pular  |  J atacar  |  K esquivar  |  L counter\n"
	+ "E interagir  |  U Red Brand  |  T provocar  |  M mapa  |  Esc pausa\n"
	+ "R respawn (morto)  |  F8/F9 save/load"
)

@export var intro_visible_seconds: float = 28.0
@export var fade_seconds: float = 0.8
@export var show_on_first_area_only: bool = true

@onready var _panel: PanelContainer = %TutorialPanel
@onready var _label: Label = %TutorialLabel

var _visible_timer: float = 0.0
var _dismissed: bool = false
var _force_visible: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 6
	if _panel != null:
		_panel.add_theme_stylebox_override("panel", HudThemeV2.make_panel_style(5))
	if _label != null:
		_label.text = CONTROLS_REFERENCE
		HudThemeV2.apply_label_muted(_label, 11)
	_visible_timer = intro_visible_seconds
	_update_visibility(1.0)


static func get_controls_reference() -> String:
	return CONTROLS_REFERENCE


func show_reference(force: bool = true) -> void:
	_force_visible = force
	_dismissed = false
	_visible_timer = intro_visible_seconds
	_update_visibility(1.0)


func dismiss() -> void:
	_dismissed = true
	_force_visible = false
	_update_visibility(0.0)


func notify_new_command_unlocked() -> void:
	show_reference(true)


func _process(delta: float) -> void:
	if _force_visible or _dismissed:
		return
	if _visible_timer > 0.0:
		_visible_timer = maxf(_visible_timer - delta, 0.0)
		if _visible_timer <= fade_seconds:
			_update_visibility(_visible_timer / fade_seconds)
		if _visible_timer <= 0.0:
			_dismissed = true
			_update_visibility(0.0)


func _update_visibility(alpha: float) -> void:
	if _panel == null:
		return
	_panel.visible = alpha > 0.01
	_panel.modulate.a = clampf(alpha, 0.0, 1.0)
