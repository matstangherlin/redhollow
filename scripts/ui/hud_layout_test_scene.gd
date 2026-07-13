extends Control

## Isolated HUD layout test — mock vitals/style/objective without full gameplay shell.

@onready var _style_hud: StyleHudV2 = $HudV2/StyleHudV2
@onready var _objective_hud: ObjectiveHudV2 = $HudV2/ObjectiveHudV2
@onready var _tutorial: ControlsTutorialOverlay = $HudV2/ControlsTutorial
@onready var _scenario_label: Label = %ScenarioLabel

var _mock_health: float = 12.0
var _mock_brand: float = 40.0
var _scenario_index: int = 0

const SCENARIOS: Array[String] = [
	"exploração",
	"combate",
	"vida baixa",
	"Red Brand cheia",
	"objetivo atualizado",
	"resolução pequena (sim)",
]


func _ready() -> void:
	$HudV2.set_shell_visible(true)
	_apply_mock_state()
	_update_scenario_label()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_SPACE:
			_cycle_scenario()
		KEY_H:
			_tutorial.show_reference(true)
		KEY_O:
			_objective_hud.update_objective("test", "Objetivo", "Investigue o saloon ao norte.")
		KEY_C:
			_style_hud.set_combat_highlight(true)


func _cycle_scenario() -> void:
	_scenario_index = (_scenario_index + 1) % SCENARIOS.size()
	match SCENARIOS[_scenario_index]:
		"exploração":
			_mock_health = 12.0
			_mock_brand = 25.0
			_style_hud.set_combat_highlight(false)
		"combate":
			_style_hud.set_combat_highlight(true)
		"vida baixa":
			_mock_health = 3.0
		"Red Brand cheia":
			_mock_brand = 100.0
		"objetivo atualizado":
			_objective_hud.update_objective("test", "Novo marco", "Retorne à igreja antes do anoitecer.")
		"resolução pequena (sim)":
			scale = Vector2(0.85, 0.85)
	_apply_mock_state()
	_update_scenario_label()


func _apply_mock_state() -> void:
	_style_hud.preview_vitals(_mock_health, 12.0, _mock_brand)
	if _style_hud.rank_label != null:
		_style_hud.rank_label.text = "IRON"
	if _style_hud.score_label != null:
		_style_hud.score_label.text = "128"
	if _style_hud.multiplier_label != null:
		_style_hud.multiplier_label.text = "x1.25"
	if _style_hud.progress_bar != null:
		_style_hud.progress_bar.value = 42.0


func _update_scenario_label() -> void:
	if _scenario_label != null:
		_scenario_label.text = (
			"HUD Layout Test — cenário: %s | Espaço cicla | H tutorial | O objetivo | C combate"
			% SCENARIOS[_scenario_index]
		)
