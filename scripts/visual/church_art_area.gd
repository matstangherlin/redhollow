extends AreaRoot
class_name ChurchArtArea

## Art variant of the church district: identical gameplay, presentation swapped.
## Modes: greybox | north_star | final_candidate (approved mold → full 1800 px church).
## Does NOT alter catacombs.

const ART_PRESENTATION_SCENE := preload("res://scenes/environment/chapter_zero/church_art_presentation.tscn")
const Spec := preload("res://scripts/visual/church_final_mold_spec.gd")
const FinalMoldComposer := preload("res://scripts/visual/church_final_mold_composer.gd")
const GREYBOX_VISUAL_GROUP := "church_greybox_visual"
const DEBUG_LABEL_NAMES: Array[StringName] = [
	&"AreaLabel",
	&"GuideLabel",
	&"PenitentPrompt",
	&"PassagePrompt",
	&"ExitLabel",
	&"FeedbackLabel",
]

@export var show_greybox_visuals: bool = false
@export var show_art_presentation: bool = true
## When true (and art presentation on), applies the approved final mold to the full church.
@export var enable_final_sample: bool = false

var _art_presentation: ChurchArtPresentation = null
var _performance_monitor: Node = null
var _visual_mode: StringName = Spec.MODE_NORTH_STAR
var _mold_stats: Dictionary = {}
var _greybox_tagged: bool = false


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
		_art_presentation = ART_PRESENTATION_SCENE.instantiate() as ChurchArtPresentation
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

	_apply_final_mold_layer()


func _apply_final_mold_layer() -> void:
	if _art_presentation == null or not show_art_presentation:
		return
	if _visual_mode == Spec.MODE_FINAL_CANDIDATE:
		var profile: EnvironmentVisualProfile = _art_presentation.profile
		if profile == null:
			profile = load("res://resources/visual/chapter_zero_church_profile.tres") as EnvironmentVisualProfile
		_mold_stats = FinalMoldComposer.apply(_art_presentation, profile)
		_refresh_perf_binding()
	else:
		FinalMoldComposer.remove(_art_presentation)
		_mold_stats = {}


func _refresh_perf_binding() -> void:
	if _performance_monitor != null and _art_presentation != null:
		if _performance_monitor.has_method("bind_scene_root"):
			_performance_monitor.call("bind_scene_root", _art_presentation)
		if _performance_monitor.has_method("note_sample_stats"):
			_performance_monitor.call("note_sample_stats", _mold_stats)


func _ensure_gameplay_draw_order() -> void:
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
	return _mold_stats.duplicate(true)


func get_art_presentation() -> ChurchArtPresentation:
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
	_performance_monitor.name = "ChurchPerformanceMonitor"
	debug_layer.add_child(_performance_monitor)
	if _performance_monitor.has_method("bind_scene_root"):
		_performance_monitor.call("bind_scene_root", _art_presentation)


func _tag_greybox_visuals() -> void:
	if _greybox_tagged:
		return
	_greybox_tagged = true

	for node in find_children("*", "Polygon2D", true, false):
		if node is Polygon2D and not node.is_in_group(GREYBOX_VISUAL_GROUP):
			var path := String(node.get_path())
			if path.contains("Solids") or path.contains("Exits") or path.contains("ActivationVisual"):
				node.add_to_group(GREYBOX_VISUAL_GROUP)

	for node in find_children("*", "Label", true, false):
		if node.name in DEBUG_LABEL_NAMES and not node.is_in_group(GREYBOX_VISUAL_GROUP):
			node.add_to_group(GREYBOX_VISUAL_GROUP)


func _set_greybox_visible(visible_state: bool) -> void:
	for node in get_tree().get_nodes_in_group(GREYBOX_VISUAL_GROUP):
		if is_ancestor_of(node) and node is Polygon2D:
			node.visible = visible_state


func _set_debug_labels_visible(visible_state: bool) -> void:
	for node in find_children("*", "Label", true, false):
		if node.name in DEBUG_LABEL_NAMES:
			node.visible = visible_state
