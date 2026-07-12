extends StaticBody2D
class_name CombatArenaGate

@export var gate_visual_path: NodePath

var _visual: CanvasItem = null
var _closed: bool = false


func _ready() -> void:
	_visual = get_node_or_null(gate_visual_path) as CanvasItem
	set_closed(false)


func set_closed(closed: bool) -> void:
	if _closed == closed:
		return
	_closed = closed
	call_deferred("_apply_closed_state")


func _apply_closed_state() -> void:
	if not is_inside_tree():
		return

	set_collision_layer_value(1, _closed)
	set_collision_mask_value(1, _closed)
	if _visual != null:
		_visual.visible = _closed
	visible = _closed or (_visual != null and _visual.visible)
