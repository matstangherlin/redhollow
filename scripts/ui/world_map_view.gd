extends Control
class_name WorldMapView

## Provisional beta map — rectangles and lines only.

const COLOR_BG := Color(0.08, 0.07, 0.06, 0.92)
const COLOR_GRID := Color(0.2, 0.18, 0.16, 0.35)
const COLOR_NODE := Color(0.42, 0.32, 0.24, 1.0)
const COLOR_NODE_VISITED := Color(0.55, 0.4, 0.28, 1.0)
const COLOR_CURRENT := Color(0.92, 0.42, 0.18, 1.0)
const COLOR_OBJECTIVE := Color(0.95, 0.78, 0.22, 1.0)
const COLOR_CHECKPOINT := Color(0.35, 0.82, 0.95, 1.0)
const COLOR_BARRIER := Color(0.92, 0.18, 0.12, 1.0)
const COLOR_EDGE := Color(0.72, 0.62, 0.5, 0.65)
const COLOR_EDGE_BLOCKED := Color(0.55, 0.22, 0.18, 0.8)
const COLOR_SECRET := Color(0.78, 0.62, 0.95, 1.0)
const COLOR_HIDDEN := Color(0.12, 0.1, 0.09, 0.2)

const CELL_SIZE := Vector2(88, 56)
const GRID_OFFSET := Vector2(48, 40)

@export var world_map_service_path: NodePath
@export var visible_by_default: bool = false

var _service: WorldMapService = null


func _ready() -> void:
	visible = visible_by_default
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resolve_service()
	if _service != null and not _service.map_state_changed.is_connected(_on_map_state_changed):
		_service.map_state_changed.connect(_on_map_state_changed)


func set_map_visible(is_visible: bool) -> void:
	visible = is_visible
	queue_redraw()


func toggle_map_visible() -> void:
	set_map_visible(not visible)


func refresh() -> void:
	queue_redraw()


func _resolve_service() -> void:
	if world_map_service_path != NodePath(""):
		_service = get_node_or_null(world_map_service_path) as WorldMapService
	if _service == null:
		for node in get_tree().get_nodes_in_group(WorldMapService.SERVICE_GROUP):
			if node is WorldMapService:
				_service = node
				return


func _on_map_state_changed() -> void:
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	_resolve_service()
	if _service == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG, true)
	_draw_grid()

	var node_centers: Dictionary = {}
	for node in _service.get_visible_nodes():
		var state: Dictionary = _service.get_node_display_state(node.area_id)
		var center := _node_center(state.get("map_position", Vector2i.ZERO))
		node_centers[String(node.area_id)] = center
		_draw_node(state, center)

	for connection in _service.get_visible_connections():
		_draw_connection(connection, node_centers)


func _draw_grid() -> void:
	var cols := 10
	var rows := 6
	for x in range(cols + 1):
		var px := GRID_OFFSET.x + float(x) * CELL_SIZE.x
		draw_line(Vector2(px, GRID_OFFSET.y), Vector2(px, GRID_OFFSET.y + rows * CELL_SIZE.y), COLOR_GRID, 1.0)
	for y in range(rows + 1):
		var py := GRID_OFFSET.y + float(y) * CELL_SIZE.y
		draw_line(Vector2(GRID_OFFSET.x, py), Vector2(GRID_OFFSET.x + cols * CELL_SIZE.x, py), COLOR_GRID, 1.0)


func _draw_node(state: Dictionary, center: Vector2) -> void:
	var rect := Rect2(center - CELL_SIZE * 0.38, CELL_SIZE * 0.76)
	var fill := COLOR_NODE
	if bool(state.get("is_visited", false)):
		fill = COLOR_NODE_VISITED
	if bool(state.get("is_current", false)):
		fill = COLOR_CURRENT
	if bool(state.get("is_objective", false)):
		draw_rect(rect.grow(4), COLOR_OBJECTIVE, false, 2.0)
	draw_rect(rect, fill, true)
	draw_rect(rect, Color(0.12, 0.1, 0.08, 1.0), false, 1.5)

	var label := String(state.get("display_name", ""))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, 14), label, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 8), 10, Color(0.95, 0.9, 0.82, 1.0))

	if bool(state.get("has_checkpoint", false)):
		draw_circle(rect.position + Vector2(rect.size.x - 10, 10), 4.0, COLOR_CHECKPOINT)
	if bool(state.get("has_barrier", false)):
		draw_rect(Rect2(rect.position + Vector2(6, rect.size.y - 12), Vector2(10, 6)), COLOR_BARRIER, true)
	var secrets_found := int(state.get("secrets_found", 0))
	if secrets_found > 0:
		draw_circle(rect.position + Vector2(12, rect.size.y - 10), 3.0, COLOR_SECRET)


func _draw_connection(connection: AreaConnectionData, centers: Dictionary) -> void:
	var from_center: Variant = centers.get(String(connection.from_area_id), null)
	var to_center: Variant = centers.get(String(connection.to_area_id), null)
	if from_center == null or to_center == null:
		return

	var color := COLOR_EDGE
	if connection.is_blocked_display and not _service.is_connection_available(connection):
		color = COLOR_EDGE_BLOCKED
	if connection.is_secret_passage:
		color = COLOR_SECRET
	if connection.is_shortcut:
		_draw_dashed_line(from_center, to_center, color, 2.0, 6.0)
	else:
		draw_line(from_center, to_center, color, 2.0)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float) -> void:
	var delta := to - from
	var length := delta.length()
	if length < 0.001:
		return
	var direction := delta / length
	var cursor := from
	var draw_segment := true
	while cursor.distance_to(to) > dash_length:
		var next := cursor + direction * dash_length
		if draw_segment:
			draw_line(cursor, next, color, width)
		draw_segment = not draw_segment
		cursor = next
	if draw_segment:
		draw_line(cursor, to, color, width)


func _node_center(map_position: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(map_position) * CELL_SIZE + CELL_SIZE * 0.5
