extends CanvasLayer
class_name BetaPlaytestDebugPanel

## Optional debug-only overlay. Off by default. Toggle with F10.

const PANEL_GROUP := "beta_playtest_debug_panel"
const RecorderScript := preload("res://scripts/debug/beta_playtest_recorder.gd")

@export var start_visible: bool = false
@export var refresh_interval: float = 0.25

var _root: Control
var _label: Label
var _refresh_left: float = 0.0
var _game_root: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 128
	if not OS.is_debug_build():
		queue_free()
		return

	add_to_group(PANEL_GROUP)
	_game_root = get_parent()
	_build_ui()
	visible = start_visible
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		visible = not visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = refresh_interval
	_refresh_label()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 12.0
	panel.offset_top = 120.0
	panel.offset_right = 380.0
	panel.offset_bottom = 380.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.86, 0.95))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_label)
	_refresh_label()


func _refresh_label() -> void:
	if _label == null:
		return

	var area_id := "-"
	var objective := "-"
	var checkpoint := "-"
	var locks := "none"
	var arena := "none"
	var flags := "(none)"
	var save_version := str(SaveData.CURRENT_SAVE_VERSION)
	var fps := Engine.get_frames_per_second()
	var recorder_line := "-"

	if _game_root != null:
		var transition := _game_root.get_node_or_null("%AreaTransitionManager") as AreaTransitionManager
		if transition != null and transition.get_current_area() != null:
			area_id = String(transition.get_current_area().area_id)

		var progression := _find_progression()
		if progression != null:
			checkpoint = String(progression.active_checkpoint_id)
			if checkpoint.is_empty():
				checkpoint = "-"
			var critical: PackedStringArray = PackedStringArray()
			for flag_id in [
				String(ChapterZeroFlags.MET_ELIAS),
				String(ChapterZeroFlags.RED_BRAND_CACHE_USED),
				String(ChapterZeroFlags.CHECKPOINT_ACTIVATED),
				String(ChapterZeroFlags.DEACON_DEFEATED),
				String(ChapterZeroFlags.CHAPTER_COMPLETED),
			]:
				if bool(progression.narrative_flags.get(flag_id, false)):
					critical.append(flag_id)
			flags = ", ".join(critical) if not critical.is_empty() else "(none)"

		var director := _game_root.get_node_or_null("NarrativeDirector") as NarrativeDirector
		if director != null:
			objective = director.get_objective_tracker().get_active_objective_id()
			if objective.is_empty():
				objective = "-"

		var lock_manager := _game_root.get_node_or_null("GameplayLockManager") as GameplayLockManager
		if lock_manager != null:
			locks = _summarize_locks(lock_manager)

		arena = _summarize_arenas()

	for node in get_tree().get_nodes_in_group("beta_playtest_recorder"):
		if node.get_script() == RecorderScript and node.has_method("get_snapshot"):
			var snap: Variant = node.call("get_snapshot")
			if typeof(snap) == TYPE_DICTIONARY:
				var snap_dict := snap as Dictionary
				recorder_line = "%s (%d ev)" % [
					String(snap_dict.get("session_id", "?")),
					int(snap_dict.get("event_count", 0)),
				]
				if String(snap_dict.get("objective_id", "")) != "":
					objective = String(snap_dict.get("objective_id", objective))
			break

	_label.text = "\n".join(
		PackedStringArray(
			[
				"PLAYTEST DEBUG (F10)",
				"area: %s" % area_id,
				"objective: %s" % objective,
				"checkpoint: %s" % checkpoint,
				"flags: %s" % flags,
				"locks: %s" % locks,
				"arena: %s" % arena,
				"save_version: %s" % save_version,
				"fps: %d" % fps,
				"session: %s" % recorder_line,
			]
		)
	)


func _find_progression() -> ProgressionComponent:
	if _game_root == null:
		return null
	for node in get_tree().get_nodes_in_group("progression_component"):
		if node is ProgressionComponent:
			return node as ProgressionComponent
	return null


func _summarize_locks(lock_manager: GameplayLockManager) -> String:
	var active: PackedStringArray = PackedStringArray()
	var reason_names: PackedStringArray = PackedStringArray(
		[
			"DIALOGUE",
			"AREA_TRANSITION",
			"PAUSE",
			"CUTSCENE",
			"DEATH",
			"RESPAWN",
			"BOSS_INTRO",
			"COMPLETION",
			"LOADING",
		]
	)
	for reason_i in range(reason_names.size()):
		if lock_manager.has_lock(reason_i as GameplayLockManager.LockReason):
			active.append(reason_names[reason_i])
	if active.is_empty():
		return "none"
	return ", ".join(active)


func _summarize_arenas() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for node in get_tree().get_nodes_in_group(CombatArenaController.CONTROLLER_GROUP):
		var arena_id := String(node.name)
		if "arena_id" in node:
			arena_id = String(node.get("arena_id"))
		var state := -1
		if "state" in node:
			state = int(node.get("state"))
		parts.append("%s:%d" % [arena_id, state])
	if parts.is_empty():
		return "none"
	return " | ".join(parts)
