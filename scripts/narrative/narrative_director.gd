extends Node
class_name NarrativeDirector

signal world_event_fired(event_id: StringName)
signal narrative_flag_set(flag_id: StringName, value: Variant)

const DIRECTOR_GROUP := "narrative_director"
const EVENTS_PATH := "res://data/narrative/chapter_zero_events.json"

var _progression: ProgressionComponent = null
var _objective_tracker: ObjectiveTracker = ObjectiveTracker.new()
var _events: Dictionary = {}
var _chapter: ChapterData = null


func configure(chapter: ChapterData) -> void:
	_chapter = chapter
	_apply_chapter_config()
	if is_inside_tree() and _progression != null:
		_refresh_objectives()


func _ready() -> void:
	add_to_group(DIRECTOR_GROUP)
	call_deferred("_deferred_setup")


func _deferred_setup() -> void:
	if _chapter == null:
		var registry := ContentRegistry.get_active()
		if registry != null:
			_chapter = registry.get_starting_chapter()
	_apply_chapter_config()
	_bind_runtime()


func _apply_chapter_config() -> void:
	var events_path := EVENTS_PATH
	var objectives_path := ObjectiveLibrary.DEFAULT_PATH
	if _chapter != null:
		if not _chapter.events_data_path.is_empty():
			events_path = _chapter.events_data_path
		if not _chapter.objectives_data_path.is_empty():
			objectives_path = _chapter.objectives_data_path
	_load_events(events_path)
	_objective_tracker.load_objectives(objectives_path)


func _bind_runtime() -> void:
	_progression = _find_progression()
	if _progression != null:
		if not _progression.progression_changed.is_connected(_on_progression_changed):
			_progression.progression_changed.connect(_on_progression_changed)

	for controller in get_tree().get_nodes_in_group("dialogue_controller"):
		if controller is DialogueController:
			var dialogue := controller as DialogueController
			if not dialogue.dialogue_action_requested.is_connected(_on_dialogue_action_requested):
				dialogue.dialogue_action_requested.connect(_on_dialogue_action_requested)
			if not dialogue.dialogue_finished.is_connected(_on_dialogue_finished):
				dialogue.dialogue_finished.connect(_on_dialogue_finished)

	for arena in get_tree().get_nodes_in_group("combat_arena_controller"):
		if not arena.arena_completed.is_connected(_on_arena_completed):
			arena.arena_completed.connect(_on_arena_completed)

	for encounter in get_tree().get_nodes_in_group("boss_encounter_controller"):
		if not encounter.boss_defeated.is_connected(_on_boss_defeated):
			encounter.boss_defeated.connect(_on_boss_defeated)

	get_tree().node_added.connect(_on_node_added)

	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		_connect_checkpoint(checkpoint)

	_track_enemy_group("chapter_zero_street_brawler", ChapterZeroFlags.STREET_BRAWLER_DEFEATED)
	_track_enemy_group("chapter_zero_gunslinger", ChapterZeroFlags.GUNSLINGER_DEFEATED)
	_track_enemy_group("chapter_zero_chain_penitent", ChapterZeroFlags.CHAIN_PENITENT_DEFEATED)
	_track_duo_pack(
		"chapter_zero_duo",
		ChapterZeroFlags.DUO_ENCOUNTER_CLEARED,
		[ChapterZeroFlags.SHORTCUT_OPEN]
	)
	set_narrative_flag(ChapterZeroFlags.CHAPTER_STARTED, true)
	_refresh_objectives()


func bind_objective_hud(hud: Node) -> void:
	if hud == null:
		return
	if not _objective_tracker.objective_changed.is_connected(hud.update_objective):
		_objective_tracker.objective_changed.connect(hud.update_objective)


func set_narrative_flag(flag_id: StringName, value: Variant = true) -> void:
	if _progression == null:
		_progression = _find_progression()
	if _progression == null:
		return
	_progression.set_narrative_flag(flag_id, value)
	narrative_flag_set.emit(flag_id, value)


func fire_world_event(event_id: StringName) -> bool:
	var entry: Dictionary = _events.get(String(event_id), {})
	if entry.is_empty():
		return false
	if not _event_conditions_met(entry):
		return false
	var flags_to_set: Array = entry.get("sets_flags", [])
	for flag_variant in flags_to_set:
		set_narrative_flag(StringName(String(flag_variant)), true)
	world_event_fired.emit(event_id)
	return true


