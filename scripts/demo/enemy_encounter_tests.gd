extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const VS_STREET := "res://scenes/areas/vertical_slice_street.tscn"
const VS_CHURCH := "res://scenes/areas/vertical_slice_church.tscn"
const VS_UNDERGROUND := "res://scenes/areas/vertical_slice_underground.tscn"


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "enemy_encounter_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_street_encounters(failures)
	_test_church_encounters(failures)
	_test_underground_boss(failures)
	_test_arena_spawn_points(failures)
	_test_lifecycle_state_contract(failures)
	_test_scene_controller_wiring(failures)

	suite.finish(failures, 6)


func _test_street_encounters(failures: PackedStringArray) -> void:
	var street := (load(VS_STREET) as PackedScene).instantiate()
	for node_path in [
		"WorldObjects/CultBrawlerStreet",
		"WorldObjects/GunslingerOptional",
		"WorldObjects/DuoBrawler",
		"WorldObjects/DuoGunslinger",
		"WorldObjects/MarkedCartridge",
		"WorldObjects/ShortcutGate",
	]:
		if street.get_node_or_null(node_path) == null:
			failures.append("Street missing encounter node: %s." % node_path)
	street.queue_free()


func _test_church_encounters(failures: PackedStringArray) -> void:
	var church := (load(VS_CHURCH) as PackedScene).instantiate()
	for node_path in [
		"WorldObjects/ChainPenitentAlcove",
		"WorldObjects/ChurchYardArena",
		"WorldObjects/RedBrandPassage",
		"WorldObjects/ChurchCheckpoint",
	]:
		if church.get_node_or_null(node_path) == null:
			failures.append("Church missing encounter node: %s." % node_path)
	church.queue_free()


func _test_underground_boss(failures: PackedStringArray) -> void:
	var underground := (load(VS_UNDERGROUND) as PackedScene).instantiate()
	if underground.get_node_or_null("WorldObjects/DeaconRusk") == null:
		failures.append("Underground must keep Deacon Rusk.")
	if underground.get_node_or_null("WorldObjects/DeaconRuskEncounter") == null:
		failures.append("Underground must keep the Deacon Rusk encounter controller.")
	underground.queue_free()


func _test_arena_spawn_points(failures: PackedStringArray) -> void:
	var arena_scene := load("res://scenes/world/combat_arena.tscn") as PackedScene
	var arena := arena_scene.instantiate()
	var spawn_paths: Array = arena.get("enemy_spawn_paths")
	if spawn_paths.size() < 3:
		failures.append("Combined arena should spawn three enemy types.")
	arena.queue_free()


func _test_lifecycle_state_contract(failures: PackedStringArray) -> void:
	var expected_states := [
		"INACTIVE",
		"ACTIVATION_REQUESTED",
		"CLOSING_GATES",
		"SPAWNING",
		"ACTIVE",
		"RESETTING",
		"COMPLETED",
	]
	if Array(CombatArenaController.ArenaState.keys()) != expected_states:
		failures.append("Combat arena lifecycle states do not match the deterministic contract.")
	if Array(BossEncounterController.EncounterState.keys()) != expected_states:
		failures.append("Boss encounter lifecycle states do not match the deterministic contract.")


func _test_scene_controller_wiring(failures: PackedStringArray) -> void:
	var church := (load(VS_CHURCH) as PackedScene).instantiate()
	var arena := church.get_node_or_null("WorldObjects/ChurchYardArena") as CombatArenaController
	if arena == null:
		failures.append("North Star church arena must use CombatArenaController.")
	else:
		if arena.activation_zone_path.is_empty() or arena.gate_paths.is_empty():
			failures.append("North Star church arena must wire activation and gates explicitly.")
		if arena.enemy_spawn_paths.size() != 3:
			failures.append("North Star church arena must retain its three configured spawn points.")
	church.queue_free()

	var underground := (load(VS_UNDERGROUND) as PackedScene).instantiate()
	var encounter := underground.get_node_or_null("WorldObjects/DeaconRuskEncounter") as BossEncounterController
	if encounter == null:
		failures.append("Deacon Rusk arena must use BossEncounterController.")
	else:
		if encounter.activation_zone_path.is_empty() or encounter.gate_paths.is_empty():
			failures.append("Deacon Rusk arena must wire activation and gates explicitly.")
		if underground.find_children("*", "DeaconRusk", true, false).size() != 1:
			failures.append("Deacon Rusk arena must contain exactly one boss instance.")
	underground.queue_free()
