extends Resource
class_name AttackData

@export var attack_id: StringName = &""
@export var display_name: String = ""
@export var damage: float = 1.0
@export var startup_time: float = 0.0
@export var active_time: float = 0.0
@export var recovery_time: float = 0.0
@export var hitbox_size: Vector2 = Vector2.ZERO
@export var hitbox_offset: Vector2 = Vector2.ZERO
@export var hitstun_time: float = 0.0
@export var knockback: Vector2 = Vector2.ZERO
@export var attacker_hitstop: float = 0.0
@export var target_hitstop: float = 0.0
@export var style_gain: int = 0
@export var cancel_window_start: float = 0.0
@export var cancel_window_end: float = 0.0
@export var can_hit_ground_targets: bool = true
@export var can_hit_air_targets: bool = false
@export var max_hits_per_target: int = 1
@export var counterable: bool = true
@export var red_brand_gain: float = 0.0
@export var red_brand_cost: float = 0.0
@export var tags: PackedStringArray = PackedStringArray()


func get_total_time() -> float:
	return startup_time + active_time + recovery_time


func has_cancel_window() -> bool:
	return cancel_window_end > cancel_window_start