extends RefCounted
class_name CombatFeedbackProfileLibrary

## Registry for Calder beta attack feedback profiles.

const PROFILE_DIR := "res://resources/combat/feedback_profiles/"

const ATTACK_PROFILE_PATHS: Dictionary = {
	"calder_straight": PROFILE_DIR + "calder_straight_feedback.tres",
	"body_hook": PROFILE_DIR + "body_hook_feedback.tres",
	"red_knuckle": PROFILE_DIR + "red_knuckle_feedback.tres",
	"calder_counter": PROFILE_DIR + "calder_counter_feedback.tres",
	"red_brand_breaker_lv1": PROFILE_DIR + "red_brand_breaker_lv1_feedback.tres",
	"red_brand_breaker_lv2": PROFILE_DIR + "red_brand_breaker_lv2_feedback.tres",
}

static var _cache: Dictionary = {}


static func get_profile(attack_id: StringName) -> CombatFeedbackProfile:
	var key := String(attack_id)
	if key.is_empty():
		return null

	if _cache.has(key):
		return _cache[key]

	var path: String = ATTACK_PROFILE_PATHS.get(key, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null

	var loaded: Variant = load(path)
	if loaded is CombatFeedbackProfile:
		_cache[key] = loaded
		return loaded

	return null


static func resolve_for_attack(attack_data: Resource) -> CombatFeedbackProfile:
	if attack_data == null:
		return null
	return get_profile(attack_data.get("attack_id"))


static func get_registered_attack_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for key in ATTACK_PROFILE_PATHS.keys():
		ids.append(StringName(String(key)))
	return ids


static func clear_cache() -> void:
	_cache.clear()
