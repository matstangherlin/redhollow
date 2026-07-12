extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const AreaTransitionManagerScript := preload("res://scripts/world/area_transition_manager.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const CameraScene := preload("res://scenes/core/camera_controller.tscn")
const StreetScene := preload("res://scenes/areas/street_test.tscn")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "area_transition_tests")
	var failures: PackedStringArray = PackedStringArray()

	var game_root := Node.new()
	game_root.name = "GameRoot"
	root.add_child(game_root)

	var world_host := Node2D.new()
	world_host.name = "WorldHost"
	game_root.add_child(world_host)

	var player: Node = PlayerScene.instantiate()
	player.name = "Player"
	game_root.add_child(player)

	var camera: Node = CameraScene.instantiate()
	camera.name = "CameraController"
	camera.set("target_path", NodePath("../Player"))
	game_root.add_child(camera)

	await TestHelpers.mount_dialogue_system(game_root, get_tree())
	await TestHelpers.mount_progression(game_root, get_tree())
	await TestHelpers.await_frames(get_tree(), 2)

	var manager: Node = AreaTransitionManagerScript.new()
	manager.name = "AreaTransitionManager"
	manager.world_host_path = NodePath("../WorldHost")
	manager.player_path = NodePath("../Player")
	manager.camera_controller_path = NodePath("../CameraController")
	manager.initial_area_scene = StreetScene
	manager.initial_spawn_id = &"default"
	manager.transition_pause_seconds = 0.01
	game_root.add_child(manager)

	await TestHelpers.await_frames(get_tree(), 2)
	manager.initialize(game_root)
	await get_tree().create_timer(0.05).timeout

	_test_initial_spawn(failures, manager, player)
	await _test_street_to_church_async(failures, manager, player)
	await _test_church_return_async(failures, manager, player)
	_test_camera_limits(failures, manager, camera)
	_test_persistent_health(failures, player)
	await _test_underground_transition_async(failures, manager, player)

	game_root.queue_free()

	suite.finish(failures, 6)


func _test_initial_spawn(failures: PackedStringArray, manager: Node, player: Node) -> void:
	var area: Node = manager.get_current_area()
	if area == null or String(area.get("area_id")) != "street_test":
		failures.append("Initial area should be street_test.")

	if player.global_position.distance_to(Vector2(120, 848)) > 4.0:
		failures.append("Initial spawn position mismatch on street_test.")


func _test_street_to_church_async(failures: PackedStringArray, manager: Node, player: Node) -> void:
	var area: Node = manager.get_current_area()
	var exit: AreaExit = _find_exit(area, &"to_church")
	if exit == null:
		failures.append("Street exit to church not found.")
		return

	manager.request_transition(exit, player)
	await get_tree().create_timer(0.05).timeout

	if String(manager.get_current_area_id()) != "church_entrance_test":
		failures.append("Transition to church_entrance_test failed.")

	if player.global_position.distance_to(Vector2(80, 848)) > 4.0:
		failures.append("Church from_street spawn mismatch.")


func _test_church_return_async(failures: PackedStringArray, manager: Node, player: Node) -> void:
	var area: Node = manager.get_current_area()
	var exit: AreaExit = _find_exit(area, &"to_street")
	if exit == null:
		failures.append("Church return exit not found.")
		return

	manager.request_transition(exit, player)
	await get_tree().create_timer(0.05).timeout

	if String(manager.get_current_area_id()) != "street_test":
		failures.append("Return transition to street_test failed.")

	if player.global_position.distance_to(Vector2(1280, 848)) > 4.0:
		failures.append("Street from_church spawn mismatch.")


func _test_camera_limits(failures: PackedStringArray, manager: Node, camera: Node) -> void:
	var area: Node = manager.get_current_area()
	var limits: Rect2 = area.get("camera_limits")
	if camera.get("area_limits") != limits:
		failures.append("Camera limits were not updated for current area.")


func _test_persistent_health(failures: PackedStringArray, player: Node) -> void:
	var health := player.get_node_or_null("Components/HealthComponent")
	if health == null:
		failures.append("Player health component missing.")
		return

	health.call("apply_damage", 3.0, null)
	var current_after := float(health.get("current_health"))
	if current_after >= 12.0:
		failures.append("Health damage did not apply during transition test.")


func _test_underground_transition_async(failures: PackedStringArray, manager: Node, player: Node) -> void:
	var to_church := _find_exit(manager.get_current_area(), &"to_church")
	if to_church != null:
		manager.request_transition(to_church, player)
		await get_tree().create_timer(0.05).timeout

	var underground_exit := _find_exit(manager.get_current_area(), &"to_underground")
	if underground_exit == null:
		failures.append("Underground exit not found in church area.")
		return

	manager.request_transition(underground_exit, player)
	await get_tree().create_timer(0.05).timeout

	if String(manager.get_current_area_id()) != "underground_test":
		failures.append("Transition to underground_test failed.")

	if player.global_position.distance_to(Vector2(80, 848)) > 4.0:
		failures.append("Underground from_church_entrance spawn mismatch.")


func _find_exit(area: Node, exit_id: StringName) -> AreaExit:
	if area == null or not area.has_method("get_exits"):
		return null

	for node in area.call("get_exits"):
		if node is AreaExit and node.exit_id == exit_id:
			return node

	return null
