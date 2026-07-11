extends Node
class_name StyleManager

signal style_changed(style_score: float, style_rank: StringName)
signal style_feedback(message: String, amount: float)
signal style_reset
signal taunt_triggered(phrase: String, performer: Node, valid_targets: Array)

enum StyleRank {
	DUST,
	IRON,
	VERMILION,
	CRIMSON,
	HOLLOW,
}

const STYLE_TRACKABLE_GROUP := "style_trackable"
const PLAYER_GROUP := "player"
const RANK_NAMES := {
	StyleRank.DUST: &"DUST",
	StyleRank.IRON: &"IRON",
	StyleRank.VERMILION: &"VERMILION",
	StyleRank.CRIMSON: &"CRIMSON",
	StyleRank.HOLLOW: &"HOLLOW",
}
const RANK_THRESHOLDS := {
	StyleRank.DUST: 0.0,
	StyleRank.IRON: 100.0,
	StyleRank.VERMILION: 300.0,
	StyleRank.CRIMSON: 600.0,
	StyleRank.HOLLOW: 1000.0,
}
const REWARD_MULTIPLIERS := {
	StyleRank.DUST: 1.0,
	StyleRank.IRON: 1.25,
	StyleRank.VERMILION: 1.5,
	StyleRank.CRIMSON: 1.75,
	StyleRank.HOLLOW: 2.0,
}

@export var arena_path: NodePath
@export var decay_delay: float = 4.0
@export var decay_rate: float = 10.0
@export var variety_history_size: int = 6
@export var repetition_penalty_step: float = 0.16
@export var min_gain_multiplier: float = 0.35
@export var variety_restore_amount: float = 0.22
@export var combo_complete_bonus: float = 35.0
@export var counter_bonus: float = 85.0
@export var enemy_defeat_bonus: float = 40.0
@export var narrow_dodge_bonus: float = 30.0
@export var taunt_base_bonus: float = 18.0
@export var taunt_risky_multiplier: float = 1.65
@export var taunt_nearby_range: float = 200.0
@export var taunt_combat_memory: float = 3.5
@export var taunt_spam_window: float = 8.0
@export var taunt_spam_penalty_step: float = 0.22
@export var taunt_min_reward_multiplier: float = 0.35
@export var damage_penalty_ratio: float = 0.18
@export var damage_penalty_flat: float = 15.0
@export var failed_risky_action_penalty: float = 20.0
@export var inactivity_decay_only_after_delay: bool = true

var style_score: float = 0.0
var style_rank: StringName = &"DUST"
var repetition_penalty: float = 0.0
var variety_history: Array[StringName] = []
var reward_multiplier: float = 1.0

var _current_rank: int = StyleRank.DUST
var _time_since_last_style_action: float = 0.0
var _is_decaying: bool = false
var _active_pressure_count: int = 0
var _dodge_threat_overlap: bool = false
var _bound_nodes: Array[Node] = []
var _player: Node = null
var _recent_taunt_times: Array[float] = []
var _last_combat_timestamp: float = -999.0

@onready var style_hud: CanvasLayer = $StyleHud


func _ready() -> void:
	add_to_group("style_manager")
	await get_tree().process_frame
	_bind_arena_combat()
	if style_hud != null and style_hud.has_method("bind_style_manager"):
		style_hud.call("bind_style_manager", self)
	_publish_style_state()
	_show_feedback("Style Ready", 0.0)


func _process(delta: float) -> void:
	_update_decay(delta)
	_update_narrow_dodge_tracking()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_reset"):
		reset_style()


func reset_style() -> void:
	style_score = 0.0
	repetition_penalty = 0.0
	variety_history.clear()
	_time_since_last_style_action = 0.0
	_is_decaying = false
	_active_pressure_count = 0
	_dodge_threat_overlap = false
	_recent_taunt_times.clear()
	_last_combat_timestamp = -999.0
	_update_rank()
	style_reset.emit()
	_publish_style_state()
	_show_feedback("Style Reset", 0.0)


func get_reward_multiplier() -> float:
	return reward_multiplier


