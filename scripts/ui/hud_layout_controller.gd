extends Node
class_name HudLayoutController

const HUD_LAYOUT_GROUP := "hud_layout_controller"

@export var use_hud_v2: bool = false
@export var allow_runtime_toggle: bool = true
@export var hide_legacy_demo_hints_when_v2: bool = true

var _game_root: Node = null
var _legacy_objective: ObjectiveHud = null
var _legacy_style_hud: StyleHud = null
var _hud_v2: HudShellV2 = null
var _demo_hints: CanvasLayer = null


func _ready() -> void:
	add_to_group(HUD_LAYOUT_GROUP)
	call_deferred("_late_setup")


func _unhandled_input(event: InputEvent) -> void:
	if not allow_runtime_toggle:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		apply_layout(not use_hud_v2)
		get_viewport().set_input_as_handled()


func is_using_hud_v2() -> bool:
	return use_hud_v2


func get_active_objective_hud() -> ObjectiveHud:
	if use_hud_v2 and _hud_v2 != null:
		return _hud_v2.get_objective_hud()
	return _legacy_objective


func get_active_style_hud() -> StyleHud:
	if use_hud_v2 and _hud_v2 != null:
		return _hud_v2.get_style_hud()
	return _legacy_style_hud


func apply_layout(enable_v2: bool) -> void:
	use_hud_v2 = enable_v2

	if _legacy_objective != null:
		_legacy_objective.visible = not enable_v2
	if _legacy_style_hud != null:
		_legacy_style_hud.visible = not enable_v2
	if _hud_v2 != null:
		_hud_v2.set_shell_visible(enable_v2)
	if _demo_hints != null and hide_legacy_demo_hints_when_v2:
		_demo_hints.visible = not enable_v2

	_rebind_hud_targets()
	print("[HudLayout] Using HUD %s (F3 alterna)." % ("V2" if enable_v2 else "legado"))


func _late_setup() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	_game_root = get_parent()
	if _game_root == null:
		return

	_legacy_objective = _game_root.get_node_or_null("ObjectiveHud") as ObjectiveHud
	_legacy_style_hud = _game_root.get_node_or_null("StyleManager/StyleHud") as StyleHud
	_hud_v2 = _game_root.get_node_or_null("HudV2") as HudShellV2
	_demo_hints = _game_root.get_node_or_null("VerticalSliceController/DemoHints") as CanvasLayer

	apply_layout(use_hud_v2)


func _rebind_hud_targets() -> void:
	if _game_root == null:
		return

	var game_services := _game_root.get_node_or_null("GameServices") as GameServices
	var style_hud := get_active_style_hud()

	if game_services != null and game_services.style_manager != null:
		game_services.style_manager.bind_style_hud(style_hud)
	if game_services != null and game_services.red_brand_director != null:
		if game_services.red_brand_director.has_method("bind_style_hud"):
			game_services.red_brand_director.call("bind_style_hud", style_hud)

	var director := _game_root.get_node_or_null("NarrativeDirector")
	var objective_hud := get_active_objective_hud()
	if director != null and objective_hud != null and director.has_method("bind_objective_hud"):
		director.call("bind_objective_hud", objective_hud)
