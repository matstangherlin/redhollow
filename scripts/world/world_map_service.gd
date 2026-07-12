extends Node
class_name WorldMapService

## Tracks discovered areas and feeds the provisional world map UI.

signal map_state_changed()
signal area_discovered(area_id: StringName)
signal area_visited(area_id: StringName)

const SERVICE_GROUP := "world_map_service"

const OBJECTIVE_AREA_HINTS: Dictionary = {
	"cz_obj_opening": &"vs_greybox_street",
	"cz_obj_street": &"vs_greybox_street",
	"cz_obj_gunslinger": &"vs_greybox_street",
	"cz_obj_duo": &"vs_greybox_street",
	"cz_obj_church": &"vs_greybox_church",
	"cz_obj_red_brand": &"vs_greybox_church",
	"cz_obj_barrier": &"vs_greybox_church",
	"cz_obj_underground": &"vs_greybox_underground",
	"cz_obj_rusk": &"vs_greybox_underground",
}

var world_map: WorldMapState = WorldMapState.new()

var _graph: WorldGraphData = null
var _progression: ProgressionComponent = null
var _transition_manager: AreaTransitionManager = null
var _uses_progression_state: bool = false


func _ready() -> void:
	add_to_group(SERVICE_GROUP)


func bind(
	graph: WorldGraphData,
	progression: ProgressionComponent,
	transition_manager: AreaTransitionManager = null
) -> void:
	_graph = graph
	_progression = progression
	_transition_manager = transition_manager
	if _progression != null:
		world_map = _progression.world_map_state
		_uses_progression_state = true
	_connect_transition_signals()
	_seed_starting_discovery()


func _get_map_state() -> WorldMapState:
	if _uses_progression_state and _progression != null:
		return _progression.world_map_state
	return world_map


func get_graph() -> WorldGraphData:
	if _graph == null:
		_graph = WorldGraphFactory.create_beta_graph()
	return _graph


func export_save_state() -> Dictionary:
	return _get_map_state().export_dict()


func import_save_state(state: Dictionary) -> void:
	_get_map_state().import_dict(state)
	map_state_changed.emit()


func reset_for_demo() -> void:
	_get_map_state().reset()
	_seed_starting_discovery()


func on_area_entered(area_id: StringName) -> void:
	if area_id == &"":
		return

	var map_state := _get_map_state()
	map_state.current_area_id = area_id
	map_state.mark_visited(area_id)
	_discover_neighbors(area_id)
	_sync_secrets_and_barriers_from_progression()
	map_state_changed.emit()
	area_visited.emit(area_id)


func on_secret_found(secret_id: StringName) -> void:
	_get_map_state().mark_secret(secret_id)
	map_state_changed.emit()


func on_shortcut_unlocked(shortcut_id: StringName) -> void:
	_get_map_state().mark_shortcut(shortcut_id)
	map_state_changed.emit()


func on_barrier_known(barrier_id: StringName) -> void:
	_get_map_state().mark_barrier(barrier_id)
	map_state_changed.emit()


func set_objective_area(area_id: StringName) -> void:
	_get_map_state().objective_area_id = area_id
	map_state_changed.emit()


func set_objective_from_id(objective_id: String) -> void:
	if OBJECTIVE_AREA_HINTS.has(objective_id):
		set_objective_area(OBJECTIVE_AREA_HINTS[objective_id])
	else:
		set_objective_area(&"")


func get_visible_nodes() -> Array[AreaData]:
	var graph := get_graph()
	var map_state := _get_map_state()
	var visible: Array[AreaData] = []
	for node in graph.nodes:
		if node == null:
			continue
		if map_state.is_discovered(node.area_id):
			visible.append(node)
	return visible


