extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const ContentRegistryScript := preload("res://scripts/content/content_registry.gd")
const AreaTransitionManagerScript := preload("res://scripts/world/area_transition_manager.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const StreetScene := preload("res://scenes/areas/vertical_slice_street_art.tscn")
const ChurchScene := preload("res://scenes/areas/vertical_slice_church_art.tscn")

const BETA_MANIFEST := "res://resources/content/manifests/beta_demo.tres"
const FULL_MANIFEST := "res://resources/content/manifests/full_game.tres"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "world_map_graph_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_beta_graph_nodes(failures)
	_test_full_graph_future_nodes(failures)
	_test_no_false_future_edges(failures)
	_test_discovery_and_visit(failures)
	await _test_transition_backtracking(failures)
	_test_ability_blocked_connection(failures)
	_test_save_roundtrip(failures)
	_test_objective_hint(failures)
	_test_hidden_undiscovered_nodes(failures)
	_test_manifest_graph_paths(failures)

	ContentRegistryScript.clear_active()
	suite.finish(failures, 10)


func _test_beta_graph_nodes(failures: PackedStringArray) -> void:
	var registry := ContentRegistryScript.activate_from_path(BETA_MANIFEST)
	var graph := registry.get_world_graph()
	if graph.get_playable_nodes().size() != 3:
		failures.append("Beta graph should expose exactly 3 playable nodes.")
	if graph.get_node(&"vs_greybox_street") == null:
		failures.append("Beta graph missing street node.")
	if graph.get_node(&"vs_greybox_street").map_position == Vector2i.ZERO:
		failures.append("Street node should define map coordinates.")


func _test_full_graph_future_nodes(failures: PackedStringArray) -> void:
	var registry := ContentRegistryScript.activate_from_path(FULL_MANIFEST)
	var graph := registry.get_world_graph()
	if graph.nodes.size() < 13:
		failures.append("Full graph should register 13 main region nodes.")
	var locked := graph.get_node(&"region_crimson_palace")
	if locked == null or locked.is_playable_in_graph():
		failures.append("Palácio Rubro should be a locked graph node without scene.")


func _test_no_false_future_edges(failures: PackedStringArray) -> void:
	var graph := WorldGraphFactory.create_full_graph()
	for connection in graph.connections:
		if connection == null:
			continue
		var target := graph.get_node(connection.to_area_id)
		if target != null and not target.is_playable_in_graph() and connection.is_playable_edge:
			failures.append(
				"Future node %s should not have playable edge yet: %s"
				% [String(target.area_id), String(connection.connection_id)]
			)


func _test_discovery_and_visit(failures: PackedStringArray) -> void:
	var progression := ProgressionComponent.new()
	var service := WorldMapService.new()
	var graph := WorldGraphFactory.create_beta_graph()
	service.bind(graph, progression, null)

	service.on_area_entered(&"vs_greybox_street")
	if not progression.world_map_state.is_discovered(&"vs_greybox_street"):
		failures.append("Entering street should discover street.")
	if not progression.world_map_state.is_visited(&"vs_greybox_street"):
		failures.append("Entering street should mark visited.")

	service.on_area_entered(&"vs_greybox_church")
	if not progression.world_map_state.is_visited(&"vs_greybox_church"):
		failures.append("Entering church should mark visited.")


func _test_transition_backtracking(failures: PackedStringArray) -> void:
	var game_root := Node.new()
	get_tree().root.add_child(game_root)

	var world_host := Node2D.new()
	world_host.name = "WorldHost"
	game_root.add_child(world_host)

	var player: CharacterBody2D = PlayerScene.instantiate()
	game_root.add_child(player)

	var progression := ProgressionComponent.new()
	progression.set_narrative_flag(&"cz_met_elias", true)
	game_root.add_child(progression)

	var map_service := WorldMapService.new()
	game_root.add_child(map_service)

	var manager: AreaTransitionManager = AreaTransitionManagerScript.new()
	manager.world_host_path = NodePath("../WorldHost")
	manager.player_path = NodePath("../Player")
	manager.initial_area_scene = StreetScene
	manager.transition_pause_seconds = 0.01
	game_root.add_child(manager)

	ContentRegistryScript.activate_from_path(BETA_MANIFEST)
	map_service.bind(ContentRegistryScript.get_active().get_world_graph(), progression, manager)

	await TestHelpers.await_frames(get_tree(), 2)
	manager.initialize(game_root)
	await get_tree().create_timer(0.05).timeout

	var street := manager.get_current_area()
	var exit: AreaExit = street.get_node_or_null("Exits/ToChurchExit") as AreaExit
	if exit == null:
		failures.append("Street exit to church missing for backtracking test.")
	else:
		manager.request_transition(exit, player)
		await get_tree().create_timer(0.05).timeout
		if manager.get_current_area_id() != &"vs_greybox_church":
			failures.append("Transition street -> church failed.")

		var church := manager.get_current_area()
		var return_exit: AreaExit = church.get_node_or_null("Exits/ToStreetExit") as AreaExit
		if return_exit != null:
			manager.request_transition(return_exit, player)
			await get_tree().create_timer(0.05).timeout
			if manager.get_current_area_id() != &"vs_greybox_street":
				failures.append("Backtracking church -> street failed.")

	game_root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_ability_blocked_connection(failures: PackedStringArray) -> void:
	var graph := WorldGraphFactory.create_beta_graph()
	var connection := graph.get_connections_between(&"vs_greybox_church", &"vs_greybox_underground")[0]
	var progression := ProgressionComponent.new()
	if connection.is_available(progression):
		failures.append("Church -> underground should require progression flag.")
	progression.set_narrative_flag(&"cz_underground_reached", true)
	if not connection.is_available(progression):
		failures.append("Underground connection should open after required flag.")


func _test_save_roundtrip(failures: PackedStringArray) -> void:
	var progression := ProgressionComponent.new()
	progression.world_map_state.mark_discovered(&"vs_greybox_street")
	progression.world_map_state.mark_visited(&"vs_greybox_street")
	progression.world_map_state.mark_secret(&"cz_partner_clue")
	progression.world_map_state.current_area_id = &"vs_greybox_street"

	var exported := progression.export_save_state()
	var clone := ProgressionComponent.new()
	clone.import_save_state(exported)

	if not clone.world_map_state.is_visited(&"vs_greybox_street"):
		failures.append("World map visit state lost on save roundtrip.")
	if not clone.world_map_state.found_secrets.has("cz_partner_clue"):
		failures.append("World map secret state lost on save roundtrip.")


func _test_objective_hint(failures: PackedStringArray) -> void:
	var service := WorldMapService.new()
	service.set_objective_from_id("cz_obj_church")
	if service._get_map_state().objective_area_id != &"vs_greybox_church":
		failures.append("Objective hint should map church objective to church area.")


func _test_hidden_undiscovered_nodes(failures: PackedStringArray) -> void:
	var progression := ProgressionComponent.new()
	var service := WorldMapService.new()
	service.bind(WorldGraphFactory.create_beta_graph(), progression, null)
	progression.world_map_state.mark_discovered(&"vs_greybox_street")

	var visible := service.get_visible_nodes()
	if visible.size() != 1:
		failures.append("Only discovered areas should be visible on map.")
	if visible[0].area_id != &"vs_greybox_street":
		failures.append("Visible node should be discovered street only.")


func _test_manifest_graph_paths(failures: PackedStringArray) -> void:
	var beta := ContentRegistryScript.activate_from_path(BETA_MANIFEST)
	if beta.get_world_graph().manifest_id != &"beta_demo":
		failures.append("Beta registry should load beta world graph.")
	var full := ContentRegistryScript.activate_from_path(FULL_MANIFEST)
	if full.get_world_graph().nodes.size() < 13:
		failures.append("Full manifest should load expanded world graph.")
