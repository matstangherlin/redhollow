extends Node
class_name StreetVisualModeController

## Cycles greybox → north_star → final_candidate for street art tests.

signal visual_mode_changed(mode: StringName)

const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")

@export var target_area_path: NodePath
@export var toggle_action: StringName = &"debug_toggle"

var _area: StreetArtArea = null
var _mode: StringName = Spec.MODE_NORTH_STAR


func _ready() -> void:
	_area = get_node_or_null(target_area_path) as StreetArtArea
	if _area != null:
		_mode = _area.get_presentation_mode()
		_area.set_presentation_mode(_mode)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(toggle_action):
		return
	cycle_mode()
	get_viewport().set_input_as_handled()


func cycle_mode() -> void:
	if _area == null:
		_mode = Spec.next_mode(_mode)
	else:
		_mode = _area.cycle_presentation_mode()
	visual_mode_changed.emit(_mode)


func toggle_mode() -> void:
	## Legacy binary toggle: greybox ↔ north_star.
	if _mode == Spec.MODE_GREYBOX:
		_mode = Spec.MODE_NORTH_STAR
	else:
		_mode = Spec.MODE_GREYBOX
	if _area != null:
		_area.set_presentation_mode(_mode)
	visual_mode_changed.emit(_mode)


func is_art_mode() -> bool:
	return _mode != Spec.MODE_GREYBOX


func get_mode() -> StringName:
	return _mode
