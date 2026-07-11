extends RefCounted
class_name PlayerStateTypes

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	DODGE,
	COUNTER,
	TAUNT,
	HURT,
	DEAD,
	INTERACT,
}

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

enum DodgePhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

enum CounterPhase {
	NONE,
	STARTUP,
	WINDOW,
	RECOVERY,
	COUNTER_ATTACK,
}

enum BrandBreakerPhase {
	NONE,
	CHARGING,
}

const RUN_SPEED_THRESHOLD := 1.0
const ATTACK_MOVEMENT_DECELERATION_SCALE := 0.75
