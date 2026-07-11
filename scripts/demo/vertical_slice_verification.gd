extends SceneTree

const VS_STREET := "res://scenes/areas/vertical_slice_street.tscn"
const VS_CHURCH := "res://scenes/areas/vertical_slice_church.tscn"
const VS_UNDERGROUND := "res://scenes/areas/vertical_slice_underground.tscn"
const VS_MAIN := "res://scenes/demo/vertical_slice_greybox.tscn"
const DIALOGUE_PATH := "res://data/dialogues/dialogues_pt_br.json"


func _initialize() -> void:
	call_deferred("_run_verification")


func _run_verification() -> void:
	var failures: PackedStringArray = PackedStringArray()

	_verify_main_scene(failures)
	_verify_area_chain(failures)
	_verify_dialogue_ids(failures)
	_verify_demo_scene_nodes(failures)
	_verify_no_autoload_duplicates(failures)
	_verify_boss_encounter_paths(failures)

	if failures.is_empty():
		print("Vertical slice verification passed.")
	else:
		for failure in failures:
			push_error(failure)
		print("Vertical slice verification failed: %s" % failures.size())

	quit()


func _verify_main_scene(failures: PackedStringArray) -> void:
	var main_scene: String = String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene != VS_MAIN:
		failures.append("Main scene should be vertical_slice_greybox.tscn.")


func _verify_area_chain(failures: PackedStringArray) -> void:
	var street := load(VS_STREET) as PackedScene
	var church := load(VS_CHURCH) as PackedScene
	var underground := load(VS_UNDERGROUND) as PackedScene
	if street == null or church == null or underground == null:
		failures.append("Vertical slice area scenes must load.")
		return

	var street_root: AreaRoot = street.instantiate() as AreaRoot
	var church_root: AreaRoot = church.instantiate() as AreaRoot
	var underground_root: AreaRoot = underground.instantiate() as AreaRoot

	_check_exit_target(street_root, &"to_church", VS_CHURCH, failures)
	_check_exit_target(church_root, &"to_street", VS_STREET, failures)
	_check_exit_target(church_root, &"to_underground", VS_UNDERGROUND, failures)
	_check_exit_target(underground_root, &"to_church_entrance", VS_CHURCH, failures)

	street_root.queue_free()
	church_root.queue_free()
	underground_root.queue_free()


func _check_exit_target(
	area: AreaRoot,
	exit_id: StringName,
	expected_scene: String,
	failures: PackedStringArray
) -> void:
	for exit in area.get_exits():
		if exit.exit_id != exit_id:
			continue
		if exit.target_scene != expected_scene:
			failures.append(
				"Exit '%s' in %s should target %s." % [String(exit_id), area.area_id, expected_scene]
			)
		return
	failures.append("Missing exit '%s' in area %s." % [String(exit_id), area.area_id])


func _verify_dialogue_ids(failures: PackedStringArray) -> void:
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.READ)
	if file == null:
		failures.append("Dialogue file missing.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Dialogue JSON invalid.")
		return
	var data: Dictionary = parsed as Dictionary
	var dialogues: Dictionary = data.get("dialogues", {}) as Dictionary
	if not dialogues.has("elias_vertical_slice_intro"):
		failures.append("Missing elias_vertical_slice_intro dialogue.")


func _verify_demo_scene_nodes(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	if demo == null:
		failures.append("vertical_slice_greybox scene missing.")
		return
	var root := demo.instantiate()
	if root.get_node_or_null("VerticalSliceController/CompletionOverlay") == null:
		failures.append("Completion overlay missing in demo scene.")
	if root.get_node_or_null("%SaveManager") == null:
		failures.append("SaveManager unique name missing in demo scene.")
	if root.get_node_or_null("%AreaTransitionManager") == null:
		failures.append("AreaTransitionManager unique name missing in demo scene.")
	root.queue_free()


func _verify_no_autoload_duplicates(failures: PackedStringArray) -> void:
	var autoloads: Variant = ProjectSettings.get_setting("autoload", {})
	if autoloads is Dictionary and (autoloads as Dictionary).size() > 0:
		failures.append("Prototype expects no autoloads; found %s." % (autoloads as Dictionary).size())


func _verify_boss_encounter_paths(failures: PackedStringArray) -> void:
	var underground := load(VS_UNDERGROUND) as PackedScene
	if underground == null:
		failures.append("Underground scene failed to load.")
		return
	var underground_root: Node = underground.instantiate()
	var boss := underground_root.get_node_or_null("WorldObjects/DeaconRusk")
	var encounter := underground_root.get_node_or_null("WorldObjects/DeaconRuskEncounter")
	if boss == null or encounter == null:
		failures.append("Underground area must contain Deacon Rusk and encounter controller.")
	underground_root.queue_free()
