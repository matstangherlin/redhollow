extends StaticBody2D
class_name CombatArenaGate

@export var gate_visual_path: NodePath

var _visual: CanvasItem = null


func _ready() -> void:
	_visual = get_node_or_null(gate_visual_path) as CanvasItem
	set_closed(false)


func set_closed(closed: bool) -> void:
	set_collision_layer_value(1, closed)
	set_collision_mask_value(1, closed)
	if _visual != null:
		_visual.visible = closed
	visible = closed or (_visual != null and _visual.visible)
