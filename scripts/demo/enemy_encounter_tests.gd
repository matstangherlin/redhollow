extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const VS_STREET := "res://scenes/areas/vertical_slice_street.tscn"
const VS_CHURCH := "res://scenes/areas/vertical_slice_church.tscn"
const VS_UNDERGROUND := "res://scenes/areas/vertical_slice_underground.tscn"


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "enemy_encounter_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_street_encounters(failures)
	_test_church_encounters(failures)
	_test_underground_boss(failures)
	_test_arena_spawn_points(failures)

	suite.finish(failures, 4)


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
	underground.queue_free()


func _test_arena_spawn_points(failures: PackedStringArray) -> void:
	var arena_scene := load("res://scenes/world/combat_arena.tscn") as PackedScene
	var arena := arena_scene.instantiate()
	var spawn_paths: Array = arena.get("enemy_spawn_paths")
	if spawn_paths.size() < 3:
		failures.append("Combined arena should spawn three enemy types.")
	arena.queue_free()