func _event_conditions_met(entry: Dictionary) -> bool:
	if _progression == null:
		_progression = _find_progression()
	if _progression == null:
		return true
	return meets_dialogue_conditions({
		"requires_flags_all": entry.get("requires_flags_all", []),
		"requires_flags_any": entry.get("requires_flags_any", []),
		"excludes_flags": entry.get("excludes_flags", []),
	})


func meets_dialogue_conditions(conditions: Dictionary) -> bool:
	if conditions.is_empty():
		return true
	if _progression == null:
		return true

	var requires_all: Array = conditions.get("requires_flags_all", [])
	for flag_variant in requires_all:
		if not bool(_progression.narrative_flags.get(String(flag_variant), false)):
			return false

	var requires_any: Array = conditions.get("requires_flags_any", [])
	if not requires_any.is_empty():
		for flag_variant in requires_any:
			if bool(_progression.narrative_flags.get(String(flag_variant), false)):
				return true
		return false

	var excludes: Array = conditions.get("excludes_flags", [])
	for flag_variant in excludes:
		if bool(_progression.narrative_flags.get(String(flag_variant), false)):
			return false

	return true


func get_narrative_flags() -> Dictionary:
	if _progression == null:
		return {}
	return _progression.narrative_flags.duplicate(true)


func _on_dialogue_action_requested(action: Dictionary, _phase: StringName) -> void:
	var action_type := String(action.get("type", ""))
	match action_type:
		"set_flag":
			set_narrative_flag(StringName(String(action.get("flag", ""))), action.get("value", true))
		"fire_event":
			fire_world_event(StringName(String(action.get("event_id", ""))))


func _on_dialogue_finished(dialogue_id: StringName) -> void:
	match String(dialogue_id):
		"cz_elias_opening":
			fire_world_event(&"cz_evt_met_elias")
		"cz_calder_street_bark":
			pass
	_refresh_objectives()


func _on_progression_changed(property: StringName, _value: Variant) -> void:
	if property == &"narrative_flags" or property == &"active_checkpoint_id":
		_refresh_objectives()


func _on_arena_completed(_arena_id: StringName) -> void:
	_refresh_objectives()


func _on_boss_defeated(_boss_id: StringName) -> void:
	set_narrative_flag(ChapterZeroFlags.DEACON_DEFEATED, true)
	set_narrative_flag(ChapterZeroFlags.LEGACY_DEMO_COMPLETED, true)
	set_narrative_flag(ChapterZeroFlags.CHAPTER_COMPLETED, true)
	_refresh_objectives()


func _on_node_added(node: Node) -> void:
	if node.is_in_group("checkpoints"):
		_connect_checkpoint(node)
	if node.is_in_group("chapter_zero_street_brawler"):
		_track_enemy_death(node, ChapterZeroFlags.STREET_BRAWLER_DEFEATED)
	if node.is_in_group("chapter_zero_gunslinger"):
		_track_enemy_death(node, ChapterZeroFlags.GUNSLINGER_DEFEATED)
	if node.is_in_group("chapter_zero_chain_penitent"):
		_track_enemy_death(node, ChapterZeroFlags.CHAIN_PENITENT_DEFEATED)
	if node.is_in_group("chapter_zero_duo"):
		_track_duo_enemy_death(node)
	if node.is_in_group("dialogue_controller") and node is DialogueController:
		var dialogue := node as DialogueController
		if not dialogue.dialogue_action_requested.is_connected(_on_dialogue_action_requested):
			dialogue.dialogue_action_requested.connect(_on_dialogue_action_requested)
		if not dialogue.dialogue_finished.is_connected(_on_dialogue_finished):
			dialogue.dialogue_finished.connect(_on_dialogue_finished)


func _connect_checkpoint(node: Node) -> void:
	if not node.has_signal("checkpoint_activated"):
		return
	if node.is_connected("checkpoint_activated", Callable(self, "_on_checkpoint_activated")):
		return
	node.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))


func _on_checkpoint_activated(
	_checkpoint_id: StringName,
	_position: Vector2,
	_interactor: Node,
	_restore_health: bool,
	_restore_red_brand: bool
) -> void:
	fire_world_event(&"cz_evt_checkpoint")
	set_narrative_flag(ChapterZeroFlags.CHECKPOINT_ACTIVATED, true)
	if String(_checkpoint_id) == "vs_church_checkpoint":
		set_narrative_flag(ChapterZeroFlags.CHURCH_CHECKPOINT_ACTIVATED, true)


func _track_enemy_group(group_name: String, flag_id: StringName) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		_track_enemy_death(node, flag_id)