func get_node_display_state(area_id: StringName) -> Dictionary:
	var graph := get_graph()
	var map_state := _get_map_state()
	var node := graph.get_node(area_id)
	if node == null:
		return {}

	var destroyed := _is_barrier_destroyed(area_id, node)
	return {
		"area_id": area_id,
		"display_name": node.display_name,
		"map_position": node.map_position,
		"visual_category": node.visual_category,
		"is_current": map_state.current_area_id == area_id,
		"is_visited": map_state.is_visited(area_id),
		"is_discovered": map_state.is_discovered(area_id),
		"is_playable": node.is_playable_in_graph(),
		"has_checkpoint": _has_active_checkpoint(node),
		"is_objective": map_state.objective_area_id == area_id,
		"has_barrier": node.barrier_ids.size() > 0 and not destroyed,
		"secrets_found": _count_found_secrets(node),
		"secrets_total": node.secret_ids.size(),
	}


func get_visible_connections() -> Array[AreaConnectionData]:
	var graph := get_graph()
	var map_state := _get_map_state()
	var visible: Array[AreaConnectionData] = []
	for connection in graph.connections:
		if connection == null:
			continue
		if not map_state.is_discovered(connection.from_area_id):
			continue
		if not map_state.is_discovered(connection.to_area_id):
			continue
		visible.append(connection)
	return visible


func _seed_starting_discovery() -> void:
	var registry := ContentRegistry.get_active()
	if registry != null:
		var chapter := registry.get_starting_chapter()
		if chapter != null:
			var start_area := chapter.get_starting_area()
			if start_area != null:
				_get_map_state().mark_discovered(start_area.area_id)
				return
	_get_map_state().mark_discovered(&"vs_greybox_street")


func _discover_neighbors(area_id: StringName) -> void:
	var graph := get_graph()
	var map_state := _get_map_state()
	for connection in graph.get_connections_from(area_id):
		if connection == null or not connection.is_playable_edge:
			continue
		var target := graph.get_node(connection.to_area_id)
		if target == null or not target.is_playable_in_graph():
			continue
		if connection.is_secret_passage and not map_state.found_secrets.has(String(connection.required_flag)):
			continue
		map_state.mark_discovered(connection.to_area_id)


func _sync_secrets_and_barriers_from_progression() -> void:
	if _progression == null:
		return

	var graph := get_graph()
	for node in graph.nodes:
		if node == null:
			continue
		for secret_id in node.secret_ids:
			if bool(_progression.narrative_flags.get(String(secret_id), false)):
				_get_map_state().mark_secret(secret_id)
		for barrier_id in node.barrier_ids:
			_get_map_state().mark_barrier(barrier_id)


func _has_active_checkpoint(node: AreaData) -> bool:
	if _progression == null or node == null:
		return false
	if node.primary_checkpoint_id == &"":
		return false
	return String(_progression.active_checkpoint_id) == String(node.primary_checkpoint_id)


func _count_found_secrets(node: AreaData) -> int:
	var count := 0
	var map_state := _get_map_state()
	for secret_id in node.secret_ids:
		if map_state.found_secrets.has(String(secret_id)):
			count += 1
	return count


func _is_barrier_destroyed(_area_id: StringName, node: AreaData) -> bool:
	if node.barrier_ids.is_empty():
		return true
	var registry := _find_barrier_registry()
	if registry == null:
		return false
	for barrier_id in node.barrier_ids:
		if not registry.is_destroyed(StringName(String(barrier_id))):
			return false
	return true


func _find_barrier_registry() -> BarrierRegistry:
	if not is_inside_tree():
		return null
	for node in get_tree().get_nodes_in_group("barrier_registry"):
		if node is BarrierRegistry:
			return node as BarrierRegistry
	return null


func _connect_transition_signals() -> void:
	if _transition_manager == null:
		return
	if not _transition_manager.area_loaded.is_connected(_on_area_loaded):
		_transition_manager.area_loaded.connect(_on_area_loaded)
	if not _transition_manager.transition_finished.is_connected(_on_transition_finished):
		_transition_manager.transition_finished.connect(_on_transition_finished)


func _on_area_loaded(area: AreaRoot) -> void:
	if area != null:
		on_area_entered(area.area_id)


func is_connection_available(connection: AreaConnectionData) -> bool:
	return connection != null and connection.is_available(_progression)


func _on_transition_finished(_area_id: StringName, _spawn_id: StringName) -> void:
	map_state_changed.emit()
