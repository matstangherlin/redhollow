extends RefCounted
class_name CombatFeedbackResolver

## Maps AttackData and context to feedback intensity. Combat timing stays in AttackData.

enum ImpactTier {
	LIGHT,
	MEDIUM,
	HEAVY,
	BREAKER,
	COUNTER,
	SPECIAL,
}


static func resolve_hit_feedback(
	attack_data: Resource,
	attacker: Node,
	target: Node
) -> Dictionary:
	var profile := CombatFeedbackProfileLibrary.resolve_for_attack(attack_data)
	if profile != null:
		return profile.to_feedback_dict(attacker, target)

	return _resolve_legacy_hit_feedback(attack_data, attacker, target)


static func resolve_profile(attack_data: Resource) -> CombatFeedbackProfile:
	return CombatFeedbackProfileLibrary.resolve_for_attack(attack_data)


static func resolve_attack_windup_sfx(attack_data: Resource) -> StringName:
	var profile := CombatFeedbackProfileLibrary.resolve_for_attack(attack_data)
	if profile != null and profile.sfx_id != &"":
		return profile.sfx_id

	var tags := _get_tags(attack_data)
	if tags.has("kick"):
		return AudioEventId.KICK
	if tags.has("chain"):
		return AudioEventId.CHAIN
	if tags.has("gun") or tags.has("shot"):
		return AudioEventId.GUNSHOT
	if tags.has("punch") or tags.has("straight"):
		return AudioEventId.PUNCH
	return AudioEventId.PUNCH


static func resolve_telegraph_vfx(counterable: bool) -> StringName:
	return &"telegraph_counterable" if counterable else &"telegraph_not_counterable"


static func tier_rank(tier: ImpactTier) -> int:
	return int(tier)


static func _resolve_legacy_hit_feedback(
	attack_data: Resource,
	attacker: Node,
	target: Node
) -> Dictionary:
	var tier := _resolve_tier(attack_data)
	var tags := _get_tags(attack_data)
	var sfx := _resolve_impact_sfx(tags, tier)
	var vfx := _resolve_vfx_kind(tier, tags)

	return {
		"tier": tier,
		"sfx_id": sfx,
		"vfx_kind": vfx,
		"shake_intensity": _shake_for_tier(tier),
		"shake_duration": _shake_duration_for_tier(tier),
		"zoom_amount": _zoom_for_tier(tier),
		"zoom_duration": _zoom_duration_for_tier(tier),
		"flash_strength": _flash_for_tier(tier),
		"particle_count": _default_particle_count(tier),
		"particle_lifetime": 0.18,
		"impact_color": Color(0.95, 0.88, 0.72, 0.85),
		"attacker_is_player": _is_player(attacker),
		"target_is_player": _is_player(target),
	}


static func _resolve_tier(attack_data: Resource) -> ImpactTier:
	if attack_data == null:
		return ImpactTier.LIGHT

	var attack_id := String(attack_data.get("attack_id"))
	var tags := _get_tags(attack_data)
	var damage := float(attack_data.get("damage"))

	if attack_id.contains("counter") or tags.has("counter"):
		return ImpactTier.COUNTER
	if tags.has("red_brand_breaker") or attack_id.contains("breaker"):
		return ImpactTier.BREAKER
	if tags.has("red_brand") or attack_id.contains("red_knuckle"):
		return ImpactTier.HEAVY
	if tags.has("gun") or tags.has("shot") or tags.has("chain"):
		return ImpactTier.MEDIUM
	if damage >= 14.0:
		return ImpactTier.HEAVY
	if damage >= 6.0:
		return ImpactTier.MEDIUM
	return ImpactTier.LIGHT


static func _resolve_impact_sfx(tags: PackedStringArray, tier: ImpactTier) -> StringName:
	if tags.has("vermilite") or tags.has("red_brand"):
		return AudioEventId.IMPACT_VERMILITE
	if tags.has("stone") or tags.has("barrier"):
		return AudioEventId.IMPACT_STONE
	if tags.has("chain"):
		return AudioEventId.CHAIN
	if tags.has("gun") or tags.has("shot"):
		return AudioEventId.GUNSHOT
	if tier == ImpactTier.BREAKER:
		return AudioEventId.RED_BRAND_BREAKER
	if tier >= ImpactTier.HEAVY:
		return AudioEventId.KICK
	if tags.has("kick"):
		return AudioEventId.KICK
	return AudioEventId.IMPACT_FLESH


static func _resolve_vfx_kind(tier: ImpactTier, tags: PackedStringArray) -> StringName:
	if tags.has("red_brand_breaker") or tags.has("breaker"):
		return &"red_brand"
	if tags.has("red_brand"):
		return &"hit_heavy"
	if tags.has("gun") or tags.has("shot"):
		return &"gunshot"
	if tags.has("chain"):
		return &"chain"
	if tags.has("vermilite"):
		return &"vermilite"
	if tags.has("boss"):
		return &"boss"
	if tier == ImpactTier.COUNTER:
		return &"counter"
	if tier >= ImpactTier.HEAVY:
		return &"hit_heavy"
	return &"hit_normal"


static func _default_particle_count(tier: ImpactTier) -> int:
	match tier:
		ImpactTier.LIGHT:
			return 6
		ImpactTier.MEDIUM:
			return 8
		ImpactTier.HEAVY:
			return 10
		ImpactTier.BREAKER:
			return 14
		ImpactTier.COUNTER:
			return 12
		_:
			return 6


static func _shake_for_tier(tier: ImpactTier) -> float:
	match tier:
		ImpactTier.LIGHT:
			return 2.5
		ImpactTier.MEDIUM:
			return 5.0
		ImpactTier.HEAVY:
			return 8.5
		ImpactTier.BREAKER:
			return 12.0
		ImpactTier.COUNTER:
			return 7.0
		_:
			return 3.0


static func _shake_duration_for_tier(tier: ImpactTier) -> float:
	match tier:
		ImpactTier.LIGHT:
			return 0.08
		ImpactTier.MEDIUM:
			return 0.12
		ImpactTier.HEAVY:
			return 0.18
		ImpactTier.BREAKER:
			return 0.24
		ImpactTier.COUNTER:
			return 0.16
		_:
			return 0.10


static func _zoom_for_tier(tier: ImpactTier) -> float:
	match tier:
		ImpactTier.HEAVY:
			return 0.025
		ImpactTier.BREAKER:
			return 0.04
		ImpactTier.COUNTER:
			return 0.02
		_:
			return 0.0


static func _zoom_duration_for_tier(tier: ImpactTier) -> float:
	if _zoom_for_tier(tier) <= 0.0:
		return 0.0
	return 0.10


static func _flash_for_tier(tier: ImpactTier) -> float:
	match tier:
		ImpactTier.LIGHT:
			return 0.18
		ImpactTier.MEDIUM:
			return 0.28
		ImpactTier.HEAVY:
			return 0.42
		ImpactTier.BREAKER:
			return 0.55
		ImpactTier.COUNTER:
			return 0.38
		_:
			return 0.20


static func _get_tags(attack_data: Resource) -> PackedStringArray:
	if attack_data == null:
		return PackedStringArray()
	var tags: Variant = attack_data.get("tags")
	if tags is PackedStringArray:
		return tags
	return PackedStringArray()


static func _is_player(node: Node) -> bool:
	return node != null and node.is_in_group("player")
