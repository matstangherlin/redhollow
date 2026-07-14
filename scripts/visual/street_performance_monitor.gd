extends CanvasLayer
class_name StreetPerformanceMonitor

## Runtime performance overlay for the street north-star / final sample.

@export var show_by_default: bool = false

var _label: Label = null
var _visible_state: bool = false
var _particle_count: int = 0
var _light_count: int = 0
var _sample_stats: Dictionary = {}
var _first_frame_ms: float = -1.0
var _frames_seen: int = 0
var _texture_bytes_est: int = 0


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_label()
	set_monitor_visible(show_by_default)


func bind_scene_root(root: Node) -> void:
	_particle_count = _count_nodes(root, "GPUParticles2D")
	_light_count = _count_nodes(root, "PointLight2D") + _count_nodes(root, "DirectionalLight2D")
	_texture_bytes_est = _estimate_texture_bytes(root)


func note_sample_stats(stats: Dictionary) -> void:
	_sample_stats = stats.duplicate(true)


func set_monitor_visible(is_visible: bool) -> void:
	_visible_state = is_visible
	visible = is_visible
	if _label != null:
		_label.visible = is_visible


func toggle_visible() -> void:
	set_monitor_visible(not _visible_state)


func is_monitor_visible() -> bool:
	return _visible_state


func get_snapshot() -> Dictionary:
	return {
		"fps": Engine.get_frames_per_second(),
		"frame_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0),
		"lights": _light_count,
		"particles": _particle_count,
		"texture_bytes_est": _texture_bytes_est,
		"first_frame_ms": _first_frame_ms,
		"sample": _sample_stats,
	}


func _build_label() -> void:
	_label = Label.new()
	_label.name = "PerfLabel"
	_label.position = Vector2(12, 48)
	_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 0.92))
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)


func _process(_delta: float) -> void:
	_frames_seen += 1
	var frame_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	if _frames_seen == 1:
		_first_frame_ms = frame_ms

	if not _visible_state or _label == null:
		return

	var fps := Engine.get_frames_per_second()
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var tex_mb := float(_texture_bytes_est) / (1024.0 * 1024.0)
	var band := ""
	if not _sample_stats.is_empty():
		band = (
			" | sample X %d–%d mats %d lights+%d parts+%d"
			% [
				int(_sample_stats.get("band_x_min", 0)),
				int(_sample_stats.get("band_x_max", 0)),
				int(_sample_stats.get("materials", 0)),
				int(_sample_stats.get("lights", 0)),
				int(_sample_stats.get("particles", 0)),
			]
		)

	_label.text = (
		"Street Perf | FPS %d | frame %.2f ms | physics %.2f ms | stutter0 %.2f ms\n"
		+ "draw calls %d | primitives %d | lights %d | particles %d\n"
		+ "memory %.1f MB | tex~ %.2f MB | objects %d | P toggle%s"
		% [
			fps,
			frame_ms,
			physics_ms,
			_first_frame_ms,
			draw_calls,
			primitives,
			_light_count,
			_particle_count,
			memory_mb,
			tex_mb,
			objects,
			band,
		]
	)


func _count_nodes(root: Node, class_name_text: String) -> int:
	var count := 0
	for node in root.find_children("*", class_name_text, true, false):
		count += 1
	return count


func _estimate_texture_bytes(root: Node) -> int:
	var total := 0
	var seen: Dictionary = {}
	for node in root.find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var key := sprite.texture.resource_path
		if key.is_empty() or seen.has(key):
			continue
		seen[key] = true
		var size := sprite.texture.get_size()
		total += int(size.x * size.y * 4.0)
	return total
