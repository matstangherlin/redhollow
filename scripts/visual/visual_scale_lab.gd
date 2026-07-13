extends Node2D

## Visual-only laboratory to compare Calder sprite scales before art production.
## Does NOT modify player collision, AttackData, or movement.

const SilhouetteFactory := preload("res://scripts/visual/visual_scale_silhouette_factory.gd")

const PROFILE_32X56 := "res://resources/visual/scale_profiles/scale_32x56.tres"
const PROFILE_40X72 := "res://resources/visual/scale_profiles/scale_40x72.tres"
const PROFILE_48X80 := "res://resources/visual/scale_profiles/scale_48x80.tres"
const STRAIGHT_ATTACK := preload("res://resources/combat/calder_straight.tres")
const GAMEPLAY_COLLISION := Vector2(32, 56)

enum LayoutMode { SIDE_BY_SIDE, FOCUS }
enum CameraMode { CURRENT, CLOSE, INTERMEDIATE }
enum ResolutionRef { VIEW_1152, VIEW_1920 }

const CAMERA_ZOOM := {
	CameraMode.CURRENT: 1.0,
	CameraMode.CLOSE: 1.12,
	CameraMode.INTERMEDIATE: 1.28,
}
const RESOLUTION_REFS := {
	ResolutionRef.VIEW_1152: Vector2(1152, 648),
	ResolutionRef.VIEW_1920: Vector2(1920, 1080),
}
const COLUMN_SPACING := 720.0
const GROUND_Y := 900.0
const HUD_MOCK_HEIGHT := 48.0

@onready var _world: Node2D = $World
@onready var _columns_root: Node2D = $World/Columns
@onready var _lab_camera: Camera2D = $LabCamera
@onready var _hud_label: Label = $UI/Panel/Margin/VBox/HeaderLabel
@onready var _metrics_label: Label = $UI/Panel/Margin/VBox/MetricsLabel
@onready var _help_label: Label = $UI/Panel/Margin/VBox/HelpLabel
@onready var _preview_viewport: SubViewport = $UI/PreviewFrame/SubViewport
@onready var _preview_world: Node2D = $UI/PreviewFrame/SubViewport/PreviewWorld
@onready var _preview_camera: Camera2D = $UI/PreviewFrame/SubViewport/PreviewCamera
@onready var _hud_mock: ColorRect = $UI/PreviewFrame/SubViewport/HudMock

var _profiles: Array = []
var _columns: Array[Node2D] = []
var _layout_mode: LayoutMode = LayoutMode.SIDE_BY_SIDE
var _selected_scale: int = 0
var _camera_mode: CameraMode = CameraMode.CURRENT
var _resolution_ref: ResolutionRef = ResolutionRef.VIEW_1152
var _show_hud_mock: bool = true
var _show_projectile: bool = true
var _preview_column: Node2D = null


func _enemy_height(profile: Resource, enemy_id: StringName) -> int:
	return int(profile.call(&"get_enemy_height", enemy_id))


func _collision_mismatch(profile: Resource) -> Vector2i:
	return profile.call(&"get_collision_mismatch_px") as Vector2i


func _ready() -> void:
	_load_profiles()
	_build_ground()
	_build_columns()
	_refresh_layout()
	_sync_preview_world()
	_resize_preview_viewport()
	_update_ui()
	_lab_camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				_select_scale(0)
			KEY_2, KEY_KP_2:
				_select_scale(1)
			KEY_3, KEY_KP_3:
				_select_scale(2)
			KEY_4, KEY_KP_4:
				_set_camera_mode(CameraMode.CURRENT)
			KEY_5, KEY_KP_5:
				_set_camera_mode(CameraMode.CLOSE)
			KEY_6, KEY_KP_6:
				_set_camera_mode(CameraMode.INTERMEDIATE)
			KEY_TAB:
				_layout_mode = LayoutMode.FOCUS if _layout_mode == LayoutMode.SIDE_BY_SIDE else LayoutMode.SIDE_BY_SIDE
				_refresh_layout()
				_update_ui()
			KEY_H:
				_show_hud_mock = not _show_hud_mock
				if _hud_mock != null:
					_hud_mock.visible = _show_hud_mock
				_update_ui()
			KEY_P:
				_show_projectile = not _show_projectile
				_sync_preview_world()
				_update_ui()
			KEY_R:
				_resolution_ref = ResolutionRef.VIEW_1920 if _resolution_ref == ResolutionRef.VIEW_1152 else ResolutionRef.VIEW_1152
				_resize_preview_viewport()
				_update_ui()
			KEY_LEFT, KEY_A:
				_pan_lab(-120.0)
			KEY_RIGHT, KEY_D:
				_pan_lab(120.0)


