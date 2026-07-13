extends Node
class_name HudShellV2

## Container for HUD V2 presentation layers. Does not replace gameplay systems.

@onready var _style_hud: StyleHudV2 = $StyleHudV2
@onready var _objective_hud: ObjectiveHudV2 = $ObjectiveHudV2
@onready var _tutorial: ControlsTutorialOverlay = $ControlsTutorial


func _ready() -> void:
	set_shell_visible(false)


func get_style_hud() -> StyleHudV2:
	return _style_hud


func get_objective_hud() -> ObjectiveHudV2:
	return _objective_hud


func get_tutorial_overlay() -> ControlsTutorialOverlay:
	return _tutorial


func set_shell_visible(is_visible: bool) -> void:
	if _style_hud != null:
		_style_hud.visible = is_visible
	if _objective_hud != null:
		_objective_hud.visible = is_visible
	if _tutorial != null:
		_tutorial.visible = is_visible
		if is_visible:
			_tutorial.show_reference(false)
		else:
			_tutorial.dismiss()
