extends Node

const HITSTOP_GROUP := "hitstop_controller"

@export var max_hitstop_duration: float = 0.08

## Hitstop used to freeze Engine.time_scale, which permanently soft-locked the game
## because scaled delta became 0 and the timer never finished. Keep a lightweight
## marker for feedback systems, but never freeze the simulation.
var hitstop_remaining: float = 0.0
var hitstop_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(HITSTOP_GROUP)
	force_release()


func _process(delta: float) -> void:
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false

	if not hitstop_active:
		return

	hitstop_remaining = maxf(hitstop_remaining - maxf(delta, 0.016), 0.0)
	if hitstop_remaining <= 0.0:
		hitstop_active = false


func request_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return

	var safe_duration := minf(duration, max_hitstop_duration)
	hitstop_active = true
	hitstop_remaining = maxf(hitstop_remaining, safe_duration)
	# Intentionally do NOT pause the tree or change Engine.time_scale.


func force_release() -> void:
	hitstop_active = false
	hitstop_remaining = 0.0
	Engine.time_scale = 1.0
	if get_tree() != null:
		get_tree().paused = false