func _load_profiles() -> void:
	_profiles.clear()
	for path in [PROFILE_32X56, PROFILE_40X72, PROFILE_48X80]:
		var profile: Resource = load(path) as Resource
		if profile != null and profile.has_method("get_enemy_height"):
			_profiles.append(profile)


func _build_ground() -> void:
	var ground := Polygon2D.new()
	ground.name = "Ground"
	ground.color = Color(0.34, 0.26, 0.2, 1.0)
	ground.polygon = PackedVector2Array([
		Vector2(-200, GROUND_Y),
		Vector2(3000, GROUND_Y),
		Vector2(3000, GROUND_Y + 12),
		Vector2(-200, GROUND_Y + 12),
	])
	_world.add_child(ground)
	_world.move_child(ground, 0)


func _build_columns() -> void:
	for child in _columns_root.get_children():
		child.queue_free()
	_columns.clear()

	for index in range(_profiles.size()):
		var column := _build_column(_profiles[index], index)
		_columns_root.add_child(column)
		_columns.append(column)


func _build_column(profile: Resource, index: int) -> Node2D:
	var column := Node2D.new()
	column.name = "ScaleColumn_%d" % index

	var label := Label.new()
	label.name = "Title"
	label.text = profile.display_name
	label.position = Vector2(-80, GROUND_Y - 220)
	label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1.0))
	label.add_theme_font_size_override("font_size", 12)
	column.add_child(label)

	_add_environment(column, Vector2(0, GROUND_Y))
	_add_character_column(column, profile)

	return column


func _add_environment(parent: Node2D, origin: Vector2) -> void:
	var saloon := _make_prop_sprite(&"saloon", origin + Vector2(-220, -128))
	parent.add_child(saloon)

	var door := _make_prop_sprite(&"door", origin + Vector2(-40, -64))
	parent.add_child(door)

	var window := _make_prop_sprite(&"window", origin + Vector2(80, -96))
	parent.add_child(window)

	var sidewalk := _make_prop_sprite(&"sidewalk", origin + Vector2(-128, -12))
	parent.add_child(sidewalk)

	var platform := _make_prop_sprite(&"platform", origin + Vector2(160, -48))
	parent.add_child(platform)

	var barrel := _make_prop_sprite(&"barrel", origin + Vector2(120, -40))
	parent.add_child(barrel)


func _add_character_column(parent: Node2D, profile: Resource) -> void:
	var origin := Vector2.ZERO

	var calder := _make_sprite_node(
		"Calder",
		SilhouetteFactory.create_calder_idle_texture(profile.frame_size),
		origin + Vector2(0, -profile.frame_size.y)
	)
	parent.add_child(calder)

	var brawler_h: int = _enemy_height(profile, &"brawler")
	var brawler_w := int(round(float(brawler_h) * 0.6))
	var brawler := _make_sprite_node(
		"CultBrawler",
		SilhouetteFactory.create_enemy_texture(&"brawler", Vector2i(brawler_w, brawler_h)),
		origin + Vector2(-120, -brawler_h)
	)
	parent.add_child(brawler)

	var gun_h: int = _enemy_height(profile, &"gunslinger")
	var gun_w := int(round(float(gun_h) * 0.58))
	var gunslinger := _make_sprite_node(
		"Gunslinger",
		SilhouetteFactory.create_enemy_texture(&"gunslinger", Vector2i(gun_w, gun_h)),
		origin + Vector2(140, -gun_h)
	)
	parent.add_child(gunslinger)

	_add_gameplay_collision_overlay(parent, origin)
	_add_attack_reach_overlay(parent, origin)
	_add_deacon_marker(parent, profile, origin + Vector2(0, -180))


