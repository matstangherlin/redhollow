extends AreaRoot
class_name StreetArtArea

## Art variant of the street: identical gameplay, presentation swapped.
## Modes: greybox | north_star | final_candidate (approved mold → full 2400 px street).

const ART_PRESENTATION_SCENE := preload("res://scenes/environment/chapter_zero/street_art_presentation.tscn")
const CULT_BRAWLER_SCENE := preload("res://scenes/enemies/cult_brawler.tscn")
const Spec := preload("res://scripts/visual/street_final_sample_spec.gd")
const FinalMoldComposer := preload("res://scripts/visual/street_final_mold_composer.gd")
const GREYBOX_VISUAL_GROUP := "street_greybox_visual"
const DEBUG_LABEL_NAMES: Array[StringName] = [
	&"AreaLabel",
	&"GuideLabel",
	&"TutorialDodgeLabel",
	&"GunslingerPrompt",
	&"DuoPrompt",
	&"SecretLabel",
	&"ExitLabel",
]
const SAMPLE_BRAWLER_NAME := "CultBrawlerFinalSample"

@export var show_greybox_visuals: bool = false
@export var show_art_presentation: bool = true
## When true (and art presentation on), applies the approved final mold to the full street.
@export var enable_final_sample: bool = false

var _art_presentation: StreetArtPresentation = null
var _greybox_tagged: bool = false
var _performance_monitor: Node = null
var _visual_mode: StringName = Spec.MODE_NORTH_STAR
var _sample_brawler: Node = null
var _sample_stats: Dictionary = {}


func _ready() -> void:
	super._ready()
	call_deferred("_sync_mode_from_exports")


func _unhandled_input(event: InputEvent) -> void:
	if _visual_mode == Spec.MODE_GREYBOX:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_P:
				var monitor: Node = get_performance_monitor()
				if monitor != null and monitor.has_method("toggle_visible"):
					monitor.call("toggle_visible")
					get_viewport().set_input_as_handled()
			KEY_APOSTROPHE:
				_cycle_region_visual_state()
				get_viewport().set_input_as_handled()


func _cycle_region_visual_state() -> void:
	var presentation := get_art_presentation()
	if presentation == null:
		return
	var controller: RegionVisualController = presentation.get_region_visual_controller()
	if controller == null:
		return
	var next_state := (int(controller.get_current_state()) + 1) % 4
	controller.transition_to_state(next_state as CorruptionVisualState.State)


func _sync_mode_from_exports() -> void:
	if show_greybox_visuals and not show_art_presentation:
		set_presentation_mode(Spec.MODE_GREYBOX)
	elif enable_final_sample and show_art_presentation:
		set_presentation_mode(Spec.MODE_FINAL_CANDIDATE)
	else:
		set_presentation_mode(Spec.MODE_NORTH_STAR if show_art_presentation else Spec.MODE_GREYBOX)


func _apply_visual_mode() -> void:
	_tag_greybox_visuals()
	var is_greybox := _visual_mode == Spec.MODE_GREYBOX
	show_greybox_visuals = is_greybox
	show_art_presentation = not is_greybox
	enable_final_sample = _visual_mode == Spec.MODE_FINAL_CANDIDATE

	_set_greybox_visible(show_greybox_visuals)
	_set_debug_labels_visible(show_greybox_visuals)

	if show_art_presentation and _art_presentation == null:
		_art_presentation = ART_PRESENTATION_SCENE.instantiate() as StreetArtPresentation
		if _art_presentation != null:
			add_child(_art_presentation)
			move_child(_art_presentation, 0)
			_ensure_gameplay_draw_order()
			_ensure_performance_monitor()
	elif _art_presentation != null:
		_art_presentation.visible = show_art_presentation
		if show_art_presentation:
			_ensure_gameplay_draw_order()
			_ensure_performance_monitor()

	_apply_final_sample_layer()


func _apply_final_sample_layer() -> void:
	if _art_presentation == null or not show_art_presentation:
		_clear_sample_brawler()
		return
	if _visual_mode == Spec.MODE_FINAL_CANDIDATE:
		var profile: EnvironmentVisualProfile = _art_presentation.profile
		if profile == null:
			profile = load("res://resources/visual/chapter_zero_street_profile.tres") as EnvironmentVisualProfile
		_sample_stats = FinalMoldComposer.apply(_art_presentation, profile)
		_ensure_sample_brawler()
		_refresh_perf_binding()
	else:
		FinalMoldComposer.remove(_art_presentation)
		_sample_stats = {}
		_clear_sample_brawler()


