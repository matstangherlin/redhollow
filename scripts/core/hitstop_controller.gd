extends Node
class_name HitstopController

const HITSTOP_GROUP := "hitstop_controller"

@export var max_hitstop_duration: float = 0.08

## Marker-only hitstop for feedback hooks. Does not pause the tree or change Engine.time_scale.
var hitstop_remaining: float = 0.0
var hitstop_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(HITSTOP_GROUP)
	force_release()


func _process(delta: float) -> void:
	if not hitstop_active:
		return

	var step := maxf(delta, 0.016)
	hitstop_remaining = maxf(hitstop_remaining - step, 0.0)
	if hitstop_remaining <= 0.0:
		hitstop_active = false


func request_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return

	var safe_duration := minf(duration, max_hitstop_duration)
	hitstop_active = true
	hitstop_remaining = maxf(hitstop_remaining, safe_duration)


func force_release() -> void:
	hitstop_active = false
	hitstop_remaining = 0.0
