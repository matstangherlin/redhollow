extends Node

signal demo_completed

const DEMO_GROUP := "vertical_slice_controller"
const BOSS_ENCOUNTER_GROUP := "boss_encounter_controller"
const PROGRESSION_GROUP := "progression_component"
const SAVE_MANAGER_GROUP := "save_manager"
const AREA_TRANSITION_GROUP := "area_transition_manager"
const STYLE_MANAGER_GROUP := "style_manager"
const RED_BRAND_DIRECTOR_GROUP := "red_brand_director"

const VS_STREET_SCENE := "res://scenes/areas/vertical_slice_street.tscn"
const VS_MAIN_SCENE := "res://scenes/demo/vertical_slice_greybox.tscn"
const COMPLETION_FLAG := &"vertical_slice_completed"

@export var street_scene: PackedScene
@export var street_spawn_id: StringName = &"default"

var _completion_shown: bool = false


func _ready() -> void:
	add_to_group(DEMO_GROUP)
	if street_scene == null:
		street_scene = load(VS_STREET_SCENE) as PackedScene
	call_deferred("_initialize_demo")


func _initialize_demo() -> void:
	await get_tree().process_frame
	_connect_runtime_signals()
	_check_existing_completion()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("demo_return_start"):
		return_to_start()


func return_to_start() -> void:
	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node.has_method("force_reset"):
			node.call("force_reset")

	for node in get_tree().get_nodes_in_group("hitstop_controller"):
		if node.has_method("force_release"):
			node.call("force_release")

	if Engine.time_scale <= 0.0:
		Engine.time_scale = 1.0
	if get_tree().paused:
		get_tree().paused = false

	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("clear_input_locks"):
		player.call("clear_input_locks")

	var save_manager := _find_node_in_group(SAVE_MANAGER_GROUP)
	if save_manager != null and save_manager.has_method("delete_save"):
		save_manager.call("delete_save")

	_reset_progression_for_demo()
	_completion_shown = false
	_hide_completion_overlay()

	var transition_manager := _find_node_in_group(AREA_TRANSITION_GROUP) as AreaTransitionManager
	if transition_manager != null and street_scene != null:
		transition_manager.jump_to_area(street_scene, street_spawn_id)

	var save_manager_after := _find_node_in_group(SAVE_MANAGER_GROUP)
	if save_manager_after != null and save_manager_after.has_method("create_new_save"):
		save_manager_after.call("create_new_save")

	_reset_player_combat_state()
	_reset_style_and_brand()
	_reset_barriers()


func _reset_barriers() -> void:
	for node in get_tree().get_nodes_in_group("barrier_registry"):
		if node.has_method("reset_registry"):
			node.call("reset_registry")


func _connect_runtime_signals() -> void:
	for encounter in get_tree().get_nodes_in_group(BOSS_ENCOUNTER_GROUP):
		if not encounter.boss_defeated.is_connected(_on_boss_defeated):
			encounter.boss_defeated.connect(_on_boss_defeated)

	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.is_in_group(BOSS_ENCOUNTER_GROUP):
		if not node.has_signal("boss_defeated"):
			return
		if not node.boss_defeated.is_connected(_on_boss_defeated):
			node.boss_defeated.connect(_on_boss_defeated)


func _on_boss_defeated(_boss_id: StringName) -> void:
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node.has_method("set_narrative_flag"):
			node.call("set_narrative_flag", COMPLETION_FLAG, true)

	var save_manager := _find_node_in_group(SAVE_MANAGER_GROUP)
	if save_manager != null and save_manager.has_method("save_game"):
		save_manager.call("save_game")

	_show_completion_overlay()
	demo_completed.emit()


func _check_existing_completion() -> void:
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		var flags: Dictionary = node.get("narrative_flags")
		if bool(flags.get(String(COMPLETION_FLAG), false)):
			_show_completion_overlay()


func _show_completion_overlay() -> void:
	if _completion_shown:
		return
	_completion_shown = true

	var overlay := get_node_or_null("CompletionOverlay")
	if overlay == null:
		return
	overlay.visible = true


func _hide_completion_overlay() -> void:
	var overlay := get_node_or_null("CompletionOverlay")
	if overlay != null:
		overlay.visible = false


func _reset_progression_for_demo() -> void:
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node.has_method("reset_for_demo"):
			node.call("reset_for_demo")


func _reset_player_combat_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.has_method("apply_save_state"):
		player.call(
			"apply_save_state",
			{
				"player_max_health": 12.0,
				"player_current_health": 12.0,
				"red_brand_energy": 0.0,
				"checkpoint_position": {"x": 120.0, "y": 848.0},
			}
		)
	if player.has_method("set_spawn_position"):
		player.call("set_spawn_position", Vector2(120, 848))


func _reset_style_and_brand() -> void:
	for node in get_tree().get_nodes_in_group(STYLE_MANAGER_GROUP):
		if node.has_method("reset_style"):
			node.call("reset_style")
	for node in get_tree().get_nodes_in_group(RED_BRAND_DIRECTOR_GROUP):
		if node.has_method("reset_red_brand"):
			node.call("reset_red_brand")


func _find_node_in_group(group_name: String) -> Node:
	return get_tree().get_first_node_in_group(group_name)