func _ensure_sample_brawler() -> void:
	## Live combat sample inside the band; production CultBrawlerStreet stays at X=1280.
	if _sample_brawler != null and is_instance_valid(_sample_brawler):
		return
	var world := get_node_or_null("WorldObjects")
	if world == null:
		return
	_sample_brawler = CULT_BRAWLER_SCENE.instantiate()
	_sample_brawler.name = SAMPLE_BRAWLER_NAME
	if _sample_brawler is Node2D:
		(_sample_brawler as Node2D).position = Vector2(740, 848)
	if "patrol_distance" in _sample_brawler:
		_sample_brawler.set("patrol_distance", 60.0)
	world.add_child(_sample_brawler)


func _clear_sample_brawler() -> void:
	if _sample_brawler != null and is_instance_valid(_sample_brawler):
		_sample_brawler.queue_free()
	_sample_brawler = null
	var world := get_node_or_null("WorldObjects")
	if world != null:
		var orphan := world.get_node_or_null(SAMPLE_BRAWLER_NAME)
		if orphan != null:
			orphan.queue_free()


func _refresh_perf_binding() -> void:
	if _performance_monitor != null and _art_presentation != null:
		if _performance_monitor.has_method("bind_scene_root"):
			_performance_monitor.call("bind_scene_root", _art_presentation)
		if _performance_monitor.has_method("note_sample_stats"):
			_performance_monitor.call("note_sample_stats", _sample_stats)


func _ensure_gameplay_draw_order() -> void:
	# Gameplay entities must render above art foreground (z 40) and atmosphere (z 50).
	for node_name in [&"WorldObjects", &"Exits", &"Spawns"]:
		var node := get_node_or_null(NodePath(String(node_name)))
		if node is CanvasItem:
			(node as CanvasItem).z_index = 70


func set_visual_mode(use_art: bool) -> void:
	## Backward-compatible binary API used by older tests.
	set_presentation_mode(Spec.MODE_NORTH_STAR if use_art else Spec.MODE_GREYBOX)


func set_presentation_mode(mode: StringName) -> void:
	_visual_mode = mode
	_apply_visual_mode()


func cycle_presentation_mode() -> StringName:
	set_presentation_mode(Spec.next_mode(_visual_mode))
	return _visual_mode


func get_presentation_mode() -> StringName:
	return _visual_mode


func get_final_sample_stats() -> Dictionary:
	return _sample_stats.duplicate(true)


func get_art_presentation() -> StreetArtPresentation:
	return _art_presentation


func get_performance_monitor() -> Node:
	return _performance_monitor


func _ensure_performance_monitor() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _art_presentation == null:
		return
	if _performance_monitor != null:
		return

	var debug_layer := _art_presentation.get_debug_layer()
	if debug_layer == null:
		return

	var monitor_script: GDScript = load("res://scripts/visual/street_performance_monitor.gd") as GDScript
	if monitor_script == null:
		return

	_performance_monitor = monitor_script.new()
	_performance_monitor.name = "StreetPerformanceMonitor"
	debug_layer.add_child(_performance_monitor)
	if _performance_monitor.has_method("bind_scene_root"):
		_performance_monitor.call("bind_scene_root", _art_presentation)


func _tag_greybox_visuals() -> void:
	if _greybox_tagged:
		return
	_greybox_tagged = true

	# Only tag level greybox decoration — never NPC/enemy Polygon2D visuals.
	var greybox_roots: Array[StringName] = [&"Solids", &"Exits"]
	for root_name in greybox_roots:
		var root := get_node_or_null(NodePath(String(root_name)))
		if root == null:
			continue
		for node in root.find_children("*", "Polygon2D", true, false):
			if node is Polygon2D and not node.is_in_group(GREYBOX_VISUAL_GROUP):
				node.add_to_group(GREYBOX_VISUAL_GROUP)

	for prop_name in [&"SecretCache", &"HeartSymbol"]:
		var prop := get_node_or_null("WorldObjects/%s" % String(prop_name))
		if prop is Polygon2D and not prop.is_in_group(GREYBOX_VISUAL_GROUP):
			prop.add_to_group(GREYBOX_VISUAL_GROUP)

	for node in find_children("*", "Label", true, false):
		if node.name in DEBUG_LABEL_NAMES:
			if not node.is_in_group(GREYBOX_VISUAL_GROUP):
				node.add_to_group(GREYBOX_VISUAL_GROUP)


func _set_greybox_visible(visible_state: bool) -> void:
	for node in get_tree().get_nodes_in_group(GREYBOX_VISUAL_GROUP):
		if is_ancestor_of(node) and node is Polygon2D:
			node.visible = visible_state


func _set_debug_labels_visible(visible_state: bool) -> void:
	for node in find_children("*", "Label", true, false):
		if node.name in DEBUG_LABEL_NAMES:
			node.visible = visible_state
