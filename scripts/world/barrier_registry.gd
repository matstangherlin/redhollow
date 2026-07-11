extends Node
class_name BarrierRegistry

signal barrier_destroyed(barrier_id: StringName)
signal registry_reset

const REGISTRY_GROUP := "barrier_registry"
const RED_BARRIER_GROUP := "red_barrier"

var _destroyed_barrier_ids: Dictionary = {}


func _ready() -> void:
	add_to_group(REGISTRY_GROUP)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		reset_registry()


func mark_destroyed(barrier_id: StringName) -> void:
	if barrier_id == &"" or _destroyed_barrier_ids.has(barrier_id):
		return

	_destroyed_barrier_ids[barrier_id] = true
	barrier_destroyed.emit(barrier_id)


func is_destroyed(barrier_id: StringName) -> bool:
	return barrier_id != &"" and _destroyed_barrier_ids.has(barrier_id)


func get_destroyed_barrier_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for barrier_id in _destroyed_barrier_ids.keys():
		ids.append(StringName(barrier_id))
	return ids


func reset_registry() -> void:
	_destroyed_barrier_ids.clear()
	registry_reset.emit()

	for node in get_tree().get_nodes_in_group(RED_BARRIER_GROUP):
		if node.has_method("reset_barrier"):
			node.call("reset_barrier")


func export_destroyed_state() -> Dictionary:
	return _destroyed_barrier_ids.duplicate()


func import_destroyed_state(state: Dictionary) -> void:
	_destroyed_barrier_ids = state.duplicate()

	for node in get_tree().get_nodes_in_group(RED_BARRIER_GROUP):
		if not node.has_method("sync_with_registry"):
			continue
		node.call("sync_with_registry")