func get_rank_progress() -> float:
	var current_threshold := float(RANK_THRESHOLDS[_current_rank])
	if _current_rank >= StyleRank.HOLLOW:
		return 1.0

	var next_rank := _current_rank + 1
	var next_threshold := float(RANK_THRESHOLDS[next_rank])
	if next_threshold <= current_threshold:
		return 1.0

	return clampf((style_score - current_threshold) / (next_threshold - current_threshold), 0.0, 1.0)


func refresh_world_bindings(_area: AreaRoot = null) -> void:
	_prune_bound_nodes()
	_active_pressure_count = 0
	for node in get_tree().get_nodes_in_group(STYLE_TRACKABLE_GROUP):
		_bind_style_trackable(node)


func _bind_arena_combat() -> void:
	_player = get_tree().get_first_node_in_group(PLAYER_GROUP)
	if _player == null:
		var arena := get_node_or_null(arena_path)
		if arena != null:
			_player = _find_player_in_arena(arena)

	if _player == null:
		push_warning("StyleManager could not find player.")
		return

	_bind_player(_player)

	for node in get_tree().get_nodes_in_group(STYLE_TRACKABLE_GROUP):
		_bind_style_trackable(node)


func _find_player_in_arena(arena: Node) -> Node:
	var player := arena.get_node_or_null("Player")
	if player != null:
		return player

	return get_tree().get_first_node_in_group(PLAYER_GROUP)


func _bind_player(player: Node) -> void:
	_track_bound_node(player)

	var hitbox := _find_component(player, "HitboxComponent")
	if hitbox != null and hitbox.has_signal("hit_landed"):
		hitbox.connect("hit_landed", Callable(self, "_on_player_hit_landed"))

	if player.has_signal("counter_success"):
		player.connect("counter_success", Callable(self, "_on_counter_success"))

	if player.has_signal("combo_completed"):
		player.connect("combo_completed", Callable(self, "_on_combo_completed"))

	if player.has_signal("dodge_started"):
		player.connect("dodge_started", Callable(self, "_on_dodge_started"))

	if player.has_signal("dodge_finished"):
		player.connect("dodge_finished", Callable(self, "_on_dodge_finished"))

	if player.has_signal("counter_resolved"):
		player.connect("counter_resolved", Callable(self, "_on_counter_resolved"))

	if player.has_signal("taunt_performed"):
		player.connect("taunt_performed", Callable(self, "_on_taunt_performed"))

	if player.has_signal("taunt_started"):
		player.connect("taunt_started", Callable(self, "_on_taunt_started"))

	var health := _find_component(player, "HealthComponent")
	if health != null and health.has_signal("damaged"):
		health.connect("damaged", Callable(self, "_on_player_damaged"))


func _bind_style_trackable(node: Node) -> void:
	if _bound_nodes.has(node):
		return

	_track_bound_node(node)

	if node.has_signal("combat_pressure_changed") and not node.is_connected(
		"combat_pressure_changed",
		Callable(self, "_on_combat_pressure_changed")
	):
		node.connect("combat_pressure_changed", Callable(self, "_on_combat_pressure_changed"))

	var health := _find_component(node, "HealthComponent")
	if health != null and health.has_signal("died"):
		var died_callable := Callable(self, "_on_enemy_died").bind(node)
		if not health.is_connected("died", died_callable):
			health.connect("died", died_callable)


func _track_bound_node(node: Node) -> void:
	if node == null or _bound_nodes.has(node):
		return

	_bound_nodes.append(node)


func _prune_bound_nodes() -> void:
	var valid_nodes: Array[Node] = []
	for node in _bound_nodes:
		if node != null and is_instance_valid(node):
			valid_nodes.append(node)
	_bound_nodes = valid_nodes


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
	if attack_data == null:
		return

	var attack_id := StringName(attack_data.get("attack_id"))
	var base_gain := float(attack_data.get("style_gain"))
	var gain_multiplier := _register_attack_variety(attack_id)
	var final_gain := base_gain * gain_multiplier
	_add_style(final_gain, "Hit +%.0f" % final_gain)


func _on_combo_completed() -> void:
	_add_style(combo_complete_bonus, "Combo +%.0f" % combo_complete_bonus)


