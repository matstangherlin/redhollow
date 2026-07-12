extends Node
class_name StreetVisualModeController

## Toggles greybox vs art presentation for street art tests.

signal visual_mode_changed(use_art: bool)

@export var target_area_path: NodePath
@export var toggle_action: StringName = &"debug_toggle"

var _area: StreetArtArea = null
var _use_art: bool = true


func _ready() -> void:
	_area = get_node_or_null(target_area_path) as StreetArtArea
	if _area != null:
		_use_art = _area.show_art_presentation
		_area.set_visual_mode(_use_art)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(toggle_action):
		return
	toggle_mode()
	get_viewport().set_input_as_handled()


func toggle_mode() -> void:
	_use_art = not _use_art
	if _area != null:
		_area.set_visual_mode(_use_art)
	visual_mode_changed.emit(_use_art)


func is_art_mode() -> bool:
	return _use_art
