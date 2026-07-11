extends Node

const STYLE_TRACKABLE_GROUP := "style_trackable"
const PLAYER_GROUP := "player"

@export var arena_path: NodePath
@export var style_hud_path: NodePath

var _player: Node = null
var _red_brand_component: RedBrandComponent = null
var _style_hud: Node = null


func _ready() -> void:
	add_to_group("red_brand_director")
	await get_tree().process_frame
	_bind_arena()


func refresh_world_bindings() -> void:
	_bind_enemy_deaths()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		reset_red_brand()


func reset_red_brand() -> void:
	if _red_brand_component != null:
		_red_brand_component.reset_energy()


func _bind_arena() -> void:
	_player = get_tree().get_first_node_in_group(PLAYER_GROUP)
	if _player == null:
		var arena := get_node_or_null(arena_path)
		if arena != null:
			_player = _find_player_in_arena(arena)

	if _player == null:
		push_warning("RedBrandDirector could not find player.")
		return

	_red_brand_component = _find_red_brand_component(_player)
	if _red_brand_component == null:
		push_warning("RedBrandDirector could not find RedBrandComponent on player.")
		return

	_style_hud = get_node_or_null(style_hud_path)
	if _style_hud != null and _style_hud.has_method("bind_red_brand_component"):
		_style_hud.call("bind_red_brand_component", _red_brand_component)

	_bind_player_combat(_player)
	_bind_enemy_deaths()


func _find_player_in_arena(arena: Node) -> Node:
	var player := arena.get_node_or_null("Player")
	if player != null:
		return player

	return get_tree().get_first_node_in_group(PLAYER_GROUP)


func _find_red_brand_component(player: Node) -> RedBrandComponent:
	var component := player.get_node_or_null("Components/RedBrandComponent")
	if component is RedBrandComponent:
		return component

	var unique := player.get_node_or_null("%RedBrandComponent")
	if unique is RedBrandComponent:
		return unique

	return player.find_child("RedBrandComponent", true, false) as RedBrandComponent


func _bind_player_combat(player: Node) -> void:
	var hitbox := _find_component(player, "HitboxComponent")
	if hitbox != null and hitbox.has_signal("hit_landed"):
		hitbox.connect("hit_landed", Callable(self, "_on_player_hit_landed"))

	if player.has_signal("combo_completed"):
		player.connect("combo_completed", Callable(self, "_on_combo_completed"))

	if player.has_signal("counter_success"):
		player.connect("counter_success", Callable(self, "_on_counter_success"))

	if player.has_signal("brand_breaker_charge_started"):
		player.connect("brand_breaker_charge_started", Callable(self, "_on_brand_breaker_charge_started"))
	if player.has_signal("brand_breaker_charge_updated"):
		player.connect("brand_breaker_charge_updated", Callable(self, "_on_brand_breaker_charge_updated"))
	if player.has_signal("brand_breaker_charge_cancelled"):
		player.connect("brand_breaker_charge_cancelled", Callable(self, "_on_brand_breaker_charge_cancelled"))
	if player.has_signal("brand_breaker_released"):
		player.connect("brand_breaker_released", Callable(self, "_on_brand_breaker_released"))


func _bind_enemy_deaths() -> void:
	for node in get_tree().get_nodes_in_group(STYLE_TRACKABLE_GROUP):
		_bind_enemy_death(node)


func _bind_enemy_death(node: Node) -> void:
	var health := _find_component(node, "HealthComponent")
	if health != null and health.has_signal("died") and not health.is_connected("died", Callable(self, "_on_enemy_died")):
		health.connect("died", Callable(self, "_on_enemy_died"))


func _find_component(root: Node, component_name: String) -> Node:
	if root == null:
		return null

	var direct := root.get_node_or_null("Components/%s" % component_name)
	if direct != null:
		return direct

	var unique := root.get_node_or_null("%s" % component_name)
	if unique != null:
		return unique

	return root.find_child(component_name, true, false)


func _on_player_hit_landed(_target: Node, _hurtbox: Area2D, attack_data: Resource) -> void:
	if _red_brand_component == null or _red_brand_component.config == null:
		return

	var gain := _red_brand_component.config.hit_gain
	if attack_data != null:
		gain += float(attack_data.get("red_brand_gain"))

	_red_brand_component.gain_energy(gain, &"hit")


func _on_combo_completed() -> void:
	if _red_brand_component == null or _red_brand_component.config == null:
		return

	_red_brand_component.gain_energy(_red_brand_component.config.combo_gain, &"combo")


func _on_counter_success(_attack_data: Resource, _attacker: Node) -> void:
	if _red_brand_component == null or _red_brand_component.config == null:
		return

	_red_brand_component.gain_energy(_red_brand_component.config.counter_gain, &"counter")


func _on_enemy_died() -> void:
	if _red_brand_component == null or _red_brand_component.config == null:
		return

	_red_brand_component.gain_energy(_red_brand_component.config.kill_gain, &"kill")


func _on_brand_breaker_charge_started() -> void:
	if _style_hud != null and _style_hud.has_method("show_brand_charge"):
		_style_hud.call("show_brand_charge", true)


func _on_brand_breaker_charge_updated(charge_time: float, preview_level: int) -> void:
	if _style_hud != null and _style_hud.has_method("update_brand_charge"):
		_style_hud.call("update_brand_charge", charge_time, preview_level)


func _on_brand_breaker_charge_cancelled() -> void:
	if _style_hud != null and _style_hud.has_method("show_brand_charge"):
		_style_hud.call("show_brand_charge", false)


func _on_brand_breaker_released(_level: int, _cost: float) -> void:
	if _style_hud != null and _style_hud.has_method("show_brand_charge"):
		_style_hud.call("show_brand_charge", false)
