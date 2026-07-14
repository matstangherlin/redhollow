extends StaticBody2D
class_name CombatArenaGate

signal closed_state_applied(closed: bool)

@export var gate_visual_path: NodePath

var _visual: CanvasItem = null
var _requested_closed: bool = false
var _applied_closed: bool = false
var _apply_scheduled: bool = false


func _ready() -> void:
	_visual = get_node_or_null(gate_visual_path) as CanvasItem
	set_closed(false)


func set_closed(closed: bool) -> void:
	_requested_closed = closed
	_schedule_apply()


func is_closed() -> bool:
	return _requested_closed


func is_physics_closed() -> bool:
	return _applied_closed


func _schedule_apply() -> void:
	if _apply_scheduled:
		return
	_apply_scheduled = true
	call_deferred("_apply_requested_state")


func _apply_requested_state() -> void:
	_apply_scheduled = false
	if not is_inside_tree():
		return

	var target_closed := _requested_closed
	set_collision_layer_value(1, target_closed)
	set_collision_mask_value(1, target_closed)
	if _visual != null:
		_visual.visible = target_closed
	visible = target_closed or (_visual != null and _visual.visible)
	_applied_closed = target_closed
	closed_state_applied.emit(target_closed)

	if _requested_closed != _applied_closed:
		_schedule_apply()