func _track_enemy_death(enemy: Node, flag_id: StringName) -> void:
	var health := _find_enemy_health(enemy)
	if health == null or not health.has_signal("died"):
		return
	if health.is_connected("died", Callable(self, "_on_tracked_enemy_died")):
		return
	health.connect("died", Callable(self, "_on_tracked_enemy_died").bind(flag_id), CONNECT_ONE_SHOT)


func _track_duo_pack(group_name: String, completion_flag: StringName, extra_flags: Array = []) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		_track_duo_enemy_death(node, group_name, completion_flag, extra_flags)


func _track_duo_enemy_death(
	enemy: Node,
	group_name: String = "chapter_zero_duo",
	completion_flag: StringName = ChapterZeroFlags.DUO_ENCOUNTER_CLEARED,
	extra_flags: Array = [ChapterZeroFlags.SHORTCUT_OPEN]
) -> void:
	var health := _find_enemy_health(enemy)
	if health == null or not health.has_signal("died"):
		return
	if health.is_connected("died", Callable(self, "_on_duo_enemy_died")):
		return
	health.connect(
		"died",
		Callable(self, "_on_duo_enemy_died").bind(group_name, completion_flag, extra_flags),
		CONNECT_ONE_SHOT
	)


func _on_duo_enemy_died(
	group_name: String,
	completion_flag: StringName,
	extra_flags: Array
) -> void:
	call_deferred("_check_duo_pack_cleared", group_name, completion_flag, extra_flags)


func _check_duo_pack_cleared(
	group_name: String,
	completion_flag: StringName,
	extra_flags: Array
) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		var health := _find_enemy_health(node)
		if health != null and not bool(health.get("is_dead")):
			return
	set_narrative_flag(completion_flag, true)
	for flag_variant in extra_flags:
		set_narrative_flag(StringName(String(flag_variant)), true)
	_refresh_objectives()


func _find_enemy_health(enemy: Node) -> Node:
	if enemy == null:
		return null
	var components_path := enemy.get_node_or_null("Components/HealthComponent")
	if components_path != null:
		return components_path
	if enemy is HealthComponent:
		return enemy
	for child in enemy.get_children():
		if child is HealthComponent:
			return child
		var nested := _find_enemy_health(child)
		if nested != null:
			return nested
	return null


func _on_tracked_enemy_died(flag_id: StringName) -> void:
	set_narrative_flag(flag_id, true)
	if flag_id == ChapterZeroFlags.STREET_BRAWLER_DEFEATED:
		fire_world_event(&"cz_evt_brawler_defeated")
	if flag_id == ChapterZeroFlags.GUNSLINGER_DEFEATED:
		fire_world_event(&"cz_evt_gunslinger_defeated")
	if flag_id == ChapterZeroFlags.CHAIN_PENITENT_DEFEATED:
		fire_world_event(&"cz_evt_chain_penitent_defeated")
	_refresh_objectives()


func notify_area_entered(area_id: StringName) -> void:
	match String(area_id):
		"vs_greybox_church":
			fire_world_event(&"cz_evt_church_reached")
		"vs_greybox_underground":
			fire_world_event(&"cz_evt_underground_reached")
	_refresh_objectives()


func notify_barrier_destroyed(barrier_id: StringName) -> void:
	fire_world_event(&"cz_evt_barrier_broken")
	set_narrative_flag(ChapterZeroFlags.BARRIER_BROKEN, true)
	if String(barrier_id) == "vs_church_red_brand_passage":
		set_narrative_flag(ChapterZeroFlags.RED_BRAND_PASSAGE_OPEN, true)
	_refresh_objectives()


func _refresh_objectives() -> void:
	if _progression == null:
		return
	_objective_tracker.refresh_from_flags(_progression.narrative_flags)
	_sync_world_map_objective()


func _sync_world_map_objective() -> void:
	var objective_id := _objective_tracker.get_active_objective_id()
	for node in get_tree().get_nodes_in_group(WorldMapService.SERVICE_GROUP):
		if node is WorldMapService:
			(node as WorldMapService).set_objective_from_id(objective_id)
			return


func _load_events(path: String = EVENTS_PATH) -> void:
	_events.clear()
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_events = (parsed as Dictionary).get("events", {})
	if _chapter != null:
		for event_data in _chapter.embedded_events:
			if event_data == null:
				continue
			_events[String(event_data.event_id)] = event_data.to_event_dictionary()


func _find_progression() -> ProgressionComponent:
	for node in get_tree().get_nodes_in_group("progression_component"):
		if node is ProgressionComponent:
			return node as ProgressionComponent
	return null
