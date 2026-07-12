extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const ContentRegistryScript := preload("res://scripts/content/content_registry.gd")

const BETA_MANIFEST_PATH := "res://resources/content/manifests/beta_demo.tres"
const MAIN_MENU_SCENE := "res://scenes/product/main_menu.tscn"
const GAME_SHELL_SCENE := "res://scenes/demo/vertical_slice_greybox.tscn"
const LOADING_SCENE := "res://scenes/ui/loading_screen.tscn"
const OBJECTIVES_PATH := "res://data/narrative/chapter_zero_objectives.json"
const EVENTS_PATH := "res://data/narrative/chapter_zero_events.json"

const ENEMY_SCENES := {
	"cult_brawler": "res://scenes/enemies/cult_brawler.tscn",
	"vermilite_gunslinger": "res://scenes/enemies/vermilite_gunslinger.tscn",
	"chain_penitent": "res://scenes/enemies/chain_penitent.tscn",
	"deacon_rusk": "res://scenes/enemies/deacon_rusk.tscn",
}

const AREA_SCENES := {
	"street": "res://scenes/areas/vertical_slice_street.tscn",
	"church": "res://scenes/areas/vertical_slice_church.tscn",
	"underground": "res://scenes/areas/vertical_slice_underground.tscn",
}

const ENCOUNTER_PREFABS := {
	"combat_arena": "res://scenes/world/combat_arena.tscn",
	"boss_encounter": "res://scenes/world/boss_encounter.tscn",
	"red_barrier": "res://scenes/world/red_barrier.tscn",
}


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "beta_integration_smoke_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_required_autoloads(failures)
	_test_main_menu_exists(failures)
	_test_beta_manifest_loads(failures)
	_test_chapter_data_valid(failures)
	_test_objectives_have_ids(failures)
	_test_events_have_ids(failures)
	_test_areas_exist(failures)
	_test_enemy_scenes_load(failures)
	_test_encounter_prefabs_load(failures)
	_test_boss_and_finale_exist(failures)
	_test_save_accepts_beta_chapter(failures)
	_test_settings_schema(failures)
	_test_pause_and_boot_contract(failures)

	ContentRegistryScript.clear_active()
	suite.finish(failures, 22)


func _test_required_autoloads(failures: PackedStringArray) -> void:
	if SettingsManager == null:
		failures.append("SettingsManager autoload must exist for beta shell.")
	if GameBootState == null:
		failures.append("GameBootState autoload must exist for menu boot flow.")
	if InputDeviceManager == null:
		failures.append("InputDeviceManager autoload must exist for gamepad prompts.")
	if InputSetup == null:
		failures.append("InputSetup autoload must exist for input map bootstrap.")


func _test_main_menu_exists(failures: PackedStringArray) -> void:
	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene != MAIN_MENU_SCENE:
		failures.append("Main scene must be main_menu.tscn for beta integration gate.")

	var menu_scene := load(MAIN_MENU_SCENE) as PackedScene
	if menu_scene == null:
		failures.append("Main menu scene must load.")
		return

	var menu := menu_scene.instantiate()
	for path in [
		"Layout/MenuPanel/MenuVBox/NewGameButton",
		"Layout/MenuPanel/MenuVBox/ContinueButton",
		"Layout/MenuPanel/MenuVBox/OptionsButton",
		"ConfirmationDialog",
		"LoadingScreen",
		"OptionsMenu",
	]:
		if menu.get_node_or_null(path) == null:
			failures.append("Main menu missing node: %s." % path)
	menu.queue_free()


func _test_beta_manifest_loads(failures: PackedStringArray) -> void:
	var manifest = ContentRegistryScript.load_manifest(BETA_MANIFEST_PATH)
	if manifest == null:
		failures.append("beta_demo manifest must load.")
		return

	if String(manifest.manifest_id) != "beta_demo":
		failures.append("beta_demo manifest_id mismatch.")

	if manifest.game_shell_scene_path != GAME_SHELL_SCENE:
		failures.append("beta_demo shell must point to vertical_slice_greybox.")

	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	if registry == null:
		failures.append("ContentRegistry must activate beta_demo manifest.")


