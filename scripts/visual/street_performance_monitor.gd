extends CanvasLayer
class_name StreetPerformanceMonitor

## Runtime performance overlay for the street north-star slice (debug layer).

@export var show_by_default: bool = false

var _label: Label = null
var _visible_state: bool = false
var _particle_count: int = 0
var _light_count: int = 0


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_label()
	set_monitor_visible(show_by_default)


func bind_scene_root(root: Node) -> void:
	_particle_count = _count_nodes(root, "GPUParticles2D")
	_light_count = _count_nodes(root, "PointLight2D") + _count_nodes(root, "DirectionalLight2D")


func set_monitor_visible(is_visible: bool) -> void:
	_visible_state = is_visible
	visible = is_visible
	if _label != null:
		_label.visible = is_visible


func toggle_visible() -> void:
	set_monitor_visible(not _visible_state)


func is_monitor_visible() -> bool:
	return _visible_state


func _build_label() -> void:
	_label = Label.new()
	_label.name = "PerfLabel"
	_label.position = Vector2(12, 48)
	_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 0.92))
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)


func _process(_delta: float) -> void:
	if not _visible_state or _label == null:
		return

	var fps := Engine.get_frames_per_second()
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))

	_label.text = (
		"Street Perf | FPS %d | frame %.2f ms | physics %.2f ms\n"
		+ "draw calls %d | primitives %d | lights %d | particles %d\n"
		+ "memory %.1f MB | objects %d | P toggle perf"
		% [fps, frame_ms, physics_ms, draw_calls, primitives, _light_count, _particle_count, memory_mb, objects]
	)


func _count_nodes(root: Node, class_name_text: String) -> int:
	var count := 0
	for node in root.find_children("*", class_name_text, true, false):
		count += 1
	return count
