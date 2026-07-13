extends AreaRoot
class_name StreetArtArea

## Art variant of the street: identical gameplay, presentation swapped.

const ART_PRESENTATION_SCENE := preload("res://scenes/environment/chapter_zero/street_art_presentation.tscn")
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

@export var show_greybox_visuals: bool = false
@export var show_art_presentation: bool = true

var _art_presentation: StreetArtPresentation = null
var _greybox_tagged: bool = false
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
				var presentation := get_art_presentation()
				if presentation == null:
					return
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


func _ensure_gameplay_draw_order() -> void:
	# Gameplay entities must render above art foreground (z 40) and atmosphere (z 50).
	for node_name in [&"WorldObjects", &"Exits", &"Spawns"]:
		var node := get_node_or_null(NodePath(String(node_name)))
		if node is CanvasItem:
			(node as CanvasItem).z_index = 70


func set_visual_mode(use_art: bool) -> void:
	show_art_presentation = use_art
	show_greybox_visuals = not use_art
	_apply_visual_mode()


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