func _on_counter_success(_attack_data: Resource, _attacker: Node) -> void:
	_register_attack_variety(&"calder_counter")
	_add_style(counter_bonus, "Counter +%.0f" % counter_bonus)


func _on_counter_resolved(result: String) -> void:
	if result == "success":
		return

	if _active_pressure_count <= 0:
		return

	if result == "miss" or result == "miss_window" or result == "not_counterable":
		_subtract_style(failed_risky_action_penalty, "Failed Counter -%.0f" % failed_risky_action_penalty)


func _on_taunt_started(phrase: String, _line_id: StringName) -> void:
	if style_hud != null and style_hud.has_method("show_taunt_line"):
		style_hud.call("show_taunt_line", phrase)


func _on_taunt_performed(phrase: String, context: Dictionary) -> void:
	var nearby_targets := _get_nearby_valid_enemies()
	taunt_triggered.emit(phrase, _player, nearby_targets)

	if not _can_award_taunt_style():
		_show_feedback("Taunt", 0.0)
		return

	var bonus := _calculate_taunt_bonus()
	_register_taunt_spam()
	_add_style(bonus, "Taunt +%.0f" % bonus)


func _can_award_taunt_style() -> bool:
	if not _has_valid_enemy():
		return false

	return _has_nearby_valid_enemy() or _is_in_combat()


func _has_valid_enemy() -> bool:
	for node in get_tree().get_nodes_in_group(STYLE_TRACKABLE_GROUP):
		if _is_valid_enemy(node):
			return true
	return false


func _has_nearby_valid_enemy() -> bool:
	return not _get_nearby_valid_enemies().is_empty()


func _get_nearby_valid_enemies() -> Array:
	var targets: Array = []
	if _player == null or not (_player is Node2D):
		return targets

	var player_position := (_player as Node2D).global_position
	for node in get_tree().get_nodes_in_group(STYLE_TRACKABLE_GROUP):
		if not _is_valid_enemy(node) or not (node is Node2D):
			continue

		if (node as Node2D).global_position.distance_to(player_position) <= taunt_nearby_range:
			targets.append(node)

	return targets


func _is_valid_enemy(node: Node) -> bool:
	if node == null or not node.is_inside_tree():
		return false

	var health := _find_component(node, "HealthComponent")
	if health == null:
		return false

	return not bool(health.get("is_dead"))


func _is_in_combat() -> bool:
	if _active_pressure_count > 0:
		return true

	var now := Time.get_ticks_msec() / 1000.0
	return now - _last_combat_timestamp <= taunt_combat_memory


func _calculate_taunt_bonus() -> float:
	var bonus := taunt_base_bonus
	if _active_pressure_count > 0:
		bonus *= taunt_risky_multiplier

	var spam_multiplier := _get_taunt_spam_multiplier()
	return maxf(bonus * spam_multiplier, taunt_base_bonus * taunt_min_reward_multiplier)


func _get_taunt_spam_multiplier() -> float:
	_prune_recent_taunts()
	var spam_stacks := maxi(_recent_taunt_times.size() - 1, 0)
	return maxf(1.0 - float(spam_stacks) * taunt_spam_penalty_step, taunt_min_reward_multiplier)


func _register_taunt_spam() -> void:
	_prune_recent_taunts()
	_recent_taunt_times.append(Time.get_ticks_msec() / 1000.0)


func _prune_recent_taunts() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var filtered: Array[float] = []
	for timestamp in _recent_taunt_times:
		if now - timestamp <= taunt_spam_window:
			filtered.append(timestamp)
	_recent_taunt_times = filtered


func _on_dodge_started() -> void:
	_dodge_threat_overlap = false


func _on_dodge_finished() -> void:
	if not _dodge_threat_overlap:
		return

	_add_style(narrow_dodge_bonus, "Close Dodge +%.0f" % narrow_dodge_bonus)
	_dodge_threat_overlap = false


func _on_player_damaged(amount: float, _source: Node) -> void:
	var penalty := maxf(style_score * damage_penalty_ratio, 0.0) + damage_penalty_flat
	penalty = minf(penalty, style_score)
	if penalty <= 0.0:
		return

	_subtract_style(penalty, "Damage -%.0f" % penalty)


