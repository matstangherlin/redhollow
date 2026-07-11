extends SceneTree

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const VS_MAIN := "res://scenes/demo/vertical_slice_greybox.tscn"
const VS_STREET := "res://scenes/areas/vertical_slice_street.tscn"
const VS_CHURCH := "res://scenes/areas/vertical_slice_church.tscn"
const VS_UNDERGROUND := "res://scenes/areas/vertical_slice_underground.tscn"
const DIALOGUE_PATH := "res://data/dialogues/dialogues_pt_br.json"


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var suite := TestHelpers.begin_suite(self, "vertical_slice_regression_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_main_scene(failures)
	_test_demo_scene_contract(failures)
	_test_player_demo_settings(failures)
	_test_area_chain(failures)
	_test_street_flow_nodes(failures)
	_test_church_flow_nodes(failures)
	_test_underground_flow_nodes(failures)
	_test_dialogue_contract(failures)
	_test_save_player_contract(failures)
	_test_hitstop_and_style_presence(failures)
	_test_gameplay_lock_presence(failures)
	_test_completion_controller(failures)
	_test_player_reset_contract(failures)

	suite.finish(failures, 13)


func _test_main_scene(failures: PackedStringArray) -> void:
	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene != VS_MAIN:
		failures.append("Main scene must remain vertical_slice_greybox for slice regression.")


func _test_demo_scene_contract(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	if demo == null:
		failures.append("vertical_slice_greybox must load.")
		return

	var root := demo.instantiate()
	for path in [
		"VerticalSliceController",
		"VerticalSliceController/CompletionOverlay",
		"%SaveManager",
		"%AreaTransitionManager",
		"HitstopController",
		"GameplayLockManager",
		"StyleManager",
		"Player",
		"CameraController",
	]:
		if root.get_node_or_null(path) == null:
			failures.append("Demo scene missing required node: %s." % path)

	root.queue_free()


func _test_player_demo_settings(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	var root := demo.instantiate()
	var player := root.get_node_or_null("Player")
	if player == null:
		failures.append("Demo Player node missing.")
		root.queue_free()
		return

	if not is_equal_approx(float(player.get("fall_recovery_y")), 1320.0):
		failures.append("Demo player fall_recovery_y must remain 1320.")

	var camera := root.get_node_or_null("CameraController")
	if camera != null and NodePath(String(camera.get("target_path"))) != NodePath("../Player"):
		failures.append("Demo camera target_path must point to ../Player.")

	root.queue_free()


func _test_area_chain(failures: PackedStringArray) -> void:
	var street := (load(VS_STREET) as PackedScene).instantiate() as AreaRoot
	var church := (load(VS_CHURCH) as PackedScene).instantiate() as AreaRoot
	var underground := (load(VS_UNDERGROUND) as PackedScene).instantiate() as AreaRoot

	_check_exit(street, &"to_church", VS_CHURCH, failures)
	_check_exit(church, &"to_street", VS_STREET, failures)
	_check_exit(church, &"to_underground", VS_UNDERGROUND, failures)
	_check_exit(underground, &"to_church_entrance", VS_CHURCH, failures)

	street.queue_free()
	church.queue_free()
	underground.queue_free()


func _check_exit(area: AreaRoot, exit_id: StringName, expected_scene: String, failures: PackedStringArray) -> void:
	for exit in area.get_exits():
		if exit.exit_id == exit_id:
			if exit.target_scene != expected_scene:
				failures.append("Exit %s target mismatch in %s." % [String(exit_id), area.area_id])
			return
	failures.append("Missing exit %s in %s." % [String(exit_id), area.area_id])


func _test_street_flow_nodes(failures: PackedStringArray) -> void:
	var street := (load(VS_STREET) as PackedScene).instantiate()
	if not is_equal_approx(float(street.get("fall_recovery_y")), 1320.0):
		failures.append("Street fall_recovery_y must remain 1320.")

	if street.get_node_or_null("WorldObjects/CultBrawlerStreet") == null:
		failures.append("Street must keep CultBrawler encounter for slice flow.")

	street.queue_free()


func _test_church_flow_nodes(failures: PackedStringArray) -> void:
	var church := (load(VS_CHURCH) as PackedScene).instantiate()
	if church.get_node_or_null("WorldObjects/CultRedBarrier") == null:
		failures.append("Church must keep CultRedBarrier for slice flow.")
	if church.get_node_or_null("WorldObjects/ChurchYardArena") == null:
		failures.append("Church must keep CombatArena for slice flow.")

	church.queue_free()


func _test_underground_flow_nodes(failures: PackedStringArray) -> void:
	var underground := (load(VS_UNDERGROUND) as PackedScene).instantiate()
	if not is_equal_approx(float(underground.get("fall_recovery_y")), 1280.0):
		failures.append("Underground fall_recovery_y must remain 1280.")
	if underground.get_node_or_null("WorldObjects/UndergroundCheckpoint") == null:
		failures.append("Underground must keep checkpoint.")
	if underground.get_node_or_null("WorldObjects/DeaconRusk") == null:
		failures.append("Underground must keep Deacon Rusk.")
	if underground.get_node_or_null("WorldObjects/DeaconRuskEncounter") == null:
		failures.append("Underground must keep boss encounter controller.")

	underground.queue_free()


func _test_dialogue_contract(failures: PackedStringArray) -> void:
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		failures.append("Dialogue JSON missing for slice.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Dialogue JSON invalid.")
		return

	var dialogues: Dictionary = (parsed as Dictionary).get("dialogues", {})
	for required_id in ["elias_vertical_slice_intro", "elias_church_warning"]:
		if not dialogues.has(required_id):
			failures.append("Missing required dialogue id: %s." % required_id)


func _test_save_player_contract(failures: PackedStringArray) -> void:
	var save_manager_script := load("res://scripts/save/save_manager.gd") as Script
	if save_manager_script == null:
		failures.append("SaveManager script missing.")
		return

	var methods := save_manager_script.get_script_method_list()
	var has_apply := false
	for entry in methods:
		if String(entry.get("name", "")) == "_apply_save_state":
			has_apply = true
			break
	if not has_apply:
		failures.append("SaveManager must keep _apply_save_state for player restoration.")


func _test_hitstop_and_style_presence(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	var root := demo.instantiate()
	var hitstop := root.get_node_or_null("HitstopController")
	if hitstop == null or not hitstop.has_method("request_hitstop"):
		failures.append("Demo must include HitstopController with request_hitstop.")
	var style := root.get_node_or_null("StyleManager")
	if style == null:
		failures.append("Demo must include StyleManager for slice scoring.")
	root.queue_free()


func _test_completion_controller(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	var root := demo.instantiate()
	var controller := root.get_node_or_null("VerticalSliceController")
	if controller == null:
		failures.append("VerticalSliceController missing.")
		root.queue_free()
		return

	if not controller.has_method("return_to_start"):
		failures.append("VerticalSliceController must expose return_to_start.")
	if not controller.has_signal("demo_completed"):
		failures.append("VerticalSliceController must expose demo_completed signal.")

	root.queue_free()


func _test_gameplay_lock_presence(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	var root := demo.instantiate()
	var lock_manager := root.get_node_or_null("GameplayLockManager")
	if lock_manager == null or not lock_manager.has_method("acquire_lock"):
		failures.append("Demo must include GameplayLockManager with acquire_lock.")
	root.queue_free()


func _test_player_reset_contract(failures: PackedStringArray) -> void:
	var controller_script := load("res://scripts/demo/vertical_slice_controller.gd") as Script
	if controller_script == null:
		failures.append("VerticalSliceController script missing.")
		return

	var source := controller_script.source_code
	if not source.contains("apply_save_state"):
		failures.append("return_to_start flow must restore player via apply_save_state.")
	if not source.contains("debug_force_release_all"):
		failures.append("return_to_start flow must release gameplay locks via GameplayLockManager.")
	if not source.contains("begin_new_session"):
		failures.append("return_to_start flow must begin a new gameplay session.")
