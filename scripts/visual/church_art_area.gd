extends AreaRoot
class_name ChurchArtArea

## Art variant of the church district: identical gameplay, presentation swapped.

const ART_PRESENTATION_SCENE := preload("res://scenes/environment/chapter_zero/church_art_presentation.tscn")
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

var _art_presentation: ChurchArtPresentation = null
var _performance_monitor: Node = null


func _ready() -> void:
	super._ready()
	call_deferred("_apply_visual_mode")


func _unhandled_input(event: InputEvent) -> void:
	if not show_art_presentation:
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


func _apply_visual_mode() -> void:
	_tag_greybox_visuals()
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


func _ensure_gameplay_draw_order() -> void:
	for node_name in [&"WorldObjects", &"Exits", &"Spawns"]:
		var node := get_node_or_null(NodePath(String(node_name)))
		if node is CanvasItem:
			(node as CanvasItem).z_index = 70


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