func _on_enemy_died(enemy: Node) -> void:
	if enemy == null:
		return

	var health := _find_component(enemy, "HealthComponent")
	var bonus := enemy_defeat_bonus
	if health != null:
		var max_health := float(health.get("max_health"))
		if max_health > 0.0:
			bonus = maxf(enemy_defeat_bonus, max_health * 3.5)

	_add_style(bonus, "Defeat +%.0f" % bonus)


func _on_combat_pressure_changed(is_active: bool) -> void:
	if is_active:
		_active_pressure_count += 1
		_mark_combat_activity()
	else:
		_active_pressure_count = maxi(_active_pressure_count - 1, 0)


func _register_attack_variety(attack_id: StringName) -> float:
	if attack_id == &"":
		return 1.0

	var recent_repeats := _count_recent_repeats(attack_id)
	repetition_penalty = clampf(float(recent_repeats) * repetition_penalty_step, 0.0, 1.0 - min_gain_multiplier)

	if _is_varied_attack(attack_id):
		repetition_penalty = maxf(repetition_penalty - variety_restore_amount, 0.0)

	variety_history.push_front(attack_id)
	while variety_history.size() > variety_history_size:
		variety_history.pop_back()

	return maxf(1.0 - repetition_penalty, min_gain_multiplier)


func _count_recent_repeats(attack_id: StringName) -> int:
	var repeats := 0
	for recorded_id in variety_history:
		if recorded_id == attack_id:
			repeats += 1
	return repeats


func _is_varied_attack(attack_id: StringName) -> bool:
	if variety_history.is_empty():
		return true

	return variety_history[0] != attack_id


func grant_style_reward(amount: float, feedback: String) -> void:
	_add_style(amount, feedback)


func _add_style(amount: float, feedback: String) -> void:
	if amount <= 0.0:
		return

	style_score += amount
	_reset_decay_timer()
	_update_rank()
	_publish_style_state()
	_show_feedback(feedback, amount)


func _subtract_style(amount: float, feedback: String) -> void:
	if amount <= 0.0:
		return

	style_score = maxf(style_score - amount, 0.0)
	_update_rank()
	_publish_style_state()
	_show_feedback(feedback, -amount)


func _reset_decay_timer() -> void:
	_time_since_last_style_action = 0.0
	_is_decaying = false
	_mark_combat_activity()


func _mark_combat_activity() -> void:
	_last_combat_timestamp = Time.get_ticks_msec() / 1000.0


func _update_decay(delta: float) -> void:
	if not inactivity_decay_only_after_delay and style_score <= 0.0:
		return

	_time_since_last_style_action += delta
	if _time_since_last_style_action < decay_delay:
		_is_decaying = false
		return

	if not _is_decaying:
		_is_decaying = true

	var decay_amount := decay_rate * delta
	if decay_amount <= 0.0:
		return

	var previous_score := style_score
	style_score = maxf(style_score - decay_amount, 0.0)
	if not is_equal_approx(previous_score, style_score):
		_update_rank()
		_publish_style_state()


func _update_narrow_dodge_tracking() -> void:
	if _player == null:
		return

	if not _player.has_method("_is_dodging") or not bool(_player.call("_is_dodging")):
		return

	if not _player.has_method("_is_health_invulnerable") or not bool(_player.call("_is_health_invulnerable")):
		return

	if _active_pressure_count > 0:
		_dodge_threat_overlap = true


func _update_rank() -> void:
	var new_rank := StyleRank.DUST
	for rank in [StyleRank.HOLLOW, StyleRank.CRIMSON, StyleRank.VERMILION, StyleRank.IRON, StyleRank.DUST]:
		if style_score >= float(RANK_THRESHOLDS[rank]):
			new_rank = rank
			break

	_current_rank = new_rank
	style_rank = RANK_NAMES[new_rank]
	reward_multiplier = float(REWARD_MULTIPLIERS[new_rank])


func _publish_style_state() -> void:
	style_changed.emit(style_score, style_rank)


func _show_feedback(message: String, amount: float) -> void:
	style_feedback.emit(message, amount)
