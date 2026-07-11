extends RefCounted
class_name PlayerStateSnapshot

const DEFAULT_MAX_HEALTH := 12.0


static func capture(player: CharacterBody2D) -> Dictionary:
	if player == null:
		return _empty_state()

	if player.has_method("export_save_state"):
		return player.export_save_state()

	return _empty_state()


static func apply(player: CharacterBody2D, save_data: Dictionary, include_position: bool = true) -> void:
	if player == null or save_data.is_empty():
		return

	if player.has_method("import_save_state"):
		var payload := save_data
		if not include_position:
			payload = save_data.duplicate(true)
			payload.erase("checkpoint_position")
		player.import_save_state(payload)


static func _empty_state() -> Dictionary:
	return {
		"spawn_position": {"x": 0.0, "y": 0.0},
		"max_health": DEFAULT_MAX_HEALTH,
		"current_health": DEFAULT_MAX_HEALTH,
		"red_brand_energy": 0.0,
	}
