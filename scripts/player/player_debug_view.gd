extends Node
class_name PlayerDebugView

@export var enabled_in_debug_builds: bool = true

var visible_in_game: bool = false

var _debug_label: Label = null
var _hitbox_component: Area2D = null
var _hurtbox_component: Area2D = null


func setup(debug_label: Label, hitbox_component: Area2D, hurtbox_component: Area2D) -> void:
	_debug_label = debug_label
	_hurtbox_component = hurtbox_component
	_hitbox_component = hitbox_component
	set_debug_visible(false)


func set_debug_visible(is_visible: bool) -> void:
	if not enabled_in_debug_builds:
		is_visible = false

	visible_in_game = is_visible
	if _debug_label != null:
		_debug_label.visible = is_visible
	if _hitbox_component != null and _hitbox_component.has_method("set_debug_draw_enabled"):
		_hitbox_component.call("set_debug_draw_enabled", is_visible)
	if _hurtbox_component != null and _hurtbox_component.has_method("set_debug_draw_enabled"):
		_hurtbox_component.call("set_debug_draw_enabled", is_visible)


func toggle_visibility() -> void:
	set_debug_visible(not visible_in_game)


func refresh(snapshot: Dictionary) -> void:
	if not visible_in_game or _debug_label == null:
		return

	_debug_label.text = "state: %s\nvelocity.x: %.2f\nvelocity.y: %.2f\nis_on_floor: %s\ncoyote: %.3f\njump_buffer: %.3f\nfacing: %d\nattack: %s\ncombo_index: %d / %d\nbuffered_input: %s\nbuffer_time: %.3f\nattack_phase: %s\nattack_time: %.3f\nlast_hit: %s\ndodge_phase: %s\ndodge_time: %.3f\ndodge_invulnerable: %s\ndodge_recovery: %.3f\ndodge_cooldown: %.3f\ncounter_phase: %s\ncounter_window: %.3f\ncounter_recovery: %.3f\ncounter_cooldown: %.3f\nlast_counter: %s\nincoming_attack: %s\nincoming_counterable: %s\ntaunt_time: %.3f\ntaunt_vulnerable: %s\ntaunt_cooldown: %.3f\ntaunt_phrase: %s\nred_brand: %.0f / %.0f\nbrand_charge_level: %d\nbrand_cost: %.0f\nbrand_charge_time: %.3f\nbrand_breaker: %s\ninput_blocked: %s\ninteract_id: %s\ninteract_distance: %.1f\ninteract_priority: %d" % [
		String(snapshot.get("state_name", "unknown")),
		float(snapshot.get("velocity_x", 0.0)),
		float(snapshot.get("velocity_y", 0.0)),
		str(snapshot.get("is_on_floor", false)),
		float(snapshot.get("coyote_time_remaining", 0.0)),
		float(snapshot.get("jump_buffer_remaining", 0.0)),
		int(snapshot.get("facing_direction", 1)),
		String(snapshot.get("attack_name", "none")),
		int(snapshot.get("combo_index_display", 0)),
		int(snapshot.get("combo_size", 0)),
		String(snapshot.get("buffered_attack_name", "none")),
		float(snapshot.get("combo_buffer_time_remaining", 0.0)),
		String(snapshot.get("attack_phase_name", "none")),
		float(snapshot.get("attack_phase_time_remaining", 0.0)),
		String(snapshot.get("last_hit_target_name", "none")),
		String(snapshot.get("dodge_phase_name", "none")),
		float(snapshot.get("dodge_elapsed_time", 0.0)),
		str(snapshot.get("is_invulnerable", false)),
		float(snapshot.get("dodge_recovery_remaining", 0.0)),
		float(snapshot.get("dodge_cooldown_remaining", 0.0)),
		String(snapshot.get("counter_phase_name", "none")),
		float(snapshot.get("counter_window_remaining", 0.0)),
		float(snapshot.get("counter_recovery_remaining", 0.0)),
		float(snapshot.get("counter_cooldown_remaining", 0.0)),
		String(snapshot.get("last_counter_result", "none")),
		String(snapshot.get("last_incoming_attack_name", "none")),
		str(snapshot.get("last_incoming_counterable", false)),
		float(snapshot.get("taunt_elapsed_time", 0.0)),
		str(snapshot.get("taunt_vulnerable", false)),
		float(snapshot.get("taunt_cooldown_remaining", 0.0)),
		String(snapshot.get("taunt_phrase", "none")),
		float(snapshot.get("red_brand_current", 0.0)),
		float(snapshot.get("red_brand_max", 0.0)),
		int(snapshot.get("brand_charge_level", 0)),
		float(snapshot.get("brand_breaker_release_cost", 0.0)),
		float(snapshot.get("brand_charge_time", 0.0)),
		String(snapshot.get("brand_breaker_state_name", "none")),
		str(snapshot.get("input_blocked", false)),
		String(snapshot.get("interact_id", "none")),
		float(snapshot.get("interact_distance", -1.0)),
		int(snapshot.get("interact_priority", 0)),
	]
