extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const STREET_KIT := preload("res://resources/environment/kits/chapter_zero_street_kit.tres")
const ROOM_A := preload("res://scenes/environment/modular/kit_room_saloon_front.tscn")
const ROOM_B := preload("res://scenes/environment/modular/kit_room_alley_corner.tscn")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "modular_kit_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_kit_modules(failures)
	_test_tile_contract(failures)
	_test_prop_catalog(failures)
	await _test_room_a_validation(failures)
	await _test_room_b_validation(failures)
	await _test_room_reuse(failures)
	_test_region_stubs(failures)

	suite.finish(failures, 7)


func _test_kit_modules(failures: PackedStringArray) -> void:
	var kit := EnvironmentKitFactory.create_street_kit()
	var required: PackedStringArray = PackedStringArray([
		"dirt_ground", "wood_sidewalk", "platform", "roof", "wall_wood", "wall_stone",
		"door", "window", "balcony", "lamp_post", "fence", "barrel", "crate", "wagon",
		"sign", "lantern", "stairs", "blocked_entrance", "secret_passage", "vermilite_barrier",
	])
	for module_id in required:
		if kit.get_module(StringName(module_id)) == null:
			failures.append("Street kit missing module: %s." % module_id)


func _test_tile_contract(failures: PackedStringArray) -> void:
	var kit := EnvironmentKitFactory.create_street_kit()
	if kit.tile_size_px != 16:
		failures.append("Tile size must remain 16px.")
	if kit.get_tile_spec(&"dirt_ground") == null:
		failures.append("Street kit missing dirt_ground tile spec.")
	if kit.get_tile_spec(&"autotile_stone_wall") == null:
		failures.append("Street kit missing autotile spec.")


func _test_prop_catalog(failures: PackedStringArray) -> void:
	var catalog := PropCatalog.new()
	catalog.ensure_built_in()
	if catalog.get_entry(&"lantern") == null:
		failures.append("Prop catalog missing lantern entry.")
	if catalog.get_entry(&"vermilite_barrier") == null:
		failures.append("Prop catalog missing vermilite_barrier entry.")


func _test_room_a_validation(failures: PackedStringArray) -> void:
	var room: KitModularRoom = ROOM_A.instantiate()
	get_tree().root.add_child(room)
	await TestHelpers.await_frames(get_tree(), 2)

	var report := EnvironmentKitValidator.validate_area(room)
	if not bool(report.get("passed", false)):
		for issue in report.get("failures", PackedStringArray()):
			failures.append("Saloon room validation: %s" % issue)

	if room.get_node_or_null("Solids/Ground") == null:
		failures.append("Saloon room missing ground collision.")

	room.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_room_b_validation(failures: PackedStringArray) -> void:
	var room: KitModularRoom = ROOM_B.instantiate()
	get_tree().root.add_child(room)
	await TestHelpers.await_frames(get_tree(), 2)

	var report := EnvironmentKitValidator.validate_area(room)
	if not bool(report.get("passed", false)):
		for issue in report.get("failures", PackedStringArray()):
			failures.append("Alley room validation: %s" % issue)

	var exit: AreaExit = room.get_node_or_null("Exits/ToSaloon") as AreaExit
	if exit == null:
		failures.append("Alley room missing exit to saloon.")

	room.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_room_reuse(failures: PackedStringArray) -> void:
	var room_a: KitModularRoom = ROOM_A.instantiate()
	var room_b: KitModularRoom = ROOM_B.instantiate()
	get_tree().root.add_child(room_a)
	get_tree().root.add_child(room_b)
	await TestHelpers.await_frames(get_tree(), 2)

	var markers_a := room_a.find_children("*", "EnvironmentModuleInstance", true, false).size()
	var markers_b := room_b.find_children("*", "EnvironmentModuleInstance", true, false).size()
	if markers_a < 8:
		failures.append("Saloon room should place multiple kit modules.")
	if markers_b < 8:
		failures.append("Alley room should place multiple kit modules.")

	var shared := 0
	for node in room_a.find_children("*", "ArtPlaceholderSlot", true, false):
		for other in room_b.find_children("*", "ArtPlaceholderSlot", true, false):
			if node.name == other.name:
				shared += 1
	if shared < 3:
		failures.append("Rooms should reuse kit module types (barrel, crate, lantern, etc.).")

	room_a.queue_free()
	room_b.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)


func _test_region_stubs(failures: PackedStringArray) -> void:
	var stubs := RegionVisualTheme.get_future_region_stubs()
	if stubs.size() < 8:
		failures.append("Future region stubs should document at least 8 districts.")
	if String(stubs[0].get("id", "")) != "centro":
		failures.append("First future region stub should be centro.")
