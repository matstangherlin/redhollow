extends RefCounted
class_name WorldGraphFactory

const CHAPTER_ZERO := &"chapter_zero_bell_before_nightfall"

const SCENE_STREET := "res://scenes/areas/vertical_slice_street.tscn"
const SCENE_CHURCH := "res://scenes/areas/vertical_slice_church.tscn"
const SCENE_UNDERGROUND := "res://scenes/areas/vertical_slice_underground.tscn"


static func create_beta_graph() -> WorldGraphData:
	var graph := WorldGraphData.new()
	graph.graph_id = &"beta_chapter_zero"
	graph.manifest_id = &"beta_demo"
	graph.display_name = "Capítulo Zero — Beta"
	populate_for_manifest("beta_demo", graph)
	return graph


static func create_full_graph() -> WorldGraphData:
	var graph := WorldGraphData.new()
	graph.graph_id = &"full_game_world"
	graph.manifest_id = &"full_game"
	graph.display_name = "Red Hollow — Mapa completo"
	populate_for_manifest("full_game", graph)
	return graph


static func populate_for_manifest(manifest_id: String, graph: WorldGraphData) -> void:
	graph.nodes = _build_nodes(manifest_id == "full_game")
	graph.connections = _build_connections(manifest_id == "full_game")


static func _build_nodes(include_future: bool) -> Array[AreaData]:
	var nodes: Array[AreaData] = []
	nodes.append(_playable_node(
		&"vs_greybox_street", "Centro", SCENE_STREET, Vector2i(1, 2), &"street", 10,
		[], ["cz_street_statue", "cz_partner_clue", "cz_duo_gate"], []
	))
	nodes.append(_playable_node(
		&"vs_greybox_church", "Distrito da Igreja", SCENE_CHURCH, Vector2i(3, 2), &"church", 20,
		["vs_church_checkpoint"], ["cz_church_shortcut"], ["vs_church_red_brand_passage"]
	))
	nodes.append(_playable_node(
		&"vs_greybox_underground", "Catacumbas", SCENE_UNDERGROUND, Vector2i(3, 4), &"underground", 30,
		["vs_underground_checkpoint"], ["cz_partner_evidence"], []
	))

	if not include_future:
		return nodes

	nodes.append(_locked_node(&"region_train_station", "Estação Ferroviária", Vector2i(5, 2), &"industrial"))
	nodes.append(_locked_node(&"region_prison", "Prisão", Vector2i(6, 3), &"industrial"))
	nodes.append(_locked_node(&"region_black_market", "Mercado Clandestino", Vector2i(2, 3), &"street"))
	nodes.append(_locked_node(&"region_cemetery", "Cemitério", Vector2i(4, 1), &"church"))
	nodes.append(_locked_node(&"region_vermilite_mine", "Mina Vermilite", Vector2i(6, 4), &"mine"))
	nodes.append(_locked_node(&"region_industrial_complex", "Complexo Industrial", Vector2i(7, 3), &"industrial"))
	nodes.append(_locked_node(&"region_magnus_mansion", "Mansão de Magnus", Vector2i(8, 2), &"mansion"))
	nodes.append(_locked_node(&"region_crimson_church", "Igreja Rubra", Vector2i(5, 4), &"corrupted"))
	nodes.append(_locked_node(&"region_crimson_palace", "Palácio Rubro", Vector2i(9, 3), &"corrupted"))
	nodes.append(_locked_node(&"region_underground_altar", "Altar Subterrâneo", Vector2i(4, 5), &"corrupted"))
	return nodes


static func _build_connections(include_future: bool) -> Array[AreaConnectionData]:
	var connections: Array[AreaConnectionData] = []
	connections.append(_edge(&"street_to_church", &"vs_greybox_street", &"vs_greybox_church", &"to_church", &"default"))
	connections.append(_edge(&"church_to_street", &"vs_greybox_church", &"vs_greybox_street", &"to_street", &"default"))
	connections.append(_edge(&"church_to_underground", &"vs_greybox_church", &"vs_greybox_underground", &"to_underground", &"default", &"", &"cz_underground_reached"))
	connections.append(_edge(&"underground_to_church", &"vs_greybox_underground", &"vs_greybox_church", &"to_church_entrance", &"default"))
	connections.append(_edge(&"church_shortcut_street", &"vs_greybox_church", &"vs_greybox_street", &"shortcut_to_street", &"default", &"", &"cz_church_shortcut_unlocked", true, false))
	connections.append(_edge(&"street_secret_alley", &"vs_greybox_street", &"vs_greybox_street", &"duo_gate", &"default", &"", &"cz_duo_encounter_cleared", true, true))

	if not include_future:
		return connections

	# Future regions registered without playable edges (no false paths).
	return connections


static func _playable_node(
	area_id: StringName,
	display_name: String,
	scene_path: String,
	map_position: Vector2i,
	visual_category: StringName,
	sort_order: int,
	checkpoints: Array,
	secrets: Array,
	barriers: Array
) -> AreaData:
	var node := AreaData.new()
	node.area_id = area_id
	node.display_name = display_name
	node.chapter_id = CHAPTER_ZERO
	node.scene_path = scene_path
	node.map_position = map_position
	node.visual_category = visual_category
	node.sort_order = sort_order
	node.is_graph_node = true
	node.is_playable_in_build = true
	node.checkpoint_ids = PackedStringArray(checkpoints)
	if checkpoints.size() > 0:
		node.primary_checkpoint_id = StringName(checkpoints[0])
	node.secret_ids = PackedStringArray(secrets)
	node.barrier_ids = PackedStringArray(barriers)
	node.optional_completion_percent = -1.0
	return node


static func _locked_node(
	area_id: StringName,
	display_name: String,
	map_position: Vector2i,
	visual_category: StringName
) -> AreaData:
	var node := AreaData.new()
	node.area_id = area_id
	node.display_name = display_name
	node.chapter_id = CHAPTER_ZERO
	node.scene_path = ""
	node.map_position = map_position
	node.visual_category = visual_category
	node.is_graph_node = true
	node.is_playable_in_build = false
	return node


static func _edge(
	connection_id: StringName,
	from_id: StringName,
	to_id: StringName,
	exit_id: StringName,
	spawn_id: StringName,
	ability_id: StringName = &"",
	flag_id: StringName = &"",
	is_shortcut: bool = false,
	is_secret: bool = false
) -> AreaConnectionData:
	var connection := AreaConnectionData.new()
	connection.connection_id = connection_id
	connection.from_area_id = from_id
	connection.to_area_id = to_id
	connection.from_exit_id = exit_id
	connection.to_spawn_id = spawn_id
	connection.required_ability_id = ability_id
	connection.required_flag = flag_id
	connection.is_shortcut = is_shortcut
	connection.is_secret_passage = is_secret
	connection.is_playable_edge = true
	connection.is_blocked_display = flag_id != &""
	return connection