func _make_prop_sprite(prop_id: StringName, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = String(prop_id)
	sprite.texture = SilhouetteFactory.create_prop_texture(prop_id)
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


func _make_sprite_node(node_name: String, texture: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = pos
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return sprite


func _add_gameplay_collision_overlay(parent: Node2D, origin: Vector2) -> void:
	var top_left := origin + Vector2(-GAMEPLAY_COLLISION.x * 0.5, -GAMEPLAY_COLLISION.y)
	var fill := Polygon2D.new()
	fill.name = "GameplayCollisionOverlay"
	fill.color = Color(0.2, 0.9, 0.4, 0.18)
	fill.polygon = PackedVector2Array([
		top_left,
		top_left + Vector2(GAMEPLAY_COLLISION.x, 0),
		top_left + GAMEPLAY_COLLISION,
		top_left + Vector2(0, GAMEPLAY_COLLISION.y),
	])
	parent.add_child(fill)


func _add_attack_reach_overlay(parent: Node2D, origin: Vector2) -> void:
	var attack: AttackData = STRAIGHT_ATTACK
	var hb_size: Vector2 = attack.hitbox_size
	var hb_offset: Vector2 = attack.hitbox_offset
	var center := origin + hb_offset
	var rect_pos := center - hb_size * 0.5

	var reach := Polygon2D.new()
	reach.name = "AttackReachOverlay"
	reach.color = Color(0.95, 0.75, 0.15, 0.22)
	reach.polygon = PackedVector2Array([
		rect_pos,
		rect_pos + Vector2(hb_size.x, 0),
		rect_pos + hb_size,
		rect_pos + Vector2(0, hb_size.y),
	])
	parent.add_child(reach)

	var reach_line := Line2D.new()
	reach_line.name = "AttackReachLine"
	reach_line.width = 1.0
	reach_line.default_color = Color(0.98, 0.82, 0.2, 0.95)
	reach_line.points = PackedVector2Array([
		origin + Vector2(0, -28),
		center,
	])
	parent.add_child(reach_line)


func _add_deacon_marker(parent: Node2D, profile: Resource, pos: Vector2) -> void:
	var deacon_h: int = _enemy_height(profile, &"deacon")
	var deacon_w := int(round(float(deacon_h) * 0.58))
	var ghost := _make_sprite_node(
		"DeaconGhost",
		SilhouetteFactory.create_enemy_texture(&"brawler", Vector2i(deacon_w, deacon_h)),
		pos + Vector2(0, -deacon_h)
	)
	ghost.modulate = Color(0.55, 0.12, 0.18, 0.35)
	parent.add_child(ghost)

	var label := Label.new()
	label.name = "DeaconLabel"
	label.text = "Deacon ~%dpx" % deacon_h
	label.position = pos + Vector2(-36, -deacon_h - 18)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.85, 0.5, 0.55, 0.8))
	parent.add_child(label)


func _select_scale(index: int) -> void:
	_selected_scale = clampi(index, 0, _profiles.size() - 1)
	_refresh_layout()
	_sync_preview_world()
	_update_ui()


func _set_camera_mode(mode: CameraMode) -> void:
	_camera_mode = mode
	_apply_preview_camera()
	_update_ui()


func _refresh_layout() -> void:
	for index in range(_columns.size()):
		var column: Node2D = _columns[index]
		var visible := _layout_mode == LayoutMode.SIDE_BY_SIDE or index == _selected_scale
		column.visible = visible
		if _layout_mode == LayoutMode.SIDE_BY_SIDE:
			column.position = Vector2(280.0 + float(index) * COLUMN_SPACING, 0.0)
		else:
			column.position = Vector2(640.0, 0.0)

	if _layout_mode == LayoutMode.FOCUS:
		_lab_camera.position = Vector2(640, GROUND_Y - 180)
	else:
		_lab_camera.position = Vector2(1100, GROUND_Y - 180)

	_apply_preview_camera()


func _pan_lab(delta_x: float) -> void:
	_lab_camera.position.x += delta_x


func _sync_preview_world() -> void:
	for child in _preview_world.get_children():
		child.queue_free()

	if _selected_scale < 0 or _selected_scale >= _columns.size():
		return

	var source: Node2D = _columns[_selected_scale]
	_preview_column = source.duplicate() as Node2D
	_preview_column.position = Vector2(360, GROUND_Y)
	_preview_world.add_child(_preview_column)

	if not _show_projectile:
		var projectile := _preview_column.get_node_or_null("ProjectileMarker")
		if projectile != null:
			projectile.visible = false
	else:
		_add_projectile_marker(_preview_column)

	_apply_preview_camera()


func _add_projectile_marker(column: Node2D) -> void:
	if column.get_node_or_null("ProjectileMarker") != null:
		return
	var marker := Sprite2D.new()
	marker.name = "ProjectileMarker"
	var image := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.85, 0.2, 0.45, 1.0))
	marker.texture = ImageTexture.create_from_image(image)
	marker.position = Vector2(200, -72)
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(marker)


func _resize_preview_viewport() -> void:
	var ref_size: Vector2 = RESOLUTION_REFS[_resolution_ref]
	var display_scale := 0.33
	_preview_viewport.size = Vector2i(int(ref_size.x), int(ref_size.y))
	$UI/PreviewFrame.custom_minimum_size = ref_size * display_scale
	$UI/PreviewFrame.size = ref_size * display_scale
	if _hud_mock != null:
		_hud_mock.size = Vector2(ref_size.x, HUD_MOCK_HEIGHT)
		_hud_mock.visible = _show_hud_mock
	_apply_preview_camera()