func _test_chapter_data_valid(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	var chapter = registry.get_starting_chapter() if registry != null else null
	if chapter == null:
		failures.append("ChapterData starting chapter must resolve.")
		return

	if String(chapter.chapter_id) != "chapter_zero_bell_before_nightfall":
		failures.append("Starting chapter must be chapter_zero_bell_before_nightfall.")

	if String(chapter.starting_area_id) != "vs_greybox_street":
		failures.append("Chapter must start on street area.")

	if chapter.get_playable_areas().size() != 3:
		failures.append("Chapter zero must define three playable areas.")

	if String(chapter.completion_flag_id) != "cz_chapter_zero_completed":
		failures.append("Chapter completion flag must be cz_chapter_zero_completed.")


func _test_objectives_have_ids(failures: PackedStringArray) -> void:
	if not FileAccess.file_exists(OBJECTIVES_PATH):
		failures.append("Chapter zero objectives JSON missing.")
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Chapter zero objectives JSON invalid.")
		return

	var objectives: Array = (parsed as Dictionary).get("objectives", [])
	if objectives.size() < 10:
		failures.append("Chapter zero must define at least 10 objectives.")

	var seen: Dictionary = {}
	for entry in objectives:
		if typeof(entry) != TYPE_DICTIONARY:
			failures.append("Objective entry must be a dictionary.")
			continue
		var objective_id := String((entry as Dictionary).get("id", ""))
		if objective_id.is_empty():
			failures.append("Every objective must have a non-empty id.")
		elif seen.has(objective_id):
			failures.append("Duplicate objective id: %s." % objective_id)
		else:
			seen[objective_id] = true


func _test_events_have_ids(failures: PackedStringArray) -> void:
	if not FileAccess.file_exists(EVENTS_PATH):
		failures.append("Chapter zero events JSON missing.")
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Chapter zero events JSON invalid.")
		return

	var events: Dictionary = (parsed as Dictionary).get("events", {})
	if events.is_empty():
		failures.append("Chapter zero events must not be empty.")
		return

	for event_key in events.keys():
		var event_entry: Variant = events[event_key]
		if typeof(event_entry) != TYPE_DICTIONARY:
			failures.append("Event %s must be a dictionary." % String(event_key))
			continue
		var event_id := String((event_entry as Dictionary).get("event_id", ""))
		if event_id.is_empty():
			failures.append("Event %s missing event_id." % String(event_key))


func _test_areas_exist(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	for area_key in AREA_SCENES.keys():
		var scene_path: String = AREA_SCENES[area_key]
		var packed := load(scene_path) as PackedScene
		if packed == null:
			failures.append("Area scene must load: %s." % scene_path)
			continue
		var instance := packed.instantiate()
		if instance == null:
			failures.append("Area scene must instantiate: %s." % scene_path)
		else:
			instance.queue_free()
		if registry != null and not registry.can_load_area_scene(scene_path):
			failures.append("Manifest must allow area scene: %s." % scene_path)


func _test_enemy_scenes_load(failures: PackedStringArray) -> void:
	for enemy_key in ENEMY_SCENES.keys():
		var scene_path: String = ENEMY_SCENES[enemy_key]
		var packed := load(scene_path) as PackedScene
		if packed == null:
			failures.append("Enemy scene must load: %s." % enemy_key)
			continue
		var instance := packed.instantiate()
		if instance == null:
			failures.append("Enemy scene must instantiate: %s." % enemy_key)
		else:
			instance.queue_free()


func _test_encounter_prefabs_load(failures: PackedStringArray) -> void:
	for prefab_key in ENCOUNTER_PREFABS.keys():
		var scene_path: String = ENCOUNTER_PREFABS[prefab_key]
		var packed := load(scene_path) as PackedScene
		if packed == null:
			failures.append("Encounter prefab must load: %s." % prefab_key)
			continue
		var instance := packed.instantiate()
		if instance == null:
			failures.append("Encounter prefab must instantiate: %s." % prefab_key)
		else:
			instance.queue_free()


func _test_boss_and_finale_exist(failures: PackedStringArray) -> void:
	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	var chapter = registry.get_starting_chapter() if registry != null else null
	if chapter == null or chapter.bosses.is_empty():
		failures.append("Chapter must register Deacon Rusk boss data.")
	else:
		var boss = chapter.bosses[0]
		if String(boss.boss_id) != "deacon_rusk":
			failures.append("Boss id must be deacon_rusk.")
		if boss.enemy_scene_path != ENEMY_SCENES["deacon_rusk"]:
			failures.append("Boss data must reference deacon_rusk scene.")

	var shell := load(GAME_SHELL_SCENE) as PackedScene
	if shell == null:
		failures.append("Game shell scene must load for finale contract.")
		return

	var root := shell.instantiate()
	if root.get_node_or_null("VerticalSliceController/ChapterZeroFinale") == null:
		failures.append("Chapter zero finale node must exist in game shell.")
	if root.get_node_or_null("VerticalSliceController/CompletionOverlay") == null:
		failures.append("Beta completion overlay must exist in game shell.")
	root.queue_free()


func _test_save_accepts_beta_chapter(failures: PackedStringArray) -> void:
	var save := SaveData.create_default(AREA_SCENES["street"])
	save["content_manifest_id"] = "beta_demo"
	save["chapter_id"] = "chapter_zero_bell_before_nightfall"
	save["checkpoint_id"] = "vs_underground_checkpoint"
	save["narrative_flags"] = {
		"cz_chapter_zero_completed": false,
		"boss_vs_deacon_rusk_defeated": false,
		"arena_vs_church_yard_complete": false,
	}
	save["destroyed_barriers"] = {"vs_church_gate_01": false}

	var validation := SaveData.validate(save)
	if not validation.get("valid", false):
		failures.append("Save schema must accept beta chapter payload.")

	var registry = ContentRegistryScript.activate_from_path(BETA_MANIFEST_PATH)
	if registry == null or not registry.is_save_compatible_with_manifest(save):
		failures.append("beta_demo manifest must accept chapter zero save.")

	var inspection := SaveManager.inspect_slot("slot_missing_gate_test")
	if String(inspection.get("status", "")) != "none":
		failures.append("Missing save slot should report status none.")


func _test_settings_schema(failures: PackedStringArray) -> void:
	var defaults := SettingsData.create_default()
	var video: Dictionary = defaults.get("video", {})
	var audio: Dictionary = defaults.get("audio", {})
	var accessibility: Dictionary = defaults.get("accessibility", {})

	if not video.has("resolution"):
		failures.append("Settings must define resolution.")
	if not video.has("display_mode"):
		failures.append("Settings must define display mode (fullscreen/windowed).")
	if not video.has("vsync"):
		failures.append("Settings must define VSync.")
	if not audio.has("master"):
		failures.append("Settings must define master volume.")
	if not accessibility.has("screen_shake_intensity"):
		failures.append("Settings must define screen shake intensity.")
	if not accessibility.has("reduced_flashes"):
		failures.append("Settings must define reduced flashes toggle.")
	if not accessibility.has("text_speed"):
		failures.append("Settings must define text speed.")

	if InputDeviceManager == null:
		failures.append("InputDeviceManager required for last-device tracking.")
	elif not ("last_device_kind" in InputDeviceManager):
		failures.append("InputDeviceManager must expose last_device_kind.")


func _test_pause_and_boot_contract(failures: PackedStringArray) -> void:
	if not InputMap.has_action("pause"):
		failures.append("Input map must define pause action.")

	if load(LOADING_SCENE) as PackedScene == null:
		failures.append("Loading screen scene must load.")

	var shell := load(GAME_SHELL_SCENE) as PackedScene
	if shell == null:
		failures.append("Game shell must load for pause contract.")
		return

	var root := shell.instantiate()
	if root.get_node_or_null("ProductShell/PauseMenu") == null:
		failures.append("Pause menu must exist in game shell.")
	root.queue_free()

	if GameBootState == null:
		failures.append("GameBootState required for new-game boot contract.")
		return

	GameBootState.set_new_game()
	if GameBootState.consume_boot_mode() != GameBootState.BootMode.NEW_GAME:
		failures.append("GameBootState must consume NEW_GAME boot mode once.")
