extends Resource
class_name WorldGraphData

## Interconnected world graph for a product profile (beta or full game).

@export var graph_id: StringName = &""
@export var manifest_id: StringName = &""
@export var display_name: String = ""
@export var nodes: Array[AreaData] = []
@export var connections: Array[AreaConnectionData] = []


func ensure_built_in() -> void:
	if not nodes.is_empty():
		return
	WorldGraphFactory.populate_for_manifest(String(manifest_id), self)


func get_node(area_id: StringName) -> AreaData:
	ensure_built_in()
	for node in nodes:
		if node != null and node.area_id == area_id:
			return node
	return null


func get_playable_nodes() -> Array[AreaData]:
	ensure_built_in()
	var playable: Array[AreaData] = []
	for node in nodes:
		if node != null and node.is_playable_in_graph():
			playable.append(node)
	return playable


func get_connections_from(area_id: StringName) -> Array[AreaConnectionData]:
	ensure_built_in()
	var result: Array[AreaConnectionData] = []
	for connection in connections:
		if connection != null and connection.from_area_id == area_id:
			result.append(connection)
	return result


func get_connections_between(from_id: StringName, to_id: StringName) -> Array[AreaConnectionData]:
	ensure_built_in()
	var result: Array[AreaConnectionData] = []
	for connection in connections:
		if connection == null:
			continue
		if connection.from_area_id == from_id and connection.to_area_id == to_id:
			result.append(connection)
	return result