func _apply_preview_camera() -> void:
	if _preview_camera == null:
		return
	var zoom: float = CAMERA_ZOOM[_camera_mode]
	_preview_camera.position = Vector2(360, GROUND_Y - 160)
	_preview_camera.zoom = Vector2.ONE * zoom
	_lab_camera.zoom = Vector2.ONE * (0.85 if _layout_mode == LayoutMode.SIDE_BY_SIDE else 1.0)


func _update_ui() -> void:
	var profile: Resource = _profiles[_selected_scale]
	var ref_size: Vector2 = RESOLUTION_REFS[_resolution_ref]
	var zoom: float = CAMERA_ZOOM[_camera_mode]
	var metrics := _compute_metrics(profile, ref_size, zoom)

	if _hud_label != null:
		_hud_label.text = (
			"Visual Scale Lab — %s | layout: %s | câmera: %s | ref: %dx%d"
			% [
				profile.display_name,
				"FOCUS" if _layout_mode == LayoutMode.FOCUS else "LADO A LADO",
				_camera_mode_name(_camera_mode),
				int(ref_size.x),
				int(ref_size.y),
			]
		)

	if _metrics_label != null:
		_metrics_label.text = metrics

	if _help_label != null:
		_help_label.text = (
			"1/2/3 escala | 4/5/6 câmera | Tab layout | R ref 1152/1920 | H HUD | P projétil | A/D pan"
		)

	_queue_debug_print(profile, metrics)


func _compute_metrics(profile: Resource, viewport_size: Vector2, zoom: float) -> String:
	var frame_h := float(profile.frame_size.y)
	var frame_w := float(profile.frame_size.x)
	var visible_h := viewport_size.y / zoom
	var visible_w := viewport_size.x / zoom

	var calder_screen_pct := (frame_h * zoom / viewport_size.y) * 100.0
	var chars_across := visible_w / (frame_w * 1.35)
	var attack_reach := STRAIGHT_ATTACK.hitbox_offset.x + STRAIGHT_ATTACK.hitbox_size.x * 0.5
	var deacon_h: float = float(_enemy_height(profile, &"deacon"))
	var boss_headroom := visible_h - deacon_h - HUD_MOCK_HEIGHT
	var platform_tile := 16.0
	var platform_steps := frame_h / platform_tile
	var brand_px := float(profile.get("red_brand_zone_px").x)
	var mismatch: Vector2i = _collision_mismatch(profile)
	var detail_score := frame_w * frame_h
	var anim_cost: float = float(profile.get("animation_cost_multiplier"))

	var lines: PackedStringArray = PackedStringArray()
	lines.append("— Métricas (visual only; colisão gameplay permanece 32×56) —")
	lines.append("Calder na tela: %.1f%% da altura visível" % calder_screen_pct)
	lines.append("Personagens na largura (est.): %.1f" % chars_across)
	lines.append("Alcance visual ataque (hitbox real): %.0f px" % attack_reach)
	lines.append("Espaço chefe (Deacon %dpx): %.0f px acima do chão livres" % [int(deacon_h), boss_headroom])
	lines.append("Plataforma 16px: %.1f× altura Calder" % platform_steps)
	lines.append("Red Brand legível: ~%.0f px (zona alvo ≥8px ideal)" % (brand_px * zoom))
	lines.append("Detalhe possível (px/frame): %d" % int(detail_score))
	lines.append("Custo animação relativo: %.2f× baseline" % anim_cost)
	lines.append(
		"Risco colisão vs sprite: +%d× +%d px (verde=gameplay)" % [mismatch.x, mismatch.y]
	)
	lines.append("HUD mock: %d px (%.1f%% tela)" % [int(HUD_MOCK_HEIGHT), HUD_MOCK_HEIGHT * zoom / viewport_size.y * 100.0])
	lines.append("Área visível: %.0f × %.0f px @ zoom %.2f" % [visible_w, visible_h, zoom])
	return "\n".join(lines)


func _camera_mode_name(mode: CameraMode) -> String:
	match mode:
		CameraMode.CURRENT:
			return "atual (1.0)"
		CameraMode.CLOSE:
			return "aproximada (1.12)"
		CameraMode.INTERMEDIATE:
			return "intermediária (1.28)"
	return "?"


func _queue_debug_print(profile: Resource, metrics: String) -> void:
	if not OS.is_debug_build():
		return
	print("[VisualScaleLab] profile=%s" % String(profile.get("profile_id")))
	print(metrics)
